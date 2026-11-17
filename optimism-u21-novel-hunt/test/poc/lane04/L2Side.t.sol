// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

interface IL2CDM {
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function sendMessage(address, bytes calldata, uint32) external payable;
    function OTHER_MESSENGER() external view returns (address);
    function failedMessages(bytes32) external view returns (bool);
    function successfulMessages(bytes32) external view returns (bool);
    function version() external view returns (string memory);
    function baseGas(bytes calldata, uint32) external view returns (uint64);
}

/// Deployed OP Mainnet L2CrossDomainMessenger (v2.2.1, not upgraded by U21): can it ever be the `sender` of an
/// L2ToL1MessagePasser withdrawal whose target is not the L1 messenger?
contract L2SideTest is Test {
    IL2CDM constant L2CDM = IL2CDM(0x4200000000000000000000000000000000000007);
    address constant PASSER = 0x4200000000000000000000000000000000000016;
    address constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    event MessagePassed(uint256 indexed nonce, address indexed sender, address indexed target, uint256 value, uint256 gasLimit, bytes data, bytes32 withdrawalHash);

    function setUp() public { vm.createSelectFork("l2"); }

    function test_l2cdm_cannot_target_passer() public {
        assertEq(L2CDM.version(), "2.2.1");
        assertEq(L2CDM.OTHER_MESSENGER(), L1CDM);
        address aliased = address(uint160(L1CDM) + uint160(0x1111000000000000000000000000000000001111));
        uint256 nonce = (uint256(1) << 240) | 0xffffffffffff;
        // an L1->L2 message (permissionless on L1) that asks the L2 messenger to call the message passer
        bytes memory inner = abi.encodeWithSignature("initiateWithdrawal(address,uint256,bytes)", address(0xdead), uint256(100000), bytes(""));
        vm.prank(aliased);
        vm.expectRevert("CrossDomainMessenger: cannot send message to blocked system address");
        L2CDM.relayMessage(nonce, address(this), PASSER, 0, 200000, inner);
        vm.prank(aliased);
        vm.expectRevert("CrossDomainMessenger: cannot send message to blocked system address");
        L2CDM.relayMessage(nonce, address(this), address(L2CDM), 0, 200000, inner);
    }

    function test_sendMessage_always_targets_other_messenger_and_old_baseGas() public {
        vm.recordLogs();
        L2CDM.sendMessage(address(0xBEEF), hex"1234", 100000);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == PASSER && logs[i].topics[0] == MessagePassed.selector) {
                found = true;
                assertEq(address(uint160(uint256(logs[i].topics[2]))), address(L2CDM));
                assertEq(address(uint160(uint256(logs[i].topics[3]))), L1CDM);
                (, uint256 gasLimit,,) = abi.decode(logs[i].data, (uint256, uint256, bytes, bytes32));
                // pre-v9 budget: 21000 + 200000 + 40000 + 40000 + 5000 + 100000*64/63 + 16*(2+260)
                assertEq(gasLimit, 21000 + 285000 + (uint256(100000) * 64) / 63 + 16 * 262);
                console.log("L2 baseGas(2 bytes, 100000) =", gasLimit);
            }
        }
        assertTrue(found);
    }
}
