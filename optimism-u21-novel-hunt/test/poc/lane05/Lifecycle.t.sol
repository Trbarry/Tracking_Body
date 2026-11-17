// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";

contract Receiver {
    uint256 public got;
    receive() external payable { got += msg.value; }
}

/// Real deployed OP Mainnet contracts on the `l1` fork (block 26433900, post-U21).
contract LifecycleBase is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    address constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    uint32 constant GT = 9;

    bytes4 constant E_UNPROVEN = bytes4(keccak256("OptimismPortal_Unproven()"));
    bytes4 constant E_NOT_INVALIDATED = bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()"));
    bytes4 constant E_INVALID_ROOT = bytes4(keccak256("OptimismPortal_InvalidRootClaim()"));
    bytes4 constant E_NOT_OLD = bytes4(keccak256("OptimismPortal_ProofNotOldEnough()"));
    bytes4 constant E_ALREADY_FINALIZED = bytes4(keccak256("OptimismPortal_AlreadyFinalized()"));
    bytes4 constant E_IMPROPER = bytes4(keccak256("OptimismPortal_ImproperDisputeGame()"));
    bytes4 constant E_INVALID_GAME = bytes4(keccak256("OptimismPortal_InvalidDisputeGame()"));
    bytes4 constant E_PAUSED = bytes4(keccak256("OptimismPortal_CallPaused()"));

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");
    address challenger = makeAddr("challenger");
    address rando = makeAddr("rando");

    function setUp() public virtual {
        vm.createSelectFork("l1");
        vm.deal(attacker, 100 ether);
        vm.deal(challenger, 100 ether);
    }

    function _hashWithdrawal(WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
        return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
    }

    /// Single-leaf secure trie containing keccak(storageKey) -> 0x01.
    function _singleLeafTrie(bytes32 _withdrawalHash) internal pure returns (bytes32 root, bytes[] memory proof) {
        bytes32 storageKey = keccak256(abi.encode(_withdrawalHash, uint256(0)));
        bytes32 path = keccak256(abi.encode(storageKey));
        bytes memory leaf = abi.encodePacked(hex"e3", hex"a1", hex"20", path, hex"01");
        root = keccak256(leaf);
        proof = new bytes[](1);
        proof[0] = leaf;
    }

    /// Creates a type-9 game whose (fabricated) super root commits to an output root that contains `_wh`.
    function _createGameFor(address _creator, bytes32 _wh, uint64 _seq)
        internal
        returns (IGame game, uint256 index, OutputRootProof memory orp, bytes[] memory wproof)
    {
        bytes32 storageRoot;
        (storageRoot, wproof) = _singleLeafTrie(_wh);
        orp = OutputRootProof({
            version: bytes32(0),
            stateRoot: keccak256("state"),
            messagePasserStorageRoot: storageRoot,
            latestBlockhash: keccak256("blk")
        });
        bytes32 outputRoot = keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash));
        bytes memory extra = abi.encodePacked(bytes1(0x01), _seq, uint256(10), outputRoot);
        bytes32 rootClaim = keccak256(extra);
        uint256 bond = DGF.initBonds(GT);
        index = DGF.gameCount();
        vm.prank(_creator);
        game = IGame(DGF.create{ value: bond }(GT, rootClaim, extra));
    }

    function _nextSeq() internal view returns (uint64) {
        (, uint256 s) = ASR.getAnchorRoot();
        return uint64(s + 1_000_000 + uint256(keccak256(abi.encode(gasleft()))) % 1000);
    }

    function _resolveChallengerWins(IGame game) internal {
        uint256 bond = game.getRequiredBond(2);
        bytes32 rc = game.rootClaim();
        vm.prank(challenger);
        game.attack{ value: bond }(rc, 0, bytes32(uint256(0xbad)));
        vm.warp(block.timestamp + game.maxClockDuration() + 1);
        game.resolveClaim(1, 0);
        game.resolveClaim(0, 0);
        assertEq(game.resolve(), 1, "CHALLENGER_WINS");
    }

    function _resolveDefenderWins(IGame game) internal {
        vm.warp(block.timestamp + game.maxClockDuration() + 1);
        game.resolveClaim(0, 0);
        assertEq(game.resolve(), 2, "DEFENDER_WINS");
    }

    function _wd(address target, uint256 value, uint256 nonce) internal pure returns (WithdrawalTransaction memory) {
        return WithdrawalTransaction({
            nonce: nonce, sender: address(0xA11CE), target: target, value: value, gasLimit: 100_000, data: ""
        });
    }
}

