# REJ-CF5-02 — unexpected live sibling games are invalid permissionless proposals

After accounting for official proposer rotations, Ink index 2638 and Unichain index 17586 are the only in-progress/claim-valid games not made by a historical official proposer. Both are type 9, in progress, and `isGameClaimValid == false`. Independent post-Isthmus L2-header reconstruction mismatches both embedded roots (`mirror/CF5/evidence/output-root-verification.json`). Permissionless creation of an invalid bonded proposal is expected fault-proof behavior; rejected.
