// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// ATK-T3 — bridge token identity, L1ERC721Bridge, OptimismMintableERC20Factory (OP Mainnet).
//
// Forks: L1 `l1` (26433900, post-U21) and `l1pre` (26430858, N-1, pre-U21); L2 `l2` (OP 159654093).
// Every attacker object is attacker-deployed (fake L2 tokens) or a locally deployed standard token that
// stands for an honest L1 asset. No third-party contract is called. Deployed Optimism bytecode under test:
// L2StandardBridge 1.13.2, L2ERC721Bridge 1.10.1, L2CrossDomainMessenger 2.2.1, L2ToL1MessagePasser
// (OP fork); OptimismPortal2, L1CrossDomainMessenger 2.13.0 (2.11.1 on l1pre), L1StandardBridge 2.8.2,
// L1ERC721Bridge 2.9.1, OptimismMintableERC20Factory 1.11.0 (L1 fork).
//
// HARNESS-ONLY step (documented, identical to lane B / PASS A NestedReplay): the L2->L1 withdrawal that the
// ATTACKER himself initiates on the L2 fork (exact MessagePassed bytes captured from the deployed L2
// contracts) is proven on L1 by injecting provenWithdrawals[hash][SUB] against the real claim-valid anchor
// game (vm.store), because the L2 fork state is not committed to by any L1 game. In production the attacker
// proves his own withdrawal and waits 7 days. Finalization then runs through the real, permissionless
// OptimismPortal2.finalizeWithdrawalTransactionExternalProof -> L1CrossDomainMessenger -> bridge.

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function anchorStateRegistry() external view returns (address);
}

interface IASR {
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
}

interface IGame {
    function createdAt() external view returns (uint64);
}

interface IL1CDM {
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function version() external view returns (string memory);
}

interface IL1SB {
    function depositERC20To(address, address, address, uint256, uint32, bytes calldata) external;
    function deposits(address, address) external view returns (uint256);
    function finalizeBridgeERC20(address, address, address, address, uint256, bytes calldata) external;
    function finalizeERC20Withdrawal(address, address, address, address, uint256, bytes calldata) external;
    function version() external view returns (string memory);
}

interface IL1NB {
    function bridgeERC721To(address, address, address, uint256, uint32, bytes calldata) external;
    function deposits(address, address, uint256) external view returns (bool);
    function finalizeBridgeERC721(address, address, address, address, uint256, bytes calldata) external;
    function version() external view returns (string memory);
}

interface IL1Factory {
    function createOptimismMintableERC20(address, string memory, string memory) external returns (address);
}

interface IL2SB {
    function bridgeERC20To(address, address, address, uint256, uint32, bytes calldata) external;
    function withdrawTo(address, address, uint256, uint32, bytes calldata) external payable;
}

interface IL2NB {
    function bridgeERC721To(address, address, address, uint256, uint32, bytes calldata) external;
}

interface IL2Factory20 {
    function createOptimismMintableERC20(address, string memory, string memory) external returns (address);
}

interface IL2Factory721 {
    function createOptimismMintableERC721(address, string memory, string memory) external returns (address);
}

interface IMintable20 {
    function mint(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IMintable721 {
    function safeMint(address, uint256) external;
    function ownerOf(uint256) external view returns (address);
}

// ------------------------------------------------------------------------------------------------
// Local stand-ins for honest L1 assets (standard, OZ-equivalent checks). Deployed on the fork only.
// ------------------------------------------------------------------------------------------------
contract StdERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
        totalSupply += a;
    }

    function approve(address s, uint256 a) external returns (bool) {
        allowance[msg.sender][s] = a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a;
        balanceOf[f] -= a;
        balanceOf[to] += a;
        return true;
    }
}

contract StdERC721 {
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function mint(address to, uint256 id) external {
        require(ownerOf[id] == address(0), "minted");
        ownerOf[id] = to;
    }

    function approve(address s, uint256 id) external {
        require(msg.sender == ownerOf[id], "not owner");
        getApproved[id] = s;
    }

    function transferFrom(address from, address to, uint256 id) public {
        address o = ownerOf[id];
        require(o == from, "ERC721: transfer from incorrect owner");
        require(msg.sender == o || getApproved[id] == msg.sender || isApprovedForAll[o][msg.sender], "not approved");
        require(to != address(0), "zero");
        delete getApproved[id];
        ownerOf[id] = to;
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);
        if (to.code.length > 0) {
            (bool ok, bytes memory r) =
                to.call(abi.encodeWithSelector(0x150b7a02, msg.sender, from, id, bytes("")));
            require(ok && r.length == 32 && bytes4(r) == bytes4(0x150b7a02), "unsafe recipient");
        }
    }
}

