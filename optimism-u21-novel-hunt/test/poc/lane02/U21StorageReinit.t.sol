// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

// LANE 02 — storage / re-initialisation invariants against the REAL deployed v9 bytecode at the end of the
// upgrade block (N = 26430859, fork alias `l1n`). Read-only fork; no broadcast.

interface IPortal {
    function initialize(address, address, address) external;
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function guardian() external view returns (address);
    function systemConfig() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function respectedGameTypeUpdatedAt() external view returns (uint64);
    function l2Sender() external view returns (address);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function params() external view returns (uint128, uint64, uint64);
    function version() external view returns (string memory);
    function initVersion() external view returns (uint8);
    function proxyAdminOwner() external view returns (address);
    function proxyAdmin() external view returns (address);
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function provenWithdrawals(bytes32, address) external view returns (address, uint64);
    function migrateLiquidity() external;
}

interface ISysCfg {
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function optimismPortal() external view returns (address);
    function delayedWETH() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function optimismMintableERC20Factory() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function owner() external view returns (address);
    function guardian() external view returns (address);
    function setFeature(bytes32, bool) external;
    function initVersion() external view returns (uint8);
}

interface ILockbox {
    function initialize(address, address[] calldata) external;
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function guardian() external view returns (address);
    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
}

interface IASR {
    struct Proposal {
        bytes32 root;
        uint256 l2SequenceNumber;
    }

    function initialize(address, address, Proposal calldata, uint32) external;
    function paused() external view returns (bool);
    function ethLockbox() external view returns (address);
    function superchainConfig() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function anchorGame() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function getAnchorRoot() external view returns (bytes32, uint256);
}

interface IWETH {
    function initialize(address) external;
    function ethLockbox() external view returns (address);
    function config() external view returns (address);
}

interface IInit1 {
    function initialize(address) external;
}

interface IInit2 {
    function initialize(address, address) external;
}

