// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ATKE_Base.sol";

/// @notice ATK-E. Poison every attacker-writable legacy/orphaned/current object of OP Mainnet + Unichain from an
///         unprivileged EOA, then run the PLANNED OPCMv2.migrate (real deployed OPCM 9.0.3) and compare it with a
///         clean migrate executed at the same block/timestamp (snapshot/revert). Records every account and storage
///         access of both migrations (vm.startStateDiffRecording) to evidence/attack-wave/E/.
contract ATKE_PoisonTest is ATKEBase {
    string constant EV = "../../../../evidence/attack-wave/E/";

    address opAtkGame;
    address uniAtkGame;
    uint256 forcedIntoLockboxes;
    uint256 portalDonations;
    uint256 portalDeposits;
    string poisonLog;

    struct Outcome {
        address lb;
        address asr;
        address dgf;
        uint256 lbBal;
        bytes32 startRoot;
        uint256 startSeq;
        bytes32 anchorRoot;
        uint256 anchorSeq;
        uint32 rgt;
        uint64 retire;
        address impl9;
        bytes32 args9;
        uint256 bond9;
        address opOldAnchor;
        address uniOldAnchor;
        bytes32 opOldStartRoot;
        uint64 opOldRetire;
        address opOldLb;
        address uniOldLb;
        address uniScWeth;
        address uniWethLb;
        bool authOp;
        bool authUni;
        bool authOldOp;
        bool authOldUni;
        uint256 gas;
    }

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        vm.deal(attacker, 1000 ether);
    }

    function _outcome() internal view returns (Outcome memory o) {
        o.lb = sharedLB;
        o.asr = address(sharedASR);
        o.dgf = address(sharedDGF);
        o.lbBal = sharedLB.balance;
        Proposal memory s = sharedASR.getStartingAnchorRoot();
        o.startRoot = s.root;
        o.startSeq = s.l2SequenceNumber;
        (o.anchorRoot, o.anchorSeq) = sharedASR.getAnchorRoot();
        o.rgt = sharedASR.respectedGameType();
        o.retire = sharedASR.retirementTimestamp();
        o.impl9 = sharedDGF.gameImpls(9);
        o.args9 = keccak256(sharedDGF.gameArgs(9));
        o.bond9 = sharedDGF.initBonds(9);
        o.opOldAnchor = OP_ASR.anchorGame();
        o.uniOldAnchor = UNI_ASR.anchorGame();
        o.opOldStartRoot = OP_ASR.getStartingAnchorRoot().root;
        o.opOldRetire = OP_ASR.retirementTimestamp();
        o.opOldLb = OP_ASR.ethLockbox();
        o.uniOldLb = UNI_ASR.ethLockbox();
        o.uniScWeth = UNI_SC.delayedWETH();
        o.uniWethLb = IWETH(UNI_WETH).ethLockbox();
        o.authOp = ILockbox(sharedLB).authorizedPortals(address(OP_PORTAL));
        o.authUni = ILockbox(sharedLB).authorizedPortals(address(UNI_PORTAL));
        o.authOldOp = ILockbox(sharedLB).authorizedLockboxes(OP_LB);
        o.authOldUni = ILockbox(sharedLB).authorizedLockboxes(UNI_LB);
        o.gas = lastMigrateGas;
    }

    function _log(string memory what, bool ok, bytes memory ret) internal {
        poisonLog = string.concat(poisonLog, what, " | ", _res(ok, ret), "\n");
    }

    /// @dev every attacker-writable object we found, from an unprivileged EOA (tx.origin == msg.sender == attacker)
    function _poison() internal {
        bool ok;
        bytes memory r;
        vm.startPrank(attacker, attacker);

        // P1 orphaned gen-2 registries (v2.2.2): permissionless setAnchorState with a LIVE-registry legacy game
        {
            (,, address gop) = OP_DGF.gameAtIndex(20094);
            (,, address guni) = UNI_DGF.gameAtIndex(16394);
            (ok, r) = address(OP_GEN2).call(abi.encodeCall(IASR.setAnchorState, (gop)));
            _log("P1 OP gen2 0x1c68.setAnchorState(game#20094)", ok, r);
            (ok, r) = address(UNI_GEN2).call(abi.encodeCall(IASR.setAnchorState, (guni)));
            _log("P1 UNI gen2 0xD5D0.setAnchorState(game#16394)", ok, r);
        }
        // P2 orphaned gen-0 registries (v2.0.0): the only non-view entry points
        {
            (,, address gop) = OP_DGF.gameAtIndex(20094);
            (ok, r) = OP_GEN0.call(abi.encodeWithSignature("tryUpdateAnchorState()"));
            _log("P2 OP gen0 0x18DA.tryUpdateAnchorState()", ok, r);
            (ok, r) = OP_GEN0.call(abi.encodeWithSignature("setAnchorState(address)", gop));
            _log("P2 OP gen0 0x18DA.setAnchorState(game)", ok, r);
            (ok, r) = UNI_GEN0.call(abi.encodeWithSignature("tryUpdateAnchorState()"));
            _log("P2 UNI gen0 0x318A.tryUpdateAnchorState()", ok, r);
        }
        // P3 live per-chain registries: advance the anchor with the newest claim-valid game, if any
        _advanceLiveAnchor(OP_ASR, OP_DGF, "OP");
        _advanceLiveAnchor(UNI_ASR, UNI_DGF, "UNI");

        // P4 ETH donations / forced ETH into every custody contract that migrate() or its validator reads
        OP_PORTAL.donateETH{ value: 1 ether }();
        UNI_PORTAL.donateETH{ value: 1 ether }();
        portalDonations = 2 ether;
        new Forcer{ value: 1 ether }(payable(OP_LB));
        new Forcer{ value: 1 ether }(payable(UNI_LB));
        forcedIntoLockboxes = 2 ether;
        new Forcer{ value: 1 ether }(payable(OP_L1CDM));
        new Forcer{ value: 1 ether }(payable(UNI_L1CDM));
        new Forcer{ value: 1 ether }(payable(OP_L1SB));
        new Forcer{ value: 1 ether }(payable(UNI_L1SB));
        new Forcer{ value: 1 }(payable(address(OP_ASR)));
        new Forcer{ value: 1 }(payable(address(OP_GEN2)));
        _log("P4 donateETH x2, SELFDESTRUCT-forced ETH into lockboxes/L1CDMs/L1SBs/ASRs", true, "");

        // P5 normal deposits (value locked in the per-chain lockbox before migrate)
        OP_PORTAL.depositTransaction{ value: 1 ether }(attacker, 1 ether, 100_000, false, "");
        UNI_PORTAL.depositTransaction{ value: 1 ether }(attacker, 1 ether, 100_000, false, "");
        portalDeposits = 2 ether;
        _log("P5 depositTransaction 1 ETH on both portals", true, "");

        // P6 every DelayedWETH generation: deposit + self-scoped unlock (all permissionless writers)
        address[11] memory w = _legacyWeths();
        for (uint256 i; i < w.length; i++) {
            (ok, r) = w[i].call{ value: 0.01 ether }(abi.encodeWithSignature("deposit()"));
            _log(string.concat("P6 legacy WETH ", vm.toString(w[i]), ".deposit"), ok, r);
            (ok, r) = w[i].call(abi.encodeWithSignature("unlock(address,uint256)", attacker, 0.01 ether));
            _log(string.concat("P6 legacy WETH ", vm.toString(w[i]), ".unlock(self)"), ok, r);
        }
        IWETH(OP_WETH).deposit{ value: 0.01 ether }();
        IWETH(UNI_WETH).deposit{ value: 0.01 ether }();
        (ok, r) = OP_WETH.call(abi.encodeWithSignature("unlock(address,uint256)", attacker, 0.01 ether));
        _log("P6 OP DelayedWETH (to become SHARED) deposit+unlock(self)", ok, r);

        // P7 in-flight wrong-root type-9 games on both per-chain factories, created in the migration block
        {
            (bytes32 root, bytes memory extra) = _newSuperProposal(OP_DGF, 1);
            opAtkGame = OP_DGF.create{ value: OP_DGF.initBonds(9) }(9, root, extra);
            (root, extra) = _newSuperProposal(UNI_DGF, 1);
            uniAtkGame = UNI_DGF.create{ value: UNI_DGF.initBonds(9) }(9, root, extra);
            _log(string.concat("P7 wrong-root type-9 games created: OP ", vm.toString(opAtkGame), " UNI ", vm.toString(uniAtkGame)), true, "");
        }
        vm.stopPrank();
    }

    function _advanceLiveAnchor(IASR asr, IDGF dgf, string memory name) internal {
        (, uint256 seq) = asr.getAnchorRoot();
        uint256 n = dgf.gameCount();
        for (uint256 i = n; i > n - 150; i--) {
            (uint32 t,, address g) = dgf.gameAtIndex(i - 1);
            if (t != 9) continue;
            if (IGame(g).l2SequenceNumber() <= seq) break;
            if (!asr.isGameClaimValid(g)) continue;
            (bool ok, bytes memory r) = address(asr).call(abi.encodeCall(IASR.setAnchorState, (g)));
            _log(string.concat("P3 ", name, " live ASR.setAnchorState(game#", vm.toString(i - 1), ")"), ok, r);
            return;
        }
        _log(string.concat("P3 ", name, " live ASR: no claim-valid game newer than the anchor in the last 150"), true, "");
    }

    function _dump(Vm.AccountAccess[] memory d, string memory file) internal {
        string memory path = string.concat(EV, file);
        vm.writeFile(path, "");
        for (uint256 i; i < d.length; i++) {
            vm.writeLine(
                path,
                string.concat(
                    "A ", vm.toString(uint256(d[i].kind)), " ", vm.toString(d[i].account), " from ", vm.toString(d[i].accessor),
                    " value ", vm.toString(d[i].value), " bal ", vm.toString(d[i].oldBalance), "->", vm.toString(d[i].newBalance),
                    d[i].reverted ? " REVERTED" : ""
                )
            );
            for (uint256 j; j < d[i].storageAccesses.length; j++) {
                Vm.StorageAccess memory s = d[i].storageAccesses[j];
                vm.writeLine(
                    path,
                    string.concat(
                        s.isWrite ? "  W " : "  R ", vm.toString(s.account), " ", vm.toString(s.slot), " ",
                        vm.toString(s.previousValue), " -> ", vm.toString(s.newValue), s.reverted ? " REVERTED" : ""
                    )
                );
            }
        }
    }

    function _recordedMigrate(string memory file) internal returns (Outcome memory o) {
        vm.startStateDiffRecording();
        _migrate();
        Vm.AccountAccess[] memory d = vm.stopAndReturnStateDiff();
        _dump(d, file);
        o = _outcome();
    }

    /// E-01/E-02/E-03: poison everything, migrate, compare with a clean migrate at the same timestamp.
    function test_E01_poison_then_migrate_vs_clean() public {
        uint256 preLb = OP_LB.balance + UNI_LB.balance;
        uint256 snap = vm.snapshotState();
        Outcome memory c = _recordedMigrate("migrate-clean.accesses.txt");
        vm.revertToState(snap);

        _poison();
        address opAnchorPre = OP_ASR.anchorGame();
        address uniAnchorPre = UNI_ASR.anchorGame();
        address opGen2Pre = OP_GEN2.anchorGame();
        Outcome memory p = _recordedMigrate("migrate-poisoned.accesses.txt");

        // deployed addresses / starting anchor / respected type / retirement / game config: identical
        assertEq(p.lb, c.lb, "shared lockbox address");
        assertEq(p.asr, c.asr, "shared ASR address");
        assertEq(p.dgf, c.dgf, "shared DGF address");
        assertEq(p.startRoot, c.startRoot);
        assertEq(p.startSeq, c.startSeq);
        assertEq(p.anchorRoot, c.anchorRoot, "shared anchor root");
        assertEq(p.anchorSeq, c.anchorSeq);
        assertEq(p.rgt, c.rgt);
        assertEq(p.retire, c.retire);
        assertEq(p.impl9, c.impl9);
        assertEq(p.args9, c.args9);
        assertEq(p.bond9, c.bond9);
        assertEq(p.opOldStartRoot, c.opOldStartRoot);
        assertEq(p.opOldRetire, c.opOldRetire);
        assertEq(p.opOldLb, c.opOldLb);
        assertEq(p.uniOldLb, c.uniOldLb);
        assertEq(p.uniScWeth, c.uniScWeth);
        assertEq(p.uniWethLb, c.uniWethLb);
        assertTrue(p.authOp && p.authUni && p.authOldOp && p.authOldUni);
        // the attacker-moved legacy anchors are carried through unchanged (rootChanged == false in ASR.initialize)
        assertEq(p.opOldAnchor, opAnchorPre);
        assertEq(p.uniOldAnchor, uniAnchorPre);
        assertEq(OP_GEN2.anchorGame(), opGen2Pre, "gen2 untouched by migrate");
        // pooled solvency: shared lockbox == clean + exactly what the attacker put into portals/lockboxes
        assertEq(c.lbBal, preLb);
        assertEq(p.lbBal, c.lbBal + portalDonations + forcedIntoLockboxes + portalDeposits, "conservation");
        assertEq(address(OP_PORTAL).balance + address(UNI_PORTAL).balance + OP_LB.balance + UNI_LB.balance, 0);

        _writeE01(c, p);
    }

    function _writeE01(Outcome memory c, Outcome memory p) internal {
        string memory out = string.concat(
            "# ATK-E E-01 poison log (unprivileged EOA ", vm.toString(attacker), ", L1 fork 26433900)\n", poisonLog,
            "\nshared lockbox ", vm.toString(p.lb), "\nshared ASR ", vm.toString(p.asr), "\nshared DGF ", vm.toString(p.dgf)
        );
        out = string.concat(
            out, "\nclean migrate gas ", vm.toString(c.gas), "\npoisoned migrate gas ", vm.toString(p.gas),
            "\nEIP-7825 cap 16777216", "\nshared lockbox clean ", vm.toString(c.lbBal), " poisoned ", vm.toString(p.lbBal)
        );
        out = string.concat(
            out, "\nold OP ASR anchorGame (poisoned, carried) ", vm.toString(p.opOldAnchor), " clean ", vm.toString(c.opOldAnchor),
            "\nold UNI ASR anchorGame (poisoned, carried) ", vm.toString(p.uniOldAnchor), " clean ", vm.toString(c.uniOldAnchor)
        );
        out = string.concat(out, "\nOP gen2 anchorGame after ", vm.toString(OP_GEN2.anchorGame()), "\n");
        console.log(out);
        vm.writeFile(string.concat(EV, "E01-poison-vs-clean.txt"), out);
    }

    /// E-04..E-07: post-migration behaviour of the poisoned objects.
    function test_E04_postMigration_poisoned_objects_inert() public {
        _poison();
        _migrate();
        string memory out = "# ATK-E E-04 post-migration reads of attacker-created/moved objects\n";

        // attacker's in-flight legacy games: not in the shared domain, still proper in the legacy domain
        assertFalse(sharedASR.isGameRegistered(opAtkGame));
        assertFalse(sharedASR.isGameClaimValid(opAtkGame));
        assertFalse(sharedASR.isGameRegistered(uniAtkGame));
        assertTrue(OP_ASR.isGameProper(opAtkGame), "legacy game proper in legacy ASR");
        assertEq(OP_DGF.gameImpls(9), address(0), "legacy DGF cleared");
        out = string.concat(out, "shared.isGameRegistered(opAtkGame)=false shared.isGameClaimValid=false oldASR.isGameProper=true oldDGF.impl(9)=0\n");

        // no new game can be created on the legacy factories
        vm.startPrank(attacker, attacker);
        (bytes32 root, bytes memory extra) = _newSuperProposal(OP_DGF, 2);
        (bool ok, bytes memory r) = address(OP_DGF).call{ value: 0.08 ether }(abi.encodeCall(IDGF.create, (9, root, extra)));
        assertFalse(ok);
        out = string.concat(out, "legacy OP DGF.create(9) after migrate: ", _res(ok, r), "\n");

        // a fresh shared-DGF game (attacker proposal after the starting anchor)
        vm.warp(block.timestamp + 60);
        bytes memory sx = abi.encodePacked(uint8(1), uint64(block.timestamp - 30), uint256(10), keccak256("op"), uint256(130), keccak256("uni"));
        address sg = sharedDGF.create{ value: 0.08 ether }(9, keccak256(sx), sx);
        vm.stopPrank();
        out = string.concat(out, "shared game created by attacker ", vm.toString(sg), "\n");
        assertTrue(sharedASR.isGameRegistered(sg));
        // legacy registries never accept a shared-domain game, so nothing can bridge the two domains
        assertFalse(OP_ASR.isGameRegistered(sg));
        assertFalse(OP_ASR.isGameClaimValid(sg));
        (ok, r) = address(OP_GEN2).staticcall(abi.encodeCall(IASR.isGameClaimValid, (sg)));
        out = string.concat(out, "gen2.isGameClaimValid(sharedGame): ", _res(ok, r), ok ? (abi.decode(r, (bool)) ? " true" : " false") : "", "\n");
        if (ok) assertFalse(abi.decode(r, (bool)));
        vm.prank(attacker, attacker);
        (ok, r) = address(OP_ASR).call(abi.encodeCall(IASR.setAnchorState, (sg)));
        assertFalse(ok);
        out = string.concat(out, "oldASR.setAnchorState(sharedGame): ", _res(ok, r), "\n");

        // gen2 still mirrors portal getters, which now read the SHARED registry
        out = string.concat(
            out, "portal.respectedGameType() (mirrors shared ASR) ", vm.toString(OP_PORTAL.respectedGameType()),
            " respectedGameTypeUpdatedAt ", vm.toString(OP_PORTAL.respectedGameTypeUpdatedAt()), "\n"
        );
        (,, address g20094) = OP_DGF.gameAtIndex(20094);
        (ok, r) = address(OP_GEN2).staticcall(abi.encodeCall(IASR.isGameClaimValid, (g20094)));
        out = string.concat(out, "gen2.isGameClaimValid(game#20094) after migrate: ", _res(ok, r), ok ? (abi.decode(r, (bool)) ? " true" : " false") : "", "\n");
        (ok, r) = address(OP_GEN2).staticcall(abi.encodeWithSignature("getAnchorRoot()"));
        out = string.concat(out, "gen2.getAnchorRoot() after migrate: ", _res(ok, r), "\n");

        // pause routing of every attacker-touched legacy object now resolves through the shared lockbox
        assertEq(OP_ASR.ethLockbox(), sharedLB);
        assertEq(UNI_ASR.ethLockbox(), sharedLB);
        assertEq(IWETH(UNI_WETH).ethLockbox(), sharedLB);
        assertEq(IWETH(OP_WETH).ethLockbox(), sharedLB);
        out = string.concat(out, "old ASRs + both DelayedWETHs ethLockbox == shared lockbox\n");
        console.log(out);
        vm.writeFile(string.concat(EV, "E04-post-migration.txt"), out);
    }

    /// E-08: hidden pre-positioning at the shared proxies' CREATE2 addresses (attacker pre-funds them).
    ///       Same block => the addresses of the clean run are the addresses the honest migrate will use.
    function test_E08_prefund_predicted_shared_addresses() public {
        uint256 snap = vm.snapshotState();
        _migrate();
        address lb = sharedLB;
        address asr = address(sharedASR);
        address dgf = address(sharedDGF);
        uint256 cleanBal = lb.balance;
        vm.revertToState(snap);
        assertEq(lb.code.length, 0);
        vm.startPrank(attacker, attacker);
        new Forcer{ value: 5 ether }(payable(lb));
        new Forcer{ value: 1 ether }(payable(asr));
        new Forcer{ value: 1 ether }(payable(dgf));
        vm.stopPrank();
        (bool ok, bytes memory r) = _tryMigrate(_scs());
        assertTrue(ok, string(r));
        assertEq(sharedLB, lb);
        assertEq(address(sharedASR), asr);
        assertEq(address(sharedDGF), dgf);
        assertEq(lb.balance, cleanBal + 5 ether, "pre-funded ETH becomes lockbox surplus");
        string memory out = string.concat(
            "# ATK-E E-08 pre-funded predicted CREATE2 addresses\nlockbox ", vm.toString(lb), " +5 ETH, asr +1, dgf +1\nmigrate: OK, same addresses; lockbox balance ",
            vm.toString(lb.balance), " (clean ", vm.toString(cleanBal), ")\n"
        );
        console.log(out);
        vm.writeFile(string.concat(EV, "E08-prefund-create2.txt"), out);
    }

    /// E-09/E-10: partial failure then retry, and a repeated migrate after poisoning.
    function test_E09_failed_then_retry_and_repeat() public {
        uint256 snap = vm.snapshotState();
        _migrate();
        Outcome memory c = _outcome();
        vm.revertToState(snap);

        _poison();
        // a failed first attempt (non-ascending chain ids) leaves no partial state
        address[] memory bad = new address[](2);
        bad[0] = address(UNI_SC);
        bad[1] = address(OP_SC);
        (bool ok, bytes memory r) = _tryMigrate(bad);
        assertFalse(ok);
        string memory out = string.concat("# ATK-E E-09/E-10\nfirst attempt [UNI,OP]: ", _res(ok, r), "\n");
        assertEq(OP_PORTAL.ethLockbox(), OP_LB);
        assertFalse(OP_SC.isFeatureEnabled("INTEROP"));
        _migrate();
        Outcome memory p = _outcome();
        assertEq(p.lb, c.lb);
        assertEq(p.asr, c.asr);
        assertEq(p.dgf, c.dgf);
        assertEq(p.anchorRoot, c.anchorRoot);
        out = string.concat(out, "retry [OP,UNI]: OK, addresses identical to clean run\n");
        (ok, r) = _tryMigrate(_scs());
        assertFalse(ok);
        assertEq(_sel(r), bytes4(keccak256("OPContractsManagerMigrator_ChainAlreadyMigrated()")));
        out = string.concat(out, "repeat migrate: ", _res(ok, r), " (ChainAlreadyMigrated)\n");
        // repeat with only Unichain (subset re-migration) is also refused
        address[] memory one = new address[](1);
        one[0] = address(UNI_SC);
        (ok, r) = _tryMigrate(one);
        assertFalse(ok);
        out = string.concat(out, "repeat [UNI] only: ", _res(ok, r), "\n");
        console.log(out);
        vm.writeFile(string.concat(EV, "E09-retry-repeat.txt"), out);
    }
}
