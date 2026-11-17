from h import *
T11='2022_11-Invariant_Testing-TrailOfBits'
REPORT(T11,commit='optimism b31d35b67755479645dd150e7cc8c6710f0b4a56; op-geth a68e5aa189e14fde92cec03c1abd98cc7f0db263 (p8)',
 scope='Testing-strategy review: invariants of OptimismPortal + ResourceMetering, op-node, op-geth; Echidna/Slither/go test (p4,9).',
 oos='Concurrent/asynchronous cascading deposits+withdrawals were NOT tested; not all invariants documented; block production/fee computation not tested for all config permutations (p9-10).')
F(T11,'TOB-OPTEST-1','Undetermined','None','Risk of misconfigured GasPriceOracle state variables that can lock L2','CONFIG_TRUST',['OVM_GasPriceOracle (L2)','op-geth rollup_l1_cost.go'],['setOverhead','setScalar','setDecimals'],
 'owner sets overhead/scalar to extreme value','privileged misconfiguration','L2 txs (including the fix tx) not accepted; deadlock','owner fee exemption or max fee cap (recommendation)','acknowledged','p26',
 residual='SystemConfig bounds on fee scalars; forced inclusion via deposits bypasses L2 fee',later='Bedrock v1.0.0 moves overhead/scalar to L1 SystemConfig (deposits are fee-exempt so config can be repaired); Ecotone setGasConfigEcotone, Isthmus operator fee, Jovian DA footprint/min base fee (v5/v6)')
T1='2023_01-Bedrock_Updates-TrailOfBits'
REPORT(T1,commit='optimism 1bfe79f20b37a77c1158e7c5fdbff2ae109e0a1d; ee96ff8585699b054c95c6ff4a2411ee9fedcc87 (contracts); 991120f6d2009b4a96580d7db3021694439c63f5 (Merkle trie); op-geth 68bfa8b473bb8770216517f007b521fab41c5afa (p8)',
 scope='System-configuration workflow (SystemConfig, op-node ConfigUpdate parsing, op-geth L1 cost) and two-step withdrawal workflow (OptimismPortal prove/finalize) (p9-11).',
 oos='Late commits ee96ff8 (ResourceMetering, L2ToL1MessagePasser, L2OutputOracle changes) and 991120f (refactored MerkleTrie) and PRs 4329/4337 (OptimismPortal, CrossDomainMessenger) were reviewed but NOT evaluated in the context of the larger system (p11).')
F(T1,'TOB-OPTCW-1','High','High','Ability to block withdrawals by resubmitting withdrawal proofs','REPLAY_OR_DOUBLE_SPEND',['OptimismPortal'],['proveWithdrawalTransaction','finalizeWithdrawalTransaction'],
 'victim withdrawal proven and inside the finalization period','permissionless (anyone can re-prove)','re-proving overwrites provenWithdrawals[hash].timestamp and restarts the 7-day period indefinitely (temporary freeze, repeatable)',
 're-prove allowed only if the output root at the stored l2OutputIndex changed (PR 4057)','fixed','p15-16, fix review p24-25',fix_commit='PR 4057 (commit hash not stated)',
 residual='safety condition of the fix: provenWithdrawals is keyed by withdrawalHash only and a re-prove is gated on outputRoot mismatch at the stored index',
 siblings='proof submitter identity; delete/blacklist paths',
 later='v1.4.0 OptimismPortal2 REPLACES the condition: provenWithdrawals keyed by (withdrawalHash, proofSubmitter) and re-proving is unrestricted per submitter (finalizeWithdrawalTransactionExternalProof chooses the submitter); v4.0.0 super-root proofs; v9 deleteProvenWithdrawal')
S1='2023_01-Bedrock-Sherlock-contest'
REPORT(S1,commit='3f4b3c328153a8aa03611158b6984d624b17c1d9 (README index)',
 scope='All contracts in packages/contracts-bedrock, op-node, op-geth, migration tooling (op-chain-ops) per contest description; source: ext/2023-01-optimism-judging/README.md',
 oos='LES subprotocol declared unsupported by sponsor (M-7 discussion); privileged roles trusted; spec-only issues classed "S"')
