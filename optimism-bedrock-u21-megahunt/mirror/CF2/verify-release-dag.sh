#!/usr/bin/env bash
# Named test: CF2-DAG-INTEGRITY
# Read-only verification of the mirror deliverables, local tag objects, and pinned-chain receipts.
set -euo pipefail

out_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
optimism_repo=/home/user/ethereum-optimism/optimism
l1_rpc=http://127.0.0.1:7545
l2_rpc=http://127.0.0.1:7546

for json in RELEASE-DAG.json impl-history-op-mainnet.json impl-history-ink.json impl-history-soneium.json impl-history-unichain.json; do
  jq empty "$out_dir/$json"
done

while read -r node tag expected; do
  actual="$(git -C "$optimism_repo" rev-parse "${tag}^{commit}")"
  test "$actual" = "$expected"
  jq -e --arg node "$node" --arg commit "$expected" \
    '.nodes[] | select(.id == $node) | .release.commit == $commit' \
    "$out_dir/RELEASE-DAG.json" >/dev/null
done <<'TAGS'
U1 op-contracts/v1.0.0 a12a09f7000ff785a4058998e09b366cbe5a3ed2
U2 op-contracts/v1.1.0 c383eb880f307caa3ca41010ec10f30f08396b2e
U4 op-contracts/v1.2.0 856c08bf84d9aa829d1e764fc8e9a37d41960ba0
U5 op-contracts/v1.2.0 856c08bf84d9aa829d1e764fc8e9a37d41960ba0
U6 op-contracts/v1.3.0 e6ef3a900c42c8722e72c2e2314027f85d12ced5
U7 op-contracts/v1.4.0 547ea72d9849e13ce169fd31df0f9197651b3f86
U8 op-contracts/v1.5.0 9047beb54c66a5c572784efec8984f259302ec92
U9 op-contracts/v1.5.0 9047beb54c66a5c572784efec8984f259302ec92
U10 op-contracts/v1.6.0 33f06d2d5e4034125df02264a5ffe84571bd0359
U11 op-contracts/v1.8.0 2073f4059bd806af3e8b76b820aa3fa0b42016d0
U13 op-contracts/v2.0.0 8d0dd96e494b2ba154587877351e87788336a4ec
M2.1 op-contracts/v2.1.0 e45b33a0233d172596429676e1d3e89943a17799
M2.2 op-contracts/v2.2.0 7fe5151ad73e90ec7aed7452dee863a06c821209
U14 op-contracts/v3.0.0 ef7a933ca7f3d27ac40406f87fea25e0c3ba2016
M3.0.1 op-contracts/v3.0.1 48e36d5c7fe1a0f211d7447939b5978ccf55f281
U15a op-contracts/v3.0.0 ef7a933ca7f3d27ac40406f87fea25e0c3ba2016
U15 op-contracts/v3.0.0 ef7a933ca7f3d27ac40406f87fea25e0c3ba2016
U16 op-contracts/v4.0.0 54c19f6acb7a6d3505f884bae601733d3d54a3a6
U16a op-contracts/v4.1.0 594bc933a38425f745b46399a3619bcdeb74965d
U17 op-contracts/v5.0.0 d09c836f818c73ae139f60b717654c4e53712743
U18 op-contracts/v6.0.0 018f5ae926ec3277746b56a1c4ddb715c568603d
U19-L1 op-contracts/v7.0.0 a7c88c8d636ceb9944ea0edaf7d033da258778ab
U19b op-contracts/v7.0.0 a7c88c8d636ceb9944ea0edaf7d033da258778ab
U20 op-contracts/v8.0.0 f45a5ccfebcdf6da3f5b09cbc512667c063730b7
U21 op-contracts/v9.0.0 ba6fcadbc57eb99918c5b0f14f57c72527f531e3
TAGS

