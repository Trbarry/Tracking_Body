// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IL2Messenger {
    function version() external view returns (string memory);
    function baseGas(bytes memory message, uint32 minGasLimit) external pure returns (uint64);
    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external payable;
    function RELAY_CONSTANT_OVERHEAD() external view returns (uint64);
    function RELAY_CALL_OVERHEAD() external view returns (uint64);
    function RELAY_RESERVED_GAS() external view returns (uint64);
    function RELAY_GAS_CHECK_BUFFER() external view returns (uint64);
}

interface IL1Messenger {
    function version() external view returns (string memory);
    function relayMessage(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 minGasLimit,
        bytes calldata message
    ) external payable;
    function successfulMessages(bytes32 messageHash) external view returns (bool);
    function failedMessages(bytes32 messageHash) external view returns (bool);
}

interface IPortal {
    function finalizeWithdrawalTransactionExternalProof(
        WithdrawalTransaction calldata withdrawal,
        address proofSubmitter
    ) external;
    function finalizedWithdrawals(bytes32 withdrawalHash) external view returns (bool);
    function provenWithdrawals(bytes32 withdrawalHash, address proofSubmitter)
        external
        view
        returns (address disputeGameProxy, uint64 timestamp);
}

contract BurnAllGas {
    function burn() external pure {
        assembly {
            invalid()
        }
    }
}

