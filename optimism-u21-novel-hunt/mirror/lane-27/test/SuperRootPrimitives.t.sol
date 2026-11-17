// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface IFactorySuper27 {
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData)
        external
        payable
        returns (address proxy);
    function initBonds(uint32 gameType) external view returns (uint256);
}

interface IGameSuper27 {
    function gameCreator() external pure returns (address);
    function gameType() external pure returns (uint32);
    function rootClaim() external pure returns (bytes32);
    function rootClaimByChainId(uint256 chainId) external pure returns (bytes32);
    function l2SequenceNumber() external pure returns (uint256);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function status() external view returns (uint8);
    function absolutePrestate() external pure returns (bytes32);
    function vm() external pure returns (address);
    function anchorStateRegistry() external pure returns (address);
    function weth() external pure returns (address);
    function maxGameDepth() external view returns (uint256);
    function splitDepth() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function clockExtension() external view returns (uint64);
}

interface IASRSuper27 {
    function getAnchorRoot() external view returns (bytes32 root, uint256 sequence);
    function isGameProper(address game) external view returns (bool);
    function isGameRespected(address game) external view returns (bool);
    function isGameClaimValid(address game) external view returns (bool);
}

contract SuperRootPrimitivesTest is Test {
    IFactorySuper27 internal constant FACTORY =
        IFactorySuper27(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IASRSuper27 internal constant ASR =
        IASRSuper27(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    address internal constant TYPE5_PROPOSER = 0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0;
    address internal constant EXPECTED_VM = 0xaCc005DCd857B401e4732E6F7837135A22825cfA;
    address internal constant EXPECTED_WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;

    function setUp() external {
        vm.createSelectFork("l1n");
    }

    function test_type9PermissionlessAndDuplicateChainIdsFirstWins() external {
        vm.deal(address(this), 1 ether);
        (, uint256 anchorSequence) = ASR.getAnchorRoot();
        uint64 proposedSequence = uint64(anchorSequence + 123_456);
        bytes32 firstRoot = keccak256("first OP output");
        bytes32 secondRoot = keccak256("duplicate OP output");

        // Hash-consistent, correctly shaped, but non-canonical: chain ID 10 occurs twice.
        bytes memory extraData = abi.encodePacked(
            bytes1(0x01),
            bytes8(proposedSequence),
            bytes32(uint256(10)),
            firstRoot,
            bytes32(uint256(10)),
            secondRoot
        );
        bytes32 superRoot = keccak256(extraData);
        _cacheEmptyFactoryUUID(9, superRoot, extraData);

        address proxy = FACTORY.create{value: FACTORY.initBonds(9)}(9, superRoot, extraData);
        IGameSuper27 game = IGameSuper27(proxy);

        assertEq(game.gameCreator(), address(this));
        assertEq(game.gameType(), 9);
        assertEq(game.rootClaim(), superRoot);
        assertEq(game.l2SequenceNumber(), proposedSequence);
        assertEq(game.rootClaimByChainId(10), firstRoot, "L1 lookup is first-match");
        assertTrue(game.wasRespectedGameTypeWhenCreated());
        assertEq(game.status(), 0);
        assertTrue(ASR.isGameProper(proxy));
        assertTrue(ASR.isGameRespected(proxy));
        assertFalse(ASR.isGameClaimValid(proxy), "unresolved malformed game cannot finalize withdrawals");

        assertEq(game.absolutePrestate(), 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9);
        assertEq(game.vm(), EXPECTED_VM);
        assertEq(game.anchorStateRegistry(), address(ASR));
        assertEq(game.weth(), EXPECTED_WETH);
        assertEq(game.maxGameDepth(), 73);
        assertEq(game.splitDepth(), 30);
        assertEq(game.maxClockDuration(), 302_400);
        assertEq(game.clockExtension(), 10_800);
    }

    function test_rootClaimBindsWholeSuperRootPreimage() external {
        vm.deal(address(this), 1 ether);
        (, uint256 anchorSequence) = ASR.getAnchorRoot();
        bytes memory committed = abi.encodePacked(
            bytes1(0x01), bytes8(uint64(anchorSequence + 1)), bytes32(uint256(10)), keccak256("A")
        );
        bytes memory supplied = abi.encodePacked(
            bytes1(0x01), bytes8(uint64(anchorSequence + 2)), bytes32(uint256(10)), keccak256("B")
        );
        uint256 bond = FACTORY.initBonds(9);
        _cacheEmptyFactoryUUID(9, keccak256(committed), supplied);

        vm.expectRevert();
        FACTORY.create{value: bond}(9, keccak256(committed), supplied);
    }

    function test_type5CreationIsNotPermissionless() external {
        assertEq(FACTORY.initBonds(5), 0);
        bytes memory extraData = abi.encodePacked(
            bytes1(0x01), bytes8(uint64(block.timestamp + 1)), bytes32(uint256(10)), keccak256("root")
        );
        _cacheEmptyFactoryUUID(5, keccak256(extraData), extraData);

        vm.expectRevert();
        FACTORY.create(5, keccak256(extraData), extraData);

        assertTrue(tx.origin != TYPE5_PROPOSER);
    }

    /// @dev The shared anvil lazily fetches untouched mapping slots from its archive upstream.
    ///      Set the cryptographically fresh UUID slot to its real expected value (zero) locally so
    ///      this test does not depend on upstream rate limits. This does not bypass contract logic.
    function _cacheEmptyFactoryUUID(uint32 gameType, bytes32 rootClaim, bytes memory extraData) internal {
        bytes32 uuid = keccak256(abi.encode(gameType, rootClaim, extraData));
        bytes32 disputeGamesSlot = keccak256(abi.encode(uuid, uint256(103)));
        vm.store(address(FACTORY), disputeGamesSlot, bytes32(0));
    }
}
