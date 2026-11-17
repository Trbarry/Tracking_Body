// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

interface IPortal24 {
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }

    function version() external view returns (string memory);
    function l2Sender() external view returns (address);
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory _tx) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory _tx, address _proofSubmitter)
        external;
    function finalizedWithdrawals(bytes32 _hash) external view returns (bool);
    function provenWithdrawals(bytes32 _hash, address _submitter) external view returns (address, uint64);
    function checkWithdrawal(bytes32 _hash, address _submitter) external view;
    function deleteProvenWithdrawal(bytes32 _hash, address _submitter) external;
}

interface IMessenger24 {
    function version() external view returns (string memory);
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes memory _message
    ) external payable;
    function baseGas(bytes memory _message, uint32 _minGasLimit) external pure returns (uint64);
    function successfulMessages(bytes32 _hash) external view returns (bool);
    function failedMessages(bytes32 _hash) external view returns (bool);
}

interface IGame24 {
    function createdAt() external view returns (uint64);
    function status() external view returns (uint8);
}

contract GasGate24 {
    uint256 public immutable minEntryGas;
    uint256 public calls;
    uint256 public lastEntryGas;
    uint256 public totalValue;

    constructor(uint256 _minEntryGas) {
        minEntryGas = _minEntryGas;
    }

    fallback() external payable {
        uint256 entryGas = gasleft();
        if (entryGas < minEntryGas) revert("GasGate24: low gas");
        lastEntryGas = entryGas;
        calls++;
        totalValue += msg.value;
    }
}

contract ToggleTarget24 {
    bool public reject = true;
    uint256 public calls;
    uint256 public totalValue;

    function setReject(bool _reject) external {
        reject = _reject;
    }

    fallback() external payable {
        if (reject) revert("ToggleTarget24: rejected");
        calls++;
        totalValue += msg.value;
    }
}

contract AlwaysRevert24 {
    fallback() external payable {
        revert("AlwaysRevert24");
    }
}

contract ReturnBomb24 {
    fallback() external payable {
        assembly {
            return(0, 0x10000)
        }
    }
}

contract Ephemeral24 {
    constructor() {
        selfdestruct(payable(msg.sender));
    }
}

