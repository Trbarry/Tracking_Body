# ATTACK-T1-11 — Creator identity: tx.origin-authorised (super-)permissioned games, DEFENDER_WINS at creation

Lane ATK-T1, Opus 5.5. Target 11 (row 13). Kill type: failing experiment + privileged.

**Original condition.** Sherlock FP M-3 fixed only permissionless games (factory passes the creator). v9
`SuperPermissionedDisputeGame.sol:60` authorises `tx.origin == proposer()` and sets DEFENDER_WINS at creation (:66-68); Soneium
respects type 5; OP/Ink/Unichain register type 5 but respect 9.

**Sequence executed.** `T1_Registry.t.sol::test_T1_03_txOriginTypesClosed` + `test_T1_01_…`: type-5 proposers read from the live
`gameArgs(5)` (OP 0xc27b…5bE0, Ink 0x3832…D177, Soneium 0x400c…E1b8, Unichain 0x86b3…75b7) are code-less EOAs (no EIP-7702
delegation designator); attacker `create(5,…)` directly and through an attacker relay contract reverts on all four chains.

**Barrier.** The only origin that can create a type-5 game is the proposer key; there is no permissionless path by which an attacker
contract executes inside a proposer-originated transaction (ATTACK-F-07: Soneium proposer nonce 8537 == its game count, it only ever
calls `create`). Requires leaked key / social engineering (out of authorization). On OP/Ink/Unichain type 5 is not respected
(`isGameRespected` false). Known: U20 3.2.4 (Part 2 #8). Output: `evidence/attack-wave/T1/T1_Registry.out.txt`.