F(S1,'H-1','High','Critical','Malicious user can finalize other\'s withdrawal with less than specified gas limit','GAS_ACCOUNTING',['OptimismPortal'],['finalizeWithdrawalTransaction'],
 'withdrawal direct via L2ToL1MessagePasser with gasLimit within 5122 gas of real need','permissionless third-party finalizer','gas check precedes SSTORE(l2Sender)+call prep so target gets gasLimit-5122; portal has no replay -> permanent loss',
 'SafeCall.callWithMinGas (check at the call site) introduced','fixed','README.md L1-235 (issue #109)',residual='portal has no replay; the finalizer is untrusted and chooses gas',
 siblings='L1CrossDomainMessenger.relayMessage (001-H folder: same class)',later='2023-03 H-3/M-1/M-4/M-6 re-open the class; v1.0.0 SafeCall.hasMinGas; v9 150k reserve + Amsterdam gas constants')
F(S1,'H-2','High','Critical','Withdrawals with high gas limits can be bricked (63/64 rule not accounted)','GAS_ACCOUNTING',['OptimismPortal'],['finalizeWithdrawalTransaction'],
 'withdrawal gasLimit >= 952,192','permissionless third-party finalizer','EIP-150 silently caps forwarded gas; finalize marks withdrawal done with insufficient gas -> permanent lock',
 'account for 63/64 in the min-gas check (callWithMinGas)','fixed','README.md L236-484',residual='EVM gas schedule (EIP-150/2929) constants hard-coded in SafeCall',
 later='gas-schedule changes: EIP-7623 floor cost, EIP-7825 cap, Amsterdam EIP-8037 (v9 constants)')
F(S1,'H-3','High','Critical','Causing users lose their fund during finalizing withdrawal (messenger reentrancy guard)','REENTRANCY_STATE_CLOBBER',['OptimismPortal','L1CrossDomainMessenger'],['finalizeWithdrawalTransaction','relayMessage'],
 'attacker contract is target of a messenger message; victim withdrawal finalizable','permissionless','attacker message re-enters portal.finalize for the VICTIM withdrawal while messenger.relayMessage is nonReentrant -> victim relay reverts inside portal, portal marks finalized, message never recorded as failed -> funds lost',
 'remove revert-on-reentrancy from the path: relayMessage records failedMessages instead of reverting; xDomainMsgSender-based guard (see v1.0.0)','fixed','README.md L485-654',
 residual='safety condition: a relayMessage call coming from the portal with a valid message must NEVER revert without recording success/failure',
 siblings='L2CrossDomainMessenger; any future wrapper between portal and messenger (ETHLockbox, SuperchainConfig pause check)',
 later='v1.2.0 adds paused() revert in relayMessage (2023_12 Trust review); v4.0.0 portal->lockbox->messenger path; v9 adds a NEW revert in the messenger relay path (PASS A C6/C7) — direct retouch of this safety condition')
F(S1,'M-1','Medium','High','Batcher frames are incorrectly decoded leading to consensus split','DERIVATION_CONSENSUS',['op-node derive/frame.go'],['Frame.UnmarshalBinary'],'malicious batcher frame without is_last byte','malicious batcher/sequencer','op-node accepts frame the spec rejects -> consensus split between implementations','return non-EOF error','fixed','README.md L655-786',
 later='second client (kona) makes this class live again; 2026_03 Kona review')
F(S1,'M-2','Medium','None','Censorship resistance undermined: deposits DoSed at low cost by filling MAX_RESOURCE_LIMIT','DOS_RESOURCE',['OptimismPortal','ResourceMetering'],['depositTransaction','metered'],'attacker buys the per-block deposit gas','permissionless, pays L1 gas','victim deposits revert in that block',
 'acknowledged; EIP-1559 style market kept','acknowledged','README.md L787-872',residual='KNOWN ISSUE on Immunefi (MAX_RESOURCE_LIMIT deposit griefing)',later='v1.0.0 ResourceConfig moved to SystemConfig; unchanged through v9')
