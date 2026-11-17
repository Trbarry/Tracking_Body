// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

interface IMessagePasser {
    function messageNonce() external view returns (uint256);
    function sentMessages(bytes32) external view returns (bool);
    function version() external view returns (string memory);
}

contract BigSender {
    function send(address cdm, address target, uint256 len, uint32 minGas) external payable {
        bytes memory m = new bytes(len);
        ICDM(cdm).sendMessage{ value: msg.value }(target, m, minGas);
    }
}

contract Sink2 {
    uint256 public hits;
    fallback() external payable { hits++; }
}

/// OP Mainnet (L2) side: live L2CrossDomainMessenger v2.2.1 (no L2 hardfork in U21).
contract L2Side08Test is Base08 {
    ICDM constant l2cdm = ICDM(L2CDM);
    IMessagePasser constant mp = IMessagePasser(0x4200000000000000000000000000000000000016);

    function setUp() public {
        vm.createSelectFork("l2");
    }

    /// live L2 baseGas == replicated formula used by the L1 harness
    function test_l2_baseGas_matches_formula() public {
        assertEq(l2cdm.version(), "2.2.1");
        uint32[6] memory ms = [uint32(0), 1, 200_000, 350_000, 3_000_000, type(uint32).max];
        uint256[8] memory lens = [uint256(0), 1, 164, 228, 10_000, 11_616, 100_000, 300_000];
        for (uint256 i; i < ms.length; i++) {
            for (uint256 j; j < lens.length; j++) {
                assertEq(l2cdm.baseGas(new bytes(lens[j]), ms[i]), l2BaseGasLive(lens[j], ms[i]));
            }
        }
        emit log_named_uint("baseGas(len=164,m=0)  [ETH bridge wd]", l2cdm.baseGas(new bytes(164), 0));
        emit log_named_uint("baseGas(len=228,m=200000) [ERC20 bridge wd]", l2cdm.baseGas(new bytes(228), 200_000));
    }

    /// the withdrawal the live L2CDM actually registers == what the L1 harness fabricates
    function test_l2_sendMessage_registers_expected_withdrawal() public {
        address user = makeAddr("user");
        vm.deal(user, 10 ether);
        uint256 mpNonce = mp.messageNonce();
        uint256 cdmNonce = l2cdm.messageNonce();
        bytes memory m = hex"c0ffee";
        vm.prank(user);
        l2cdm.sendMessage{ value: 1 ether }(address(0xBEEF), m, 123_456);
        WithdrawalTransaction memory w;
        w.nonce = mpNonce;
        w.sender = L2CDM;
        w.target = address(l1cdm);
        w.value = 1 ether;
        w.gasLimit = l2BaseGasLive(m.length, 123_456);
        w.data = relayCalldata(cdmNonce, user, address(0xBEEF), 1 ether, 123_456, m);
        assertTrue(mp.sentMessages(hashWithdrawal(w)), "withdrawal hash registered with formula gasLimit");
    }

    /// how large a message can a contract push through the live L2CDM, and at what L2 gas
    function test_l2_large_message_cost() public {
        BigSender s = new BigSender();
        uint256[5] memory lens = [uint256(10_000), 100_000, 300_000, 600_000, 1_000_000];
        for (uint256 i; i < lens.length; i++) {
            uint256 g = gasleft();
            try s.send{ gas: 200_000_000 }(L2CDM, address(0xBEEF), lens[i], 0) {
                emit log_named_uint(string.concat("L2 gas to send len=", vm.toString(lens[i])), g - gasleft());
                emit log_named_uint("   withdrawal gasLimit (baseGas)", l2cdm.baseGas(new bytes(lens[i]), 0));
            } catch {
                emit log_named_uint("send failed len", lens[i]);
            }
        }
    }

    /// L1 -> L2: gas the L1CDM v2.13.0 budgets (REMOTE_* = L2 constants, numerically unchanged) is enough for the
    /// live L2CDM to execute; a failing target is recorded failed and replayable on L2.
    function test_l2_relay_from_l1_with_l1_baseGas() public {
        address aliased = address(uint160(address(l1cdm)) + uint160(0x1111000000000000000000000000000000001111));
        Sink2 sink = new Sink2();
        bytes memory m = hex"01020304";
        uint32 minGas = 100_000;
        uint64 l1BaseGas = l2BaseGasLive(m.length, minGas); // L1CDM v2.13.0 baseGas is numerically the same formula (asserted on the l1 fork)
        uint256 nonce = v1Nonce(55555555);
        bytes32 h = msgHash(nonce, address(this), address(sink), 0, minGas, m);
        vm.prank(aliased);
        l2cdm.relayMessage{ gas: l1BaseGas - 21_000 - 16 * (m.length + 260) }(nonce, address(this), address(sink), 0, minGas, m);
        assertTrue(l2cdm.successfulMessages(h), "delivered with L1-budgeted gas");
        // failing target -> failed + replayable
        nonce = v1Nonce(55555556);
        address bad = address(new BigSender()); // no fallback -> reverts
        h = msgHash(nonce, address(this), bad, 0, minGas, m);
        vm.prank(aliased);
        l2cdm.relayMessage{ gas: l1BaseGas }(nonce, address(this), bad, 0, minGas, m);
        assertTrue(l2cdm.failedMessages(h) && !l2cdm.successfulMessages(h), "failed recorded");
        vm.etch(bad, address(sink).code);
        l2cdm.relayMessage(nonce, address(this), bad, 0, minGas, m); // anyone replays
        assertTrue(l2cdm.successfulMessages(h), "replayed");
    }

    /// The live L2CDM refuses to relay to itself or to the L2ToL1MessagePasser, so a withdrawal with
    /// sender == L2CDM can only ever target the L1CDM (the portal's "checking the sender is enough" assumption).
    function test_l2_cdm_cannot_be_made_to_withdraw_to_arbitrary_target() public {
        address aliased = address(uint160(address(l1cdm)) + uint160(0x1111000000000000000000000000000000001111));
        vm.deal(aliased, 10 ether);
        vm.startPrank(aliased);
        vm.expectRevert("CrossDomainMessenger: cannot send message to blocked system address");
        l2cdm.relayMessage{ value: 1 ether }(v1Nonce(66666661), address(this), address(mp), 1 ether, 0, "");
        vm.expectRevert("CrossDomainMessenger: cannot send message to blocked system address");
        l2cdm.relayMessage(v1Nonce(66666662), address(this), L2CDM, 0, 0, abi.encodeCall(ICDM.sendMessage, (address(1), "", 0)));
        vm.stopPrank();
    }
}
