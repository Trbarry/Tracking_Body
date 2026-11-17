// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

interface ISuperchainConfig26 {
    function guardian() external view returns (address);
    function pause(address identifier) external;
    function unpause(address identifier) external;
    function extend(address identifier) external;
    function paused(address identifier) external view returns (bool);
    function pauseTimestamps(address identifier) external view returns (uint256);
    function pauseExpiry() external view returns (uint256);
}

interface IPausable26 {
    function paused() external view returns (bool);
}

interface ISystemConfig26 is IPausable26 {
    function superchainConfig() external view returns (address);
    function optimismPortal() external view returns (address);
    function setFeature(bytes32 feature, bool enabled) external;
    function isCustomGasToken() external view returns (bool);
}

interface IETHLockbox26 is IPausable26 {
    function superchainConfig() external view returns (address);
    function unlockETH(uint256 value) external;
}

interface IPortal26 is IPausable26 {
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }

    struct OutputRootProof {
        bytes32 version;
        bytes32 stateRoot;
        bytes32 messagePasserStorageRoot;
        bytes32 latestBlockhash;
    }

    function ethLockbox() external view returns (address);
    function superchainConfig() external view returns (address);
    function depositTransaction(address to, uint256 value, uint64 gasLimit, bool isCreation, bytes calldata data)
        external
        payable;
    function donateETH() external payable;
    function proveWithdrawalTransaction(
        WithdrawalTransaction calldata withdrawal,
        uint256 disputeGameIndex,
        OutputRootProof calldata outputRootProof,
        bytes[] calldata withdrawalProof
    ) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata withdrawal) external;
}

interface IMessenger26 is IPausable26 {
    function superchainConfig() external view returns (address);
    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external payable;
    function relayMessage(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 minGasLimit,
        bytes calldata message
    ) external payable;
}

interface IStandardBridge26 is IPausable26 {
    function otherBridge() external view returns (address);
    function depositETHTo(address to, uint32 minGasLimit, bytes calldata extraData) external payable;
    function finalizeBridgeETH(address from, address to, uint256 amount, bytes calldata extraData) external payable;
    function finalizeBridgeERC20(
        address localToken,
        address remoteToken,
        address from,
        address to,
        uint256 amount,
        bytes calldata extraData
    ) external;
}

interface IERC721Bridge26 is IPausable26 {
    function otherBridge() external view returns (address);
    function finalizeBridgeERC721(
        address localToken,
        address remoteToken,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata extraData
    ) external;
}

interface IDelayedWETH26 {
    function ethLockbox() external view returns (address);
    function deposit() external payable;
    function balanceOf(address owner) external view returns (uint256);
    function withdraw(address guy, uint256 wad) external;
}

interface IAnchorStateRegistry26 is IPausable26 {
    function ethLockbox() external view returns (address);
    function superchainConfig() external view returns (address);
    function setAnchorState(address game) external;
}

interface IDisputeGame26 {
    function closeGame() external;
    function claimCredit(address recipient) external;
    function hasUnlockedCredit(address recipient) external view returns (bool);
}

