#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <rpc-url> <from-block> <to-block> <output-dir>" >&2
  exit 2
fi

rpc_url=$1
from_block=$2
to_block=$3
output_dir=$4
portal=0xbEb5Fc579115071764c7423A4f12eDde41f106Ed
proven=0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62
extension=0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97
finalized=0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b

mkdir -p "$output_dir/chunks"

seq "$from_block" 100 "$to_block" | xargs -P 2 -I BLOCK bash -c '
  set -euo pipefail
  start=$1
  limit=$2
  end=$((start + 99))
  if (( end > limit )); then end=$limit; fi
  if [[ -f "$8/chunks/$start.json" ]]; then
    exit 0
  fi
  from_hex=$(printf "0x%x" "$start")
  to_hex=$(printf "0x%x" "$end")
  payload=$(jq -cn \
    --arg address "$3" \
    --arg from "$from_hex" \
    --arg to "$to_hex" \
    --arg proven "$4" \
    --arg extension "$5" \
    --arg finalized "$6" \
    "{jsonrpc:\"2.0\",id:1,method:\"eth_getLogs\",params:[{address:\$address,fromBlock:\$from,toBlock:\$to,topics:[[\$proven,\$extension,\$finalized]]}]}"
  )
  response=$(curl --fail-with-body -sS --retry 8 --retry-all-errors --retry-delay 1 \
    -X POST "$7" -H "content-type: application/json" --data "$payload")
  error=$(jq -r ".error.message // empty" <<<"$response")
  if [[ -n "$error" ]]; then
    jq -cn --argjson start "$start" --argjson end "$end" --arg error "$error" \
      "{start:\$start,end:\$end,error:\$error}" > "$8/chunks/$start.error.json"
    exit 0
  fi
  jq -c ".result" <<<"$response" > "$8/chunks/$start.json"
  rm -f "$8/chunks/$start.error.json"
' _ BLOCK "$to_block" "$portal" "$proven" "$extension" "$finalized" "$rpc_url" "$output_dir"

find "$output_dir/chunks" -name '*.json' ! -name '*.error.json' -print0 \
  | sort -z \
  | xargs -0 jq -s 'add' > "$output_dir/portal-events.json"

find "$output_dir/chunks" -name '*.error.json' -print0 \
  | sort -z \
  | xargs -0 -r jq -s '.' > "$output_dir/errors.json"

jq -n \
  --arg rpc "$rpc_url" \
  --argjson from "$from_block" \
  --argjson to "$to_block" \
  --slurpfile events "$output_dir/portal-events.json" \
  --slurpfile errors "$output_dir/errors.json" \
  '{rpc:$rpc,fromBlock:$from,toBlock:$to,eventCount:($events[0]|length),errorCount:($errors[0]|length)}'
