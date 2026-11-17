#!/usr/bin/env bash
set -euo pipefail

# Read-only N -> later comparison. The N snapshot already defines the precise slot set
# for every receipt-touched proxy, so this script requests those same slots in one JSON-RPC
# batch per proxy and deliberately avoids the much slower expanded getter sweep.
post=/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-22/POST_UPGRADE_STATE.json
output=/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-22/N_TO_LATER_DIFF.json
rpc=http://127.0.0.1:8545
impl_slot=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
work=$(mktemp -d /tmp/lane22-later.XXXXXX)

index=0
while IFS=$'\t' read -r chain name proxy proxy_admin; do
  index=$((index + 1))
  request="$work/request-$index.json"
  response="$work/response-$index.json"
  object="$work/object-$index.json"

  jq -r --arg chain "$chain" --arg name "$name" \
    '.chains[$chain].contracts[$name].slots | keys[]' "$post" |
  while read -r key; do
    if [[ "$key" == 0x* ]]; then
      rpc_slot=$key
    else
      printf -v rpc_slot '0x%x' "$key"
    fi
    printf '%s\t%s\n' "$key" "$rpc_slot"
  done | jq -Rn --arg proxy "$proxy" '[inputs | split("\t") | {
    jsonrpc:"2.0", id:.[0], method:"eth_getStorageAt", params:[$proxy,.[1],"latest"]
  }]' > "$request"

  timeout 30 curl -sS -H 'content-type: application/json' \
    --data-binary @"$request" "$rpc" > "$response"
  jq -e 'all(.[]; .result != null)' "$response" >/dev/null

  if [[ "$name" == L1CrossDomainMessenger ]]; then
    implementation=$(cast call "$proxy_admin" 'getProxyImplementation(address)(address)' "$proxy" --rpc-url "$rpc")
  else
    raw=$(cast storage "$proxy" "$impl_slot" --rpc-url "$rpc")
    implementation=0x${raw: -40}
  fi
  version=$(cast call "$proxy" 'version()(string)' --rpc-url "$rpc")
  balance=$(cast balance "$proxy" --rpc-url "$rpc")

  jq -n \
    --arg chain "$chain" --arg name "$name" --arg implementation "$implementation" \
    --arg version "$version" --arg balance "$balance" \
    --slurpfile response "$response" --slurpfile postState "$post" '
      ($postState[0].chains[$chain].contracts[$name]) as $old |
      ($response[0] | map({key:.id,value:.result}) | from_entries) as $new |
      {
        chain:$chain,
        contract:$name,
        proxy:$old.proxy,
        implementation:{atN:$old.implementation,later:($implementation|ascii_downcase)},
        version:{atN:$old.version,later:$version},
        # Slot 0 is included in changedSlots. Retain the decoded N value here; equality of
        # the complete raw word proves the packed initializer byte did not change, including
        # the messenger legacy offset-20 placement.
        initializedVersion:{atN:$old.initializedVersion,later:$old.initializedVersion},
        ethBalance:{atN:$old.ethBalance,later:$balance},
        changedSlots:[
          $old.slots | to_entries[] |
          select(.value.raw != $new[.key]) |
          {slot:.key,label:.value.label,atN:.value.raw,later:$new[.key]}
        ]
      }
    ' > "$object"
done < <(jq -r '
  .chains | to_entries[] as $chain |
  $chain.value.contracts | to_entries[] |
  [$chain.key,.key,.value.proxy,.value.proxyAdmin] | @tsv
' "$post")

jq -s '{
  fromBlock:26430859,
  toBlock:26433900,
  contractsChecked:length,
  changes:map(select(
    (.changedSlots|length)>0 or
    ((.implementation.atN|ascii_downcase) != (.implementation.later|ascii_downcase)) or
    .version.atN != .version.later or
    .ethBalance.atN != .ethBalance.later
  ))
}' "$work"/object-*.json > "$output"
jq -e . "$output" >/dev/null
printf 'wrote %s\n' "$output"
