// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";

interface ICrossDomainMessenger {
    function version() external view returns (string memory);
    function baseGas(bytes memory, uint32) external pure returns (uint64);
    function RELAY_CONSTANT_OVERHEAD() external view returns (uint64);
    function RELAY_CALL_OVERHEAD() external view returns (uint64);
    function RELAY_RESERVED_GAS() external view returns (uint64);
    function RELAY_GAS_CHECK_BUFFER() external view returns (uint64);
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function relayMessage(uint256, address, address, uint256, uint256, bytes memory) external payable;
}

interface IAddressManager {
    function getAddress(string memory) external view returns (address);
}

interface IPortal {
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }

    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address disputeGameProxy, uint64 timestamp);
}

contract GasThresholdTarget {
    uint256 public calls;

    function ping(uint256 requiredGas) external {
        require(gasleft() >= requiredGas, "target: insufficient gas");
        calls++;
    }
}

contract PayloadSink {
    uint256 public calls;

    fallback() external payable {
        calls++;
    }
}

contract ToggleETHReceiver {
    bool public accepts;
    uint256 public receives;

    function setAccepts(bool value) external {
        accepts = value;
    }

    receive() external payable {
        require(accepts, "receiver rejects ETH");
        receives++;
    }
}

contract PortalMessengerSemanticsTest is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address internal constant L1_ERC721_BRIDGE = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
    address internal constant ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;

    address internal constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant L2_ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;

    address internal constant POST_ANCHOR_GAME = 0x55A5CFd4270340b3822BB9D8eebdb450ac206f95;
    address internal constant PRE_ANCHOR_GAME = 0x51024A83c2F94c8e70014A732d3e2559CdceeB1D;

    address internal constant L1_V9_IMPLEMENTATION = 0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448;
    address internal constant L2_LIVE_IMPLEMENTATION = 0x250AF3f400cf8Aac8D410c90f1ba3968dD87DF96;
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes4 internal constant L1CDM_CALL_FAILED = bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"));
    bytes4 internal constant ALREADY_FINALIZED = bytes4(keccak256("OptimismPortal_AlreadyFinalized()"));

    uint256 internal l1Fork;
    uint256 internal l1PreFork;
    uint256 internal l2Fork;
    uint256 internal nextNonce;

    function setUp() public {
        l2Fork = vm.createFork("l2p");
        l1PreFork = vm.createFork("l1prep");
        l1Fork = vm.createSelectFork("l1p");
        nextNonce = 1;
    }

    function test_liveImplementationsAndBudgetSkew() external {
        vm.selectFork(l2Fork);
        address l2Implementation = address(uint160(uint256(vm.load(L2_MESSENGER, IMPLEMENTATION_SLOT))));
        assertEq(l2Implementation, L2_LIVE_IMPLEMENTATION);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).version(), "2.2.1");
        assertEq(L2_LIVE_IMPLEMENTATION.codehash, 0xeaead896b67f526a720640109c289239f97d5a03aac938475e80cae0a2101b03);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).RELAY_CONSTANT_OVERHEAD(), 200_000);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).RELAY_CALL_OVERHEAD(), 40_000);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).RELAY_RESERVED_GAS(), 40_000);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).RELAY_GAS_CHECK_BUFFER(), 5_000);
        assertEq(ICrossDomainMessenger(L2_MESSENGER).baseGas(hex"", 0), 310_160);

        vm.selectFork(l1Fork);
        assertEq(
            IAddressManager(ADDRESS_MANAGER).getAddress("OVM_L1CrossDomainMessenger"), L1_V9_IMPLEMENTATION
        );
        assertEq(ICrossDomainMessenger(L1_MESSENGER).version(), "2.13.0");
        assertEq(L1_V9_IMPLEMENTATION.codehash, 0x249d14f5f61132812ad2d4229d182fbab820491698126d18f0b526c9bf6cf073);

        // These compatibility getters deliberately expose the remote L2 budgets, not the
        // v9 L1-local reserve (135k) and check buffer (15k).
        assertEq(ICrossDomainMessenger(L1_MESSENGER).RELAY_CONSTANT_OVERHEAD(), 200_000);
        assertEq(ICrossDomainMessenger(L1_MESSENGER).RELAY_CALL_OVERHEAD(), 40_000);
        assertEq(ICrossDomainMessenger(L1_MESSENGER).RELAY_RESERVED_GAS(), 40_000);
        assertEq(ICrossDomainMessenger(L1_MESSENGER).RELAY_GAS_CHECK_BUFFER(), 5_000);
        assertEq(ICrossDomainMessenger(L1_MESSENGER).baseGas(hex"", 0), 310_160);
    }

    function test_l1ToL2Budget_matchesLiveL2Relay() external {
        vm.selectFork(l2Fork);
        GasThresholdTarget target = new GasThresholdTarget();
        bytes memory message = abi.encodeCall(target.ping, (100_000));
        uint32 minGasLimit = 100_000;
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), address(target), 0, minGasLimit, message);

        vm.selectFork(l1Fork);
        uint64 l1Budget = ICrossDomainMessenger(L1_MESSENGER).baseGas(message, minGasLimit);

        vm.selectFork(l2Fork);
        address aliasedL1Messenger = address(uint160(L1_MESSENGER) + uint160(0x1111000000000000000000000000000000001111));
        vm.prank(aliasedL1Messenger);
        (bool success,) = L2_MESSENGER.call{ gas: l1Budget }(relayData);
        assertTrue(success);
        assertTrue(ICrossDomainMessenger(L2_MESSENGER).successfulMessages(keccak256(relayData)));
        assertFalse(ICrossDomainMessenger(L2_MESSENGER).failedMessages(keccak256(relayData)));
        assertEq(target.calls(), 1);
    }

    function test_liveOldL2Budget_canFinalizeWithMoreTransactionGas() external {
        GasThresholdTarget target = new GasThresholdTarget();
        bytes memory message = abi.encodeCall(target.ping, (100_000));
        uint32 minGasLimit = 100_000;
        uint64 withdrawalGasLimit = _liveL2BaseGas(message, minGasLimit);
        bytes memory relayData = _relayData(_versionedNonce(nextNonce++), address(this), address(target), 0, minGasLimit, message);

        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 0, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 3_000_000 }(withdrawal, address(this));

        bytes32 messageHash = keccak256(relayData);
        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
        assertEq(target.calls(), 1);
    }

    function test_lowGasFinalization_recordsFailure_thenDirectReplayDelivers() external {
        GasThresholdTarget target = new GasThresholdTarget();
        uint256 requiredTargetGas = 500_000;
        bytes memory message = abi.encodeCall(target.ping, (requiredTargetGas));
        uint64 withdrawalGasLimit = _liveL2BaseGas(message, 0);
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), address(target), 0, 0, message);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 0, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        uint256 leastSuccessfulPortalCallGas = _leastSuccessfulPortalCallGas(withdrawal, 250_000, 2_000_000);
        emit log_named_uint("leastSuccessfulPortalCallGas", leastSuccessfulPortalCallGas);
        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: leastSuccessfulPortalCallGas }(
            withdrawal, address(this)
        );

        bytes32 messageHash = keccak256(relayData);
        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
        assertEq(target.calls(), 0);

        ICrossDomainMessenger(L1_MESSENGER).relayMessage{ gas: 2_000_000 }(
            nonce, address(this), address(target), 0, 0, message
        );
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertEq(target.calls(), 1);

        (bool finalizedAgain, bytes memory revertData) = address(PORTAL).call(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, address(this)))
        );
        assertFalse(finalizedAgain);
        assertEq(bytes4(revertData), ALREADY_FINALIZED);
        assertEq(target.calls(), 1);
    }

    function test_maxAlignedPayload_liveOldL2Budget_recordsAnOutcome() external {
        PayloadSink target = new PayloadSink();
        bytes memory message = new bytes(119_744);
        uint32 minGasLimit = 50_000;
        uint64 withdrawalGasLimit = _liveL2BaseGas(message, minGasLimit);
        bytes memory relayData = _relayData(
            _versionedNonce(nextNonce++), address(this), address(target), 0, minGasLimit, message
        );
        assertEq(relayData.length, 119_972);

        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 0, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);
        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 10_000_000 }(withdrawal, address(this));

        bytes32 messageHash = keccak256(relayData);
        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertTrue(
            ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash)
                || ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash)
        );
        assertEq(target.calls(), 1);
    }

    function test_valueToNewAccount_liveOldL2Budget_delivers() external {
        address target = address(new PayloadSink());
        vm.etch(target, hex"");
        vm.setNonceUnsafe(target, 0);
        vm.deal(target, 0);
        assertEq(target.code.length, 0);
        assertEq(target.codehash, bytes32(0));
        assertEq(target.balance, 0);
        bytes memory message = hex"";
        uint64 withdrawalGasLimit = _liveL2BaseGas(message, 0);
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), target, 1, 0, message);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 1, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 3_000_000 }(withdrawal, address(this));

        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(keccak256(relayData)));
        assertEq(target.balance, 1);
    }

    function test_today_exactLiveOldL2Budget_valueToNewAccount_recordsOutcome() external {
        address target = address(new PayloadSink());
        vm.etch(target, hex"");
        vm.setNonceUnsafe(target, 0);
        vm.deal(target, 0);
        assertEq(target.codehash, bytes32(0));

        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), target, 1, 0, hex"");
        assertEq(_liveL2BaseGas(hex"", 0), 310_160);

        vm.store(PORTAL, bytes32(uint256(50)), bytes32(uint256(uint160(L2_MESSENGER))));
        vm.deal(PORTAL, 1);
        vm.prank(PORTAL);
        (bool callSuccess,) = L1_MESSENGER.call{ gas: 310_160, value: 1 }(relayData);

        bytes32 messageHash = keccak256(relayData);
        assertTrue(callSuccess);
        assertTrue(
            ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash)
                || ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash)
        );
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertEq(target.balance, 1);
    }

    function test_highMinGas_exactOldBudgetFailsButMaxGasReplayDelivers() external {
        GasThresholdTarget target = new GasThresholdTarget();
        uint32 minGasLimit = 15_000_000;
        bytes memory message = abi.encodeCall(target.ping, (14_900_000));
        uint64 oldBudget = _liveL2BaseGas(message, minGasLimit);
        emit log_named_uint("liveOldL2Budget", oldBudget);

        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), address(target), 0, minGasLimit, message);
        bytes32 messageHash = keccak256(relayData);

        vm.store(PORTAL, bytes32(uint256(50)), bytes32(uint256(uint160(L2_MESSENGER))));
        vm.prank(PORTAL);
        (bool initialCallSuccess,) = L1_MESSENGER.call{ gas: oldBudget }(relayData);
        assertTrue(initialCallSuccess);
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
        assertEq(target.calls(), 0);

        ICrossDomainMessenger(L1_MESSENGER).relayMessage{ gas: 16_700_000 }(
            nonce, address(this), address(target), 0, minGasLimit, message
        );
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertEq(target.calls(), 1);
    }

    function test_standardBridgeFailure_isRecordedAndReplaySucceeds() external {
        ToggleETHReceiver recipient = new ToggleETHReceiver();
        uint256 recipientStartingBalance = address(recipient).balance;
        uint256 amount = 1;
        bytes memory bridgeMessage = abi.encodeWithSignature(
            "finalizeBridgeETH(address,address,uint256,bytes)", address(this), address(recipient), amount, hex""
        );
        uint32 minGasLimit = 200_000;
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(
            nonce, L2_STANDARD_BRIDGE, L1_STANDARD_BRIDGE, amount, minGasLimit, bridgeMessage
        );
        uint64 withdrawalGasLimit = _liveL2BaseGas(bridgeMessage, minGasLimit);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, amount, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 3_000_000 }(withdrawal, address(this));

        bytes32 messageHash = keccak256(relayData);
        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
        assertEq(address(recipient).balance, recipientStartingBalance);

        recipient.setAccepts(true);
        ICrossDomainMessenger(L1_MESSENGER).relayMessage{ gas: 3_000_000 }(
            nonce, L2_STANDARD_BRIDGE, L1_STANDARD_BRIDGE, amount, minGasLimit, bridgeMessage
        );
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
        assertEq(address(recipient).balance, recipientStartingBalance + amount);
        assertEq(recipient.receives(), 1);
    }

    function test_erc721BridgeFailure_isRecordedAsReplayable() external {
        address localToken = makeAddr("unescrowed L1 NFT");
        address remoteToken = makeAddr("L2 NFT");
        bytes memory bridgeMessage = abi.encodeWithSignature(
            "finalizeBridgeERC721(address,address,address,address,uint256,bytes)",
            localToken,
            remoteToken,
            address(this),
            address(this),
            7,
            hex""
        );
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, L2_ERC721_BRIDGE, L1_ERC721_BRIDGE, 0, 0, bridgeMessage);
        uint64 withdrawalGasLimit = _liveL2BaseGas(bridgeMessage, 0);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 0, withdrawalGasLimit);
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 3_000_000 }(withdrawal, address(this));

        bytes32 messageHash = keccak256(relayData);
        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));

        // A replay is admitted (the messenger call returns normally) even though the bridge target
        // still reverts because this synthetic token ID is deliberately not escrowed.
        ICrossDomainMessenger(L1_MESSENGER).relayMessage{ gas: 2_000_000 }(
            nonce, L2_ERC721_BRIDGE, L1_ERC721_BRIDGE, 0, 0, bridgeMessage
        );
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(messageHash));
        assertTrue(ICrossDomainMessenger(L1_MESSENGER).failedMessages(messageHash));
    }

    function test_v9RevertingMessengerCall_leavesWithdrawalUnfinalized() external {
        bytes memory message = hex"";
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), L1_MESSENGER, 0, 0, message);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(
            relayData, 0, _liveL2BaseGas(message, 0)
        );
        bytes32 withdrawalHash = _seedProof(withdrawal, POST_ANCHOR_GAME);

        (bool success, bytes memory revertData) = address(PORTAL).call{ gas: 3_000_000 }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, address(this)))
        );

        assertFalse(success);
        assertEq(bytes4(revertData), L1CDM_CALL_FAILED);
        assertFalse(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(keccak256(relayData)));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).failedMessages(keccak256(relayData)));
    }

    function test_v8SameRevertingMessengerCall_wasFinalizedWithoutOutcome() external {
        vm.selectFork(l1PreFork);
        bytes memory message = hex"";
        uint256 nonce = _versionedNonce(nextNonce++);
        bytes memory relayData = _relayData(nonce, address(this), L1_MESSENGER, 0, 0, message);
        IPortal.WithdrawalTransaction memory withdrawal = _withdrawal(relayData, 0, 310_160);
        bytes32 withdrawalHash = _seedProof(withdrawal, PRE_ANCHOR_GAME);

        IPortal(PORTAL).finalizeWithdrawalTransactionExternalProof{ gas: 3_000_000 }(withdrawal, address(this));

        assertTrue(IPortal(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).successfulMessages(keccak256(relayData)));
        assertFalse(ICrossDomainMessenger(L1_MESSENGER).failedMessages(keccak256(relayData)));
    }

    function _liveL2BaseGas(bytes memory message, uint32 minGasLimit) internal returns (uint64 gasLimit) {
        vm.selectFork(l2Fork);
        gasLimit = ICrossDomainMessenger(L2_MESSENGER).baseGas(message, minGasLimit);
        vm.selectFork(l1Fork);
    }

    function _withdrawal(bytes memory relayData, uint256 value, uint256 gasLimit)
        internal
        view
        returns (IPortal.WithdrawalTransaction memory withdrawal)
    {
        withdrawal = IPortal.WithdrawalTransaction({
            nonce: nextNonce + 10_000,
            sender: L2_MESSENGER,
            target: L1_MESSENGER,
            value: value,
            gasLimit: gasLimit,
            data: relayData
        });
    }

    function _seedProof(IPortal.WithdrawalTransaction memory withdrawal, address game)
        internal
        returns (bytes32 withdrawalHash)
    {
        withdrawalHash = keccak256(
            abi.encode(
                withdrawal.nonce,
                withdrawal.sender,
                withdrawal.target,
                withdrawal.value,
                withdrawal.gasLimit,
                withdrawal.data
            )
        );
        bytes32 firstMappingSlot = keccak256(abi.encode(withdrawalHash, uint256(57)));
        bytes32 provenWithdrawalSlot = keccak256(abi.encode(address(this), firstMappingSlot));
        emit log_named_bytes32("withdrawalHash", withdrawalHash);
        emit log_named_bytes32("messageHash", keccak256(withdrawal.data));
        emit log_named_bytes32("proofSlot", provenWithdrawalSlot);
        uint64 provenAt = uint64(block.timestamp - 604_801);
        bytes32 packed = bytes32(uint256(uint160(game)) | (uint256(provenAt) << 160));
        vm.store(PORTAL, provenWithdrawalSlot, packed);

        (address storedGame, uint64 storedTimestamp) = IPortal(PORTAL).provenWithdrawals(withdrawalHash, address(this));
        assertEq(storedGame, game);
        assertEq(storedTimestamp, provenAt);
    }

    function _relayData(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 minGasLimit,
        bytes memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature(
            "relayMessage(uint256,address,address,uint256,uint256,bytes)",
            nonce,
            sender,
            target,
            value,
            minGasLimit,
            message
        );
    }

    function _versionedNonce(uint256 nonce) internal pure returns (uint256) {
        return (uint256(1) << 240) | nonce;
    }

    function _leastSuccessfulPortalCallGas(
        IPortal.WithdrawalTransaction memory withdrawal,
        uint256 low,
        uint256 high
    )
        internal
        returns (uint256)
    {
        assertFalse(_tryFinalize(withdrawal, low));
        assertTrue(_tryFinalize(withdrawal, high));
        while (high - low > 1) {
            uint256 mid = (high + low) / 2;
            if (_tryFinalize(withdrawal, mid)) high = mid;
            else low = mid;
        }
        return high;
    }

    function _tryFinalize(IPortal.WithdrawalTransaction memory withdrawal) internal returns (bool) {
        return _tryFinalize(withdrawal, gasleft() / 2);
    }

    function _tryFinalize(IPortal.WithdrawalTransaction memory withdrawal, uint256 gasAmount)
        internal
        returns (bool success)
    {
        uint256 snapshot = vm.snapshotState();
        (success,) = address(PORTAL).call{ gas: gasAmount }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (withdrawal, address(this)))
        );
        vm.revertToState(snapshot);
    }
}
