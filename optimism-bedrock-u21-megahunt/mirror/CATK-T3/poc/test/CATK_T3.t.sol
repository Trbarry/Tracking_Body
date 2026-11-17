// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface IERC165Shape {
    function supportsInterface(bytes4) external view returns (bool);
}

interface ILegacyMintableERC20Shape is IERC165Shape {
    function l1Token() external view returns (address);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

interface IOptimismMintableERC20Shape is IERC165Shape {
    function remoteToken() external view returns (address);
    function bridge() external returns (address);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

interface IL1StandardBridge {
    function bridgeERC20To(address, address, address, uint256, uint32, bytes calldata) external;
    function finalizeBridgeERC20(address, address, address, address, uint256, bytes calldata) external;
    function deposits(address, address) external view returns (uint256);
}

interface IL1ERC721Bridge {
    function bridgeERC721To(address, address, address, uint256, uint32, bytes calldata) external;
    function finalizeBridgeERC721(address, address, address, address, uint256, bytes calldata) external;
    function deposits(address, address, uint256) external view returns (bool);
}

interface IMintableFactory {
    function createOptimismMintableERC20(address, string calldata, string calldata) external returns (address);
    function deployments(address) external view returns (address);
    function bridge() external view returns (address);
}

interface IFactoryToken {
    function remoteToken() external view returns (address);
    function l1Token() external view returns (address);
    function bridge() external view returns (address);
    function supportsInterface(bytes4) external view returns (bool);
}

interface IERC721ReceiverShape {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4);
}

contract ShapeToken {
    address public immutable bridge;
    address public immutable legacyRemote;
    address public immutable modernRemote;
    bool public immutable legacy;
    bool public immutable modern;
    mapping(address => uint256) public balanceOf;

    constructor(address bridge_, address legacyRemote_, address modernRemote_, bool legacy_, bool modern_) {
        bridge = bridge_;
        legacyRemote = legacyRemote_;
        modernRemote = modernRemote_;
        legacy = legacy_;
        modern = modern_;
        balanceOf[msg.sender] = 100 ether;
    }

    function supportsInterface(bytes4 id) external view returns (bool) {
        if (id == 0x01ffc9a7) return true;
        if (id == 0xffffffff) return false;
        if (id == type(ILegacyMintableERC20Shape).interfaceId) return legacy;
        if (id == type(IOptimismMintableERC20Shape).interfaceId) return modern;
        return false;
    }

    function l1Token() external view returns (address) {
        return legacyRemote;
    }

    function remoteToken() external view returns (address) {
        return modernRemote;
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == bridge, "only bridge");
        balanceOf[from] -= amount;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == bridge, "only bridge");
        balanceOf[to] += amount;
    }
}

