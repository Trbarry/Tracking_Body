#!/usr/bin/env bash
set -euo pipefail

post=/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-22/POST_UPGRADE_STATE.json
rpc=http://127.0.0.1:8545
output=/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-22/N_TO_LATER_DIFF.json
impl_slot=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

index=0
while IFS=$'\t' read -r chain name proxy proxy_admin slots_json; do
  index=$((index + 1))
  request="$tmp_dir/request-$index.json"
  response="$tmp_dir/response-$index.json"
  object="$tmp_dir/object-$index.json"

  # Fetch a proof for all declared slots in one upstream request. This avoids making the
  # archive fork resolve each empty slot as a separate upstream eth_getStorageAt call.
  jq -r '.[]' <<< "$slots_json" | while read -r slot; do
    printf '"0x%064x"\n' "$slot"
  done | jq -s . > "$request"
  timeout 30 cast rpc --rpc-url "$rpc" eth_getProof "$proxy" "$(<"$request")" latest > "$response"
  jq -e '.storageProof != null' "$response" >/dev/null

  if [[ "$name" == L1CrossDomainMessenger ]]; then
    implementation=$(cast call "$proxy_admin" 'getProxyImplementation(address)(address)' "$proxy" --rpc-url "$rpc")
  else
    implementation_raw=$(cast storage "$proxy" "$impl_slot" --rpc-url "$rpc")
    implementation=0x${implementation_raw: -40}
  fi
  version=$(cast call "$proxy" 'version()(string)' --rpc-url "$rpc")
  balance=$(cast balance "$proxy" --rpc-url "$rpc")

  jq -n \
    --arg chain "$chain" --arg name "$name" --arg implementation "$implementation" \
    --arg version "$version" --arg balance "$balance" \
    --argjson requestedSlots "$slots_json" \
    --slurpfile later "$response" --slurpfile postState "$post" '
      ($postState[0].chains[$chain].contracts[$name]) as $old |
      ($later[0].storageProof | to_entries | map({
        key:($requestedSlots[.key]|tostring),
        value:("0x" + (("0000000000000000000000000000000000000000000000000000000000000000"
          + (.value.value|ltrimstr("0x")))[-64:]))
      }) | from_entries) as $newSlots |
      {
        chain:$chain,
        contract:$name,
        implementation:{atN:$old.implementation,later:$implementation},
        version:{atN:$old.version,later:$version},
        ethBalance:{atN:$old.ethBalance,later:$balance},
        changedSlots:[
          ($old.slots|to_entries[]) as $slot |
          select($slot.value.raw != $newSlots[$slot.key]) |
          {slot:$slot.key,label:$slot.value.label,atN:$slot.value.raw,later:$newSlots[$slot.key]}
        ]
      }
  ' > "$object"
done < <(jq -r '
  .chains|to_entries[] as $ch |
  $ch.value.contracts|to_entries[] |
  [$ch.key,.key,.value.proxy,.value.proxyAdmin,
   (.value.slots|to_entries|map(select(.value.label != "<unused-or-unstructured>")|.key|tonumber)|tojson)]|@tsv
' "$post")

jq -s '
  {
    fromBlock:26430859,
    toBlock:26433900,
    contractsChecked:length,
    changes:map(select(
      (.changedSlots|length)>0 or
      .implementation.atN != .implementation.later or
      .version.atN != .version.later or
      .ethBalance.atN != .ethBalance.later
    ))
  }
' "$tmp_dir"/object-*.json > "$output"
jq -e . "$output" >/dev/null
echo "wrote $output"
