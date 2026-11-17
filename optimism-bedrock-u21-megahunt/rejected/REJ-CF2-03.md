# REJ-CF2-03 — Granite/U7 AnchorStateRegistry storage is the live U21 ASR state

## Hypothesis

If the ASR proxy had survived from U7, Granite's recovery-era state/permissions or anchors could persist into U21 despite later implementation upgrades.

## Falsification

Passive implementation-slot reconstruction shows three different proxies:

1. U7 ASR `0x18DAc71c228D1C32c99489B7323d441E1175e443`, upgraded by Granite from 1.0.0 to 2.0.0 and retired at U13.
2. U13 replacement `0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b`, version 2.2.2, retired at U16.
3. Current U16 ASR `0x23B2C62946350F4246f9f9D027e071f0264FD113`, versions 3.5.0→3.7.0→3.9.0→4.0.0 through U21.

U13 source explicitly deploys a replacement proxy (`OPContractsManager.sol:542-580` at v2.0.0); U16 source deploys `AnchorStateRegistry-U16` (`OPContractsManager.sol:662-699` at v4.0.0). Raw blocks, implementations and receipts are in `impl-history-op-mainnet.json`.

## Disposition

Rejected as a current-storage aliasing theory. The old objects remain relevant only to historical games/proofs that reference them; they are not the live U21 ASR proxy state.