contract U21StorageReinitTest is Test {
    address constant PAO = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    bytes32 constant ETH_LOCKBOX = "ETH_LOCKBOX";
    bytes32 constant INTEROP = "INTEROP";
    bytes32 constant CGT = "CUSTOM_GAS_TOKEN";
    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address[4] sysCfgs = [
        0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, // OP Mainnet
        0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, // Ink
        0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, // Soneium
        0xc407398d063f942feBbcC6F80a156b47F3f1BDA6 // Unichain
    ];

    function setUp() public {
        vm.createSelectFork("l1n");
        assertEq(block.number, 26430859, "must be the upgrade block");
    }

    /// Every v9 pointer that U21 introduced is non-zero and mutually consistent on all four chains.
    function test_newV9FieldsWiredOnAllFourChains() public view {
        for (uint256 i; i < 4; i++) {
            ISysCfg sc = ISysCfg(sysCfgs[i]);
            IPortal portal = IPortal(sc.optimismPortal());
            ILockbox lb = ILockbox(portal.ethLockbox());
            IASR asr = IASR(portal.anchorStateRegistry());
            IWETH weth = IWETH(sc.delayedWETH());
            assertTrue(address(lb) != address(0), "lockbox zero");
            assertTrue(sc.isFeatureEnabled(ETH_LOCKBOX), "ETH_LOCKBOX feature");
            assertFalse(sc.isFeatureEnabled(INTEROP), "INTEROP must be off");
            assertFalse(sc.isFeatureEnabled(CGT), "CGT must be off");
            assertEq(lb.superchainConfig(), SUPERCHAIN_CONFIG, "lockbox.superchainConfig");
            assertEq(sc.superchainConfig(), SUPERCHAIN_CONFIG, "systemConfig.superchainConfig");
            assertEq(asr.ethLockbox(), address(lb), "asr.ethLockbox");
            assertEq(weth.ethLockbox(), address(lb), "weth.ethLockbox");
            assertEq(weth.config(), SUPERCHAIN_CONFIG, "weth.config");
            assertEq(asr.superchainConfig(), SUPERCHAIN_CONFIG, "asr.superchainConfig");
            assertEq(portal.superchainConfig(), SUPERCHAIN_CONFIG, "portal.superchainConfig");
            assertEq(asr.disputeGameFactory(), sc.disputeGameFactory(), "dgf");
            assertTrue(lb.authorizedPortals(address(portal)), "portal authorised");
            assertFalse(lb.authorizedLockboxes(address(lb)), "no self lockbox auth");
            assertEq(address(portal).balance, 0, "portal holds no ETH");
            // one pause resolver for everything
            assertEq(portal.paused(), lb.paused());
            assertEq(sc.paused(), lb.paused());
            assertEq(asr.paused(), lb.paused());
            assertFalse(lb.paused());
            assertEq(portal.proxyAdminOwner(), PAO);
        }
    }

    /// Nobody (random caller, ProxyAdmin owner, ProxyAdmin) can run any initializer again on the live proxies.
    function test_reinitializeRevertsForEveryCaller() public {
        for (uint256 i; i < 4; i++) {
            ISysCfg sc = ISysCfg(sysCfgs[i]);
            IPortal portal = IPortal(sc.optimismPortal());
            address lb = portal.ethLockbox();
            address asr = portal.anchorStateRegistry();
            address weth = sc.delayedWETH();
            Addrs memory x = Addrs({
                sc: address(sc),
                portal: address(portal),
                lb: lb,
                asr: asr,
                weth: weth,
                dgf: sc.disputeGameFactory(),
                factory: sc.optimismMintableERC20Factory(),
                cdm: sc.l1CrossDomainMessenger(),
                sb: sc.l1StandardBridge(),
                nft: sc.l1ERC721Bridge()
            });
            _expectAllInitializersLocked(x, address(0xBEEF));
            _expectAllInitializersLocked(x, PAO);
            _expectAllInitializersLocked(x, portal.proxyAdmin());
        }
    }

    struct Addrs {
        address sc;
        address portal;
        address lb;
        address asr;
        address weth;
        address dgf;
        address factory;
        address cdm;
        address sb;
        address nft;
    }

    function _expectAllInitializersLocked(Addrs memory x, address caller) internal {
        bytes memory err = bytes("Initializable: contract is already initialized");
        address[] memory portals = new address[](1);
        portals[0] = x.portal;
        vm.startPrank(caller);
        vm.expectRevert(err);
        IPortal(x.portal).initialize(x.sc, x.asr, x.lb);
        vm.expectRevert(err);
        ILockbox(x.lb).initialize(SUPERCHAIN_CONFIG, portals);
        vm.expectRevert(err);
        IASR(x.asr).initialize(x.lb, x.dgf, IASR.Proposal(bytes32(uint256(1)), 2), 9);
        vm.expectRevert(err);
        IWETH(x.weth).initialize(x.lb);
        vm.expectRevert(err);
        IInit1(x.dgf).initialize(caller);
        vm.expectRevert(err);
        IInit1(x.factory).initialize(caller); // `initializer` (not reinitializer) + ProxyAdmin ACL, src/universal/OptimismMintableERC20Factory.sol:65-67
        vm.expectRevert(err);
        IInit2(x.cdm).initialize(x.sc, x.portal);
        vm.expectRevert(err);
        IInit2(x.sb).initialize(x.cdm, x.sc);
        vm.expectRevert(err);
        IInit2(x.nft).initialize(x.cdm, x.sc);
        vm.expectRevert(err);
        IInit1(SUPERCHAIN_CONFIG).initialize(caller);
        vm.stopPrank();
    }

    /// The implementation contracts behind the proxies are locked (_initialized == 255) and cannot be initialised.
    function test_implementationsAreLocked() public {
        ISysCfg sc = ISysCfg(sysCfgs[0]);
        IPortal portal = IPortal(sc.optimismPortal());
        address[7] memory proxies = [
            address(portal),
            address(sc),
            portal.ethLockbox(),
            portal.anchorStateRegistry(),
            sc.delayedWETH(),
            sc.disputeGameFactory(),
            SUPERCHAIN_CONFIG
        ];
        for (uint256 i; i < proxies.length; i++) {
            address impl = address(uint160(uint256(vm.load(proxies[i], IMPL_SLOT))));
            assertTrue(impl.code.length > 0, "impl has code");
            assertEq(uint8(uint256(vm.load(impl, bytes32(0)))), 255, "impl _initialized must be 255");
        }
        address portalImpl = address(uint160(uint256(vm.load(address(portal), IMPL_SLOT))));
        address asr_ = portal.anchorStateRegistry();
        address lb_ = portal.ethLockbox();
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        IPortal(portalImpl).initialize(address(sc), asr_, lb_);
        address lbImpl = address(uint160(uint256(vm.load(lb_, IMPL_SLOT))));
        address[] memory none = new address[](0);
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        ILockbox(lbImpl).initialize(SUPERCHAIN_CONFIG, none);
        // ETH-moving entry points on the bare lockbox implementation are closed to everyone
        vm.deal(address(this), 1 ether);
        vm.expectRevert();
        ILockbox(lbImpl).lockETH{ value: 1 }();
        vm.expectRevert();
        ILockbox(lbImpl).receiveLiquidity{ value: 1 }();
        vm.expectRevert();
        ILockbox(lbImpl).unlockETH(0);
    }

    struct View {
        bool paused;
        address superchainConfig;
        address guardian;
        address systemConfig;
        address asr;
        address lockbox;
        address dgf;
        uint32 rgt;
        uint64 rgtAt;
        address l2Sender;
        bool scPaused;
        bool asrPaused;
        address asrLockbox;
        address wethLockbox;
        bytes32 anchorRoot;
        uint256 anchorSeq;
    }

    function _view(ISysCfg sc) internal view returns (View memory v) {
        IPortal portal = IPortal(sc.optimismPortal());
        v.paused = portal.paused();
        v.superchainConfig = portal.superchainConfig();
        v.guardian = portal.guardian();
        v.systemConfig = portal.systemConfig();
        v.asr = portal.anchorStateRegistry();
        v.lockbox = portal.ethLockbox();
        v.dgf = portal.disputeGameFactory();
        v.rgt = portal.respectedGameType();
        v.rgtAt = portal.respectedGameTypeUpdatedAt();
        v.l2Sender = portal.l2Sender();
        v.scPaused = sc.paused();
        v.asrPaused = IASR(v.asr).paused();
        v.asrLockbox = IASR(v.asr).ethLockbox();
        v.wethLockbox = IWETH(sc.delayedWETH()).ethLockbox();
        (v.anchorRoot, v.anchorSeq) = IASR(v.asr).getAnchorRoot();
    }

    function _trashPortal(address portal, bytes32 junk) internal {
        // 52 (legacy provenWithdrawals), 53 (paused|superchainConfig), 54 (l2Oracle), 56 (disputeGameFactory),
        // 58 (disputeGameBlacklist), 59 (respectedGameType|respectedGameTypeUpdatedAt), 61 (_balance)
        uint8[7] memory ps = [52, 53, 54, 56, 58, 59, 61];
        for (uint256 k; k < ps.length; k++) {
            vm.store(portal, bytes32(uint256(ps[k])), junk);
        }
        // slot 63: keep ethLockbox (low 20 bytes), set the legacy superRootsActive bool + all upper bytes
        bytes32 s63 = vm.load(portal, bytes32(uint256(63)));
        vm.store(portal, bytes32(uint256(63)), s63 | bytes32(uint256(type(uint96).max) << 160));
    }

    function _trashOthers(ISysCfg sc, address lb, address asr, bytes32 junk) internal {
        // ETHLockbox / ASR slot 0: keep _initialized/_initializing (low 2 bytes), trash the legacy systemConfig spacer
        bytes32 l0 = vm.load(lb, bytes32(0));
        vm.store(lb, bytes32(0), (l0 & bytes32(uint256(0xffff))) | (junk << 16));
        bytes32 a0 = vm.load(asr, bytes32(0));
        vm.store(asr, bytes32(0), (a0 & bytes32(uint256(0xffff))) | (junk << 16));
        // DelayedWETH slot 4 (legacy systemConfig)
        vm.store(sc.delayedWETH(), bytes32(uint256(4)), junk);
        // L1CDM legacy spacers 51, 101, 151, 201, 202, 251, 253 ; L1StandardBridge 1, 50, 51
        address cdm = sc.l1CrossDomainMessenger();
        uint8[7] memory cs = [51, 101, 151, 201, 202, 251, 253];
        for (uint256 k; k < cs.length; k++) {
            vm.store(cdm, bytes32(uint256(cs[k])), junk);
        }
        address sb = sc.l1StandardBridge();
        vm.store(sb, bytes32(uint256(1)), junk);
        vm.store(sb, bytes32(uint256(50)), junk);
        vm.store(sb, bytes32(uint256(51)), junk);
    }

    /// Differential test: overwrite every legacy `spacer_*` slot that is NON-ZERO on mainnet (and the zero ones) with
    /// adversarial garbage; every v9 getter, the pause resolver and a live ETH deposit must be unaffected.
    /// => no v9 code path reads a pre-upgrade value under a new meaning.
    function test_legacySpacerSlotsAreDeadStorage() public {
        for (uint256 i; i < 4; i++) {
            ISysCfg sc = ISysCfg(sysCfgs[i]);
            IPortal portal = IPortal(sc.optimismPortal());
            address lb = portal.ethLockbox();
            bytes32 beforeHash = keccak256(abi.encode(_view(sc)));
            bytes32 junk = keccak256(abi.encode("lane02-junk", i));
            _trashPortal(address(portal), junk);
            _trashOthers(sc, lb, portal.anchorStateRegistry(), junk);
            assertEq(beforeHash, keccak256(abi.encode(_view(sc))), "a v9 getter depends on a legacy spacer slot");

            // live deposit still routes ETH to the lockbox
            uint256 balBefore = lb.balance;
            address user = address(0xA11CE);
            vm.deal(user, 2 ether);
            vm.prank(user, user);
            portal.depositTransaction{ value: 1 ether }(user, 1 ether, 100_000, false, "");
            assertEq(lb.balance, balBefore + 1 ether, "deposit must land in the lockbox");
            assertEq(address(portal).balance, 0);
        }
    }

    /// ETH_LOCKBOX / INTEROP can never be switched off again, even by the ProxyAdmin owner.
    function test_featureFlagsAreOneWay() public {
        ISysCfg sc = ISysCfg(sysCfgs[0]);
        vm.startPrank(PAO);
        vm.expectRevert(abi.encodeWithSignature("SystemConfig_InvalidFeatureState()"));
        sc.setFeature(ETH_LOCKBOX, false);
        vm.expectRevert(abi.encodeWithSignature("SystemConfig_InvalidFeatureState()"));
        sc.setFeature(INTEROP, false);
        vm.stopPrank();
    }
}
