// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// F5 — chain-history differential.
// Runs the SAME unprivileged call sequence against the real deployed v9 contracts of OP Mainnet, Ink,
// Soneium and Unichain on the pinned L1 fork (block 26433900) and records the outcome per chain.
// No privileged prank, no storage write: every call is made by a fresh EOA.

interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function gameArgs(uint32) external view returns (bytes memory);
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData) external payable returns (address);
}

interface IASR {
    function retirementTimestamp() external view returns (uint64);
    function respectedGameType() external view returns (uint32);
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function isGameClaimValid(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function setAnchorState(address) external;
}

interface IGame {
    function l2SequenceNumber() external view returns (uint256);
    function l2BlockNumber() external view returns (uint256);
    function gameType() external view returns (uint32);
    function createdAt() external view returns (uint64);
    function status() external view returns (uint8);
    function anchorStateRegistry() external view returns (address);
    function rootClaim() external view returns (bytes32);
}

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

interface IPortal {
    function proveWithdrawalTransaction(
        WithdrawalTransaction memory _tx,
        uint256 _disputeGameIndex,
        OutputRootProof calldata _outputRootProof,
        bytes[] calldata _withdrawalProof
    ) external;
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function paused() external view returns (bool);
}

interface ISystemConfig {
    function l2ChainId() external view returns (uint256);
    function isFeatureEnabled(bytes32) external view returns (bool);
}

contract F5_ChainHistoryDifferential is Test {
    struct ChainCfg {
        string name;
        address portal;
        address systemConfig;
        uint256 legacyValidIdx; // latest claim-valid legacy (block-number domain) game: type 0 / 1 / 8
        uint256 retiredIdx; // a game created before the U16 ASR (retired)
    }

    ChainCfg[4] internal chains;
    address internal attacker = makeAddr("f5-unprivileged");

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        chains[0] = ChainCfg("OP", 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed, 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 20094, 0);
        chains[1] = ChainCfg("INK", 0x5d66C1782664115999C47c9fA5cd031f495D3e4F, 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, 2521, 0);
        chains[2] = ChainCfg("SONEIUM", 0x88e529A6ccd302c948689Cd5156C83D4614FAE92, 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, 7954, 0);
        chains[3] = ChainCfg("UNICHAIN", 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2, 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6, 16394, 0);
        vm.deal(attacker, 10 ether);
    }

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }

    function _name(bytes4 s) internal pure returns (string memory) {
        if (s == bytes4(keccak256("NoImplementation(uint32)"))) return "NoImplementation";
        if (s == bytes4(keccak256("BadAuth()"))) return "BadAuth";
        if (s == bytes4(keccak256("IncorrectBondAmount()"))) return "IncorrectBondAmount";
        if (s == bytes4(keccak256("AnchorStateRegistry_InvalidAnchorGame()"))) return "ASR_InvalidAnchorGame";
        if (s == bytes4(keccak256("OptimismPortal_ImproperDisputeGame()"))) return "Portal_ImproperDisputeGame";
        if (s == bytes4(keccak256("OptimismPortal_InvalidDisputeGame()"))) return "Portal_InvalidDisputeGame";
        if (s == bytes4(keccak256("OptimismPortal_InvalidOutputRootProof()"))) return "Portal_InvalidOutputRootProof";
        if (s == bytes4(keccak256("OptimismPortal_InvalidProofTimestamp()"))) return "Portal_InvalidProofTimestamp";
        if (s == bytes4(keccak256("OptimismPortal_InvalidMerkleProof()"))) return "Portal_InvalidMerkleProof";
        if (s == bytes4(keccak256("UnexpectedRootClaim(bytes32)"))) return "UnexpectedRootClaim";
        if (s == bytes4(0)) return "REVERT(empty)";
        return vm.toString(abi.encodePacked(s));
    }

    function _create(IDGF dgf, uint32 gt, bytes32 root, bytes memory extra) internal returns (bool ok, bytes memory ret) {
        uint256 bond = dgf.initBonds(gt);
        vm.prank(attacker, attacker);
        (ok, ret) = address(dgf).call{ value: bond }(abi.encodeCall(IDGF.create, (gt, root, extra)));
    }

    function _prove(IPortal portal, uint256 idx) internal returns (bool ok, bytes memory ret) {
        WithdrawalTransaction memory wd =
            WithdrawalTransaction({ nonce: 1 << 240, sender: attacker, target: attacker, value: 1 ether, gasLimit: 100000, data: "" });
        OutputRootProof memory p = OutputRootProof(bytes32(0), bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)));
        bytes[] memory proof = new bytes[](0);
        vm.prank(attacker, attacker);
        (ok, ret) = address(portal).call(abi.encodeCall(IPortal.proveWithdrawalTransaction, (wd, idx, p, proof)));
    }

    function test_same_sequence_four_chains() public {
        string memory out = "chain | create(9) | create(5) | create(0) | create(1) | create(8) | setAnchorState(legacy) | prove(legacy game) | prove(retired game) | legacySeq | anchorSeq | respected | retirementTs\n";
        for (uint256 i = 0; i < 4; i++) {
            ChainCfg memory c = chains[i];
            uint256 snap = vm.snapshotState();
            IPortal portal = IPortal(c.portal);
            IDGF dgf = IDGF(portal.disputeGameFactory());
            IASR asr = IASR(portal.anchorStateRegistry());
            uint256 chainId = ISystemConfig(c.systemConfig).l2ChainId();
            string memory row = c.name;

            // S1: permissionless super game (type 9) with an arbitrary super root for this chain, far in the future.
            {
                bytes memory extra = abi.encodePacked(bytes1(0x01), uint64(block.timestamp + 3600), bytes32(chainId), keccak256("f5-fake-output-root"));
                (bool ok, bytes memory ret) = _create(dgf, 9, keccak256(extra), extra);
                row = string.concat(row, " | ", ok ? "OK(created)" : _name(_sel(ret)));
                // S2: permissioned super game (type 5) by a non-proposer.
                (ok, ret) = _create(dgf, 5, keccak256(extra), extra);
                row = string.concat(row, " | ", ok ? "OK(created)" : _name(_sel(ret)));
            }
            // S3: legacy game types.
            {
                bytes memory extraL = abi.encode(uint256(1) << 40);
                uint32[3] memory legacy = [uint32(0), 1, 8];
                for (uint256 k = 0; k < 3; k++) {
                    (bool ok, bytes memory ret) = _create(dgf, legacy[k], keccak256("f5-fake-output-root"), extraL);
                    row = string.concat(row, " | ", ok ? "OK(created)" : _name(_sel(ret)));
                }
            }
            // S4: try to install the latest claim-valid LEGACY game (block-number domain) as the anchor.
            (,, address legacyGame) = dgf.gameAtIndex(c.legacyValidIdx);
            {
                assertTrue(asr.isGameClaimValid(legacyGame), "fixture: legacy game must be claim-valid");
                vm.prank(attacker, attacker);
                (bool ok, bytes memory ret) = address(asr).call(abi.encodeCall(IASR.setAnchorState, (legacyGame)));
                row = string.concat(row, " | ", ok ? "OK(ANCHOR MOVED)" : _name(_sel(ret)));
                assertFalse(ok, "legacy game must not become the anchor");
            }
            // S5: prove against the legacy claim-valid game with a bogus output root proof.
            {
                (bool ok, bytes memory ret) = _prove(portal, c.legacyValidIdx);
                row = string.concat(row, " | ", ok ? "OK" : _name(_sel(ret)));
                // S6: prove against a retired game.
                (ok, ret) = _prove(portal, c.retiredIdx);
                row = string.concat(row, " | ", ok ? "OK" : _name(_sel(ret)));
            }
            {
                (, uint256 anchorSeq) = asr.getAnchorRoot();
                uint256 legacySeq = IGame(legacyGame).l2SequenceNumber();
                assertLt(legacySeq, anchorSeq, "block-number domain must stay below the timestamp-domain anchor");
                row = string.concat(row, " | ", vm.toString(legacySeq), " | ", vm.toString(anchorSeq), " | ", vm.toString(uint256(asr.respectedGameType())), " | ", vm.toString(uint256(asr.retirementTimestamp())));
            }
            out = string.concat(out, row, "\n");
            vm.revertToState(snap);
        }
        console.log(out);
        vm.writeFile("F5-differential-output.txt", out);
    }

    // A legacy game whose own AnchorStateRegistry is an ORPHANED registry is still "registered" for the live
    // registry (isGameRegistered only checks the factory); it is excluded solely by retirementTimestamp.
    function test_orphaned_asr_games_only_excluded_by_retirement() public {
        for (uint256 i = 0; i < 4; i++) {
            ChainCfg memory c = chains[i];
            IPortal portal = IPortal(c.portal);
            IDGF dgf = IDGF(portal.disputeGameFactory());
            IASR asr = IASR(portal.anchorStateRegistry());
            (,, address g) = dgf.gameAtIndex(c.retiredIdx);
            address own = IGame(g).anchorStateRegistry();
            assertTrue(own != address(asr), "game 0 belongs to a legacy registry");
            assertTrue(asr.isGameRetired(g));
            assertFalse(asr.isGameProper(g));
            assertLe(uint256(IGame(g).createdAt()), uint256(asr.retirementTimestamp()));
            console.log(c.name, "game0 ownASR", own);
            console.log("   live ASR", address(asr), "retirementTimestamp", uint256(asr.retirementTimestamp()));
        }
    }
}
