# PRIM-CF2-03 — Game type, prestate, and root format form a versioned proof tuple

## Primitive

Withdrawal validity is keyed by more than the current respected game type. The relevant tuple is game type, absolute prestate, root format, respected-at-creation status, ASR/DGF object, and Portal validation code. Old objects can remain finalizable after current mappings rotate.

## Three-hop edge

- Create at U18: type 8 `CANNON_KONA` is installed with prestate `0x0323914d3050e80c3d09da528be54794fde60cd26849cd3410dde0da7cd7d4fa`, but type 0 remains respected (`upgrade-18.mdx:17-40,83-123`).
- Transform at U19: type 8 becomes respected and type 0 is disabled only for new games; in-flight type-0 games remain resolvable (`upgrade-19.mdx:30-34,60-64`). U19 prestate is `0x0337ecb3604c0b40c352e0c7711beb17a212d583f4fe956fd8d66e29ad5f9025`.
- Consume/transform at U20/U21: permissionless chains move to type 9 super roots, then rotate the type-9 prestate from `0x031ac6…` to `0x03e5a5…`. Portal deliberately supports old output-root and new super-root proofs (`upgrade-20.mdx:24-55,101-112`; `upgrade-21.mdx:99-176`).

## Audit use

Model each created game/proof against its creation-time tuple, not the latest DGF mapping. Exercise old-game finalization across every ASR/Portal upgrade, challenger-win/blacklist deletion, respected-type rotation, and root-format boundary. Separately prove that a standard upgrade cannot inherit the proof-invalidating semantics of `OPCM.migrate()`.

## Outcome

Mechanism established. U20 and the executed U21 standard upgrade retain existing proofs; only future one-way migration blanket-invalidates them, while U21 deletion is limited to challenger-won or blacklisted games (`OptimismPortal2.sol:707-727` at v9.0.0).
