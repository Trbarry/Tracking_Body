// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./PauseMatrix.t.sol";

interface ISafe { function execTransactionFromModuleReturnData(address, uint256, bytes memory, uint8) external returns (bool, bytes memory); }
interface ISysX {
    function initialize(address,uint32,uint32,bytes32,uint64,address,bytes memory,bytes memory,uint256,address) external;
    function setFeature(bytes32, bool) external;
    function isFeatureEnabled(bytes32) external view returns (bool);
    function proxyAdminOwner() external view returns (address);
    function proxyAdmin() external view returns (address);
    function owner() external view returns (address);
    function setGasLimit(uint64) external;
    function gasLimit() external view returns (uint64);
    function l2ChainId() external view returns (uint256);
    function minimumGasLimit() external view returns (uint64);
    function maximumGasLimit() external view returns (uint64);
}

contract FeatureMachineTest is Test {
    ISC constant SC = ISC(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    ISysX constant SYS = ISysX(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    IPortal portal;
    address pao; address admin; address owner; address guardian; address lockbox;
    bytes32 constant ETH_LOCKBOX = "ETH_LOCKBOX";
    bytes32 constant CGT = "CUSTOM_GAS_TOKEN";
    bytes32 constant INTEROP = "INTEROP";

    function setUp() public {
        vm.createSelectFork("l1", 26433900);
        portal = IPortal(ISys(address(SYS)).optimismPortal());
        pao = SYS.proxyAdminOwner(); admin = SYS.proxyAdmin(); owner = SYS.owner(); guardian = SC.guardian();
        lockbox = portal.ethLockbox();
    }

    function test_setFeature_access_and_transitions() public {
        bytes4 NOT_AUTH = bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner()"));
        bytes4 BAD = bytes4(keccak256("SystemConfig_InvalidFeatureState()"));
        // nobody but ProxyAdmin / PAO: random, SystemConfig owner, guardian
        address[3] memory callers = [address(0xbeef), owner, guardian];
        for (uint256 i; i < 3; i++) {
            vm.prank(callers[i]); vm.expectRevert(NOT_AUTH); SYS.setFeature(CGT, true);
            vm.prank(callers[i]); vm.expectRevert(NOT_AUTH); SYS.setFeature(INTEROP, true);
            vm.prank(callers[i]); vm.expectRevert(NOT_AUTH); SYS.setFeature(ETH_LOCKBOX, false);
        }
        // ETH_LOCKBOX cannot be disabled, cannot be re-enabled (no-op guard)
        vm.prank(pao); vm.expectRevert(BAD); SYS.setFeature(ETH_LOCKBOX, false);
        vm.prank(pao); vm.expectRevert(BAD); SYS.setFeature(ETH_LOCKBOX, true);
        vm.prank(admin); vm.expectRevert(BAD); SYS.setFeature(ETH_LOCKBOX, false);
        // INTEROP: one-way (PRIVILEGED prank: only to document the state machine)
        vm.prank(pao); SYS.setFeature(INTEROP, true);
        vm.prank(pao); vm.expectRevert(BAD); SYS.setFeature(INTEROP, false);
        // CGT: freely togglable by PAO post-deployment, no validation of liquidity (PRIVILEGED)
        uint256 lb = lockbox.balance;
        assertGt(lb, 100_000 ether);
        vm.prank(pao); SYS.setFeature(CGT, true);
        vm.deal(address(0xA11CE), 2 ether);
        vm.prank(address(0xA11CE), address(0xA11CE)); vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        portal.depositTransaction{ value: 1 ether }(address(0xA11CE), 1 ether, 100000, false, "");
        WithdrawalTransaction memory wtx = WithdrawalTransaction(0, address(1), address(2), 1 ether, 100000, "");
        OutputRootProof memory orp; bytes[] memory proof = new bytes[](0);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        portal.proveWithdrawalTransaction(wtx, 0, orp, proof);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        portal.finalizeWithdrawalTransaction(wtx);
        // pause identifier unaffected by CGT
        vm.prank(guardian); SC.pause(lockbox);
        assertTrue(portal.paused()); assertTrue(ISys(address(SYS)).paused());
        vm.prank(guardian); SC.unpause(lockbox);
        vm.prank(pao); SYS.setFeature(CGT, false);
        assertEq(lockbox.balance, lb);
        // arbitrary feature names accepted
        vm.prank(pao); SYS.setFeature("ANYTHING", true);
    }

    function test_owner_surface_bounds() public {
        // SystemConfig owner (operator) can move gasLimit only within [minimumGasLimit, 500M]
        uint64 lo = SYS.minimumGasLimit(); uint64 hi = SYS.maximumGasLimit();
        assertEq(lo, 21_000_000); assertEq(hi, 500_000_000);
        vm.prank(owner); vm.expectRevert(bytes("SystemConfig: gas limit too low")); SYS.setGasLimit(lo - 1);
        vm.prank(owner); vm.expectRevert(bytes("SystemConfig: gas limit too high")); SYS.setGasLimit(hi + 1);
        vm.prank(owner); SYS.setGasLimit(lo);
        // deposits still work at the floor (maxResourceLimit 20M unchanged)
        vm.deal(address(0xA11CE), 2 ether);
        vm.prank(address(0xA11CE), address(0xA11CE));
        portal.depositTransaction{ value: 1 ether }(address(0xA11CE), 1 ether, 100000, false, "");
        // no external setter for resource config or l2ChainId
        (bool ok,) = address(SYS).call(abi.encodeWithSignature("setResourceConfig((uint32,uint8,uint8,uint32,uint32,uint128))", uint32(1), uint8(1), uint8(2), uint32(1), uint32(1), uint128(1)));
        assertFalse(ok);
        assertEq(SYS.l2ChainId(), 10);
    }

    /// The deployed DeputyPauseModule -> Guardian Safe -> SuperchainConfig path reaches the lockbox identifier.
    function test_deputy_module_path() public {
        address module = 0x76fC2F971FB355D0453cF9F64d3F9E4f640E1754;
        vm.prank(module);
        (bool ok,) = ISafe(guardian).execTransactionFromModuleReturnData(address(SC), 0, abi.encodeWithSignature("pause(address)", lockbox), 0);
        assertTrue(ok);
        assertTrue(portal.paused());
        // an expired pause cannot be re-armed through the module (it can only call pause())
        vm.warp(block.timestamp + SC.pauseExpiry());
        assertFalse(portal.paused());
        vm.prank(module);
        (ok,) = ISafe(guardian).execTransactionFromModuleReturnData(address(SC), 0, abi.encodeWithSignature("pause(address)", lockbox), 0);
        assertFalse(ok);
        assertFalse(portal.paused());
    }

    function test_gas_of_pause_getters() public {
        ISys s = ISys(address(SYS));
        address cdm = s.l1CrossDomainMessenger();
        uint256 g = gasleft(); IPausable(cdm).paused(); emit log_named_uint("L1CDM.paused() cold gas", g - gasleft());
        g = gasleft(); IPausable(cdm).paused(); emit log_named_uint("L1CDM.paused() warm gas", g - gasleft());
    }
}
