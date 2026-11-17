// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

contract StorageDiffTest is Test {
    uint256 internal pre;
    uint256 internal post;

    bytes32 internal constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    function setUp() public {
        pre = vm.createFork("l1pre");
        post = vm.createFork("l1n");
    }

    function test_diffRelevantU21ProxyStorage() public {
        _diff("SuperchainConfig", 0x95703e0982140D16f8ebA6d158FccEde42f04a4C, 1);

        _diffChain(
            "OP",
            0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,
            0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
            0x322b47Ff1FA8D5611F761e3E275C45B71b294D43,
            0x23B2C62946350F4246f9f9D027e071f0264FD113,
            0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162,
            0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
            0x5a7749f83b81B301cAb5f48EB8516B986DAef23D
        );
        _diffChain(
            "Ink",
            0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
            0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
            0xbd4AbB321138e8Eddc399cE64E66451294325a14,
            0xEe018bAf058227872540AC60eFbd38b023d9dAe2,
            0x57b4C29DAee99a28E6E86778b499361294c134eA,
            0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f,
            0x88FF1e5b602916615391F55854588EFcBB7663f0,
            0x661235a238B11191211fa95D4Dd9E423d521E0Be
        );
        _diffChain(
            "Soneium",
            0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
            0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
            0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
            0x4890928941e62e273dA359374b105F803329F473,
            0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47,
            0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f,
            0xeb9bf100225c214Efc3E7C651ebbaDcF85177607,
            0x5933e323bE8896DfaCd1cD671442F27dAA10a053
        );
        _diffChain(
            "Unichain",
            0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,
            0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2,
            0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5,
            0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9,
            0x74ad145aC900F1DD5551F0C9E143314DC4022FCf,
            0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6,
            0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA,
            0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf
        );
    }

    function _diffChain(
        string memory chain,
        address systemConfig,
        address portal,
        address lockbox,
        address asr,
        address delayedWETH,
        address messenger,
        address bridge,
        address erc721Bridge
    ) internal {
        _diff(string.concat(chain, ".SystemConfig"), systemConfig, 109);
        _diffSystemConfigNamespaced(chain, systemConfig);
        _diff(string.concat(chain, ".Portal"), portal, 63);
        _diff(string.concat(chain, ".ETHLockbox"), lockbox, 3);
        _diff(string.concat(chain, ".ASR"), asr, 6);
        _diff(string.concat(chain, ".DelayedWETH"), delayedWETH, 5);
        _diff(string.concat(chain, ".L1CDM"), messenger, 254);
        _diff(string.concat(chain, ".L1StandardBridge"), bridge, 52);
        _diff(string.concat(chain, ".L1ERC721Bridge"), erc721Bridge, 51);
    }

    function _diff(string memory label, address target, uint256 maxSlot) internal {
        bytes32[] memory beforeValues = new bytes32[](maxSlot + 1);
        vm.selectFork(pre);
        for (uint256 i; i <= maxSlot; ++i) beforeValues[i] = vm.load(target, bytes32(i));

        vm.selectFork(post);
        for (uint256 i; i <= maxSlot; ++i) {
            bytes32 afterValue = vm.load(target, bytes32(i));
            if (afterValue != beforeValues[i]) {
                console2.log(label);
                console2.log("slot", i);
                console2.log("before");
                console2.logBytes32(beforeValues[i]);
                console2.log("after");
                console2.logBytes32(afterValue);
            }
        }

        _diffOne(label, target, IMPLEMENTATION_SLOT);
    }

    function _diffSystemConfigNamespaced(string memory chain, address target) internal {
        bytes32[9] memory slots = [
            keccak256("systemconfig.unsafeblocksigner"),
            bytes32(uint256(keccak256("systemconfig.l1crossdomainmessenger")) - 1),
            bytes32(uint256(keccak256("systemconfig.l1erc721bridge")) - 1),
            bytes32(uint256(keccak256("systemconfig.l1standardbridge")) - 1),
            bytes32(uint256(keccak256("systemconfig.optimismportal")) - 1),
            bytes32(uint256(keccak256("systemconfig.optimismmintableerc20factory")) - 1),
            bytes32(uint256(keccak256("systemconfig.delayedweth")) - 1),
            bytes32(uint256(keccak256("systemconfig.opcm")) - 1),
            bytes32(uint256(keccak256("systemconfig.startBlock")) - 1)
        ];
        for (uint256 i; i < slots.length; ++i) {
            _diffOne(string.concat(chain, ".SystemConfig.namespaced"), target, slots[i]);
        }

        bytes32 mappingSlot = bytes32(uint256(109));
        _diffOne(
            string.concat(chain, ".feature.ETH_LOCKBOX"),
            target,
            keccak256(abi.encode(bytes32("ETH_LOCKBOX"), mappingSlot))
        );
        _diffOne(
            string.concat(chain, ".feature.INTEROP"),
            target,
            keccak256(abi.encode(bytes32("INTEROP"), mappingSlot))
        );
        _diffOne(
            string.concat(chain, ".feature.CUSTOM_GAS_TOKEN"),
            target,
            keccak256(abi.encode(bytes32("CUSTOM_GAS_TOKEN"), mappingSlot))
        );
    }

    function _diffOne(string memory label, address target, bytes32 slot) internal {
        vm.selectFork(pre);
        bytes32 beforeValue = vm.load(target, slot);
        vm.selectFork(post);
        bytes32 afterValue = vm.load(target, slot);
        if (afterValue != beforeValue) {
            console2.log(label);
            console2.log("slot");
            console2.logBytes32(slot);
            console2.log("before");
            console2.logBytes32(beforeValue);
            console2.log("after");
            console2.logBytes32(afterValue);
        }
    }

}
