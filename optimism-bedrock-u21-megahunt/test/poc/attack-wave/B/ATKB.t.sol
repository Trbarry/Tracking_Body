// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

// ATK-B — forced messenger failure (L1CDM re-entry branch) x delayed replay, on deployed v9
// bytecode (OP Mainnet, L1 fork @ 26433900).
//
// HARNESS-ONLY: the ATTACKER's own failed message is created by injecting a provenWithdrawals entry
// for the attacker's own L2CDM withdrawal against a real claim-valid game (vm.store), exactly as in
// PASS A NestedReplay.t.sol. In production the attacker sends that message from L2 himself and waits
// for maturity; it is his own message to his own contract. Every VICTIM object is a real mainnet
// withdrawal driven through public functions only. No privileged prank except the documented planned
// OPCMv2.migrate (test_E5) executed as the Safe, which ATTACK_CONTEXT allows for setup.

interface IERC20b {
    function balanceOf(address) external view returns (uint256);
}

interface IBridge {
    function deposits(address, address) external view returns (uint256);
}

contract Attacker {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    address[] public tos;
    bytes[] public cds;
    uint256[] public gases;
    bool public armed;
    bool[] public oks;

    function arm(address[] calldata t, bytes[] calldata c, uint256[] calldata g) external {
        delete tos;
        delete cds;
        delete gases;
        delete oks;
        for (uint256 i; i < t.length; i++) {
            tos.push(t[i]);
            cds.push(c[i]);
            gases.push(g[i]);
        }
        armed = true;
    }

    function okAt(uint256 i) external view returns (bool) {
        return oks[i];
    }

    fallback() external payable {
        require(armed, "not armed"); // first delivery fails => attacker's message becomes replayable
        armed = false; // one shot per arm()
        for (uint256 i; i < tos.length; i++) {
            (bool ok,) = gases[i] == 0 ? tos[i].call(cds[i]) : tos[i].call{ gas: gases[i] }(cds[i]);
            oks.push(ok);
        }
    }
}

struct MigDGConfig {
    bool enabled;
    uint256 initBond;
    uint32 gameType;
    bytes gameArgs;
}

struct MigProposal {
    bytes32 root;
    uint256 l2SequenceNumber;
}

struct MigInput {
    address[] chainSystemConfigs;
    MigDGConfig[] disputeGameConfigs;
    MigProposal startingAnchorRoot;
    uint32 startingRespectedGameType;
}

interface IOPCMv2 {
    function migrate(MigInput calldata) external;
}

