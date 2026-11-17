// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

interface ISC {
    function guardian() external view returns (address);
    function pause(address) external;
    function unpause(address) external;
    function extend(address) external;
    function paused(address) external view returns (bool);
    function paused() external view returns (bool);
    function pausable(address) external view returns (bool);
    function expiration(address) external view returns (uint256);
    function pauseTimestamps(address) external view returns (uint256);
    function isLocalOrGlobalPaused(address) external view returns (bool);
    function pauseExpiry() external view returns (uint256);
}
interface IPausable { function paused() external view returns (bool); }
interface ISys is IPausable {
    function optimismPortal() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function delayedWETH() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function setFeature(bytes32, bool) external;
    function isFeatureEnabled(bytes32) external view returns (bool);
    function proxyAdminOwner() external view returns (address);
    function owner() external view returns (address);
    function setGasLimit(uint64) external;
}
struct WithdrawalTransaction { uint256 nonce; address sender; address target; uint256 value; uint256 gasLimit; bytes data; }
struct OutputRootProof { bytes32 version; bytes32 stateRoot; bytes32 messagePasserStorageRoot; bytes32 latestBlockhash; }
interface IPortal is IPausable {
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function proveWithdrawalTransaction(WithdrawalTransaction memory, uint256, OutputRootProof calldata, bytes[] calldata) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function migrateToSharedDisputeGame(address, address) external;
    function migrateLiquidity() external;
    function donateETH() external payable;
}
interface ILockbox is IPausable {
    function unlockETH(uint256) external;
    function lockETH() external payable;
    function migrateLiquidity(address) external;
}
interface ICDM is IPausable {
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function sendMessage(address, bytes calldata, uint32) external payable;
}
interface IBridge is IPausable {
    function finalizeBridgeETH(address, address, uint256, bytes calldata) external payable;
    function finalizeBridgeERC20(address, address, address, address, uint256, bytes calldata) external;
    function depositETH(uint32, bytes calldata) external payable;
}
interface I721 is IPausable { function finalizeBridgeERC721(address, address, address, address, uint256, bytes calldata) external; }
interface IWETH { function withdraw(address, uint256) external; function withdraw(uint256) external; function unlock(address, uint256) external; function deposit() external payable; function balanceOf(address) external view returns (uint256); }
interface IASR is IPausable {
    function setAnchorState(address) external;
    function isGameProper(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function anchorGame() external view returns (address);
    function ethLockbox() external view returns (address);
}
interface IDGF { function gameCount() external view returns (uint256); function gameAtIndex(uint256) external view returns (uint32, uint64, address); function create(uint32, bytes32, bytes calldata) external payable returns (address); function initBonds(uint32) external view returns (uint256);}
interface IGame {
    function status() external view returns (uint8);
    function resolvedAt() external view returns (uint64);
    function createdAt() external view returns (uint64);
    function gameCreator() external view returns (address);
    function claimCredit(address) external;
    function credit(address) external view returns (uint256);
    function normalModeCredit(address) external view returns (uint256);
    function refundModeCredit(address) external view returns (uint256);
    function bondDistributionMode() external view returns (uint8);
    function closeGame() external;
    function weth() external view returns (address);
    function gameType() external view returns (uint32);
}

contract PauseMatrixTest is Test {
    ISC constant SC = ISC(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    address[4] SYS = [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6];
    string[4] NAME = ["op", "ink", "soneium", "unichain"];
    address guardian;

    function setUp() public {
        vm.createSelectFork("l1", 26433900);
        guardian = SC.guardian();
    }

    function _all(uint256 i) internal view returns (bool[7] memory p) {
        ISys s = ISys(SYS[i]);
        IPortal portal = IPortal(s.optimismPortal());
        p[0] = s.paused();
        p[1] = portal.paused();
        p[2] = IPausable(portal.ethLockbox()).paused();
        p[3] = IPausable(portal.anchorStateRegistry()).paused();
        p[4] = IPausable(s.l1CrossDomainMessenger()).paused();
        p[5] = IPausable(s.l1StandardBridge()).paused();
        p[6] = IPausable(s.l1ERC721Bridge()).paused();
    }
    function _assertAll(uint256 i, bool expected) internal view {
        bool[7] memory p = _all(i);
        for (uint256 k; k < 7; k++) assertEq(p[k], expected, string.concat(NAME[i], " getter ", vm.toString(k)));
    }

    /// Every pause getter of every chain resolves to the same identifier (its lockbox), chain-isolated.
    function test_identifier_consistency() public {
        for (uint256 i; i < 4; i++) _assertAll(i, false);
        for (uint256 i; i < 4; i++) {
            address lockbox = IPortal(ISys(SYS[i]).optimismPortal()).ethLockbox();
            uint256 snap = vm.snapshotState();
            vm.prank(guardian); SC.pause(lockbox);
            for (uint256 j; j < 4; j++) _assertAll(j, i == j);
            vm.revertToState(snap); snap = vm.snapshotState();
            // old identifier (portal address) no longer pauses anything
            address portalAddr = ISys(SYS[i]).optimismPortal(); vm.prank(guardian); SC.pause(portalAddr);
            for (uint256 j; j < 4; j++) _assertAll(j, false);
            vm.revertToState(snap); snap = vm.snapshotState();
            // SystemConfig address as identifier: nothing
            vm.prank(guardian); SC.pause(SYS[i]);
            for (uint256 j; j < 4; j++) _assertAll(j, false);
            vm.revertToState(snap);
        }
        vm.prank(guardian); SC.pause(address(0));
        for (uint256 j; j < 4; j++) _assertAll(j, true);
    }

    /// Expiry / re-arm semantics.
    function test_expiry_semantics() public {
        address lockbox = IPortal(ISys(SYS[0]).optimismPortal()).ethLockbox();
        vm.prank(guardian); SC.pause(lockbox);
        _assertAll(0, true);
        vm.warp(block.timestamp + SC.pauseExpiry() - 1);
        _assertAll(0, true);
        vm.warp(block.timestamp + 1);
        _assertAll(0, false);                       // expired silently, no tx needed
        assertFalse(SC.pausable(lockbox));           // but still "not pausable"
        vm.prank(guardian); vm.expectRevert(); SC.pause(lockbox); // AlreadyPaused -> a fresh pause() fails
        vm.prank(guardian); SC.extend(lockbox);      // extend re-arms an expired pause
        _assertAll(0, true);
        vm.prank(address(0xbeef)); vm.expectRevert(); SC.unpause(lockbox);
        vm.prank(address(0xbeef)); vm.expectRevert(); SC.extend(lockbox);
        vm.prank(address(0xbeef)); vm.expectRevert(); SC.pause(address(1));
    }

    function _findResolvedGame(address dgf, uint32 wantType) internal view returns (IGame g) {
        uint256 n = IDGF(dgf).gameCount();
        for (uint256 k = 1; k < 400; k++) {
            (uint32 gt,, address a) = IDGF(dgf).gameAtIndex(n - k);
            if (gt != wantType) continue;
            IGame c = IGame(a);
            if (c.status() == 2 && c.resolvedAt() != 0) {
                address cr = c.gameCreator();
                (bool ok, bytes memory d) = a.staticcall(abi.encodeWithSignature("normalModeCredit(address)", cr));
                (bool ok2, bytes memory d2) = a.staticcall(abi.encodeWithSignature("bondDistributionMode()"));
                if (ok && ok2 && abi.decode(d, (uint256)) > 0 && abi.decode(d2, (uint8)) == 0) return c;
            }
        }
    }

    /// Value-moving entry points under a lockbox-identifier pause on OP Mainnet.
    function test_value_paths_under_pause_op() public {
        ISys s = ISys(SYS[0]);
        IPortal portal = IPortal(s.optimismPortal());
        ILockbox lockbox = ILockbox(portal.ethLockbox());
        IASR asr = IASR(portal.anchorStateRegistry());
        IGame game = _findResolvedGame(s.disputeGameFactory(), 9);
        emit log_named_address("resolved game w/ unclaimed credit", address(game));
        assertTrue(address(game) != address(0), "need a game");
        address creator = game.gameCreator();
        if (block.timestamp - game.resolvedAt() <= 302400) vm.warp(uint256(game.resolvedAt()) + 302400 + 1);

        // Baseline (unpaused): claimCredit step 1 works (closeGame + unlock); and setAnchorState may work.
        uint256 snap = vm.snapshotState();
        game.claimCredit(creator);
        vm.revertToState(snap);

        vm.prank(guardian); SC.pause(address(lockbox));

        WithdrawalTransaction memory wtx = WithdrawalTransaction(0, address(1), address(2), 1 ether, 100000, "");
        OutputRootProof memory orp;
        bytes[] memory proof = new bytes[](0);

        // 1. prove
        vm.expectRevert(bytes4(keccak256("OptimismPortal_CallPaused()")));
        portal.proveWithdrawalTransaction(wtx, 0, orp, proof);
        // 2. finalize (both variants)
        vm.expectRevert(bytes4(keccak256("OptimismPortal_CallPaused()")));
        portal.finalizeWithdrawalTransaction(wtx);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_CallPaused()")));
        portal.finalizeWithdrawalTransactionExternalProof(wtx, address(this));
        // 3. lockbox unlock even from the authorized portal
        vm.prank(address(portal)); vm.expectRevert(bytes4(keccak256("ETHLockbox_Paused()")));
        lockbox.unlockETH(1);
        // 4. messenger relay
        ICDM cdm = ICDM(s.l1CrossDomainMessenger());
        vm.expectRevert(bytes("CrossDomainMessenger: paused"));
        cdm.relayMessage(1 << 240, address(1), address(2), 0, 0, "");
        // 5. bridges (prank as messenger so the pause check is what fires, not onlyOtherBridge)
        IBridge br = IBridge(s.l1StandardBridge());
        vm.mockCall(address(cdm), abi.encodeWithSignature("xDomainMessageSender()"), abi.encode(address(0x4200000000000000000000000000000000000010)));
        vm.prank(address(cdm)); vm.expectRevert(bytes("StandardBridge: paused"));
        br.finalizeBridgeETH(address(1), address(2), 0, "");
        vm.prank(address(cdm)); vm.expectRevert(bytes("StandardBridge: paused"));
        br.finalizeBridgeERC20(address(1), address(2), address(3), address(4), 0, "");
        I721 nft = I721(s.l1ERC721Bridge());
        vm.mockCall(address(cdm), abi.encodeWithSignature("xDomainMessageSender()"), abi.encode(address(0x4200000000000000000000000000000000000014)));
        vm.prank(address(cdm)); vm.expectRevert(bytes("L1ERC721Bridge: paused"));
        nft.finalizeBridgeERC721(address(1), address(2), address(3), address(4), 0, "");
        vm.clearMockedCalls();
        // 6. DelayedWETH
        IWETH weth = IWETH(s.delayedWETH());
        vm.expectRevert(bytes("DelayedWETH: contract is paused"));
        weth.withdraw(address(this), 0);
        // 7. game claimCredit / closeGame
        vm.expectRevert(bytes4(keccak256("GamePaused()")));
        game.claimCredit(creator);
        vm.expectRevert(bytes4(keccak256("GamePaused()")));
        game.closeGame();
        // 8. ASR
        assertFalse(asr.isGameProper(address(game)));
        vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_InvalidAnchorGame()")));
        asr.setAnchorState(address(game));

        // ---- what stays live ----
        // deposits (ETH flows INTO the lockbox)
        uint256 b0 = address(lockbox).balance;
        vm.deal(address(0xA11CE), 10 ether);
        vm.prank(address(0xA11CE), address(0xA11CE));
        portal.depositTransaction{ value: 1 ether }(address(0xA11CE), 1 ether, 100000, false, "");
        assertEq(address(lockbox).balance, b0 + 1 ether);
        // messenger / bridge deposits
        vm.prank(address(0xA11CE), address(0xA11CE));
        br.depositETH{ value: 1 ether }(200000, "");
        assertEq(address(lockbox).balance, b0 + 2 ether);
        // DelayedWETH.unlock (bookkeeping only) + deposit
        weth.unlock(address(this), 1);
        // game creation
        // (not value-out; skipped)
    }

    /// Legacy DelayedWETH proxies (<= v1.3.0, pre-U16 games) only honour the GLOBAL pause.
    function test_legacy_weth_ignores_identifier_pause() public {
        address lockbox = IPortal(ISys(SYS[0]).optimismPortal()).ethLockbox();
        address[3] memory legacy = [0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14, 0x82511d494B5C942BE57498a70Fdd7184Ee33B975, 0x323dFC63c9B83CB83f40325AaB74b245937cbdF0];
        vm.prank(guardian); SC.pause(lockbox);
        for (uint256 i; i < 3; i++) {
            emit log_named_decimal_uint("legacy weth balance", legacy[i].balance, 18);
            // not the paused revert: reaches the bookkeeping checks
            vm.expectRevert(bytes("DelayedWETH: insufficient unlocked withdrawal"));
            IWETH(legacy[i]).withdraw(address(this), 1);
        }
        vm.prank(guardian); SC.pause(address(0));
        for (uint256 i; i < 3; i++) {
            vm.expectRevert(bytes("DelayedWETH: contract is paused"));
            IWETH(legacy[i]).withdraw(address(this), 1);
        }
    }
}