F(S1,'M-3','Medium','None','Panic when decoding a malformed deposit transaction JSON string','DOS_RESOURCE',['op-geth'],['transaction JSON unmarshal'],'malicious RPC','remote RPC','client panic','nil check','fixed','README.md L873-943')
F(S1,'M-4','Medium','High','MigrateWithdrawal() may set gas limit so high that migrated withdrawals cannot be relayed on L1','GAS_ACCOUNTING',['op-chain-ops migrate.go','OptimismPortal'],['MigrateWithdrawal'],'legacy pending withdrawal with large calldata','none (migration bug)','migrated withdrawal gasLimit over L1 block limit -> unrelayable',
 'correct gas estimation (4/16 per byte)','fixed','README.md L944-1083',residual='migrated withdrawals carry a synthetic gasLimit computed once at migration',later='2023-03 H-1 (same object, opposite error); legacy withdrawals remain provable forever under any later portal')
F(S1,'M-5','Medium','None','Contract with only IOptimismMintableERC20 interface not compatible with StandardBridge','TOKEN_SEMANTICS',['StandardBridge'],['_isCorrectTokenPair'],'token without l1Token()','user','token unusable','support both interfaces','fixed','README.md L1084-1140')
F(S1,'M-6','Medium','Medium','Crafted p2p spam can render nodes unable to process L2 blocks','DOS_RESOURCE',['op-node p2p'],['BuildBlocksValidator'],'p2p','remote peer','targeted nodes halted','larger LRU','fixed','README.md L1141-1216')
F(S1,'M-7','Medium','None','LES does not forward the transaction to the sequencer','SPEC_MISMATCH',['op-geth les'],[],'LES used','n/a','tx not forwarded','no action (LES unsupported)','won\'t fix','README.md L1217-1381')
F(S1,'M-8','Medium','High','Optimism Portal can run out of gas due to incorrect overhead estimation','GAS_ACCOUNTING',['OptimismPortal'],['finalizeWithdrawalTransaction'],'see H-1','permissionless','same root cause as H-1 (5k SSTORE between check and call)','see H-1','fixed','README.md L1382-1554')
F(S1,'M-9','Medium','None','Migration can be bricked by sending a message directly to the LegacyMessagePasser','UPGRADE_SEQUENCING',['op-chain-ops','LegacyMessagePasser'],['migration witness parsing'],'pre-migration direct call to 0x4200..00','permissionless (pre-Bedrock)','migration halts','skip malformed entries','fixed','README.md L1555-1641',later='one-time OVM->Bedrock migration; residue = set of legacy withdrawals migrated')
F(S1,'M-10','Medium','None','Challenger can override the 7 day finalization period (deleteL2Outputs on finalized outputs)','CONFIG_TRUST',['L2OutputOracle'],['deleteL2Outputs'],'challenger deletes old outputs','privileged (challenger)','finalized-age outputs deletable; proven withdrawals must be re-proven','known/expected behaviour per sponsor','disputed','README.md L1642-1778',
 later='v1.0.0 adds check that outputs older than finalization period cannot be deleted; v1.4.0+ replaced by blacklist / respectedGameType / retirement timestamp')
F(S1,'M-11','Medium','None','Gasless ETH bridging from L1 to L2 (no minimum deposit gas limit)','DOS_RESOURCE',['OptimismPortal'],['depositTransaction'],'_gasLimit = 0','permissionless','L2 resources consumed without paying; metering circumvented',
 'require _gasLimit >= 21000 (later minimumGasLimit(byteCount))','fixed','README.md L1779-1879',later='2023-03 M-5 (calldata not included); v1.0.0 minimumGasLimit = len*16+21000; v3+/v9 floor-cost adjustments')
F(S1,'M-12','Medium','High','Deposits via L1CrossDomainMessenger fail and are not replayable when L2CrossDomainMessenger is paused','PAUSE_COVERAGE',['L1CrossDomainMessenger','L2CrossDomainMessenger'],['sendMessage','relayMessage whenNotPaused'],'L2 messenger paused while L1 deposits sent','privileged pause + ordinary users','relayMessage reverts at top level on L2 -> deposit tx fails, no failedMessages entry -> funds frozen',
 'pause removed from messenger for v1.0.0','fixed','README.md L1880-1932',residual='safety condition: no revert-before-record in relayMessage on the receiving side of a non-replayable transport',
 siblings='006-M folder: L1StandardBridge path',later='v1.2.0 RE-INTRODUCES paused() in L1CrossDomainMessenger.relayMessage (L1 side only, portal finalize also paused so atomic); v9 lockbox-identifier pause')
