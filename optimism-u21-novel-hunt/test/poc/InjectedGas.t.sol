// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21GasScan.sol";

// ------------------------------------------------------------------------------------------------
// HARNESS-ONLY INJECTION. Nothing in this file is a production-reachable sequence by itself.
//
// The withdrawals below never existed on L2. They are injected with vm.store into
// `OptimismPortal2.provenWithdrawals[hash][submitter]` pointing at a REAL type-9 game that is
// already finalized + DEFENDER_WINS on the fork. Everything downstream of that single storage
// write is the real deployed bytecode (portal proxy+impl, ETHLockbox, L1CrossDomainMessenger
// ResolvedDelegateProxy+impl, SuperchainConfig, SystemConfig, AnchorStateRegistry, game).
// What is being measured is the GAS BEHAVIOUR of the real portal + messenger for message shapes
// (size / minGasLimit / value / target behaviour) that the real fixtures do not cover.
//
//   U21_FORK=l1pre forge test --match-path test/InjectedGas.t.sol   (v8)
//   U21_FORK=l1    forge test --match-path test/InjectedGas.t.sol   (v9)
// ------------------------------------------------------------------------------------------------

contract TOk {
    uint256 public seenGas;
    uint256 public calls;

    fallback() external payable {
        uint256 g = gasleft();
        seenGas = g;
        calls++;
    }
}

contract TRevert {
    fallback() external payable {
        revert("TRevert");
    }
}

contract TBurn {
    fallback() external payable {
        assembly {
            invalid()
        }
    }
}

contract TBomb {
    fallback() external payable {
        assembly {
            return(0, 200000)
        }
    }
}

/// @dev Re-enters every portal / lockbox / messenger entry point from inside the withdrawal call.
contract TReenter {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockbox constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    IMessenger constant L1CDM = IMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);

    bytes public otherFinalize; // calldata finalizing ANOTHER mature injected withdrawal
    bytes public selfRelay; // calldata relaying the message currently being relayed
    uint256 public mask; // bit i set => re-entrant call i SUCCEEDED
    uint256 public calls;

    function arm(bytes calldata _otherFinalize, bytes calldata _selfRelay) external {
        otherFinalize = _otherFinalize;
        selfRelay = _selfRelay;
    }

    fallback() external payable {
        uint256 m;
        bool ok;
        (ok,) = address(PORTAL).call{ gas: gasleft() / 8 }(otherFinalize);
        if (ok) m |= 1; // must never succeed (l2Sender guard)
        (ok,) = address(L1CDM).call{ gas: gasleft() / 8 }(selfRelay);
        if (ok) m |= 2; // must never succeed during the first relay
        (ok,) = address(LOCKBOX).call{ gas: gasleft() / 8 }(abi.encodeCall(ILockbox.unlockETH, (1 ether)));
        if (ok) m |= 4; // must never succeed (unauthorized)
        (ok,) = address(LOCKBOX).call{ gas: gasleft() / 8, value: msg.value / 4 }(abi.encodeCall(ILockbox.lockETH, ()));
        if (ok) m |= 8; // must never succeed (unauthorized)
        (ok,) = address(PORTAL).call{ gas: gasleft() / 8 }(abi.encodeCall(IPortal.migrateLiquidity, ()));
        if (ok) m |= 16; // must never succeed (owner only)
        mask = m;
        calls++;
    }
}

