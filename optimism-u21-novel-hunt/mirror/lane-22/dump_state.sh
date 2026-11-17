#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <rpc-url> <block-number> <output-json>" >&2
  exit 2
fi

rpc_url=$1
block_number=$2
output_json=$3
layout_root=/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/snapshots/storageLayout
impl_slot=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
admin_slot=0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
eth_lockbox_feature=0x4554485f4c4f434b424f58000000000000000000000000000000000000000000
interop_feature=0x494e5445524f5000000000000000000000000000000000000000000000000000
custom_gas_token_feature=0x435553544f4d5f4741535f544f4b454e00000000000000000000000000000000

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

targets() {
  printf '%s\n' \
    'OP Mainnet|SuperchainConfig|0x95703e0982140D16f8ebA6d158FccEde42f04a4C|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|SystemConfig|0x229047fed2591dbec1eF1118d64F7aF3dB9EB290|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|OptimismPortal2|0xbEb5Fc579115071764c7423A4f12eDde41f106Ed|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|ETHLockbox|0x322b47Ff1FA8D5611F761e3E275C45B71b294D43|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|0xbEb5Fc579115071764c7423A4f12eDde41f106Ed' \
    'OP Mainnet|L1CrossDomainMessenger|0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|L1StandardBridge|0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|L1ERC721Bridge|0x5a7749f83b81b301cab5f48eb8516b986daef23d|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|OptimismMintableERC20Factory|0x75505a97bd334e7bd3c476893285569c4136fa0f|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|DisputeGameFactory|0xe5965Ab5962eDc7477C8520243A95517CD252fA9|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|DelayedWETH|0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'OP Mainnet|AnchorStateRegistry|0x23B2C62946350F4246f9f9D027e071f0264FD113|0x543bA4AADBAb8f9025686Bd03993043599c6fB04|' \
    'Ink|SystemConfig|0x62c0a111929fa32cec2f76adba54c16afb6e8364|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|OptimismPortal2|0x5d66C1782664115999C47c9fA5cd031f495D3e4F|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|ETHLockbox|0xbd4AbB321138e8Eddc399cE64E66451294325a14|0xd56045e68956fce2576e680c95a4750cf8241f79|0x5d66C1782664115999C47c9fA5cd031f495D3e4F' \
    'Ink|L1CrossDomainMessenger|0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|L1StandardBridge|0x88ff1e5b602916615391f55854588efcbb7663f0|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|L1ERC721Bridge|0x661235a238b11191211fa95d4dd9e423d521e0be|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|OptimismMintableERC20Factory|0xa8b389a82e088b164cd03230e900980cced34d29|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|DisputeGameFactory|0x10d7b35078d3baabb96dd45a9143b94be65b12cd|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|DelayedWETH|0x57b4c29daee99a28e6e86778b499361294c134ea|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Ink|AnchorStateRegistry|0xee018bAf058227872540AC60eFbd38b023d9dAe2|0xd56045e68956fce2576e680c95a4750cf8241f79|' \
    'Soneium|SystemConfig|0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|OptimismPortal2|0x88e529A6ccd302c948689Cd5156C83D4614FAE92|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|ETHLockbox|0x67B4de6FfA66EF201Ea6099A89cA397D56622E31|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|0x88e529A6ccd302c948689Cd5156C83D4614FAE92' \
    'Soneium|L1CrossDomainMessenger|0x9cf951e3f74b644e621b36ca9cea147a78d4c39f|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|L1StandardBridge|0xeb9bf100225c214efc3e7c651ebbadcf85177607|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|L1ERC721Bridge|0x5933e323be8896dfacd1cd671442f27daa10a053|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|OptimismMintableERC20Factory|0xc1047e30efc9e172cfe7aa0219895b6a43fc415f|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|DisputeGameFactory|0x512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|DelayedWETH|0x18fbb58c366e21f395ddec7cba0510a2d9116b47|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Soneium|AnchorStateRegistry|0x4890928941e62e273dA359374b105F803329F473|0x89889b569c3a505f3640ee1bd0ac1d557f436d2a|' \
    'Unichain|SystemConfig|0xc407398d063f942febbcc6f80a156b47f3f1bda6|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|OptimismPortal2|0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|ETHLockbox|0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2' \
    'Unichain|L1CrossDomainMessenger|0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|L1StandardBridge|0x81014f44b0a345033bb2b3b21c7a1a308b35feea|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|L1ERC721Bridge|0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|OptimismMintableERC20Factory|0xa2b597eaeacb6f627e088cbead319e934ed5edad|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|DisputeGameFactory|0x2f12d621a16e2d3285929c9996f478508951dfe4|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|DelayedWETH|0x74ad145ac900f1dd5551f0c9e143314dc4022fcf|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|' \
    'Unichain|AnchorStateRegistry|0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9|0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4|'
}

