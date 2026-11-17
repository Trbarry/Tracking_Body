// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IOptimismPortal2 {
    function finalizeWithdrawalTransactionExternalProof(
        WithdrawalTransaction memory _tx,
        address _proofSubmitter
    ) external;

    function finalizedWithdrawals(bytes32 _withdrawalHash) external view returns (bool);
    function ethLockbox() external view returns (address);
    function l2Sender() external view returns (address);
    function donateETH() external payable;
}

interface IETHLockbox {
    function authorizedPortals(address _portal) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256 _value) external;
}

interface IL1PortalDeposit {
    function depositTransaction(
        address _to,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes calldata _data
    ) external payable;
}

interface IL1CrossDomainMessenger {
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable;

    function failedMessages(bytes32 _messageHash) external view returns (bool);
}

interface IL2CrossDomainMessenger {
    function messageNonce() external view returns (uint256);
    function baseGas(bytes calldata _message, uint32 _minGasLimit) external pure returns (uint64);
    function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external payable;
}

interface IAddressManager {
    function owner() external view returns (address);
    function getAddress(string calldata _name) external view returns (address);
    function setAddress(string calldata _name, address _address) external;
}

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
}

interface IERC20Like {
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface IStandardBridge {
    function finalizeBridgeETH(address _from, address _to, uint256 _amount, bytes calldata _extraData)
        external
        payable;
}

interface IERC721Bridge {
    function finalizeBridgeERC721(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    ) external;
}

interface IL2ToL1MessagePasser {
    function messageNonce() external view returns (uint256);
    function initiateWithdrawal(address _target, uint256 _gasLimit, bytes calldata _data) external payable;
    function sentMessages(bytes32 _withdrawalHash) external view returns (bool);
}

contract HitReceiver {
    uint256 public hits;

    function ping() external {
        ++hits;
    }
}

/// @dev Test-only stand-in for the new lockbox after a future migration. The portal's lockbox
///      pointer is changed with vm.store solely to make the old, deployed OP lockbox targetable.
contract LocalReplacementLockbox {
    IOptimismPortal2 internal immutable portal;

    constructor(IOptimismPortal2 _portal) payable {
        portal = _portal;
    }

    receive() external payable { }

    function paused() external pure returns (bool) {
        return false;
    }

    function unlockETH(uint256 _value) external {
        require(msg.sender == address(portal), "not portal");
        portal.donateETH{ value: _value }();
    }

    function lockETH() external payable {
        require(msg.sender == address(portal), "not portal");
    }
}

contract CATKFUnsafeTargetsTest is Test {
    IOptimismPortal2 internal constant PORTAL =
        IOptimismPortal2(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    address internal constant OP_LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant INK_PORTAL = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
    address internal constant INK_LOCKBOX = 0xbd4AbB321138e8Eddc399cE64E66451294325a14;
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
    address internal constant PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant DELAYED_WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address internal constant ANCHOR_GAME = 0x55A5CFd4270340b3822BB9D8eebdb450ac206f95;
    address internal constant ATTACKER = 0xA11cE00000000000000000000000000000000f00;
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;
    address internal constant MESSAGE_PASSER = 0x4200000000000000000000000000000000000016;

    uint256 internal constant PROVEN_WITHDRAWALS_SLOT = 57;
    uint256 internal constant ETH_LOCKBOX_SLOT = 63;
    uint64 internal constant GAME_CREATED_AT = 1_794_299_939;
    bytes4 internal constant BAD_TARGET = bytes4(keccak256("OptimismPortal_BadTarget()"));

    uint256 internal serial;

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26_433_900);
        assertEq(PORTAL.ethLockbox(), OP_LOCKBOX);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_currentPortalAndCurrentLockboxAreHardBlocked() public {
        WithdrawalTransaction memory toPortal = _withdrawal(address(PORTAL), 0, bytes(""));
        _prove(toPortal);
        vm.expectRevert(BAD_TARGET);
        PORTAL.finalizeWithdrawalTransactionExternalProof(toPortal, address(this));

        WithdrawalTransaction memory toLockbox = _withdrawal(OP_LOCKBOX, 0, abi.encodeCall(IETHLockbox.lockETH, ()));
        _prove(toLockbox);
        vm.expectRevert(BAD_TARGET);
        PORTAL.finalizeWithdrawalTransactionExternalProof(toLockbox, address(this));
    }

    function test_siblingLockboxRejectsOPPortalAndValueIsRelocked() public {
        address[3] memory siblingLockboxes = [
            INK_LOCKBOX,
            address(0x67B4de6FfA66EF201Ea6099A89cA397D56622E31),
            address(0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5)
        ];
        for (uint256 i; i < siblingLockboxes.length; ++i) {
            assertFalse(IETHLockbox(siblingLockboxes[i]).authorizedPortals(address(PORTAL)));
            uint256 opBefore = OP_LOCKBOX.balance;
            uint256 siblingBefore = siblingLockboxes[i].balance;

            WithdrawalTransaction memory txn =
                _withdrawal(siblingLockboxes[i], 1 ether, abi.encodeCall(IETHLockbox.lockETH, ()));
            _proveAndFinalize(txn);

            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
            assertEq(OP_LOCKBOX.balance, opBefore, "failed value was not relocked");
            assertEq(siblingLockboxes[i].balance, siblingBefore, "sibling accepted alien portal");
        }
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_siblingPortalCompositionOnlyMovesEqualCustody() public {
        address[3] memory siblingPortals = [
            INK_PORTAL,
            address(0x88e529A6ccd302c948689Cd5156C83D4614FAE92),
            address(0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2)
        ];
        address[3] memory siblingLockboxes = [
            INK_LOCKBOX,
            address(0x67B4de6FfA66EF201Ea6099A89cA397D56622E31),
            address(0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5)
        ];
        bytes memory deposit = abi.encodeCall(
            IL1PortalDeposit.depositTransaction,
            (ATTACKER, 1 ether, uint64(100_000), false, bytes(""))
        );
        for (uint256 i; i < siblingPortals.length; ++i) {
            uint256 opBefore = OP_LOCKBOX.balance;
            uint256 siblingBefore = siblingLockboxes[i].balance;
            WithdrawalTransaction memory txn = _withdrawal(siblingPortals[i], 1 ether, deposit);

            _proveAndFinalize(txn);

            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
            assertEq(OP_LOCKBOX.balance, opBefore - 1 ether, "source custody did not fall exactly");
            assertEq(siblingLockboxes[i].balance, siblingBefore + 1 ether, "destination custody mismatch");
            assertEq(
                opBefore + siblingBefore,
                OP_LOCKBOX.balance + siblingLockboxes[i].balance,
                "custody created"
            );
        }
    }

    function test_rawAttackerWithdrawalCannotEnterMessengerFirstRelayBranch() public {
        HitReceiver receiver = new HitReceiver();
        uint256 versionOneNonce = uint256(1) << 240;
        bytes memory relay = abi.encodeCall(
            IL1CrossDomainMessenger.relayMessage,
            (versionOneNonce, ATTACKER, address(receiver), 0, 100_000, abi.encodeCall(HitReceiver.ping, ()))
        );
        WithdrawalTransaction memory txn = _withdrawal(L1_MESSENGER, 0, relay);

        _proveAndFinalize(txn);

        assertEq(receiver.hits(), 0, "raw sender forged canonical messenger authority");
        assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)), "non-messenger failure not consumed");
    }

    function test_siblingMessengerDoesNotRecognizeOPPortal() public {
        address[3] memory siblingMessengers = [
            address(0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f),
            address(0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f),
            address(0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6)
        ];
        HitReceiver receiver = new HitReceiver();
        bytes memory relay = abi.encodeCall(
            IL1CrossDomainMessenger.relayMessage,
            (
                uint256(1) << 240,
                ATTACKER,
                address(receiver),
                0,
                100_000,
                abi.encodeCall(HitReceiver.ping, ())
            )
        );
        for (uint256 i; i < siblingMessengers.length; ++i) {
            WithdrawalTransaction memory txn = _withdrawal(siblingMessengers[i], 0, relay);

            _proveAndFinalize(txn);

            assertEq(receiver.hits(), 0, "sibling messenger accepted the wrong portal");
            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        }
    }

    function test_allCurrentBridgeProxiesRejectRawPortalFrame() public {
        address[4] memory standardBridges = [
            address(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1),
            address(0x88FF1e5b602916615391F55854588EFcBB7663f0),
            address(0xeb9bf100225c214Efc3E7C651ebbaDcF85177607),
            address(0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA)
        ];
        address[4] memory erc721Bridges = [
            address(0x5a7749f83b81B301cAb5f48EB8516B986DAef23D),
            address(0x661235a238B11191211fa95D4Dd9E423d521E0Be),
            address(0x5933e323bE8896DfaCd1cD671442F27dAA10a053),
            address(0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf)
        ];

        for (uint256 i; i < standardBridges.length; ++i) {
            WithdrawalTransaction memory txn = _withdrawal(
                standardBridges[i],
                0,
                abi.encodeCall(IStandardBridge.finalizeBridgeETH, (ATTACKER, ATTACKER, 0, bytes("")))
            );
            _proveAndFinalize(txn);
            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        }
        for (uint256 i; i < erc721Bridges.length; ++i) {
            WithdrawalTransaction memory txn = _withdrawal(
                erc721Bridges[i],
                0,
                abi.encodeCall(
                    IERC721Bridge.finalizeBridgeERC721,
                    (address(1), address(2), ATTACKER, ATTACKER, 1, bytes(""))
                )
            );
            _proveAndFinalize(txn);
            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        }
    }

    function test_attackerCanonicalMessengerPathStillFailsBridgeIdentity() public {
        uint256 nonce = (uint256(1) << 240) | 0xCA7F;
        bytes memory bridgeCall =
            abi.encodeCall(IStandardBridge.finalizeBridgeETH, (ATTACKER, ATTACKER, 0, bytes("")));
        bytes memory relay = abi.encodeCall(
            IL1CrossDomainMessenger.relayMessage,
            (nonce, ATTACKER, address(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1), 0, 200_000, bridgeCall)
        );
        WithdrawalTransaction memory txn = _withdrawal(L1_MESSENGER, 0, relay);
        txn.sender = L2_MESSENGER;

        _proveAndFinalize(txn);

        assertTrue(IL1CrossDomainMessenger(L1_MESSENGER).failedMessages(keccak256(relay)));
        assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
    }

    function test_historicalCodeLaterSelfMessageCannotAffectSharedProtocolState() public {
        // Exact effective target/sender from withdrawal
        // 0x21dee2453190e2b5e3bb4d4a1f4161d35eb268bd7995cc46980f51c71a79902e.
        // It had no L1 code when initiated and is now an EIP-7702 delegation designator.
        address codeLaterAccount = 0x00C7ecc4187F239e09D4cFeA5aBe6d3c18f923bC;
        assertEq(codeLaterAccount.code.length, 23, "expected EIP-7702 designator");

        uint256 messageNonce = (uint256(1) << 240) | 0x648a;
        bytes memory message = abi.encodeWithSelector(
            bytes4(0x06684706),
            uint256(4778384329583297500742918515827483896875618958121606201292619776)
        );
        bytes memory relay = abi.encodeCall(
            IL1CrossDomainMessenger.relayMessage,
            (messageNonce, codeLaterAccount, codeLaterAccount, 0, 387_163, message)
        );
        WithdrawalTransaction memory txn = _withdrawal(L1_MESSENGER, 0, relay);
        txn.sender = L2_MESSENGER;
        uint256 targetBalanceBefore = codeLaterAccount.balance;

        _proveAndFinalize(txn);

        assertTrue(
            IL1CrossDomainMessenger(L1_MESSENGER).failedMessages(keccak256(relay)),
            "unknown delegated selector unexpectedly succeeded"
        );
        assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        assertEq(codeLaterAccount.balance, targetBalanceBefore, "zero-value self-message moved ETH");
    }

    function test_allASRGenerationsRejectPortalAsGuardian() public {
        address[6] memory registries = [
            address(0x18DAc71c228D1C32c99489B7323d441E1175e443),
            address(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b),
            address(0x23B2C62946350F4246f9f9D027e071f0264FD113),
            address(0xEe018bAf058227872540AC60eFbd38b023d9dAe2),
            address(0x4890928941e62e273dA359374b105F803329F473),
            address(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9)
        ];
        bytes4 getter = bytes4(keccak256("respectedGameType()"));
        bytes memory setter = abi.encodeWithSignature("setRespectedGameType(uint32)", uint32(123));

        for (uint256 i; i < registries.length; ++i) {
            (bool beforeOk, bytes memory beforeValue) = registries[i].staticcall(abi.encodeWithSelector(getter));
            WithdrawalTransaction memory txn = _withdrawal(registries[i], 0, setter);
            _proveAndFinalize(txn);
            (bool afterOk, bytes memory afterValue) = registries[i].staticcall(abi.encodeWithSelector(getter));
            assertEq(afterOk, beforeOk);
            assertEq(keccak256(afterValue), keccak256(beforeValue), "portal changed respected game type");
            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        }
    }

    function test_allDelayedWETHGenerationsHaveNoPortalOwnedObject() public {
        address[13] memory weths = [
            address(0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14),
            address(0x82511d494B5C942BE57498a70Fdd7184Ee33B975),
            address(0x9F9b897e37de5052cD70Db6D08474550DDb07f39),
            address(0x323dFC63c9B83CB83f40325AaB74b245937cbdF0),
            address(0x21429aF66058BC3e4aE4a8f2EC4531AaC433ecbC),
            address(0xe214879aD573693A4C49f7654449Caa455cdE34f),
            address(0xc5f54F934075677FBA99b5E43468439cbdE88ca7),
            address(0xD061AB95069987868768818cc1248705351e2D0e),
            address(0xe03F4d1D0E6B8b18b97198598b3f792E57BA17d4),
            address(0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162),
            address(0x57b4C29DAee99a28E6E86778b499361294c134eA),
            address(0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47),
            address(0x74ad145aC900F1DD5551F0C9E143314DC4022FCf)
        ];

        for (uint256 i; i < weths.length; ++i) {
            IERC20Like weth = IERC20Like(weths[i]);
            assertEq(weth.balanceOf(address(PORTAL)), 0, "live portal-owned WETH object");
            uint256 attackerBefore = weth.balanceOf(ATTACKER);
            WithdrawalTransaction memory txn =
                _withdrawal(weths[i], 0, abi.encodeCall(IERC20Like.transfer, (ATTACKER, 1)));
            _proveAndFinalize(txn);
            assertEq(weth.balanceOf(address(PORTAL)), 0);
            assertEq(weth.balanceOf(ATTACKER), attackerBefore);
            assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(txn)));
        }
    }

    function test_adminTargetsDoNotTreatPortalAsOwner() public {
        address[4] memory addressManagers = [
            ADDRESS_MANAGER,
            address(0x9b7C9BbD6d540A8A4dEDd935819fC4408Ba71153),
            address(0xB24bFEeCE1B3b7A44559F4Cbc21BeD312b130b70),
            address(0x8098F676033A377b9Defe302e9fE6877cD63D575)
        ];
        for (uint256 i; i < addressManagers.length; ++i) {
            IAddressManager manager = IAddressManager(addressManagers[i]);
            address managerOwner = manager.owner();
            address oldNamed = manager.getAddress("CATK-F");
            WithdrawalTransaction memory managerTxn = _withdrawal(
                addressManagers[i], 0, abi.encodeCall(IAddressManager.setAddress, ("CATK-F", ATTACKER))
            );
            _proveAndFinalize(managerTxn);
            assertEq(manager.owner(), managerOwner);
            assertEq(manager.getAddress("CATK-F"), oldNamed);
        }

        address[4] memory proxyAdmins = [
            PROXY_ADMIN,
            address(0xd56045E68956FCe2576E680c95a4750cf8241f79),
            address(0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a),
            address(0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4)
        ];
        address[4] memory systemConfigs = [
            SYSTEM_CONFIG,
            address(0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364),
            address(0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3),
            address(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6)
        ];
        address[4] memory disputeGameFactories = [
            address(0xe5965Ab5962eDc7477C8520243A95517CD252fA9),
            address(0x10d7B35078d3baabB96Dd45a9143B94be65b12CD),
            address(0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0),
            address(0x2F12d621a16e2d3285929C9996f478508951dFe4)
        ];
        for (uint256 i; i < proxyAdmins.length; ++i) {
            IOwnable proxyAdmin = IOwnable(proxyAdmins[i]);
            address proxyAdminOwner = proxyAdmin.owner();
            WithdrawalTransaction memory adminTxn = _withdrawal(
                proxyAdmins[i], 0, abi.encodeCall(IOwnable.transferOwnership, (ATTACKER))
            );
            _proveAndFinalize(adminTxn);
            assertEq(proxyAdmin.owner(), proxyAdminOwner);

            IOwnable systemConfig = IOwnable(systemConfigs[i]);
            address configOwner = systemConfig.owner();
            WithdrawalTransaction memory configTxn = _withdrawal(
                systemConfigs[i], 0, abi.encodeCall(IOwnable.transferOwnership, (ATTACKER))
            );
            _proveAndFinalize(configTxn);
            assertEq(systemConfig.owner(), configOwner);

            IOwnable disputeGameFactory = IOwnable(disputeGameFactories[i]);
            address factoryOwner = disputeGameFactory.owner();
            WithdrawalTransaction memory factoryTxn = _withdrawal(
                disputeGameFactories[i], 0, abi.encodeCall(IOwnable.transferOwnership, (ATTACKER))
            );
            _proveAndFinalize(factoryTxn);
            assertEq(disputeGameFactory.owner(), factoryOwner);
        }
    }

    function test_delayedWETHRoundTripCanOnlyRecoverSelfFundedValue() public {
        IERC20Like weth = IERC20Like(DELAYED_WETH);
        assertEq(weth.balanceOf(address(PORTAL)), 0, "unexpected live portal WETH object");
        uint256 lockboxBefore = OP_LOCKBOX.balance;
        uint256 wethEthBefore = DELAYED_WETH.balance;

        // Empty calldata enters WETH receive/deposit and credits msg.sender, which is the portal.
        WithdrawalTransaction memory wrapTxn = _withdrawal(DELAYED_WETH, 1 ether, bytes(""));
        _proveAndFinalize(wrapTxn);
        assertEq(weth.balanceOf(address(PORTAL)), 1 ether);
        assertEq(DELAYED_WETH.balance, wethEthBefore + 1 ether);

        WithdrawalTransaction memory sweepTxn = _withdrawal(
            DELAYED_WETH, 0, abi.encodeCall(IERC20Like.transfer, (ATTACKER, 1 ether))
        );
        _proveAndFinalize(sweepTxn);
        assertEq(weth.balanceOf(address(PORTAL)), 0);
        assertEq(weth.balanceOf(ATTACKER), 1 ether);
        assertEq(OP_LOCKBOX.balance, lockboxBefore - 1 ether);
        assertEq(DELAYED_WETH.balance, wethEthBefore + 1 ether, "WETH backing was not attacker-funded");
    }

    function test_futureRetiredLockboxAcceptsLockButCannotBeUnlockedInWithdrawal() public {
        assertTrue(IETHLockbox(OP_LOCKBOX).authorizedPortals(address(PORTAL)));
        LocalReplacementLockbox replacement = new LocalReplacementLockbox{ value: 10 ether }(PORTAL);
        uint256 replacementBefore = address(replacement).balance;

        // Vehicle only: model the portal after it has migrated away from the deployed OP lockbox.
        bytes32 oldWord = vm.load(address(PORTAL), bytes32(ETH_LOCKBOX_SLOT));
        uint256 highBits = uint256(oldWord) & ~uint256(type(uint160).max);
        vm.store(
            address(PORTAL),
            bytes32(ETH_LOCKBOX_SLOT),
            bytes32(highBits | uint256(uint160(address(replacement))))
        );
        assertEq(PORTAL.ethLockbox(), address(replacement));

        uint256 oldLockboxBefore = OP_LOCKBOX.balance;
        WithdrawalTransaction memory relockOld =
            _withdrawal(OP_LOCKBOX, 1 ether, abi.encodeCall(IETHLockbox.lockETH, ()));
        _proveAndFinalize(relockOld);
        assertEq(OP_LOCKBOX.balance, oldLockboxBefore + 1 ether, "retired lockbox did not accept old portal");
        assertEq(
            address(replacement).balance,
            replacementBefore - 1 ether,
            "value did not originate in replacement custody"
        );

        WithdrawalTransaction memory drainOld =
            _withdrawal(OP_LOCKBOX, 0, abi.encodeCall(IETHLockbox.unlockETH, (1 ether)));
        _proveAndFinalize(drainOld);
        assertEq(OP_LOCKBOX.balance, oldLockboxBefore + 1 ether, "withdrawal bypassed l2Sender guard");
        assertTrue(PORTAL.finalizedWithdrawals(_hashWithdrawal(drainOld)), "failed drain remained replayable");
    }

    function _withdrawal(address _target, uint256 _value, bytes memory _data)
        internal
        returns (WithdrawalTransaction memory)
    {
        return WithdrawalTransaction({
            nonce: uint256(keccak256(abi.encode("CATK-F", ++serial))),
            sender: ATTACKER,
            target: _target,
            value: _value,
            gasLimit: 700_000,
            data: _data
        });
    }

    function _proveAndFinalize(WithdrawalTransaction memory _txn) internal {
        _prove(_txn);
        PORTAL.finalizeWithdrawalTransactionExternalProof(_txn, address(this));
    }

    function _prove(WithdrawalTransaction memory _txn) internal {
        bytes32 withdrawalHash = _hashWithdrawal(_txn);
        bytes32 outer = keccak256(abi.encode(withdrawalHash, PROVEN_WITHDRAWALS_SLOT));
        bytes32 cell = keccak256(abi.encode(address(this), outer));
        uint256 packed = uint256(uint160(ANCHOR_GAME)) | (uint256(GAME_CREATED_AT + 1) << 160);
        vm.store(address(PORTAL), cell, bytes32(packed));
    }

    function _hashWithdrawal(WithdrawalTransaction memory _txn) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(_txn.nonce, _txn.sender, _txn.target, _txn.value, _txn.gasLimit, _txn.data)
        );
    }
}