contract PlainERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address owner, uint256 amount) {
        balanceOf[owner] = amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract PlainERC721 {
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;

    function mint(address to, uint256 id) external {
        require(ownerOf[id] == address(0), "already minted");
        ownerOf[id] = to;
    }

    function approve(address spender, uint256 id) external {
        require(ownerOf[id] == msg.sender, "not owner");
        getApproved[id] = spender;
    }

    function transferFrom(address from, address to, uint256 id) external {
        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        _transfer(from, to, id);
        if (to.code.length != 0) {
            bytes4 got = IERC721ReceiverShape(to).onERC721Received(msg.sender, from, id, "");
            require(got == IERC721ReceiverShape.onERC721Received.selector, "unsafe receiver");
        }
    }

    function _transfer(address from, address to, uint256 id) internal {
        require(ownerOf[id] == from, "wrong owner");
        require(msg.sender == from || getApproved[id] == msg.sender, "not approved");
        ownerOf[id] = to;
        delete getApproved[id];
    }
}

contract CATKT3IdentityForkTest is Test {
    IL1StandardBridge constant L1SB = IL1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    IL1ERC721Bridge constant L1NFT = IL1ERC721Bridge(0x5a7749f83b81B301cAb5f48EB8516B986DAef23D);
    IMintableFactory constant FACTORY = IMintableFactory(0x75505a97BD334E7BD3C476893285569C4136Fa0F);

    address constant REMOTE_A = address(0xA11CE);
    address constant REMOTE_B = address(0xB0B);
    address constant REMOTE_C = address(0xCAFE);
    uint32 constant MIN_GAS = 200_000;

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26_433_900);
    }

    function test_interfaceMatrix_dualInterfaceUsesLegacyIdentity() public {
        assertEq(type(ILegacyMintableERC20Shape).interfaceId, bytes4(0x1d1d8b63));
        ShapeToken token = new ShapeToken(address(L1SB), REMOTE_A, REMOTE_B, true, true);

        vm.expectRevert(bytes("StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"));
        L1SB.bridgeERC20To(address(token), REMOTE_B, address(this), 7 ether, MIN_GAS, "");

        L1SB.bridgeERC20To(address(token), REMOTE_A, address(this), 7 ether, MIN_GAS, "");
        assertEq(token.balanceOf(address(this)), 93 ether);
    }

    function test_interfaceMatrix_legacyOnlyAndModernOnlyAreDisjoint() public {
        ShapeToken legacy = new ShapeToken(address(L1SB), REMOTE_A, REMOTE_B, true, false);
        ShapeToken modern = new ShapeToken(address(L1SB), REMOTE_A, REMOTE_B, false, true);

        vm.expectRevert(bytes("StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"));
        L1SB.bridgeERC20To(address(legacy), REMOTE_B, address(this), 1 ether, MIN_GAS, "");
        L1SB.bridgeERC20To(address(legacy), REMOTE_A, address(this), 1 ether, MIN_GAS, "");

        vm.expectRevert(bytes("StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"));
        L1SB.bridgeERC20To(address(modern), REMOTE_A, address(this), 1 ether, MIN_GAS, "");
        L1SB.bridgeERC20To(address(modern), REMOTE_B, address(this), 1 ether, MIN_GAS, "");

        assertEq(legacy.balanceOf(address(this)), 99 ether);
        assertEq(modern.balanceOf(address(this)), 99 ether);
    }

    function test_nonMintableAccounting_isIsolatedByExactRemoteAddress() public {
        PlainERC20 token = new PlainERC20(address(this), 100 ether);
        token.approve(address(L1SB), type(uint256).max);

        uint256 a0 = L1SB.deposits(address(token), REMOTE_A);
        uint256 b0 = L1SB.deposits(address(token), REMOTE_B);
        L1SB.bridgeERC20To(address(token), REMOTE_A, address(this), 11 ether, MIN_GAS, "");
        L1SB.bridgeERC20To(address(token), REMOTE_B, address(this), 13 ether, MIN_GAS, "");

        assertEq(L1SB.deposits(address(token), REMOTE_A), a0 + 11 ether);
        assertEq(L1SB.deposits(address(token), REMOTE_B), b0 + 13 ether);
        assertEq(L1SB.deposits(address(token), REMOTE_C), 0);

        vm.expectRevert();
        L1SB.finalizeBridgeERC20(address(token), REMOTE_A, address(this), address(this), 1 ether, "");
        assertEq(L1SB.deposits(address(token), REMOTE_A), a0 + 11 ether);
    }

    function test_factory_sameRemoteCreatesDistinctImmutableIdentities() public {
        assertEq(FACTORY.bridge(), address(L1SB));
        address first = FACTORY.createOptimismMintableERC20(REMOTE_A, "Representation A", "rA");
        address second = FACTORY.createOptimismMintableERC20(REMOTE_A, "Representation B", "rB");

        assertTrue(first != second);
        assertEq(FACTORY.deployments(first), REMOTE_A);
        assertEq(FACTORY.deployments(second), REMOTE_A);
        assertEq(IFactoryToken(first).remoteToken(), REMOTE_A);
        assertEq(IFactoryToken(first).l1Token(), REMOTE_A);
        assertEq(IFactoryToken(first).bridge(), address(L1SB));
        assertEq(IFactoryToken(second).remoteToken(), REMOTE_A);
        assertTrue(IFactoryToken(first).supportsInterface(type(ILegacyMintableERC20Shape).interfaceId));
        assertTrue(IFactoryToken(first).supportsInterface(type(IOptimismMintableERC20Shape).interfaceId));

        (bool rebound,) = first.call(abi.encodeWithSignature("setRemoteToken(address)", REMOTE_B));
        assertFalse(rebound);
        assertEq(IFactoryToken(first).remoteToken(), REMOTE_A);

        (bool duplicate,) = address(FACTORY).call{gas: 5_000_000}(
            abi.encodeCall(IMintableFactory.createOptimismMintableERC20, (REMOTE_A, "Representation A", "rA"))
        );
        assertFalse(duplicate, "same CREATE2 tuple must collide");
    }

    function test_erc721Deposit_isIsolatedByExactPairAndTokenId() public {
        PlainERC721 nft = new PlainERC721();
        nft.mint(address(this), 42);
        nft.mint(address(this), 43);
        nft.approve(address(L1NFT), 42);
        nft.approve(address(L1NFT), 43);

        L1NFT.bridgeERC721To(address(nft), REMOTE_A, address(0xD00D), 42, MIN_GAS, "");
        L1NFT.bridgeERC721To(address(nft), REMOTE_B, address(0xD00D), 43, MIN_GAS, "");

        assertEq(nft.ownerOf(42), address(L1NFT));
        assertEq(nft.ownerOf(43), address(L1NFT));
        assertTrue(L1NFT.deposits(address(nft), REMOTE_A, 42));
        assertTrue(L1NFT.deposits(address(nft), REMOTE_B, 43));
        assertFalse(L1NFT.deposits(address(nft), REMOTE_B, 42));
        assertFalse(L1NFT.deposits(address(nft), REMOTE_A, 43));

        vm.expectRevert();
        L1NFT.finalizeBridgeERC721(address(nft), REMOTE_A, address(this), address(this), 42, "");
        assertTrue(L1NFT.deposits(address(nft), REMOTE_A, 42));
    }
}