slot_list() {
  local name=$1
  seq 0 69
  case "$name" in
    SystemConfig|DisputeGameFactory)
      seq 70 109
      ;;
    L1CrossDomainMessenger)
      seq 201 207
      seq 251 254
      ;;
  esac
}

safe_call() {
  local address=$1
  shift
  local out
  if out=$(cast call "$address" "$@" --rpc-url "$rpc_url" 2>/dev/null); then
    printf '%s' "$out"
  else
    printf '%s' '<reverted-or-absent>'
  fi
}

add_getter() {
  local current=$1
  local key=$2
  shift 2
  local value
  value=$(safe_call "$@")
  jq -c --arg key "$key" --arg value "$value" '. + {($key): $value}' <<< "$current"
}

getters_for() {
  local name=$1
  local proxy=$2
  local portal=${3:-}
  local getters='{}'

  getters=$(add_getter "$getters" version "$proxy" 'version()(string)')
  getters=$(add_getter "$getters" initVersion "$proxy" 'initVersion()(uint8)')
  case "$name" in
    SuperchainConfig)
      getters=$(add_getter "$getters" guardian "$proxy" 'guardian()(address)')
      getters=$(add_getter "$getters" globalPaused "$proxy" 'paused(address)(bool)' 0x0000000000000000000000000000000000000000)
      ;;
    SystemConfig)
      getters=$(add_getter "$getters" owner "$proxy" 'owner()(address)')
      getters=$(add_getter "$getters" l2ChainId "$proxy" 'l2ChainId()(uint256)')
      getters=$(add_getter "$getters" superchainConfig "$proxy" 'superchainConfig()(address)')
      getters=$(add_getter "$getters" unsafeBlockSigner "$proxy" 'unsafeBlockSigner()(address)')
      getters=$(add_getter "$getters" l1CrossDomainMessenger "$proxy" 'l1CrossDomainMessenger()(address)')
      getters=$(add_getter "$getters" l1ERC721Bridge "$proxy" 'l1ERC721Bridge()(address)')
      getters=$(add_getter "$getters" l1StandardBridge "$proxy" 'l1StandardBridge()(address)')
      getters=$(add_getter "$getters" optimismPortal "$proxy" 'optimismPortal()(address)')
      getters=$(add_getter "$getters" optimismMintableERC20Factory "$proxy" 'optimismMintableERC20Factory()(address)')
      getters=$(add_getter "$getters" delayedWETH "$proxy" 'delayedWETH()(address)')
      getters=$(add_getter "$getters" lastUsedOPCM "$proxy" 'lastUsedOPCM()(address)')
      getters=$(add_getter "$getters" lastUsedOPCMVersion "$proxy" 'lastUsedOPCMVersion()(string)')
      getters=$(add_getter "$getters" startBlock "$proxy" 'startBlock()(uint256)')
      getters=$(add_getter "$getters" paused "$proxy" 'paused()(bool)')
      getters=$(add_getter "$getters" feature_ETH_LOCKBOX "$proxy" 'isFeatureEnabled(bytes32)(bool)' "$eth_lockbox_feature")
      getters=$(add_getter "$getters" feature_INTEROP "$proxy" 'isFeatureEnabled(bytes32)(bool)' "$interop_feature")
      getters=$(add_getter "$getters" feature_CUSTOM_GAS_TOKEN "$proxy" 'isFeatureEnabled(bytes32)(bool)' "$custom_gas_token_feature")
      ;;
    OptimismPortal2)
      getters=$(add_getter "$getters" systemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" anchorStateRegistry "$proxy" 'anchorStateRegistry()(address)')
      getters=$(add_getter "$getters" ethLockbox "$proxy" 'ethLockbox()(address)')
      getters=$(add_getter "$getters" l2Sender "$proxy" 'l2Sender()(address)')
      getters=$(add_getter "$getters" paused "$proxy" 'paused()(bool)')
      getters=$(add_getter "$getters" respectedGameType "$proxy" 'respectedGameType()(uint32)')
      ;;
    ETHLockbox)
      getters=$(add_getter "$getters" legacySystemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" superchainConfig "$proxy" 'superchainConfig()(address)')
      getters=$(add_getter "$getters" paused "$proxy" 'paused()(bool)')
      if [[ -n "$portal" ]]; then
        getters=$(add_getter "$getters" authorizedPortal "$proxy" 'authorizedPortals(address)(bool)' "$portal")
      fi
      ;;
    L1CrossDomainMessenger)
      getters=$(add_getter "$getters" systemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" portal "$proxy" 'portal()(address)')
      getters=$(add_getter "$getters" otherMessenger "$proxy" 'otherMessenger()(address)')
      ;;
    L1StandardBridge|L1ERC721Bridge)
      getters=$(add_getter "$getters" systemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" messenger "$proxy" 'messenger()(address)')
      getters=$(add_getter "$getters" otherBridge "$proxy" 'otherBridge()(address)')
      ;;
    OptimismMintableERC20Factory)
      getters=$(add_getter "$getters" bridge "$proxy" 'bridge()(address)')
      ;;
    DisputeGameFactory)
      getters=$(add_getter "$getters" owner "$proxy" 'owner()(address)')
      getters=$(add_getter "$getters" gameCount "$proxy" 'gameCount()(uint256)')
      for game_type in $(seq 0 10); do
        getters=$(add_getter "$getters" "gameImpls_$game_type" "$proxy" 'gameImpls(uint32)(address)' "$game_type")
        getters=$(add_getter "$getters" "initBonds_$game_type" "$proxy" 'initBonds(uint32)(uint256)' "$game_type")
        getters=$(add_getter "$getters" "gameArgs_$game_type" "$proxy" 'gameArgs(uint32)(bytes)' "$game_type")
      done
      ;;
    DelayedWETH)
      getters=$(add_getter "$getters" legacySystemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" ethLockbox "$proxy" 'ethLockbox()(address)')
      getters=$(add_getter "$getters" config "$proxy" 'config()(address)')
      getters=$(add_getter "$getters" delay "$proxy" 'delay()(uint256)')
      ;;
    AnchorStateRegistry)
      getters=$(add_getter "$getters" legacySystemConfig "$proxy" 'systemConfig()(address)')
      getters=$(add_getter "$getters" ethLockbox "$proxy" 'ethLockbox()(address)')
      getters=$(add_getter "$getters" disputeGameFactory "$proxy" 'disputeGameFactory()(address)')
      getters=$(add_getter "$getters" anchorGame "$proxy" 'anchorGame()(address)')
      getters=$(add_getter "$getters" respectedGameType "$proxy" 'respectedGameType()(uint32)')
      getters=$(add_getter "$getters" retirementTimestamp "$proxy" 'retirementTimestamp()(uint64)')
      getters=$(add_getter "$getters" paused "$proxy" 'paused()(bool)')
      ;;
  esac
  printf '%s' "$getters"
}

