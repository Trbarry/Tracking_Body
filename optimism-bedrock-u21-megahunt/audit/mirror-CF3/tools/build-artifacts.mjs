import fs from "node:fs";
import path from "node:path";

const OUT = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/audit/mirror-CF3";
const CORPUS = "/home/user/ethereum-optimism/audits-txt";
const records = [];

const severityMap = {
  Critical: "Immunefi Critical only if the report's impact still satisfies a current Critical impact; historical label is not an automatic promotion",
  High: "Immunefi High only if the report's impact still satisfies a current High impact; historical label is not an automatic promotion",
  Medium: "Immunefi Medium only if the report's impact still satisfies a current Medium impact; historical label is not an automatic promotion",
  Low: "below current reward threshold (the current Optimism Immunefi table has no Low tier)",
};

const vocab = [
  "AUTHORIZATION_OR_ROLE_BINDING",
  "GAS_ACCOUNTING_OR_EIP150",
  "IDENTITY_DOMAIN_OR_NAMESPACE_BINDING",
  "UPGRADE_MIGRATION_STATE_CONTINUITY",
  "PROOF_OR_TRACE_SOUNDNESS",
  "STATE_MACHINE_ORDERING_OR_REPLAY",
  "INPUT_VALIDATION_OR_TYPE_CONFUSION",
  "LIQUIDITY_OR_VALUE_ACCOUNTING",
  "PAUSE_OR_INCIDENT_RESPONSE",
  "RESOURCE_EXHAUSTION_OR_DOS",
  "STORAGE_LAYOUT_OR_INITIALIZATION",
  "CONSENSUS_OR_DERIVATION_DIVERGENCE",
  "CRYPTOGRAPHIC_OR_SERIALIZATION",
  "EXTERNAL_CALL_OR_TOKEN_SEMANTICS",
];

function rootClass(title) {
  const t = title.toLowerCase();
  if (/gas|eip-150|out.of.gas|oog|basefee|scalar|overhead/.test(t)) return vocab[1];
  if (/chain id|domain|identifier|game type|version|nonce|replay|source.auth|registry/.test(t)) return vocab[2];
  if (/migrat|upgrad|legacy|initialize|reinitial|cutover|rollback|deployment/.test(t)) return vocab[3];
  if (/proof|trace|preimage|mips|cannon|output root|anchor|dispute|claim|futex|instruction|syscall/.test(t)) return vocab[4];
  if (/pause|guardian|incident|liveness/.test(t)) return vocab[8];
  if (/liquidity|fund|eth|token|bond|balance|withdraw|bridge|fee|value/.test(t)) return vocab[7];
  if (/storage|slot|implementation|proxy|constructor/.test(t)) return vocab[10];
  if (/consensus|derivation|batch|channel|sequencer|l1 origin|fork/.test(t)) return vocab[11];
  if (/rlp|ssz|signature|eip-712|encoding|decode|cast|overflow|underflow|memory/.test(t)) return vocab[12];
  if (/call|erc20|erc721|target|recipient|transfer|precompile/.test(t)) return vocab[13];
  if (/dos|denial|panic|crash|unbounded|spam|block|bricked|stuck|freeze/.test(t)) return vocab[9];
  if (/owner|auth|permission|access|role|admin|relayer|proposer|challenger/.test(t)) return vocab[0];
  if (/replay|ordering|front.run|finaliz|state/.test(t)) return vocab[5];
  return vocab[6];
}

const contractNames = [
  "OptimismPortal", "OptimismPortal2", "ETHLockbox", "L1CrossDomainMessenger",
  "L2CrossDomainMessenger", "CrossDomainMessenger", "L1StandardBridge", "L2StandardBridge",
  "L1ERC721Bridge", "L2ERC721Bridge", "StandardBridge", "SystemConfig", "SuperchainConfig",
  "AnchorStateRegistry", "DisputeGameFactory", "FaultDisputeGame", "PermissionedDisputeGame",
  "SuperFaultDisputeGame", "SuperPermissionedDisputeGame", "DelayedWETH", "OPContractsManager",
  "OPContractsManagerV2", "OPContractsManagerMigrator", "OPContractsManagerMigrationValidator",
  "OPContractsManagerStandardValidator", "ProxyAdmin", "SafeCall", "MIPS", "MIPS64",
  "PreimageOracle", "L2ToL1MessagePasser", "LegacyMessagePasser", "L2OutputOracle",
  "OptimismMintableERC20Factory", "L2ToL2CrossDomainMessenger", "CrossL2Inbox", "SuperchainETHBridge",
  "ETHLiquidity", "FeeVault", "DeputyPauseModule", "LivenessModule", "LivenessModule2",
];

function affectedContracts(title, fallback = []) {
  const found = contractNames.filter((name) => title.toLowerCase().includes(name.toLowerCase()));
  if (/portal/i.test(title) && !found.some((x) => x.startsWith("OptimismPortal"))) found.push("OptimismPortal family");
  if (/bridge/i.test(title) && !found.some((x) => /Bridge/.test(x))) found.push("bridge family");
  if (/messag/i.test(title) && !found.some((x) => /Messenger|MessagePasser/.test(x))) found.push("messenger family");
  if (/validator/i.test(title) && !found.some((x) => /Validator/.test(x))) found.push("OPCM validator family");
  if (/game/i.test(title) && !found.some((x) => /Game|Registry/.test(x))) found.push("dispute-game family");
  return [...new Set([...found, ...fallback])];
}

