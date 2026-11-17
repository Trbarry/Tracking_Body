#!/bin/bash
# usage: state.sh <rpc> 
RPC=$1
c() { cast call --rpc-url $RPC "$@" 2>&1 | head -3 | tr '\n' ' '; }
SC=0x95703e0982140D16f8ebA6d158FccEde42f04a4C
declare -A SYS=( [op]=0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 [ink]=0x62c0a111929fa32cec2f76adba54c16afb6e8364 [soneium]=0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3 [unichain]=0xc407398d063f942febbcc6f80a156b47f3f1bda6 )
echo "block $(cast block-number --rpc-url $RPC)  SC version $(c $SC 'version()(string)') guardian $(c $SC 'guardian()(address)') global ts $(c $SC 'pauseTimestamps(address)(uint256)' 0x0000000000000000000000000000000000000000)"
for n in op ink soneium unichain; do
  S=${SYS[$n]}
  echo "=== $n SystemConfig $S"
  for f in 'version()(string)' 'owner()(address)' 'l2ChainId()(uint256)' 'superchainConfig()(address)' 'paused()(bool)' 'guardian()(address)' 'batcherHash()(bytes32)' 'unsafeBlockSigner()(address)' 'gasLimit()(uint64)' 'overhead()(uint256)' 'scalar()(uint256)' 'basefeeScalar()(uint32)' 'blobbasefeeScalar()(uint32)' 'eip1559Denominator()(uint32)' 'eip1559Elasticity()(uint32)' 'operatorFeeScalar()(uint32)' 'operatorFeeConstant()(uint64)' 'daFootprintGasScalar()(uint16)' 'minBaseFee()(uint64)' 'startBlock()(uint256)' 'initVersion()(uint8)' 'minimumGasLimit()(uint64)' 'lastUsedOPCM()(address)' 'lastUsedOPCMVersion()(string)' 'isCustomGasToken()(bool)' 'proxyAdmin()(address)' 'proxyAdminOwner()(address)' 'disputeGameFactory()(address)' 'l1CrossDomainMessenger()(address)' 'l1ERC721Bridge()(address)' 'l1StandardBridge()(address)' 'optimismPortal()(address)' 'optimismMintableERC20Factory()(address)' 'delayedWETH()(address)' 'resourceConfig()((uint32,uint8,uint8,uint32,uint32,uint128))'; do
    echo "  $f = $(c $S "$f")"
  done
  for feat in ETH_LOCKBOX CUSTOM_GAS_TOKEN INTEROP; do
    echo "  feature $feat = $(c $S 'isFeatureEnabled(bytes32)(bool)' $(cast format-bytes32-string $feat))"
  done
  echo "  slot0..=$(cast storage --rpc-url $RPC $S 0) impl=$(cast storage --rpc-url $RPC $S 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)"
  P=$(cast call --rpc-url $RPC $S 'optimismPortal()(address)')
  echo "  -- portal $P version $(c $P 'version()(string)') paused $(c $P 'paused()(bool)') sysCfg $(c $P 'systemConfig()(address)') asr $(c $P 'anchorStateRegistry()(address)') lockbox $(c $P 'ethLockbox()(address)') sc $(c $P 'superchainConfig()(address)') bal $(cast balance --rpc-url $RPC $P -e) l2Sender $(c $P 'l2Sender()(address)') initV $(c $P 'initVersion()(uint8)')"
  echo "     SC.pauseTimestamps[portal] = $(c $SC 'pauseTimestamps(address)(uint256)' $P)"
  L=$(cast call --rpc-url $RPC $P 'ethLockbox()(address)' 2>/dev/null)
  if [ -n "$L" ] && [ "$L" != "0x0000000000000000000000000000000000000000" ]; then
    echo "  -- lockbox $L version $(c $L 'version()(string)') paused $(c $L 'paused()(bool)') sc $(c $L 'superchainConfig()(address)') sysCfg(legacy) $(c $L 'systemConfig()(address)') authPortal $(c $L 'authorizedPortals(address)(bool)' $P) bal $(cast balance --rpc-url $RPC $L -e) pao $(c $L 'proxyAdminOwner()(address)')"
    echo "     slots: 0=$(cast storage --rpc-url $RPC $L 0) 3=$(cast storage --rpc-url $RPC $L 3)"
    echo "     SC.pauseTimestamps[lockbox] = $(c $SC 'pauseTimestamps(address)(uint256)' $L)"
  fi
  A=$(cast call --rpc-url $RPC $P 'anchorStateRegistry()(address)')
  echo "  -- ASR $A version $(c $A 'version()(string)') paused $(c $A 'paused()(bool)') lockbox $(c $A 'ethLockbox()(address)') sysCfg(legacy) $(c $A 'systemConfig()(address)') sc $(c $A 'superchainConfig()(address)') dgf $(c $A 'disputeGameFactory()(address)') rgt $(c $A 'respectedGameType()(uint32)')"
  W=$(cast call --rpc-url $RPC $S 'delayedWETH()(address)' 2>/dev/null)
  echo "  -- DelayedWETH(sysCfg) $W version $(c $W 'version()(string)') lockbox $(c $W 'ethLockbox()(address)') sysCfg(legacy) $(c $W 'systemConfig()(address)') config $(c $W 'config()(address)') bal $(cast balance --rpc-url $RPC $W -e) delay $(c $W 'delay()(uint256)')"
  for X in l1CrossDomainMessenger l1StandardBridge l1ERC721Bridge; do
    XA=$(cast call --rpc-url $RPC $S "$X()(address)")
    echo "  -- $X $XA version $(c $XA 'version()(string)') paused $(c $XA 'paused()(bool)') sysCfg $(c $XA 'systemConfig()(address)') sc $(c $XA 'superchainConfig()(address)') bal $(cast balance --rpc-url $RPC $XA -e)"
  done
  XA=$(cast call --rpc-url $RPC $S "l1CrossDomainMessenger()(address)")
  echo "     L1CDM portal $(c $XA 'portal()(address)') other $(c $XA 'OTHER_MESSENGER()(address)')"
done
