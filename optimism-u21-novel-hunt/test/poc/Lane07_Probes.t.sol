// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";
import "./Lane07_Migration.t.sol";

// LANE 07 — probes against today's real state (L1 block 26433900), no privileged action.
contract ProbesTest is Test {
    IPortal constant pOP = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address attacker = address(0xA77AC4E2);

    function setUp() public { vm.createSelectFork(vm.envOr("L1_ALIAS", string("l1"))); vm.deal(attacker, 10 ether); }

    // Legacy output-root games (type 0 / type 8) created after retirementTimestamp=1753379243 are still
    // claim-valid in the same ASR that now respects type 9. They pass the registry gates of the prove path
    // (the call dies only at the output-root preimage check), but cannot move the anchor.
    function test_legacy_output_root_games_still_valid_but_cannot_anchor() public {
        uint256[2] memory idxs = [uint256(17500), 19000];
        for (uint256 k; k < 2; k++) {
            (uint32 t,, address g) = DGF.gameAtIndex(idxs[k]);
            assertTrue(t == 0 || t == 8);
            assertTrue(ASR.isGameClaimValid(g), "legacy game claim-valid");
            WithdrawalTransaction memory w = WithdrawalTransaction(1, attacker, attacker, 1 ether, 100000, "");
            OutputRootProof memory o = OutputRootProof(0, bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)));
            bytes[] memory pr = new bytes[](0);
            vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidOutputRootProof()"))); // i.e. passed Proper+Respected gates
            vm.prank(attacker); pOP.proveWithdrawalTransaction(w, idxs[k], o, pr);
            // sequence number is an L2 block number (~1.5e8) < anchor timestamp (~1.79e9)
            (, uint256 aSeq) = ASR.getAnchorRoot();
            assertLt(IGame(g).l2SequenceNumber(), aSeq);
            vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_InvalidAnchorGame()")));
            ASR.setAnchorState(g);
        }
    }

    // Legacy types cannot be created any more; type 5 is tx.origin-gated and (when created by the real
    // proposer) not respected on OP Mainnet.
    function test_game_creation_surface() public {
        vm.startPrank(attacker, attacker);
        vm.expectRevert(abi.encodeWithSignature("NoImplementation(uint32)", uint32(0)));
        DGF.create(0, bytes32(uint256(1)), abi.encode(uint256(200_000_000)));
        vm.expectRevert(abi.encodeWithSignature("NoImplementation(uint32)", uint32(8)));
        DGF.create(8, bytes32(uint256(1)), abi.encode(uint256(200_000_000)));
        bytes memory e = abi.encodePacked(bytes1(0x01), uint64(block.timestamp), uint256(10), bytes32(uint256(0xdead)));
        vm.expectRevert(bytes4(keccak256("BadAuth()")));
        DGF.create(5, keccak256(e), e);
        // type 9: permissionless, 0.08 ETH, any timestamp > anchor, including far future / uint64 max - 1
        bytes memory f = abi.encodePacked(bytes1(0x01), type(uint64).max - 1, uint256(10), bytes32(uint256(0xdead)));
        address g = DGF.create{ value: 0.08 ether }(9, keccak256(f), f);
        assertEq(IGame(g).l2SequenceNumber(), type(uint64).max - 1);
        assertTrue(IGame(g).wasRespectedGameTypeWhenCreated());
        // root claim must be the keccak of a well-formed v1 super root: version byte and length are enforced on L1
        bytes memory bad = abi.encodePacked(bytes1(0x02), uint64(block.timestamp), uint256(10), bytes32(uint256(0xdead)));
        vm.expectRevert(); DGF.create{ value: 0.08 ether }(9, keccak256(bad), bad);
        vm.expectRevert(bytes4(keccak256("BadExtraData()")));
        DGF.create{ value: 0.08 ether }(9, bytes32(uint256(0x1234)), e); // root != keccak(extraData)
        bytes memory short_ = abi.encodePacked(bytes1(0x01), uint64(block.timestamp));
        vm.expectRevert(bytes4(keccak256("BadExtraData()")));
        DGF.create{ value: 0.08 ether }(9, keccak256(short_), short_);
        vm.stopPrank();

        // a type-5 game created by the real proposer (its normal role) is NOT respected on OP Mainnet
        address proposer = 0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0;
        vm.prank(proposer, proposer);
        address g5 = DGF.create(5, keccak256(e), e);
        assertFalse(IGame(g5).wasRespectedGameTypeWhenCreated());
        assertFalse(ASR.isGameClaimValid(g5));
        vm.warp(block.timestamp + 302401);
        vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_InvalidAnchorGame()")));
        ASR.setAnchorState(g5);
    }
}
