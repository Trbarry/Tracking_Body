// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./T1Base.sol";

/// Rows 1, 2, 11/13, 21/22 of audit/FIX-CLOSURE-MATRIX.md section B (targets 1, 2, 11, 13).
contract T1_Registry is T1Base {
    uint32[] probeTypes;

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        _load();
        // every type ever configured on any of the four factories (ImplementationSet / ArgsSet / InitBondUpdated
        // full-history scan, evidence/attack-wave/T1/dgf-config-events.json) plus a probe band.
        for (uint32 t = 0; t <= 16; t++) probeTypes.push(t);
        probeTypes.push(42);
        probeTypes.push(254);
        probeTypes.push(255);
        probeTypes.push(1337);
        probeTypes.push(type(uint32).max);
    }

    function _contains(bytes memory hay, address needle) internal pure returns (bool) {
        bytes20 n = bytes20(needle);
        if (hay.length < 20) return false;
        for (uint256 i; i + 20 <= hay.length; i++) {
            bytes20 w;
            assembly {
                w := mload(add(add(hay, 32), i))
            }
            if (w == n) return true;
        }
        return false;
    }

    /// T1-01 (target 1, mutations a/b/c; target 13 l2ChainId binding).
    function test_T1_01_registeredTypesBoundToPortalRegistry() public {
        address[4] memory created;
        for (uint256 i; i < 4; i++) {
            IPortal p = IPortal(portal[i]);
            IASR A = IASR(p.anchorStateRegistry());
            assertEq(address(A), asr[i], "portal ASR");
            IDGF F = IDGF(A.disputeGameFactory());
            assertEq(address(F), p.disputeGameFactory(), "portal DGF == ASR DGF");
            assertEq(address(F), dgf[i], "DGF");
            assertEq(ISysCfg(p.systemConfig()).disputeGameFactory(), address(F), "SystemConfig DGF");
            assertEq(ISysCfg(p.systemConfig()).l2ChainId(), chainIds[i], "SystemConfig.l2ChainId binding");
            uint32 resp = A.respectedGameType();
            console.log("== chain", names[i], "respected type", resp);

            for (uint256 k; k < probeTypes.length; k++) {
                uint32 t = probeTypes[k];
                address impl = F.gameImpls(t);
                if (impl == address(0)) continue;
                bytes memory args = F.gameArgs(t);
                console.log("  type", t, impl);
                console.log("    args len", args.length, "bond", F.initBonds(t));
                // the registry named in the args must be the portal's registry and no other chain's/generation's
                assertTrue(_contains(args, address(A)), "args name the portal ASR");
                for (uint256 j; j < 4; j++) {
                    if (j != i) assertFalse(_contains(args, asr[j]), "args name a sibling ASR");
                }
                assertFalse(_contains(args, 0x18DAc71c228D1C32c99489B7323d441E1175e443), "gen-0 ASR");
                assertFalse(_contains(args, 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b), "gen-1 ASR");

                // permissionless creation attempt from an unprivileged EOA
                bytes32 junk = keccak256(abi.encode("t1-junk-root", i, t));
                (, uint256 seq) = A.getAnchorRoot();
                bytes memory extra = _superProof(uint64(seq + 3600), chainIds[i], junk);
                bytes32 root = keccak256(extra);
                uint256 bond = F.initBonds(t);
                vm.deal(attacker, bond + 1 ether);
                vm.prank(attacker, attacker);
                (bool ok, bytes memory ret) = address(F).call{ value: bond }(abi.encodeCall(IDGF.create, (t, root, extra)));
                if (!ok) {
                    console.log("    attacker create REVERTS (permissioned)");
                    // the only gated types are the tx.origin-authorised ones; type 9 must be open
                    assertTrue(t != 9, "type 9 must be permissionless");
                    continue;
                }
                IGame g = IGame(abi.decode(ret, (address)));
                created[i] = address(g);
                assertEq(g.anchorStateRegistry(), address(A), "created game bound to portal ASR");
                assertTrue(A.isGameRegistered(address(g)), "registered");
                assertFalse(A.isGameRetired(address(g)), "not retired");
                assertEq(g.wasRespectedGameTypeWhenCreated(), t == resp, "respected snapshot");
                assertFalse(A.isGameClaimValid(address(g)), "fresh game not claim-valid");
                assertEq(g.rootClaimByChainId(chainIds[i]), junk, "per-chain root read with SystemConfig.l2ChainId");
                // the portal's own chain id selects the attacker's entry only on its own chain
                for (uint256 j; j < 4; j++) {
                    if (j == i) continue;
                    (bool ok2,) = address(g).staticcall(abi.encodeCall(IGame.rootClaimByChainId, (chainIds[j])));
                    assertFalse(ok2, "sibling chain id absent -> UnknownChainId");
                }
                console.log("    attacker game", address(g), "ASR bound, respected", g.wasRespectedGameTypeWhenCreated());
            }
        }
        // mutation b/c: a game of one chain's factory presented to another chain's registry (shared impl 0x19af533c)
        for (uint256 i; i < 4; i++) {
            for (uint256 j; j < 4; j++) {
                address anc = IASR(asr[j]).anchorGame();
                assertEq(IASR(asr[i]).isGameRegistered(anc), i == j, "anchor registered only in own registry");
                if (created[j] != address(0)) {
                    assertEq(IASR(asr[i]).isGameRegistered(created[j]), i == j, "attacker game only in own registry");
                }
            }
        }
    }

    /// T1-02 (target 2): the live anchor of each chain is not blacklisted / retired / de-respected / foreign.
    function test_T1_02_anchorGamesClean() public view {
        for (uint256 i; i < 4; i++) {
            IASR A = IASR(asr[i]);
            address anc = A.anchorGame();
            assertTrue(anc != address(0), "anchor game set");
            IGame g = IGame(anc);
            (bytes32 r, uint256 s) = A.getAnchorRoot();
            assertEq(r, g.rootClaim());
            assertEq(s, g.l2SequenceNumber());
            assertTrue(A.isGameClaimValid(anc), "anchor claim-valid");
            assertFalse(A.isGameBlacklisted(anc), "anchor not blacklisted");
            assertFalse(A.isGameRetired(anc), "anchor not retired");
            assertEq(g.gameType(), A.respectedGameType(), "anchor of the respected type");
            assertEq(g.anchorStateRegistry(), address(A), "anchor bound to own registry");
            assertEq(g.status(), 2, "DEFENDER_WINS");
            console.log(names[i], anc, g.gameType());
            console.log("   seq", s, "createdAt", g.createdAt());
        }
    }

    /// T1-03 (targets 11/13): tx.origin-authorised types cannot be created by an attacker contract either,
    /// and the Soneium proposer is a code-less EOA (no EIP-7702 delegation that would let others act as origin).
    function test_T1_03_txOriginTypesClosed() public {
        for (uint256 i; i < 4; i++) {
            IDGF F = IDGF(dgf[i]);
            if (F.gameImpls(5) == address(0)) continue;
            bytes memory args = F.gameArgs(5);
            address proposer;
            assembly {
                proposer := shr(96, mload(add(args, 52)))
            }
            console.log(names[i], "type-5 proposer", proposer, proposer.code.length);
            assertEq(proposer.code.length, 0, "proposer has no code / delegation");
            // attacker contract routes the call; tx.origin is still the attacker
            Relay rl = new Relay();
            (, uint256 seq) = IASR(asr[i]).getAnchorRoot();
            bytes memory extra = _superProof(uint64(seq + 7200), chainIds[i], bytes32(uint256(1)));
            vm.prank(attacker, attacker);
            (bool ok,) = rl.go(address(F), abi.encodeCall(IDGF.create, (5, keccak256(extra), extra)));
            assertFalse(ok, "type 5 create by non-proposer origin reverts");
        }
    }
}

contract Relay {
    function go(address t, bytes memory d) external returns (bool ok, bytes memory r) {
        (ok, r) = t.call(d);
    }
}
