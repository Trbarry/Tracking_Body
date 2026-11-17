import csv
COLS=['pre-v1.0.0 (Bedrock dev, 2022)','v1.0.0','v1.1.0','v1.2.0','v1.3.0','v1.4.0','v1.5.0','v1.6.0','v1.8.0','v2.0.0','v2.1.0','v2.2.0','v3.0.0','v3.0.1','v4.0.0','v4.1.0','v5.0.0','v6.0.0','v7.0.0','v8.0.0','v9.0.0']
# (label, column, components, note)
P='OptimismPortal (L2OutputOracle era)';P2='OptimismPortal2';PI='OptimismPortalInterop';LB='ETHLockbox';M='L1CrossDomainMessenger/CrossDomainMessenger';SB='L1StandardBridge/StandardBridge';EB='L1ERC721Bridge';F20='OptimismMintableERC20Factory';SC='SystemConfig';SUP='SuperchainConfig';PV='ProtocolVersions';RM='ResourceMetering';OO='L2OutputOracle';DGF='DisputeGameFactory';ASR='AnchorStateRegistry';FDG='FaultDisputeGame';PDG='PermissionedDisputeGame';SFDG='SuperFaultDisputeGame';SPDG='SuperPermissionedDisputeGame';ZK='ZK / OPSuccinct dispute game';WETH='DelayedWETH';MIPS='MIPS (32-bit)';M64='MIPS64';PO='PreimageOracle';PA='ProxyAdmin';AM='AddressManager/ResolvedDelegateProxy';CS='L1ChugSplashProxy';PX='Proxy';OPCM='OPContractsManager (v1: Deployer/Upgrader/GameTypeAdder/InteropMigrator)';OPCM2='OPContractsManagerV2 + Utils + Container';MIG='OPContractsManagerMigrator (migrate)';VAL='StandardValidator / MigrationValidator';VOPCM='VerifyOPCM.s.sol';UPS='upgrade tooling (op-chain-ops l1.go / StorageSetter / Deploy.s.sol)';DPM='DeputyPauseModule';LIBS='SafeCall / Hashing / Encoding / MerkleTrie libs';L2M='L2 predeploys: L2CDM / L2StandardBridge / L2ERC721Bridge / L2ToL1MessagePasser / L1Block / GasPriceOracle';L2I='L2 interop predeploys (CrossL2Inbox, L2ToL2CDM, SuperchainETHBridge/WETH, ETHLiquidity)';L2C='L2 CGT predeploys / LiquidityController';FV='FeeVaults / FeeSplitter';NODE='op-node / op-geth (derivation, p2p)';OPP='op-program / Cannon Go VM / op-challenger';KONA='kona proof program';OVM='OVM->Bedrock migration tooling (op-chain-ops migrate)'
ROWS=[P,P2,PI,LB,M,SB,EB,F20,SC,SUP,PV,RM,OO,DGF,ASR,FDG,PDG,SFDG,SPDG,ZK,WETH,MIPS,M64,PO,PA,AM,CS,PX,OPCM,OPCM2,MIG,VAL,VOPCM,UPS,DPM,LIBS,L2M,L2I,L2C,FV,NODE,OPP,KONA,OVM]
E=[
('Zeppelin-2022_05@0c05488/e2da9e2/8cbaf02','pre-v1.0.0 (Bedrock dev, 2022)',[P,OO,M,SB,L2M,LIBS,F20]),
('SigmaPrime-2022_08@b708721','pre-v1.0.0 (Bedrock dev, 2022)',[NODE]),
('ToB-OpNode-2022_05@05136a3 (counts only)','pre-v1.0.0 (Bedrock dev, 2022)',[NODE]),
('Zeppelin-2022_09@93d3bd4','v1.0.0',[P,OO,M,SB,EB,RM,L2M,LIBS,PX,PA,CS]),
('ToB-invariants-2022_11@b31d35b','v1.0.0',[P,RM,NODE]),
('RV-deposit-2022_12@n/s','v1.0.0',[P]),
('ToB-2023_01@1bfe79f/ee96ff8/991120f','v1.0.0',[P,SC,NODE,LIBS]),
('Sherlock-Bedrock-2023_01@3f4b3c3','v1.0.0',[P,OO,M,SB,EB,F20,SC,RM,L2M,LIBS,PX,PA,NODE,OVM]),
('Sherlock-fix-review-2023_03@9b9f78c','v1.0.0',[P,OO,M,SB,L2M,LIBS,NODE,OVM]),
('Trust-2023_12@d1651bb (diff since Sherlock commit)','v1.2.0',[P,M,SB,EB,SUP,RM,UPS]),
('Kontrol-pausability-2024_02@876e16a (reverts-when-paused only)','v1.2.0',[P,M,SB,EB]),
('Cantina-MCP-2024_02@e6ef3a9','v1.3.0',[P,M,SB,EB,F20,OO,SC,UPS]),
('Sherlock-FP-2024_03@5137f3b (safeguards; game bugs OOS by rule)','v1.4.0',[P2,DGF,ASR,WETH,FDG,PDG,MIPS,PO]),
('Cantina-MIPS-2024_08@71b9311','v1.4.0',[MIPS,OPP]),
('Spearbit-NoMIPS-2024_08@1f70817','v1.6.0',[FDG,PDG,DGF,ASR,WETH,PO]),
('3DOC-FGETFD-2024_10@52d0e60 (PR 12050)','v1.8.0',[MIPS,OPP]),
('MiloTruck-DPM-2024_12@2f17e6b','v2.0.0',[DPM]),
('Radiant-DPM-2024_12@2f17e6b','v2.0.0',[DPM]),
('Offbeat-IRI-2025_01@984bae9/ce2ce43 (diff)','v2.0.0',[P2,PI,ASR,WETH,FDG,OPCM]),
('Spearbit-MTCannon-2025_01@cc2715c','v2.0.0',[M64,OPP]),
('Base-MTCannon-2025_01@b8c011f','v2.0.0',[M64]),
('Spearbit-U13-2025_02@7d6d154','v2.0.0',[OPCM,SC,ASR,FDG,P2,DGF,SUP,AM]),
('Spearbit-Interop-Contracts-2025_03@6c80f23 (pre-redesign; no release)','v4.0.0',[PI,L2I,SUP]),
('Wonderland-2025_03@9df1fc1','v4.0.0',[LB,P2,L2I]),
('Cantina-contest-2025_04@e4b921c (SuperFDG OOS)','v4.0.0',[P2,LB,ASR,FDG,SC,SUP,OPCM,DGF]),
('aleph_v-blob-2025_04@08d81d9 (op-program v1.6.0)','v4.0.0',[OPP,PO]),
('Spearbit-InteropPortal-2025_05@7cd84fe','v4.0.0',[P2,SC,SUP,ASR,OPCM,DPM,LIBS,M,FDG]),
('Spearbit-U16-2025_05@54c19f6 (explicit file list)','v4.0.0',[LB,M,EB,SB,OPCM,P2,PV,SUP,SC,M64,ASR,WETH,DGF,SFDG,SPDG,LIBS,DPM]),
('Coinbase-Cannon-Go-2025_05@4c68444','v4.0.0',[M64]),
('Spearbit-Cannon-fix-2025_06@ffe3d5f/7f7b9ab','v4.0.0',[M64,OPP]),
('Radiant-Cannon-3DOC-2025_06@689111f (PR 15737; no release)','v4.0.0',[M64,OPP]),
('Spearbit-VerifyOPCM-2025_07@731280c/54c19f6','v4.0.0',[VOPCM,OPCM]),
('Spearbit-U16a-2025_09@4758016 (U15->U16a and U16->U16a fork-tested)','v4.1.0',[M64,M,EB,SB,P2,SC,OPCM]),
('Spearbit-U17-2025_10@aeed703 (U16->U17 fork-tested)','v5.0.0',[M,EB,SB,OPCM,P2,SUP,SC,M64,DGF,FDG,PDG,F20,L2M,LIBS]),
('Spearbit-RevShare-2025_10@f1fcd96 (counts only)','v5.0.0',[FV]),
('Spearbit-CGT-2025_11@1f888ed','v6.0.0',[OPCM,P2,SC,L2C,UPS]),
('Cantina-U18-2026_01@87d406d','v6.0.0',[ASR,DGF,SFDG,SPDG,FDG,PDG,ZK,OPCM,VAL,P2,SC,FV,L2M,L2C,DPM]),
('Cantina-OPCMv2-2026_06@a00b397 (Feb 2026; no release)','v7.0.0',[OPCM2,MIG,VOPCM]),
('Cantina-Kona-2026_03@kona 86910c9','v7.0.0',[KONA]),
('Cantina-U19-2026_05@7cbcb58','v7.0.0',[OPCM2,MIG,VAL,ASR,P2,SC,PDG,M64,LB,FV,L2C]),
('Cantina-InteropL2-2026_06@fa9974a (no release)','v8.0.0',[L2I,LIBS]),
('Cantina-U20-2026_08@7799a24','v8.0.0',[OPCM2,VAL,P2,SFDG,SPDG,SUP,SC,LIBS]),
('Cantina-U21-2026_11@8fdb277','v9.0.0',[ASR,M,WETH,LB,MIG,VAL,OPCM2,P2,SUP,SC,LIBS]),
]
cells={(r,c):[] for r in ROWS for c in COLS}
for lab,col,comps in E:
    for comp in comps: cells[(comp,col)].append(lab)
