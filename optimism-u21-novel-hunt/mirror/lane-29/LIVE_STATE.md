# Lane 29 live state and event evidence

All L1 reads are passive. `pre` is `http://127.0.0.1:8546` at block 26430858,
`N` is `http://127.0.0.1:8547` at block 26430859, and `later` is
`http://127.0.0.1:8545` at block 26433900. Addresses are shown checksummed where
practical. Source commit: `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`.

## Block 26433900

All four lockboxes return `version() = 2.0.0`, `paused() = false`, initialized
byte `1`, and `superchainConfig() = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C`.
All four portals return `version() = 6.1.0`, initialized byte `3`,
`l2Sender() = 0x000000000000000000000000000000000000dEaD`, and zero ETH balance.

| Chain | Portal | Lockbox | Lockbox balance (ETH) | ProxyAdmin | ProxyAdmin owner |
|---|---|---|---:|---|---|
| OP (10) | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | 182541.068255115703234018 | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` |
| Ink (57073) | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | 23088.758336628210326229 | `0xd56045E68956FCe2576E680c95a4750cf8241f79` | same Safe |
| Soneium (1868) | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | 2195.560152606106316659 | `0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a` | same Safe |
| Unichain (130) | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | 18266.157945407766718622 | `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | same Safe |

Every portal and lockbox pair for a chain reports the ProxyAdmin in the table.
The four ProxyAdmins are distinct but have the same owner.

The EIP-1967 implementation slots at block N are identical across all four:

- portal implementation `0xb20B23af6071405C37dDDA0C0640e8eBb7899645`, 23,173 bytes,
  runtime keccak `0xfa4b463e4752a7ba51c244c04e3574e796f023c361bf0a6f8673e53bdbd03f6e`;
- lockbox implementation `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe`, 5,006 bytes,
  runtime keccak `0xccd3ca72b4aa8413a2a76143a32c92e1f0f3503e82c177767dffbb8ee79ba362`.

## Authorization matrices

Rows are lockboxes and columns are portals, in OP / Ink / Soneium / Unichain order:

```text
authorizedPortals
true  false false false
false true  false false
false false true  false
false false false true
```

For `authorizedLockboxes`, every one of the 16 entries in the four-by-four known-lockbox
cross product is `false`. These matrices were identical at N-1, N, and block 26433900.
The fork test `test_liveAuthorizationMatricesAreDiagonalAndLockboxMatrixEmpty` checks the
deployed contracts at N.

## SystemConfig migration preconditions

At block 26433900 all four SystemConfigs report:

- `ETH_LOCKBOX = true`, `INTEROP = false`, `CUSTOM_GAS_TOKEN = false`, `paused = false`;
- `lastUsedOPCM() = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` and
  `lastUsedOPCMVersion() = "9.0.3"`;
- the same SuperchainConfig above, version `2.5.0`;
- `OPContractsManagerV2.isPermittedMigrateSequence` is `true` for OP Mainnet and Unichain.

OP Mainnet and Unichain have chain IDs 10 and 130, distinct ProxyAdmins with the same owner,
and combined current old-lockbox liquidity of exactly
`200807226200523469952640` wei (200807.226200523469952640 ETH). Both portal balances are zero.

The L1StandardBridge and L1CrossDomainMessenger balances are zero for all four chains. The
per-chain DelayedWETH balances are dispute-game assets, not L2 ETH backing: OP
`20.662782 ETH`, Ink `5.710376 ETH`, Soneium `0`, Unichain `21.419797 ETH`.

## Exact N-1 -> N storage facts

At N-1 every lockbox was version 1.3.1. At N each was version 2.0.0. Slot 0 did not
change: low byte `0x01` remained initialized and bytes 2..21 retained the legacy per-chain
SystemConfig address as the v9 spacer. Slot 3 changed from zero to the common SuperchainConfig.

Every portal changed from version 5.8.0 to 6.1.0, while the inspected proxy state stayed
constant: slot 0 initialized byte `3`, slot 50 `0x...dEaD`, slot 55 per-chain SystemConfig,
slot 62 per-chain AnchorStateRegistry, and slot 63 per-chain lockbox. Portal balance stayed zero.

The OP lockbox balance changed from `182416306525160721816415` wei at N-1 to
`182420511216757812708529` wei at end-of-N. This was a 4.204691597090892114 ETH
`ETHLocked` in transaction index 0x155, before the U21 transaction at index 0x166; the U21
receipt itself moved no liquidity. The other three lockbox balances were unchanged across the
block.

## Events

The saved U21 receipt contains one expected `PortalAuthorized` for each lockbox and its own
portal. It contains no `LockboxAuthorized`, `LiquidityMigrated`, or `LiquidityReceived` event.

An `eth_getLogs` scan over the 10,000 blocks 26423901..26433900, split into 100-block
ranges because of public endpoint limits, found only those same four `PortalAuthorized` events
for the four authorization/migration topics. Most ranges used
`https://ethereum-rpc.publicnode.com`; four endpoint-limited ranges were rechecked on
`https://eth.drpc.org`. No unexpected authorization or migration event was found.

From N through block 26433900 inclusive, normal liquidity events were:

- OP: 16 locks totaling 124.781398637077677658 ETH; 3 unlocks totaling
  0.019668682096260055 ETH. Excluding the earlier-in-block-N lock, this exactly explains the
  N-to-later balance increase of 120.557038357890525489 ETH.
- Unichain: one lock of 43.810927375207071116 ETH and no unlock, exactly matching its balance delta.
- Ink and Soneium: no lock/unlock events in that interval.

## Cross-portal L2 alias state

The L1-to-L2 aliases of the four L1 portals are:

| Source portal | Alias |
|---|---|
| OP | `0xcfc6fc579115071764c7423a4f12edde41f117fe` |
| Ink | `0x6e77c1782664115999c47c9fa5cd031f495d4f60` |
| Soneium | `0x99f629a6ccd302c948689cd5156c83d4614fbfa3` |
| Unichain | `0x1ce58f6b86a26d3a217d0fa6ffe2b491b956b8b3` |

All 16 alias/target-chain combinations had balance zero, nonce zero, and no code when queried
on OP Mainnet (pinned block 159654093), Ink (near block 61412168), Soneium (near 30887914),
and Unichain (near 64162220). The latter three reads used their public RPCs and were passive.

For comparison, each chain's own L1CrossDomainMessenger alias has a high nonce and sometimes
dust, but the messenger blocks its own portal as a relay target. Every cross-chain messenger
alias had zero balance/nonce/code. No v9 core L2 contract authorizes a portal alias; the only
generic alias checks are the paired L1CrossDomainMessenger check and configurable
`CrossDomainOwnable` helpers.

The interop `ETHLiquidity` predeploy `0x4200...0025` is presently an uninitialized proxy with
zero balance on all four chains. v9 genesis code preloads it with `type(uint128).max` only when
the interop-gated implementation is activated, and `ETHLiquidity.mint` is restricted to the
SuperchainETHBridge (`src/L2/ETHLiquidity.sol:43-48`). The documented backing invariant excludes
the ETH held by that contract.

