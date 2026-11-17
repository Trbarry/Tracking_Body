// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// F6 historical harness — piece 1: named fork points for OP Mainnet's L1 contracts.
//
// A "fork point" is an L1 block in which the implementation pointer of a tracked OP Mainnet proxy
// changed (19 of them between Bedrock and Upgrade 21, see HistoricalForkData.sol, generated from
// evidence/F6-op-upgrade-blocks.json). For point i:
//     _forkBefore(i)  -> state at the END of block  blockOf(i) - 1   (old implementations)
//     _forkAfter(i)   -> state at the END of block  blockOf(i)       (new implementations)
// All forks come from the local read-only archive proxy (any block; forge caches what it reads in
// ~/.foundry/cache/rpc). Nothing is ever broadcast.
//
// Memory rule (PASS A lost a run to a 6.3 GB OOM): `_forkAt` creates a NEW fork every call. Inside
// a loop use `_rollTo` (one fork, re-pinned with vm.rollFork) and vm.revertToStateAndDelete.

import "forge-std/Test.sol";
import { HFData } from "./HistoricalForkData.sol";

interface IVersioned {
    function version() external view returns (string memory);
}

abstract contract HistoricalFork is Test {
    string internal constant L1_ARCHIVE = "http://127.0.0.1:7545";
    string internal constant L2_ARCHIVE = "http://127.0.0.1:7546";

    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant EIP1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // ---- OP Mainnet L1 addresses (proxies; stable since Bedrock unless noted) ----
    address internal constant OP_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant OP_SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant OP_L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1; // ResolvedDelegateProxy
    address internal constant OP_L1_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1; // L1ChugSplashProxy
    address internal constant OP_DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9; // exists from block 19884570
    address internal constant OP_ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113; // exists from U16 (22990599)
    address internal constant OP_ASR_LEGACY = 0x18DAc71c228D1C32c99489B7323d441E1175e443; // 19884570 .. U16
    address internal constant OP_LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43; // exists from U16
    address internal constant OP_ERC721_BRIDGE = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
    address internal constant OP_ERC20_FACTORY = 0x75505a97BD334E7BD3C476893285569C4136Fa0F;
    address internal constant OP_SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant OP_L2OO = 0xdfe97868233d1aa22e815a266982f2cf17685a27; // Bedrock .. fault proofs
    address internal constant OP_ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
    address internal constant OP_PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address internal constant OP_PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // Safe, from v1.2.0 on
    address internal constant L2_CDM = 0x4200000000000000000000000000000000000007;

    /// @dev storage slot of AddressManager.addresses[keccak256("OVM_L1CrossDomainMessenger")]
    ///      (Lib_AddressManager: Ownable._owner at slot 0, `addresses` mapping at slot 1).
    function _addressManagerSlot(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(abi.encodePacked(name)), uint256(1)));
    }

    // ------------------------------------------------------------------------------------------
    // Fork creation
    // ------------------------------------------------------------------------------------------

    /// @notice NEW fork of L1 at the END of `blockNumber`. Do not call in a loop (use _rollTo).
    function _forkAt(uint256 blockNumber) internal returns (uint256 forkId) {
        forkId = vm.createSelectFork(L1_ARCHIVE, blockNumber);
    }

    /// @notice Re-pins the ACTIVE fork to the END of `blockNumber`. Local changes to non-persistent
    ///         accounts are discarded; accounts marked with vm.makePersistent keep every slot they
    ///         have touched so far (see UpgradeReplay._carry for what that means).
    function _rollTo(uint256 blockNumber) internal {
        vm.rollFork(blockNumber);
    }

    /// @notice Fork at the last block that still runs the OLD implementations of point `i`.
    function _forkBefore(uint256 i) internal returns (uint256) {
        return _forkAt(HFData.blockOf(i) - 1);
    }

    /// @notice Fork at the block in which point `i` was executed (state at its end: NEW impls).
    function _forkAfter(uint256 i) internal returns (uint256) {
        return _forkAt(HFData.blockOf(i));
    }

    function _rollBefore(uint256 i) internal {
        _rollTo(HFData.blockOf(i) - 1);
    }

    function _rollAfter(uint256 i) internal {
        _rollTo(HFData.blockOf(i));
    }

    /// @notice Fork point index by label ("U19_V7", "V1_4_0_FP", ...). Reverts if unknown.
    function _point(string memory label_) internal pure returns (uint256) {
        bytes32 h = keccak256(bytes(label_));
        for (uint256 i; i < HFData.POINTS; i++) {
            if (keccak256(bytes(HFData.label(i))) == h) return i;
        }
        revert(string.concat("HistoricalFork: unknown fork point ", label_));
    }

    /// @notice Index of the last fork point whose block is <= `blockNumber` (the release that is
    ///         live at the end of that block). Reverts before Bedrock step 1.
    function _eraOf(uint256 blockNumber) internal pure returns (uint256 i) {
        require(blockNumber >= HFData.blockOf(0), "HistoricalFork: pre-Bedrock block");
        for (i = HFData.POINTS - 1; HFData.blockOf(i) > blockNumber; i--) { }
    }

    // ------------------------------------------------------------------------------------------
    // Implementation pointers
    // ------------------------------------------------------------------------------------------

    /// @notice (holder, slot) of the implementation pointer of tracked contract `c` (HFData ids).
    function _pointerLocation(uint256 c) internal pure returns (address holder, bytes32 slot) {
        if (c == HFData.L1CDM) return (OP_ADDRESS_MANAGER, _addressManagerSlot("OVM_L1CrossDomainMessenger"));
        return (HFData.proxyOf(c), EIP1967_IMPL_SLOT); // Proxy and L1ChugSplashProxy share the slot
    }

    /// @notice Live implementation pointer of tracked contract `c` on the active fork.
    function _impl(uint256 c) internal view returns (address) {
        (address holder, bytes32 slot) = _pointerLocation(c);
        return address(uint160(uint256(vm.load(holder, slot))));
    }

    /// @notice Generic EIP-1967 implementation of any proxy on the active fork.
    function _impl1967(address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, EIP1967_IMPL_SLOT))));
    }

    /// @notice version() of `a`, or "" if the call fails (no code / no getter).
    function _version(address a) internal view returns (string memory v) {
        if (a.code.length == 0) return "";
        try IVersioned(a).version() returns (string memory s) {
            v = s;
        } catch { }
    }

    /// @notice Number of tracked contracts whose live pointer differs from the table value for
    ///         point `i` (`after_` selects implAfter / implBefore). Logs every difference.
    function _implMismatches(uint256 i, bool after_) internal returns (uint256 n) {
        for (uint256 c; c < HFData.CONTRACTS; c++) {
            address want = after_ ? HFData.implAfter(c, i) : HFData.implBefore(c, i);
            address got = _impl(c);
            if (got != want) {
                n++;
                emit log_named_string("impl mismatch", string.concat(HFData.label(i), after_ ? " after " : " before ", HFData.contractName(c)));
                emit log_named_address("  want", want);
                emit log_named_address("  got ", got);
            }
        }
    }

    function _assertImpls(uint256 i, bool after_) internal {
        assertEq(_implMismatches(i, after_), 0, string.concat("implementation pointers differ from table at ", HFData.label(i)));
    }
}