function affectedFunctions(title) {
  const out = [];
  for (const m of title.matchAll(/(?:[A-Za-z0-9_]+(?:\.|::|#))([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(\))?/g)) out.push(m[1]);
  for (const name of ["initialize", "upgrade", "migrate", "relayMessage", "sendMessage", "sendETH", "proveWithdrawalTransaction", "finalizeWithdrawalTransaction", "challengeRootL2Block", "setAnchorState", "setImplementation", "deploy", "baseGas", "callWithMinGas", "burn", "fund"]) {
    if (title.toLowerCase().includes(name.toLowerCase())) out.push(name);
  }
  return [...new Set(out)];
}

function conditionFor(cls) {
  return {
    AUTHORIZATION_OR_ROLE_BINDING: "The cited entrypoint is reached by the role/caller combination described in the source finding.",
    GAS_ACCOUNTING_OR_EIP150: "A boundary gas limit, message size, or EIP-150 forwarding state reaches the cited path.",
    IDENTITY_DOMAIN_OR_NAMESPACE_BINDING: "A mismatched, reused, or insufficiently bound identifier/configuration is accepted by the cited path.",
    UPGRADE_MIGRATION_STATE_CONTINUITY: "The deployment or upgrade history reaches the migration/initialization state described by the source.",
    PROOF_OR_TRACE_SOUNDNESS: "A crafted game, proof, trace, instruction, or preimage input reaches the cited verifier path.",
    STATE_MACHINE_ORDERING_OR_REPLAY: "Calls or state transitions occur in the ordering/replay condition described by the source.",
    INPUT_VALIDATION_OR_TYPE_CONFUSION: "The affected parser or entrypoint accepts the cited malformed, boundary, or unsupported input.",
    LIQUIDITY_OR_VALUE_ACCOUNTING: "Value or bond flow reaches the cited failure/mis-accounting state.",
    PAUSE_OR_INCIDENT_RESPONSE: "The relevant pause/guardian state and identifier combination exists.",
    RESOURCE_EXHAUSTION_OR_DOS: "An attacker or malformed input can repeatedly reach the cited resource-exhausting/reverting path.",
    STORAGE_LAYOUT_OR_INITIALIZATION: "The proxy/implementation storage or initializer state matches the source finding.",
    CONSENSUS_OR_DERIVATION_DIVERGENCE: "Different honest implementations or nodes process the cited input/state differently.",
    CRYPTOGRAPHIC_OR_SERIALIZATION: "The cited encoding, cast, signature, or arithmetic boundary is reached.",
    EXTERNAL_CALL_OR_TOKEN_SEMANTICS: "The cited external-call, target-code, or non-standard token behavior occurs.",
  }[cls];
}

function attackerFor(cls) {
  if ([vocab[3], vocab[8], vocab[10]].includes(cls)) return "Usually privileged operator/governance or misconfiguration; permissionless exploitability is not inferred unless the source says so.";
  if ([vocab[4], vocab[9], vocab[11]].includes(cls)) return "Permissionless malformed-input/game/message submitter where the report permits it; otherwise the report's stated role.";
  return "The source report's stated caller or user; this catalog does not broaden the attacker model.";
}

function norm(s) {
  return String(s).normalize("NFKD").toLowerCase().replace(/[^a-z0-9]+/g, " ").replace(/\s+/g, " ").trim();
}

const textCache = new Map();
function reportPage(file, title, manualPage, findingId) {
  if (manualPage) return manualPage;
  if (!file) return null;
  const full = path.join(CORPUS, file);
  if (!fs.existsSync(full)) return null;
  if (!textCache.has(full)) textCache.set(full, fs.readFileSync(full, "utf8").split("\f"));
  const needle = norm(title).split(" ").slice(0, 7).join(" ");
  let hit = null;
  textCache.get(full).forEach((p, i) => { if (norm(p).includes(needle)) hit = i + 1; });
  if (hit === null && findingId) {
    const idNeedle = `${norm(findingId)} ${norm(title).split(" ").slice(0, 2).join(" ")}`;
    textCache.get(full).forEach((p, i) => { if (norm(p).includes(idNeedle)) hit = i + 1; });
  }
  if (hit === null && findingId) {
    const idOnly = norm(findingId);
    textCache.get(full).forEach((p, i) => { if (i > 1 && norm(p).includes(idOnly)) hit = i + 1; });
  }
  return hit;
}

function laterTags(meta, title, cls) {
  const report = meta.report;
  // Family-level retouches are emitted only where the indexed later review scopes or the
  // ranked code checks establish them. This is deliberately not a generic "all later tags" list.
  if (/2020-|2021-|2022-05 OpenZeppelin Bedrock/.test(report)) return ["v1.0.0 (Bedrock abstraction replacement; family-level only)"];
  if (/Sherlock Bedrock|Bedrock updates/.test(report)) return ["v1.2.0", "v4.0.0", "v9.0.0"];
  if (/Trust SuperchainConfig/.test(report)) return ["v1.3.0", "v4.0.0", "v9.0.0"];
  if (/MCP L1/.test(report)) return ["v4.0.0", "v7.0.0", "v9.0.0"];
  if (/Fault Proof MIPS|Fault Proof no-MIPS/.test(report)) return ["v1.8.0", "v2.0.0", "v8.0.0", "v9.0.0"];
  if (/Upgrade 13/.test(report)) return ["v4.0.0", "v6.0.0", "v8.0.0", "v9.0.0"];
  if (/Interop Portal|Upgrade 16|Wonderland ETHLockbox/.test(report)) return ["v4.1.0", "v7.0.0", "v8.0.0", "v9.0.0"];
  if (/U16a/.test(report)) return ["v5.0.0", "v6.0.0", "v7.0.0", "v8.0.0", "v9.0.0"];
  if (/Custom Gas Token|Upgrade 18/.test(report)) return ["v7.0.0", "v8.0.0", "v9.0.0"];
  if (/Upgrade 19|OPContractsManager v2/.test(report)) return ["v8.0.0", "v9.0.0"];
  if (/Upgrade 20/.test(report)) return ["v9.0.0"];
  return [];
}

function addGroup(meta, rows) {
  for (const row of rows) {
    const [finding_id, severity_original, title, manualPage = null, status = "report status not normalized", fix_commit = null, fix_strategy = null, tests = []] = row;
    const cls = rootClass(title);
    const pg = reportPage(meta.file, title, manualPage, finding_id);
    records.push({
      report: meta.report,
      finding_id,
      severity_original,
      severity_current_mapping: severityMap[severity_original],
      title,
      root_cause_class: cls,
      affected_contracts: affectedContracts(title, meta.defaultContracts || []),
      affected_functions: affectedFunctions(title),
      required_state: conditionFor(cls),
      attacker_model: attackerFor(cls),
      impact: `Source-classified ${severity_original}: ${title}. Current Immunefi impact must be demonstrated independently.`,
      exact_commit: meta.commit,
      fix_commit,
      fix_strategy: fix_strategy || (status.match(/fixed|resolved|verified/i) ? "Source marks the issue fixed/resolved; this record does not infer a broader family closure beyond the cited fix." : "No exact fix strategy is asserted beyond the cited report status."),
      tests_added: tests.length ? tests : ["Not normalized in this pass; consult the cited finding/fix review for any PoC or regression test."],
      scope_assumptions: meta.assumptions || ["Only the files/diff and deployment assumptions stated by the report were reviewed."],
      explicit_out_of_scope: meta.oos || ["No additional explicit exclusion normalized; consult the source report's scope statement."],
      residual_assumptions: ["Historical severity is not a current Immunefi classification.", "Sibling entrypoints and later abstractions require independent closure review."],
      sibling_paths_not_reviewed: ["Not established by this normalized record: inverse flow, wrappers, pre-existing objects, or skipped histories; consult the cited report for any express coverage."],
      later_releases_that_retouch_root_cause: laterTags(meta, title, cls),
      status,
      audited_release: meta.tag || null,
      evidence: pg ? `${meta.file || meta.report}, PDF page ${pg}; audited commit ${meta.commit}` : `${meta.report}, finding ${finding_id}; audited commit ${meta.commit}`,
    });
  }
}

// Historical OVM / Bedrock findings.
addGroup({ report: "2020-10 Trail of Bits Optimism OVM assessment", file: "2020_10-Rollup-TrailOfBits.txt", commit: "not stated in report (contracts-v2 snapshot reviewed 2020-09-14 through 2020-10-02)", tag: null }, [
  ["TOB-OVM-001","High","SafetyChecker allows deployment of bytecode with unsafe instructions"],
  ["TOB-OVM-002","High","The owner of the AddressManager contract can backdoor any contract"],
  ["TOB-OVM-003","High","No access control in appendStateBatch allows blocking proof verification"],
  ["TOB-OVM-004","Medium","Integer overflow is possible while checking the fraud proof window"],
  ["TOB-OVM-005","Medium","Result of target.call(message) execution is ignored"],
  ["TOB-OVM-006","Low","Re-entrancy risk in message passing contracts"],
  ["TOB-OVM-007","High","Downcasting of integer can lead to incorrect update of state variable"],
  ["TOB-OVM-008","High","Lib_MerkleUtils.verify accepts empty proofs"],
  ["TOB-OVM-009","Low","Denial-of-service protections in enqueue can be ineffective"],
  ["TOB-OVM-010","High","Lib_TimeboundRingBuffer.push incorrectly updates deletionOffset"],
  ["TOB-OVM-012","Low","Insufficient logging in cross-domain messengers"],
  ["TOB-OVM-013","Low","Any user can create backdoored OVM_StateTransitioner contracts"],
  ["TOB-OVM-014","High","Fraud verification allows any transaction to be used regardless of the state root"],
  ["TOB-OVM-015","Low","Sequencer calls to append new batches can be front-run"],
  ["TOB-OVM-017","High","_verifyQueueTransaction uses an incorrect variable in its body",48],
  ["TOB-OVM-018","Medium","appendSequencerBatch reverts if the queue is empty",50],
  ["TOB-OVM-019","High","Monotonicity of L2 timestamp and block number can be violated",52],
  ["TOB-OVM-020","Medium","Fraud verification reverts if submitted within the force inclusion period",55],
]);

addGroup({ report: "2020-11 Dapphub ECDSA wallet assessment", file: "2020_11-Dapphub-ECDSA_Wallet.txt", commit: "bb3539bbd10c15a72a46cf4fb8d2472ef68f6322", tag: null }, [
  ["B01","High","L1 transactions can be replayed on L2",null,"fixed","0aa6e3a"],
  ["B02","High","Relayer can provide insufficient gas for inner transaction",null,"fixed","6a4d48a"],
  ["B03","High","Account overcharges fees if the transaction uses less gas than specified in gasLimit",null,"not fixed in report",null],
  ["B04","High","Arithmetic overflow in relayer fee calculation",null,"not fixed in report",null],
  ["B05","High","Arithmetic underflow in gas limit calculation",null,"fixed","6a4d48a"],
  ["B06","High","Transactions can be executed despite failing gas transfer",null,"fixed","46e2f65"],
  ["B07","High","Incorrect casting in LibBytes32.fromAddress",null,"fixed","244424f"],
  ["B08","High","Arithmetic overflow in input validation for LibBytesUtils.slice",null,"fixed","6712904"],
  ["B09","High","Memory corruption in Lib_RLPWriter.writeAddress",null,"fixed","96baeba"],
  ["B10","High","Memory corruption in LibBytesUtils.slice",null,"fixed","ca84d45"],
  ["B11","Medium","ovmSETNONCE and ovmCREATE allow users to overflow their nonce",null,"not fixed in report",null],
  ["B12","Low","The value of a transaction is silently ignored in the Execution Manager"],
]);

addGroup({ report: "2021-03 OpenZeppelin OVM and Rollup audit", file: "2021_03-OVM_and_Rollup-OpenZeppelin.txt", commit: "18e128343731b9bde23812ce932e24d81440b6b7 (first four weeks); a935e276f5620b40802b52721e3474232e458f72 (last three weeks)", tag: null }, [
  ["C01","Critical","Possible state manipulation after execution of transactions with invalid gas limit"],
  ["C02","Critical","Partially shared keys with EXTENSION nodes"],
  ["C03","Critical","Unbounded nuisance gas"],
  ["C04","Critical","Valid L1-to-L2 queue transactions may be proven fraudulent by spoofing queue origin"],
  ["H01","High","Valid transactions cannot be enqueued"],
  ["H02","High","Unhandled transfer failures"],
  ["H03","High","Relayers may not receive transaction fees"],
  ["H04","High","Irrelevant proof contributions are accepted"],
  ["H05","High","Repeatedly exceeding nuisance gas limit"],
  ["M01","Medium","Potential mismatch in allowed gas limit for sequenced and queued transactions"],
  ["M02","Medium","Pre-state root and transaction may not uniquely identify transitions"],
  ["M03","Medium","Initial state root cannot be challenged"],
  ["M04","Medium","Sequencer entrypoint contracts ignore success flags and returned data"],
  ["M05","Medium","Nuisance gas left is not reduced to zero when operation exceeds budget"],
  ["L01","Low","Appending transactions to the Canonical Transaction Chain in specific blocks might unexpectedly fail"],
  ["L02","Low","Inaccessible code when retrieving Merkle roots"],
  ["L04","Low","Merkle tree elements are overwritten"],
  ["L08","Low","Unspecified behavior of OVM gas refund for revert flags"],
  ["L09","Low","Nuisance gas proportional to code size is charged unnecessarily when changing an account"],
  ["L11","Low","Incorrect state transitioner index"],
  ["L12","Low","Inconsistent and error-prone storage references in proxy contracts"],
  ["L13","Low","Inconsistent key slicing when computing trie root"],
  ["L14","Low","Branch node modification in Merkle Trie may deviate from specification"],
  ["L17","Low","Lookup key strings are not centrally defined"],
  ["L18","Low","Lack of allowance front-running mitigation in ERC20 contract"],
  ["L19","Low","Lack of event emissions"],
]);

addGroup({ report: "2022-05 OpenZeppelin Bedrock contracts audit", file: "2022_05-Bedrock_Contracts-Zeppelin.txt", commit: "0c05488 (majority), e2da9e2 (final days), 8cbaf02 (post-audit extended review)", tag: null, defaultContracts: ["Bedrock contract set"] }, [
  ["C-01","Critical","Initiate unauthorized ERC20 bridge operations",5],
  ["H-01","High","Inverted finalization validation",6],
  ["H-02","High","Token refunds may use incorrect addresses",7],
  ["M-01","Medium","Deposit refund may behave unexpectedly",9],
  ["M-02","Medium","Donated ETH appears trapped",10],
  ["M-03","Medium","Excessive gas",11],
  ["M-04","Medium","Invalid L2 sender",12],
  ["M-05","Medium","Misleading data parameter",13],
  ["M-06","Medium","Unpause functionality",14],
  ["L-01","Low","Confusing reference to transaction sender",15],
  ["L-02","Low","Disable implementation contracts",15],
  ["L-03","Low","Implementation contracts have constructors",16],
  ["L-04","Low","Nonstandard tokens",16],
  ["L-05","Low","Warn about trapped funds",17],
  ["L-06","Low","Zero gas limit for refund transfer",17],
  ["L-07","Low","Unlimited message length",18],
]);

addGroup({ report: "2022-05 Trail of Bits OpNode assessment", file: "2022_05-OpNode-TrailOfBits.txt", commit: "optimistic-specs 05136a32b9828b595dde47f767218dec53f19aa4; optimistic-geth a7423f3a3167d20e93b6d60e648fbe9fec17f380", tag: null }, [
  ["TOB-OPT-1","High","Risk of theft due to reentrancy vulnerability in WithdrawalsRelay"],
  ["TOB-OPT-2","Low","Missing zero address checks in L2 CheckpointOracle"],
  ["TOB-OPT-3","High","Possible failure to parse deposit transactions due to incorrect gasLimit type"],
  ["TOB-OPT-5","High","Execution engine API lacks endpoint authentication"],
  ["TOB-OPT-6","High","Pre-deployed L1 attributes contract will never be updated"],
  ["TOB-OPT-7","Low","Underspecified behavior regarding deposits made through smart contracts"],
  ["TOB-OPT-8","Low","Incorrect error handling when creating an L2 block"],
]);

addGroup({ report: "2022-08 Sigma Prime Bedrock Go audit", file: "2022_08-Bedrock_GoLang-SigmaPrime.txt", commit: "optimism b708721; op-geth 70b0248", tag: null }, [
  ["OPB-01","Critical","Panic when unmarshalling untrusted SSZ data from P2P",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-02","High","Lack of buffer size checks before using FillBytes()",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-03","High","Lack of size checks in UnmarshalText()",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-04","Medium","Unsafe casting leads to integer overflow",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-05","Medium","Insecure order of events in verifying unsafe L2 blocks",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-06","Medium","Unsafe use of nonce to identify deposit transactions",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-07","Medium","Private key stored without encryption",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-08","Medium","JWT secret stored without encryption",null,"closed",null],
  ["OPB-09","Medium","Unsafe casting used throughout the codebase",null,"closed",null],
  ["OPB-10","Medium","No checks for deposit transaction type when calling L1InfoDepositTxData()",null,"resolved","055e4e7c/68b97bc"],
  ["OPB-11","Low","Inconsistent handling of deposit transactions in older hard-forks",null,"resolved","055e4e7c/68b97bc"],
]);

addGroup({ report: "2022-09 OpenZeppelin Bedrock and Periphery audit", file: "2022_09-Bedrock_and_Periphery-Zeppelin.txt", commit: "93d3bd411a8ae75702539ac9c5fe00bad21d4104", tag: "v1.0.0" }, [
  ["M-01","Medium","Asymmetric failure behavior of ERC721 bridges"],
  ["M-02","Medium","Confusing deprecated OptimismMintableERC20 interface considerations"],
  ["M-03","Medium","ETH can be sent to undeliverable recipient"],
  ["M-04","Medium","Unsatisfiable gasLimit values could lead to frozen assets"],
  ["M-05","Medium","Incomplete backwards compatibility"],
  ["M-06","Medium","Lack of input validation"],
  ["M-07","Medium","CrossDomainMessenger allows sending messages to unrelayable addresses"],
  ["M-08","Medium","Upgradeability inconsistencies"],
  ["L-01","Low","Documentation could be improved"],
  ["L-02","Low","Multiple OpenZeppelin contract versions in use"],
  ["L-03","Low","Not inheriting supported interfaces"],
  ["L-04","Low","Standard Bridge does not support tokens with transfer fees"],
  ["L-05","Low","Auto withdrawal transactions can be misleading"],
  ["L-06","Low","Circumventable requirement that owner and proposer are distinct"],
  ["L-08","Low","ERC721 bridge contracts do not use safeTransferFrom"],
  ["L-10","Low","Specifications do not cover all aspects of current implementation"],
  ["L-12","Low","Potential revert-inducing overflow"],
  ["L-14","Low","Variables missing the immutable keyword"],
]);

addGroup({ report: "2022-10 Spearbit Drippie review", file: "2022_10-Drippie-Spearbit.txt", commit: "2a7be367634f147736f960eb2f38a77291cdfcad", tag: "v1.0.0" }, [
  ["5.1.1","Medium","Permitting multiple drip calls per block"],
]);

addGroup({ report: "2023-01 Trail of Bits Bedrock updates assessment", file: "2023_01-Bedrock_Updates-TrailOfBits.txt", commit: "ee96ff8585699b054c95c6ff4a2411ee9fedcc87", tag: "v1.0.0", defaultContracts: ["SystemConfig"] }, [
  ["TOB-OPTCW-1","High","Ability to block withdrawals by resubmitting withdrawal proofs"],
]);

addGroup({ report: "2023-01 Sherlock Bedrock contest final report", file: null, commit: "3f4b3c328153a8aa03611158b6984d624b17c1d9", tag: "v1.0.0", assumptions: ["All contracts in packages/contracts-bedrock/src plus the contest-listed op-node/op-geth scope; judging assumptions apply."], oos: ["Known issues and exclusions in the contest README."] }, [
  ["H-1","High","Malicious user can finalize another user's withdrawal with less than the specified gas limit, leading to loss of funds",4,"fixed or acknowledged by final report","PR #4867 (merge commit not stated in report)"],
  ["H-2","High","Withdrawals with high gas limits can be bricked by a malicious user, permanently locking funds",10,"fixed or acknowledged by final report","PR #4867 (merge commit not stated in report)"],
  ["H-3","High","Users can lose funds during finalization of a withdrawal transaction",17,"fixed or acknowledged by final report",null],
  ["M-1","Medium","Batcher frames are incorrectly decoded, leading to consensus split",23,"fixed or acknowledged by final report",null],
  ["M-2","Medium","Censorship resistance is undermined and bridging assets can be denied at low cost",27,"fixed or acknowledged by final report",null],
  ["M-3","Medium","Panic when decoding a malformed deposit transaction JSON string",30,"fixed or acknowledged by final report",null],
  ["M-4","Medium","MigrateWithdrawal may set gas limits so high that old withdrawals cannot be relayed on L1",32,"fixed or acknowledged by final report","PR #4911 (merge commit not stated in report)"],
  ["M-5","Medium","A contract implementing only IOptimismMintableERC20 is not compatible with StandardBridge",37,"fixed or acknowledged by final report","PR #4909 (merge commit not stated in report)"],
  ["M-6","Medium","Crafted P2P spam can render nodes permanently unable to process L2 blocks",39,"fixed or acknowledged by final report","PR #4873 (merge commit not stated in report)"],
  ["M-7","Medium","LES does not forward the transaction to the sequencer",41,"fixed or acknowledged by final report",null],
  ["M-8","Medium","OptimismPortal can run out of gas due to incorrect overhead estimation",45,"fixed or acknowledged by final report",null],
  ["M-9","Medium","Migration can be bricked by sending a message directly to LegacyMessagePasser",50,"fixed or acknowledged by final report","PR #4861 (merge commit not stated in report)"],
  ["M-10","Medium","Challenger can override the seven-day finalization period",53,"fixed or acknowledged by final report",null],
  ["M-11","Medium","Gasless ETH bridging from L1 to L2",57,"fixed or acknowledged by final report",null],
  ["M-12","Medium","L1-to-L2 deposits through L1CrossDomainMessenger fail and are not replayable when L2CrossDomainMessenger is paused",60,"fixed or acknowledged by final report","PR #4913 (merge commit not stated in report)"],
  ["M-13","Medium","Withdrawal transactions can get stuck if an output root is reproposed",62,"fixed or acknowledged by final report","PR #4866 (merge commit not stated in report)"],
]);

addGroup({ report: "2023-03 Sherlock Bedrock fix review final report", file: null, commit: "optimism 9b9f78c6613c6ee53b93ca43c71bb74479f4b975; op-geth 7eee103098 (full op-geth hash not stated)", tag: "v1.0.0" }, [
  ["H-1","High","All migrated withdrawals that require more than 135,175 gas may be bricked",3,"fixed or acknowledged by final report",null],
  ["H-2","High","Legacy withdrawals can be relayed twice, causing double spending of bridged assets",16,"fixed or acknowledged by final report",null],
  ["H-3","High","The formula used in SafeCall.callWithMinGas() is wrong",19,"fixed or acknowledged by final report",null],
  ["M-1","Medium","Setting baseFeeMaxChangeDenominator to 1 will break all deposits",29,"fixed or acknowledged by final report",null],
  ["M-2","Medium","Gas usage of cross-chain messages is undercounted, causing L1/L2 discrepancy and affecting intrinsic gas",33,"fixed or acknowledged by final report",null],
  ["M-3","Medium","Estimating gas required to relay the message on both L1 and L2 is incorrect",37,"fixed or acknowledged by final report",null],
  ["M-4","Medium","A malicious actor can prevent migration by calling a nonexistent LegacyMessagePasser function and making witness reads fail",40,"fixed or acknowledged by final report",null],
  ["M-5","Medium","A malicious user can finalize another user's withdrawal with precise gas, causing loss even after the prior fix",42,"fixed or acknowledged by final report",null],
  ["M-6","Medium","Incorrect calculation of required gas limit during deposit transaction",59,"fixed or acknowledged by final report",null],
  ["M-7","Medium","Users can lose funds when bridging a long message from L2 to L1 due to uncontrolled out-of-gas error",61,"fixed or acknowledged by final report",null],
]);

addGroup({ report: "2023-12 Trust SuperchainConfig upgrade review", file: "2023_12_SuperchainConfigUpgrade_Trust.txt", commit: "d1651bb22645ebd41ac4bb2ab4786f9a56fc1003", tag: "v1.2.0" }, [
  ["TRST-H-1","High","Anyone can execute a withdrawal twice by abusing the upgrade procedure",null,"fixed","81b56fee40f96c798174115c375f41c3d2ff9d40"],
  ["TRST-M-1","Medium","Anyone can make a victim's withdrawal transaction revert, delaying withdrawals and increasing cost",null,"acknowledged",null],
  ["TRST-M-2","Medium","Insufficient calldata gas stipend could make initial delivery fail",null,"acknowledged",null],
  ["TRST-M-3","Medium","Messages over 50k bytes can be permanently lost due to unaccounted gas costs",null,"acknowledged",null],
  ["TRST-L-1","Low","User is forced to overpay for deposit gas due to calldata gas calculation",null,"acknowledged",null],
  ["TRST-L-2","Low","The metering logic in OptimismPortal is incorrect immediately after the upgrade",null,"fixed","81b56fee40f96c798174115c375f41c3d2ff9d40"],
  ["TRST-L-3","Low","A storage slot is accidentally skipped",null,"acknowledged",null],
  ["TRST-L-4","Low","Upgrades reset the state of unused storage slots",null,"acknowledged",null],
  ["TRST-L-5","Low","The gas buffer is insufficient, risking unexpected reverts",null,"acknowledged",null],
  ["TRST-L-6","Low","OptimismPortal consumes all forwarded gas even if the transaction is undeliverable",null,"acknowledged",null],
  ["TRST-L-7","Low","Users can underpay gas for contract creations, causing them to fail",null,"acknowledged",null],
  ["TRST-L-8","Low","Different ERC20Factory addresses between chains prevent identical token addresses",null,"acknowledged",null],
]);

addGroup({ report: "2024-05 Sherlock Optimism Fault Proofs contest final report", file: null, commit: "5137f3b74c6ebcac4f0f5a118b0f4909df03aec6", tag: null, oos: ["Contest README assumptions for game exploitability and delayed-WETH airgap; game-only root causes excluded unless a non-game contract was implicated."] }, [
  ["M-1","Medium","Incorrect game type can be proven and finalized due to unsafe cast",3,"fixed","PR #10152 (merge commit not stated in report)"],
  ["M-2","Medium","Fault game factory can be manipulated to deny service to a game type using malicious l2BlockNumber",28,"fixed","PRs #10431, #10434, and #10438 (merge commits not stated in report)"],
  ["M-3","Medium","Theft of initial bonds from proposers using smart wallets",42,"fixed","PR #10149 (merge commit not stated in report)"],
  ["M-4","Medium","Loss of bond amounts on reorganization attacks",54,"fixed","PR #10520 (merge commit not stated in report)"],
]);

addGroup({ report: "2024-02 Cantina MCP L1 review", file: "2024_02-MCP_L1-Cantina.txt", commit: "e6ef3a900c42c8722e72c2e2314027f85d12ced5", tag: "v1.3.0" }, [
  ["3.1.1","Low","Avoid using real values in the implementation"],
  ["3.1.2","Low","Different sources of values for checking and deployment"],
  ["3.1.3","Low","Gaps should be reserved for FeeVault"],
  ["3.1.4","Low","OP Chain deployment process is not compatible with MCP L1"],
  ["3.1.5","Low","Inconsistent version updates"],
  ["3.1.6","Low","Incorrect implementation initialization testing"],
  ["3.1.7","Low","Resource config values can be modified during the MCP L1 upgrade"],
]);

addGroup({ report: "2024-05 Cantina Safe Liveness Extensions contest", file: "2024_05_SafeLivenessExtensions-Cantina.txt", commit: "not stated in report", tag: null, defaultContracts: ["Safe liveness extensions"] }, [
  ["3.1.1","Medium","An owner can be censored by another owner with a lower address"],
  ["3.1.2","Medium","Acceptance of a new Safe threshold incorrectly depends on liveness updates of owners"],
  ["3.1.3","Medium","Removing owners through LivenessModule does not update the guard lastLive mapping"],
  ["3.1.4","Medium","During execTransaction reentrancy all owners are marked live"],
  ["3.1.5","Medium","Liveness is reset for all owners when LivenessGuard is upgraded or replaced"],
  ["3.1.6","Medium","EIP-1271 non-compliance and denial-of-service risk for account-abstraction wallets in the council Safe"],
]);

addGroup({ report: "2024-08 Cantina Fault Proof MIPS review", file: "2024_08_Fault-Proofs-MIPS_Cantina.txt", commit: "71b93116738ee98c9f8713b1a5dfe626ce06c1b2", tag: "v1.4.0", defaultContracts: ["MIPS"] }, [
  ["3.1.1","Critical","Allocation overflow could allow arbitrary code execution"],
  ["3.2.1","High","Lack of garbage collection or deallocation conflicts with the EVM gas security model"],
  ["3.3.1","Medium","Unknown or unimplemented system calls silently succeed"],
  ["3.3.2","Medium","Unaligned memory reads are silently aligned but should panic"],
  ["3.3.3","Medium","Integer overflow is not implemented for add, addi, and sub"],
  ["3.3.4","Medium","add, addi, and sub must panic on overflow"],
  ["3.3.5","Medium","Wrong implementation of srav"],
  ["3.3.6","Medium","A nonzero rd register may be wrongly set to zero"],
  ["3.3.7","Medium","J and JAL use the wrong PC value as the high bits for the jump"],
  ["3.3.8","Medium","Branch instructions bgezal and bltzal are not implemented"],
  ["3.4.1","Low","Validation of binary instruction encoding is too lax"],
  ["3.4.2","Low","Location of the registers array in memory should be verified"],
  ["3.4.3","Low","state.exited should be constrained to zero or one"],
]);

addGroup({ report: "2024-08 Spearbit Fault Proof no-MIPS review", file: "2024_08_Fault-Proofs-No-MIPS_Spearbit.txt", commit: "1f7081798ce2d49b8643514663d10681cb853a3d", tag: "v1.6.0" }, [
  ["5.1.1","Medium","PreimageOracle.loadPrecompilePreimagePart overwrites correct preimage parts when the precompile runs out of gas"],
  ["5.1.2","Medium","Invalid ancestor lookup leads to out-of-bounds array access"],
  ["5.1.3","Medium","An attacker with more available funds can counter an honest root-claim defender"],
  ["5.1.4","Medium","challengeRootL2Block can block an honest gamer from receiving the bond"],
  ["5.2.1","Low","FaultDisputeGame.step can be called after the parent claim is resolved"],
  ["5.2.2","Low","challengeRootL2Block between resolveClaim and resolve results in incorrect GameStatus and state"],
  ["5.2.3","Low","Extension period is not applied correctly for the next root when SPLIT_DEPTH is one or less"],
  ["5.2.4","Low","Inconsistent partOffset check and memory boundaries in loadLocalData"],
  ["5.2.5","Low","Preimage proposals can be initialized multiple times"],
  ["5.2.6","Low","clockExtension and maxClockDuration are not validated correctly in the DisputeGame constructor"],
]);

addGroup({ report: "2024-12 MiloTruck DeputyPauseModule review", file: "2024_12-DPM-MiloTruck.txt", commit: "2f17e6b67c61de5d8073d556272796d201bc740b", tag: null, defaultContracts: ["DeputyPauseModule"] }, [
  ["L-1","Low","Error from low-level call is not bubbled up correctly",null,"acknowledged",null],
  ["L-2","Low","deputyGuardianModule must not be set to the FOUNDATION_SAFE address",null,"resolved","4851 (short mitigation commit stated by report)"],
  ["L-3","Low","Previous signatures remain usable after deputyGuardianModule changes",null,"acknowledged",null],
]);

addGroup({ report: "2024-12 Radiant Labs DeputyPauseModule review", file: "2024_12-DPM-RadiantLabs.txt", commit: "2f17e6b67c61de5d8073d556272796d201bc740b", tag: null, defaultContracts: ["DeputyPauseModule"] }, [
  ["3.1.1","Low","Struct encoding does not follow EIP-712"],
  ["3.1.2","Low","Deputy key rotation can be optimized for faster incident response"],
]);

addGroup({ report: "2025-01 Offbeat Labs Incident Response Improvements review", file: "2025_01-IRI-OffbeatLabs.txt", commit: "984bae9146398a2997ec13757bfe2438ca8f92eb and ce2ce43 (second snapshot stated in report)", tag: null }, [
  ["L-01","Low","Out-of-gas considerations for try/catch",null,"fixed and verified","PR #14144 (merge commit not stated in report)","Add fuzz coverage for gas boundaries and monitoring/semgrep defenses described by the report.",["PR #14144 fuzz testing", "PR #14144 semgrep rule"]],
]);

addGroup({ report: "2025-01 Coinbase Protocol Security multithreaded Cannon review", file: "2025_01-MT-Cannon-Base.txt", commit: "b8c011f18c79d735e01168345fc1c6f02fac584f", tag: null, defaultContracts: ["MIPS64"] }, [
  ["M-01","Medium","Incorrect implementation of SLL and SLLV",null,"fixed and verified",null,"Apply the shifts to uint32 values, or truncate to 32 bits before sign extension.",["testSLL", "testSLLV"]],
]);

addGroup({ report: "2025-01 Spearbit multithreaded Cannon review", file: "2025_01-MT-Cannon-Spearbit.txt", commit: "cc2715c3d6ebef374451b598f48980ad817e0a0e", tag: null, defaultContracts: ["MIPS64"] }, [
  ["5.1.1","High","Value loaded from memory inside futex differs from what userspace uses for comparison"],
  ["5.2.1","Medium","Failure to clear upper bits after shifts"],
  ["5.3.1","Low","Instruction bltzal is implemented in Go but not in Solidity"],
]);

addGroup({ report: "2025-02 Spearbit Upgrade 13 review", file: "2025_02-Upgrade13-Spearbit.txt", commit: "7d6d15437b7580b022f4c8c1ea9c0cd8d2e587e1", tag: "v2.0.0" }, [
  ["5.1.1","Medium","EIP-1559 parameters are not set in SystemConfig.initialize()"],
  ["5.1.2","Medium","A blacklisted anchorGame in AnchorStateRegistry prevents submitting L2 root claims to L1"],
  ["5.2.1","Low","Missing checks in OPContractsManager"],
  ["5.2.2","Low","OptimismPortal2.proveWithdrawalTransaction rejects valid dispute games when respectedGameType is updated"],
  ["5.2.3","Low","SystemConfig._setGasConfig should validate overhead and scalar according to the specification"],
  ["5.2.4","Low","OPContractsManager addGameType can fail due to a common saltMixer"],
  ["5.2.5","Low","Games created before their type is respected can deny creation of valid games for specific claims"],
  ["5.2.6","Low","Possible denial of service prevents Anchor State from being updated in time"],
]);

addGroup({ report: "2025-03 Spearbit Interop Contracts review", file: "2025_03-Interop-Contracts-Spearbit.txt", commit: "6c80f23ab3074b5c66ff06e390ae2448bd4d2240", tag: null }, [
  ["5.1.1","High","A chain operator can deny service to an entire cluster during the upgrade block, potentially stealing ETH from other chains"],
  ["5.1.2","High","Malicious tokens can be deployed at deterministic addresses on other chains to steal funds"],
  ["5.2.1","Medium","Withdrawals can be bricked if a chain enables interop before migrating to the SharedLockbox"],
  ["5.2.2","Medium","Transaction prevention through invalid message validation"],
  ["5.2.3","Medium","Native token can be flash minted, breaking protocol expectations"],
  ["5.3.1","Low","sendETH allows sending ETH to invalid chain IDs"],
  ["5.3.2","Low","Invalid withdrawal targets could be prevented at initiation"],
  ["5.3.3","Low","Chain ID parameter can be derived from the permissioned game"],
  ["5.3.4","Low","isDeposit restriction can be bypassed"],
]);

addGroup({ report: "2025-03 Wonderland ETHLockbox redesign review", file: "2025_03-Interop-Portal-Wonderland.txt", commit: "9df1fc15d0bf0dc9464db249ce06424607d5f399", tag: "v4.0.0", defaultContracts: ["ETHLockbox","OptimismPortal2"] }, [
  ["L-0","Low","Safety checks are missing to ensure migrations are done correctly"],
  ["L-1","Low","Incorrect balance emitted in LiquidityMigrated event"],
  ["L-2","Low","Ether remains in OptimismPortal instead of ETHLockbox if a finalized withdrawal fails"],
]);

addGroup({ report: "2025-04 Cantina Interop Portal contest", file: "2025_04-Interop-Portal-Cantina.txt", commit: "e4b921c9dbf8cd3a8db20ef4f15e0e2aa495fcc3", tag: "v4.0.0" }, [
  ["3.1.1","Low","The challenger does not receive the defender's bond if the protocol is paused at game closure"],
  ["3.1.2","Low","Missing recency check in setAnchorState()"],
  ["3.1.3","Low","A new ETHLockbox address can be a withdrawal target, breaking the invariant"],
  ["3.1.4","Low","Addition of new chains to the super anchor root will not be possible"],
  ["3.1.5","Low","Withdrawal hashes can still be proven after finalization, allowing supervisor-event spam"],
  ["3.1.6","Low","Output roots are not checked for ascending chain-ID order when proving with SuperRoot"],
  ["3.1.7","Low","Missing SuperRoot timestamp validation against output roots when proving a withdrawal"],
]);

const u16Rows = [
  ["5.1.1","Low","ReinitializableBase allows initialize() to be incorrectly called during an upgrade"],
  ["5.1.2","Low","Version enforcement could be violated for future versions"],
  ["5.1.3","Low","OptimismPortal2.migrateToSuperRoots could accidentally unpause a chain"],
  ["5.1.4","Low","Mismatching version is passed into EIP-712 for DeputyPauseModule"],
  ["5.1.5","Low","ProxyAdminOwnedBase.proxyAdmin creates risk for future contracts"],
];
addGroup({ report: "2025-05 Spearbit Interop Portal review", file: "2025_05-Interop-Portal-Spearbit.txt", commit: "7cd84fed9554193c2dcd683e1ff2d0e2605448f6", tag: "v4.0.0" }, u16Rows);
addGroup({ report: "2025-05 Spearbit Upgrade 16 review", file: "2025_05-Upgrade16-Spearbit.txt", commit: "54c19f6acb7a6d3505f884bae601733d3d54a3a6", tag: "v4.0.0" }, u16Rows);

addGroup({ report: "2025-06 Radiant Labs Cannon Go 1.24 review", file: "2025_06-Cannon-3DOC.txt", commit: "689111fca9a10e6670ba0b5c7f1a549a212c855b", tag: null, defaultContracts: ["MIPS64"] }, [
  ["3.1.1","Medium","getrandom syscall does not clear LOAD_LINKED reservations"],
  ["3.2.1","Low","Returned byte count deviates from the getrandom specification"],
]);

addGroup({ report: "2025-07 Spearbit VerifyOPCM review", file: "2025_07-VerifyOPCM-Spearbit.txt", commit: "731280c6fc0ad184d252e0fb1d0ad12b5f59fd60", tag: "v4.0.0" }, [
  ["5.1.1","Medium","Blueprints and implementations are checked only for OPContractsManagerDeployer"],
  ["5.2.1","Low","Immutable variables are not checked"],
]);

addGroup({ report: "2025-09 Spearbit U16a review", file: "2025_09-U16a-Spearbit.txt", commit: "475801690f7a451469ee4da87b5fe3c54c92f372", tag: "v4.1.0" }, [
  ["5.1.1","Low","Semver gate ignores prerelease metadata, blocking RC-to-release SuperchainConfig upgrades"],
  ["5.1.2","Low","Unnecessary DisputeGame and DelayedWETH redeployment when AnchorStateRegistry is not new"],
  ["5.1.3","Low","A chain can be accidentally unpaused when changing the ETH_LOCKBOX feature"],
]);

addGroup({ report: "2025-10 Spearbit revenue-sharing review", file: "2025_10-Rev-Sharing-Spearbit.txt", commit: "f1fcd96406d895f37c2d1a422d50ea7dbd03a491", tag: null }, [
  ["3.1.7","Low","Withdrawal transactions can fail, but can be replayed later, due to resource metering",null,"fixed","b81d1cf4"],
]);

addGroup({ report: "2025-11 Spearbit Safer Safes review", file: "2025_11-SaferSafes-Spearbit.txt", commit: "cb54822c5e18925498f48d8677b71992bf402631", tag: null, defaultContracts: ["Safe governance modules"] }, [
  ["5.1.1","Medium","Using the same signatures for scheduleTransaction and execTransaction introduces a security risk"],
  ["5.2.1","Low","FREI-PI invariant can be bypassed"],
  ["5.2.2","Low","The success boolean returned by execTransactionFromModule is not checked"],
]);

addGroup({ report: "2025-11 Spearbit Custom Gas Token review", file: "2025_11-Custom-Gas-Token-Spearbit.txt", commit: "1f888ede1940fce20f71db89fc13039fdd96757e", tag: "v6.0.0" }, [
  ["3.1.1","Low","Missing custom-gas-token predeploy mirrors"],
  ["3.1.2","Low","Custom-gas-token mode strands donateETH funds"],
  ["3.1.3","Low","Missing zero-value validation in burn()"],
  ["3.1.4","Low","OptimismPortal2 lacks an isCustomGasToken flag"],
  ["3.1.5","Low","NativeAssetLiquidity lacks a fund() function"],
  ["3.1.6","Low","LiquidityController events are off-specification"],
]);

addGroup({ report: "2026-01 Cantina Upgrade 18 review", file: "2026_01-U18-Cantina.txt", commit: "87d406db86907833f75d5c8fb26ade3dcb85eb41", tag: "v6.0.0" }, [
  ["3.1.1","Low","DisputeGameFactory.setImplementation allows setting a new implementation with outdated parameters"],
  ["3.1.2","Low","Potential calldata injection in dispute games"],
  ["3.1.3","Low","New DisputeGameFactory permits games using incompatible old implementations"],
  ["3.1.4","Low","Withdrawals to the zero address lead to loss of funds"],
]);

addGroup({ report: "2026-03 Cantina Kona review", file: "2026_03-Kona-Cantina.txt", commit: "kona 86910c9112437bbb849eca28961f813c5450e103", tag: null, defaultContracts: ["Kona proof/derivation programs"] }, [
  ["3.1.1","Critical","An attacker can trivially win a dispute game due to faulty trace extension mechanics"],
  ["3.1.2","Critical","Improper checks lead to invalid output root validation"],
  ["3.2.1","High","Multiple deviations in channel decompression can lead to consensus failure"],
  ["3.3.1","Medium","Reset signals do not fully clear the derivation pipeline"],
  ["3.3.2","Medium","Pipeline initialization uses incorrect SystemConfig"],
  ["3.4.1","Low","Type 0x7e batcher transactions are not supported during L1 retrieval"],
  ["3.4.2","Low","Unchecked elasticity parameter in EIP-1559 decoding"],
  ["3.4.3","Low","Unexpected panics on deposit-only transactions in consolidation"],
  ["3.4.4","Low","Vague value-setting logic can cause unexpected behavior"],
  ["3.4.5","Low","BootInfo loading does not enforce equality of SuperRoot and L2 timestamps"],
  ["3.4.6","Low","consolidate_dependencies always returns errors"],
  ["3.4.7","Low","Incorrect logic can leave transition states unfinalized"],
  ["3.4.8","Low","Driver does not wait for the executor to be ready"],
  ["3.4.9","Low","CalldataSource.next return semantics can be confused"],
  ["3.4.10","Low","Unremoved values cause unbounded memory growth"],
  ["3.4.11","Low","Incorrect assumption can panic PipelineCursor"],
  ["3.4.12","Low","Channel Assembler does not enforce strict frame ingestion order"],
  ["3.4.13","Low","Estimated channel size is tracked incorrectly during pruning"],
  ["3.4.14","Low","A batch with an unknown type causes a panic"],
  ["3.4.15","Low","Brotli activation uses the wrong timestamp"],
  ["3.4.16","Low","Malformed truncated span batches can panic"],
  ["3.4.17","Low","Incorrect hint payload can produce incorrect oracle responses"],
  ["3.4.18","Low","span-batch transaction decoding does not bound payload_length_with_header"],
  ["3.4.19","Low","Incorrect value is passed to is_interop_active, causing wrong error handling"],
  ["3.4.20","Low","Malformed span-batch bits are padded incorrectly"],
  ["3.4.21","Low","L2AccountProof hinting deviates from specification"],
  ["3.4.22","Low","Managed traversal does not reset the pipeline for Holocene activation"],
  ["3.4.23","Low","Channels with uint16 maximum frames never become ready"],
  ["3.4.24","Low","Overallocation while returning channel data can cause out-of-memory failure"],
  ["3.4.25","Low","BatchQueue span cache uses an inefficient data type"],
  ["3.4.26","Low","Deposits with mint above uint128 maximum can halt derivation"],
  ["3.4.27","Low","L1 and L2 timestamps are misaligned between data sources"],
  ["3.4.28","Low","Frame-number overflow can let malicious batchers break the frame queue"],
  ["3.4.29","Low","Misaligned single batches are handled incorrectly"],
  ["3.4.30","Low","Batch parent-hash check always fails"],
  ["3.4.31","Low","Undecided span batches are silently lost"],
  ["3.4.32","Low","Incorrect precompile versions are used after Jovian"],
]);

addGroup({ report: "2026-05 Cantina Upgrade 19 review", file: "2026_05-U19-Cantina.txt", commit: "7cbcb58ffb7322343f0ed6b926f65bea7630ce3e", tag: "v7.0.0" }, [
  ["3.1.1","Medium","L2ContractsManager drops X Layer liquidity minters"],
  ["3.1.2","Medium","OPContractsManager utilities allow unsupported v5 initializers"],
  ["3.1.3","Medium","Separate FeeVault route setters can misroute accrued fees"],
  ["3.2.1","Low","assertValidStateRegistry is missing a check on respected game state"],
  ["3.2.2","Low","assertValidSharedLockbox lacks an explicit SystemConfig check"],
  ["3.2.3","Low","ORACLE checks are missing in assertValidMipsVm"],
  ["3.2.4","Low","A renounced SystemConfig owner blocks normal OPContractsManager upgrades"],
  ["3.2.5","Low","assertValidSuperchainConfig should check the guardian address"],
  ["3.2.6","Low","assertValidOptimismMintableERC20Factory does not check the bridge version"],
  ["3.2.7","Low","Validator misses the portal AnchorStateRegistry check"],
  ["3.2.8","Low","Validator omits critical SystemConfig checks"],
  ["3.2.9","Low","Assertions should ensure DisputeGameFactory and ProxyAdmin owners are sound"],
  ["3.2.10","Low","An unauthorized root-block challenge wins the bond"],
]);

addGroup({ report: "2026-06 Cantina OPContractsManager v2 review", file: "2026_06-OPCMv2-Cantina.txt", commit: "a00b39720a3f61276d2fa3991abfb672c9dd35ce", tag: null }, [
  ["3.1.1","Medium","OPContractsManagerMigrator.migrate fails to reinitialize SystemConfig with the migrated DelayedWETH proxy",null,"fixed and verified","PR #19281 (merge commit not stated in report)"],
  ["3.2.1","Low","Dirty upper bits in SystemConfig.batcherHash cause upgrades to revert",null,"acknowledged",null],
  ["3.2.2","Low","OPContractsManagerMigrator.migrate does not enforce a SuperchainConfig version floor",null,"fixed and verified","PR #19281 (documentation remediation; merge commit not stated)"],
  ["3.2.3","Low","Initial deployment does not validate startingRespectedGameType against enabled games",null,"fixed and verified","PR #19272 (merge commit not stated in report)"],
  ["3.2.4","Low","Migration accepts invalid game configs and ignores enabled state",null,"fixed and verified","PR #19281 (documentation remediation; merge commit not stated)"],
  ["3.2.5","Low","Repeated migration clears shared DisputeGameFactory implementations and breaks unmigrated portals",null,"fixed and verified","PR #19271 (documentation remediation; merge commit not stated)"],
  ["3.2.6","Low","Calls to deploy can be forced to revert through front-running",null,"fixed and verified","PR #19272 (merge commit not stated in report)"],
]);

addGroup({ report: "2026-06 Cantina Interop L2 contracts review", file: "2026_06-Interop-L2-Contracts.txt", commit: "fa9974a2cd38d9e7633a12f9024d52f41de55f86", tag: null }, [
  ["3.1.1","Low","sendETH accepts invalid destination chain IDs",null,"acknowledged",null],
  ["3.1.2","Low","Relay value is not source-authenticated",null,"acknowledged",null],
  ["3.1.3","Low","relayMessage consumes no-code target messages",null,"fixed and verified","da3c4f4 (documentation remediation)"],
  ["3.1.4","Low","Unbounded target return data in relayMessage enables relayer gas griefing",null,"acknowledged",null],
]);

addGroup({ report: "2026-08 Cantina Upgrade 20 review", file: "2026_08-U20-Cantina.txt", commit: "7799a2464f23b4e19abd5e29843545f960e677be", tag: "v8.0.0" }, [
  ["3.1.1","Low","Initial super deployments accept invalid anchors"],
  ["3.1.2","Low","StandardValidator accepts arbitrary same-version SuperPermissioned game implementations"],
  ["3.1.3","Low","StandardValidator does not bind SystemConfig chain ID to the validated super-game domain"],
  ["3.1.4","Low","Super-root migration can retain a legacy anchor and leave permissionless invalid claims unchallengeable"],
  ["3.1.5","Low","SuperPermissioned game initialization can trap a configured bond"],
  ["3.1.6","Low","Validator does not bind dispute-game registries to the Portal registry"],
]);

addGroup({ report: "2026-11 Cantina Upgrade 21 review", file: "2026_11-U21-Cantina.txt", commit: "8fdb2775612f23a7d51bde6c1f4961faf7e0dd7b", tag: "v9.0.0" }, [
  ["3.1.1","Low","A post-migration upgrade can register an output-root game type on the shared DisputeGameFactory",null,"acknowledged",null],
  ["3.1.2","Low","StandardValidator does not detect a pause recorded against the retired portal identifier",null,"acknowledged",null],
  ["3.1.3","Low","Deployed L2 messengers retain the old relay budget and can no longer guarantee an L1 relay",null,"acknowledged",null],
  ["3.1.4","Low","Withdrawals can commit gas limits exceeding L1 finalization capacity",null,"acknowledged",null],
  ["3.1.5","Low","Migration shortens legacy safety delays",null,"acknowledged",null],
  ["3.1.6","Low","OPContractsManager patch releases cannot upgrade chains",null,"acknowledged",null],
  ["3.1.7","Low","Stale portal authorization exposes pooled ETH",null,"acknowledged",null],
  ["3.1.8","Low","A zero proposer makes permissioned games unusable",null,"acknowledged",null],
  ["3.1.9","Low","Standard upgrades shorten withdrawal reviews",null,"acknowledged",null],
  ["3.1.10","Low","State gas reserve lowers the withdrawal ceiling",null,"acknowledged",null],
  ["3.1.11","Low","Migration strands equal-version replacements",null,"acknowledged",null],
  ["3.1.12","Low","Legacy lockbox batches exceed the gas cap",null,"acknowledged",null],
  ["3.1.13","Low","Migration accepts incompatible finality delays",null,"acknowledged",null],
  ["3.1.14","Low","L2 precompile calls can strand relayed ETH",null,"acknowledged",null],
  ["3.1.15","Low","Shared games inherit a shorter bond delay",null,"acknowledged",null],
  ["3.1.16","Low","L2 proxy haircut defeats the baseGas guarantee",null,"acknowledged",null],
  ["3.1.17","Low","Validators miss an unregistered respected type",null,"acknowledged",null],
  ["3.1.18","Low","Migration validator does not bind chain IDs",null,"acknowledged",null],
  ["3.1.19","Low","Migration accepts placeholder or future anchors",null,"acknowledged",null],
]);

// FINDING_GROUPS

function writeJson() {
  const document = {
    generated_at: "2026-11-17T00:00:00Z",
    schema_notes: [
      "One record is retained for every Medium-or-higher source finding and every in-scope/relevant Low found during the independent corpus pass.",
      "Duplicate root causes in separate reports remain separate audit observations.",
      "Low findings map below the present reward threshold because SCOPE.md defines no Immunefi Low tier.",
      "Null/qualified fix commits are deliberate when the report names only a PR or does not identify an exact commit.",
    ],
    root_cause_vocabulary: vocab,
    finding_count: records.length,
    findings: records,
  };
  fs.writeFileSync(path.join(OUT, "AUDIT-FINDINGS.json"), JSON.stringify(document, null, 2) + "\n");
}

function csvCell(value) {
  const s = value || "—";
  return `"${s.replaceAll('"', '""')}"`;
}

function writeCoverage() {
  const releases = [
    ["v1.0.0","a12a09f7"],["v1.1.0","c383eb88"],["v1.2.0","856c08bf"],["v1.3.0","e6ef3a90"],
    ["v1.4.0","547ea72d"],["v1.5.0","9047beb5"],["v1.6.0","33f06d2d"],["v1.8.0","2073f405"],
    ["v2.0.0","8d0dd96e"],["v2.1.0","e45b33a0"],["v2.2.0","7fe5151a"],["v3.0.0","ef7a933c"],
    ["v3.0.1","48e36d5c"],["v4.0.0","54c19f6a"],["v4.1.0","594bc933"],["v5.0.0","d09c836f"],
    ["v6.0.0","018f5ae9"],["v7.0.0","a7c88c8d"],["v8.0.0","f45a5ccf"],["v9.0.0","ba6fcadb"],
  ];
  const B = "OZ-Bedrock+Periphery@93d3bd41; Sherlock-Bedrock@3f4b3c32; Sherlock-Fix@9b9f78c6";
  const P = `${B}; ToB-Invariant@b31d35b6; RV-DepositTx@commit-not-stated; ToB-BedrockUpdates@ee96ff85`;
  const T = "Trust-Superchain@d1651bb2";
  const M = "Cantina-MCP-L1@e6ef3a90";
  const U13 = "Spearbit-U13@7d6d1543";
  const V4P = "Wonderland-Lockbox@9df1fc15; Cantina-InteropPortal@e4b921c9; Spearbit-InteropPortal@7cd84fed; Spearbit-U16@54c19f6a";
  const V4O = "Spearbit-U16@54c19f6a; Spearbit-VerifyOPCM@731280c6";
  const rows = {
    "OptimismPortal / withdrawal state": {"v1.0.0":P,"v1.2.0":T,"v1.3.0":M,"v2.0.0":U13,"v4.0.0":V4P,"v4.1.0":"Spearbit-U16a@47580169","v5.0.0":"Spearbit-U17@aeed7033","v6.0.0":"Spearbit-CGT@1f888ede; Cantina-U18@87d406db","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "ETHLockbox / shared liquidity": {"v4.0.0":V4P,"v4.1.0":"Spearbit-U16a@47580169","v6.0.0":"Spearbit-CGT@1f888ede","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "L1/L2 cross-domain messengers": {"v1.0.0":B,"v1.2.0":T,"v1.3.0":M,"v4.0.0":"Spearbit-U16@54c19f6a","v6.0.0":"Spearbit-CGT@1f888ede","v9.0.0":"Cantina-U21@8fdb2775"},
    "Standard / ERC20 bridges": {"v1.0.0":B,"v1.2.0":T,"v1.3.0":M,"v4.0.0":"Spearbit-U16@54c19f6a","v6.0.0":"Spearbit-CGT@1f888ede","v7.0.0":"Cantina-U19@7cbcb58f"},
    "ERC721 bridges": {"v1.0.0":B,"v1.2.0":T,"v1.3.0":M},
    "OptimismMintableERC20Factory": {"v1.0.0":B,"v1.3.0":M,"v7.0.0":"Cantina-U19@7cbcb58f"},
    "SystemConfig": {"v1.0.0":B,"v1.3.0":M,"v2.0.0":U13,"v4.0.0":"Spearbit-U16@54c19f6a","v4.1.0":"Spearbit-U16a@47580169","v6.0.0":"Spearbit-CGT@1f888ede; Cantina-U18@87d406db","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "SuperchainConfig / pause namespace": {"v1.2.0":T,"v4.0.0":"Spearbit-U16@54c19f6a","v4.1.0":"Spearbit-U16a@47580169","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "AnchorStateRegistry": {"v2.0.0":U13,"v4.0.0":V4P,"v4.1.0":"Spearbit-U16a@47580169","v5.0.0":"Spearbit-U17@aeed7033","v6.0.0":"Cantina-U18@87d406db","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "DisputeGameFactory / games": {"v1.6.0":"Spearbit-NoMIPS@1f708179","v2.0.0":U13,"v4.0.0":V4P,"v4.1.0":"Spearbit-U16a@47580169","v5.0.0":"Spearbit-U17@aeed7033","v6.0.0":"Cantina-U18@87d406db","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "DelayedWETH / bond delay": {"v1.6.0":"Spearbit-NoMIPS@1f708179","v2.0.0":U13,"v4.0.0":"Spearbit-U16@54c19f6a","v4.1.0":"Spearbit-U16a@47580169","v5.0.0":"Spearbit-U17@aeed7033","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "ProxyAdmin / OPContractsManager": {"v1.0.0":B,"v2.0.0":U13,"v4.0.0":V4O,"v4.1.0":"Spearbit-U16a@47580169","v5.0.0":"Spearbit-U17@aeed7033","v6.0.0":"Cantina-U18@87d406db","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "Deployment / migration validators": {"v4.0.0":"Spearbit-VerifyOPCM@731280c6","v4.1.0":"Spearbit-U16a@47580169","v7.0.0":"Cantina-U19@7cbcb58f","v8.0.0":"Cantina-U20@7799a246","v9.0.0":"Cantina-U21@8fdb2775"},
    "MIPS / Cannon proof VM": {"v1.4.0":"Cantina-MIPS@71b93116","v1.8.0":"3Doc-FGETFD@52d0e60c (no accepted finding)","v4.0.0":"Spearbit-CannonFix@ffe3d5fe (fix review)"},
    "op-program / Kona proof program": {},
    "op-node / derivation / op-geth": {"v1.0.0":"Sherlock-Bedrock@3f4b3c32"},
  };
  const header = ["component", ...releases.map(([t,c]) => `${t}@${c}`)].map(csvCell).join(",");
  const lines = [header];
  for (const [component, cells] of Object.entries(rows)) {
    lines.push([component, ...releases.map(([tag]) => cells[tag])].map(csvCell).join(","));
  }
  fs.writeFileSync(path.join(OUT, "AUDIT-COVERAGE-MATRIX.csv"), lines.join("\n") + "\n");
}

function writeClosure() {
  const top = `# Fix-closure matrix

The matrix separates **instance closure** (the exact reported line was changed) from **root-family closure** (inverse direction, siblings, wrappers, old objects, and skipped histories were also tested). “Not evidenced” is a negative result, not an assertion that a bug exists.

## Ranked top 15 later-bypass / removed-safety-condition checks

| Rank | Fix/root family | Instance closure | Inverse, sibling, wrapper closure | Pre-existing objects / skipped upgrades | Later retouch and evidence | Priority |
|---:|---|---|---|---|---|---:|
| 1 | Bedrock minimum-gas fixes (Sherlock H-1/H-2; fix H-3/M-5) | Exact pre-call/EIP-150 formulas were reworked. | Direct Portal call covered historically; L2 proxy haircut, state-creation cost, and wrapped messenger budgets are separate. | No one report tests a v1 message through all later gas-budget changes. | v9.0.0 explicitly calls the helper a footgun and excludes memory/code costs (\`SafeCall.sol:88-102\`); U21 3.1.3/3.1.4/3.1.10/3.1.16 retouch the guarantee (report pp.5,9,13). | 9/10 |
| 2 | Withdrawal-proof overwrite/resubmission fix (TOB-OPTCW-1 / PR #4867) | Later Portal uses per-submitter proof records. | Finalize wrapper is present; deletion and submitter-array inverse cleanup are not symmetric. | Old proof objects were reshaped at v2 and are later invalidated by migration. | v2.0.0 creates nested records/array (\`OptimismPortal2.sol:114,132,366-377\`); v9.0.0 deletes only the mapping entry (\`OptimismPortal2.sol:707-727\`). | 9/10 |
| 3 | U16 lockbox authorization/migration safety | Portal/lockbox compatibility checks were added around migration. | Authorization is one-way; the retired-portal inverse path has no deauthorize entrypoint. | Pre-existing authorized portals remain objects after pooling. | v9.0.0 authorization mappings and authorize-only APIs (\`ETHLockbox.sol:72,122-136,180-195,218-234\`); U21 3.1.7 acknowledges stale authorization (p.7). | 9/10 |
| 4 | Pause-preservation fixes (Trust/U16/U16a) | Individual accidental-unpause instances were addressed. | Portal, legacy lockbox, shared lockbox, and retired identifiers are distinct pause keys. | Skipped migrations can carry a pause under an identifier no later validator checks. | v9 validator checks retired portal/legacy lockbox keys separately (\`OPContractsManagerMigrationValidator.sol:536-574\`); U21 3.1.2 reports a missed retired identifier (p.4). | 8/10 |
| 5 | Fault-game type cast / registry-binding fixes | Unsafe cast instance fixed by PR #10152. | Same-version implementation substitution and cross-registry identity are different directions. | Games created before registry/ASR replacement survive as historical proof objects. | U20 3.1.2/3.1.6 (pp.5,8); v9 validator compares shared ASR across portals (\`OPContractsManagerMigrationValidator.sol:481-521\`). | 8/10 |
| 6 | Malicious block-number / anchor-poison fixes | PRs #10431/#10434/#10438 closed the original l2BlockNumber path. | Starting-anchor validity, recency, future placeholder and non-super chain-domain checks are siblings. | A legacy anchor can be carried through super-root migration. | v9 validates exact starting anchor fields (\`OPContractsManagerMigrationValidator.sol:663-681\`), while U20 3.1.1/3.1.4 and U21 3.1.19 document remaining histories. | 8/10 |
| 7 | OPCMv2 DelayedWETH migration fix (3.1.1 / PR #19281) | Later migrator reuses/aligns the shared DelayedWETH instance. | DGF game args, SystemConfig slot, and existing games are three consumers; report verified the immediate instance only. | No named test follows a pre-migration game's WETH through later upgrade and payout. | v9.0.0 stores DelayedWETH in SystemConfig (\`SystemConfig.sol:90,236,309\`) and migrator validation requires a shared value (\`OPContractsManagerMigrationValidator.sol:481-521\`). | 8/10 |
| 8 | OPCM semver/reinitializer fixes (U16/U16a) | RC/prerelease and wrong-selector instances were reported. | Patch, equal-version replacement, deploy, upgrade, and migrate use different gates. | Skipped releases are not demonstrated by one report. | v9 OPCM documents one-way migration and exact release gating (\`OPContractsManagerV2.sol:280-313,1034-1049\`); U21 3.1.6/3.1.11 remain acknowledged. | 8/10 |
| 9 | SystemConfig gas/scalar/batcher validation | U13 and later validators added point checks. | Raw owner setters remain wider than supported OPCM decoding. | Divergent legacy words may persist until an upgrade canonicalizes them. | v9 unrestricted \`batcherHash\` setter (\`SystemConfig.sol:361-370\`); OPCMv2 3.2.1 and U21 3.2.12 document the accepted mismatch. | 7/10 |
| 10 | Cross-domain \`baseGas\` fixes | Historical length/EIP-150 undercounts were fixed per fix review. | L1 and L2 messenger budgets, Portal ceiling, precompile cost, and proxy overhead are composed but separately reviewed. | Deployed L2 messenger code may retain an older budget across L1 upgrade. | v9 dynamic/floor formula (\`CrossDomainMessenger.sol:371-417\`) and L1 override (\`L1CrossDomainMessenger.sol:117-118\`); U21 3.1.3/3.1.16. | 7/10 |
| 11 | Repeated migration / DGF clearing (OPCMv2 3.2.5) | Closure was documentation that re-migration is unsupported. | Partial migration and one-chain-at-a-time effects are not fixed by that documentation. | An already shared factory is the exact dangerous pre-existing object. | v9 migration is explicitly one-way and invalidates prior proofs (\`OPContractsManagerV2.sol:280-307\`); cleared types still mutate an existing DGF (\`OPContractsManagerMigrator.sol:537-539\`). | 7/10 |
| 12 | Validator chain-ID/domain checks | U19/U20 added several point checks. | Portal, SystemConfig, game args, migration manifest, and non-super roots each carry an identity. | Duplicate/mismatched legacy IDs are history-dependent. | v9 migrator rejects duplicate/nonascending IDs (\`OPContractsManagerMigrator.sol:287-327\`); U21 3.1.18 still identifies a migration-validator binding gap (p.15). | 7/10 |
| 13 | Finality / bond-delay safety assumptions | Earlier reports fixed concrete bypasses and added delays. | Upgrade and migration can move delays in both directions; shared and legacy games use different sources. | Existing proofs/games retain timestamps from before the cutover. | U21 3.1.5/3.1.9/3.1.13/3.1.15 acknowledge shortened/incompatible delays (pp.6-13). No single regression suite spans those histories. | 7/10 |
| 14 | CGT donation/liquidity-mode fixes | Point findings added flags/mirrors and mode handling. | Direct donation, lockbox lock, native-asset liquidity, and withdrawal are different value paths. | ETH donated before a mode change is the key old object. | v9 Portal donation remains intentionally empty (\`OptimismPortal2.sol:372-383\`); SystemConfig exposes CGT state (\`SystemConfig.sol:587\`). | 6/10 |
| 15 | No-code relay remediation | Accepted remediation documents permanent consumption. | Contract-bound versus EOA/value delivery remains one generic entrypoint. | A counterfactual address changes from no-code to code after consumption. | v9 warning plus state-before-call are explicit (\`L2ToL2CrossDomainMessenger.sol:192-243\`). This is known by design; only a new protocol-guaranteed target class could change severity. | 5/10 |

## Per-finding closure ledger

This ledger includes every Medium+ record and every retained Low. “Source-only” means the report/fix review did not evidence the listed closure dimension. Detailed exceptions and later-code checks are in the ranked table above.

| Report / ID | Sev. | Root or instance fixed? | Inverse direction | Sibling contracts | Direct + wrapped entrypoints | Pre-existing objects | Skipped histories | Later abstraction / cleanup | Evidence |
|---|---|---|---|---|---|---|---|---|---|
`;
  const rows = records.map((r) => {
    const fixed = /fixed|resolved|verified/i.test(r.status)
      ? `Instance/source fix only (${r.fix_commit || "exact commit not stated"})`
      : /acknowledged|not fixed|closed/i.test(r.status)
        ? `No broad fix asserted (${r.status})`
        : "Status not normalized; no closure asserted";
    const later = r.later_releases_that_retouch_root_cause.length
      ? `Retouched: ${r.later_releases_that_retouch_root_cause.join("/")}; source-only closure`
      : "No indexed later-tag claim";
    const cells = [
      `${r.report} / ${r.finding_id}`,
      r.severity_original,
      fixed,
      "Not evidenced by source",
      "Not evidenced by source",
      "Not evidenced unless named in finding",
      "Not evidenced unless named in finding",
      "Not evidenced unless named in finding",
      later,
      r.evidence,
    ];
    return `| ${cells.map((x) => String(x).replaceAll("|", "\\|").replaceAll("\n", " ")).join(" | ")} |`;
  });
  fs.writeFileSync(path.join(OUT, "FIX-CLOSURE-MATRIX.md"), top + rows.join("\n") + "\n");
}

writeJson();
writeCoverage();
writeClosure();
