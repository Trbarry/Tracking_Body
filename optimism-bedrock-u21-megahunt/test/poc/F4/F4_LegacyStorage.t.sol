// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// F4 — Storage and initializer historian. Fork tests against the REAL deployed bytecode at L1 block 26433900
// (rpc alias `l1`). Stresses PASS A closures C1/C2 with PRE-v7 history that the lane-02 junk test did not cover:
//   * real legacy `provenWithdrawals` entries (portal v1, slot-52 single-level mapping, {outputRoot,timestamp,l2OutputIndex})
//   * legacy MAPPING ENTRIES and semantic "poison" values (paused = 1, reentrancy status = 2, blocked/relayed = 1,
//     blacklisted = 1, guardian = attacker) written into every slot that held a different meaning before v7.
// Nothing is broadcast. No privileged prank is used.
import "./Base.sol";

interface ISysCfgF4 {
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function optimismMintableERC20Factory() external view returns (address);
    function optimismPortal() external view returns (address);
    function delayedWETH() external view returns (address);
    function superchainConfig() external view returns (address);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function scalar() external view returns (uint256);
    function basefeeScalar() external view returns (uint32);
    function blobbasefeeScalar() external view returns (uint32);
    function gasLimit() external view returns (uint64);
    function batcherHash() external view returns (bytes32);
    function startBlock() external view returns (uint256);
    function unsafeBlockSigner() external view returns (address);
    function guardian() external view returns (address);
    function eip1559Denominator() external view returns (uint32);
    function eip1559Elasticity() external view returns (uint32);
}

interface IPortalF4 {
    function paused() external view returns (bool);
    function guardian() external view returns (address);
    function superchainConfig() external view returns (address);
    function systemConfig() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function respectedGameTypeUpdatedAt() external view returns (uint64);
    function disputeGameBlacklist(address) external view returns (bool);
    function ethLockbox() external view returns (address);
}

interface ICdmF4 {
    function paused() external view returns (bool);
    function portal() external view returns (address);
    function PORTAL() external view returns (address);
    function systemConfig() external view returns (address);
    function otherMessenger() external view returns (address);
    function OTHER_MESSENGER() external view returns (address);
    function messageNonce() external view returns (uint256);
    function superchainConfig() external view returns (address);
    function proxyAdmin() external view returns (address);
    function sendMessage(address, bytes calldata, uint32) external payable;
}

interface IBridgeF4 {
    function paused() external view returns (bool);
    function messenger() external view returns (address);
    function MESSENGER() external view returns (address);
    function otherBridge() external view returns (address);
    function OTHER_BRIDGE() external view returns (address);
    function systemConfig() external view returns (address);
    function superchainConfig() external view returns (address);
    function depositETH(uint32, bytes calldata) external payable;
    function proxyAdmin() external view returns (address);
}

interface IScF4 {
    function paused() external view returns (bool);
    function paused(address) external view returns (bool);
    function guardian() external view returns (address);
}

interface IFactoryF4 {
    function bridge() external view returns (address);
    function BRIDGE() external view returns (address);
}

