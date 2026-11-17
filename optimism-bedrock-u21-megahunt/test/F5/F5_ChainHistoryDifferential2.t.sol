// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// F5 — chain-history differential, part 2 (L1 fork @ 26433900, real deployed bytecode, unprivileged EOA only).
//  (a) current factory configuration of every game type 0..10 binds to the portal's CURRENT registry (all 4 chains)
//  (b) the two invalid in-progress super-root games found by the root census (Ink #2638, Unichain #17586) are inert:
//      not claim-valid, not provable, not anchorable, not resolvable now
//  (c) same permissionless call against each chain's ORPHANED generation-2 registry (v2.2.2):
//      setAnchorState(<current anchor game of the live registry>) — divergent pre-state (Soneium anchorGame == 0)

interface IDGF {
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
}

interface IASR {
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
    function setAnchorState(address) external;
}

interface IGame {
    function anchorStateRegistry() external view returns (address);
    function status() external view returns (uint8);
    function resolve() external returns (uint8);
    function createdAt() external view returns (uint64);
}

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

interface IPortal {
    function proveWithdrawalTransaction(WithdrawalTransaction memory, uint256, OutputRootProof calldata, bytes[] calldata) external;
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
}

contract F5_ChainHistoryDifferential2 is Test {
    address internal attacker = makeAddr("f5-unprivileged-2");

    string[4] internal names = ["OP", "INK", "SONEIUM", "UNICHAIN"];
    address[4] internal portals = [
        0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
        0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
        0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
        0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2
    ];
    // generation-2 (v2.2.2) registries, orphaned at U16 (evidence/F5/<CHAIN>-stage2.json)
    address[4] internal gen2 = [
        0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b,
        0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d,
        0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1,
        0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
    ];

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
    }

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }

    function _argsRegistry(bytes memory a) internal pure returns (address r) {
        // 124/164-byte args: prestate(32) vm(20) asr(20) weth(20) l2ChainId(32) [proposer challenger]; 40-byte: asr(20) proposer(20)
        uint256 off = a.length == 40 ? 0 : 52;
        assembly {
            r := shr(96, mload(add(add(a, 32), off)))
        }
    }

    function test_a_current_factory_config_bound_to_current_registry() public view {
        for (uint256 i = 0; i < 4; i++) {
            IPortal p = IPortal(portals[i]);
            IDGF dgf = IDGF(p.disputeGameFactory());
            address asr = p.anchorStateRegistry();
            uint256 live;
            for (uint32 t = 0; t <= 10; t++) {
                address impl = dgf.gameImpls(t);
                if (impl == address(0)) continue;
                live++;
                bytes memory a = dgf.gameArgs(t);
                assertTrue(a.length == 40 || a.length == 124 || a.length == 164, "args-based impl expected for every live type");
                assertEq(_argsRegistry(a), asr, "gameArgs registry != portal registry");
                console.log(names[i], "type", uint256(t));
                console.log("   impl", impl, "argsLen", a.length);
            }
            assertGt(live, 0);
            address anchor = IASR(asr).anchorGame();
            assertEq(IGame(anchor).anchorStateRegistry(), asr, "anchor game bound to current registry");
        }
    }

    function test_b_invalid_inprogress_super_games_inert() public {
        _inert(1, 2638);
        _inert(3, 17586);
    }

    function _inert(uint256 ci, uint256 idx) internal {
        IPortal p = IPortal(portals[ci]);
        IASR asr = IASR(p.anchorStateRegistry());
        (,, address g) = IDGF(p.disputeGameFactory()).gameAtIndex(idx);
        assertEq(IGame(g).status(), 0, "IN_PROGRESS");
        assertFalse(asr.isGameClaimValid(g));
        assertEq(IGame(g).anchorStateRegistry(), address(asr));
        console.log(names[ci], "game", idx, g);
        vm.prank(attacker, attacker);
        (bool ok, bytes memory r) = g.call(abi.encodeCall(IGame.resolve, ()));
        assertFalse(ok, "resolve must revert");
        console.logBytes4(_sel(r));
        vm.prank(attacker, attacker);
        (ok, r) = address(asr).call(abi.encodeCall(IASR.setAnchorState, (g)));
        assertFalse(ok, "anchor must not move");
        console.logBytes4(_sel(r));
        _proveInert(p, idx);
    }

    function _proveInert(IPortal p, uint256 idx) internal {
        WithdrawalTransaction memory wd = WithdrawalTransaction(1 << 240, attacker, attacker, 1 ether, 100000, "");
        OutputRootProof memory orp = OutputRootProof(bytes32(0), bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)));
        vm.prank(attacker, attacker);
        (bool ok, bytes memory r) = address(p).call(abi.encodeCall(IPortal.proveWithdrawalTransaction, (wd, idx, orp, new bytes[](0))));
        assertFalse(ok, "prove must revert");
        console.logBytes4(_sel(r));
    }

    function test_c_orphaned_gen2_registry_setAnchorState_differential() public {
        string memory out = "chain | gen2 anchor before | live anchor game | setAnchorState(live anchor) on gen2 | gen2 anchor after\n";
        for (uint256 i = 0; i < 4; i++) {
            uint256 snap = vm.snapshotState();
            IASR live = IASR(IPortal(portals[i]).anchorStateRegistry());
            address g = live.anchorGame();
            IASR old = IASR(gen2[i]);
            address before = old.anchorGame();
            vm.prank(attacker, attacker);
            (bool ok, bytes memory ret) = address(old).call(abi.encodeCall(IASR.setAnchorState, (g)));
            address afterA = old.anchorGame();
            out = string.concat(
                out, names[i], " | ", vm.toString(before), " | ", vm.toString(g), " | ",
                ok ? "OK" : vm.toString(abi.encodePacked(_sel(ret))), " | ", vm.toString(afterA), "\n"
            );
            // the live registry is never affected by a call on the orphaned one
            assertEq(live.anchorGame(), g);
            vm.revertToState(snap);
        }
        console.log(out);
        vm.writeFile("F5-differential2-output.txt", out);
    }

    // (d) same as (c) but with the latest claim-valid LEGACY (block-number domain) game of the live registry,
    //     which has l2BlockNumber(): the orphaned v2.2.2 registry accepts it permissionlessly.
    function test_d_orphaned_gen2_registry_accepts_current_legacy_game() public {
        uint256[4] memory legacyValid = [uint256(20094), 2521, 7954, 16394];
        string memory out = "chain | gen2 anchor before | candidate (live-registry game) | gen2.isGameClaimValid | setAnchorState on gen2 | gen2 anchor after | live anchor unchanged\n";
        for (uint256 i = 0; i < 4; i++) {
            uint256 snap = vm.snapshotState();
            IPortal p = IPortal(portals[i]);
            IASR live = IASR(p.anchorStateRegistry());
            address liveAnchor = live.anchorGame();
            (,, address g) = IDGF(p.disputeGameFactory()).gameAtIndex(legacyValid[i]);
            assertEq(IGame(g).anchorStateRegistry(), address(live), "candidate belongs to the LIVE registry");
            IASR old = IASR(gen2[i]);
            address before = old.anchorGame();
            bool cv = old.isGameClaimValid(g);
            vm.prank(attacker, attacker);
            (bool ok, bytes memory ret) = address(old).call(abi.encodeCall(IASR.setAnchorState, (g)));
            out = string.concat(out, names[i], " | ", vm.toString(before), " | ", vm.toString(g), " | ", cv ? "true" : "false", " | ");
            out = string.concat(out, ok ? "OK" : vm.toString(abi.encodePacked(_sel(ret))), " | ", vm.toString(old.anchorGame()), " | ", live.anchorGame() == liveAnchor ? "yes" : "NO", "\n");
            assertEq(live.anchorGame(), liveAnchor);
            vm.revertToState(snap);
        }
        console.log(out);
        vm.writeFile("F5-differential3-output.txt", out);
    }
}
