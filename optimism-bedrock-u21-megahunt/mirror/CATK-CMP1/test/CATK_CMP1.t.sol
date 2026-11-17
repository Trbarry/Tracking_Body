// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base.sol";

interface ISuperchainPause {
    function pause(address identifier) external;
    function unpause(address identifier) external;
    function paused(address identifier) external view returns (bool);
}

interface IEtherfiSyncPool {
    function pause() external;
    function unpause() external;
    function getTotalUnbackedTokens() external view returns (uint256);
}

interface IHopBridgeState {
    function transferRootCommittedAt(uint256 destinationChainId, bytes32 rootId) external view returns (uint256);
}

interface ILockboxState {
    function authorizedPortals(address portal) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256 value) external;
}

contract CMP1ForceETH {
    constructor() payable { }

    function force(address payable target) external {
        selfdestruct(target);
    }
}

/// @notice Installed only at the real carrier withdrawal's EOA recipient on the
/// local fork. The first delivery rejects. The second nests finalization of the
/// real application withdrawal while the messenger reentrancy guard is occupied.
contract CMP1CarrierReceiver {
    IPortal internal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    bool public armed;
    bool public nestedOk;
    bytes public payload;

    function arm(bytes calldata callData) external {
        payload = callData;
        armed = true;
    }

    receive() external payable {
        require(armed, "reject initial carrier delivery");
        (nestedOk,) = address(PORTAL).call(payload);
        require(nestedOk, "nested finalization failed");
    }
}