contract CATKT3FakeL2ForkTest is Test {
    IL1StandardBridge constant L1SB = IL1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    IL1StandardBridge constant L2SB = IL1StandardBridge(0x4200000000000000000000000000000000000010);
    IMintableFactory constant L2FACTORY = IMintableFactory(0x4200000000000000000000000000000000000012);
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant L2_USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    uint32 constant MIN_GAS = 200_000;

    function test_fakeL2Tokens_allInterfaceShapesRemainPairIsolatedOnL1() public {
        vm.createSelectFork("l2");
        ShapeToken dual = new ShapeToken(address(L2SB), USDT, WBTC, true, true);
        ShapeToken legacy = new ShapeToken(address(L2SB), USDT, WBTC, true, false);
        ShapeToken modern = new ShapeToken(address(L2SB), WBTC, USDT, false, true);

        vm.expectRevert(bytes("StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"));
        L2SB.bridgeERC20To(address(dual), WBTC, address(this), 1 ether, MIN_GAS, "");
        L2SB.bridgeERC20To(address(dual), USDT, address(this), 1 ether, MIN_GAS, "");
        L2SB.bridgeERC20To(address(legacy), USDT, address(this), 1 ether, MIN_GAS, "");
        L2SB.bridgeERC20To(address(modern), USDT, address(this), 1 ether, MIN_GAS, "");

        address dualAddress = address(dual);
        address legacyAddress = address(legacy);
        address modernAddress = address(modern);
        vm.createSelectFork("l1");

        assertGt(L1SB.deposits(USDT, L2_USDT), 0, "canonical pair has real escrow");
        assertEq(L1SB.deposits(USDT, dualAddress), 0, "fake dual-interface pair has none");
        assertEq(L1SB.deposits(USDT, legacyAddress), 0, "fake legacy-interface pair has none");
        assertEq(L1SB.deposits(USDT, modernAddress), 0, "fake modern-interface pair has none");
    }

    function test_l2FactoryTokens_haveImmutableIdentityButNoCanonicalPairEscrow() public {
        vm.createSelectFork("l2");
        assertEq(L2FACTORY.bridge(), address(L2SB));
        address first = L2FACTORY.createOptimismMintableERC20(USDT, "Fake USDT A", "fUSDT-A");
        address second = L2FACTORY.createOptimismMintableERC20(USDT, "Fake USDT B", "fUSDT-B");
        assertTrue(first != second);
        assertEq(IFactoryToken(first).remoteToken(), USDT);
        assertEq(IFactoryToken(first).l1Token(), USDT);
        assertEq(IFactoryToken(first).bridge(), address(L2SB));
        assertEq(IFactoryToken(second).remoteToken(), USDT);

        (bool unauthorizedMint,) = first.call(abi.encodeWithSignature("mint(address,uint256)", address(this), 1));
        assertFalse(unauthorizedMint, "attacker cannot mint factory token");

        vm.createSelectFork("l1");
        assertGt(L1SB.deposits(USDT, L2_USDT), 0);
        assertEq(L1SB.deposits(USDT, first), 0);
        assertEq(L1SB.deposits(USDT, second), 0);
    }
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

interface IPortalT3 {
    function proveWithdrawalTransaction(
        WithdrawalTransaction memory,
        uint256,
        OutputRootProof calldata,
        bytes[] calldata
    ) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function checkWithdrawal(bytes32, address) external view;
    function version() external view returns (string memory);
}

interface IDisputeGameFactoryT3 {
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface IDisputeGameT3 {
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function maxClockDuration() external view returns (uint64);
    function claimDataLen() external view returns (uint256);
    function resolvedSubgames(uint256) external view returns (bool);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function rootClaimByChainId(uint256) external view returns (bytes32);
}

interface IERC721Owner {
    function ownerOf(uint256) external view returns (address);
}

interface IERC20Balance {
    function balanceOf(address) external view returns (uint256);
}

interface IMessengerStatus {
    function successfulMessages(bytes32) external view returns (bool);
}

contract CATKT3InFlightNFTForkTest is Test {
    IPortalT3 constant PORTAL = IPortalT3(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IDisputeGameFactoryT3 constant DGF = IDisputeGameFactoryT3(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IMessengerStatus constant L1CDM = IMessengerStatus(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    IL1ERC721Bridge constant L1NFT = IL1ERC721Bridge(0x5a7749f83b81B301cAb5f48EB8516B986DAef23D);
    IL1StandardBridge constant L1SB = IL1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    address constant NFT = 0x932261f9Fc8DA46C4a22e31B45c4De60623848bF;
    address constant REMOTE_NFT = 0x779f253e1A039D24D916a44b84FDf52A4CdB9959;
    address constant COMMITTED_RECIPIENT = 0x1129DA039E16dA3a06F7a76076F7f1a2B9B8b3ec;
    uint256 constant TOKEN_ID = 36_383;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant L2_USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
    address constant LEGACY_RECIPIENT = 0x3CFFb70E70E78912581e90D81E6345640c1F4dFE;
    uint256 constant LEGACY_AMOUNT = 100_000_000;
    bytes32 constant LEGACY_V1_HASH = 0x521bb1f5bbe3e20d944306f991a3cfb81d9335c81824f0badf2674266dbb093e;
    uint256 constant GAME_INDEX = 21_377;
    address constant SUBMITTER = address(0x7103);
    address constant FINALIZER = address(0x7104);

    function _load(string memory fixture)
        internal
        view
        returns (
            WithdrawalTransaction memory w,
            OutputRootProof memory orp,
            bytes[] memory proof,
            bytes32 h,
            address game
        )
    {
        string memory base = string.concat(vm.projectRoot(), "/test/fixtures/");
        string memory o = vm.readFile(string.concat(base, "nft-output-pre-u21.json"));
        orp = OutputRootProof(
            vm.parseJsonBytes32(o, ".version"),
            vm.parseJsonBytes32(o, ".stateRoot"),
            vm.parseJsonBytes32(o, ".messagePasserStorageRoot"),
            vm.parseJsonBytes32(o, ".latestBlockhash")
        );
        string memory j = vm.readFile(string.concat(base, fixture));
        w = WithdrawalTransaction(
            vm.parseUint(vm.parseJsonString(j, ".nonce")),
            vm.parseJsonAddress(j, ".sender"),
            vm.parseJsonAddress(j, ".target"),
            vm.parseUint(vm.parseJsonString(j, ".value")),
            vm.parseUint(vm.parseJsonString(j, ".gasLimit")),
            vm.parseJsonBytes(j, ".data")
        );
        proof = vm.parseJsonBytesArray(j, ".proof");
        h = keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
        assertEq(h, vm.parseJsonBytes32(j, ".withdrawalHash"));
        (,, game) = DGF.gameAtIndex(GAME_INDEX);
        assertEq(game, vm.parseJsonAddress(o, ".game"));
        assertEq(
            IDisputeGameT3(game).rootClaimByChainId(10),
            keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash))
        );
    }

    function _resolve(address game) internal {
        IDisputeGameT3 g = IDisputeGameT3(game);
        if (g.status() != 0) return;
        uint256 ready = uint256(g.createdAt()) + 2 * uint256(g.maxClockDuration()) + 1;
        if (block.timestamp < ready) vm.warp(ready);
        for (uint256 i = g.claimDataLen(); i > 0; i--) {
            if (!g.resolvedSubgames(i - 1)) g.resolveClaim(i - 1, 0);
        }
        assertEq(g.resolve(), 2, "honest game must resolve DEFENDER_WINS");
    }

    function _finalizeOn(string memory forkAlias, string memory expectedVersion) internal {
        vm.createSelectFork(forkAlias);
        assertEq(PORTAL.version(), expectedVersion);
        (WithdrawalTransaction memory w, OutputRootProof memory orp, bytes[] memory proof, bytes32 h, address game) =
            _load("nft-inflight.json");

        assertFalse(PORTAL.finalizedWithdrawals(h));
        assertTrue(L1NFT.deposits(NFT, REMOTE_NFT, TOKEN_ID));
        assertEq(IERC721Owner(NFT).ownerOf(TOKEN_ID), address(L1NFT));

        vm.prank(SUBMITTER, SUBMITTER);
        PORTAL.proveWithdrawalTransaction(w, GAME_INDEX, orp, proof);
        _resolve(game);
        uint256 proofReady = block.timestamp + PORTAL.proofMaturityDelaySeconds() + 1;
        uint256 gameReady = uint256(IDisputeGameT3(game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
        vm.warp(proofReady > gameReady ? proofReady : gameReady);
        PORTAL.checkWithdrawal(h, SUBMITTER);

        vm.prank(FINALIZER, FINALIZER);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertFalse(L1NFT.deposits(NFT, REMOTE_NFT, TOKEN_ID));
        assertEq(IERC721Owner(NFT).ownerOf(TOKEN_ID), COMMITTED_RECIPIENT);
        assertFalse(L1NFT.deposits(NFT, address(0xBAD), TOKEN_ID));

        vm.prank(FINALIZER, FINALIZER);
        vm.expectRevert();
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, SUBMITTER);
    }

    function _finalizeLegacyERC20On(string memory forkAlias, string memory expectedVersion) internal {
        vm.createSelectFork(forkAlias);
        assertEq(PORTAL.version(), expectedVersion);
        (WithdrawalTransaction memory w, OutputRootProof memory orp, bytes[] memory proof, bytes32 h, address game) =
            _load("erc20-legacy-inflight.json");

        uint256 escrowBefore = L1SB.deposits(USDT, L2_USDT);
        uint256 recipientBefore = IERC20Balance(USDT).balanceOf(LEGACY_RECIPIENT);
        assertFalse(PORTAL.finalizedWithdrawals(h));
        assertFalse(L1CDM.successfulMessages(LEGACY_V1_HASH));

        vm.prank(SUBMITTER, SUBMITTER);
        PORTAL.proveWithdrawalTransaction(w, GAME_INDEX, orp, proof);
        _resolve(game);
        uint256 proofReady = block.timestamp + PORTAL.proofMaturityDelaySeconds() + 1;
        uint256 gameReady = uint256(IDisputeGameT3(game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
        vm.warp(proofReady > gameReady ? proofReady : gameReady);
        PORTAL.checkWithdrawal(h, SUBMITTER);

        vm.prank(FINALIZER, FINALIZER);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertTrue(L1CDM.successfulMessages(LEGACY_V1_HASH));
        assertEq(L1SB.deposits(USDT, L2_USDT), escrowBefore - LEGACY_AMOUNT);
        assertEq(IERC20Balance(USDT).balanceOf(LEGACY_RECIPIENT), recipientBefore + LEGACY_AMOUNT);

        vm.prank(FINALIZER, FINALIZER);
        vm.expectRevert();
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, SUBMITTER);
    }

    function test_preU21_inFlightERC721_deliversCommittedRecipientOnce() public {
        _finalizeOn("l1pre", "5.8.0");
    }

    function test_postU21_sameInFlightERC721_deliversCommittedRecipientOnce() public {
        _finalizeOn("l1", "6.1.0");
    }

    function test_preU21_legacyERC20Wrapper_debitsExactPairOnce() public {
        _finalizeLegacyERC20On("l1pre", "5.8.0");
    }

    function test_postU21_sameLegacyERC20Wrapper_debitsExactPairOnce() public {
        _finalizeLegacyERC20On("l1", "6.1.0");
    }
}
