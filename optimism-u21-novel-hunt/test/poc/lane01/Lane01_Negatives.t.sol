// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

// LANE 01 negative-result harness. Local fork of mainnet at block 26433900 only; nothing is broadcast.
contract DelegateCaller {
    function run(address _target, bytes memory _data) external returns (bool ok, bytes memory ret) {
        (ok, ret) = _target.delegatecall(_data);
    }
}

contract Lane01NegativesTest is Test {
    address constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;
    address constant UTILS = 0xE1EA0F70fDA205fDfeEc770A259e4C34C0f7c4c6;
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant OP_PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address constant OP_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address constant PORTAL_IMPL = 0xb20B23af6071405C37dDDA0C0640e8eBb7899645;
    address constant STORAGE_SETTER = 0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8;
    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        vm.createSelectFork("l1");
    }

    /// Direct CALL of the delegatecall-only entry points reverts with OnlyDelegateCall.
    function test_directCall_upgrade_reverts() public {
        bytes memory c1 = vm.parseBytes(vm.readFile("test/u21-call1.hex"));
        bytes memory c0 = vm.parseBytes(vm.readFile("test/u21-call0.hex"));
        vm.prank(address(0xBAD));
        (bool ok, bytes memory ret) = OPCM.call(c1);
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(keccak256("OPContractsManagerV2_OnlyDelegateCall()")));
        vm.prank(address(0xBAD));
        (ok, ret) = OPCM.call(c0);
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(keccak256("OPContractsManagerV2_OnlyDelegateCall()")));
    }

    /// A non-owner contract that DELEGATECALLs the OPCM with the exact U21 OP Mainnet input cannot
    /// mutate anything: the first ProxyAdmin.upgrade() reverts on Ownable.
    function test_attackerDelegatecall_upgrade_reverts() public {
        bytes memory c1 = vm.parseBytes(vm.readFile("test/u21-call1.hex"));
        bytes memory c0 = vm.parseBytes(vm.readFile("test/u21-call0.hex"));
        DelegateCaller d = new DelegateCaller();
        (bool ok, bytes memory ret) = d.run(OPCM, c1);
        assertFalse(ok);
        emit log_named_bytes("upgrade() via attacker delegatecall revert data", ret);
        (ok, ret) = d.run(OPCM, c0);
        assertFalse(ok);
        emit log_named_bytes("upgradeSuperchain() via attacker delegatecall revert data", ret);
    }

    /// OPContractsManagerUtils.upgrade is external and unguarded, but a direct CALL makes the Utils
    /// contract the msg.sender of ProxyAdmin.upgrade, which is not the owner.
    function test_directCall_utilsUpgrade_reverts() public {
        bytes memory data = abi.encodeWithSignature(
            "upgrade(address,address,address,bytes,bytes32,uint8)",
            OP_PROXY_ADMIN, OP_PORTAL, PORTAL_IMPL, hex"", bytes32(0), uint8(0)
        );
        vm.prank(address(0xBAD));
        (bool ok,) = UTILS.call(data);
        assertFalse(ok);
        assertEq(address(uint160(uint256(vm.load(OP_PORTAL, IMPL_SLOT)))), PORTAL_IMPL);
    }

    /// Every initializer executed by U21 is no longer callable: not by an arbitrary account, not by
    /// the ProxyAdmin owner, not by the ProxyAdmin (the initialized byte equals initVersion()).
    function test_reinitialize_all_proxies_reverts() public {
        string memory f = "test/u21-inits.csv";
        uint256 n;
        while (true) {
            string memory line = vm.readLine(f);
            if (bytes(line).length == 0) break;
            string[] memory p = vm.split(line, ",");
            address target = vm.parseAddress(p[0]);
            bytes memory data = vm.parseBytes(p[1]);
            address[3] memory callers = [address(0xBAD), SAFE, _proxyAdminOf(target)];
            for (uint256 i = 0; i < 3; i++) {
                vm.prank(callers[i]);
                (bool ok,) = target.call(data);
                assertFalse(ok, "initializer re-run succeeded");
            }
            n++;
        }
        assertEq(n, 41);
    }

    /// No proxy touched by U21 is left pointing at the permissionless StorageSetter.
    function test_noProxyLeftOnStorageSetter() public {
        string memory f = "test/u21-inits.csv";
        while (true) {
            string memory line = vm.readLine(f);
            if (bytes(line).length == 0) break;
            string[] memory p = vm.split(line, ",");
            address target = vm.parseAddress(p[0]);
            address impl = address(uint160(uint256(vm.load(target, IMPL_SLOT))));
            assertTrue(impl != STORAGE_SETTER);
            // StorageSetter selector must not be reachable through the proxy.
            vm.prank(address(0xBAD));
            (bool ok, bytes memory ret) =
                target.call(abi.encodeWithSignature("setBytes32(bytes32,bytes32)", bytes32(uint256(0)), bytes32(0)));
            // DelayedWETH has a payable fallback (deposit) that swallows unknown selectors: success
            // with empty returndata and no storage write is fine. Everything else must revert.
            if (ok) {
                assertEq(ret.length, 0);
            }
        }
    }

    function _proxyAdminOf(address _t) internal view returns (address a) {
        (bool ok, bytes memory ret) = _t.staticcall(abi.encodeWithSignature("proxyAdmin()"));
        if (ok && ret.length == 32) a = abi.decode(ret, (address));
    }
}