contract CATKCMP1Test is Base {
    address internal constant ATTACKER = address(0xCA7C01);
    ISuperchainPause internal constant SUPERCHAIN =
        ISuperchainPause(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    IEtherfiSyncPool internal constant SYNC_POOL =
        IEtherfiSyncPool(0xD789870beA40D056A4d26055d0bEFcC8755DA146);
    address internal constant ETHERFI_OPERATIONS = 0x2aCA71020De61bb532008049e1Bd41E451aE8AdC;
    IHopBridgeState internal constant HOP = IHopBridgeState(0xb8901acB165ed027E32754E0FFe830802919727f);
    ILockboxState internal constant LOCKBOX_STATE = ILockboxState(LOCKBOX);
    address internal constant INK_PORTAL = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;

    struct Relay {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 minGas;
        bytes message;
    }

    struct ActiveFailure {
        bytes32 messageHash;
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 minGas;
        bytes message;
    }

    function setUp() public {
        _fork();
    }

    function _relay(bytes memory data) internal pure returns (Relay memory r) {
        bytes memory args = new bytes(data.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = data[i + 4];
        (r.nonce, r.sender, r.target, r.value, r.minGas, r.message) =
            abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    function _legacyETHRecipient(bytes memory message) internal pure returns (address recipient) {
        require(bytes4(message) == bytes4(0x1635f5fd), "not legacy ETH bridge calldata");
        bytes memory args = new bytes(message.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = message[i + 4];
        (, recipient,,) = abi.decode(args, (address, address, uint256, bytes));
    }

    function _activeFailure(uint256 index) internal view returns (ActiveFailure memory f) {
        string memory vectors = vm.readFile("active-zero-value-replays.json");
        string memory key = string.concat(".messages[", vm.toString(index), "]");
        f.messageHash = vm.parseJsonBytes32(vectors, string.concat(key, ".message_hash"));
        f.nonce = vm.parseJsonUint(vectors, string.concat(key, ".nonce"));
        f.sender = vm.parseJsonAddress(vectors, string.concat(key, ".sender"));
        f.target = vm.parseJsonAddress(vectors, string.concat(key, ".target"));
        f.value = vm.parseJsonUint(vectors, string.concat(key, ".value"));
        f.minGas = vm.parseJsonUint(vectors, string.concat(key, ".min_gas_limit"));
        f.message = vm.parseJsonBytes(vectors, string.concat(key, ".message"));
    }

    /// @dev Produces a genuine finalized-but-failed 363.438 ETH messenger message.
    /// The caller used for every portal finalization and replay is unprivileged.
    function _forceApplicationFailure() internal returns (Prove memory victim, Relay memory victimRelay) {
        Prove memory carrier = _load(34);
        victim = _load(1);
        _mature(carrier.hash, carrier.submitter);
        _mature(victim.hash, victim.submitter);

        Relay memory carrierRelay = _relay(carrier.wd.data);
        victimRelay = _relay(victim.wd.data);
        assertEq(victimRelay.target, 0x23CA5E5300d3b35a47DFeF6A36Ecba5AC0a96E03);
        assertEq(victimRelay.value, 363_438235322873695226);

        address carrierRecipient = _legacyETHRecipient(carrierRelay.message);
        assertEq(carrierRecipient.code.length, 0);
        CMP1CarrierReceiver template = new CMP1CarrierReceiver();
        vm.etch(carrierRecipient, address(template).code);
        CMP1CarrierReceiver receiver = CMP1CarrierReceiver(payable(carrierRecipient));

        vm.prank(ATTACKER);
        PORTAL.finalizeWithdrawalTransactionExternalProof(carrier.wd, carrier.submitter);
        assertTrue(L1CDM.failedMessages(keccak256(carrier.wd.data)));

        receiver.arm(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (victim.wd, victim.submitter))
        );
        vm.prank(ATTACKER);
        L1CDM.relayMessage(
            carrierRelay.nonce,
            carrierRelay.sender,
            carrierRelay.target,
            carrierRelay.value,
            carrierRelay.minGas,
            carrierRelay.message
        );

        bytes32 messageHash = keccak256(victim.wd.data);
        assertTrue(PORTAL.finalizedWithdrawals(victim.hash));
        assertTrue(L1CDM.failedMessages(messageHash));
        assertFalse(L1CDM.successfulMessages(messageHash));
        assertEq(address(L1CDM).balance, victimRelay.value);
    }

    function _replay(Relay memory r) internal {
        vm.prank(ATTACKER);
        L1CDM.relayMessage(r.nonce, r.sender, r.target, r.value, r.minGas, r.message);
    }

    function _assertSettled(Prove memory victim, Relay memory) internal view {
        assertTrue(L1CDM.successfulMessages(keccak256(victim.wd.data)));
        assertEq(address(L1CDM).balance, 0);
        assertEq(ATTACKER.balance, 0);
        assertTrue(PORTAL.finalizedWithdrawals(victim.hash));
    }

    function test_C01_realApplicationReplayHasNoAgeDeadline() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        vm.warp(block.timestamp + 3650 days);
        _replay(r);
        _assertSettled(victim, r);
    }

    function test_C02_applicationPauseIsPrivilegedAndTemporary() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        vm.prank(ETHERFI_OPERATIONS);
        SYNC_POOL.pause();

        _replay(r);
        assertFalse(L1CDM.successfulMessages(keccak256(victim.wd.data)));
        assertEq(address(L1CDM).balance, r.value);

        vm.prank(ETHERFI_OPERATIONS);
        SYNC_POOL.unpause();
        _replay(r);
        _assertSettled(victim, r);
    }

    function test_C03_lockboxLocalPausePropagatesToMessengerThenUnpauseRestoresReplay() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        vm.prank(GUARDIAN);
        SUPERCHAIN.pause(LOCKBOX);
        assertTrue(SUPERCHAIN.paused(LOCKBOX));

        vm.prank(ATTACKER);
        (bool ok,) = address(L1CDM).call(
            abi.encodeCall(IMessenger.relayMessage, (r.nonce, r.sender, r.target, r.value, r.minGas, r.message))
        );
        assertFalse(ok);
        assertFalse(L1CDM.successfulMessages(keccak256(victim.wd.data)));

        vm.prank(GUARDIAN);
        SUPERCHAIN.unpause(LOCKBOX);
        _replay(r);
        _assertSettled(victim, r);
    }

    function test_C04_globalPauseStopsReplayThenUnpauseRestoresIt() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        vm.prank(GUARDIAN);
        SUPERCHAIN.pause(address(0));

        vm.prank(ATTACKER);
        (bool ok,) = address(L1CDM).call(
            abi.encodeCall(IMessenger.relayMessage, (r.nonce, r.sender, r.target, r.value, r.minGas, r.message))
        );
        assertFalse(ok);
        assertFalse(L1CDM.successfulMessages(keccak256(victim.wd.data)));

        vm.prank(GUARDIAN);
        SUPERCHAIN.unpause(address(0));
        _replay(r);
        _assertSettled(victim, r);
    }

    function test_C05_blacklistedDeletedProofCannotStopPostFinalizationReplay() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        (address game,) = PORTAL.provenWithdrawals(victim.hash, victim.submitter);
        assertFalse(ASR.isGameBlacklisted(game));

        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(game);
        PORTAL.deleteProvenWithdrawal(victim.hash, victim.submitter);
        (, uint64 timestamp) = PORTAL.provenWithdrawals(victim.hash, victim.submitter);
        assertEq(timestamp, 0);

        _replay(r);
        _assertSettled(victim, r);
    }

    function test_C06_realApplicationReplayFitsBelowEIP7825TransactionCap() public {
        (Prove memory victim, Relay memory r) = _forceApplicationFailure();
        vm.prank(ATTACKER);
        (bool ok,) = address(L1CDM).call{ gas: 16_000_000 }(
            abi.encodeCall(IMessenger.relayMessage, (r.nonce, r.sender, r.target, r.value, r.minGas, r.message))
        );
        assertTrue(ok);
        _assertSettled(victim, r);
    }

    function test_C07_hopOneShotReplayIsAlreadyEconomicallyApplied() public {
        ActiveFailure memory f = _activeFailure(4);
        bytes32 rootId = 0x57a69719b6d1bba62adf334d4424457861e031239ecabc36536442874d532e69;
        assertEq(HOP.transferRootCommittedAt(8453, rootId), 1_711_679_503);
        assertTrue(L1CDM.failedMessages(f.messageHash));
        assertFalse(L1CDM.successfulMessages(f.messageHash));

        vm.prank(ATTACKER);
        L1CDM.relayMessage(f.nonce, f.sender, f.target, f.value, f.minGas, f.message);
        assertTrue(L1CDM.failedMessages(f.messageHash));
        assertFalse(L1CDM.successfulMessages(f.messageHash));
        assertEq(ATTACKER.balance, 0);
    }

    function test_C08_synthetixWrongTargetIdentityStaysUnrelayable() public {
        ActiveFailure memory f = _activeFailure(11);
        assertEq(f.target, 0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F);
        assertTrue(L1CDM.failedMessages(f.messageHash));

        vm.prank(ATTACKER);
        L1CDM.relayMessage(f.nonce, f.sender, f.target, f.value, f.minGas, f.message);
        assertFalse(L1CDM.successfulMessages(f.messageHash));
        assertEq(ATTACKER.balance, 0);
    }

    function test_C09_forcedETHAndSiblingPortalCannotUseStickyLockboxAuthorization() public {
        assertTrue(LOCKBOX_STATE.authorizedPortals(address(PORTAL)));
        assertFalse(LOCKBOX_STATE.authorizedPortals(INK_PORTAL));

        vm.deal(ATTACKER, 1 ether);
        vm.startPrank(ATTACKER);
        CMP1ForceETH forceSender = new CMP1ForceETH{ value: 1 ether }();
        forceSender.force(payable(LOCKBOX));
        vm.stopPrank();
        assertEq(ATTACKER.balance, 0);

        uint256 forcedBalance = LOCKBOX.balance;
        vm.prank(ATTACKER);
        (bool attackerUnlock,) = LOCKBOX.call(abi.encodeCall(ILockboxState.unlockETH, (1 ether)));
        assertFalse(attackerUnlock);
        assertEq(LOCKBOX.balance, forcedBalance);

        // Even possession of a sibling portal identity would fail the exact-address gate.
        // This prank is a negative caller-identity check, not an exploit precondition.
        vm.deal(INK_PORTAL, 1 ether);
        vm.prank(INK_PORTAL);
        (bool siblingLock,) = LOCKBOX.call{ value: 1 ether }(abi.encodeCall(ILockboxState.lockETH, ()));
        assertFalse(siblingLock);
        assertEq(LOCKBOX.balance, forcedBalance);
    }
}
