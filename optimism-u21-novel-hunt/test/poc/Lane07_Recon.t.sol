// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";

interface ISC {
    function l2ChainId() external view returns (uint256);
    function optimismPortal() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function delayedWETH() external view returns (address);
    function proxyAdmin() external view returns (address);
    function superchainConfig() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function lastUsedOPCM() external view returns (address);
    function lastUsedOPCMVersion() external view returns (string memory);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
}
interface IPortal {
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
    function version() external view returns (string memory);
    function disputeGameFactory() external view returns (address);
}
interface IASR {
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function version() external view returns (string memory);
}
interface IDGF {
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
    function initBonds(uint32) external view returns (uint256);
    function gameCount() external view returns (uint256);
    function owner() external view returns (address);
    function version() external view returns (string memory);
}
interface IPA { function owner() external view returns (address); }

contract ReconTest is Test {
    function test_recon() public {
        vm.createSelectFork("l1");
        address[4] memory scs = [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6];
        for (uint256 i; i < 4; i++) {
            ISC sc = ISC(scs[i]);
            console.log("=== chain", sc.l2ChainId(), sc.version());
            IPortal p = IPortal(sc.optimismPortal());
            IASR asr = IASR(p.anchorStateRegistry());
            IDGF dgf = IDGF(asr.disputeGameFactory());
            console.log("portal", address(p), p.version());
            console.log("asr", address(asr), asr.version());
            console.log("dgf", address(dgf), "scDGF", sc.disputeGameFactory());
            console.log("dgf owner", dgf.owner(), "count", dgf.gameCount());
            console.log("lockbox portal/asr", p.ethLockbox(), asr.ethLockbox());
            console.log("weth", sc.delayedWETH());
            console.log("proxyAdmin", sc.proxyAdmin(), "owner", IPA(sc.proxyAdmin()).owner());
            console.log("superchainConfig", sc.superchainConfig());
            console.log("opcm", sc.lastUsedOPCM(), sc.lastUsedOPCMVersion());
            console.log("respected", asr.respectedGameType(), "retirement", asr.retirementTimestamp());
            (bytes32 r, uint256 s) = asr.getAnchorRoot();
            console.log("anchorGame", asr.anchorGame(), "seq", s);
            console.logBytes32(r);
            uint32[8] memory ts = [uint32(0), 1, 4, 5, 6, 8, 9, 10];
            for (uint256 j; j < ts.length; j++) {
                address impl = dgf.gameImpls(ts[j]);
                if (impl == address(0)) continue;
                console.log("  type", ts[j], impl, dgf.initBonds(ts[j]));
                console.logBytes(dgf.gameArgs(ts[j]));
            }
        }
    }
}