contract DeletePredicateTest is LifecycleBase {
    /// Boundary matrix of the deletion predicate against real code.
    function test_predicate_matrix() public {
        WithdrawalTransaction memory wtx = _wd(address(0xBEEF), 0, 1);
        bytes32 wh = _hashWithdrawal(wtx);

        // unproven
        vm.expectRevert(E_UNPROVEN);
        PORTAL.deleteProvenWithdrawal(wh, attacker);

        (IGame game, uint256 idx, OutputRootProof memory orp, bytes[] memory proof) = _createGameFor(attacker, wh, _nextSeq());
        vm.warp(block.timestamp + 12);
        vm.prank(attacker);
        PORTAL.proveWithdrawalTransaction(wtx, idx, orp, proof);
        (address g, uint64 ts) = PORTAL.provenWithdrawals(wh, attacker);
        assertEq(g, address(game));
        assertEq(ts, block.timestamp);

        // IN_PROGRESS -> not deletable
        assertEq(game.status(), 0);
        vm.expectRevert(E_NOT_INVALIDATED);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(wh, attacker);

        uint256 snap = vm.snapshotState();

        // --- branch A: DEFENDER_WINS -> not deletable, even by the submitter himself
        _resolveDefenderWins(game);
        vm.expectRevert(E_NOT_INVALIDATED);
        vm.prank(attacker);
        PORTAL.deleteProvenWithdrawal(wh, attacker);

        // --- A2: DEFENDER_WINS + retired (guardian updateRetirementTimestamp): proof is permanently dead but NOT deletable
        vm.prank(GUARDIAN);
        ASR.updateRetirementTimestamp();
        assertTrue(ASR.isGameRetired(address(game)));
        assertFalse(ASR.isGameClaimValid(address(game)));
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, attacker);
        vm.warp(block.timestamp + 30 days);
        vm.expectRevert(E_INVALID_ROOT);
        PORTAL.checkWithdrawal(wh, attacker);

        vm.revertToState(snap);

        // --- branch B: CHALLENGER_WINS -> deletable by anyone, also while paused
        _resolveChallengerWins(game);
        vm.prank(GUARDIAN);
        ISuperchainConfig(SUPERCHAIN_CONFIG).pause(LOCKBOX);
        assertTrue(PORTAL.paused());
        vm.expectEmit(true, true, false, false, address(PORTAL));
        emit WithdrawalProofDeleted(wh, attacker);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(wh, attacker);
        (g, ts) = PORTAL.provenWithdrawals(wh, attacker);
        assertEq(g, address(0));
        assertEq(ts, 0);
        // array is NOT cleaned
        assertEq(PORTAL.numProofSubmitters(wh), 1);
        assertEq(PORTAL.proofSubmitters(wh, 0), attacker);
        // second delete -> Unproven
        vm.expectRevert(E_UNPROVEN);
        PORTAL.deleteProvenWithdrawal(wh, attacker);

        vm.revertToState(snap);

        // --- branch C: IN_PROGRESS but blacklisted -> deletable
        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(address(game));
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(wh, attacker);
        (g, ts) = PORTAL.provenWithdrawals(wh, attacker);
        assertEq(ts, 0);

        vm.revertToState(snap);

        // --- branch D: paused only (temporarily improper) -> not deletable
        vm.prank(GUARDIAN);
        ISuperchainConfig(SUPERCHAIN_CONFIG).pause(LOCKBOX);
        assertFalse(ASR.isGameProper(address(game)));
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, attacker);

        vm.revertToState(snap);

        // --- branch E: respected game type changed after proof -> still not deletable, still finalizable
        vm.prank(GUARDIAN);
        ASR.setRespectedGameType(5);
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, attacker);
    }

    event WithdrawalProofDeleted(bytes32 indexed withdrawalHash, address indexed proofSubmitter);
}
