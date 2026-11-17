// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Lane09Migrate.t.sol";

contract Lane09RemigrateTest is Lane09Base {
    function setUp() public {
        vm.createSelectFork("l1");
    }

    function _input(address[] memory scs) internal view returns (MigrateInput memory input) {
        DisputeGameConfig[] memory gcs = new DisputeGameConfig[](1);
        gcs[0] = DisputeGameConfig({ enabled: true, initBond: 0.08 ether, gameType: 9,
            gameArgs: abi.encode(bytes32(0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9)) });
        input = MigrateInput({ chainSystemConfigs: scs, disputeGameConfigs: gcs,
            startingAnchorRoot: Proposal({ root: keccak256("x"), l2SequenceNumber: block.timestamp - 1 }),
            startingRespectedGameType: 9 });
    }

    /// migrate() is not callable by anyone but (a delegatecall from) the ProxyAdmin owner.
    function test_migrate_unprivileged_reverts() public {
        address[] memory scs = new address[](2);
        scs[0] = address(OP_SC);
        scs[1] = address(UNI_SC);
        // direct call
        vm.expectRevert(bytes4(keccak256("OPContractsManagerV2_OnlyDelegateCall()")));
        IOPCM(OPCM).migrate(_input(scs));
        // delegatecall from an arbitrary contract (this test contract)
        (bool ok,) = OPCM.delegatecall(abi.encodeCall(IOPCM.migrate, (_input(scs))));
        assertFalse(ok, "non-owner delegatecall must fail");
    }

    function test_remigrate_reverts() public {
        _migrate();
        address[] memory scs = new address[](2);
        scs[0] = address(OP_SC);
        scs[1] = address(UNI_SC);
        vm.prank(SAFE, true);
        (bool ok, bytes memory ret) = OPCM.delegatecall(abi.encodeCall(IOPCM.migrate, (_input(scs))));
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(keccak256("OPContractsManagerMigrator_ChainAlreadyMigrated()")));
    }

    /// Pre-migration donations (portal.donateETH + force-fed ETH on the per-chain lockbox) are swept into
    /// the shared lockbox by migrate(): surplus only, no revert, no mis-accounting.
    function test_preMigration_donations_are_swept() public {
        uint256 pre = address(OP_LB).balance + address(UNI_LB).balance;
        vm.deal(address(this), 10 ether);
        OP_PORTAL.donateETH{ value: 1 ether }();
        UNI_PORTAL.donateETH{ value: 2 ether }();
        vm.deal(address(OP_LB), address(OP_LB).balance + 3 ether); // models selfdestruct/coinbase force-send
        _migrate();
        assertEq(address(sharedLB).balance, pre + 6 ether);
        assertEq(address(OP_PORTAL).balance + address(UNI_PORTAL).balance + address(OP_LB).balance + address(UNI_LB).balance, 0);
    }
}