contract PauseMatrixTest is Test {
    address internal constant SUPERCHAIN = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    address internal constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    bytes32 internal constant CUSTOM_GAS_TOKEN = bytes32("CUSTOM_GAS_TOKEN");

    address internal constant OP_SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant OP_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant OP_LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant OP_ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant OP_WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address internal constant OP_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant OP_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address internal constant OP_ERC721_BRIDGE = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
    address internal constant OP_OPEN_GAME = 0x675E956B1912Df79108408CA524fB37810500d10;
    address internal constant OP_CLOSED_LEGACY_GAME = 0xfb4D9A677aebBeAB9807c8bCc3D0FCd84ff9E826;

    bytes32 internal constant XDOMAIN_SENDER_SLOT = bytes32(uint256(204));

    function setUp() public {
        vm.createSelectFork("l1n");
        vm.deal(address(this), 10 ether);
        assertEq(ISuperchainConfig26(SUPERCHAIN).guardian(), GUARDIAN);
    }

    function test_lockboxIdentifierPausesAllDependantsOnAllFourChains() public {
        address[4] memory systems = [
            OP_SYSTEM_CONFIG,
            0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
            0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
            0xc407398d063f942feBbcC6F80a156b47F3f1BDA6
        ];
        address[4] memory portals = [
            OP_PORTAL,
            0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
            0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
            0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2
        ];
        address[4] memory lockboxes = [
            OP_LOCKBOX,
            0xbd4AbB321138e8Eddc399cE64E66451294325a14,
            0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
            0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5
        ];
        address[4] memory asrs = [
            OP_ASR,
            0xEe018bAf058227872540AC60eFbd38b023d9dAe2,
            0x4890928941e62e273dA359374b105F803329F473,
            0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9
        ];
        address[4] memory delayedWETHs = [
            OP_WETH,
            0x57b4C29DAee99a28E6E86778b499361294c134eA,
            0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47,
            0x74ad145aC900F1DD5551F0C9E143314DC4022FCf
        ];
        address[4] memory messengers = [
            OP_MESSENGER,
            0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f,
            0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f,
            0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6
        ];
        address[4] memory bridges = [
            OP_BRIDGE,
            0x88FF1e5b602916615391F55854588EFcBB7663f0,
            0xeb9bf100225c214Efc3E7C651ebbaDcF85177607,
            0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA
        ];
        address[4] memory erc721Bridges = [
            OP_ERC721_BRIDGE,
            0x661235a238B11191211fa95D4Dd9E423d521E0Be,
            0x5933e323bE8896DfaCd1cD671442F27dAA10a053,
            0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf
        ];

        for (uint256 i; i < systems.length; ++i) {
            assertEq(IPortal26(portals[i]).ethLockbox(), lockboxes[i]);
            assertEq(IAnchorStateRegistry26(asrs[i]).ethLockbox(), lockboxes[i]);
            assertEq(IDelayedWETH26(delayedWETHs[i]).ethLockbox(), lockboxes[i]);
            assertFalse(IPausable26(systems[i]).paused());

            vm.prank(GUARDIAN);
            ISuperchainConfig26(SUPERCHAIN).pause(lockboxes[i]);

            assertTrue(IPausable26(lockboxes[i]).paused());
            assertTrue(IPausable26(portals[i]).paused());
            assertTrue(IPausable26(systems[i]).paused());
            assertTrue(IPausable26(asrs[i]).paused());
            assertTrue(IPausable26(messengers[i]).paused());
            assertTrue(IPausable26(bridges[i]).paused());
            assertTrue(IPausable26(erc721Bridges[i]).paused());
        }
    }

    function test_oldPortalIdentifierDoesNotPausePostU21() public {
        vm.prank(GUARDIAN);
        ISuperchainConfig26(SUPERCHAIN).pause(OP_PORTAL);

        assertTrue(ISuperchainConfig26(SUPERCHAIN).paused(OP_PORTAL));
        assertFalse(IETHLockbox26(OP_LOCKBOX).paused());
        assertFalse(IPortal26(OP_PORTAL).paused());
        assertFalse(ISystemConfig26(OP_SYSTEM_CONFIG).paused());
        assertFalse(IAnchorStateRegistry26(OP_ASR).paused());
        assertFalse(IMessenger26(OP_MESSENGER).paused());
        assertFalse(IStandardBridge26(OP_BRIDGE).paused());
        assertFalse(IERC721Bridge26(OP_ERC721_BRIDGE).paused());
    }

    function test_pauseExpiryRequiresExtendOrUnpauseBeforeRepause() public {
        ISuperchainConfig26 cfg = ISuperchainConfig26(SUPERCHAIN);
        vm.prank(GUARDIAN);
        cfg.pause(OP_LOCKBOX);
        uint256 firstTimestamp = cfg.pauseTimestamps(OP_LOCKBOX);

        vm.warp(firstTimestamp + cfg.pauseExpiry());
        assertFalse(cfg.paused(OP_LOCKBOX));

        vm.prank(GUARDIAN);
        vm.expectRevert(abi.encodeWithSignature("SuperchainConfig_AlreadyPaused(address)", OP_LOCKBOX));
        cfg.pause(OP_LOCKBOX);

        vm.warp(block.timestamp + 1);
        vm.prank(GUARDIAN);
        cfg.extend(OP_LOCKBOX);
        assertTrue(cfg.paused(OP_LOCKBOX));

        vm.prank(GUARDIAN);
        cfg.unpause(OP_LOCKBOX);
        assertEq(cfg.pauseTimestamps(OP_LOCKBOX), 0);
    }

    function test_forcedCustomGasTokenModeStillUsesLockboxPauseIdentifier() public {
        // No governed chain is in CGT mode. This role-simulated fork state checks deployed v9
        // bytecode without claiming that the combination exists on mainnet.
        vm.prank(PROXY_ADMIN_OWNER);
        ISystemConfig26(OP_SYSTEM_CONFIG).setFeature(CUSTOM_GAS_TOKEN, true);
        assertTrue(ISystemConfig26(OP_SYSTEM_CONFIG).isCustomGasToken());

        vm.prank(GUARDIAN);
        ISuperchainConfig26(SUPERCHAIN).pause(OP_LOCKBOX);
        assertTrue(IETHLockbox26(OP_LOCKBOX).paused());
        assertTrue(IPortal26(OP_PORTAL).paused());
        assertTrue(ISystemConfig26(OP_SYSTEM_CONFIG).paused());
        assertTrue(IAnchorStateRegistry26(OP_ASR).paused());
    }

    function test_valueMovingAndStatePathsUnderLockboxPause() public {
        vm.prank(GUARDIAN);
        ISuperchainConfig26(SUPERCHAIN).pause(OP_LOCKBOX);

        IPortal26 portal = IPortal26(OP_PORTAL);
        uint256 lockboxBalance = OP_LOCKBOX.balance;

        // Inbound deposits deliberately remain live during a withdrawal pause.
        portal.depositTransaction{ value: 1 wei }(address(this), 1 wei, 21_000, false, hex"");
        assertEq(OP_LOCKBOX.balance, lockboxBalance + 1 wei);

        // Messenger and StandardBridge inbound paths also remain live and end at Portal deposits.
        IMessenger26(OP_MESSENGER).sendMessage{ value: 1 wei }(address(this), hex"", 0);
        IStandardBridge26(OP_BRIDGE).depositETHTo{ value: 1 wei }(address(this), 0, hex"");
        assertEq(OP_LOCKBOX.balance, lockboxBalance + 3 wei);

        // DelayedWETH wrapping remains live, but unwrapping does not.
        IDelayedWETH26(OP_WETH).deposit{ value: 1 wei }();
        assertEq(IDelayedWETH26(OP_WETH).balanceOf(address(this)), 1 wei);
        vm.expectRevert(bytes("DelayedWETH: contract is paused"));
        IDelayedWETH26(OP_WETH).withdraw(address(this), 0);

        IPortal26.WithdrawalTransaction memory withdrawal = IPortal26.WithdrawalTransaction({
            nonce: 0,
            sender: address(this),
            target: address(this),
            value: 0,
            gasLimit: 0,
            data: hex""
        });
        IPortal26.OutputRootProof memory outputRootProof;
        bytes[] memory withdrawalProof = new bytes[](0);

        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_CallPaused()"));
        portal.proveWithdrawalTransaction(withdrawal, 0, outputRootProof, withdrawalProof);
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_CallPaused()"));
        portal.finalizeWithdrawalTransaction(withdrawal);

        vm.expectRevert(bytes("CrossDomainMessenger: paused"));
        IMessenger26(OP_MESSENGER).relayMessage(0, address(this), address(this), 0, 0, hex"");

        // Prime the real messenger's transient xDomain sender slot to the exact state present while
        // a legitimate L2 bridge message is being relayed, then reach each bridge pause check.
        vm.store(OP_MESSENGER, XDOMAIN_SENDER_SLOT, bytes32(uint256(uint160(IStandardBridge26(OP_BRIDGE).otherBridge()))));
        vm.prank(OP_MESSENGER);
        vm.expectRevert(bytes("StandardBridge: paused"));
        IStandardBridge26(OP_BRIDGE).finalizeBridgeETH(address(this), address(this), 0, hex"");

        vm.prank(OP_MESSENGER);
        vm.expectRevert(bytes("StandardBridge: paused"));
        IStandardBridge26(OP_BRIDGE).finalizeBridgeERC20(
            address(0), address(0), address(this), address(this), 0, hex""
        );

        vm.store(
            OP_MESSENGER,
            XDOMAIN_SENDER_SLOT,
            bytes32(uint256(uint160(IERC721Bridge26(OP_ERC721_BRIDGE).otherBridge())))
        );
        vm.prank(OP_MESSENGER);
        vm.expectRevert(bytes("L1ERC721Bridge: paused"));
        IERC721Bridge26(OP_ERC721_BRIDGE).finalizeBridgeERC721(
            address(0), address(0), address(this), address(this), 0, hex""
        );

        vm.expectRevert(abi.encodeWithSignature("ETHLockbox_Paused()"));
        IETHLockbox26(OP_LOCKBOX).unlockETH(0);

        vm.expectRevert(abi.encodeWithSignature("AnchorStateRegistry_InvalidAnchorGame()"));
        IAnchorStateRegistry26(OP_ASR).setAnchorState(OP_OPEN_GAME);

        vm.expectRevert(abi.encodeWithSignature("GamePaused()"));
        IDisputeGame26(OP_OPEN_GAME).closeGame();
        vm.expectRevert(abi.encodeWithSignature("GamePaused()"));
        IDisputeGame26(OP_OPEN_GAME).claimCredit(address(this));

        // Legacy FaultDisputeGame returns from closeGame before its pause check once the game is
        // already closed. Its first claim phase may therefore unlock accounting in DelayedWETH,
        // but the DelayedWETH withdraw above proves that no underlying ETH can leave while paused.
        assertFalse(IDisputeGame26(OP_CLOSED_LEGACY_GAME).hasUnlockedCredit(address(this)));
        IDisputeGame26(OP_CLOSED_LEGACY_GAME).claimCredit(address(this));
        assertTrue(IDisputeGame26(OP_CLOSED_LEGACY_GAME).hasUnlockedCredit(address(this)));
    }
}
