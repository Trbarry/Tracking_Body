// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

contract StateDiffTest is Test {
    bytes32 internal constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 internal constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    function shouldRead(uint256 targetIndex, uint256 slot) internal pure returns (bool) {
        if (targetIndex == 0) return slot <= 1; // SuperchainConfig
        uint256 kind = (targetIndex - 1) % 8;
        if (kind == 0) return slot <= 1 || slot == 51 || (slot >= 101 && slot <= 109); // SystemConfig
        if (kind == 1) return slot <= 2 || (slot >= 50 && slot <= 63); // Portal
        if (kind == 2) return slot <= 3; // Lockbox
        if (kind == 3) return slot <= 3 || (slot >= 49 && slot <= 51); // L1ERC721Bridge
        if (kind == 4) return slot <= 3; // Mintable factory
        if (kind == 5) return slot <= 1 || slot == 51 || (slot >= 101 && slot <= 105); // DGF
        if (kind == 6) return slot <= 5; // DelayedWETH
        return slot <= 3 || slot == 5 || slot == 6; // AnchorStateRegistry
    }

    function targets() internal pure returns (address[] memory a) {
        a = new address[](33);
        // Shared SuperchainConfig, then OP Mainnet, Ink, Soneium, Unichain:
        // SystemConfig, Portal, Lockbox, L1ERC721Bridge, MintableFactory, DGF, DelayedWETH, ASR.
        a[0] = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
        a[1] = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
        a[2] = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
        a[3] = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
        a[4] = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
        a[5] = 0x75505a97BD334E7BD3C476893285569C4136Fa0F;
        a[6] = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
        a[7] = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
        a[8] = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
        a[9] = 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364;
        a[10] = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
        a[11] = 0xbd4AbB321138e8Eddc399cE64E66451294325a14;
        a[12] = 0x661235a238B11191211fa95D4Dd9E423d521E0Be;
        a[13] = 0xA8B389A82e088b164cD03230e900980CcED34d29;
        a[14] = 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD;
        a[15] = 0x57b4C29DAee99a28E6E86778b499361294c134eA;
        a[16] = 0xEe018bAf058227872540AC60eFbd38b023d9dAe2;
        a[17] = 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3;
        a[18] = 0x88e529A6ccd302c948689Cd5156C83D4614FAE92;
        a[19] = 0x67B4de6FfA66EF201Ea6099A89cA397D56622E31;
        a[20] = 0x5933e323bE8896DfaCd1cD671442F27dAA10a053;
        a[21] = 0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F;
        a[22] = 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0;
        a[23] = 0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47;
        a[24] = 0x4890928941e62e273dA359374b105F803329F473;
        a[25] = 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6;
        a[26] = 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2;
        a[27] = 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5;
        a[28] = 0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf;
        a[29] = 0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad;
        a[30] = 0x2F12d621a16e2d3285929C9996f478508951dFe4;
        a[31] = 0x74ad145aC900F1DD5551F0C9E143314DC4022FCf;
        a[32] = 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9;
    }

    function test_exactNMinus1ToNLinearStorageDiff() external {
        uint256 pre = vm.createFork("l1pre");
        uint256 post = vm.createFork("l1n");
        address[] memory a = targets();
        uint256 width = 110;
        bytes32[] memory oldValues = new bytes32[](a.length * width);
        bytes32[] memory oldImpl = new bytes32[](a.length);
        bytes32[] memory oldAdmin = new bytes32[](a.length);

        vm.selectFork(pre);
        for (uint256 i; i < a.length; i++) {
            oldImpl[i] = vm.load(a[i], IMPLEMENTATION_SLOT);
            oldAdmin[i] = vm.load(a[i], ADMIN_SLOT);
            for (uint256 s; s < width; s++) {
                if (shouldRead(i, s)) oldValues[i * width + s] = vm.load(a[i], bytes32(s));
            }
        }

        vm.selectFork(post);
        for (uint256 i; i < a.length; i++) {
            bytes32 newImpl = vm.load(a[i], IMPLEMENTATION_SLOT);
            if (newImpl != oldImpl[i]) {
                emit log_named_address("target", a[i]);
                emit log_named_bytes32("slot", IMPLEMENTATION_SLOT);
                emit log_named_bytes32("before", oldImpl[i]);
                emit log_named_bytes32("after", newImpl);
            }
            assertEq(vm.load(a[i], ADMIN_SLOT), oldAdmin[i], "admin slot changed");
            for (uint256 s; s < width; s++) {
                if (!shouldRead(i, s)) continue;
                bytes32 newValue = vm.load(a[i], bytes32(s));
                bytes32 oldValue = oldValues[i * width + s];
                if (newValue != oldValue) {
                    emit log_named_address("target", a[i]);
                    emit log_named_uint("linear slot", s);
                    emit log_named_bytes32("before", oldValue);
                    emit log_named_bytes32("after", newValue);
                }
            }
        }
    }

    // Manual scan helper: the shared later-block RPC occasionally rate-limits
    // uncached storage reads, so this is intentionally excluded from CI.
    function scan_exactNToLaterLinearStorageDiff() external {
        uint256 atN = vm.createFork("l1n");
        uint256 later = vm.createFork("l1");
        address[] memory a = targets();
        uint256 width = 110;
        bytes32[] memory oldValues = new bytes32[](a.length * width);
        bytes32[] memory oldImpl = new bytes32[](a.length);
        uint256[] memory oldBalances = new uint256[](a.length);

        vm.selectFork(atN);
        for (uint256 i; i < a.length; i++) {
            oldImpl[i] = vm.load(a[i], IMPLEMENTATION_SLOT);
            oldBalances[i] = a[i].balance;
            for (uint256 s; s < width; s++) {
                if (shouldRead(i, s)) oldValues[i * width + s] = vm.load(a[i], bytes32(s));
            }
        }

        vm.selectFork(later);
        for (uint256 i; i < a.length; i++) {
            assertEq(vm.load(a[i], IMPLEMENTATION_SLOT), oldImpl[i], "implementation changed after N");
            if (a[i].balance != oldBalances[i]) {
                emit log_named_address("balance target", a[i]);
                emit log_named_uint("balance before", oldBalances[i]);
                emit log_named_uint("balance after", a[i].balance);
            }
            for (uint256 s; s < width; s++) {
                if (!shouldRead(i, s)) continue;
                bytes32 newValue = vm.load(a[i], bytes32(s));
                bytes32 oldValue = oldValues[i * width + s];
                if (newValue != oldValue) {
                    emit log_named_address("target", a[i]);
                    emit log_named_uint("linear slot", s);
                    emit log_named_bytes32("before", oldValue);
                    emit log_named_bytes32("after", newValue);
                }
            }
        }
    }
}