contract CATKFL2ReachabilityTest is Test {
    address internal constant ATTACKER = 0xA11cE00000000000000000000000000000000f00;
    address internal constant SYSTEM_TARGET = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    IL2ToL1MessagePasser internal constant MESSAGE_PASSER =
        IL2ToL1MessagePasser(0x4200000000000000000000000000000000000016);
    IL2CrossDomainMessenger internal constant L2_XDM =
        IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;

    function setUp() public {
        vm.createSelectFork("l2");
        assertEq(block.number, 159_654_093);
    }

    function test_unprivilegedAttackerCanCreateWithdrawalButCannotSpoofSender() public {
        uint256 nonce = MESSAGE_PASSER.messageNonce();
        uint256 value = 0.25 ether;
        bytes memory data = abi.encodeWithSignature("lockETH()");
        WithdrawalTransaction memory expected = WithdrawalTransaction({
            nonce: nonce,
            sender: ATTACKER,
            target: SYSTEM_TARGET,
            value: value,
            gasLimit: 200_000,
            data: data
        });
        bytes32 expectedHash = keccak256(
            abi.encode(
                expected.nonce,
                expected.sender,
                expected.target,
                expected.value,
                expected.gasLimit,
                expected.data
            )
        );

        vm.deal(ATTACKER, value);
        vm.prank(ATTACKER);
        MESSAGE_PASSER.initiateWithdrawal{ value: value }(SYSTEM_TARGET, 200_000, data);

        assertTrue(MESSAGE_PASSER.sentMessages(expectedHash));
        assertTrue(expected.sender != 0x4200000000000000000000000000000000000007);
        assertTrue(expected.sender != 0x000000000000000000000000000000000000dEaD);
    }

    function test_attackerCanChooseL1BridgeTargetButInnerSenderRemainsAttacker() public {
        uint256 outerNonce = MESSAGE_PASSER.messageNonce();
        uint256 messageNonce = L2_XDM.messageNonce();
        uint32 minGas = 200_000;
        bytes memory bridgeCall =
            abi.encodeCall(IStandardBridge.finalizeBridgeETH, (ATTACKER, ATTACKER, 0, bytes("")));
        bytes memory relay = abi.encodeCall(
            IL1CrossDomainMessenger.relayMessage,
            (messageNonce, ATTACKER, L1_STANDARD_BRIDGE, 0, minGas, bridgeCall)
        );
        uint256 outerGas = L2_XDM.baseGas(bridgeCall, minGas);
        WithdrawalTransaction memory expected = WithdrawalTransaction({
            nonce: outerNonce,
            sender: address(L2_XDM),
            target: L1_MESSENGER,
            value: 0,
            gasLimit: outerGas,
            data: relay
        });
        bytes32 expectedHash = keccak256(
            abi.encode(
                expected.nonce,
                expected.sender,
                expected.target,
                expected.value,
                expected.gasLimit,
                expected.data
            )
        );

        vm.prank(ATTACKER);
        L2_XDM.sendMessage(L1_STANDARD_BRIDGE, bridgeCall, minGas);

        assertTrue(MESSAGE_PASSER.sentMessages(expectedHash));
    }
}
