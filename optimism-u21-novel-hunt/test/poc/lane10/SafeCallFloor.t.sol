// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortalS {
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory _tx, address _proofSubmitter) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function anchorStateRegistry() external view returns (address);
}

interface IASRs {
    function anchorGame() external view returns (address);
}

contract GasProbe {
    uint256 public lastGas;

    fallback() external payable {
        lastGas = gasleft();
    }
}

/// SafeCall.callWithMinGas as deployed in OptimismPortal2 6.1.0 (U21):
///  (1) the gas floor now depends on live state of the target: +183,600 when value != 0 and EXTCODEHASH(target) == 0;
///  (2) (old code, unchanged) hasMinGas multiplies the user-supplied uint256 gasLimit by 64 unchecked.
contract SafeCallFloorTest is Test {
    IPortalS constant PORTAL = IPortalS(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    address constant RELAYER = address(0xBEEF0002);
    address constant L2_SENDER = address(0xD00D); // an ordinary L2 account, not the L2CrossDomainMessenger

    function setUp() public {
        // `l1` = shared anvil pinned at 26433900. ALT_RPC (optional) reads the same block straight from an
        // archive node when the shared anvil's upstream is throttled (passive reads only).
        string memory alt = vm.envOr("ALT_RPC", string(""));
        if (bytes(alt).length != 0) vm.createSelectFork(alt, 26433900);
        else vm.createSelectFork("l1");
    }

    function _prove(WithdrawalTransaction memory w) internal returns (bytes32 wh) {
        wh = keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
        // SETUP: mark as proven > 7 days ago against the current anchor game (replaces the Merkle proof only).
        address game = IASRs(PORTAL.anchorStateRegistry()).anchorGame();
        uint256 ts = block.timestamp - 604_801;
        bytes32 slot = keccak256(abi.encode(RELAYER, keccak256(abi.encode(wh, uint256(57)))));
        vm.store(address(PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
    }

    function _minGasToFinalize(WithdrawalTransaction memory w) internal returns (uint256) {
        for (uint256 g = 60_000; g < 900_000; g += 500) {
            uint256 snap = vm.snapshotState();
            _prove(w);
            vm.prank(RELAYER, RELAYER);
            (bool ok,) = address(PORTAL).call{ gas: g }(
                abi.encodeWithSelector(IPortalS.finalizeWithdrawalTransactionExternalProof.selector, w, RELAYER)
            );
            vm.revertToState(snap);
            if (ok) return g;
        }
        return 0;
    }

    function test_floor_depends_on_target_existence() public {
        address fresh = address(uint160(uint256(keccak256("lane10 fresh eoa 2"))));
        address existing = address(uint160(uint256(keccak256("lane10 existing eoa"))));
        vm.deal(existing, 1); // exists: codehash == keccak256("") != 0
        assertEq(fresh.codehash, bytes32(0));
        assertTrue(existing.codehash != bytes32(0));

        WithdrawalTransaction memory w =
            WithdrawalTransaction({ nonce: (uint256(1) << 240) | 777_000_001, sender: L2_SENDER, target: fresh, value: 1 wei, gasLimit: 0, data: "" });
        uint256 gFresh = _minGasToFinalize(w);
        w.target = existing;
        w.nonce += 1;
        uint256 gExisting = _minGasToFinalize(w);
        w.target = fresh;
        w.value = 0;
        w.nonce += 1;
        uint256 gFreshNoValue = _minGasToFinalize(w);
        emit log_named_uint("min gas, 1 wei to non-existent account", gFresh);
        emit log_named_uint("min gas, 1 wei to existing account", gExisting);
        emit log_named_uint("min gas, 0 value to non-existent account", gFreshNoValue);
        emit log_named_uint("delta (fresh - existing)", gFresh - gExisting);
        // today's rules: the real extra cost of creating the account is 25,000; the floor adds 183,600 * 64/63
        assertGt(gFresh - gExisting, 183_600);
    }

    function test_uint256_gasLimit_wraps_floor() public {
        GasProbe p = new GasProbe();
        // 64 * 2^250 == 0 mod 2^256, so the "minimum gas" term vanishes from hasMinGas
        WithdrawalTransaction memory w = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 777_000_010,
            sender: L2_SENDER,
            target: address(p),
            value: 0,
            gasLimit: uint256(1) << 250,
            data: ""
        });
        bytes32 wh = _prove(w);
        vm.prank(RELAYER, RELAYER);
        (bool ok,) = address(PORTAL).call{ gas: 200_000 }(
            abi.encodeWithSelector(IPortalS.finalizeWithdrawalTransactionExternalProof.selector, w, RELAYER)
        );
        assertTrue(ok, "finalize reverted");
        assertTrue(PORTAL.finalizedWithdrawals(wh));
        emit log_named_uint("declared gasLimit (2^250), gas actually seen by target", p.lastGas());
        assertLt(p.lastGas(), 200_000);
    }
}
