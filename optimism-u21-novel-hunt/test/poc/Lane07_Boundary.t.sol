// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";
interface IDGF3 { function gameAtIndex(uint256) external view returns (uint32, uint64, address); function gameCount() external view returns (uint256); }
interface IG3 { function anchorStateRegistry() external view returns (address); function wasRespectedGameTypeWhenCreated() external view returns (bool); function status() external view returns (uint8); function version() external view returns (string memory); }
interface IASR3 { function retirementTimestamp() external view returns (uint64); function disputeGameFactory() external view returns (address); function isGameClaimValid(address) external view returns (bool); }
contract BoundaryTest is Test {
    function _check(IASR3 asr, uint256 lo0, uint256 hi0, uint256 nAfter, uint256 nSpread) internal {
        IDGF3 dgf = IDGF3(asr.disputeGameFactory());
        uint64 ret = asr.retirementTimestamp();
        uint256 lo = lo0; uint256 hi = hi0; // invariant: ts(lo) <= ret < ts(hi)
        while (hi - lo > 1) { uint256 mid = (lo + hi) / 2; (, uint64 ts,) = dgf.gameAtIndex(mid); if (ts <= ret) lo = mid; else hi = mid; }
        console.log("first non-retired index", hi, "of", dgf.gameCount());
        uint256 bad;
        for (uint256 i = hi; i < hi + nAfter; i++) bad += _one(asr, dgf, i);
        uint256 cnt = dgf.gameCount();
        for (uint256 k = 1; k <= nSpread; k++) bad += _one(asr, dgf, hi + (cnt - 1 - hi) * k / nSpread);
        console.log("games bound to a different ASR:", bad);
        assertEq(bad, 0);
    }
    function _one(IASR3 asr, IDGF3 dgf, uint256 i) internal view returns (uint256 bad) {
        (uint32 t, uint64 ts, address g) = dgf.gameAtIndex(i);
        address a = IG3(g).anchorStateRegistry();
        if (a != address(asr)) { bad = 1; console.log("FOREIGN ASR idx/type", i, t); console.log("   ", g, a); console.log("   respected/valid", IG3(g).wasRespectedGameTypeWhenCreated(), asr.isGameClaimValid(g)); }
        else console.log("ok idx/type/ts", i, t, ts);
    }
    function test_boundary_op() public { vm.createSelectFork("l1"); _check(IASR3(0x23B2C62946350F4246f9f9D027e071f0264FD113), 8000, 10000, 6, 12); }
    function test_boundary_uni() public { vm.createSelectFork("l1"); _check(IASR3(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9), 0, 17690, 6, 12); }
}
