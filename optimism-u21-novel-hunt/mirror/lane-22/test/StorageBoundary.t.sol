// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface ICoreGetters {
    function superchainConfig() external view returns (address);
    function ethLockbox() external view returns (address);
    function authorizedPortals(address) external view returns (bool);
    function paused() external view returns (bool);
}

contract StorageBoundaryTest is Test {
    address constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address constant STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant ERC721_BRIDGE = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
    address constant TOKEN_FACTORY = 0x75505a97BD334E7BD3C476893285569C4136Fa0F;
    address constant DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
    address constant DELAYED_WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;

    address constant ATTACKER = address(0xA11CE);

    uint256 preFork;
    uint256 postFork;

    struct Proposal {
        bytes32 root;
        uint256 l2SequenceNumber;
    }

    struct ResourceConfig {
        uint32 maxResourceLimit;
        uint8 elasticityMultiplier;
        uint8 baseFeeMaxChangeDenominator;
        uint32 minimumBaseFee;
        uint32 systemTxMaxGas;
        uint128 maximumBaseFee;
    }

    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address delayedWETH;
        address opcm;
    }

    function setUp() public {
        preFork = vm.createFork("l1pre");
        postFork = vm.createFork("l1n");
    }

    function test_expectedDependencySlotsOnly() public {
        vm.selectFork(preFork);
        bytes32 lockbox0Pre = vm.load(LOCKBOX, bytes32(uint256(0)));
        bytes32 lockbox3Pre = vm.load(LOCKBOX, bytes32(uint256(3)));
        bytes32 weth4Pre = vm.load(DELAYED_WETH, bytes32(uint256(4)));
        bytes32 weth5Pre = vm.load(DELAYED_WETH, bytes32(uint256(5)));
        bytes32 asr0Pre = vm.load(ASR, bytes32(uint256(0)));
        bytes32 asr6Pre = vm.load(ASR, bytes32(uint256(6)));

        vm.selectFork(postFork);
        bytes32 lockbox0Post = vm.load(LOCKBOX, bytes32(uint256(0)));
        bytes32 lockbox3Post = vm.load(LOCKBOX, bytes32(uint256(3)));
        bytes32 weth4Post = vm.load(DELAYED_WETH, bytes32(uint256(4)));
        bytes32 weth5Post = vm.load(DELAYED_WETH, bytes32(uint256(5)));
        bytes32 asr0Post = vm.load(ASR, bytes32(uint256(0)));
        bytes32 asr6Post = vm.load(ASR, bytes32(uint256(6)));

        // Legacy SystemConfig addresses remain byte-for-byte as spacers.
        assertEq(lockbox0Pre, lockbox0Post);
        assertEq(weth4Pre, weth4Post);
        assertEq(asr0Pre, asr0Post);

        // New fields were zero before U21 and hold exactly the intended dependency after it.
        assertEq(lockbox3Pre, bytes32(0));
        assertEq(address(uint160(uint256(lockbox3Post))), SUPERCHAIN_CONFIG);
        assertEq(weth5Pre, bytes32(0));
        assertEq(address(uint160(uint256(weth5Post))), LOCKBOX);

        // ASR reuses only the previously empty high 20 bytes of packed slot 6.
        assertEq(uint256(asr6Pre) >> 96, 0);
        assertEq(uint96(uint256(asr6Pre)), uint96(uint256(asr6Post)));
        assertEq(address(uint160(uint256(asr6Post) >> 96)), LOCKBOX);
    }

    function test_postUpgradeDependenciesAreLiveAndNonzero() public {
        vm.selectFork(postFork);
        assertEq(ICoreGetters(LOCKBOX).superchainConfig(), SUPERCHAIN_CONFIG);
        assertEq(ICoreGetters(DELAYED_WETH).ethLockbox(), LOCKBOX);
        assertEq(ICoreGetters(ASR).ethLockbox(), LOCKBOX);
        assertEq(ICoreGetters(PORTAL).ethLockbox(), LOCKBOX);
        assertTrue(ICoreGetters(LOCKBOX).authorizedPortals(PORTAL));
        assertFalse(ICoreGetters(LOCKBOX).paused());
        assertFalse(ICoreGetters(PORTAL).paused());
    }

    function test_historicalWithdrawalMappingsAreBitExact() public {
        bytes32[3] memory hashes = [
            bytes32(0x46661012d8656b178f8441c1fa97f2d54fde99cd13b260161c5f2333c0fc4079),
            bytes32(0xe3c033b651db7e4f5be6cf0ed9d3d8dc7d7c7da0ddd314e33d133e91c0c4cee3),
            bytes32(0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d)
        ];
        address[3] memory submitters = [
            0x2Ce910fBba65B454bBAf6A18c952A70f3bcd8299,
            0x2Ce910fBba65B454bBAf6A18c952A70f3bcd8299,
            0x47728c875b7F52a40227d662f83a3C3d0f7E6FBB
        ];

        for (uint256 i; i < hashes.length; i++) {
            bytes32 outer = keccak256(abi.encode(hashes[i], uint256(57)));
            bytes32 provenSlot = keccak256(abi.encode(submitters[i], outer));
            bytes32 submitterLengthSlot = keccak256(abi.encode(hashes[i], uint256(60)));
            vm.selectFork(preFork);
            bytes32 provenPre = vm.load(PORTAL, provenSlot);
            bytes32 lengthPre = vm.load(PORTAL, submitterLengthSlot);
            vm.selectFork(postFork);
            assertEq(vm.load(PORTAL, provenSlot), provenPre);
            assertEq(vm.load(PORTAL, submitterLengthSlot), lengthPre);
            assertNotEq(provenPre, bytes32(0));
            assertEq(uint256(lengthPre), 1);
        }

        bytes32 finalizedHash =
            0x9f49843f57159419dc9eeb462ff76309444d998af1199e5bca62e7e19b066061;
        bytes32 finalizedSlot = keccak256(abi.encode(finalizedHash, uint256(51)));
        vm.selectFork(preFork);
        assertEq(uint256(vm.load(PORTAL, finalizedSlot)), 1);
        vm.selectFork(postFork);
        assertEq(uint256(vm.load(PORTAL, finalizedSlot)), 1);
    }

    function test_publicReinitializersAreClosedToUnprivilegedCaller() public {
        vm.selectFork(postFork);
        address[] memory portals = new address[](1);
        portals[0] = PORTAL;
        ResourceConfig memory rc;
        Addresses memory addresses_;

        _assertCallFails(SUPERCHAIN_CONFIG, abi.encodeWithSignature("initialize(address)", ATTACKER));
        _assertCallFails(
            SYSTEM_CONFIG,
            abi.encodeWithSignature(
                "initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)",
                ATTACKER,
                uint32(0),
                uint32(0),
                bytes32(0),
                uint64(0),
                ATTACKER,
                rc,
                addresses_,
                uint256(10),
                SUPERCHAIN_CONFIG
            )
        );
        _assertCallFails(PORTAL, abi.encodeWithSignature("initialize(address,address,address)", SYSTEM_CONFIG, ASR, LOCKBOX));
        _assertCallFails(LOCKBOX, abi.encodeWithSignature("initialize(address,address[])", SUPERCHAIN_CONFIG, portals));
        _assertCallFails(MESSENGER, abi.encodeWithSignature("initialize(address,address)", SYSTEM_CONFIG, PORTAL));
        _assertCallFails(
            STANDARD_BRIDGE, abi.encodeWithSignature("initialize(address,address)", MESSENGER, SYSTEM_CONFIG)
        );
        _assertCallFails(ERC721_BRIDGE, abi.encodeWithSignature("initialize(address,address)", MESSENGER, SYSTEM_CONFIG));
        _assertCallFails(TOKEN_FACTORY, abi.encodeWithSignature("initialize(address)", STANDARD_BRIDGE));
        _assertCallFails(DGF, abi.encodeWithSignature("initialize(address)", ATTACKER));
        _assertCallFails(DELAYED_WETH, abi.encodeWithSignature("initialize(address)", LOCKBOX));
        _assertCallFails(
            ASR,
            abi.encodeWithSignature(
                "initialize(address,address,(bytes32,uint256),uint32)",
                LOCKBOX,
                DGF,
                Proposal({root: bytes32(0), l2SequenceNumber: 0}),
                uint32(9)
            )
        );
    }

    function test_implementationInitializersAreDisabled() public {
        vm.selectFork(postFork);
        address[11] memory implementations = [
            0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7,
            0xADe27248542c0F3E89b49e4eB76155e267F14377,
            0xb20B23af6071405C37dDDA0C0640e8eBb7899645,
            0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe,
            0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448,
            0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891,
            0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e,
            0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12,
            0x72B971717E088B59F26d4236BE222ADB6ACD393b,
            0xF024e96317907C3b8d8CB346B9FD9034c8640e15,
            0x2b27299C577d4720100e2735b652444DcEa652D0
        ];
        for (uint256 i; i < implementations.length; i++) {
            uint256 word = uint256(vm.load(implementations[i], bytes32(uint256(0))));
            uint8 initialized = implementations[i] == 0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448
                ? uint8(word >> 160)
                : uint8(word);
            assertEq(initialized, type(uint8).max);
        }
    }

    function _assertCallFails(address target, bytes memory data) internal {
        vm.prank(ATTACKER);
        (bool ok,) = target.call(data);
        assertFalse(ok, "initializer unexpectedly callable");
    }
}