contract ATKBTest is U21FixtureBase {
    address internal constant SUB = address(0x5B17);
    address internal constant ATTACKER_L2 = address(0xA77);
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CRV_L2 = 0x0994206dfE8De6Ec6920FF4D779B0d950605Fb53;
    Attacker internal attacker;
    uint256 internal nextNonce = 0xa77ac4;

    function setUp() public {
        vm.createSelectFork("l1");
        attacker = new Attacker();
    }

    // ---------------------------------------------------------------- helpers
    function _attackerMsg(uint256 n) internal view returns (WithdrawalTransaction memory awd) {
        awd.nonce = (uint256(1) << 240) | n;
        awd.sender = L2CDM;
        awd.target = address(L1CDM);
        awd.value = 0;
        awd.data = abi.encodeCall(IMessenger.relayMessage, ((uint256(1) << 240) | n, ATTACKER_L2, address(attacker), 0, 0, bytes("")));
        awd.gasLimit = 310_160;
    }

    /// Attacker's own message, delivered once (reverts in target) => failedMessages. Harness: injected proof.
    function _makeAttackerFailedMessage(address game) internal returns (uint256 n) {
        n = nextNonce++;
        WithdrawalTransaction memory awd = _attackerMsg(n);
        bytes32 h = hashWithdrawal(awd);
        bytes32 slot = keccak256(abi.encode(SUB, keccak256(abi.encode(h, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((uint256(IGame(game).createdAt() + 1) << 160) | uint256(uint160(game))));
        PORTAL.finalizeWithdrawalTransactionExternalProof(awd, SUB);
        assertTrue(L1CDM.failedMessages(keccak256(awd.data)), "attacker message failed");
    }

    function _replayAttacker(uint256 n) internal {
        vm.prank(address(0xBAD), address(0xBAD));
        L1CDM.relayMessage((uint256(1) << 240) | n, ATTACKER_L2, address(attacker), 0, 0, bytes(""));
    }

    function _one(address t, bytes memory c, uint256 g) internal {
        address[] memory a = new address[](1);
        bytes[] memory b = new bytes[](1);
        uint256[] memory gg = new uint256[](1);
        a[0] = t;
        b[0] = c;
        gg[0] = g;
        attacker.arm(a, b, gg);
    }

    function _replayCd(Inner memory i) internal pure returns (bytes memory) {
        return abi.encodeCall(IMessenger.relayMessage, (i.nonce, i.sender, i.target, i.value, i.minGasLimit, i.message));
    }

    function _forceFail(Fixture memory v) internal {
        uint256 n = _makeAttackerFailedMessage(v.game);
        _one(address(PORTAL), abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (v.wd, v.proofSubmitter)), 0);
        _replayAttacker(n);
        assertTrue(attacker.okAt(0), "nested finalize ok");
        assertTrue(PORTAL.finalizedWithdrawals(v.hash), "victim finalized in portal");
        assertTrue(L1CDM.failedMessages(messageHash(v.wd)), "victim forced into failedMessages");
        assertFalse(L1CDM.successfulMessages(messageHash(v.wd)), "victim not delivered");
    }

    function _erc20(Fixture memory f) internal pure returns (address l1, address l2, address to, uint256 amt) {
        Inner memory i = decodeInner(f.wd);
        bytes memory m = i.message;
        bytes memory body = new bytes(m.length - 4);
        for (uint256 k = 4; k < m.length; k++) body[k - 4] = m[k];
        address from;
        bytes memory extra;
        (l1, l2, from, to, amt, extra) = abi.decode(body, (address, address, address, address, uint256, bytes));
    }

    // ---------------------------------------------------------------- E1: census replay under v9
    /// Every OP Mainnet message still in failedMessages (and not successful) at 26433900, replayed by
    /// an unrelated EOA with 15M gas under v9 code. Records which are still deliverable.
    function test_E1_census_replay_stillFailed_underV9() public {
        string memory j = vm.readFile("evidence/still-failed-op.json");
        uint256 delivered;
        for (uint256 k; k < 15; k++) {
            string memory p = string.concat("[", vm.toString(k), "]");
            bytes32 h = vm.parseJsonBytes32(j, string.concat(p, ".hash"));
            bytes memory cd = vm.parseJsonBytes(j, string.concat(p, ".calldata"));
            assertEq(keccak256(cd), h, "calldata hashes to msgHash");
            assertTrue(L1CDM.failedMessages(h) && !L1CDM.successfulMessages(h), "still failed at pin");
            uint256 snap = vm.snapshotState();
            vm.prank(address(0xCAFE), address(0xCAFE));
            (bool ok, bytes memory ret) = address(L1CDM).call{ gas: 15_000_000 }(cd);
            bool s = L1CDM.successfulMessages(h);
            if (s) delivered++;
            emit log_named_bytes32("msg", h);
            emit log_named_string("  outcome", !ok ? string.concat("REVERT ", string(ret)) : (s ? "DELIVERED" : "STILL_FAILED"));
            vm.revertToStateAndDelete(snap);
        }
        emit log_named_uint("delivered by a third-party replay under v9", delivered);
        assertEq(address(L1CDM).balance, 0, "L1CDM holds no ETH: no value-bearing failed message is pending");
    }

    // ---------------------------------------------------------------- E2: ERC20 ordering / replay
    /// Victim CRV withdrawal f5 forced into failed state; a later CRV withdrawal f6 of the same pair is
    /// finalized FIRST; attacker then tries every replay-blocking move; an honest replay still pays the
    /// victim exactly once. Checks L1StandardBridge.deposits accounting and token custody.
    uint256 internal e2dep0;
    uint256 internal e2bal0;
    uint256 internal e2br0;
    uint256 internal e2sum;
    address internal e2to;

    function test_E2_forcedFail_ERC20_ordering_and_replay_blocking() public {
        Fixture memory v = _loadFixture(5);
        Fixture memory o = _loadFixture(6);
        _e2pre(v, o);
        _forceFail(v);
        assertEq(IBridge(L1_STANDARD_BRIDGE).deposits(CRV, CRV_L2), e2dep0, "no accounting change on forced fail");
        assertEq(IERC20b(CRV).balanceOf(address(L1CDM)), 0);
        // another user's withdrawal of the same pair overtakes
        _finalizeAs(o, address(0x0717));
        assertTrue(L1CDM.successfulMessages(messageHash(o.wd)), "overtaking withdrawal delivered");
        _e2block(v);
        _e2honest(v);
    }

    function _e2pre(Fixture memory v, Fixture memory o) internal {
        (address l1, address l2, address to, uint256 amtV) = _erc20(v);
        (,, address toO, uint256 amtO) = _erc20(o);
        assertEq(l1, CRV);
        assertEq(l2, CRV_L2);
        assertEq(to, toO);
        PORTAL.checkWithdrawal(v.hash, v.proofSubmitter);
        PORTAL.checkWithdrawal(o.hash, o.proofSubmitter);
        e2to = to;
        e2sum = amtV + amtO;
        e2dep0 = IBridge(L1_STANDARD_BRIDGE).deposits(CRV, CRV_L2);
        e2bal0 = IERC20b(CRV).balanceOf(to);
        e2br0 = IERC20b(CRV).balanceOf(L1_STANDARD_BRIDGE);
    }

    function _e2block(Fixture memory v) internal {
        Inner memory iv = decodeInner(v.wd);
        bytes32 vh = messageHash(v.wd);
        // blocking attempt 1: replay with too little gas -> gate branch, stays failed (no revert, no loss)
        vm.prank(address(0xBAD), address(0xBAD));
        (bool ok1,) = address(L1CDM).call{ gas: 150_000 }(_replayCd(iv));
        assertTrue(ok1 && L1CDM.failedMessages(vh) && !L1CDM.successfulMessages(vh), "low-gas replay: still failed");
        // blocking attempt 2: replay victim from INSIDE the attacker's own replay (re-entry branch)
        uint256 n2 = _makeAttackerFailedMessage(v.game);
        _one(address(L1CDM), _replayCd(iv), 0);
        _replayAttacker(n2);
        assertTrue(attacker.okAt(0), "nested replay returns normally");
        assertTrue(L1CDM.failedMessages(vh) && !L1CDM.successfulMessages(vh), "nested replay: still failed");
        // blocking attempt 3: portal re-finalize path is closed for the victim
        vm.expectRevert();
        PORTAL.finalizeWithdrawalTransactionExternalProof(v.wd, v.proofSubmitter);
    }

    function _e2honest(Fixture memory v) internal {
        Inner memory iv = decodeInner(v.wd);
        vm.prank(address(0xCAFE), address(0xCAFE));
        L1CDM.relayMessage(iv.nonce, iv.sender, iv.target, iv.value, iv.minGasLimit, iv.message);
        assertTrue(L1CDM.successfulMessages(messageHash(v.wd)), "victim delivered by replay");
        assertEq(IERC20b(CRV).balanceOf(e2to) - e2bal0, e2sum, "recipient paid both, exactly once");
        assertEq(e2dep0 - IBridge(L1_STANDARD_BRIDGE).deposits(CRV, CRV_L2), e2sum, "deposits debited exactly");
        assertEq(e2br0 - IERC20b(CRV).balanceOf(L1_STANDARD_BRIDGE), e2sum, "bridge custody exact");
        vm.expectRevert();
        L1CDM.relayMessage(iv.nonce, iv.sender, iv.target, iv.value, iv.minGasLimit, iv.message);
    }

    // ---------------------------------------------------------------- E3: starvation band of the replay
    /// After the forced failure, can a third party pick a replay gas that passes the messenger gate but
    /// makes the target fail (leaving the message stuck, or worse)? Sweep 100k..400k (step 500).
    function test_E3_replay_gas_sweep_no_starvation_band() public {
        Fixture memory v = _loadFixture(5);
        _forceFail(v);
        Inner memory iv = decodeInner(v.wd);
        bytes32 vh = messageHash(v.wd);
        (,, address to, uint256 amt) = _erc20(v);
        uint256 bal0 = IERC20b(CRV).balanceOf(to);
        uint256 nFailed;
        uint256 nRevert;
        uint256 nDelivered;
        uint256 firstDeliver;
        uint256 failAboveThreshold;
        for (uint256 g = 300_000; g <= 800_000; g += 1_000) {
            uint256 snap = vm.snapshotState();
            vm.prank(address(0xBAD), address(0xBAD));
            (bool ok,) = address(L1CDM).call{ gas: g }(_replayCd(iv));
            bool s = L1CDM.successfulMessages(vh);
            if (!ok) {
                nRevert++;
            } else if (s) {
                nDelivered++;
                if (firstDeliver == 0) firstDeliver = g;
                assertEq(IERC20b(CRV).balanceOf(to) - bal0, amt, "delivered exactly");
            } else {
                nFailed++;
                if (firstDeliver != 0) failAboveThreshold++;
                assertTrue(L1CDM.failedMessages(vh), "still replayable");
                assertEq(IERC20b(CRV).balanceOf(to), bal0, "no partial effect");
            }
            vm.revertToStateAndDelete(snap);
        }
        emit log_named_uint("still failed (retryable)", nFailed);
        emit log_named_uint("reverted (retryable)", nRevert);
        emit log_named_uint("delivered", nDelivered);
        emit log_named_uint("first delivering call gas", firstDeliver);
        emit log_named_uint("non-delivered above the threshold", failAboveThreshold);
        assertEq(failAboveThreshold, 0, "monotone: no starvation band above the delivery threshold");
        assertGt(nDelivered, 0);
    }

    // ---------------------------------------------------------------- E4: ETH legacy path + parked ETH theft
    /// Victim ETH withdrawal f1 (legacy finalizeETHWithdrawal) forced to fail: ETH parked in L1CDM.
    /// Attacker tries to pull the parked ETH: (a) replay an own message with value that never failed,
    /// (b) own failed message re-encoded with value>0, (c) victim message with a different target.
    function test_E4_parked_ETH_not_capturable() public {
        Fixture memory v = _loadFixture(1);
        Inner memory iv = decodeInner(v.wd);
        uint256 cdm0 = address(L1CDM).balance;
        _forceFail(v);
        assertEq(address(L1CDM).balance - cdm0, v.wd.value, "value parked in L1CDM");

        uint256 n = nextNonce; // the attacker's next failed message (value 0)
        _makeAttackerFailedMessage(v.game);
        vm.startPrank(address(0xBAD), address(0xBAD));
        // (b) same nonce/sender/target but value = parked amount -> different hash, not failed
        vm.expectRevert("CrossDomainMessenger: message cannot be replayed");
        L1CDM.relayMessage((uint256(1) << 240) | n, ATTACKER_L2, address(attacker), v.wd.value, 0, bytes(""));
        // (c) victim's message redirected to the attacker -> different hash
        vm.expectRevert("CrossDomainMessenger: message cannot be replayed");
        L1CDM.relayMessage(iv.nonce, iv.sender, address(attacker), iv.value, iv.minGasLimit, iv.message);
        // (a) sending value with a replay is refused
        vm.deal(address(0xBAD), 1 ether);
        vm.expectRevert("CrossDomainMessenger: value must be zero unless message is from a system address");
        L1CDM.relayMessage{ value: 1 }(iv.nonce, iv.sender, iv.target, iv.value, iv.minGasLimit, iv.message);
        vm.stopPrank();
        assertEq(address(L1CDM).balance - cdm0, v.wd.value, "parked value untouched");

        // note: the real recipient 0x0fC0..b1E2 is an EIP-7702-delegated EOA that forwards ETH to
        // 0x810b0cFd..b752, so value delivery is measured on (recipient + forwarder) and on the L1CDM.
        (,, address to,,) = _legacyEth(iv.message);
        address fwd = 0x810b0cFd3eFC3006e8819a2f96225Be6A228b752;
        uint256 b0 = to.balance + fwd.balance;
        vm.prank(address(0xCAFE), address(0xCAFE));
        L1CDM.relayMessage(iv.nonce, iv.sender, iv.target, iv.value, iv.minGasLimit, iv.message);
        assertTrue(L1CDM.successfulMessages(messageHash(v.wd)), "victim delivered");
        assertEq(to.balance + fwd.balance - b0, v.wd.value, "victim recipient (+its 7702 forwarder) paid exactly");
        assertEq(address(L1CDM).balance, cdm0, "L1CDM drained back to 0");
    }

    function _legacyEth(bytes memory m) internal pure returns (address from, address x, address to, uint256 amt, bytes memory e) {
        bytes memory body = new bytes(m.length - 4);
        for (uint256 k = 4; k < m.length; k++) body[k - 4] = m[k];
        (from, to, amt, e) = abi.decode(body, (address, address, uint256, bytes));
        x = address(0);
    }

    // ---------------------------------------------------------------- E5: forced fail, then planned migrate, then replay
    /// The value sits in L1CDM (not in the lockbox) across the planned OPCMv2.migrate (OP + Unichain,
    /// shared lockbox). Does the migration strand or sweep it, or change replayability?
    function test_E5_forcedFail_then_migrate_then_replay() public {
        Fixture memory v = _loadFixture(1);
        Fixture memory v2 = _loadFixture(7);
        Inner memory iv = decodeInner(v.wd);
        Inner memory iv2 = decodeInner(v2.wd);
        _forceFail(v);
        _forceFail(v2);
        uint256 parked = address(L1CDM).balance;
        assertEq(parked, v.wd.value);
        (,, address to2, uint256 amt2) = _erc20(v2);
        uint256 t0 = IERC20b(CRV).balanceOf(to2);

        _migrate();
        assertEq(address(L1CDM).balance, parked, "migrate leaves parked ETH in L1CDM");
        assertFalse(L1CDM.paused(), "messenger not paused after migrate");

        (,, address to,,) = _legacyEth(iv.message);
        address fwd = 0x810b0cFd3eFC3006e8819a2f96225Be6A228b752; // 7702 forwarder of the recipient
        uint256 b0 = to.balance + fwd.balance;
        vm.startPrank(address(0xCAFE), address(0xCAFE));
        L1CDM.relayMessage(iv.nonce, iv.sender, iv.target, iv.value, iv.minGasLimit, iv.message);
        L1CDM.relayMessage(iv2.nonce, iv2.sender, iv2.target, iv2.value, iv2.minGasLimit, iv2.message);
        vm.stopPrank();
        assertTrue(L1CDM.successfulMessages(messageHash(v.wd)) && L1CDM.successfulMessages(messageHash(v2.wd)));
        assertEq(to.balance + fwd.balance - b0, v.wd.value, "ETH victim paid after migrate");
        assertEq(IERC20b(CRV).balanceOf(to2) - t0, amt2, "ERC20 victim paid after migrate");
        assertEq(address(L1CDM).balance, 0);
    }

    function _migrate() internal {
        address[] memory scs = new address[](2);
        scs[0] = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
        scs[1] = 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6;
        MigDGConfig[] memory gcs = new MigDGConfig[](1);
        gcs[0] = MigDGConfig({
            enabled: true,
            initBond: 0.08 ether,
            gameType: 9,
            gameArgs: abi.encode(bytes32(0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9))
        });
        MigInput memory input = MigInput({
            chainSystemConfigs: scs,
            disputeGameConfigs: gcs,
            startingAnchorRoot: MigProposal({ root: keccak256("atkb-starting-super-root"), l2SequenceNumber: block.timestamp - 1 }),
            startingRespectedGameType: 9
        });
        vm.prank(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A, true);
        (bool ok, bytes memory ret) =
            address(0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f).delegatecall(abi.encodeCall(IOPCMv2.migrate, (input)));
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
    }
}
