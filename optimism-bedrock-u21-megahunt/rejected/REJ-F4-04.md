REJ-ID: REJ-F4-04
Title: "A proxy crossed an incompatible re-layout in place (AnchorStateRegistry v1.4->v2->v4, DelayedWETH OwnableUpgradeable drop at v4.0.0, DGF mid-layout insertion v1.1->v1.2, v1.1.0 portal/SystemConfig/L2OO orders)"

Killing fact
- ASR: three separate proxies, one per layout (0x18DAc71c… v1.4 layout frozen at 2.0.0; 0x1c68ECfb… v2 layout, never
  upgraded past 2.2.2; 0x23B2C629… v4+ layout from 22990599). DelayedWETH: ten proxies; g1-g3 keep the Ownable layout,
  g4/g5 and the live 0x1B6DBF05… were born on the v4 layout (`evidence/F4/hist-DelayedWETH-*.json`). DGF proxy born under
  1.0.0 (v1.4.0 layout) in 2024-05-16: never held the v1.1.0 layout. v1.1.0 portal / SystemConfig / L2OO code never ran
  on OP Mainnet (implementation history, `evidence/F4/hist-*.json`); the other three chains were born >= v1.6/v1.8 code.
- The only in-place unit change found (ASR slot 4 at U20) is PRIM-F4-01, not a layout change.
