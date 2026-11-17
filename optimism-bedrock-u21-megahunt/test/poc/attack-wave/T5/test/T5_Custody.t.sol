// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

// ATK-T5 — OP Mainnet custody solvency. Fork of L1 26,433,900 (deployed bytecode, read-only archive proxy :7545 pinned at 26,433,900).
// Ledger constants come from evidence/attack-wave/T5/reconcile.json (read-only scans through :7545/:7546).
interface IPortal {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data) external payable;
    function donateETH() external payable;
    function ethLockbox() external view returns (address);
}
interface IL1SB { function depositETH(uint32 _minGasLimit, bytes calldata _extraData) external payable; }
interface IL1CDM { function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external payable; }

contract ForceSend { constructor(address payable t) payable { selfdestruct(t); } }

contract T5CustodyTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant L1SB = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    bytes32 constant TD = keccak256("TransactionDeposited(address,address,uint256,bytes)");

    uint256 constant CUSTODY = 182541068255115703234018;          // lockbox @26,433,900
    uint256 constant LIABILITY_UPPER = 182539366285103703234026;  // S0 + sum(mint) - sum(initiated) + pending(bedrock) + pending(legacy)
    uint256 constant SURPLUS = 1701970011999999992;               // = Bedrock-time margin (regenesis supply delta 1.627270012 + 0.0747)

    address attacker = makeAddr("unprivileged");

    function setUp() public {
        vm.createSelectFork("l1", 26433900);
        assertEq(block.number, 26433900);
        vm.deal(attacker, 100 ether);
    }

    function _mintOf(Vm.Log[] memory logs) internal pure returns (uint256 n, uint256 sumMint, uint256 lastValue) {
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter != address(PORTAL) || logs[i].topics[0] != TD) continue;
            bytes memory op = abi.decode(logs[i].data, (bytes));
            uint256 m; uint256 v;
            assembly { m := mload(add(op, 32)) v := mload(add(op, 64)) }
            n++; sumMint += m; lastValue = v;
        }
    }

    /// (a)+(c): custody read on deployed state equals the reconciled ledger; liability upper bound is covered.
    function test_T5_custody_covers_liability_at_26433900() public view {
        assertEq(PORTAL.ethLockbox(), LOCKBOX);
        assertEq(LOCKBOX.balance, CUSTODY);
        assertEq(address(PORTAL).balance + L1SB.balance + L1CDM.balance, 0);
        assertEq(CUSTODY - LIABILITY_UPPER, SURPLUS);
        assertGe(CUSTODY, LIABILITY_UPPER);
    }

    /// (d) barrier: every unprivileged deposit entry point mints on L2 exactly what it locks in the lockbox.
    function test_T5_every_deposit_path_mints_exactly_what_it_locks() public {
        uint256 lb0 = LOCKBOX.balance;
        vm.startPrank(attacker, attacker);
        vm.recordLogs();
        PORTAL.depositTransaction{value: 3 ether}(attacker, 1 ether, 100_000, false, "");
        (uint256 n, uint256 m,) = _mintOf(vm.getRecordedLogs());
        assertEq(n, 1); assertEq(m, 3 ether); assertEq(LOCKBOX.balance - lb0, 3 ether);

        // mint 0 but value 5: no L1 lock, mint field 0 -> L2 can only move the sender's existing L2 ETH
        vm.recordLogs();
        PORTAL.depositTransaction(attacker, 5 ether, 100_000, false, "");
        (n, m,) = _mintOf(vm.getRecordedLogs());
        assertEq(n, 1); assertEq(m, 0); assertEq(LOCKBOX.balance - lb0, 3 ether);

        vm.recordLogs();
        (bool ok,) = address(PORTAL).call{value: 2 ether}("");
        assertTrue(ok);
        (n, m,) = _mintOf(vm.getRecordedLogs());
        assertEq(n, 1); assertEq(m, 2 ether); assertEq(LOCKBOX.balance - lb0, 5 ether);

        vm.recordLogs();
        IL1SB(L1SB).depositETH{value: 7 ether}(200_000, "");
        (n, m,) = _mintOf(vm.getRecordedLogs());
        assertEq(n, 1); assertEq(m, 7 ether); assertEq(LOCKBOX.balance - lb0, 12 ether);

        vm.recordLogs();
        IL1CDM(L1CDM).sendMessage{value: 11 ether}(attacker, "", 50_000);
        (n, m,) = _mintOf(vm.getRecordedLogs());
        assertEq(n, 1); assertEq(m, 11 ether); assertEq(LOCKBOX.balance - lb0, 23 ether);
        vm.stopPrank();
        assertEq(address(PORTAL).balance + L1SB.balance + L1CDM.balance, 0);
    }

    /// (c) donations and forced ETH only add surplus: no TransactionDeposited, no L2 claim created.
    function test_T5_donations_and_forced_eth_are_surplus_only() public {
        uint256 lb0 = LOCKBOX.balance;
        vm.startPrank(attacker, attacker);
        vm.recordLogs();
        PORTAL.donateETH{value: 1 ether}();
        new ForceSend{value: 1 ether}(payable(LOCKBOX));
        new ForceSend{value: 1 ether}(payable(L1SB));
        new ForceSend{value: 1 ether}(payable(L1CDM));
        (uint256 n,,) = _mintOf(vm.getRecordedLogs());
        vm.stopPrank();
        assertEq(n, 0);
        assertEq(address(PORTAL).balance, 1 ether);
        assertEq(LOCKBOX.balance - lb0, 1 ether);
    }
}