contract InjectedGasTest is U21GasScan {
    enum Kind {
        OK, // 0 records gasleft
        REVERT, // 1
        BURN, // 2 consumes all forwarded gas
        BOMB, // 3 returns 200 KB
        REENTER, // 4
        EMPTY, // 5 no code, no balance, nonce 0 (codehash == 0)
        EOA, // 6 no code, 1 wei balance (codehash == keccak(""))
        DELEG_BURN, // 7 EIP-7702 delegation designator -> TBurn
        DELEG_OK // 8 EIP-7702 delegation designator -> TOk

    }

    enum Formula {
        CURRENT_L2, // L2CrossDomainMessenger 2.2.1 live on OP Mainnet (verified with cast on fork `l2`)
        LEGACY_L2, // 285000 + 16*len + minGas*64/63 (older L2CDM; real unfinalized fixtures f0/f16 use it)
        V9_L2 // what a v9 L2CDM would compute (remote = L1 budgets 200k/40k/135k/15k)

    }

    struct Case {
        bool messenger;
        Kind kind;
        uint256 len; // inner message length (messenger) or data length (plain)
        uint256 minGas; // inner minGasLimit (messenger) or wd.gasLimit (plain)
        uint256 value;
        Formula formula;
        address target; // inner target (messenger) or wd.target (plain)
        bytes32 hash;
    }

    Case[] internal cases;
    string internal fork;
    address internal validGame;
    uint64 internal injectTs;
    address internal constant SUBMITTER = address(0x5B17);
    address internal constant PLAIN_L2_SENDER = 0x00000000000000000000000000000000000B0b01;
    address internal constant INNER_SENDER = address(0xA11cE);

    TOk internal tOk;
    address internal tRevert;
    address internal tBurn;
    address internal tBomb;
    TReenter internal tReenter;

    // context for _afterProbe
    Case internal cur;
    uint256 internal curTargetBal;
    uint256 internal curCdmBal;
    uint256 public violations; // counted, never silently dropped
    string internal violationLog;

    function setUp() public {
        fork = vm.envOr("U21_FORK", string("l1"));
        vm.createSelectFork(fork);

        // A real game that is ALREADY claim-valid on this fork (no warp, no game interaction).
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            if (ASR.isGameClaimValid(f.game)) {
                validGame = f.game;
                break;
            }
        }
        require(validGame != address(0), "no claim-valid real game on this fork");
        injectTs = IGame(validGame).createdAt() + 1;
        require(block.timestamp - injectTs > PORTAL.proofMaturityDelaySeconds(), "game too young for injection");

        tOk = new TOk();
        tRevert = address(new TRevert());
        tBurn = address(new TBurn());
        tBomb = address(new TBomb());
        tReenter = new TReenter();

        _buildCases();
    }

    // ---------------------------------------------------------------------------------------
    // case construction
    // ---------------------------------------------------------------------------------------

    function _targetFor(Kind k, uint256 salt) internal returns (address t) {
        if (k == Kind.OK) return address(tOk);
        if (k == Kind.REVERT) return tRevert;
        if (k == Kind.BURN) return tBurn;
        if (k == Kind.BOMB) return tBomb;
        if (k == Kind.REENTER) return address(tReenter);
        t = address(uint160(uint256(keccak256(abi.encode("u21.lane11.target", uint256(k), salt)))));
        if (k == Kind.EMPTY) {
            require(t.codehash == bytes32(0), "EMPTY target exists on fork");
        } else if (k == Kind.EOA) {
            vm.deal(t, 1);
            require(t.codehash == keccak256(""), "EOA target codehash");
        } else if (k == Kind.DELEG_BURN) {
            vm.etch(t, abi.encodePacked(hex"ef0100", tBurn));
        } else if (k == Kind.DELEG_OK) {
            vm.etch(t, abi.encodePacked(hex"ef0100", address(tOk)));
        }
    }

    function _l2BaseGas(Formula f, uint256 len, uint256 minGas) internal pure returns (uint256) {
        uint256 dyn = (minGas * 64) / 63;
        if (f == Formula.LEGACY_L2) return 285_000 + dyn + 16 * len;
        uint256 exec = (f == Formula.CURRENT_L2 ? 285_000 : 390_000) + dyn;
        uint256 total = len + 260;
        uint256 a = exec + total * 16;
        uint256 b = total * 40;
        return 21_000 + (a > b ? a : b);
    }

    function _build(Case memory c, uint256 idx) internal pure returns (WithdrawalTransaction memory wd) {
        bytes memory payload = new bytes(c.len);
        for (uint256 i; i < c.len; i += 32) {
            // non-zero filler, cheap to generate
            assembly {
                mstore(add(add(payload, 32), i), 0xa5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5)
            }
        }
        if (c.messenger) {
            uint256 nonce = (uint256(1) << 240) | (uint256(0xb16b00b5) << 64) | idx;
            wd.nonce = (uint256(1) << 240) | (uint256(0xfeed) << 64) | idx;
            wd.sender = 0x4200000000000000000000000000000000000007;
            wd.target = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
            wd.value = c.value;
            wd.gasLimit = _l2BaseGas(c.formula, c.len, c.minGas);
            wd.data = abi.encodeCall(
                IMessenger.relayMessage, (nonce, INNER_SENDER, c.target, c.value, c.minGas, payload)
            );
        } else {
            wd.nonce = (uint256(1) << 240) | (uint256(0xfeed) << 64) | idx;
            wd.sender = PLAIN_L2_SENDER;
            wd.target = c.target;
            wd.value = c.value;
            wd.gasLimit = c.minGas;
            wd.data = payload;
        }
    }

    function _add(bool messenger, Kind k, uint256 len, uint256 minGas, uint256 value, Formula f) internal {
        Case memory c;
        c.messenger = messenger;
        c.kind = k;
        c.len = len;
        c.minGas = minGas;
        c.value = value;
        c.formula = f;
        c.target = _targetFor(k, cases.length);
        WithdrawalTransaction memory wd = _build(c, cases.length);
        c.hash = hashWithdrawal(wd);
        // HARNESS-ONLY: inject provenWithdrawals[hash][SUBMITTER] = (validGame, injectTs).
        bytes32 slot = keccak256(abi.encode(SUBMITTER, keccak256(abi.encode(c.hash, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((uint256(injectTs) << 160) | uint256(uint160(validGame))));
        cases.push(c);
    }

    function _buildCases() internal {
        uint256 set = vm.envOr("U21_SET", uint256(0)); // 0 = all, 1 = A, 2 = B, 3 = P
        if (set == 0 || set == 1) {
            // Set A: target behaviours through the messenger.
            for (uint256 k; k <= uint256(Kind.DELEG_OK); k++) {
                for (uint256 m; m < 2; m++) {
                    for (uint256 v; v < 2; v++) {
                        _add(true, Kind(k), 100, m == 0 ? 0 : 200_000, v == 0 ? 0 : 1 ether, Formula.CURRENT_L2);
                    }
                }
            }
            _add(true, Kind.OK, 164, 0, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.BURN, 164, 0, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.OK, 164, 200_000, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.BURN, 164, 200_000, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.EMPTY, 0, 0, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.BURN, 100, 200_000, 1 ether, Formula.V9_L2);
            _add(true, Kind.EMPTY, 0, 0, 1 ether, Formula.V9_L2);
        }
        if (set == 0 || set == 2) {
            // Set B: inner message size sweep.
            uint24[6] memory lens = [uint24(0), 1_000, 10_000, 50_000, 120_000, 300_000];
            for (uint256 l; l < lens.length; l++) {
                for (uint256 m; m < 2; m++) {
                    for (uint256 f; f < 2; f++) {
                        _add(true, Kind.OK, lens[l], m == 0 ? 30_000 : 1_000_000, 0, Formula(f));
                        _add(true, Kind.BURN, lens[l], m == 0 ? 0 : 1_000_000, 0, Formula(f));
                    }
                }
            }
        }
        if (set == 0 || set == 3) {
            // Set P: plain (non-messenger) withdrawals straight to the target.
            for (uint256 g; g < 2; g++) {
                uint256 gl = g == 0 ? 0 : 100_000;
                _add(false, Kind.EMPTY, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.EMPTY, 0, gl, 0, Formula.CURRENT_L2);
                _add(false, Kind.EOA, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.OK, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.REVERT, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.BURN, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.DELEG_OK, 0, gl, 1 ether, Formula.CURRENT_L2);
                _add(false, Kind.REENTER, 0, gl, 1 ether, Formula.CURRENT_L2);
            }
        }
        if (set == 4) {
            // Set 4: fine size sweep with targets that consume ALL forwarded gas / revert.
            for (uint256 len = 15_000; len <= 115_000; len += 10_000) {
                for (uint256 f; f < 2; f++) {
                    _add(true, Kind.BURN, len, 0, 0, Formula(f));
                }
            }
            _add(true, Kind.BURN, 50_000, 0, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.BURN, 50_000, 500_000, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.REVERT, 50_000, 0, 1 ether, Formula.LEGACY_L2);
            _add(true, Kind.OK, 50_000, 0, 1 ether, Formula.LEGACY_L2); // TOk needs ~44k gas: minGas 0 under-specified
        }
        // Arm the re-entrant target with (a) a finalize of ANOTHER injected mature withdrawal and
        // (b) is filled per-case in the test body.
    }

    // ---------------------------------------------------------------------------------------
    // per-probe assertions (post-state still live)
    // ---------------------------------------------------------------------------------------

    function _violation(string memory what, uint256 gas_) internal {
        violations++;
        if (violations <= 40) {
            violationLog = string.concat(violationLog, what, "@", vm.toString(gas_), ";");
        }
    }

    function _afterProbe(Probe memory p, Class c) internal override {
        Case memory k = cur;
        if (c == Class.REVERTED) return;
        uint256 gotTarget = k.target.balance - curTargetBal;
        if (k.messenger) {
            uint256 cdmHeld = address(L1CDM).balance - curCdmBal;
            if (c == Class.FINALIZED_RELAYED) {
                // delivered: the inner target got exactly the value, messenger kept nothing
                if (k.kind != Kind.REENTER && gotTarget != k.value) _violation("relayed-but-target-not-paid", probeGas);
                if (k.kind != Kind.REENTER && cdmHeld != 0) _violation("relayed-but-messenger-holds-eth", probeGas);
                // minGasLimit guarantee as observed by the target
                if ((k.kind == Kind.OK || k.kind == Kind.DELEG_OK) && TOk(payable(k.target)).seenGas() + 5 < k.minGas) {
                    _violation("target-saw-less-than-minGasLimit", probeGas);
                }
            } else if (c == Class.FINALIZED_FAILEDMSG) {
                // replayable: the messenger must hold the value for the replay
                if (cdmHeld != k.value) _violation("failed-but-messenger-does-not-hold-value", probeGas);
                if (gotTarget != 0) _violation("failed-but-target-paid", probeGas);
            } else if (c == Class.FINALIZED_NEITHER) {
                if (cdmHeld != 0 || gotTarget != 0) _violation("neither-but-eth-moved", probeGas);
            }
            if (k.kind == Kind.REENTER && tReenter.calls() > 0 && tReenter.mask() != 0) {
                _violation("reentrant-call-succeeded", tReenter.mask());
            }
        } else {
            if (c == Class.FINALIZED_PLAIN_OK && gotTarget != k.value) _violation("plain-ok-but-target-not-paid", probeGas);
            if (c == Class.FINALIZED_PLAIN_FAIL && gotTarget != 0) _violation("plain-fail-but-target-paid", probeGas);
            if (k.kind == Kind.REENTER && tReenter.calls() > 0 && tReenter.mask() != 0) {
                _violation("reentrant-call-succeeded", tReenter.mask());
            }
        }
        p;
    }

    function _classifyCase(Probe memory p, uint256 g) internal returns (Class c) {
        (c,,) = _classify(p, g);
    }

    // ---------------------------------------------------------------------------------------
    // tests
    // ---------------------------------------------------------------------------------------

    function _probeFor(uint256 i) internal returns (Probe memory p) {
        Case memory c = cases[i];
        p.wd = _build(c, i);
        p.hash = c.hash;
        p.submitter = SUBMITTER;
        p.messenger = c.messenger;
        require(hashWithdrawal(p.wd) == c.hash, "case rebuild mismatch");
        cur = c;
        curTargetBal = c.target.balance;
        curCdmBal = address(L1CDM).balance;
        if (c.kind == Kind.REENTER) {
            // other = case (i+1) % n  (always another injected, mature withdrawal)
            uint256 j = (i + 1) % cases.length;
            WithdrawalTransaction memory other = _build(cases[j], j);
            tReenter.arm(
                abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (other, SUBMITTER)),
                c.messenger ? p.wd.data : bytes("")
            );
        }
    }

    function _label(Case memory c) internal pure returns (string memory) {
        return string.concat(
            '"messenger":', c.messenger ? "true" : "false", ',"kind":', vm.toString(uint256(c.kind)),
            ',"len":', vm.toString(c.len), ',"minGas":', vm.toString(c.minGas),
            ',"value":"', vm.toString(c.value), '","formula":', vm.toString(uint256(c.formula))
        );
    }

    /// @notice Boundary scan of every injected case; writes evidence/injected-gas-<fork><tag>.json
    function test_injected_gas_boundaries() public {
        uint256 dense = vm.envOr("U21_DENSE", uint256(300));
        uint256 from = vm.envOr("U21_FROM", uint256(0));
        uint256 to = vm.envOr("U21_TO", cases.length);
        if (to > cases.length) to = cases.length;
        string memory rows = "";
        uint256 neitherCases;
        for (uint256 i = from; i < to; i++) {
            Probe memory p = _probeFor(i);
            uint256 maxGas = p.wd.gasLimit * 2 + 3_000_000;
            Scan memory s = _scan(p, dense, 9973, maxGas);
            if (s.count[3] > 0) neitherCases++;
            rows = string.concat(
                rows,
                bytes(rows).length == 0 ? "" : ",\n",
                '{"case":', vm.toString(i), ",", _label(cases[i]),
                ',"wdGasLimit":', vm.toString(p.wd.gasLimit), ",", _scanJson(s), "}"
            );
        }
        vm.writeFile(
            string.concat("evidence/injected-gas-", fork, vm.envOr("U21_TAG", string("")), ".json"),
            string.concat('{"violations":', vm.toString(violations), ',"violationLog":"', violationLog, '","rows":[\n', rows, "\n]}\n")
        );
        emit log_named_uint("cases", to - from);
        emit log_named_uint("cases with FINALIZED_NEITHER reachable", neitherCases);
        emit log_named_uint("per-probe violations", violations);
        emit log_string(violationLog);
        if (keccak256(bytes(fork)) == keccak256("l1")) {
            assertEq(neitherCases, 0, "v9: FINALIZED_NEITHER reachable");
        }
        assertEq(violations, 0, "per-probe invariant violations");
    }

    /// @notice Fuzz: random case, random gas. v9 must never produce FINALIZED_NEITHER.
    function testFuzz_injected_gas_class(uint256 seed, uint256 gas_) public {
        uint256 i = seed % cases.length;
        Probe memory p = _probeFor(i);
        gas_ = bound(gas_, 0, p.wd.gasLimit * 2 + 1_500_000);
        Class c = _classifyCase(p, gas_);
        assertEq(violations, 0, violationLog);
        if (keccak256(bytes(fork)) == keccak256("l1")) {
            assertTrue(c != Class.FINALIZED_NEITHER, "v9: finalized with neither mapping recorded");
        }
    }
}
