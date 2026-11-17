// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

/// Replays the U21 upgrade tx on a fork of block N-1 (l1pre) and records every storage write.
/// LOCAL FORK ONLY. Nothing is broadcast.
contract ReplayTest is Test {
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant SENDER = 0xE10A25d4ec17A94CA455F3cDA84137189843B4f2;

    function test_replay_statediff() public {
        vm.createSelectFork("l1pre");
        bytes memory input = vm.parseBytes(vm.readFile("test/u21-input.hex"));
        vm.startStateDiffRecording();
        vm.prank(SENDER, SENDER);
        (bool ok, bytes memory ret) = SAFE.call{ gas: 14_000_000 }(input);
        Vm.AccountAccess[] memory acc = vm.stopAndReturnStateDiff();
        require(ok, "replay failed");
        ret;
        uint256 n;
        vm.writeFile("replay-writes.csv", "");
        for (uint256 i = 0; i < acc.length; i++) {
            for (uint256 j = 0; j < acc[i].storageAccesses.length; j++) {
                Vm.StorageAccess memory s = acc[i].storageAccesses[j];
                if (!s.isWrite || s.reverted) continue;
                n++;
                vm.writeLine(
                    "replay-writes.csv",
                    string.concat(
                        vm.toString(i), ",", vm.toString(s.account), ",", vm.toString(s.slot), ",",
                        vm.toString(s.previousValue), ",", vm.toString(s.newValue)
                    )
                );
            }
        }
        emit log_named_uint("writes", n);
        emit log_named_uint("accesses", acc.length);
    }

    function test_replay_trace() public {
        vm.createSelectFork("l1pre");
        bytes memory input = vm.parseBytes(vm.readFile("test/u21-input.hex"));
        vm.prank(SENDER, SENDER);
        (bool ok,) = SAFE.call{ gas: 14_000_000 }(input);
        require(ok, "replay failed");
    }
}
