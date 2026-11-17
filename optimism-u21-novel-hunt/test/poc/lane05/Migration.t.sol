// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";
import { LifecycleBase } from "./Lifecycle.t.sol";

interface ISysCfg {
    function setFeature(bytes32, bool) external;
    function isFeatureEnabled(bytes32) external view returns (bool);
}

interface IPortalMig {
    function migrateToSharedDisputeGame(address _newLockbox, address _newASR) external;
}

interface IDGFAdmin {
    function initialize(address) external;
    function setImplementation(uint32, address, bytes calldata) external;
    function setInitBond(uint32, uint256) external;
    function gameArgs(uint32) external view returns (bytes memory);
    function owner() external view returns (address);
}

interface IASRInit {
    struct Proposal {
        bytes32 root;
        uint256 l2SequenceNumber;
    }
    function initialize(address _lockbox, address _dgf, Proposal memory _start, uint32 _gt) external;
}

/// SIMULATION of the *future, documented, ProxyAdminOwner-only* registry swap
/// (`OptimismPortal2.migrateToSharedDisputeGame`, as driven by OPContractsManagerMigrator.migrate):
/// fresh DGF + ASR proxies running the REAL deployed v9 implementations, real portal.
/// All privileged pranks here model that planned governance action, nothing else.
contract MigrationSurvivalTest is LifecycleBase {
    address constant PAO = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // ProxyAdmin owner Safe
    address constant PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address constant SYSCFG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address constant ASR_IMPL = 0x2b27299C577d4720100e2735b652444DcEa652D0;
    address constant DGF_IMPL = 0x72B971717E088B59F26d4236BE222ADB6ACD393b;
    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    IASR newASR;
    IDGF newDGF;

    function _freshProxy(address like, address impl, string memory name) internal returns (address p) {
        p = makeAddr(name);
        vm.etch(p, like.code);
        vm.store(p, IMPL_SLOT, bytes32(uint256(uint160(impl))));
        vm.store(p, ADMIN_SLOT, bytes32(uint256(uint160(PROXY_ADMIN))));
    }

    function _migrate() internal {
        newDGF = IDGF(_freshProxy(address(DGF), DGF_IMPL, "newDGF"));
        newASR = IASR(_freshProxy(address(ASR), ASR_IMPL, "newASR"));
        vm.startPrank(PAO);
        IDGFAdmin(address(newDGF)).initialize(PAO);
        (bytes32 root, uint256 seq) = ASR.getAnchorRoot();
        IASRInit(address(newASR)).initialize(LOCKBOX, address(newDGF), IASRInit.Proposal(root, seq), GT);
        // game impl 9 with args re-pointed at the new ASR
        bytes memory args = IDGFAdmin(address(DGF)).gameArgs(GT);
        for (uint256 i; i < 20; i++) args[52 + i] = bytes20(address(newASR))[i];
        IDGFAdmin(address(newDGF)).setImplementation(GT, DGF.gameImpls(GT), args);
        IDGFAdmin(address(newDGF)).setInitBond(GT, DGF.initBonds(GT));
        ISysCfg(SYSCFG).setFeature(bytes32("INTEROP"), true);
        IPortalMig(address(PORTAL)).migrateToSharedDisputeGame(LOCKBOX, address(newASR));
        vm.stopPrank();
        assertEq(PORTAL.anchorStateRegistry(), address(newASR));
    }

    bytes32 wh;
    address sub;
    address gOld;
    bytes32 fh;
    IGame badOld;

    function _setupProofs() internal {
        // real in-flight proof #0 (v8-era) against a real honest game
        string memory j = vm.readFile("provetxs.json");
        wh = vm.parseJsonBytes32(j, ".0.hash");
        sub = vm.parseJsonAddress(j, ".0.submitter");
        (gOld,) = PORTAL.provenWithdrawals(wh, sub);
        IGame old = IGame(gOld);

        // attacker pre-positions a shadow proof against his own invalid game in the OLD factory
        WithdrawalTransaction memory fake = _wd(attacker, 1000 ether, 7);
        fh = _hashWithdrawal(fake);
        uint256 idx;
        OutputRootProof memory orp;
        bytes[] memory proof;
        (badOld, idx, orp, proof) = _createGameFor(attacker, fh, _nextSeq());
        vm.warp(block.timestamp + 12);
        vm.prank(attacker);
        PORTAL.proveWithdrawalTransaction(fake, idx, orp, proof);

        // honest old game resolves + finalizes; old proof matures
        vm.warp(uint256(old.createdAt()) + old.maxClockDuration() + 1);
        old.resolveClaim(0, 0);
        old.resolve();
        vm.warp(block.timestamp + 8 days);
        PORTAL.checkWithdrawal(wh, sub); // finalizable under the old registry
    }

    function _twin(IGame g) internal returns (address twin) {
        bytes memory extra = g.extraData();
        bytes32 rc = g.rootClaim();
        vm.prank(attacker);
        try newDGF.create{ value: 0.08 ether }(GT, rc, extra) returns (address t) {
            twin = t;
            (address reg,) = newDGF.games(GT, rc, extra);
            assertEq(reg, twin);
            assertTrue(twin != address(g));
        } catch {
            console.log("twin create reverted (seq <= anchor)");
        }
    }

    function test_proofs_do_not_survive_registry_swap() public {
        _setupProofs();
        _migrate();

        // (1) both locks under the new registry
        assertFalse(newASR.isGameRegistered(gOld), "old game not registered in new DGF");
        assertTrue(newASR.isGameRetired(gOld), "old game retired by fresh retirementTimestamp");
        assertFalse(newASR.isGameClaimValid(gOld));
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.checkWithdrawal(wh, sub);

        // (2) dead-but-not-deletable: old valid game is neither CHALLENGER_WINS nor blacklisted in the new ASR
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, sub);

        // (3) survival attempt: register games with IDENTICAL (type, rootClaim, extraData) in the NEW
        //     factory. They land at different addresses, so the stored old proxies stay unregistered.
        vm.warp(block.timestamp + 12);
        address twinHonest = _twin(IGame(gOld));
        console.log("twin of honest game", twinHonest);
        address twinBad = _twin(badOld);
        console.log("twin of attacker game", twinBad);
        assertTrue(twinBad != address(0));
        assertFalse(newASR.isGameRegistered(address(badOld)));
        assertFalse(newASR.isGameRegistered(gOld));

        // attacker's twin unchallenged for 3.5d + 3.5d airgap (worst case) -> the OLD shadow proof still dead
        vm.warp(block.timestamp + IGame(twinBad).maxClockDuration() + 1);
        IGame(twinBad).resolveClaim(0, 0);
        IGame(twinBad).resolve();
        vm.warp(block.timestamp + 4 days);
        assertTrue(newASR.isGameClaimValid(twinBad));
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.checkWithdrawal(fh, attacker);
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.checkWithdrawal(wh, sub);

        // (4) old-ASR blacklist is not consulted by delete after the swap
        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(gOld);
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, sub);
        // ... new-ASR blacklist is (guardian can blacklist arbitrary addresses)
        vm.prank(GUARDIAN);
        newASR.blacklistDisputeGame(gOld);
        PORTAL.deleteProvenWithdrawal(wh, sub);
        (, uint64 ts2) = PORTAL.provenWithdrawals(wh, sub);
        assertEq(ts2, 0);
    }
}
