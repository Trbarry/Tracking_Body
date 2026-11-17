# Tooling and relayer selection evidence

## Contract primitive

At `op-contracts/v9.0.0` commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`:

- `Encoding.sol:308-344` checks version, minimum/stride length, then decodes every `(chainId, root)` pair. It does not enforce ordering, uniqueness, or a canonical chain set.
- `SuperFaultDisputeGame.sol:277-279` checks only that `rootClaim == keccak256(encoded preimage)`.
- `SuperFaultDisputeGame.sol:809-818` returns the first entry matching the requested chain ID.
- `OptimismPortal2.sol:437-449` compares the withdrawal output proof only with that per-chain result.
- `OptimismPortal2.sol:480-484` keys the stored proof by `(withdrawalHash, msg.sender)` and expressly permits re-proving, resetting the timer.
- `OptimismPortal2.sol:711-727` permits deletion only after challenger win/blacklist, but immediate same-submitter re-proving does not require deletion.

The exact source is locally reproducible with:

```bash
git -C /home/user/ethereum-optimism/optimism show \
  op-contracts/v9.0.0:packages/contracts-bedrock/src/dispute/SuperFaultDisputeGame.sol
```

## op-node helper

The same v9 tag's `op-node/withdrawals/utils.go`:

- lines 209-245 search backward and return the first/latest game whose sequence covers the withdrawal;
- lines 269-288 decode the super root and return the first matching chain entry;
- lines 157-170 build an L2 proof at that game timestamp and compare the recomputed output root only to the selected per-chain output.

Therefore one newly latest trojan whose first chain-10 entry is the genuine timestamp output root passes the helper. `test_toolingCompatibleRecentRoot_provesPersistentRealWithdrawal` reproduces both data conditions and portal acceptance.

## viem 2.51.0 (the OP Upgrade-20 minimum)

Pinned source tag commit: `f6ce88620d8c6b9546dbef1cf3a5f91ff057ebc0`.

- `getGames.ts:89-152`: default limit 100 and `findLatestGames` of the respected type; only sequence coverage is filtered.
- `getGame.ts:92-105`: direct default strategy is `latest`; optional strategy is `random`.
- `waitForNextGame.ts:102-105`: the path used by `waitToProve` forces `random`.
- `waitToProve.ts:147-160`: returns that game to the caller.
- `buildProveWithdrawal.ts:124-164`: obtains the L2 block and MPT proof at the game timestamp, checks timestamp equality, but never validates the full super-root preimage/root claim.

Source URL pattern: `https://github.com/wevm/viem/blob/viem%402.51.0/src/op-stack/actions/<file>.ts`.

Selection consequence for `N <= 100` eligible games and `k` attacker games: recommended `waitToProve` selects a trojan with probability `k/N`; direct/default-latest consumers select a newly latest trojan deterministically until displaced. Flooding 100 latest eligible games makes the viem window attacker-only and locks 8 ETH in bonds, expected to be lost to honest counterers.

## Production-facing relayer evidence

The public `ethereum-optimism/superchain-relayer` repository at commit `043a5715ddae7860bd8d01aa1f4a2a97b8b16f51` redirects to `https://console.optimism.io/relayer`. Its README calls it a UI; its code requires the user's wallet to execute `proveWithdrawal`.

On 2026-11-17, the deployed console page loaded `/assets/index-CnONNpH0.js` (SHA-256 `85c398ce1587e316e69f900b2238d1741fcbaa41ff8ec1b6bd2ff7ce8e828a4a`). The bundle says: `Use the Relayer to manually submit your cross chain transactions.` The route is feature-flagged. The bundle contains a default-latest game selector, but also an older extra-data decoder; this is not evidence of a currently working automatic proving service.

Passive portal logs show a dedicated EOA `0x431f5015b7c05fe792aea2a05158919af1e8ddf5` submitted 135 of 487 proofs in the measured window (nonce 140 at the pin). No authoritative source attributed that address. It is therefore recorded as a high-volume submitter, not named as a production relayer.

Conclusion: tooling exposure is demonstrated; an automatic named production relayer that silently proves for unrelated users is not. Even for a shared submitter, the attacker cannot write that submitter's mapping slot without its key.