// ------------------------------------------------------------------------------------------------
// Attacker-deployed L2 tokens (deployed on the L2 fork by the attacker; allowed by the brief).
// ------------------------------------------------------------------------------------------------

/// Claims to be an OptimismMintableERC20 for `l1` under BOTH interfaces; burn is a no-op.
contract FakeMintable {
    address public immutable L1;

    constructor(address l1) {
        L1 = l1;
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id != 0xffffffff;
    }

    function l1Token() external view returns (address) {
        return L1;
    }

    function remoteToken() external view returns (address) {
        return L1;
    }

    function burn(address, uint256) external { }
    function mint(address, uint256) external { }
}

/// Legacy and new interfaces disagree: l1Token() = a, remoteToken() = b.
contract FakeSplit {
    address public immutable A;
    address public immutable B;

    constructor(address a, address b) {
        A = a;
        B = b;
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id != 0xffffffff;
    }

    function l1Token() external view returns (address) {
        return A;
    }

    function remoteToken() external view returns (address) {
        return B;
    }

    function burn(address, uint256) external { }
}

/// Only the NEW interface (IOptimismMintableERC20, 0xec4fc8e3) is reported; legacy l1Token() reverts.
contract FakeNewOnly {
    address public immutable R;

    constructor(address r) {
        R = r;
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0xec4fc8e3;
    }

    function remoteToken() external view returns (address) {
        return R;
    }

    function burn(address, uint256) external { }
}

/// Not ERC165; transferFrom "succeeds" without moving anything (escrow path on L2).
contract FakeEscrow {
    function transferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }
}

/// Fake L2 NFT claiming to be the OptimismMintableERC721 of `l1`; ownerOf always the caller's chosen owner.
contract FakeNFT {
    address public immutable L1;
    address public immutable OWNER;

    constructor(address l1, address o) {
        L1 = l1;
        OWNER = o;
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id != 0xffffffff;
    }

    function remoteToken() external view returns (address) {
        return L1;
    }

    function ownerOf(uint256) external view returns (address) {
        return OWNER;
    }

    function burn(address, uint256) external { }
}

