// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory _tx, address _proofSubmitter) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function anchorStateRegistry() external view returns (address);
    function version() external view returns (string memory);
}

interface ICDM {
    function relayMessage(uint256, address, address, uint256, uint256, bytes memory) external payable;
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function baseGas(bytes memory, uint32) external view returns (uint64);
    function version() external view returns (string memory);
    function RELAY_RESERVED_GAS() external view returns (uint64);
}

interface IASRm {
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
}

interface IG {
    function createdAt() external view returns (uint64);
}

contract GasBurner {
    uint256 public sink;

    fallback() external payable {
        // burn everything that was forwarded
        while (true) {
            sink++;
        }
    }
}

contract GasReporter {
    uint256 public lastGas;

    fallback() external payable {
        lastGas = gasleft();
    }
}

/// Cross-version relay budget: L2CrossDomainMessenger 2.2.1 (live on OP Mainnet, no L2 hardfork in U21)
/// computes the withdrawal gasLimit with the OLD L1 relay budget (reserved 40k + buffer 5k), while the
/// U21 L1CrossDomainMessenger 2.13.0 relays with reserved 135k + buffer 15k.
contract MessengerGasCrossVersionTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ICDM constant L1CDM = ICDM(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant RELAYER = address(0xBEEF0001);

    // L2CDM 2.2.1 baseGas constants (read on the l2 fork: RELAY_RESERVED_GAS() = 40000, baseGas(0x,0) = 310160)
    function _oldBaseGas(bytes memory _message, uint32 _minGasLimit) internal pure returns (uint64) {
        uint64 executionGas = uint64(200_000 + 40_000 + 40_000 + 5_000 + ((uint256(_minGasLimit) * 64) / 63));
        uint64 totalMessageSize = uint64(_message.length + 260);
        uint64 a = executionGas + totalMessageSize * 16;
        uint64 b = totalMessageSize * 40;
        return 21_000 + (a > b ? a : b);
    }

    function _newBaseGas(bytes memory _message, uint32 _minGasLimit) internal pure returns (uint64) {
        uint64 executionGas = uint64(200_000 + 40_000 + 135_000 + 15_000 + ((uint256(_minGasLimit) * 64) / 63));
        uint64 totalMessageSize = uint64(_message.length + 260);
        uint64 a = executionGas + totalMessageSize * 16;
        uint64 b = totalMessageSize * 40;
        return 21_000 + (a > b ? a : b);
    }

    function _versionedHash(uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) internal pure returns (bytes32) {
        return keccak256(abi.encodeWithSignature("relayMessage(uint256,address,address,uint256,uint256,bytes)", n, s, t, v, g, m));
    }

    struct Case {
        address target;
        uint256 value;
        uint32 minGas;
        bytes message;
        uint64 gasLimit;
    }

    function _mk(Case memory c, uint256 salt) internal returns (WithdrawalTransaction memory w, bytes32 wh, bytes32 mh) {
        uint256 msgNonce = (uint256(1) << 240) | (900_000_000 + salt);
        address sender = address(0xA11CE);
        bytes memory data = abi.encodeWithSelector(ICDM.relayMessage.selector, msgNonce, sender, c.target, c.value, uint256(c.minGas), c.message);
        w = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | (800_000_000 + salt),
            sender: L2CDM,
            target: address(L1CDM),
            value: c.value,
            gasLimit: c.gasLimit,
            data: data
        });
        wh = keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
        mh = _versionedHash(msgNonce, sender, c.target, c.value, c.minGas, c.message);
        // SETUP (state production can already be in): register this withdrawal as proven > 7 days ago against
        // the current anchor game (a finalized, valid, respected game). This replaces only the Merkle proof step.
        address game = IASRm(PORTAL.anchorStateRegistry()).anchorGame();
        require(IASRm(PORTAL.anchorStateRegistry()).isGameClaimValid(game), "anchor game not valid");
        uint256 ts = block.timestamp - 604_801;
        require(ts > IG(game).createdAt(), "proof ts must be after game creation");
        bytes32 slot = keccak256(abi.encode(RELAYER, keccak256(abi.encode(wh, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
    }

    // 0 = reverted, 1 = relayed OK, 2 = recorded failed (replayable), 3 = finalized with NO record (loss)
    function _try(Case memory c, uint256 salt, uint256 gasGiven) internal returns (uint8 outcome, bytes memory ret) {
        uint256 snap = vm.snapshotState();
        (WithdrawalTransaction memory w, bytes32 wh, bytes32 mh) = _mk(c, salt);
        vm.prank(RELAYER, RELAYER);
        bool ok;
        (ok, ret) = address(PORTAL).call{ gas: gasGiven }(
            abi.encodeWithSelector(IPortal.finalizeWithdrawalTransactionExternalProof.selector, w, RELAYER)
        );
        if (!ok) outcome = 0;
        else if (L1CDM.successfulMessages(mh)) outcome = 1;
        else if (L1CDM.failedMessages(mh)) outcome = 2;
        else outcome = 3;
        if (ok) require(PORTAL.finalizedWithdrawals(wh), "not finalized?");
        vm.revertToState(snap);
    }

    function _scan(string memory label, Case memory c, uint256 salt) internal returns (uint256 firstNonRevert, uint256 firstRelayed) {
        uint256 losses;
        uint256 failedCount;
        uint256 lastFailed;
        // coarse-to-fine scan of the gas given to finalizeWithdrawalTransaction
        for (uint256 g = 300_000; g <= scanMax + uint256(c.minGas) * 2; g += scanStep) {
            (uint8 o,) = _try(c, salt, g);
            if (o != 0 && firstNonRevert == 0) firstNonRevert = g;
            if (o == 1 && firstRelayed == 0) firstRelayed = g;
            if (o == 2) {
                failedCount++;
                lastFailed = g;
            }
            if (o == 3) losses++;
        }
        emit log_string(label);
        emit log_named_uint("  withdrawal gasLimit", c.gasLimit);
        emit log_named_uint("  first gas where finalize does not revert", firstNonRevert);
        emit log_named_uint("  first gas where message is relayed OK", firstRelayed);
        emit log_named_uint("  samples recorded as FAILED (replayable)", failedCount);
        emit log_named_uint("  last gas recorded FAILED", lastFailed);
        emit log_named_uint("  samples finalized with no record (LOSS)", losses);
        assertEq(losses, 0, "finalized without record");
    }

    uint256 scanMax = 1_000_000;
    uint256 scanStep = 2_000;

    function setUp() public {
        // `l1` = shared anvil pinned at 26433900. ALT_RPC (optional) reads the same block straight from an
        // archive node when the shared anvil's upstream is throttled (passive reads only).
        string memory alt = vm.envOr("ALT_RPC", string(""));
        if (bytes(alt).length != 0) vm.createSelectFork(alt, 26433900);
        else vm.createSelectFork("l1");
        assertEq(L1CDM.version(), "2.13.0");
        assertEq(PORTAL.version(), "6.1.0");
    }

    /// ETH sent through the messenger to a fresh (non-existent) L1 account, minGasLimit 0, old L2 budget.
    function test_oldBudget_valueToNewAccount() public {
        address fresh = address(uint160(uint256(keccak256("lane10 fresh eoa"))));
        assertEq(fresh.codehash, bytes32(0));
        Case memory c = Case({ target: fresh, value: 1 ether, minGas: 0, message: "", gasLimit: _oldBaseGas("", 0) });
        assertEq(c.gasLimit, 310_160);
        _scan("old L2 budget, 1 ETH to new account, minGas 0", c, 1);
        c.gasLimit = _newBaseGas("", 0);
        assertEq(c.gasLimit, 415_160);
        _scan("new (v9 L2CDM 2.4.0) budget, 1 ETH to new account, minGas 0", c, 2);
    }

    /// Target that burns all forwarded gas: the relay must record the failure for every gas amount.
    function test_oldBudget_gasBurningTarget_minGas0() public {
        scanMax = 800_000;
        scanStep = 3_000;
        GasBurner b = new GasBurner();
        Case memory c = Case({ target: address(b), value: 1 ether, minGas: 0, message: "", gasLimit: _oldBaseGas("", 0) });
        _scan("old L2 budget, gas-burning target, 1 ETH, minGas 0", c, 3);
    }

    function test_oldBudget_gasBurningTarget_minGas200k() public {
        scanMax = 600_000;
        scanStep = 4_000;
        GasBurner b = new GasBurner();
        Case memory c =
            Case({ target: address(b), value: 1 ether, minGas: 200_000, message: "", gasLimit: _oldBaseGas("", 200_000) });
        _scan("old L2 budget, gas-burning target, 1 ETH, minGas 200k", c, 4);
    }

    function test_oldBudget_gasBurningTarget_bigMessage() public {
        scanMax = 1_100_000;
        scanStep = 6_000;
        GasBurner b = new GasBurner();
        bytes memory m = new bytes(20_000);
        Case memory c = Case({ target: address(b), value: 1 ether, minGas: 100_000, message: m, gasLimit: _oldBaseGas(m, 100_000) });
        _scan("old L2 budget, gas-burning target, 20kB message, minGas 100k", c, 5);
    }

    /// The target must always receive at least minGasLimit when the message is relayed.
    function test_oldBudget_targetGetsMinGas() public {
        GasReporter r = new GasReporter();
        uint32 minGas = 500_000;
        Case memory c = Case({ target: address(r), value: 0, minGas: minGas, message: "", gasLimit: _oldBaseGas("", minGas) });
        uint256 minSeen = type(uint256).max;
        uint256 firstOk;
        for (uint256 g = 400_000; g <= 1_600_000; g += 1_000) {
            uint256 snap = vm.snapshotState();
            (WithdrawalTransaction memory w,, bytes32 mh) = _mk(c, 6);
            vm.prank(RELAYER, RELAYER);
            (bool ok,) = address(PORTAL).call{ gas: g }(
                abi.encodeWithSelector(IPortal.finalizeWithdrawalTransactionExternalProof.selector, w, RELAYER)
            );
            if (ok && L1CDM.successfulMessages(mh)) {
                if (firstOk == 0) firstOk = g;
                if (r.lastGas() < minSeen) minSeen = r.lastGas();
            }
            vm.revertToState(snap);
        }
        emit log_named_uint("first gas relayed OK", firstOk);
        emit log_named_uint("minimum gas observed inside target", minSeen);
        assertGe(minSeen, minGas, "target got less than minGasLimit");
    }
}