F(S1,'M-13','Medium','High','Withdrawal transactions can get stuck if output root is reproposed','STALE_STATE_AFTER_MIGRATION',['OptimismPortal','L2OutputOracle'],['proveWithdrawalTransaction'],'output at proven index deleted and re-proposed at different index/without the withdrawal','challenger/proposer action (or malicious proposer)','withdrawal cannot be re-proven (reprove only allowed at same index with changed root)',
 'allow re-prove when the output root at the stored index changed','fixed','README.md L1933-2064',residual='re-prove gate compares against a mutable external registry (L2OO index -> root)',
 later='v1.4.0: stored object is a DisputeGameProxy; re-prove unrestricted; v3/v4 validity via ASR; v9 deleteProvenWithdrawal calls status() on the stored address (queue B01)')
F(S1,'S-24','Spec/Low','Medium','Incorrectness in computing block signing hash allows cross-chain replay','SIGNATURE_REPLAY',['op-node p2p signer'],['SigningHash'],'two chains share sequencer key','remote','unsafe block gossip replay across chains (chain id not included)','include chain id','fixed','README.md L3493-3768')
F(S1,'S-7','Spec/Low','None','Address collision in cross-chain contract creation (deposit nonce 0 in receipt)','SPEC_MISMATCH',['op-geth'],['deposit receipts'],'contract creation via deposit','n/a','tooling miscomputes address','Regolith depositNonce in receipt','fixed','README.md L2385-2672',later='Regolith hardfork')
S1_SPEC=23
S3='2023_03-Bedrock-Sherlock-fix-review'
REPORT(S3,commit='9b9f78c6613c6ee53b93ca43c71bb74479f4b975 (README index)',
 scope='Fix review of the Bedrock contest: packages/contracts-bedrock, migration (op-chain-ops), op-node/op-geth; source: ext/2023-03-optimism-judging/README.md',
 oos='privileged roles; user misconfiguration judged Medium at most')
F(S3,'H-1','High','Critical','All migrated withdrawals that require more than 135,175 gas may be bricked','GAS_ACCOUNTING',['op-chain-ops migrate.go','OptimismPortal','L1CrossDomainMessenger'],['MigrateWithdrawal','finalizeWithdrawalTransaction','relayMessage'],
 'pending legacy (pre-Bedrock) withdrawal migrated with inner minGasLimit=0 and outer calldata+200k','permissionless finalizer','inner call OOG, 1/64 left insufficient to record failedMessages, portal still finalizes -> permanent loss',
 'migration gas computation changed + messenger reserves gas (RELAY_RESERVED_GAS) so failure is always recorded','fixed','README.md L1-469',
 residual='migrated legacy withdrawals keep the gas limits baked at migration; safety relies on messenger reserve >= cost of recording failure under the CURRENT gas schedule',
 later='v9 changes relay reserve constants (Amsterdam); unfinalized legacy withdrawals (if any remain) are consumed by v9 code with pre-Bedrock-era gas parameters')
F(S3,'H-2','High','Critical','Legacy withdrawals can be relayed twice (double spend) — successfulMessages storage wiped/layout changed at migration','STALE_STATE_AFTER_MIGRATION',['L1CrossDomainMessenger','L2CrossDomainMessenger'],['relayMessage (version 0 branch)'],
 'legacy v0 message already relayed before Bedrock','permissionless','old CrossDomainMessenger storage layout differs: legacy successfulMessages not visible to new check -> message relayed again as v1',
 'storage layout of new messenger aligned with legacy (spacers) so legacy successfulMessages slot 203 is read; migration prechecks','fixed','README.md L470-536',
 residual='safety condition: the legacy successfulMessages mapping stays at the same slot and the v0-hash check in relayMessage stays in the code path for version-0 nonces',
 siblings='L1ERC721Bridge / L1StandardBridge legacy storage; ResolvedDelegateProxy-backed L1CDM',
 later='every L1CDM version through v9 (2.13.0) must keep slot 203 spacer semantics + legacy branch (queue B02/B10)')