contract T3Test is Test {
    // L1 (OP Mainnet contracts)
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IL1CDM constant L1CDM = IL1CDM(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    IL1SB constant L1SB = IL1SB(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    IL1NB constant L1NB = IL1NB(0x5a7749f83b81B301cAb5f48EB8516B986DAef23D);
    IL1Factory constant L1F = IL1Factory(0x75505a97BD334E7BD3C476893285569C4136Fa0F);
    // L2 predeploys
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    IL2SB constant L2SB = IL2SB(0x4200000000000000000000000000000000000010);
    IL2NB constant L2NB = IL2NB(0x4200000000000000000000000000000000000014);
    IL2Factory20 constant L2F20 = IL2Factory20(0x4200000000000000000000000000000000000012);
    IL2Factory721 constant L2F721 = IL2Factory721(0x4200000000000000000000000000000000000017);
    address constant MP = 0x4200000000000000000000000000000000000016;
    bytes32 constant MESSAGE_PASSED =
        keccak256("MessagePassed(uint256,address,address,uint256,uint256,bytes,bytes32)");

    address constant HONEST = address(0x40E5);
    address constant ATTACKER = address(0xA77AC4);
    address constant SUB = address(0x5B17);

    uint256 l1;
    uint256 l1pre;
    uint256 l2;

    function setUp() public {
        l1 = vm.createFork("l1");
        l1pre = vm.createFork("l1pre");
        l2 = vm.createFork("l2");
    }

    // -------------------------------------------------------------------------------- helpers

    function _hash(WithdrawalTransaction memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    /// Capture the (single) L2ToL1MessagePasser MessagePassed of the last recorded logs.
    function _captureWithdrawal() internal returns (WithdrawalTransaction memory w) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 found;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter == MP && logs[i].topics[0] == MESSAGE_PASSED) {
                w.nonce = uint256(logs[i].topics[1]);
                w.sender = address(uint160(uint256(logs[i].topics[2])));
                w.target = address(uint160(uint256(logs[i].topics[3])));
                bytes32 h;
                (w.value, w.gasLimit, w.data, h) = abi.decode(logs[i].data, (uint256, uint256, bytes, bytes32));
                assertEq(h, _hash(w), "captured withdrawal hashes to logged withdrawalHash");
                found++;
            }
        }
        assertEq(found, 1, "exactly one L2->L1 withdrawal");
        assertEq(w.sender, L2CDM, "sender is L2CDM");
        assertEq(w.target, address(L1CDM), "target is L1CDM");
    }

    /// Inner bridge calldata of a captured messenger withdrawal.
    function _inner(WithdrawalTransaction memory w) internal pure returns (address sender, address target, bytes memory m) {
        bytes memory d = w.data;
        bytes memory body = new bytes(d.length - 4);
        for (uint256 k = 4; k < d.length; k++) body[k - 4] = d[k];
        (,  sender, target,,, m) = abi.decode(body, (uint256, address, address, uint256, uint256, bytes));
    }

    /// HARNESS: prove the attacker's own withdrawal against the real anchor game, then finalize it
    /// through the real permissionless portal entry point as an unrelated caller.
    function _finalizeOnL1(WithdrawalTransaction memory w) internal returns (bool delivered, bool failed) {
        IASR asr = IASR(PORTAL.anchorStateRegistry());
        address game = asr.anchorGame();
        assertTrue(asr.isGameClaimValid(game), "anchor game claim-valid");
        bytes32 h = _hash(w);
        uint256 ts = uint256(IGame(game).createdAt()) + 1;
        bytes32 slot = keccak256(abi.encode(SUB, keccak256(abi.encode(h, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
        uint256 t = ts + PORTAL.proofMaturityDelaySeconds() + 1;
        if (block.timestamp < t) vm.warp(t);
        vm.prank(address(0xF1A1), address(0xF1A1));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, SUB);
        assertTrue(PORTAL.finalizedWithdrawals(h), "portal finalized");
        bytes32 mh = keccak256(w.data);
        delivered = L1CDM.successfulMessages(mh);
        failed = L1CDM.failedMessages(mh);
        assertTrue(delivered != failed, "messenger recorded exactly one outcome");
    }

    function _replay(WithdrawalTransaction memory w, address caller) internal returns (bool delivered) {
        bytes memory d = w.data;
        bytes memory body = new bytes(d.length - 4);
        for (uint256 k = 4; k < d.length; k++) body[k - 4] = d[k];
        (uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) =
            abi.decode(body, (uint256, address, address, uint256, uint256, bytes));
        vm.prank(caller, caller);
        L1CDM.relayMessage(n, s, t, v, g, m);
        delivered = L1CDM.successfulMessages(keccak256(w.data));
    }

    // ============================================================================ (b) ERC20 identity

    /// T3-B1: fake L2 tokens (both interfaces / split interfaces / new-only / non-ERC165 escrow) make the
    /// deployed L2StandardBridge emit a withdrawal for a real L1 token X. On L1 each is finalized in the
    /// portal, fails in L1StandardBridge (deposits[X][fake] underflow), is recorded in failedMessages,
    /// stays undeliverable on replay, and X's honest escrow deposits[X][HL2] is untouched.
    function test_B1_fakeL2Tokens_cannotReleaseHonestEscrow() public {
        // L1: honest asset X, honest deposit of 1000 X for its legitimate L2 pair HL2.
        vm.selectFork(l1);
        StdERC20 X = new StdERC20();
        vm.selectFork(l2);
        address HL2 = L2F20.createOptimismMintableERC20(address(X), "X", "X"); // real L2 factory token
        vm.selectFork(l1);
        X.mint(HONEST, 1000e18);
        vm.startPrank(HONEST, HONEST);
        X.approve(address(L1SB), type(uint256).max);
        L1SB.depositERC20To(address(X), HL2, HONEST, 1000e18, 200_000, "");
        vm.stopPrank();
        assertEq(L1SB.deposits(address(X), HL2), 1000e18);

        // L2: attacker objects and the withdrawals the deployed L2 bridge emits for them.
        vm.selectFork(l2);
        address[5] memory fakes;
        fakes[0] = address(new FakeMintable(address(X)));
        fakes[1] = address(new FakeSplit(address(X), HL2)); // l1Token = X, remoteToken = HL2 (honest L2 token!)
        fakes[2] = address(new FakeNewOnly(address(X)));
        fakes[3] = address(new FakeEscrow());
        fakes[4] = fakes[0]; // legacy withdrawTo() entry point
        WithdrawalTransaction[5] memory ws;
        for (uint256 i; i < 5; i++) {
            vm.recordLogs();
            vm.prank(ATTACKER, ATTACKER);
            if (i < 4) L2SB.bridgeERC20To(fakes[i], address(X), ATTACKER, 1000e18, 200_000, "");
            else L2SB.withdrawTo(fakes[i], ATTACKER, 1000e18, 200_000, "");
            ws[i] = _captureWithdrawal();
            (, , bytes memory m) = _inner(ws[i]);
            // decode finalizeBridgeERC20(l1Token, l2Token, ...)
            bytes memory body = new bytes(m.length - 4);
            for (uint256 k = 4; k < m.length; k++) body[k - 4] = m[k];
            (address l1t, address l2t,,,,) = abi.decode(body, (address, address, address, address, uint256, bytes));
            assertEq(l1t, address(X), "message names real L1 token");
            assertEq(l2t, fakes[i], "message names the token the L2 bridge acted on, never HL2");
        }
        // Negative control on L2: attacker cannot make the L2 bridge act on HL2 without holding HL2.
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert();
        L2SB.bridgeERC20To(HL2, address(X), ATTACKER, 1, 200_000, "");

        // L1: deliver each attacker withdrawal through the real portal/messenger.
        vm.selectFork(l1);
        for (uint256 i; i < 5; i++) {
            (bool delivered, bool failed) = _finalizeOnL1(ws[i]);
            assertFalse(delivered, "fake-token withdrawal not delivered");
            assertTrue(failed, "fake-token withdrawal recorded failed");
            assertFalse(_replay(ws[i], ATTACKER), "replay still fails");
        }
        assertEq(X.balanceOf(ATTACKER), 0, "attacker got nothing");
        assertEq(X.balanceOf(address(L1SB)), 1000e18, "escrow intact");
        assertEq(L1SB.deposits(address(X), HL2), 1000e18, "honest pair accounting intact");
        emit log_named_uint("fake withdrawals delivered via portal", 5);
    }

    /// T3-B2 positive control: the per-pair barrier is exact. Attacker escrows 10 X under his own fake
    /// pair, can withdraw exactly 10 through the fake token, and 1 more fails.
    function test_B2_perPairBarrier_isExact_selfFundedOnly() public {
        vm.selectFork(l1);
        StdERC20 X = new StdERC20();
        X.mint(HONEST, 1000e18);
        X.mint(ATTACKER, 10e18);
        vm.selectFork(l2);
        address fake = address(new FakeMintable(address(X)));
        address HL2 = L2F20.createOptimismMintableERC20(address(X), "X", "X");
        vm.selectFork(l1);
        vm.startPrank(HONEST, HONEST);
        X.approve(address(L1SB), type(uint256).max);
        L1SB.depositERC20To(address(X), HL2, HONEST, 1000e18, 200_000, "");
        vm.stopPrank();
        vm.startPrank(ATTACKER, ATTACKER);
        X.approve(address(L1SB), type(uint256).max);
        L1SB.depositERC20To(address(X), fake, ATTACKER, 10e18, 200_000, "");
        vm.stopPrank();

        vm.selectFork(l2);
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2SB.bridgeERC20To(fake, address(X), ATTACKER, 10e18, 200_000, "");
        WithdrawalTransaction memory w10 = _captureWithdrawal();
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2SB.bridgeERC20To(fake, address(X), ATTACKER, 1, 200_000, "");
        WithdrawalTransaction memory w1 = _captureWithdrawal();

        vm.selectFork(l1);
        (bool d10,) = _finalizeOnL1(w10);
        assertTrue(d10, "self-funded pair withdrawal delivered");
        (bool d1, bool f1) = _finalizeOnL1(w1);
        assertFalse(d1);
        assertTrue(f1, "one unit beyond the self-funded pair fails");
        assertEq(X.balanceOf(ATTACKER), 10e18, "attacker recovers exactly his own 10");
        assertEq(L1SB.deposits(address(X), fake), 0);
        assertEq(L1SB.deposits(address(X), HL2), 1000e18, "honest pair untouched");
        assertEq(X.balanceOf(address(L1SB)), 1000e18);
    }

    /// T3-B3: L1-side OptimismMintableERC20 (created by the deployed L1 factory 1.11.0). A withdrawal from
    /// any fake L2 token naming the L1 mintable M fails `_isCorrectTokenPair` (M.remoteToken() is immutable);
    /// only the L2 token equal to M.remoteToken() can mint M. Also: a codeless remote cannot be escrowed on
    /// L2 (the real IBEX L1-mintable token's remote 0xf655... has no code on OP).
    function test_B3_l1Mintable_remoteIdentityBound() public {
        vm.selectFork(l2);
        address R = address(new FakeEscrow()); // stand-in for M's legitimate L2-native remote token
        vm.selectFork(l1);
        address M = L1F.createOptimismMintableERC20(R, "M", "M");
        vm.selectFork(l2);
        address fake = address(new FakeMintable(M));
        address split = address(new FakeSplit(M, R));
        WithdrawalTransaction[3] memory ws;
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2SB.bridgeERC20To(fake, M, ATTACKER, 1e30, 200_000, "");
        ws[0] = _captureWithdrawal();
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2SB.bridgeERC20To(split, M, ATTACKER, 1e30, 200_000, "");
        ws[1] = _captureWithdrawal();
        // Control: the legitimate remote R (here an escrow-path L2 token) does mint M on L1.
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2SB.bridgeERC20To(R, M, ATTACKER, 5, 200_000, "");
        ws[2] = _captureWithdrawal();
        // Codeless remote: SafeERC20 on L2 refuses a call to a non-contract.
        address IBEX_REMOTE = 0xF655C8567E0f213e6C634CD2A68d992152161dC6;
        assertEq(IBEX_REMOTE.code.length, 0);
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert();
        L2SB.bridgeERC20To(IBEX_REMOTE, 0x1287c312ba284DDBc6f7506F38382428174CAb14, ATTACKER, 1, 200_000, "");

        vm.selectFork(l1);
        for (uint256 i; i < 2; i++) {
            (bool d, bool f) = _finalizeOnL1(ws[i]);
            assertFalse(d);
            assertTrue(f, "fake remote cannot mint L1 mintable");
        }
        assertEq(IMintable20(M).totalSupply(), 0, "no M minted by fakes");
        (bool dOk,) = _finalizeOnL1(ws[2]);
        assertTrue(dOk, "legit remote mints");
        assertEq(IMintable20(M).balanceOf(ATTACKER), 5);
        // Real L1-mintable tokens of the OP L1 factory: all four have zero supply at 26433900.
        address[4] memory real = [
            0x1287c312ba284DDBc6f7506F38382428174CAb14,
            0x8c21c7a7ec0190636EF181a50C2E30C55c263ed3,
            0x19638BaEF31DAB2774F857D1a50194e41B1E71b2,
            0xC9B2578DF7f96323927eF5D71e100a847FC998Db
        ];
        for (uint256 i; i < 4; i++) assertEq(IMintable20(real[i]).totalSupply(), 0, "real L1-mintable supply 0");
    }

    // ============================================================================ (c) ERC721

    /// T3-C1: fake L2 NFT claiming remoteToken() = honest L1 collection N makes the deployed L2ERC721Bridge
    /// emit finalizeBridgeERC721(N, fake, ...) for an escrowed tokenId. L1ERC721Bridge 2.9.1 rejects it
    /// (deposits[N][fake][id] == false); the escrow and the NFT stay. The legitimate L2 burn releases the NFT
    /// to exactly the `_to` the L2 burn designated. Attacker re-bridging the escrowed id from L1 reverts.
    function test_C1_erc721_identityAndRecipient() public {
        vm.selectFork(l1);
        StdERC721 N = new StdERC721();
        vm.selectFork(l2);
        address HN = L2F721.createOptimismMintableERC721(address(N), "N", "N");
        vm.selectFork(l1);
        N.mint(HONEST, 7);
        vm.startPrank(HONEST, HONEST);
        N.approve(address(L1NB), 7);
        L1NB.bridgeERC721To(address(N), HN, HONEST, 7, 200_000, "");
        vm.stopPrank();
        assertTrue(L1NB.deposits(address(N), HN, 7));
        assertEq(N.ownerOf(7), address(L1NB));
        // Attacker cannot re-key the escrowed id under his own remote from L1.
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert();
        L1NB.bridgeERC721To(address(N), address(0xBEEF), ATTACKER, 7, 200_000, "");

        // L2: attacker fake + honest L2 round trip (deposit effect replayed: bridge mints HN#7 to HONEST).
        vm.selectFork(l2);
        address fake = address(new FakeNFT(address(N), ATTACKER));
        vm.recordLogs();
        vm.prank(ATTACKER, ATTACKER);
        L2NB.bridgeERC721To(fake, address(N), ATTACKER, 7, 200_000, "");
        WithdrawalTransaction memory wFake = _captureWithdrawal();
        // Attacker cannot act on HN#7 he does not own.
        vm.prank(address(L2NB));
        IMintable721(HN).safeMint(HONEST, 7); // HARNESS: effect of the honest L1->L2 deposit on L2
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert();
        L2NB.bridgeERC721To(HN, address(N), ATTACKER, 7, 200_000, "");
        address DEST = address(0xDE57);
        vm.recordLogs();
        vm.prank(HONEST, HONEST);
        L2NB.bridgeERC721To(HN, address(N), DEST, 7, 200_000, "");
        WithdrawalTransaction memory wHonest = _captureWithdrawal();

        vm.selectFork(l1);
        (bool d, bool f) = _finalizeOnL1(wFake);
        assertFalse(d);
        assertTrue(f, "fake NFT withdrawal fails on L1");
        assertFalse(_replay(wFake, ATTACKER));
        assertEq(N.ownerOf(7), address(L1NB), "NFT still escrowed");
        assertTrue(L1NB.deposits(address(N), HN, 7));
        (bool d2,) = _finalizeOnL1(wHonest);
        assertTrue(d2, "honest burn releases");
        assertEq(N.ownerOf(7), DEST, "released only to the L2-designated recipient");
        assertFalse(L1NB.deposits(address(N), HN, 7));
        // Second release of the same burn impossible: portal hash finalized, messenger successful.
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert();
        PORTAL.finalizeWithdrawalTransactionExternalProof(wHonest, SUB);
    }

    /// T3-C2: real escrow sample — direct finalize by anyone but the L1CDM/L2ERC721Bridge pair reverts on the
    /// deployed L1ERC721Bridge, and a real escrow key (largest collection on the bridge) reads true; an
    /// attacker-keyed variant of the same (local,id) reads false. Pure reads + one reverting call to the bridge.
    function test_C2_realEscrow_flags_and_auth() public {
        vm.selectFork(l1);
        address local = 0xE42caD6fC883877A76A26A16ed92444ab177E306;
        address remote = 0x899eDc47D67CdaecEF9676632b35491e73482AEe;
        // first outstanding id of this pair from the census (evidence/attack-wave/T3/erc721-census.json)
        uint256 id = vm.envOr("T3_NFT_ID", uint256(24900));
        if (id != 0) {
            assertTrue(L1NB.deposits(local, remote, id), "real escrow flag");
            assertFalse(L1NB.deposits(local, address(0xBEEF), id), "other remote key false");
        }
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert(bytes("ERC721Bridge: function can only be called from the other bridge"));
        L1NB.finalizeBridgeERC721(local, remote, ATTACKER, ATTACKER, id, "");
        // As the messenger outside a relay, xDomainMessageSender is the default and the getter reverts.
        vm.prank(address(L1CDM));
        vm.expectRevert(bytes("CrossDomainMessenger: xDomainMessageSender is not set"));
        L1NB.finalizeBridgeERC721(local, remote, ATTACKER, ATTACKER, id, "");
    }

    // ============================================================================ (d) U21 differential

    /// T3-D1: the same attacker-generated L2 withdrawals (fake ERC20, fake NFT) and the same honest ones are
    /// finalized on N-1 (L1CDM 2.11.1) and on the post-U21 pin (L1CDM 2.13.0). Outcome classes are identical
    /// (bridges are byte-identical; only messenger gas constants changed).
    function test_D1_u21_differential_sameOutcomes() public {
        uint256[2] memory forks = [l1pre, l1];
        bool[4][2] memory out;
        for (uint256 fi; fi < 2; fi++) {
            vm.selectFork(forks[fi]);
            emit log_named_string("L1CDM", L1CDM.version());
            StdERC20 X = new StdERC20();
            StdERC721 N = new StdERC721();
            uint256 l2snap;
            vm.selectFork(l2);
            l2snap = vm.snapshotState();
            address HL2 = L2F20.createOptimismMintableERC20(address(X), "X", "X");
            address HN = L2F721.createOptimismMintableERC721(address(N), "N", "N");
            address fake20 = address(new FakeMintable(address(X)));
            address fakeN = address(new FakeNFT(address(N), ATTACKER));
            vm.prank(address(L2SB));
            IMintable20(HL2).mint(HONEST, 100); // HARNESS: deposit effect on L2
            vm.prank(address(L2NB));
            IMintable721(HN).safeMint(HONEST, 9);
            WithdrawalTransaction[4] memory ws;
            vm.recordLogs();
            vm.prank(ATTACKER, ATTACKER);
            L2SB.bridgeERC20To(fake20, address(X), ATTACKER, 100, 200_000, "");
            ws[0] = _captureWithdrawal();
            vm.recordLogs();
            vm.prank(ATTACKER, ATTACKER);
            L2NB.bridgeERC721To(fakeN, address(N), ATTACKER, 9, 200_000, "");
            ws[1] = _captureWithdrawal();
            vm.recordLogs();
            vm.prank(HONEST, HONEST);
            L2SB.bridgeERC20To(HL2, address(X), HONEST, 100, 200_000, "");
            ws[2] = _captureWithdrawal();
            vm.recordLogs();
            vm.prank(HONEST, HONEST);
            L2NB.bridgeERC721To(HN, address(N), HONEST, 9, 200_000, "");
            ws[3] = _captureWithdrawal();
            vm.revertToState(l2snap);

            vm.selectFork(forks[fi]);
            X.mint(HONEST, 100);
            N.mint(HONEST, 9);
            vm.startPrank(HONEST, HONEST);
            X.approve(address(L1SB), type(uint256).max);
            L1SB.depositERC20To(address(X), HL2, HONEST, 100, 200_000, "");
            N.approve(address(L1NB), 9);
            L1NB.bridgeERC721To(address(N), HN, HONEST, 9, 200_000, "");
            vm.stopPrank();
            for (uint256 i; i < 4; i++) {
                (bool d,) = _finalizeOnL1(ws[i]);
                out[fi][i] = d;
            }
            assertEq(X.balanceOf(HONEST), 100);
            assertEq(N.ownerOf(9), HONEST);
        }
        for (uint256 i; i < 4; i++) assertEq(out[0][i], out[1][i], "same outcome pre/post U21");
        assertFalse(out[1][0]);
        assertFalse(out[1][1]);
        assertTrue(out[1][2]);
        assertTrue(out[1][3]);
    }
    // ============================================================================ (b) factory identity

    /// T3-F1: OptimismMintableERC20Factory 1.11.0 (L1). (i) bridge() is the L1StandardBridge and the
    /// initializer cannot be re-run by anyone; (ii) a squatter who front-runs a creation gets the SAME
    /// CREATE2 address with byte-identical code and identical immutables (remote, bridge, decimals) — the
    /// honest creation then reverts, but the token identity cannot differ; (iii) REMOTE_TOKEN is immutable.
    function test_F1_factory_identity_cannotBeRebound() public {
        vm.selectFork(l1);
        (bool ok, bytes memory r) = address(L1F).staticcall(abi.encodeWithSignature("bridge()"));
        assertTrue(ok);
        assertEq(abi.decode(r, (address)), address(L1SB), "factory bridge is the L1SB");
        vm.prank(ATTACKER, ATTACKER);
        (ok,) = address(L1F).call(abi.encodeWithSignature("initialize(address)", ATTACKER));
        assertFalse(ok, "re-initialize refused");
        address remote = address(uint160(0xAb1e));
        vm.prank(ATTACKER, ATTACKER);
        address squat = L1F.createOptimismMintableERC20(remote, "Tok", "TOK");
        vm.prank(HONEST, HONEST);
        (ok,) = address(L1F).call{ gas: 10_000_000 }(abi.encodeCall(IL1Factory.createOptimismMintableERC20, (remote, "Tok", "TOK")));
        assertFalse(ok, "duplicate creation reverts (CREATE2 collision)");
        (, r) = squat.staticcall(abi.encodeWithSignature("remoteToken()"));
        assertEq(abi.decode(r, (address)), remote);
        (, r) = squat.staticcall(abi.encodeWithSignature("bridge()"));
        assertEq(abi.decode(r, (address)), address(L1SB));
        (, r) = squat.staticcall(abi.encodeWithSignature("l1Token()"));
        assertEq(abi.decode(r, (address)), remote, "legacy and new identity agree");
        (, r) = address(L1F).staticcall(abi.encodeWithSignature("deployments(address)", squat));
        assertEq(abi.decode(r, (address)), remote);
        // Same salt from any sender: the address does not depend on msg.sender.
        bytes32 salt = keccak256(abi.encode(remote, "Tok", "TOK", uint8(18)));
        emit log_named_bytes32("salt", salt);
        // No setter for the remote exists: any call to a hypothetical setter reverts.
        vm.prank(ATTACKER, ATTACKER);
        (ok,) = squat.call(abi.encodeWithSignature("setRemoteToken(address)", ATTACKER));
        assertFalse(ok);
        vm.prank(ATTACKER, ATTACKER);
        (ok,) = squat.call(abi.encodeWithSignature("mint(address,uint256)", ATTACKER, 1));
        assertFalse(ok, "only the bridge mints");
    }

    /// T3-C3: pause source of both L1 bridges is the portal's SystemConfig (no divergent pause pointer).
    function test_C3_pauseSource_consistent() public {
        vm.selectFork(l1);
        (, bytes memory a) = address(L1NB).staticcall(abi.encodeWithSignature("systemConfig()"));
        (, bytes memory b) = address(L1SB).staticcall(abi.encodeWithSignature("systemConfig()"));
        (, bytes memory c) = address(PORTAL).staticcall(abi.encodeWithSignature("systemConfig()"));
        assertEq(abi.decode(a, (address)), abi.decode(c, (address)), "ERC721 bridge pause source == portal SystemConfig");
        assertEq(abi.decode(b, (address)), abi.decode(c, (address)), "L1SB pause source == portal SystemConfig");
        (, bytes memory p1) = address(L1NB).staticcall(abi.encodeWithSignature("paused()"));
        (, bytes memory p2) = address(L1SB).staticcall(abi.encodeWithSignature("paused()"));
        assertFalse(abi.decode(p1, (bool)));
        assertFalse(abi.decode(p2, (bool)));
        emit log_named_address("systemConfig", abi.decode(c, (address)));
    }
    /// T3-D2: OLD-FORMAT object. A Bedrock-migrated legacy withdrawal carries a version-0 messenger nonce and
    /// the legacy selector finalizeERC20Withdrawal (pre-Bedrock L2 bridge format). Synthesized here in the
    /// migrated encoding (sender L2CDM -> L1CDM.relayMessage(v0 nonce, L2SB, L1SB, 0, 0, legacy call)), it is
    /// finalized pre-U21 (2.11.1) and post-U21 (2.13.0): honest pair delivers on both, fake pair fails on both.
    function test_D2_legacyFormat_prePost_sameOutcome() public {
        uint256[2] memory forks = [l1pre, l1];
        bool[2][2] memory out;
        for (uint256 fi; fi < 2; fi++) {
            vm.selectFork(forks[fi]);
            StdERC20 X = new StdERC20();
            address HL2 = address(0x1E6AC7);
            address FAKE = address(0xFA4E);
            X.mint(HONEST, 50);
            vm.startPrank(HONEST, HONEST);
            X.approve(address(L1SB), type(uint256).max);
            L1SB.depositERC20To(address(X), HL2, HONEST, 50, 200_000, "");
            vm.stopPrank();
            for (uint256 j; j < 2; j++) {
                address l2t = j == 0 ? HL2 : FAKE;
                bytes memory legacyCall =
                    abi.encodeCall(IL1SB.finalizeERC20Withdrawal, (address(X), l2t, HONEST, HONEST, 50, bytes("")));
                uint256 v0nonce = 0x7e57 + j; // version 0 (top two bytes zero)
                WithdrawalTransaction memory w;
                w.nonce = (uint256(1) << 240) | (0xd2000 + j); // portal nonce is independent of the inner one
                w.sender = L2CDM;
                w.target = address(L1CDM);
                w.value = 0;
                w.gasLimit = 1_000_000;
                w.data = abi.encodeCall(IL1CDM.relayMessage, (v0nonce, address(0x4200000000000000000000000000000000000010), address(L1SB), 0, 0, legacyCall));
                (bool d,) = _finalizeOnL1(w);
                out[fi][j] = d;
            }
            assertEq(X.balanceOf(HONEST), 50, "honest legacy-format withdrawal paid exactly once");
            assertEq(L1SB.deposits(address(X), HL2), 0);
        }
        assertTrue(out[0][0] && out[1][0], "honest legacy format delivers pre and post");
        assertTrue(!out[0][1] && !out[1][1], "fake legacy format fails pre and post");
    }
}
