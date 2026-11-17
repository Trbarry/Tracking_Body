// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface ISystemConfigHandles {
    function l2ChainId() external view returns (uint256);
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function optimismPortal() external view returns (address);
    function disputeGameFactory() external view returns (address);
}

interface IPortalHandles {
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
    function proxyAdmin() external view returns (address);
}

struct ChainHandles {
    string name;
    uint256 l2ChainId;
    address systemConfig;
    address portal;
    address messenger;
    address standardBridge;
    address disputeGameFactory;
    address anchorStateRegistry;
    address ethLockbox;
    address proxyAdmin;
}

library MultiChain {
    function all() internal pure returns (ChainHandles[] memory chains) {
        chains = new ChainHandles[](4);
        chains[0] = ChainHandles({
            name: "OP Mainnet",
            l2ChainId: 10,
            systemConfig: 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,
            portal: 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
            messenger: 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            standardBridge: 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
            disputeGameFactory: 0xe5965Ab5962eDc7477C8520243A95517CD252fA9,
            anchorStateRegistry: 0x23B2C62946350F4246f9f9D027e071f0264FD113,
            ethLockbox: 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43,
            proxyAdmin: 0x543bA4AADBAb8f9025686Bd03993043599c6fB04
        });
        chains[1] = ChainHandles({
            name: "Ink",
            l2ChainId: 57_073,
            systemConfig: 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
            portal: 0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
            messenger: 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f,
            standardBridge: 0x88FF1e5b602916615391F55854588EFcBB7663f0,
            disputeGameFactory: 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD,
            anchorStateRegistry: 0xEe018bAf058227872540AC60eFbd38b023d9dAe2,
            ethLockbox: 0xbd4AbB321138e8Eddc399cE64E66451294325a14,
            proxyAdmin: 0xd56045E68956FCe2576E680c95a4750cf8241f79
        });
        chains[2] = ChainHandles({
            name: "Soneium",
            l2ChainId: 1_868,
            systemConfig: 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
            portal: 0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
            messenger: 0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f,
            standardBridge: 0xeb9bf100225c214Efc3E7C651ebbaDcF85177607,
            disputeGameFactory: 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0,
            anchorStateRegistry: 0x4890928941e62e273dA359374b105F803329F473,
            ethLockbox: 0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
            proxyAdmin: 0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a
        });
        chains[3] = ChainHandles({
            name: "Unichain",
            l2ChainId: 130,
            systemConfig: 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,
            portal: 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2,
            messenger: 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6,
            standardBridge: 0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA,
            disputeGameFactory: 0x2F12d621a16e2d3285929C9996f478508951dFe4,
            anchorStateRegistry: 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9,
            ethLockbox: 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5,
            proxyAdmin: 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4
        });
    }
}

contract MultiChainTest is Test {
    function test_same_body_validates_four_l1_deployments() external {
        vm.createSelectFork("archive", 26_430_859);
        ChainHandles[] memory chains = MultiChain.all();
        for (uint256 i; i < chains.length; i++) {
            ChainHandles memory chain = chains[i];
            ISystemConfigHandles config = ISystemConfigHandles(chain.systemConfig);
            IPortalHandles portal = IPortalHandles(chain.portal);
            assertEq(config.l2ChainId(), chain.l2ChainId, chain.name);
            assertEq(config.optimismPortal(), chain.portal, chain.name);
            assertEq(config.l1CrossDomainMessenger(), chain.messenger, chain.name);
            assertEq(config.l1StandardBridge(), chain.standardBridge, chain.name);
            assertEq(config.disputeGameFactory(), chain.disputeGameFactory, chain.name);
            assertEq(portal.anchorStateRegistry(), chain.anchorStateRegistry, chain.name);
            assertEq(portal.ethLockbox(), chain.ethLockbox, chain.name);
            assertEq(portal.proxyAdmin(), chain.proxyAdmin, chain.name);
            assertGt(chain.portal.code.length, 0, chain.name);
            assertGt(chain.ethLockbox.code.length, 0, chain.name);
        }
    }
}