F(S3,'H-3','High','Critical','The formula used in SafeCall.callWithMinGas() is wrong (EIP-150/EIP-2929 dynamic costs)','GAS_ACCOUNTING',['SafeCall','OptimismPortal','CrossDomainMessenger'],['callWithMinGas'],
 'cold target and/or value transfer','permissionless finalizer','sub-call receives less than _minGas; portal finalization bricks withdrawal',
 'formula corrected: 64/63 + 40_000 reserve + hasMinGas helper','fixed','README.md L537-900',residual='hard-coded CALL dynamic-cost bound (cold access 2600, value 9000, new-account 25000)',
 later='EIP-7702 delegated targets, Amsterdam repricing; v9 constants')
F(S3,'M-1','Medium','Critical','CrossDomainMessenger does not guarantee replayability (not enough gas left to record success/failure)','GAS_ACCOUNTING',['L1CrossDomainMessenger','OptimismPortal'],['relayMessage'],
 'user min gas limit too low for target','permissionless finalizer','portal finalizes; messenger OOG before writing successfulMessages/failedMessages -> message lost',
 'messenger forwards gasleft()-RELAY_RESERVED_GAS and pre-checks hasMinGas, else records failure','fixed','README.md L901-1068',
 residual='RELAY_RESERVED_GAS (40k) >= worst-case cost of the post-call bookkeeping incl. SSTORE + event with message-size-dependent hashing',
 later='v9 raises reserve to 150k and fixes "finalized-without-record" for 100 kB payloads (PASS A C6) — proves the v1..v8 reserve was insufficient for large messages')
F(S3,'M-2','Medium','None','Gas usage of cross-chain messages undercounted (relayMessage wrapper calldata not counted in baseGas)','GAS_ACCOUNTING',['CrossDomainMessenger'],['baseGas','sendMessage'],'any message','n/a','L1->L2 messages underpriced by ~2240 gas','count wrapper calldata in baseGas','fixed','README.md L1069-1187',later='baseGas rewritten (RELAY_CONSTANT_OVERHEAD etc.), v3 floor cost, v9')
F(S3,'M-3','Medium','None','Malicious actor can prevent migration via non-existing function call to OVM_L2ToL1MessagePasser','UPGRADE_SEQUENCING',['op-chain-ops'],['ReadWitnessData'],'pre-migration','permissionless','migration halted','skip','fixed','README.md L1188-1271')
F(S3,'M-4','Medium','High','Usage of revert in case of low gas in L1CrossDomainMessenger can result in loss of funds','GAS_ACCOUNTING',['L1CrossDomainMessenger','SafeCall'],['relayMessage','callWithMinGas'],
 'future gas schedule change or mis-sized baseGas makes the inner hasMinGas check fail while the portal check passed','permissionless finalizer','messenger reverts (instead of recording failure) inside portal finalize -> withdrawal finalized without record',
 'relayMessage uses hasMinGas and records failedMessages instead of reverting (non-reverting path)','fixed','README.md L1272-1493',
 residual='EXPLICIT safety condition: nothing in relayMessage may revert for a portal-originated first relay (except the paused/unsafe-target checks that revert before any state)',
 later='v1.2.0 paused revert; v9 new revert (PASS A C6/C7)')
F(S3,'M-5','Medium','None','Incorrect calculation of required gas limit during deposit transaction (calldata not included)','DOS_RESOURCE',['OptimismPortal'],['depositTransaction'],'large _data, _gasLimit just above 21000','permissionless','L2 resources used without compensation','minimumGasLimit(byteCount)=byteCount*16+21000','fixed','README.md L1494-1549',later='v3+ / v9: EIP-7623 floor (40 per byte) adjustments')
F(S3,'M-6','Medium','Critical','Users lose funds bridging long messages L2->L1 (memory expansion not in baseGas -> OOG)','GAS_ACCOUNTING',['CrossDomainMessenger','OptimismPortal'],['baseGas','relayMessage'],
 'long message','permissionless finalizer','relayMessage OOG before bookkeeping; portal finalized -> loss','reserve gas / hasMinGas; later calldata size caps','fixed','README.md L1550-end',
 residual='message size bounded so bookkeeping cost fits in the reserve',later='v9 fix for 100 kB payloads (PASS A C6): the same class remained reachable v1..v8')
