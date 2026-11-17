#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <prove-tx-hash> <pre|post> <output-json>" >&2
  exit 2
fi

tx_hash=$1
era=$2
output_json=$3
archive_rpc=${ARCHIVE_RPC:-https://eth.drpc.org}
state_rpc=http://127.0.0.1:8545
if [[ "$era" == pre ]]; then
  state_rpc=http://127.0.0.1:8546
elif [[ "$era" != post ]]; then
  echo "era must be pre or post" >&2
  exit 2
fi

portal=0xbEb5Fc579115071764c7423A4f12eDde41f106Ed
factory=0xe5965Ab5962eDc7477C8520243A95517CD252fA9
prove_topic=0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62
extension_topic=0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97
signature='proveWithdrawalTransaction((uint256,address,address,uint256,uint256,bytes),uint256,(bytes32,bytes32,bytes32,bytes32),bytes[])'

tx_json=$(cast tx "$tx_hash" --json --rpc-url "$archive_rpc")
receipt_json=$(cast receipt "$tx_hash" --json --rpc-url "$archive_rpc")
input=$(jq -r '.input' <<<"$tx_json")
decoded=$(cast calldata-decode --json "$signature" "$input")
block_hex=$(jq -r '.blockNumber' <<<"$tx_json")
block_number=$(cast to-dec "$block_hex")
block_json=$(cast block "$block_number" --json --rpc-url "$archive_rpc")
block_timestamp=$(cast to-dec "$(jq -r '.timestamp' <<<"$block_json")")

proven_log=$(jq -c --arg topic "$prove_topic" '.logs[] | select(.topics[0] == $topic)' <<<"$receipt_json")
extension_log=$(jq -c --arg topic "$extension_topic" '.logs[] | select(.topics[0] == $topic)' <<<"$receipt_json")
withdrawal_hash=$(jq -r '.topics[1]' <<<"$proven_log")
proof_submitter=$(jq -r '"0x" + (.topics[2][-40:])' <<<"$extension_log")
game_index=$(jq -r '.[1]' <<<"$decoded")
game_data=$(cast call "$factory" 'gameAtIndex(uint256)(uint32,uint64,address)' "$game_index" --json --rpc-url "$state_rpc")
game_address=$(jq -r '.[2]' <<<"$game_data")
game_status=$(cast call "$game_address" 'status()(uint8)' --json --rpc-url "$state_rpc" | jq -r '.[0]')
game_created_at=$(cast call "$game_address" 'createdAt()(uint64)' --json --rpc-url "$state_rpc" | jq -r '.[0]')
game_resolved_at=$(cast call "$game_address" 'resolvedAt()(uint64)' --json --rpc-url "$state_rpc" | jq -r '.[0]')
proven_data=$(cast call "$portal" 'provenWithdrawals(bytes32,address)(address,uint64)' \
  "$withdrawal_hash" "$proof_submitter" --json --rpc-url "$state_rpc")
finalized=$(cast call "$portal" 'finalizedWithdrawals(bytes32)(bool)' \
  "$withdrawal_hash" --json --rpc-url "$state_rpc" | jq -r '.[0]')

jq -n \
  --arg schema "lane31-real-withdrawal-fixture-v1" \
  --arg era "$era" \
  --arg txHash "$tx_hash" \
  --argjson tx "$tx_json" \
  --argjson decoded "$decoded" \
  --argjson blockNumber "$block_number" \
  --argjson blockTimestamp "$block_timestamp" \
  --arg withdrawalHash "$withdrawal_hash" \
  --arg proofSubmitter "$proof_submitter" \
  --argjson gameData "$game_data" \
  --argjson gameStatus "$game_status" \
  --argjson gameCreatedAt "$game_created_at" \
  --argjson gameResolvedAt "$game_resolved_at" \
  --argjson provenData "$proven_data" \
  --argjson finalized "$finalized" \
  '{
    schema: $schema,
    era: $era,
    provenance: {
      proveTxHash: $txHash,
      proveTxFrom: $tx.from,
      portal: $tx.to,
      blockNumber: $blockNumber,
      blockTimestamp: $blockTimestamp,
      rawCalldata: $tx.input,
      withdrawalHash: $withdrawalHash,
      proofSubmitter: $proofSubmitter
    },
    withdrawal: {
      nonce: ($decoded[0][0] | tostring),
      sender: $decoded[0][1],
      target: $decoded[0][2],
      value: ($decoded[0][3] | tostring),
      gasLimit: ($decoded[0][4] | tostring),
      data: $decoded[0][5]
    },
    proof: {
      disputeGameIndex: $decoded[1],
      outputRootProof: {
        version: $decoded[2][0],
        stateRoot: $decoded[2][1],
        messagePasserStorageRoot: $decoded[2][2],
        latestBlockhash: $decoded[2][3]
      },
      withdrawalProof: $decoded[3]
    },
    observedState: {
      stateRpcEra: $era,
      disputeGameType: $gameData[0],
      disputeGameCreatedAt: $gameData[1],
      disputeGame: $gameData[2],
      gameStatus: $gameStatus,
      gameCreatedAt: $gameCreatedAt,
      gameResolvedAt: $gameResolvedAt,
      storedProofGame: $provenData[0],
      storedProofTimestamp: $provenData[1],
      finalized: $finalized
    }
  }' > "$output_json"

jq '{proveTx:.provenance.proveTxHash,withdrawalHash:.provenance.withdrawalHash,gameType:.observedState.disputeGameType,value:.withdrawal.value,finalized:.observedState.finalized}' "$output_json"
