// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./InFlightObjects.sol";

interface IPortalCarry {
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function checkWithdrawal(bytes32, address) external view;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
}

interface IMessengerCarry {
    function failedMessages(bytes32) external view returns (bool);
    function successfulMessages(bytes32) external view returns (bool);
}

/// @notice Carries real v7-created objects across exact v8 and v9 official upgrade calls.
contract CarryThroughTest is Test {
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant MESSENGER_ADDRESS_MANAGER_SLOT =
        0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e;

    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address internal constant DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant ETH_LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;

    function test_v7_proof_survives_v8_v9_and_finalizes() external {
        string memory proofJson = vm.readFile("fixtures/prove-v7-carry.json");
        WithdrawalTransaction memory withdrawal = _decodeProve(vm.parseJsonBytes(proofJson, ".input"));
        bytes32 withdrawalHash = _hashWithdrawal(withdrawal);
        address submitter = vm.parseJsonAddress(proofJson, ".from");
        assertEq(withdrawalHash, vm.parseJsonBytes32(proofJson, ".event.topics[1]"));

        _replayObjectTransaction(proofJson);
        (, uint64 provenAtV7) = IPortalCarry(PORTAL).provenWithdrawals(withdrawalHash, submitter);
        assertGt(provenAtV7, 0, "v7 proof absent");
        assertFalse(IPortalCarry(PORTAL).finalizedWithdrawals(withdrawalHash));
        emit log_string("stage=v7 proof=present finalized=false");

        // Keep precisely the object-owning proxy account while the fork base advances. All other
        // accounts are refreshed from real pre-upgrade state, including Safe nonces and new OPCMs.
        vm.makePersistent(PORTAL);
        vm.rollFork(26_048_618);
        _executeUpgrade("v8");
        (, uint64 provenAtV8) = IPortalCarry(PORTAL).provenWithdrawals(withdrawalHash, submitter);
        assertEq(provenAtV8, provenAtV7, "v8 rewrote proof timestamp");
        assertFalse(IPortalCarry(PORTAL).finalizedWithdrawals(withdrawalHash));
        emit log_string("stage=v8 proof=present timestamp=unchanged finalized=false");

        vm.rollFork(26_430_858);
        _executeUpgrade("v9");
        (, uint64 provenAtV9) = IPortalCarry(PORTAL).provenWithdrawals(withdrawalHash, submitter);
        assertEq(provenAtV9, provenAtV7, "v9 rewrote proof timestamp");
        assertFalse(IPortalCarry(PORTAL).finalizedWithdrawals(withdrawalHash));
        IPortalCarry(PORTAL).checkWithdrawal(withdrawalHash, submitter);

        uint256 targetBefore = withdrawal.target.balance;
        vm.prank(address(0xCF6), address(0xCF6));
        IPortalCarry(PORTAL).finalizeWithdrawalTransactionExternalProof(withdrawal, submitter);
        assertTrue(IPortalCarry(PORTAL).finalizedWithdrawals(withdrawalHash));
        assertEq(withdrawal.target.balance - targetBefore, withdrawal.value, "target value delta");
        emit log_string("stage=v9 proof=present finalized=true targetDelta=value");
    }

    function test_v7_failed_message_replays_after_v8_v9() external {
        string memory failedJson = vm.readFile("fixtures/failed-message-v7.json");
        WithdrawalTransaction memory withdrawal =
            _decodeFinalizeExternal(vm.parseJsonBytes(failedJson, ".input"));
        bytes32 messageHash = keccak256(withdrawal.data);
        assertEq(messageHash, vm.parseJsonBytes32(failedJson, ".event.topics[1]"));

        _replayObjectTransaction(failedJson);
        assertTrue(IMessengerCarry(L1CDM).failedMessages(messageHash));
        assertFalse(IMessengerCarry(L1CDM).successfulMessages(messageHash));
        emit log_string("stage=v7 failedMessages=true successfulMessages=false");

        vm.makePersistent(L1CDM);
        vm.rollFork(26_048_618);
        _executeUpgrade("v8");
        assertTrue(IMessengerCarry(L1CDM).failedMessages(messageHash));
        emit log_string("stage=v8 failedMessages=true");

        vm.rollFork(26_430_858);
        _executeUpgrade("v9");
        assertTrue(IMessengerCarry(L1CDM).failedMessages(messageHash));
        vm.prank(address(0xCF6), address(0xCF6));
        (bool ok, bytes memory returndata) = L1CDM.call(withdrawal.data);
        assertTrue(ok, string(returndata));
        emit log_named_string(
            "stage=v9 replay outcome",
            IMessengerCarry(L1CDM).successfulMessages(messageHash) ? "successful" : "failed-again"
        );
        assertTrue(
            IMessengerCarry(L1CDM).successfulMessages(messageHash)
                || IMessengerCarry(L1CDM).failedMessages(messageHash),
            "message lost from both replay mappings"
        );
    }

    function _executeUpgrade(string memory release) internal {
        string memory json = vm.readFile(string.concat("fixtures/upgrade-", release, ".json"));
        vm.roll(vm.parseJsonUint(json, ".block"));
        vm.warp(vm.parseJsonUint(json, ".blockTimestamp"));
        address sender = vm.parseJsonAddress(json, ".from");
        address target = vm.parseJsonAddress(json, ".to");
        uint256 value = vm.parseJsonUint(json, ".value");
        if (value != 0) vm.deal(sender, sender.balance + value);
        vm.prank(sender, sender);
        (bool ok, bytes memory returndata) = target.call{
            value: value,
            gas: vm.parseJsonUint(json, ".gas")
        }(vm.parseJsonBytes(json, ".input"));
        if (!ok) {
            emit log_named_bytes(string.concat(release, " carry replay revert"), returndata);
            fail();
        }
        _assertUpgradePostState(json);
    }

    function _assertUpgradePostState(string memory json) internal view {
        _assertImpl(json, ".expected.OptimismPortal", PORTAL, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.SystemConfig", 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, IMPLEMENTATION_SLOT);
        _assertImpl(
            json,
            ".expected.L1CrossDomainMessenger",
            ADDRESS_MANAGER,
            MESSENGER_ADDRESS_MANAGER_SLOT
        );
        _assertImpl(json, ".expected.L1StandardBridge", L1_STANDARD_BRIDGE, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.DisputeGameFactory", DGF, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.AnchorStateRegistry", ASR, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.ETHLockbox", ETH_LOCKBOX, IMPLEMENTATION_SLOT);
    }

    function _assertImpl(string memory json, string memory path, address account, bytes32 slot) internal view {
        address actual = address(uint160(uint256(vm.load(account, slot))));
        assertEq(actual, vm.parseJsonAddress(json, path), path);
    }

    function _replayObjectTransaction(string memory json) internal {
        uint256 blockNumber = vm.parseJsonUint(json, ".block");
        vm.createSelectFork("archive", blockNumber - 1);
        vm.roll(blockNumber);
        vm.warp(vm.parseJsonUint(json, ".blockTimestamp"));
        address sender = vm.parseJsonAddress(json, ".from");
        vm.prank(sender, sender);
        (bool ok, bytes memory returndata) = vm.parseJsonAddress(json, ".to").call{
            value: vm.parseJsonUint(json, ".value"),
            gas: vm.parseJsonUint(json, ".gas")
        }(vm.parseJsonBytes(json, ".input"));
        if (!ok) {
            emit log_named_bytes("object replay revert", returndata);
            fail();
        }
    }

    function _decodeProve(bytes memory input) internal pure returns (WithdrawalTransaction memory withdrawal) {
        OutputRootProof memory outputRootProof;
        bytes[] memory withdrawalProof;
        uint256 gameIndex;
        (withdrawal, gameIndex, outputRootProof, withdrawalProof) = abi.decode(
            _withoutSelector(input), (WithdrawalTransaction, uint256, OutputRootProof, bytes[])
        );
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
}

interface IPortalDifferential {
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
    function donateETH() external payable;
}

interface IMessengerDifferential {
    function sendMessage(address, bytes calldata, uint32) external payable;
}

/// @notice A small generic outcome diff over the exact v8 -> v9 OP Mainnet boundary.
contract DifferentialRunnerTest is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant ACTOR = address(0xCF6D1FF);

    enum Probe {
        Deposit,
        Donate,
        SendMessage,
        CheckUnknownWithdrawal,
        DeleteUnknownProof
    }

    struct Outcome {
        bool success;
        bytes4 revertSelector;
        uint256 eventCount;
        int256 actorDelta;
        int256 portalDelta;
        int256 lockboxDelta;
    }

    function test_differential_five_permissionless_calls() external {
        uint256 v8Fork = vm.createFork("archive", 26_430_858);
        uint256 v9Fork = vm.createFork("archive", 26_430_859);
        string memory output = "differential-results.md";
        vm.writeFile(
            output,
            "| Call | Fork | success | revert selector | events | actor delta | portal delta | lockbox delta |\n"
        );
        vm.writeLine(output, "|---|---:|:---:|---|---:|---:|---:|---:|");

        for (uint256 i; i < 5; i++) {
            Probe probe = Probe(i);
            Outcome memory before = _run(v8Fork, probe);
            Outcome memory after_ = _run(v9Fork, probe);
            _writeOutcome(output, _probeName(probe), "26430858 (v8)", before);
            _writeOutcome(output, _probeName(probe), "26430859 (v9)", after_);
        }
    }

    function _run(uint256 forkId, Probe probe) internal returns (Outcome memory outcome) {
        vm.selectFork(forkId);
        vm.deal(ACTOR, 10 ether);
        uint256 actorBefore = ACTOR.balance;
        uint256 portalBefore = PORTAL.balance;
        uint256 lockboxBefore = LOCKBOX.balance;
        bytes memory payload;
        address target;
        uint256 value;
        if (probe == Probe.Deposit) {
            target = PORTAL;
            value = 1 gwei;
            payload = abi.encodeCall(
                IPortalDifferential.depositTransaction,
                (address(0xCF6D2), 1 gwei, uint64(100_000), false, bytes("cf6"))
            );
        } else if (probe == Probe.Donate) {
            target = PORTAL;
            value = 777;
            payload = abi.encodeCall(IPortalDifferential.donateETH, ());
        } else if (probe == Probe.SendMessage) {
            target = L1CDM;
            payload = abi.encodeCall(
                IMessengerDifferential.sendMessage,
                (address(0xCF6D3), bytes("cross-upgrade-diff"), uint32(100_000))
            );
        } else if (probe == Probe.CheckUnknownWithdrawal) {
            target = PORTAL;
            payload = abi.encodeWithSignature(
                "checkWithdrawal(bytes32,address)", bytes32(uint256(0xCF6)), ACTOR
            );
        } else {
            target = PORTAL;
            payload = abi.encodeWithSignature(
                "deleteProvenWithdrawal(bytes32,address)", bytes32(uint256(0xCF6)), ACTOR
            );
        }

        vm.recordLogs();
        vm.prank(ACTOR, ACTOR);
        bytes memory returndata;
        (outcome.success, returndata) = target.call{ value: value }(payload);
        outcome.eventCount = vm.getRecordedLogs().length;
        if (!outcome.success && returndata.length >= 4) {
            assembly {
                mstore(add(outcome, 0x20), mload(add(returndata, 0x20)))
            }
        }
        outcome.actorDelta = int256(ACTOR.balance) - int256(actorBefore);
        outcome.portalDelta = int256(PORTAL.balance) - int256(portalBefore);
        outcome.lockboxDelta = int256(LOCKBOX.balance) - int256(lockboxBefore);
    }

    function _writeOutcome(
        string memory output,
        string memory callName,
        string memory forkName,
        Outcome memory outcome
    ) internal {
        vm.writeLine(
            output,
            string.concat(
                "| ",
                callName,
                " | ",
                forkName,
                " | ",
                outcome.success ? "yes" : "no",
                " | ",
                _hex4(outcome.revertSelector),
                " | ",
                vm.toString(outcome.eventCount),
                " | ",
                vm.toString(outcome.actorDelta),
                " | ",
                vm.toString(outcome.portalDelta),
                " | ",
                vm.toString(outcome.lockboxDelta),
                " |"
            )
        );
    }

    function _probeName(Probe probe) internal pure returns (string memory) {
        if (probe == Probe.Deposit) return "depositTransaction";
        if (probe == Probe.Donate) return "donateETH";
        if (probe == Probe.SendMessage) return "sendMessage";
        if (probe == Probe.CheckUnknownWithdrawal) return "checkWithdrawal(unknown)";
        return "deleteProvenWithdrawal(unknown)";
    }

    function _hex4(bytes4 value) internal pure returns (string memory) {
        bytes16 alphabet = "0123456789abcdef";
        bytes memory result = new bytes(10);
        result[0] = "0";
        result[1] = "x";
        uint32 raw = uint32(value);
        for (uint256 i; i < 8; i++) {
            result[2 + i] = alphabet[(raw >> (28 - 4 * i)) & 0x0f];
        }
        return string(result);
    }
}