contract WithdrawalFinalization24Test is Test {
    event FailedRelayedMessage(bytes32 indexed msgHash);

    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;

    // Real, finalized, respected type-9 games at the pinned post-U21 block.
    address internal constant VALID_GAME_A = 0xedA34E8CEBc7FC0914F89272D9D8Db177e4E1258; // factory index 20800
    address internal constant VALID_GAME_B = 0xf60fB779a19e0805AbaC9081bD7e9863357164d7; // factory index 20700

    address internal constant PROOF_SUBMITTER = address(0x2400BEEF);
    address internal constant USER = address(0x2400C0DE);

    bytes4 internal constant ERR_L1_CDM_CALL_FAILED =
        bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"));
    bytes4 internal constant ERR_ALREADY_FINALIZED = bytes4(keccak256("OptimismPortal_AlreadyFinalized()"));
    bytes4 internal constant ERR_UNPROVEN = bytes4(keccak256("OptimismPortal_Unproven()"));

    IPortal24 internal constant portal = IPortal24(PORTAL);
    IMessenger24 internal constant messenger = IMessenger24(L1_MESSENGER);

    function setUp() external {
        vm.createSelectFork("lane24");
        assertEq(portal.version(), "6.1.0");
    }

    function _hash(IPortal24.WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
        return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
    }

    function _tx(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (IPortal24.WithdrawalTransaction memory) {
        return IPortal24.WithdrawalTransaction({
            nonce: _nonce,
            sender: _sender,
            target: _target,
            value: _value,
            gasLimit: _gasLimit,
            data: _data
        });
    }

    /// @dev Installs only the proof-record slot. The game and all validation calls are real deployed state.
    ///      This models a production-reachable proof for an arbitrary L2 withdrawal without mocking Portal code.
    function _installProof(bytes32 _withdrawalHash, address _submitter, address _game) internal {
        uint64 timestamp = IGame24(_game).createdAt() + 1;
        bytes32 first = keccak256(abi.encode(_withdrawalHash, uint256(57)));
        bytes32 slot = keccak256(abi.encode(_submitter, first));
        uint256 packed = uint256(uint160(_game)) | (uint256(timestamp) << 160);
        vm.store(PORTAL, slot, bytes32(packed));

        (address storedGame, uint64 storedTimestamp) = portal.provenWithdrawals(_withdrawalHash, _submitter);
        assertEq(storedGame, _game);
        assertEq(storedTimestamp, timestamp);
        portal.checkWithdrawal(_withdrawalHash, _submitter);
    }

    function _finalizeExternal(IPortal24.WithdrawalTransaction memory _withdrawal, address _submitter) internal {
        portal.finalizeWithdrawalTransactionExternalProof(_withdrawal, _submitter);
    }

    function _messageHash(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGas,
        bytes memory _message
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                _nonce,
                _sender,
                _target,
                _value,
                _minGas,
                _message
            )
        );
    }

    function test_valueToTrulyEmptyEOA_succeedsDespiteConservativeAmsterdamReserve() external {
        // This untouched account is nonce-zero, balance-zero and code-empty on the pinned fork.
        // Unlike an account created and destroyed in this test transaction, EXTCODEHASH is zero.
        address empty = address(0x101);
        assertEq(empty.balance, 0);
        assertEq(empty.code.length, 0);
        assertEq(_codehash(empty), bytes32(0));

        IPortal24.WithdrawalTransaction memory withdrawal = _tx(1, USER, empty, 1 ether, 21_000, hex"");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);

        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertEq(empty.balance, 1 ether);
        assertEq(address(PORTAL).balance, 0);
    }

    function test_valueToFundedCodeEmptyEOA_hasKeccakEmptyCodehashAndSucceeds() external {
        address funded = address(new Ephemeral24());
        vm.deal(funded, 1 wei);
        assertEq(funded.code.length, 0);
        assertEq(_codehash(funded), keccak256(hex""));

        IPortal24.WithdrawalTransaction memory withdrawal = _tx(2, USER, funded, 1 ether, 21_000, hex"");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);
        _finalizeExternal(withdrawal, PROOF_SUBMITTER);

        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertEq(funded.balance, 1 ether + 1 wei);
    }

    function test_contractTargets_zeroAndNonzeroValue_succeed() external {
        GasGate24 zeroTarget = new GasGate24(0);
        IPortal24.WithdrawalTransaction memory zeroWithdrawal =
            _tx(3, USER, address(zeroTarget), 0, 50_000, hex"2403");
        _installProof(_hash(zeroWithdrawal), PROOF_SUBMITTER, VALID_GAME_A);
        _finalizeExternal(zeroWithdrawal, PROOF_SUBMITTER);
        assertEq(zeroTarget.calls(), 1);
        assertEq(zeroTarget.totalValue(), 0);

        GasGate24 valueTarget = new GasGate24(0);
        IPortal24.WithdrawalTransaction memory valueWithdrawal =
            _tx(4, USER, address(valueTarget), 2 ether, 80_000, hex"2404");
        _installProof(_hash(valueWithdrawal), PROOF_SUBMITTER, VALID_GAME_A);
        _finalizeExternal(valueWithdrawal, PROOF_SUBMITTER);
        assertEq(valueTarget.calls(), 1);
        assertEq(valueTarget.totalValue(), 2 ether);
    }

    function test_revertingValueTarget_isFinalizedAndValueRelocked() external {
        AlwaysRevert24 target = new AlwaysRevert24();
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(5, USER, address(target), 3 ether, 80_000, hex"2405");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);
        uint256 lockboxBefore = LOCKBOX.balance;
        uint256 targetBefore = address(target).balance;

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);

        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertEq(address(target).balance, targetBefore);
        assertEq(PORTAL.balance, 0);
        assertEq(LOCKBOX.balance, lockboxBefore);

        vm.expectRevert(ERR_ALREADY_FINALIZED);
        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
    }

    function test_returnBomb_doesNotBombPortal() external {
        ReturnBomb24 target = new ReturnBomb24();
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(6, USER, address(target), 0, 250_000, hex"2406");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
    }

    function test_probeThirdPartyGasWindow_forEconomicNonDelivery() external {
        uint256 harmfulCap;
        uint256 targetEntryGas;
        uint256 lockboxBefore = LOCKBOX.balance;

        for (uint256 cap = 350_000; cap <= 1_200_000; cap += 25_000) {
            GasGate24 target = new GasGate24(260_000);
            IPortal24.WithdrawalTransaction memory withdrawal =
                _tx(10_000 + cap, USER, address(target), 1 ether, 30_000, hex"24aa");
            bytes32 withdrawalHash = _hash(withdrawal);
            _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);
            uint256 targetBefore = address(target).balance;

            (bool outerSuccess,) = PORTAL.call{ gas: cap }(
                abi.encodeCall(portal.finalizeWithdrawalTransactionExternalProof, (withdrawal, PROOF_SUBMITTER))
            );

            if (outerSuccess && portal.finalizedWithdrawals(withdrawalHash) && target.calls() == 0) {
                harmfulCap = cap;
                targetEntryGas = target.lastEntryGas();
                assertEq(address(target).balance, targetBefore);
                assertEq(PORTAL.balance, 0);
                assertEq(LOCKBOX.balance, lockboxBefore);
                break;
            }
        }

        emit log_named_uint("harmful outer gas cap", harmfulCap);
        emit log_named_uint("target recorded entry gas (zero means reverted)", targetEntryGas);
        assertGt(harmfulCap, 0, "no outer-success/inner-failure gas window found");
    }

    function test_sameWithdrawalShapeWithAdequateOuterGas_deliversValue() external {
        GasGate24 target = new GasGate24(260_000);
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(14, USER, address(target), 1 ether, 30_000, hex"24ab");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);

        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertEq(target.calls(), 1);
        assertEq(target.totalValue(), 1 ether);
        assertGe(target.lastEntryGas(), 260_000);
    }

    function test_externalProofIsTheThirdPartyPath_standardEntryUsesCallerProof() external {
        AlwaysRevert24 target = new AlwaysRevert24();
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(7, USER, address(target), 1 ether, 50_000, hex"2407");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        vm.expectRevert(ERR_UNPROVEN);
        portal.finalizeWithdrawalTransaction(withdrawal);
        assertFalse(portal.finalizedWithdrawals(withdrawalHash));

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
    }

    function test_senderOnlyFailureRule_L2MessengerSenderToNonMessengerTarget_reverts() external {
        AlwaysRevert24 target = new AlwaysRevert24();
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(8, L2_MESSENGER, address(target), 0, 50_000, hex"2408");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        vm.expectRevert(ERR_L1_CDM_CALL_FAILED);
        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
        assertFalse(portal.finalizedWithdrawals(withdrawalHash));
    }

    function test_senderOnlyFailureRule_nonMessengerSenderToL1MessengerTarget_finalizesFalse() external {
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(9, USER, L1_MESSENGER, 0, 50_000, hex"deadbeef");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
    }

    function test_messengerTargetFailure_isRecordedAndReplaySucceedsExactlyOnce() external {
        ToggleTarget24 target = new ToggleTarget24();
        uint256 nonce = (uint256(1) << 240) | 24;
        address xSender = address(0x24001234);
        uint256 minGas = 80_000;
        bytes memory appMessage = hex"";
        bytes memory relayData = abi.encodeCall(
            messenger.relayMessage, (nonce, xSender, address(target), 0, minGas, appMessage)
        );
        bytes32 messageHash = _messageHash(nonce, xSender, address(target), 0, minGas, appMessage);
        assertEq(messageHash, keccak256(relayData));

        IPortal24.WithdrawalTransaction memory withdrawal = _tx(
            10,
            L2_MESSENGER,
            L1_MESSENGER,
            0,
            messenger.baseGas(appMessage, uint32(minGas)),
            relayData
        );
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertTrue(messenger.failedMessages(messageHash));
        assertFalse(messenger.successfulMessages(messageHash));
        assertEq(target.calls(), 0);

        target.setReject(false);
        messenger.relayMessage(nonce, xSender, address(target), 0, minGas, appMessage);
        assertTrue(messenger.failedMessages(messageHash));
        assertTrue(messenger.successfulMessages(messageHash));
        assertEq(target.calls(), 1);

        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        messenger.relayMessage(nonce, xSender, address(target), 0, minGas, appMessage);

        vm.expectRevert(ERR_ALREADY_FINALIZED);
        _finalizeExternal(withdrawal, PROOF_SUBMITTER);
    }

    function test_messengerRevertsBeforeRecording_portalRollbackPreservesFinalizationPath() external {
        uint256 nonce = (uint256(1) << 240) | 25;
        address xSender = address(0x24005678);
        uint256 minGas = 50_000;
        bytes memory appMessage = hex"";
        // The L1 messenger rejects itself as the application target before writing failedMessages.
        bytes memory relayData =
            abi.encodeCall(messenger.relayMessage, (nonce, xSender, L1_MESSENGER, 0, minGas, appMessage));
        bytes32 messageHash = _messageHash(nonce, xSender, L1_MESSENGER, 0, minGas, appMessage);

        IPortal24.WithdrawalTransaction memory withdrawal = _tx(
            11,
            L2_MESSENGER,
            L1_MESSENGER,
            0,
            messenger.baseGas(appMessage, uint32(minGas)),
            relayData
        );
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, PROOF_SUBMITTER, VALID_GAME_A);

        vm.expectRevert(ERR_L1_CDM_CALL_FAILED);
        _finalizeExternal(withdrawal, PROOF_SUBMITTER);

        assertFalse(portal.finalizedWithdrawals(withdrawalHash));
        assertFalse(messenger.failedMessages(messageHash));
        assertFalse(messenger.successfulMessages(messageHash));
    }

    function test_v8FailedMessageStorage_replaysUnderV9CodeAndRemainsSingleExecution() external {
        ToggleTarget24 target = new ToggleTarget24();
        target.setReject(false);
        uint256 nonce = (uint256(1) << 240) | 26;
        address xSender = address(0x24007890);
        uint256 minGas = 80_000;
        bytes memory appMessage = hex"";
        bytes32 messageHash = _messageHash(nonce, xSender, address(target), 0, minGas, appMessage);

        // v8 and v9 both store failedMessages at slot 206. Install the one-bit state that a v8
        // failed relay leaves behind, then execute the replay through deployed v9 messenger code.
        bytes32 failedSlot = keccak256(abi.encode(messageHash, uint256(206)));
        vm.store(L1_MESSENGER, failedSlot, bytes32(uint256(1)));
        assertTrue(messenger.failedMessages(messageHash));
        assertFalse(messenger.successfulMessages(messageHash));

        messenger.relayMessage(nonce, xSender, address(target), 0, minGas, appMessage);

        assertTrue(messenger.failedMessages(messageHash));
        assertTrue(messenger.successfulMessages(messageHash));
        assertEq(target.calls(), 1);
        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        messenger.relayMessage(nonce, xSender, address(target), 0, minGas, appMessage);
    }

    function test_realV8FailedMessage_replaysThroughV9AndRemainsRecordedFailed() external {
        // FailedRelayedMessage emitted in v8 at block 26,385,051, tx
        // 0x39d668d98f82c46c021edabfda5b7187012022e9d018aee4998852835a667155.
        uint256 nonce =
            1766847064778384329583297500742918515827483896875618958121606201292639349;
        address xSender = 0x136b1EC699c62b0606854056f02dC7Bb80482d63;
        address target = 0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F;
        uint256 minGas = 3_000_000;
        bytes memory appMessage =
            hex"a6492fe27355534400000000000000000000000000000000000000000000000000000000000000000000000000000000d3ae25ddb644b1d1915cd0bde7a5d090bc7cf39900000000000000000000000000000000000000000000001e084b60c83e680000";
        bytes32 messageHash = 0x9546105b80a67d2890768f2cf1c9bfdbc6d855ed8e8d7f47373d491b8bb11312;
        assertEq(messageHash, _messageHash(nonce, xSender, target, 0, minGas, appMessage));
        assertTrue(messenger.failedMessages(messageHash));
        assertFalse(messenger.successfulMessages(messageHash));

        vm.expectEmit(true, false, false, false, L1_MESSENGER);
        emit FailedRelayedMessage(messageHash);
        messenger.relayMessage(nonce, xSender, target, 0, minGas, appMessage);

        assertTrue(messenger.failedMessages(messageHash));
        assertFalse(messenger.successfulMessages(messageHash));
    }

    function test_multipleSubmittersAndGames_shareGlobalReplayBit() external {
        GasGate24 target = new GasGate24(0);
        address submitterA = address(0x2400AAA1);
        address submitterB = address(0x2400BBB2);
        IPortal24.WithdrawalTransaction memory withdrawal =
            _tx(12, USER, address(target), 0, 50_000, hex"2412");
        bytes32 withdrawalHash = _hash(withdrawal);
        _installProof(withdrawalHash, submitterA, VALID_GAME_A);
        _installProof(withdrawalHash, submitterB, VALID_GAME_B);

        _finalizeExternal(withdrawal, submitterB);
        assertTrue(portal.finalizedWithdrawals(withdrawalHash));
        assertEq(target.calls(), 1);

        vm.expectRevert(ERR_ALREADY_FINALIZED);
        _finalizeExternal(withdrawal, submitterA);
        assertEq(target.calls(), 1);
    }

    function test_deleteThenRecreateProofSlot_canFinalize() external {
        bytes32 realPreUpgradeHash =
            0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d;
        address realSubmitter = 0x47728c875b7F52a40227d662f83a3C3d0f7E6FBB;
        address realGame = 0x86512332B510F40Bb9361dE685cA1e4815dEe5fe;

        (address storedGame,) = portal.provenWithdrawals(realPreUpgradeHash, realSubmitter);
        assertEq(storedGame, realGame);

        // Model the production-reachable future in which this currently-IN_PROGRESS game resolves
        // CHALLENGER_WINS. Only the game's status call is mocked; deletion runs on deployed Portal code.
        vm.mockCall(realGame, abi.encodeCall(IGame24.status, ()), abi.encode(uint8(1)));
        portal.deleteProvenWithdrawal(realPreUpgradeHash, realSubmitter);
        (storedGame,) = portal.provenWithdrawals(realPreUpgradeHash, realSubmitter);
        assertEq(storedGame, address(0));
        vm.clearMockedCalls();

        GasGate24 target = new GasGate24(0);
        IPortal24.WithdrawalTransaction memory replacement =
            _tx(13, USER, address(target), 0, 50_000, hex"2413");
        bytes32 replacementHash = _hash(replacement);
        // Recreate the same submitter key against another valid game, as re-proving would do.
        _installProof(replacementHash, realSubmitter, VALID_GAME_A);
        _finalizeExternal(replacement, realSubmitter);
        assertEq(target.calls(), 1);
    }

    function test_realV8ProofPersistsAtBlockN_afterUpgrade() external {
        vm.createSelectFork("l1n");
        assertEq(portal.version(), "6.1.0");

        bytes32 withdrawalHash =
            0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d;
        address submitter = 0x47728c875b7F52a40227d662f83a3C3d0f7E6FBB;
        (address game, uint64 timestamp) = portal.provenWithdrawals(withdrawalHash, submitter);
        assertEq(game, 0x86512332B510F40Bb9361dE685cA1e4815dEe5fe);
        assertEq(timestamp, 1_794_861_023);
        assertFalse(portal.finalizedWithdrawals(withdrawalHash));
    }

    function _codehash(address _account) internal view returns (bytes32 result) {
        assembly {
            result := extcodehash(_account)
        }
    }
}