contract GasCapCATKCTest is Test {
    uint256 internal constant L1_TX_GAS_CAP = 1 << 24;
    uint256 internal constant L2_TX_GAS_CAP = 1 << 24;

    address internal constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant VALID_GAME = 0x55A5CFd4270340b3822BB9D8eebdb450ac206f95;
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;

    address internal constant ATTACKER = address(0xa11ce);
    address internal constant MESSAGE_SENDER = address(0x515151);
    address internal constant PROOF_SUBMITTER = address(0x707070);
    address internal constant EXISTING_EOA = 0x1111111111111111111111111111111111111111;
    // keccak256("CATK-C-new-account") truncated to 20 bytes; nonce/balance/code are zero at block 26433900.
    address internal constant NEW_EOA = 0xb2eDE3e5C0cAe13eF1EBA58B223f3bfFC6F856e2;
    address internal constant BRIDGE_RECIPIENT = 0x3333333333333333333333333333333333333333;

    uint256 internal constant VERSIONED_NONCE = (uint256(1) << 240) | 0x4341544b43;
    uint64 internal constant PROOF_TIMESTAMP = 1_794_299_940; // valid game createdAt + 1
    uint256 internal constant FAILED_MESSAGES_SLOT = 206;
    uint256 internal constant PROVEN_WITHDRAWALS_SLOT = 57;

    BurnAllGas internal burner;

    function setUp() public {
        vm.createSelectFork("l1");
        burner = new BurnAllGas();
    }

    function test_liveConstantsAndL2AcceptsExtremeMetadata() public {
        vm.createSelectFork("l2");

        IL2Messenger messenger = IL2Messenger(L2_MESSENGER);
        assertEq(messenger.version(), "2.2.1");
        assertEq(messenger.RELAY_CONSTANT_OVERHEAD(), 200_000);
        assertEq(messenger.RELAY_CALL_OVERHEAD(), 40_000);
        assertEq(messenger.RELAY_RESERVED_GAS(), 40_000);
        assertEq(messenger.RELAY_GAS_CHECK_BUFFER(), 5_000);
        assertEq(messenger.baseGas(hex"", 0), 310_160);

        uint64 extremeBaseGas = messenger.baseGas(hex"", type(uint32).max);
        assertEq(extremeBaseGas, _liveBaseGas(0, type(uint32).max));
        assertGt(extremeBaseGas, L1_TX_GAS_CAP);

        bytes memory callData = abi.encodeCall(IL2Messenger.sendMessage, (EXISTING_EOA, bytes(""), type(uint32).max));
        vm.prank(ATTACKER, ATTACKER);
        (bool ok,) = L2_MESSENGER.call{gas: 2_000_000}(callData);
        assertTrue(ok, "live L2 messenger rejected uint32 max minGasLimit");

        emit log_named_uint("extreme L2 withdrawal gasLimit", extremeBaseGas);
    }

    function test_largeZeroPayloadRejectedByL2TransactionCap() public {
        vm.createSelectFork("l2");

        uint256 messageLength = 400_000;
        bytes memory message = new bytes(messageLength);
        bytes memory callData = abi.encodeCall(IL2Messenger.sendMessage, (EXISTING_EOA, message, uint32(0)));
        (uint256 standardIntrinsic, uint256 floorIntrinsic) = _intrinsic(callData);
        assertLt(floorIntrinsic, L2_TX_GAS_CAP);

        uint256 entryBudget = L2_TX_GAS_CAP - standardIntrinsic;
        uint256 gasBefore = gasleft();
        vm.prank(ATTACKER, ATTACKER);
        (bool ok,) = L2_MESSENGER.call{gas: entryBudget}(callData);
        uint256 harnessMeasuredExecution = gasBefore - gasleft();

        assertFalse(ok, "400k zero-byte message unexpectedly fit the live L2 transaction cap");
        assertEq(IL2Messenger(L2_MESSENGER).baseGas(message, 0), _liveBaseGas(messageLength, 0));
        assertEq(_liveBaseGas(messageLength, 0), 16_031_400);

        emit log_named_uint("L2 send calldata bytes", callData.length);
        emit log_named_uint("L2 calldata floor", floorIntrinsic);
        emit log_named_uint("L2 harness execution incl CALL", harnessMeasuredExecution);
        emit log_named_uint("withdrawal gasLimit for 400k message", _liveBaseGas(messageLength, 0));
    }

    function test_largeCalldataBracketsL2LimitAndStillFitsDirectReplay() public {
        vm.createSelectFork("l2");
        (bool fit379200, uint256 floor379200, uint256 used379200) = this.probeL2ZeroMessage(379_200);
        (bool fit379232, uint256 floor379232, uint256 used379232) = this.probeL2ZeroMessage(379_232);
        assertTrue(fit379200, "379200-byte zero message should fit L2 cap");
        assertFalse(fit379232, "next 32-byte word unexpectedly fit L2 cap");

        vm.createSelectFork("l1");
        (bool replay379200, uint256 replayFloor379200) = this.probeDirectZeroMessage(379_200);
        assertTrue(replay379200, "largest demonstrated L2 message did not fit direct L1 replay");

        emit log_named_uint("L2 max zero message bytes (32-byte edge)", 379_200);
        emit log_named_uint("L2 379200 calldata floor", floor379200);
        emit log_named_uint("L2 379200 measured execution incl CALL", used379200);
        emit log_named_uint("L2 379232 calldata floor", floor379232);
        emit log_named_uint("L2 379232 measured execution incl CALL", used379232);
        emit log_named_uint("L1 direct replay floor for 379200", replayFloor379200);
    }

    function test_capEdges_MinGas_ForcedFailureAlwaysHasCheaperReplay() public {
        uint256 maxPortalDelivered = _maxMinGas(ProbeKind.PortalDelivered);
        uint256 maxPortalFinalized = _maxMinGas(ProbeKind.PortalFinalized);
        uint256 maxDirectDelivered = _maxMinGas(ProbeKind.DirectDelivered);

        assertLt(maxPortalDelivered, maxPortalFinalized, "no finalized+failed band measured");
        assertLt(maxPortalFinalized, maxDirectDelivered, "portal can fail a message that direct replay cannot deliver");

        uint256 forcedFailureGas = maxPortalDelivered + 1;
        (PortalResult memory forced, DirectResult memory replay) = _attemptPortalThenDirect(uint32(forcedFailureGas));
        assertTrue(forced.callOk);
        assertTrue(forced.finalized);
        assertTrue(forced.failed);
        assertFalse(forced.delivered);
        assertTrue(replay.callOk);
        assertTrue(replay.delivered, "cap-valid forced failure was not directly replayable under the same cap");

        emit log_named_uint("max minGas: portal delivers", maxPortalDelivered);
        emit log_named_uint("max minGas: portal finalizes (possibly failed)", maxPortalFinalized);
        emit log_named_uint("max minGas: direct replay delivers", maxDirectDelivered);
        emit log_named_uint("first measured forced-failure minGas", forcedFailureGas);
    }

    function test_largePayloadPortalBarrierIsBeforeDirectReplayBarrier() public {
        bytes memory message = new bytes(379_200);
        PortalResult memory portalResult = _attemptPortal(0, message, EXISTING_EOA, 0, EXISTING_EOA);
        assertFalse(portalResult.callOk, "max-size L2 message unexpectedly finalized through portal under 2^24");
        assertFalse(portalResult.finalized);

        DirectResult memory directResult = _attemptDirect(0, message, EXISTING_EOA, 0, EXISTING_EOA, MESSAGE_SENDER);
        assertTrue(directResult.delivered, "fabricated failed state was not replayable directly");

        emit log_named_uint("large payload bytes", message.length);
        emit log_named_uint("large payload withdrawal gasLimit", _liveBaseGas(message.length, 0));
        emit log_named_uint("direct replay tx floor", directResult.floorIntrinsic);
    }

    function test_portalPayloadEdgeIsExecutionBoundAndBelowL2Edge() public {
        uint256 lowWords = 10_000; // 320,000 bytes: observed delivered.
        uint256 highWords = 10_157; // 325,024 bytes: observed rejected.

        while (lowWords + 1 < highWords) {
            uint256 midWords = (lowWords + highWords) / 2;
            (bool finalized, bool delivered,) = this.probePortalZeroMessage(midWords * 32);
            if (delivered) {
                assertTrue(finalized);
                lowWords = midWords;
            } else {
                highWords = midWords;
            }
        }

        (bool lastFitFinalized, bool lastFitDelivered, uint256 lastFitFloor) =
            this.probePortalZeroMessage(lowWords * 32);
        (bool firstFailFinalized, bool firstFailDelivered, uint256 firstFailFloor) =
            this.probePortalZeroMessage(highWords * 32);

        assertTrue(lastFitFinalized && lastFitDelivered);
        assertFalse(firstFailFinalized || firstFailDelivered);
        assertLt(firstFailFloor, L1_TX_GAS_CAP, "edge was merely the EIP-7623 calldata floor");
        assertLt(lowWords * 32, 379_200, "portal unexpectedly reaches the demonstrated L2 edge");

        (bool directReplay,) = this.probeDirectZeroMessage(highWords * 32);
        assertTrue(directReplay, "first portal-rejected word did not fit direct replay");

        emit log_named_uint("last portal-delivered zero payload bytes", lowWords * 32);
        emit log_named_uint("last portal-delivered tx floor", lastFitFloor);
        emit log_named_uint("first portal-rejected zero payload bytes", highWords * 32);
        emit log_named_uint("first portal-rejected tx floor", firstFailFloor);
    }

    function test_emptyValueNewAccountAndDeployedBridgeTargets() public {
        vm.deal(EXISTING_EOA, 1);
        assertTrue(EXISTING_EOA.codehash != bytes32(0));
        assertEq(NEW_EOA.codehash, bytes32(0));

        DirectResult memory empty = _attemptDirect(0, bytes(""), EXISTING_EOA, 0, EXISTING_EOA, MESSAGE_SENDER);
        assertTrue(empty.delivered);

        DirectResult memory existingValue = _attemptDirect(0, bytes(""), EXISTING_EOA, 1, EXISTING_EOA, MESSAGE_SENDER);
        assertTrue(existingValue.delivered);
        assertEq(existingValue.observedBalance, 2);

        DirectResult memory newValue = _attemptDirect(0, bytes(""), NEW_EOA, 1, NEW_EOA, MESSAGE_SENDER);
        assertTrue(newValue.delivered);
        assertEq(newValue.observedBalance, 1);

        bytes memory bridgeMessage = abi.encodeWithSignature(
            "finalizeBridgeETH(address,address,uint256,bytes)", ATTACKER, BRIDGE_RECIPIENT, 1, bytes("")
        );
        vm.deal(BRIDGE_RECIPIENT, 7);
        DirectResult memory bridge =
            _attemptDirect(200_000, bridgeMessage, L1_STANDARD_BRIDGE, 1, BRIDGE_RECIPIENT, L2_STANDARD_BRIDGE);
        assertTrue(bridge.delivered, "deployed L1StandardBridge finalization failed");
        assertEq(bridge.observedBalance, 8);

        emit log_named_uint("bridge direct replay floor", bridge.floorIntrinsic);
    }

    function test_newAccountReserveOnlyShrinksSelfChosenDirectWithdrawalBand() public {
        uint256 maxExisting = _maxDirectWithdrawalGas(false);
        uint256 maxNew = _maxDirectWithdrawalGas(true);

        assertGt(maxExisting, maxNew);
        assertGt(maxExisting - maxNew, 150_000);

        emit log_named_uint("max direct withdrawal gasLimit: existing account", maxExisting);
        emit log_named_uint("max direct withdrawal gasLimit: new account", maxNew);
        emit log_named_uint("new-account penalty at envelope edge", maxExisting - maxNew);
    }

    function test_gasBurningTargetRecordsReplayableFailureNotLostState() public {
        bytes memory message = abi.encodeCall(BurnAllGas.burn, ());
        PortalResult memory portalResult = _attemptPortal(0, message, address(burner), 0, address(burner));

        assertTrue(portalResult.callOk);
        assertTrue(portalResult.finalized);
        assertTrue(portalResult.failed);
        assertFalse(portalResult.delivered);

        DirectResult memory replay = _attemptDirect(0, message, address(burner), 0, address(burner), MESSAGE_SENDER);
        assertTrue(replay.callOk);
        assertTrue(replay.failed);
        assertFalse(replay.delivered);
    }

    enum ProbeKind {
        PortalDelivered,
        PortalFinalized,
        DirectDelivered
    }

    struct PortalResult {
        bool callOk;
        bool finalized;
        bool delivered;
        bool failed;
        uint256 floorIntrinsic;
        uint256 observedBalance;
    }

    struct DirectResult {
        bool callOk;
        bool delivered;
        bool failed;
        uint256 floorIntrinsic;
        uint256 observedBalance;
    }

    function probeL2ZeroMessage(uint256 messageLength)
        external
        returns (bool ok, uint256 floorIntrinsic, uint256 measuredExecution)
    {
        require(msg.sender == address(this));
        uint256 snapshot = vm.snapshotState();
        bytes memory message = new bytes(messageLength);
        bytes memory callData = abi.encodeCall(IL2Messenger.sendMessage, (EXISTING_EOA, message, uint32(0)));
        (uint256 standardIntrinsic, uint256 floorGas) = _intrinsic(callData);
        floorIntrinsic = floorGas;
        if (floorGas <= L2_TX_GAS_CAP && standardIntrinsic < L2_TX_GAS_CAP) {
            uint256 entryBudget = L2_TX_GAS_CAP - standardIntrinsic;
            uint256 gasBefore = gasleft();
            vm.prank(ATTACKER, ATTACKER);
            (ok,) = L2_MESSENGER.call{gas: entryBudget}(callData);
            measuredExecution = gasBefore - gasleft();
        }
        require(vm.revertToState(snapshot));
    }

    function probeDirectZeroMessage(uint256 messageLength) external returns (bool delivered, uint256 floorIntrinsic) {
        require(msg.sender == address(this));
        DirectResult memory result =
            _attemptDirect(0, new bytes(messageLength), EXISTING_EOA, 0, EXISTING_EOA, MESSAGE_SENDER);
        return (result.delivered, result.floorIntrinsic);
    }

    function probePortalZeroMessage(uint256 messageLength)
        external
        returns (bool finalized, bool delivered, uint256 floorIntrinsic)
    {
        require(msg.sender == address(this));
        PortalResult memory result = _attemptPortal(0, new bytes(messageLength), EXISTING_EOA, 0, EXISTING_EOA);
        return (result.finalized, result.delivered, result.floorIntrinsic);
    }

    function _maxMinGas(ProbeKind kind) internal returns (uint256) {
        uint256 low;
        uint256 high = 17_000_000;
        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            bool passes;
            if (kind == ProbeKind.DirectDelivered) {
                passes = _attemptDirect(uint32(mid), bytes(""), EXISTING_EOA, 0, EXISTING_EOA, MESSAGE_SENDER).delivered;
            } else {
                PortalResult memory result = _attemptPortal(uint32(mid), bytes(""), EXISTING_EOA, 0, EXISTING_EOA);
                passes = kind == ProbeKind.PortalDelivered ? result.delivered : result.finalized;
            }
            if (passes) low = mid;
            else high = mid - 1;
        }
        return low;
    }

    function _maxDirectWithdrawalGas(bool newAccount) internal returns (uint256) {
        uint256 low;
        uint256 high = 17_000_000;
        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            (bool ok,,) = _attemptDirectWithdrawal(uint32(mid), newAccount);
            if (ok) low = mid;
            else high = mid - 1;
        }
        return low;
    }

    function _attemptPortal(
        uint32 minGasLimit,
        bytes memory message,
        address finalTarget,
        uint256 value,
        address observe
    ) internal returns (PortalResult memory result) {
        uint256 snapshot = vm.snapshotState();

        bytes memory relayData = _relayCalldata(minGasLimit, message, finalTarget, value, MESSAGE_SENDER);
        WithdrawalTransaction memory withdrawal = WithdrawalTransaction({
            nonce: VERSIONED_NONCE,
            sender: L2_MESSENGER,
            target: L1_MESSENGER,
            value: value,
            gasLimit: _liveBaseGas(message.length, minGasLimit),
            data: relayData
        });

        bytes32 withdrawalHash = _hashWithdrawal(withdrawal);
        bytes32 messageHash = keccak256(relayData);
        _fabricateMatureProof(withdrawalHash);

        bytes memory callData =
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, PROOF_SUBMITTER));
        (uint256 standardIntrinsic, uint256 floorIntrinsic) = _intrinsic(callData);
        result.floorIntrinsic = floorIntrinsic;

        if (floorIntrinsic <= L1_TX_GAS_CAP && standardIntrinsic < L1_TX_GAS_CAP) {
            _cool(finalTarget);
            uint256 entryBudget = L1_TX_GAS_CAP - standardIntrinsic;
            vm.prank(ATTACKER, ATTACKER);
            (result.callOk,) = PORTAL.call{gas: entryBudget}(callData);
            result.finalized = IPortal(PORTAL).finalizedWithdrawals(withdrawalHash);
            result.delivered = IL1Messenger(L1_MESSENGER).successfulMessages(messageHash);
            result.failed = IL1Messenger(L1_MESSENGER).failedMessages(messageHash);
            result.observedBalance = observe.balance;
        }

        require(vm.revertToState(snapshot), "snapshot revert failed");
    }

    function _attemptDirect(
        uint32 minGasLimit,
        bytes memory message,
        address finalTarget,
        uint256 value,
        address observe,
        address sender
    ) internal returns (DirectResult memory result) {
        uint256 snapshot = vm.snapshotState();
        bytes memory callData = _relayCalldata(minGasLimit, message, finalTarget, value, sender);
        bytes32 messageHash = keccak256(callData);
        _setFailed(messageHash);
        if (value != 0) vm.deal(L1_MESSENGER, value);

        (uint256 standardIntrinsic, uint256 floorIntrinsic) = _intrinsic(callData);
        result.floorIntrinsic = floorIntrinsic;
        if (floorIntrinsic <= L1_TX_GAS_CAP && standardIntrinsic < L1_TX_GAS_CAP) {
            _cool(finalTarget);
            uint256 entryBudget = L1_TX_GAS_CAP - standardIntrinsic;
            vm.prank(ATTACKER, ATTACKER);
            (result.callOk,) = L1_MESSENGER.call{gas: entryBudget}(callData);
            result.delivered = IL1Messenger(L1_MESSENGER).successfulMessages(messageHash);
            result.failed = IL1Messenger(L1_MESSENGER).failedMessages(messageHash);
            result.observedBalance = observe.balance;
        }

        require(vm.revertToState(snapshot), "snapshot revert failed");
    }

    function _attemptPortalThenDirect(uint32 minGasLimit)
        internal
        returns (PortalResult memory portalResult, DirectResult memory replayResult)
    {
        uint256 snapshot = vm.snapshotState();
        bytes memory message = bytes("");
        bytes memory relayData = _relayCalldata(minGasLimit, message, EXISTING_EOA, 0, MESSAGE_SENDER);
        bytes32 messageHash = keccak256(relayData);

        WithdrawalTransaction memory withdrawal = WithdrawalTransaction({
            nonce: VERSIONED_NONCE,
            sender: L2_MESSENGER,
            target: L1_MESSENGER,
            value: 0,
            gasLimit: _liveBaseGas(0, minGasLimit),
            data: relayData
        });
        bytes32 withdrawalHash = _hashWithdrawal(withdrawal);
        _fabricateMatureProof(withdrawalHash);

        bytes memory portalCalldata =
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, PROOF_SUBMITTER));
        (uint256 portalIntrinsic, uint256 portalFloor) = _intrinsic(portalCalldata);
        portalResult.floorIntrinsic = portalFloor;
        assertLe(portalFloor, L1_TX_GAS_CAP);
        assertLt(portalIntrinsic, L1_TX_GAS_CAP);

        _cool(EXISTING_EOA);
        vm.prank(ATTACKER, ATTACKER);
        (portalResult.callOk,) = PORTAL.call{gas: L1_TX_GAS_CAP - portalIntrinsic}(portalCalldata);
        portalResult.finalized = IPortal(PORTAL).finalizedWithdrawals(withdrawalHash);
        portalResult.delivered = IL1Messenger(L1_MESSENGER).successfulMessages(messageHash);
        portalResult.failed = IL1Messenger(L1_MESSENGER).failedMessages(messageHash);

        // This is a second transaction against the state produced above. No failedMessages slot is fabricated.
        (uint256 replayIntrinsic, uint256 replayFloor) = _intrinsic(relayData);
        replayResult.floorIntrinsic = replayFloor;
        assertLe(replayFloor, L1_TX_GAS_CAP);
        assertLt(replayIntrinsic, L1_TX_GAS_CAP);

        _cool(EXISTING_EOA);
        vm.prank(ATTACKER, ATTACKER);
        (replayResult.callOk,) = L1_MESSENGER.call{gas: L1_TX_GAS_CAP - replayIntrinsic}(relayData);
        replayResult.delivered = IL1Messenger(L1_MESSENGER).successfulMessages(messageHash);
        replayResult.failed = IL1Messenger(L1_MESSENGER).failedMessages(messageHash);

        require(vm.revertToState(snapshot), "snapshot revert failed");
    }

    function _attemptDirectWithdrawal(uint32 gasLimit, bool newAccount)
        internal
        returns (bool callOk, bool finalized, uint256 observedBalance)
    {
        uint256 snapshot = vm.snapshotState();
        address target = newAccount ? NEW_EOA : EXISTING_EOA;
        if (!newAccount) vm.deal(target, 1);

        WithdrawalTransaction memory withdrawal = WithdrawalTransaction({
            nonce: VERSIONED_NONCE | uint256(gasLimit),
            sender: MESSAGE_SENDER,
            target: target,
            value: 1,
            gasLimit: gasLimit,
            data: bytes("")
        });
        bytes32 withdrawalHash = _hashWithdrawal(withdrawal);
        _fabricateMatureProof(withdrawalHash);
        bytes memory callData =
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, PROOF_SUBMITTER));
        (uint256 standardIntrinsic, uint256 floorIntrinsic) = _intrinsic(callData);
        if (floorIntrinsic <= L1_TX_GAS_CAP && standardIntrinsic < L1_TX_GAS_CAP) {
            _cool(target);
            uint256 entryBudget = L1_TX_GAS_CAP - standardIntrinsic;
            vm.prank(ATTACKER, ATTACKER);
            (callOk,) = PORTAL.call{gas: entryBudget}(callData);
            finalized = IPortal(PORTAL).finalizedWithdrawals(withdrawalHash);
            observedBalance = target.balance;
        }
        require(vm.revertToState(snapshot), "snapshot revert failed");
    }

    function _fabricateMatureProof(bytes32 withdrawalHash) internal {
        bytes32 outer = keccak256(abi.encode(withdrawalHash, PROVEN_WITHDRAWALS_SLOT));
        bytes32 proofSlot = keccak256(abi.encode(PROOF_SUBMITTER, outer));
        uint256 packed = uint256(uint160(VALID_GAME)) | (uint256(PROOF_TIMESTAMP) << 160);
        vm.store(PORTAL, proofSlot, bytes32(packed));

        (address game, uint64 timestamp) = IPortal(PORTAL).provenWithdrawals(withdrawalHash, PROOF_SUBMITTER);
        assertEq(game, VALID_GAME);
        assertEq(timestamp, PROOF_TIMESTAMP);
    }

    function _setFailed(bytes32 messageHash) internal {
        bytes32 slot = keccak256(abi.encode(messageHash, FAILED_MESSAGES_SLOT));
        vm.store(L1_MESSENGER, slot, bytes32(uint256(1)));
    }

    function _cool(address target) internal {
        vm.cool(PORTAL);
        vm.cool(L1_MESSENGER);
        vm.cool(SYSTEM_CONFIG);
        vm.cool(LOCKBOX);
        vm.cool(ASR);
        vm.cool(SUPERCHAIN_CONFIG);
        vm.cool(VALID_GAME);
        vm.cool(L1_STANDARD_BRIDGE);
        vm.cool(target);
    }

    function _relayCalldata(
        uint32 minGasLimit,
        bytes memory message,
        address finalTarget,
        uint256 value,
        address sender
    ) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IL1Messenger.relayMessage, (VERSIONED_NONCE, sender, finalTarget, value, uint256(minGasLimit), message)
        );
    }

    function _hashWithdrawal(WithdrawalTransaction memory withdrawal) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                withdrawal.nonce,
                withdrawal.sender,
                withdrawal.target,
                withdrawal.value,
                withdrawal.gasLimit,
                withdrawal.data
            )
        );
    }

    function _liveBaseGas(uint256 messageLength, uint32 minGasLimit) internal pure returns (uint64) {
        uint256 executionGas = 285_000 + (uint256(minGasLimit) * 64) / 63;
        uint256 totalMessageSize = messageLength + 260;
        return uint64(21_000 + _max(executionGas + totalMessageSize * 16, totalMessageSize * 40));
    }

    function _intrinsic(bytes memory txData) internal pure returns (uint256 standard, uint256 floor) {
        uint256 tokens;
        for (uint256 i; i < txData.length; ++i) {
            tokens += txData[i] == 0 ? 1 : 4;
        }
        standard = 21_000 + 4 * tokens;
        floor = 21_000 + 10 * tokens;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