with open('../AUDIT-COVERAGE-MATRIX.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['component \\ release (op-contracts tag; report mapped by audited commit / README "Subsequent Release"; upgrade numbering to be confirmed by F2)']+COLS)
    for r in ROWS: w.writerow([r]+[' | '.join(cells[(r,c)]) for c in COLS])
    w.writerow([]); w.writerow(['NOTES'])
    for n in ['Empty cell = no report in the corpus reviewed that component at that release.',
     'Columns with NO report at all: v1.1.0, v1.5.0, v2.1.0, v2.2.0, v3.0.0, v3.0.1 (v3.0.0 = the release between U13/v2.0.0 and U16/v4.0.0, called "U15"/"v15" in the U16a report).',
     'A report is placed in ONE column (the release it preceded). Diff-only reviews are marked (diff). "counts only" = non-mandatory report, findings not recorded.',
     'Rows with no coverage after their introduction: ProxyAdmin, AddressManager/ResolvedDelegateProxy, L1ChugSplashProxy and Proxy (only 2022_09 at v1.0.0; ResolvedDelegateProxy never listed in any scope); OptimismMintableERC20Factory (v1.0.0, v1.3.0, v5.0.0 file list only); L1StandardBridge/L1ERC721Bridge (last in a file list at v5.0.0; pause-pointer change at v9 not in the U21 file list); DisputeGameFactory (last at v6.0.0); FaultDisputeGame/PermissionedDisputeGame (last in a file list at v6.0.0 as V2; U19 only via PDG finding); MIPS64 and PreimageOracle (MIPS64 last at v7.0.0 via validator finding / v5.0.0 file list; PreimageOracle last substantively at v1.6.0); kona only at one commit (86910c9).']:
        w.writerow([n])
print('ok')
