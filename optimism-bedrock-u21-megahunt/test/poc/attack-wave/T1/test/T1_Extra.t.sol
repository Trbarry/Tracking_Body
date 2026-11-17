// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./T1Base.sol";

interface IFDG {
    function attack(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) external payable;
    function getRequiredBond(uint128 _position) external view returns (uint256);
}

interface IDWETH {
    function withdraw(address, uint256) external;
    function unlock(address, uint256) external;
    function delay() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function recover(uint256) external;
    function hold(address, uint256) external;
}

/// Targets 6 (row 12), 14 (rows 31/33), 15 (rows 18/19).
contract T1_Extra is T1Base {
    address challenger = makeAddr("t1-honest-challenger");
    address[] wethGen;
    address[] wethGame;

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        _load();
        wethGen.push(0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14); wethGame.push(0xA019Ec50dFd0cA20f92912342891138B07A24633); // op
        wethGen.push(0x9F9b897e37de5052cD70Db6D08474550DDb07f39); wethGame.push(0xbF09413f717C4DdFCF25decc07F03F3e356bFc96); // op
        wethGen.push(0x82511d494B5C942BE57498a70Fdd7184Ee33B975); wethGame.push(0x12DB9d3Fc16689a1AF1076620a8d9607768A207d); // op
        wethGen.push(0x323dFC63c9B83CB83f40325AaB74b245937cbdF0); wethGame.push(0x49d5c9D4eAa88190f7874c9F163359fED7f2Bd8E); // op
        wethGen.push(0xe214879aD573693A4C49f7654449Caa455cdE34f); wethGame.push(0x5812F56173A63B83664077c5210b55D6195411bd); // op
        wethGen.push(0xD061AB95069987868768818cc1248705351e2D0e); wethGame.push(0xd7d6d510139FbBdeBb337aB485235b4348D5c01f); // op
        wethGen.push(0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162); wethGame.push(0x303E84F2fb4bD67dc58509D443B88639dfA2E2Ef); // op
        wethGen.push(0x14773a8040Ff22e3DcBb0C83eC8e33Be7D920D38); wethGame.push(0xb74D0E450f8D5321424D8d3fE965daf8C754409B); // ink
        wethGen.push(0x3Beaca17eaE5643FB1479AA5f4B1fF75cc4b9B50); wethGame.push(0x98971e7492269dF7855320Fd26189F5CAE8668A5); // ink
        wethGen.push(0xf6b1554F483C391414d3830927E3600c105AaE6E); wethGame.push(0xef2f898eDcEEa268BfE1318058F22B6BccA0E592); // ink
        wethGen.push(0x3F7b07A5D638024a37A776FA228fE90b317aF6dE); wethGame.push(0x0C358B2245f0b7599e1B74B2192229c277fe091C); // ink
        wethGen.push(0x6Cbd14DA021e39A7895Ae151Ac72eCc9023e87F6); wethGame.push(0x474e7d8f0E317b64470BFd87E72dDF39E37f4583); // ink
        wethGen.push(0x57b4C29DAee99a28E6E86778b499361294c134eA); wethGame.push(0x57C4c7C6aF6300e00FdD3103Bc18115B38733D8f); // ink
        wethGen.push(0x9AEA1FD851b63d57Ba4Fc556B0e0c170126C9EAf); wethGame.push(0xC0d3F7906D20C5EC24cF0C8b06D15C09b3059945); // soneium
        wethGen.push(0x372dC0B87b790D6e1308CF9e7f73F0F1fcbD3754); wethGame.push(0xD7FD0514ceb8715F2dE0DA17310a85E1eB5B3EAD); // soneium
        wethGen.push(0x70277624cdE90492231Eb23309e1251Beb18Dff5); wethGame.push(0x90aeE9117Ae4e582Af81300E186B7CB569F51e7B); // soneium
        wethGen.push(0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47); wethGame.push(0x1907C1Ebea09cC4437384Fdeb8F2a859489D0bB8); // soneium
        wethGen.push(0x7d8Ea656D7417229f420b0c87f6428baA8499d70); wethGame.push(0xfade630e108b18F42EE64de59386cA5b31706c9d); // unichain
        wethGen.push(0x84B268A4101A8c8e3CcB33004F81eD08202bA124); wethGame.push(0xdBfa31F8e37E8162c71e3c2399baC8FF86E716c6); // unichain
        wethGen.push(0xc9edb4E340f4E9683B4557bD9db8f9d932177C86); wethGame.push(0xc606a7B21ADaE5512Ee87E3B7e98aEDA6D85d97e); // unichain
        wethGen.push(0xa0157F0730Dea8d1a5c358Dc1d340a05D8796C23); wethGame.push(0x0D0FBD406E8B153501b5B53FafD4F47e2bbf8f81); // unichain
        wethGen.push(0x0bdbEc6bd35571F97f96f3ed21822a4f2e071A3c); wethGame.push(0x0505f0003438e4acDdaBF81F601E21fb134841c7); // unichain
        wethGen.push(0x74ad145aC900F1DD5551F0C9E143314DC4022FCf); wethGame.push(0x05a0B592693CBf342CE5aF773a55883Ca4056475); // unichain
    }

    /// T1-11 (target 6): the anchor sanity check (challengeRootL2Block) exists on neither live game type; an
    /// attacker super game with the maximal sequence number is creatable, and the standard counter keeps the anchor.
    function test_T1_11_farFutureSuperGameNoBlockCheck() public {
        for (uint256 i; i < 4; i++) {
            address anc = IASR(asr[i]).anchorGame();
            (bool ok, bytes memory rd) = anc.call(abi.encodeWithSignature("challengeRootL2Block((bytes32,bytes32,bytes32,bytes32),bytes)", ORP(0, 0, 0, 0), hex""));
            assertFalse(ok);
            assertEq(rd.length, 0, "no such function on the live game type (fallback revert, empty data)");
        }
        IASR A = IASR(asr[0]);
        IDGF F = IDGF(dgf[0]);
        address anchorBefore = A.anchorGame();
        bytes memory extra = _superProof(type(uint64).max, 10, keccak256("t1-11"));
        uint256 bond = F.initBonds(9);
        vm.deal(attacker, bond);
        vm.prank(attacker, attacker);
        IGame g = IGame(F.create{ value: bond }(9, keccak256(extra), extra));
        assertEq(g.l2SequenceNumber(), type(uint64).max);
        console.log("attacker type-9 game with l2SequenceNumber 2^64-1 created", address(g));
        // unprivileged honest challenger counters the root
        uint256 b = IFDG(address(g)).getRequiredBond(2);
        vm.deal(challenger, b);
        vm.prank(challenger, challenger);
        IFDG(address(g)).attack{ value: b }(g.rootClaim(), 0, keccak256("honest"));
        vm.warp(block.timestamp + uint256(g.maxClockDuration()) + 1);
        g.resolveClaim(1, 0);
        g.resolveClaim(0, 0);
        assertEq(g.resolve(), 1, "CHALLENGER_WINS");
        vm.warp(block.timestamp + A.disputeGameFinalityDelaySeconds() + 1);
        vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_InvalidAnchorGame()")));
        A.setAnchorState(address(g));
        g.closeGame();
        assertEq(A.anchorGame(), anchorBefore, "anchor unchanged");
    }

    /// T1-12 (target 15): every DelayedWETH generation that games of the four chains ever used. An unprivileged
    /// attacker cannot move WETH/ETH out of any of them (sub-account + balance + owner gates).
    function test_T1_12_delayedWethGenerations() public {
        uint256 total;
        for (uint256 k; k < wethGen.length; k++) {
            address w = wethGen[k];
            uint256 bal = w.balance;
            total += bal;
            uint256 amt = bal == 0 ? 1 : bal;
            uint256 snap = vm.snapshotState();
            vm.startPrank(attacker, attacker);
            (bool a1,) = w.call(abi.encodeCall(IDWETH.withdraw, (attacker, amt)));
            (bool a2,) = w.call(abi.encodeCall(IDWETH.unlock, (attacker, amt)));
            vm.warp(block.timestamp + IDWETH(w).delay() + 1);
            (bool a3,) = w.call(abi.encodeCall(IDWETH.withdraw, (attacker, amt)));
            (bool a4,) = w.call(abi.encodeCall(IDWETH.withdraw, (wethGame[k], amt)));
            (bool a5,) = w.call(abi.encodeCall(IDWETH.transferFrom, (wethGame[k], attacker, 1)));
            (bool a6,) = w.call(abi.encodeCall(IDWETH.recover, (amt)));
            (bool a7,) = w.call(abi.encodeCall(IDWETH.hold, (wethGame[k], 1)));
            vm.stopPrank();
            assertFalse(a1 || a3 || a4 || a5 || a6 || a7, "extraction path open");
            assertTrue(a2, "unlock is permissionless but only books the caller's own sub-account");
            assertEq(w.balance, bal, "ETH unchanged");
            assertEq(attacker.balance, 0);
            vm.revertToState(snap);
            console.log(w, bal);
        }
        console.log("total ETH across DelayedWETH generations", total);
    }

    /// T1-13 (target 14): which absolute prestates and VMs the live type-9 implementation args use, and how many
    /// in-progress games of each chain still carry the pre-U21 prestate (judged by the old kona program).
    function test_T1_13_prestateGenerations() public view {
        uint256[3] memory ix = [uint256(0), 1, 3];
        for (uint256 q; q < 3; q++) {
            uint256 i = ix[q];
            IDGF F = IDGF(dgf[i]);
            bytes memory args = F.gameArgs(9);
            bytes32 pre;
            address vmAddr;
            assembly {
                pre := mload(add(args, 32))
                vmAddr := shr(96, mload(add(args, 64)))
            }
            uint256 n = F.gameCount();
            uint256 oldOpen;
            uint256 newOpen;
            for (uint256 k = n > 120 ? n - 120 : 0; k < n; k++) {
                (uint32 t,, address g) = F.gameAtIndex(k);
                if (t != 9 || IGame(g).status() != 0) continue;
                if (IGame(g).absolutePrestate() == pre) newOpen++;
                else oldOpen++;
            }
            console.log(names[i], "type-9 vm", vmAddr);
            console.logBytes32(pre);
            console.log("   in-progress games (last 120): old prestate / new prestate", oldOpen, newOpen);
        }
    }
}
