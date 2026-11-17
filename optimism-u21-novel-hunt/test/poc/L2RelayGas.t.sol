// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

interface IL2CDM {
    function version() external view returns (string memory);
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function baseGas(bytes calldata, uint32) external view returns (uint64);
    function otherMessenger() external view returns (address);
}

contract L2Burn {
    fallback() external payable {
        assembly {
            invalid()
        }
    }
}

contract L2Ok {
    uint256 public seen;

    fallback() external payable {
        seen = gasleft();
    }
}

/// @notice The L2 side was NOT upgraded by U21: L2CrossDomainMessenger 2.2.1 on OP Mainnet still
///         runs the pre-U21 relayMessage (calldata message copied AFTER `gasleft() - 40_000` is
///         computed). This test replays, on the `l2` fork, what the derivation pipeline does for
///         an L1->L2 message: a deposit transaction from the aliased L1CrossDomainMessenger with
///         gas limit = L1CDM.baseGas(message, minGasLimit) (formula identical on L1 v8/v9, see
///         differential D1), i.e. frame gas = baseGas - intrinsic(21000 + 16/non-zero byte).
///         Nobody chooses the gas here - it is fixed by the protocol.
///         vm.prank(aliased L1CDM) models the deposit transaction's `from`; that is how every
///         L1->L2 message arrives, not a privileged action.
contract L2RelayGasTest is Test {
    IL2CDM constant L2CDM = IL2CDM(0x4200000000000000000000000000000000000007);
    address constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address aliased;
    address burn;
    L2Ok ok;

    function setUp() public {
        vm.createSelectFork("l2");
        aliased = address(uint160(L1CDM) + uint160(0x1111000000000000000000000000000000001111));
        require(L2CDM.otherMessenger() == L1CDM, "otherMessenger");
        burn = address(new L2Burn());
        ok = new L2Ok();
    }

    function _l1BaseGas(uint256 len, uint256 minGas) internal pure returns (uint256) {
        uint256 exec = 285_000 + (minGas * 64) / 63;
        uint256 total = len + 260;
        uint256 a = exec + total * 16;
        uint256 b = total * 40;
        return 21_000 + (a > b ? a : b);
    }

    function _relay(address target, uint256 len, uint256 minGas, uint256 value, bool zeroBytes)
        internal
        returns (string memory cls, uint256 frameGas)
    {
        bytes memory payload = new bytes(len);
        if (!zeroBytes) {
            for (uint256 i; i < len; i += 32) {
                assembly {
                    mstore(add(add(payload, 32), i), 0xa5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5)
                }
            }
        }
        uint256 nonce = (uint256(1) << 240) | (uint256(0xb16b00b5) << 64) | len;
        bytes memory cd = abi.encodeCall(IL2CDM.relayMessage, (nonce, address(0xA11CE), target, value, minGas, payload));
        // intrinsic gas of the deposit transaction (charged from its gas limit before execution)
        uint256 intrinsic = 21_000;
        for (uint256 i; i < cd.length; i++) {
            intrinsic += cd[i] == 0 ? 4 : 16;
        }
        uint256 gasLimit = _l1BaseGas(len, minGas);
        frameGas = gasLimit - intrinsic;
        bytes32 h = keccak256(cd);
        vm.deal(aliased, value);
        uint256 snap = vm.snapshotState();
        vm.prank(aliased, aliased);
        (bool success,) = address(L2CDM).call{ gas: frameGas, value: value }(cd);
        bool s = L2CDM.successfulMessages(h);
        bool f = L2CDM.failedMessages(h);
        if (!success) cls = "DEPOSIT_TX_REVERTED(neither recorded, unreplayable)";
        else if (s) cls = "RELAYED";
        else if (f) cls = "FAILED(replayable)";
        else cls = "OK_BUT_NEITHER";
        vm.revertToStateAndDelete(snap);
    }

    function test_l2_relay_gas_matrix() public {
        string memory path = "evidence/l2-relay-gas.txt";
        vm.writeFile(path, string.concat("L2CDM version ", L2CDM.version(), "\n"));
        uint24[9] memory lens = [uint24(0), 1_000, 10_000, 20_000, 30_000, 40_000, 60_000, 90_000, 119_000];
        for (uint256 z; z < 2; z++) {
            for (uint256 i; i < lens.length; i++) {
                for (uint256 m; m < 2; m++) {
                    uint256 minGas = m == 0 ? 0 : 200_000;
                    (string memory c1, uint256 g1) = _relay(burn, lens[i], minGas, 0, z == 1);
                    (string memory c2,) = _relay(burn, lens[i], minGas, 1 ether, z == 1);
                    (string memory c3,) = _relay(address(ok), lens[i], minGas, 1 ether, z == 1);
                    vm.writeLine(
                        path,
                        string.concat(
                            z == 0 ? "nonzero" : "zero", " len=", vm.toString(uint256(lens[i])), " minGas=", vm.toString(minGas),
                            " frameGas=", vm.toString(g1), " | burn:", c1, " | burn+1eth:", c2, " | ok+1eth:", c3
                        )
                    );
                }
            }
        }
    }
}
