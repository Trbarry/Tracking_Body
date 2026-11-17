// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";
interface IDGF2 { function gameAtIndex(uint256) external view returns (uint32, uint64, address); function gameCount() external view returns (uint256); }
interface IG2 { function gameCreator() external view returns (address); function status() external view returns (uint8); function claimDataLen() external view returns (uint256); function absolutePrestate() external view returns (bytes32); function wasRespectedGameTypeWhenCreated() external view returns (bool); function l2SequenceNumber() external view returns (uint256); }
contract Scan2Test is Test {
    function test_scan2() public {
        vm.createSelectFork("l1");
        IDGF2 dgf = IDGF2(vm.envAddress("DGF"));
        uint256 from = vm.envUint("FROM"); uint256 to = dgf.gameCount();
        address p1 = 0x473300df21D047806A082244b417f96b32f13A33; address p2 = 0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0;
        uint256[3] memory st; uint256 challenged; uint256 nonProposer;
        bytes32 lastPre;
        for (uint256 i = from; i < to; i++) {
            (uint32 t, uint64 ts, address g) = dgf.gameAtIndex(i);
            IG2 game = IG2(g);
            uint8 s = game.status(); st[s]++;
            address c = game.gameCreator();
            uint256 n = game.claimDataLen();
            bytes32 pre = game.absolutePrestate();
            if (pre != lastPre) { console.log("prestate change at idx", i, ts); console.logBytes32(pre); lastPre = pre; }
            if (c != p1 && c != p2) { nonProposer++; console.log("NON-PROPOSER idx/type/status", i, t, s); console.log("   creator", c, g); }
            if (n > 1) { challenged++; console.log("CHALLENGED idx/claims/status", i, n, s); }
            if (s == 1) console.log("CHALLENGER_WINS idx", i, g);
            if (!game.wasRespectedGameTypeWhenCreated()) console.log("NOT RESPECTED idx", i, t);
        }
        console.log("status counts inprogress/challengerwins/defenderwins", st[0], st[1], st[2]);
        console.log("challenged", challenged, "nonProposer", nonProposer);
    }
}
