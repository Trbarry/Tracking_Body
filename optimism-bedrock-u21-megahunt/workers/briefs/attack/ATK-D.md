# LANE D — TROJAN SUPER-ROOT GAME AS A PROTOCOL ATTACK

Inputs: A-023, lead L4, PRIM-0503, PRIM-0701, PRIM-0903, PRIM-2701, PRIM-2702 (PASS A). Known mechanic:
anyone can create a respected type-9 game whose super root is non-canonical (extra / duplicated /
unsorted chain entries; L1 takes the first match) yet embeds the TRUE per-chain output root; the portal
accepts an unmodified honest proof against it; the game later loses (CHALLENGER_WINS); the proof is
dead and permissionlessly deletable; the user re-proves and waits 7 days again. Bond 0.08 ETH on OP.

Mission:
1. Reproduce end to end on a fork with deployed contracts: create the trojan game, prove a real
   withdrawal (fixtures) against it, resolve it CHALLENGER_WINS through real moves if feasible (else
   label the status manipulation), delete the proof, re-prove. Record who gets the bond.
2. Tooling: determine, from source, how the OFFICIAL and widely used withdrawal tooling selects the game
   to prove against, and whether it validates the super root (against a supernode/op-node output) before
   proving: monorepo `op-node/withdrawals`, `op-service`/`op-chain-ops` helpers, `op-e2e` utilities,
   any relayer in the monorepo, and the docs under `docs/public-docs` describing proving (and, if
   reachable via git/raw.githubusercontent.com, viem's `op-stack` actions — `getGame`/`buildProveWithdrawal`
   — and the Superchain bridge UI's selection logic). Quote the exact selection code.
3. Shared relayers/forwarders: can an attacker overwrite or replace a relayer's good proof with a trojan
   proof (proofs are per-submitter: attacker cannot write the relayer's slot — confirm), or trap victims
   who did not choose the malicious game? Is there any production relayer that proves automatically for
   users (fee-vault withdrawals, bridges)? Name it with evidence.
4. Quantify: attacker capital lost or recoverable per game; victims per game (every proof made against
   it); honest proposal cadence vs attacker cadence; maximum repeatable delay; can standard withdrawals
   be kept unavailable indefinitely for users of the default tooling?
5. Compose with the planned OP+Unichain shared migration (two-chain super roots) — label FUTURE-ONLY.
6. Map the result to the exact SCOPE.md 1.4 impact line (e.g. "Temporary freezing of funds ... (e.g.
   recoverable via an upgrade)" is High; a delay that the user can avoid by proving against another game
   is not freezing). Apply -4 if the victim's own tooling choice is what selects the game unless that
   tooling is official/default.
