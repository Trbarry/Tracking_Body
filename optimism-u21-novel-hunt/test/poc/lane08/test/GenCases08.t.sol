// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

contract Sink08 {
    fallback() external payable { }
}

contract Burner08 {
    fallback() external payable { while (true) { } }
}

contract Reverter08 {
    fallback() external payable { revert("no"); }
}

/// Pure calldata generator for the private-anvil (port 18080) real-transaction measurements.
contract GenCases08Test is Base08 {
    address constant SINK = address(uint160(0x5151000000000000000000000000000000000001));
    address constant BURNER = address(uint160(0x5151000000000000000000000000000000000002));
    address constant REVERTER = address(uint160(0x5151000000000000000000000000000000000003));
    address constant EXISTING = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // anvil account 1 (funded EOA)
    address constant FRESH = 0x00F2E5400000000000000000000000000000BeEF;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant L2USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

    uint256 internal GAME_BASE = vm.envOr("GAME_BASE", uint256(21389));
    uint256 constant TS_BASE = 1794908075 + 100000;

    string internal root = "root";
    uint256 internal n;
    string internal lastJson;

    function oldBaseGas(uint256 len, uint256 m) internal pure returns (uint64) {
        return uint64(285_000 + 16 * len + (m * 64) / 63);
    }

    function fill(uint256 len, bytes1 b) internal pure returns (bytes memory m) {
        m = new bytes(len);
        if (b != 0) {
            for (uint256 i; i < len; i++) m[i] = b;
        }
    }

    struct Built { WithdrawalTransaction w; bytes create; bytes prove; }

    function build(uint256 i, address sender, address target, uint256 value, uint32 m, bytes memory message, bool old) internal view returns (Built memory b) {
        b.w = messengerWithdrawal(7_000_000 + i, 7_000_000 + i, sender, target, value, m, message);
        if (old) b.w.gasLimit = oldBaseGas(message.length, m);
        bytes32 path = keccak256(abi.encode(keccak256(abi.encode(hashWithdrawal(b.w), uint256(0)))));
        bytes memory leaf = abi.encodePacked(hex"e3a120", path, hex"01");
        OutputRootProof memory orp = OutputRootProof(bytes32(0), keccak256("state"), keccak256(leaf), keccak256("bh"));
        bytes32 outputRoot = keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash));
        bytes memory extra = abi.encodePacked(bytes1(0x01), uint64(TS_BASE + i), L2_CHAIN_ID, outputRoot);
        bytes[] memory proof = new bytes[](1);
        proof[0] = leaf;
        b.create = abi.encodeCall(IDGF.create, (9, keccak256(extra), extra));
        b.prove = abi.encodeCall(IPortal.proveWithdrawalTransaction, (b.w, GAME_BASE + i, orp, proof));
    }

    function add(string memory label, address sender, address target, uint256 value, uint32 m, bytes memory message, bool old) internal {
        uint256 i = n++;
        if (i != vm.envUint("CASE")) return;
        Built memory b = build(i, sender, target, value, m, message, old);
        string memory k = string.concat("case", vm.toString(i));
        vm.serializeString(k, "label", label);
        vm.serializeUint(k, "gasLimit", b.w.gasLimit);
        vm.serializeUint(k, "minGasLimit", m);
        vm.serializeUint(k, "value", value);
        vm.serializeUint(k, "msgLen", message.length);
        vm.serializeUint(k, "dataLen", b.w.data.length);
        vm.serializeBool(k, "oldBudget", old);
        vm.serializeBytes32(k, "withdrawalHash", hashWithdrawal(b.w));
        vm.serializeBytes32(k, "msgHash", keccak256(b.w.data));
        vm.serializeBytes(k, "create", b.create);
        vm.serializeBytes(k, "prove", b.prove);
        string memory o = vm.serializeBytes(k, "finalize", abi.encodeCall(IPortal.finalizeWithdrawalTransaction, (b.w)));
        vm.writeJson(o, string.concat(vm.envOr("CASEDIR", string("data")), "/case_", vm.toString(i), ".json"));
    }

    function test_generate() public {
        bytes memory ethMsgExisting = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", EXISTING, EXISTING, 1 ether, bytes(""));
        bytes memory ethMsgFresh = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", EXISTING, FRESH, 1 ether, bytes(""));
        bytes memory usdcMsg = abi.encodeWithSignature("finalizeBridgeERC20(address,address,address,address,uint256,bytes)", USDC, L2USDC, EXISTING, EXISTING, 1_000e6, bytes(""));

        add("ETH bridge wd, m=0, existing EOA, live L2 baseGas (v2.2.1)", L2_BRIDGE, L1_BRIDGE, 1 ether, 0, ethMsgExisting, false);
        add("ETH bridge wd, m=0, existing EOA, OLD L2 baseGas (285k+16*len)", L2_BRIDGE, L1_BRIDGE, 1 ether, 0, ethMsgExisting, true);
        add("ETH bridge wd, m=200000, existing EOA, live", L2_BRIDGE, L1_BRIDGE, 1 ether, 200_000, ethMsgExisting, false);
        add("ETH bridge wd, m=0, FRESH account recipient, old", L2_BRIDGE, L1_BRIDGE, 1 ether, 0, ethMsgFresh, true);
        add("USDC bridge wd, m=0, old", L2_BRIDGE, L1_BRIDGE, 0, 0, usdcMsg, true);
        add("Sink, empty msg, m=0, value 0, old", address(0xA11CE), SINK, 0, 0, "", true);
        add("1 ETH to FRESH EOA via messenger, empty msg, m=0, old", address(0xA11CE), FRESH, 1 ether, 0, "", true);
        add("Burner (uses all gas), 1 ETH, m=0, old", address(0xA11CE), BURNER, 1 ether, 0, "", true);
        add("Burner, m=1000000, old", address(0xA11CE), BURNER, 0, 1_000_000, "", true);
        add("Reverter, 1 ETH, m=0, old", address(0xA11CE), REVERTER, 1 ether, 0, "", true);
        add("Sink, 10000 x 0xff, m=0, old", address(0xA11CE), SINK, 0, 0, fill(10_000, 0xff), true);
        add("Sink, 10000 x 0xff, m=0, live", address(0xA11CE), SINK, 0, 0, fill(10_000, 0xff), false);
        add("Sink, 100000 x 0xff, m=0, old", address(0xA11CE), SINK, 0, 0, fill(100_000, 0xff), true);
        add("Sink, 100000 x 0xff, m=0, live", address(0xA11CE), SINK, 0, 0, fill(100_000, 0xff), false);
        add("Burner, 100000 x 0xff, 1 ETH, m=0, old", address(0xA11CE), BURNER, 1 ether, 0, fill(100_000, 0xff), true);
        add("Sink, 300000 x 0x00, m=0, old", address(0xA11CE), SINK, 0, 0, fill(300_000, 0x00), true);
        add("Sink, 300000 x 0x00, m=0, live", address(0xA11CE), SINK, 0, 0, fill(300_000, 0x00), false);
        add("UNSAFE target = OptimismPortal, 1 ETH, m=0, old", address(0xA11CE), address(portal), 1 ether, 0, "", true);
        add("Sink, m=5000000, live", address(0xA11CE), SINK, 0, 5_000_000, "", false);
        add("Sink, m=8000000, live", address(0xA11CE), SINK, 0, 8_000_000, "", false);
        add("Sink, m=6000000, old", address(0xA11CE), SINK, 0, 6_000_000, "", true);
        if (vm.envUint("CASE") == 999) {
            vm.serializeUint(root, "n", n);
            vm.serializeBytes(root, "sinkCode", type(Sink08).runtimeCode);
            vm.serializeBytes(root, "burnerCode", type(Burner08).runtimeCode);
            string memory out = vm.serializeBytes(root, "reverterCode", type(Reverter08).runtimeCode);
            vm.writeJson(out, "data/cases.json");
        }
    }
}