check_receipt() {
  local rpc=$1 tx=$2 expected=$3 hex_block actual expected_hex
  hex_block="$(cast rpc eth_getTransactionReceipt "$tx" --rpc-url "$rpc" | jq -r '.blockNumber // empty')"
  if test -z "$hex_block"; then
    printf -v expected_hex '0x%x' "$expected"
    cast rpc eth_getBlockByNumber "$expected_hex" false --rpc-url "$rpc" \
      | jq -e --arg tx "$tx" '.transactions | index($tx) != null' >/dev/null
    return
  fi
  actual=$((16#${hex_block#0x}))
  test "$actual" -eq "$expected"
}

while read -r block tx; do
  check_receipt "$l1_rpc" "$tx" "$block"
done <<'L1_RECEIPTS'
17422444 0x76bceccd7d44656f5a129a600a6120091570b897c1d45c18cd7134cfe67c2537
17423158 0xe2ff41f9bdf03d5455f55539b8b9c350276a179ca7f79322e2077d7c1ffb1268
19064589 0x8ba0e42b89cde22310b644ed30fd44e4a348619a165a54c908e7dc341e9bbd0c
19314493 0x3f7c36a1d636cdb23bf4f9171c27ebe58b73f4c0e6a33dbaac2c2f3c142faf50
19634866 0x4758bd62359bc69d7e8a0faaf5308d826379c23258d689a7430d5c0ad0361ad2
19884570 0x2c16c813ff50e9e09a3c58508a9b90293c896f1f91534d09a5002f50bc8760ff
20062696 0xbe810ed6e1e827930bd46cde42c4883662ddb6d244a26af2f0409cc2782bee61
20063224 0xe361c0d4ae3aebc94b3f281ee372fbb1cbdb0c33ca8b1b35e7f3b009b2fcbdb0
20063319 0x50db9c1b9f5a8616f982022429a1d75c35986bcfb67bd1e3358d97ddbe751144
20270847 0x7abecacd8b1a54db8f0835a5c82edfab96ff922a41d2faa914c339e3e9319b43
20723924 0x3bd2d811d0298313e6fb75f0e69fb54280c9b4f2e60f8f04472aaa166c285641
21580854 0x22ab07b0bb1bc8504256835d555307ff522b78651dca33c9cd5b05591ca5b4f7
21695024 0x86da7386a26978c3db89e97c1f4feee613a8a0c07bbe4640624b05276f49c350
21945575 0x9c6af2cb2b4fcde9e351662342f15b60f004108b575dddd05d0caa4f50220966
22081789 0x191505a1bff29cc42fe5a1eb1888170c5241d552d7028d26ec3e54980980cf16
22182531 0x5f3530e593bbac37c61dc5b7755b6a40c06c20c1a3a1b13fca5b7d00cde65c29
22254924 0x7e5e478cafbe30293645e6972a477f77dcfdc006c4cf1dd248a94e6386d04159
22339996 0xbe44244e352a9ffa67ad7f7133e9ed014b380e4b1bd789419e6d33aaad780d12
22342667 0xc74c5e0dddfa9e2d0fd5d902fb7b1aa4cc28ba034ebed7bf3a0aa3a8b8d21b20
22432368 0xc4a7089a92c96b83475a7c20e40b4c888a277a90208d649c81df243ecdceb587
22432925 0xd3247421f6f8039ab186878aa996984a67b3149dd543e688b1d30236516eba00
22990599 0x46acdce174c8d83ebe2f208d8c76c867e75617483d64c3e407f69ae2f9868716
22990670 0xdd89a3933dea0f44e1a461441f3c78e341702e9a4148784780644cdac90148c2
22990722 0x1f1f283ad793a901a94e11241d46b87cd264b2e276a690b9554148ba56c57959
23491328 0x744cf7d28324729cace731ac736872da669439a0d380f1f52b8d31af203f7329
23492571 0xc98240172fa3950ec9c62f32cc09d0eb0ed21684b02f1b2677357674cda64ca5
23877377 0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5
23878509 0x7c9e6b65258838fb38bc0bf584cb0c0802bc0dfbbe877a8639880e2ed88b3aa6
24421512 0x8808cd53114e4cf07bfde30daf24f2984d4a40ab09c5ca67bd171ac29d6dbf37
24427874 0x5672a02ba8c40bd35c87787ceddff5181c588e697a1924be6ea061af71cbb4ca
24478557 0xeba2fc77f814ea5de7fc0e3b1496926483d14cf8541633c04aec9d1fec8eaf9c
25397811 0xbfdac60c9687a2e469159bf2458e73de2915a0a5eb53c4991a7ecde2b1fb3f15
25475307 0xb3c65cbf6285d4b32d576c866fffced1c77747c53163b604e20feb6aad121421
26048619 0x0a0fe86f7b1a3d3d2d0be990e3f8b15628b885363ae527fa9548cb2c2375741a
26430859 0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99
L1_RECEIPTS

check_receipt "$l2_rpc" 0x93b7a9956faec114c3bac7fd72479ebdc23f8aace38220f8914cbf6af971bf6e 121221987

# Every raw implementation-history row must point to a transaction in its claimed L1 block,
# including legacy OVM, genesis deployments, replacement ASR objects, and unchanged-version rows.
while read -r block tx; do
  check_receipt "$l1_rpc" "$tx" "$block"
done < <(
  jq -r '.. | objects | select(has("block") and has("tx")) | [.block, .tx] | @tsv' \
    "$out_dir"/impl-history-*.json | sort -n -u
)

test "$(jq '.nodes | length' "$out_dir/RELEASE-DAG.json")" -eq 29
test "$(jq '.edges | length' "$out_dir/RELEASE-DAG.json")" -eq 30
printf '%s\n' 'CF2-DAG-INTEGRITY PASS'