index=0
while IFS='|' read -r chain name proxy proxy_admin portal; do
  index=$((index + 1))
  request_file="$tmp_dir/request-$index.json"
  response_file="$tmp_dir/response-$index.json"
  object_file="$tmp_dir/object-$index.json"

  slot_list "$name" | while read -r slot; do
    printf '%s\t0x%x\n' "$slot" "$slot"
  done | jq -Rn --arg proxy "$proxy" '[inputs | split("\t") | {
      jsonrpc: "2.0", id: (.[0] | tonumber), method: "eth_getStorageAt",
      params: [$proxy, .[1], "latest"]
    }]' > "$request_file"
  curl -sS -H 'content-type: application/json' --data-binary @"$request_file" "$rpc_url" > "$response_file"
  # The shared local fork can occasionally return a transient per-item error in a large batch.
  # Retry only those read-only storage requests individually and require a complete dump.
  while read -r failed_slot; do
    [[ -z "$failed_slot" ]] && continue
    retry_value=$(cast storage "$proxy" "$failed_slot" --rpc-url "$rpc_url")
    jq --argjson id "$failed_slot" --arg value "$retry_value" '
      map(if .id == $id then {jsonrpc: "2.0", id: $id, result: $value} else . end)
    ' "$response_file" > "$response_file.retry"
    mv "$response_file.retry" "$response_file"
  done < <(jq -r '.[] | select(.result == null) | .id' "$response_file")
  jq -e 'all(.[]; .result != null)' "$response_file" >/dev/null

  slot_zero=$(jq -r '.[] | select(.id == 0) | .result' "$response_file")
  if [[ "$name" == L1CrossDomainMessenger ]]; then
    raw=${slot_zero#0x}
    initialized_hex=${raw:22:2}
  else
    initialized_hex=${slot_zero: -2}
  fi
  initialized_version=$((16#$initialized_hex))

  if [[ "$name" == L1CrossDomainMessenger ]]; then
    implementation=$(safe_call "$proxy_admin" 'getProxyImplementation(address)(address)' "$proxy")
  else
    implementation_raw=$(cast storage "$proxy" "$impl_slot" --rpc-url "$rpc_url")
    implementation=0x${implementation_raw: -40}
  fi
  admin_raw=$(cast storage "$proxy" "$admin_slot" --rpc-url "$rpc_url")
  proxy_admin_slot=0x${admin_raw: -40}
  version=$(safe_call "$proxy" 'version()(string)')
  eth_balance=$(cast balance "$proxy" --rpc-url "$rpc_url")
  getters=$(getters_for "$name" "$proxy" "$portal")
  extra_slots='{}'

  if [[ "$name" == SystemConfig ]]; then
    opcm_storage_slot=$(safe_call "$proxy" 'OPCM_SLOT()(bytes32)')
    opcm_raw=$(cast storage "$proxy" "$opcm_storage_slot" --rpc-url "$rpc_url")
    opcm_decoded=$(jq -r '.lastUsedOPCM' <<< "$getters")
    extra_slots=$(jq -c --arg slot "$opcm_storage_slot" --arg raw "$opcm_raw" --arg decoded "$opcm_decoded" '
      . + {($slot):{label:"OPCM_SLOT/lastUsedOPCM",type:"address",raw:$raw,decoded:$decoded}}
    ' <<< "$extra_slots")
    for feature_row in \
      "ETH_LOCKBOX|$eth_lockbox_feature" \
      "INTEROP|$interop_feature" \
      "CUSTOM_GAS_TOKEN|$custom_gas_token_feature"; do
      IFS='|' read -r feature_name feature_key <<< "$feature_row"
      feature_slot=$(cast index bytes32 "$feature_key" 109)
      feature_raw=$(cast storage "$proxy" "$feature_slot" --rpc-url "$rpc_url")
      feature_decoded=$(jq -r ".feature_$feature_name" <<< "$getters")
      extra_slots=$(jq -c --arg slot "$feature_slot" --arg name "$feature_name" --arg raw "$feature_raw" \
        --arg decoded "$feature_decoded" '
          . + {($slot):{label:("isFeatureEnabled["+$name+"]"),type:"bool",raw:$raw,decoded:$decoded}}
        ' <<< "$extra_slots")
    done
  elif [[ "$name" == DisputeGameFactory ]]; then
    for game_type in $(seq 0 10); do
      for mapping_row in 'gameImpls|101|address' 'initBonds|102|uint256' 'gameArgs|105|bytes-dynamic-head'; do
        IFS='|' read -r mapping_name mapping_base mapping_type <<< "$mapping_row"
        mapping_slot=$(cast index uint32 "$game_type" "$mapping_base")
        mapping_raw=$(cast storage "$proxy" "$mapping_slot" --rpc-url "$rpc_url")
        mapping_decoded=$(jq -r ".${mapping_name}_${game_type}" <<< "$getters")
        extra_slots=$(jq -c --arg slot "$mapping_slot" --arg name "$mapping_name" \
          --arg gameType "$game_type" --arg type "$mapping_type" --arg raw "$mapping_raw" \
          --arg decoded "$mapping_decoded" '
            . + {($slot):{
              label:($name+"["+$gameType+"]"),type:$type,raw:$raw,decoded:$decoded
            }}
          ' <<< "$extra_slots")
      done
    done
  fi

  jq -n \
    --arg chain "$chain" \
    --arg name "$name" \
    --arg proxy "$proxy" \
    --arg implementation "$implementation" \
    --arg proxyAdmin "$proxy_admin" \
    --arg proxyAdminSlot "$proxy_admin_slot" \
    --arg version "$version" \
    --argjson initializedVersion "$initialized_version" \
    --arg ethBalanceWei "$eth_balance" \
    --argjson getters "$getters" \
    --argjson extraSlots "$extra_slots" \
    --slurpfile response "$response_file" \
    --slurpfile layout "$layout_root/$name.json" '
      ($layout[0] | group_by(.slot) | map({
        key: .[0].slot,
        value: {
          label: (map(.label + "@offset" + (.offset|tostring)) | join(", ")),
          type: (map(.type) | join(", "))
        }
      }) | from_entries) as $layoutMap |
      (($response[0] | map({
        key: (.id | tostring),
        value: (($layoutMap[(.id|tostring)] // {label: "<unused-or-unstructured>", type: "bytes32"})
          + {raw: .result, decoded: null})
      }) | from_entries) + $extraSlots) as $slots |
      {
        chain: $chain,
        name: $name,
        value: {
          proxy: $proxy,
          implementation: $implementation,
          proxyAdmin: $proxyAdmin,
          proxyAdminSlot: $proxyAdminSlot,
          version: $version,
          initializedVersion: $initializedVersion,
          slots: $slots,
          getters: $getters,
          ethBalance: $ethBalanceWei
        }
      }' > "$object_file"
done < <(targets)

jq -s \
  --arg rpc "$rpc_url" \
  --argjson block "$block_number" '
    reduce .[] as $item (
      {schemaVersion: 1, rpc: $rpc, block: $block, chains: {}};
      .chains[$item.chain].contracts[$item.name] = $item.value
    )' "$tmp_dir"/object-*.json > "$output_json"

jq -e . "$output_json" >/dev/null
echo "wrote $output_json"
