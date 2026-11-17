// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

interface IPortalObjects {
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
}

interface IMessengerObjects {
    function failedMessages(bytes32) external view returns (bool);
}

interface IDisputeGameFactoryObjects {
    function gameCount() external view returns (uint256);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
}

interface IAnchorStateRegistryObjects {
    function getAnchorRoot() external view returns (bytes32 root, uint256 l2BlockNumber);
}

interface IDisputeGameObjects {
    function status() external view returns (uint8);
}

/// @notice Creates or replays four real in-flight object classes through protocol entry points.
/// @dev No storage injection, mock, or privileged impersonation is used in these tests.
contract InFlightObjectsTest is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant L2CDM = 0x4200000000000000000000000000000000000007;

    bytes32 internal constant DEPOSIT_EVENT = keccak256("TransactionDeposited(address,address,uint256,bytes)");
    bytes32 internal constant PROVEN_EVENT = keccak256("WithdrawalProven(bytes32,address,address)");
    bytes32 internal constant FAILED_EVENT = keccak256("FailedRelayedMessage(bytes32)");

    function test_create_deposit_v7() external {
        vm.createSelectFork("archive", 25_397_812);
        address depositor = address(0xCF6001);
        vm.deal(depositor, 1 ether);
        vm.recordLogs();
        vm.prank(depositor, depositor);
        IPortalObjects(PORTAL).depositTransaction{ value: 0.25 ether }(
            address(0xCF6002), 0.25 ether, 100_000, false, hex"c0ffee"
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertTrue(_hasTopic(logs, PORTAL, DEPOSIT_EVENT), "deposit event missing");
    }

    function test_replay_real_prove_v7() external {
        string memory json = vm.readFile("fixtures/prove-v7.json");
        bytes memory input = vm.parseJsonBytes(json, ".input");
        WithdrawalTransaction memory withdrawal = _decodeProve(input);
        bytes32 withdrawalHash = _hashWithdrawal(withdrawal);
        assertEq(withdrawalHash, vm.parseJsonBytes32(json, ".event.topics[1]"));

        address submitter = vm.parseJsonAddress(json, ".from");
        Vm.Log[] memory logs = _replayFixture(json);
        (address game, uint64 timestamp) = IPortalObjects(PORTAL).provenWithdrawals(withdrawalHash, submitter);
        assertNotEq(game, address(0), "proof game missing");
        assertGt(timestamp, 0, "proof timestamp missing");
        assertTrue(_hasTopic(logs, PORTAL, PROVEN_EVENT), "WithdrawalProven missing");
    }

    function test_replay_real_failed_message_v7() external {
        string memory json = vm.readFile("fixtures/failed-message-v7.json");
        bytes memory input = vm.parseJsonBytes(json, ".input");
        WithdrawalTransaction memory withdrawal = _decodeFinalizeExternal(input);
        assertEq(withdrawal.sender, L2CDM, "fixture is not a messenger withdrawal");
        bytes32 messageHash = keccak256(withdrawal.data);
        assertEq(messageHash, vm.parseJsonBytes32(json, ".event.topics[1]"));

        Vm.Log[] memory logs = _replayFixture(json);
        assertTrue(IMessengerObjects(L1CDM).failedMessages(messageHash), "failedMessages not set");
        assertTrue(_hasTopic(logs, L1CDM, FAILED_EVENT), "FailedRelayedMessage missing");
    }

    function test_create_in_progress_dispute_game_v7() external {
        vm.createSelectFork("archive", 25_397_812);
        uint32 gameType = 8; // CANNON_KONA, permissionless at the v7 fork point.
        uint256 bond = IDisputeGameFactoryObjects(DGF).initBonds(gameType);
        (, uint256 anchorBlock) = IAnchorStateRegistryObjects(ASR).getAnchorRoot();
        bytes memory extraData = abi.encode(anchorBlock + 1);
        bytes32 rootClaim = keccak256("CF6 in-progress historical game");
        address creator = address(0xCF6003);
        vm.deal(creator, bond);
        uint256 beforeCount = IDisputeGameFactoryObjects(DGF).gameCount();
        vm.prank(creator, creator);
        address game = IDisputeGameFactoryObjects(DGF).create{ value: bond }(gameType, rootClaim, extraData);
        assertEq(IDisputeGameFactoryObjects(DGF).gameCount(), beforeCount + 1);
        assertGt(game.code.length, 0);
        assertEq(IDisputeGameObjects(game).status(), 0, "new game not IN_PROGRESS");
    }

    function _replayFixture(string memory json) internal returns (Vm.Log[] memory logs) {
        uint256 blockNumber = vm.parseJsonUint(json, ".block");
        vm.createSelectFork("archive", blockNumber - 1);
        vm.roll(blockNumber);
        vm.warp(vm.parseJsonUint(json, ".blockTimestamp"));
        address sender = vm.parseJsonAddress(json, ".from");
        address target = vm.parseJsonAddress(json, ".to");
        uint256 value = vm.parseJsonUint(json, ".value");
        if (value != 0) vm.deal(sender, sender.balance + value);
        vm.recordLogs();
        vm.prank(sender, sender);
        (bool ok, bytes memory returndata) = target.call{
            value: value,
            gas: vm.parseJsonUint(json, ".gas")
        }(vm.parseJsonBytes(json, ".input"));
        if (!ok) {
            emit log_named_bytes("fixture replay revert", returndata);
            fail();
        }
        logs = vm.getRecordedLogs();
    }

    function _decodeProve(bytes memory input) internal pure returns (WithdrawalTransaction memory withdrawal) {
        bytes memory body = _withoutSelector(input);
        OutputRootProof memory outputRootProof;
        bytes[] memory withdrawalProof;
        uint256 gameIndex;
        (withdrawal, gameIndex, outputRootProof, withdrawalProof) =
            abi.decode(body, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
        gameIndex;
        outputRootProof;
        withdrawalProof;
    }

    function _decodeFinalizeExternal(bytes memory input)
        internal
        pure
        returns (WithdrawalTransaction memory withdrawal)
    {
        address proofSubmitter;
        (withdrawal, proofSubmitter) = abi.decode(_withoutSelector(input), (WithdrawalTransaction, address));
        proofSubmitter;
    }

    function _withoutSelector(bytes memory input) internal pure returns (bytes memory body) {
        require(input.length >= 4, "short calldata");
        body = new bytes(input.length - 4);
        for (uint256 i = 4; i < input.length; i++) body[i - 4] = input[i];
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

    function _hasTopic(Vm.Log[] memory logs, address emitter, bytes32 topic0) internal pure returns (bool) {
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter == emitter && logs[i].topics.length != 0 && logs[i].topics[0] == topic0) {
                return true;
            }
        }
        return false;
    }
}