contract F4LegacyStorageTest is Base {
    ISysCfgF4 constant SC = ISysCfgF4(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    address constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address constant L1ERC721 = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
    address constant FACTORY = 0x75505a97BD334E7BD3C476893285569C4136Fa0F;
    address constant L2OO = 0xdfe97868233d1aa22e815a266982f2cf17685a27;

    struct Legacy {
        bytes32 hash;
        bool finalized;
        uint256 l2OutputIndex;
        uint256 timestamp;
    }

    Legacy[] internal legacy;

    function L(bytes32 h, bool f, uint256 idx, uint256 ts) internal {
        legacy.push(Legacy(h, f, idx, ts));
    }

    function setUp() public {
        _fork();
        // 12 never-finalized + 12 finalized withdrawals first proven under OptimismPortal v1 (1.6.0 / 2.4.0 / 2.5.0),
        // sampled from the full event census evidence/F4/op-portal-withdrawal-events.jsonl
        // (hash, finalized?, l2OutputIndex, proof timestamp as read from the live legacy slot at block 26433900)
        L(hex"b27dc0397cea37ce9e3d3aaeb8e60be9c472ca41276e55767a62b790d1409cb3", false, 852, 1689146939);
        L(hex"d9e5b3abe4dc8b2f74508ad640c52f790a19a00c208fd06d87d68f6c4aacc62f", false, 1291, 1690723727);
        L(hex"4e7f268e901ccd097084dca0af56011528ce59c961847066e0a5b643d802d643", false, 406, 1687537583);
        L(hex"ba50a930a9503720e7f21d6e3db2a2edbe27440ee101d3bab3f7cfaa325c30c7", false, 4342, 1701710939);
        L(hex"49369694d163e70876a8a8f871de242cb41d698d99942b0b5d491153d218c66d", false, 1967, 1693157327);
        L(hex"24fb55798d5f171937c382e1abf547130b3afde2a9db71eb57c7cc6f8d486a7b", false, 2533, 1695195023);
        L(hex"7b478fb885dc8d83e824287fb1607b2d70b6a2932a6a861db0bbfb113988874e", false, 577, 1688153183);
        L(hex"ace9243c6d217fb5c54d2b5cbcf44997db7e3491a2a87e83d765734c60d7328a", false, 360, 1687371995);
        L(hex"5cdb2b1908de957003d7f0b6e36e5a11e5a2be5a67dca3b7b8f7078858bbb42a", false, 275, 1687065995);
        L(hex"78ae454df1e4e22065cd5c8872c5cedd5fc0e6041fa00a61d79ede402c93fe4a", false, 67, 1686317183);
        L(hex"a3357d419c111eca4635bde46541b20d8a8564ce8da93775c4ab338c77b9e614", false, 0, 1693292375);
        L(hex"517471fbcc1de704764513b158ed7cefe093e48c996f1398be83cbd85be772d4", false, 3038, 1697016539);
        L(hex"8455065d52473e8b75d57d4b1d323305ca396c7ec71d94bf36957943534f38ae", true, 2276, 1695210599);
        L(hex"5bfecdf3c28cb5e492c85a40e77169b59bc18ac039925c6daec7d1cad6e92a7b", true, 6363, 1708982099);
        L(hex"0447db17e4f22dec6ec4c33b18d55a52301a0041924c4f06518e4efe311c8ddb", true, 6034, 1707801335);
        L(hex"4d421fbd252f4d124cf3dcc3eaa02e581a49430dc3349d80e94a27ef19407bde", true, 504, 1687888451);
        L(hex"7a17dd209b86adb5ee66681f083cb60aa7cb19d71be7bf94f66b3fcea31751e7", true, 2065, 1693563491);
        L(hex"9a1774a4f719da629c00a7dfb3ea07a9acf8369e513ac3bccb1296a535040cff", true, 4226, 1701495059);
        L(hex"a5397ffa46f6df7162d9e649648474cfa49b02b23863f6646f4d124d0e235a9f", true, 4416, 1701971579);
        L(hex"088a95865e1aec87074a6b0cef2483b6f51d91f4b2ff2158fe94c67653d40164", true, 3058, 1697088227);
        L(hex"55e8dd4addc4d9f06978a549243b96fc5f8618c9055fb42fe09f730be68c31e5", true, 6164, 1708264271);
        L(hex"8949e385a8749be6f6bfc90cd200d3c17f828bd090267da2d44d72e11dc41fdb", true, 1612, 1691877179);
        L(hex"74357c8c092b63582f894bba9631af69a487f520b96c6717840ea7374b542760", true, 1037, 1689807671);
        L(hex"304ed9eef347a7606edae9ea57cab5578430e6b4210718f0ff86c5f64513ffb2", true, 7102, 1711641611);
    }

    // ---------------------------------------------------------------------------------------------------------------
    // 1. Legacy slot-52 `provenWithdrawals` entries still exist and no v9 portal entry point reads them.
    // ---------------------------------------------------------------------------------------------------------------
    bytes4 constant UNPROVEN = bytes4(keccak256("OptimismPortal_Unproven()"));
    bytes4 constant FINALIZED = bytes4(keccak256("OptimismPortal_AlreadyFinalized()"));

    function _probe(bytes32 h, bool fin, address who) internal {
        (address g, uint64 ts) = PORTAL.provenWithdrawals(h, who);
        assertEq(g, address(0));
        assertEq(ts, 0);
        (bool ok1, bytes memory r1) = address(PORTAL).call(abi.encodeWithSelector(IPortal.checkWithdrawal.selector, h, who));
        assertFalse(ok1);
        assertEq(bytes4(r1), fin ? FINALIZED : UNPROVEN, "checkWithdrawal revert reason");
        (bool ok2, bytes memory r2) =
            address(PORTAL).call(abi.encodeWithSelector(IPortal.deleteProvenWithdrawal.selector, h, who));
        assertFalse(ok2);
        assertEq(bytes4(r2), UNPROVEN, "deleteProvenWithdrawal must revert Unproven on a legacy-only proof");
    }

    function _legacyEntry(Legacy memory e) internal view returns (bytes32 s52) {
        s52 = keccak256(abi.encode(e.hash, uint256(52)));
        bytes32 w0 = vm.load(address(PORTAL), s52);
        bytes32 w1 = vm.load(address(PORTAL), bytes32(uint256(s52) + 1));
        // the legacy struct {bytes32 outputRoot; uint128 timestamp; uint128 l2OutputIndex} is still in storage
        assertTrue(w0 != bytes32(0), "legacy outputRoot gone");
        assertEq(uint256(uint128(uint256(w1))), e.timestamp, "legacy timestamp");
        assertEq(uint256(w1) >> 128, e.l2OutputIndex, "legacy l2OutputIndex");
        // the legacy output root equals what the (still deployed) L2OutputOracle holds at that index
        (bool ok, bytes memory ret) = L2OO.staticcall(abi.encodeWithSignature("getL2Output(uint256)", e.l2OutputIndex));
        assertTrue(ok, "L2OO.getL2Output");
        (bytes32 root,,) = abi.decode(ret, (bytes32, uint128, uint128));
        assertEq(root, w0, "legacy entry points at a real L2OO output");
    }

    function test_legacyProvenEntriesExistButAreUnreachable() public {
        for (uint256 i; i < legacy.length; i++) {
            Legacy memory e = legacy[i];
            bytes32 s52 = _legacyEntry(e);
            vm.record();
            assertEq(PORTAL.finalizedWithdrawals(e.hash), e.finalized, "finalized flag (slot 51 never moved)");
            assertEq(PORTAL.numProofSubmitters(e.hash), 0, "no v9 submitter for a legacy-only proof");
            _probe(e.hash, e.finalized, address(this));
            _probe(e.hash, e.finalized, address(0xdEaD));
            _probe(e.hash, e.finalized, 0x4200000000000000000000000000000000000007);
            (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(PORTAL));
            assertEq(writes.length, 0, "no write");
            assertGt(reads.length, 0, "accesses recorded");
            for (uint256 r; r < reads.length; r++) {
                assertTrue(reads[r] != s52 && reads[r] != bytes32(uint256(s52) + 1), "v9 read a legacy slot-52 entry");
                assertTrue(uint256(reads[r]) != 52, "v9 read slot 52");
            }
        }
    }

    // ---------------------------------------------------------------------------------------------------------------
    // 2. Differential: poison every slot that had another meaning before v7, then run a REAL withdrawal
    //    (portal -> lockbox -> L1CDM.relayMessage -> L1StandardBridge.finalizeBridgeETH) and a bridge deposit.
    // ---------------------------------------------------------------------------------------------------------------
    struct Outcome {
        bytes32 getters;
        uint256 lockboxDelta;
        uint256 recipientGain;
        bool finalized;
        bool relayed;
        bool failed;
        uint256 depositLockboxGain;
        uint256 nonceAfter;
    }

    function _gPortal() internal view returns (bytes32 h) {
        IPortalF4 p = IPortalF4(address(PORTAL));
        h = keccak256(abi.encode(p.paused(), p.guardian(), p.superchainConfig(), p.systemConfig(), p.anchorStateRegistry()));
        h = keccak256(abi.encode(h, p.disputeGameFactory(), p.respectedGameType(), p.respectedGameTypeUpdatedAt()));
        h = keccak256(abi.encode(h, p.ethLockbox(), PORTAL.l2Sender()));
    }

    function _gCdm() internal view returns (bytes32 h) {
        ICdmF4 m = ICdmF4(address(L1CDM));
        h = keccak256(abi.encode(m.paused(), m.portal(), m.PORTAL(), m.systemConfig(), m.otherMessenger()));
        h = keccak256(abi.encode(h, m.OTHER_MESSENGER(), m.superchainConfig(), m.proxyAdmin(), m.messageNonce()));
    }

    function _gBridges() internal view returns (bytes32 h) {
        IBridgeF4 b = IBridgeF4(BRIDGE);
        IBridgeF4 n = IBridgeF4(L1ERC721);
        h = keccak256(abi.encode(b.paused(), b.messenger(), b.MESSENGER(), b.otherBridge(), b.OTHER_BRIDGE()));
        h = keccak256(abi.encode(h, b.systemConfig(), b.superchainConfig(), b.proxyAdmin()));
        h = keccak256(abi.encode(h, n.paused(), n.messenger(), n.otherBridge(), n.systemConfig()));
        h = keccak256(abi.encode(h, IFactoryF4(FACTORY).bridge(), IFactoryF4(FACTORY).BRIDGE()));
    }

    function _gConfigs() internal view returns (bytes32 h) {
        IScF4 s = IScF4(SUPERCHAIN_CONFIG);
        h = keccak256(abi.encode(s.paused(), s.paused(address(PORTAL)), s.paused(LOCKBOX), s.guardian()));
        h = keccak256(abi.encode(h, SC.paused(), SC.owner(), SC.scalar(), SC.basefeeScalar(), SC.blobbasefeeScalar()));
        h = keccak256(abi.encode(h, SC.gasLimit(), SC.batcherHash(), SC.startBlock(), SC.unsafeBlockSigner()));
        h = keccak256(abi.encode(h, SC.guardian(), SC.eip1559Denominator(), SC.eip1559Elasticity()));
        h = keccak256(abi.encode(h, SC.l1CrossDomainMessenger(), SC.l1StandardBridge(), SC.optimismPortal(), SC.superchainConfig()));
    }

    function _getters() internal view returns (bytes32) {
        return keccak256(abi.encode(_gPortal(), _gCdm(), _gBridges(), _gConfigs()));
    }

    function _flow(Prove memory p, address recipient) internal returns (Outcome memory o) {
        address game = _mature(p.hash, p.submitter);
        game;
        o.getters = _getters();
        uint256 lb = LOCKBOX.balance;
        uint256 rb = recipient.balance;
        vm.prank(p.submitter);
        PORTAL.finalizeWithdrawalTransaction(p.wd);
        o.lockboxDelta = lb - LOCKBOX.balance;
        o.recipientGain = recipient.balance - rb;
        o.finalized = PORTAL.finalizedWithdrawals(p.hash);
        o.relayed = L1CDM.successfulMessages(_msgHash(p.wd.data));
        o.failed = L1CDM.failedMessages(_msgHash(p.wd.data));
        // bridge deposit: EOA -> L1StandardBridge -> L1CDM -> portal -> lockbox
        address user = address(0xA11CE);
        vm.deal(user, 2 ether);
        lb = LOCKBOX.balance;
        vm.prank(user, user);
        IBridgeF4(BRIDGE).depositETH{ value: 1 ether }(200_000, "");
        o.depositLockboxGain = LOCKBOX.balance - lb;
        o.nonceAfter = ICdmF4(address(L1CDM)).messageNonce();
    }

    function _hashed(string memory name) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(bytes(name))) - 1);
    }

    bytes32 constant JUNK = keccak256("F4-junk");
    bytes32 constant ONE = bytes32(uint256(1));

    /// keep the two low bytes (`_initialized`, `_initializing`), poison the 30 bytes above them
    function _poisonAboveInit(address a) internal {
        bytes32 v = vm.load(a, bytes32(0));
        vm.store(a, bytes32(0), (v & bytes32(uint256(0xffff))) | (JUNK << 16));
    }

    function _poisonPortal(bytes32 wdHash, address game) internal {
        address portal = address(PORTAL);
        // ---- legacy base slots (v1.0.0 .. v4.0.0 meanings)
        vm.store(portal, bytes32(uint256(52)), JUNK); // v1 provenWithdrawals base
        vm.store(portal, bytes32(uint256(53)), bytes32(uint256(uint160(address(0xBAD))) << 8 | 1)); // paused = true | superchainConfig
        vm.store(portal, bytes32(uint256(54)), JUNK); // l2Oracle
        vm.store(portal, bytes32(uint256(56)), JUNK); // disputeGameFactory
        vm.store(portal, bytes32(uint256(58)), JUNK); // disputeGameBlacklist base
        vm.store(portal, bytes32(uint256(59)), bytes32(type(uint256).max)); // respectedGameType | UpdatedAt = max
        vm.store(portal, bytes32(uint256(61)), JUNK); // _balance (CGT)
        bytes32 s63 = vm.load(portal, bytes32(uint256(63)));
        vm.store(portal, bytes32(uint256(63)), s63 | bytes32(uint256(1) << 160)); // superRootsActive = true
        // ---- legacy MAPPING ENTRIES for this very withdrawal / game
        bytes32 s52 = keccak256(abi.encode(wdHash, uint256(52)));
        vm.store(portal, s52, JUNK); // legacy proof with a junk output root ...
        vm.store(portal, bytes32(uint256(s52) + 1), ONE); // ... timestamp 1, index 0
        vm.store(portal, keccak256(abi.encode(game, uint256(58))), ONE); // legacy portal blacklist[game] = true
        // gap slots never used by any release
        vm.store(portal, bytes32(uint256(2)), JUNK);
        vm.store(portal, bytes32(uint256(49)), JUNK);
    }

    function _poisonMessenger(bytes32 msgHash) internal {
        address cdm = address(L1CDM);
        bytes32 c0 = vm.load(cdm, bytes32(0));
        // libAddressManager (OVM), bytes 0..19; `_initialized` lives at byte 20
        vm.store(cdm, bytes32(0), (c0 & ~bytes32(uint256(type(uint160).max))) | bytes32(uint256(uint160(address(0xBAD)))));
        vm.store(cdm, bytes32(uint256(51)), JUNK); // OVM _owner
        vm.store(cdm, bytes32(uint256(101)), ONE); // Pausable _paused = true
        vm.store(cdm, bytes32(uint256(151)), bytes32(uint256(2))); // ReentrancyGuard _status = ENTERED
        vm.store(cdm, bytes32(uint256(201)), JUNK);
        vm.store(cdm, bytes32(uint256(202)), JUNK);
        vm.store(cdm, keccak256(abi.encode(msgHash, uint256(201))), ONE); // blockedMessages[hash] = true
        vm.store(cdm, keccak256(abi.encode(msgHash, uint256(202))), ONE); // relayedMessages[hash] = true
        vm.store(cdm, bytes32(uint256(249)), JUNK); // v1.1.0 `PORTAL` (now inside __gap)
        vm.store(cdm, bytes32(uint256(250)), JUNK); // __gap tail
        vm.store(cdm, bytes32(uint256(251)), JUNK); // superchainConfig (v1.2.0 .. v3)
        vm.store(cdm, bytes32(uint256(253)), JUNK); // systemConfig (v1.5.0 .. v1.8.0)
    }

    function _poisonRest() internal {
        // ---- L1StandardBridge / L1ERC721Bridge / factory
        _poisonAboveInit(BRIDGE); // OVM messenger bytes / spacer_0_2_30
        vm.store(BRIDGE, bytes32(uint256(1)), JUNK); // OVM l2TokenBridge
        vm.store(BRIDGE, bytes32(uint256(50)), JUNK); // superchainConfig
        vm.store(BRIDGE, bytes32(uint256(51)), JUNK); // systemConfig (v1.5.0 .. v1.8.0)
        _poisonAboveInit(L1ERC721);
        vm.store(L1ERC721, bytes32(uint256(50)), JUNK);
        _poisonAboveInit(FACTORY);
        // ---- SuperchainConfig v1 hashed slots (guardian / global paused), cleared by `upgrade()` at U16
        vm.store(SUPERCHAIN_CONFIG, _hashed("superchainConfig.paused"), ONE);
        vm.store(SUPERCHAIN_CONFIG, _hashed("superchainConfig.guardian"), bytes32(uint256(uint160(address(0xBAD)))));
        // ---- SystemConfig deprecated hashed slots
        address sc = address(SC);
        vm.store(sc, _hashed("systemconfig.batchinbox"), JUNK);
        vm.store(sc, _hashed("systemconfig.l2outputoracle"), JUNK);
        vm.store(sc, _hashed("systemconfig.disputegamefactory"), JUNK);
        vm.store(sc, _hashed("opstack.gaspayingtoken"), JUNK);
        vm.store(sc, _hashed("opstack.gaspayingtokenname"), JUNK);
        vm.store(sc, _hashed("opstack.gaspayingtokensymbol"), JUNK);
        // ---- ETHLockbox / ASR / DelayedWETH v8 `systemConfig` spacers
        _poisonAboveInit(LOCKBOX);
        _poisonAboveInit(IPortalF4(address(PORTAL)).anchorStateRegistry());
        vm.store(SC.delayedWETH(), bytes32(uint256(4)), JUNK);
    }

    function _poison(Prove memory p, address game) internal {
        _poisonPortal(p.hash, game);
        _poisonMessenger(_msgHash(p.wd.data));
        _poisonRest();
    }

    function test_poisonedPreV7Slots_realWithdrawalAndDepositAreUnchanged() public {
        Prove memory p = _load(0); // real L2CDM -> L1CDM -> L1StandardBridge ETH withdrawal proven under v8
        (address game,) = PORTAL.provenWithdrawals(p.hash, p.submitter);
        // recipient of the bridged ETH = `_to` of finalizeBridgeETH inside relayMessage
        address recipient = _recipient(p.wd.data);

        uint256 snap = vm.snapshotState();
        Outcome memory clean = _flow(p, recipient);
        vm.revertToState(snap);

        _poison(p, game);
        Outcome memory dirty = _flow(p, recipient);

        assertEq(clean.getters, dirty.getters, "a v9 getter depends on a pre-v7 legacy slot");
        assertEq(clean.lockboxDelta, dirty.lockboxDelta);
        assertEq(clean.recipientGain, dirty.recipientGain);
        assertEq(clean.finalized, dirty.finalized);
        assertEq(clean.relayed, dirty.relayed);
        assertEq(clean.failed, dirty.failed);
        assertEq(clean.depositLockboxGain, dirty.depositLockboxGain);
        assertEq(clean.nonceAfter, dirty.nonceAfter);
        // and the clean run really did something
        assertTrue(clean.finalized && clean.relayed && !clean.failed, "real withdrawal must finalize and relay");
        assertEq(clean.lockboxDelta, p.wd.value);
        assertEq(clean.recipientGain, p.wd.value);
        assertEq(clean.depositLockboxGain, 1 ether);
    }

    /// relayMessage(uint256,address,address,uint256,uint256,bytes) -> message = finalizeBridgeETH(address from,address to,uint256,bytes)
    function _recipient(bytes memory relayCalldata) internal pure returns (address to) {
        bytes memory args = new bytes(relayCalldata.length - 4);
        for (uint256 j; j < args.length; j++) args[j] = relayCalldata[j + 4];
        (,,,,, bytes memory message) = abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
        bytes memory margs = new bytes(message.length - 4);
        for (uint256 j; j < margs.length; j++) margs[j] = message[j + 4];
        (, to,,) = abi.decode(margs, (address, address, uint256, bytes));
    }

    // ---------------------------------------------------------------------------------------------------------------
    // 3. A FABRICATED legacy proof (written straight into the slot-52 mapping, mock-only) gives no v9 capability:
    //    v9 neither finalizes it nor lets anyone delete / consume it. Locates the absence of a reader.
    // ---------------------------------------------------------------------------------------------------------------
    function test_fabricatedLegacyProofGivesNothing() public {
        WithdrawalTransaction memory w = WithdrawalTransaction({
            nonce: uint256(1) << 240 | 0xF4F4F4,
            sender: address(0xBEEF),
            target: address(0xCAFE),
            value: 1 ether,
            gasLimit: 100_000,
            data: ""
        });
        bytes32 h = hashWd(w);
        bytes32 s52 = keccak256(abi.encode(h, uint256(52)));
        // a "mature" legacy proof against the last real L2OO output
        (bool ok, bytes memory ret) = L2OO.staticcall(abi.encodeWithSignature("latestOutputIndex()"));
        assertTrue(ok);
        uint256 idx = abi.decode(ret, (uint256));
        (ok, ret) = L2OO.staticcall(abi.encodeWithSignature("getL2Output(uint256)", idx));
        (bytes32 root,,) = abi.decode(ret, (bytes32, uint128, uint128));
        vm.store(address(PORTAL), s52, root);
        vm.store(address(PORTAL), bytes32(uint256(s52) + 1), bytes32((idx << 128) | (block.timestamp - 30 days)));

        uint256 lb = LOCKBOX.balance;
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.finalizeWithdrawalTransaction(w);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, address(this));
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.deleteProvenWithdrawal(h, address(this));
        assertEq(LOCKBOX.balance, lb);
        assertFalse(PORTAL.finalizedWithdrawals(h));
    }
}
