#!/bin/bash
# (re)start the lane-08 private anvil: $1 = port (18080..18089), $2 = upstream local anvil url, $3 = fork block
PORT=$1; UP=$2; BLK=$3
pkill -f "anvil --fork-url .* --port $PORT " 2>/dev/null
for i in $(seq 1 60); do pgrep -f "anvil --fork-url .* --port $PORT " >/dev/null || break; sleep 0.5; done
nohup anvil --fork-url $UP --fork-block-number $BLK --port $PORT --hardfork prague --retries 30 --fork-retry-backoff 1500 --timeout 60000 --no-mining --gas-limit 60000000 > /home/user/u21-work/lane08/data/anvil$PORT.log 2>&1 &
for i in $(seq 1 60); do cast block-number --rpc-url http://127.0.0.1:$PORT >/dev/null 2>&1 && break; sleep 0.5; done
cast block-number --rpc-url http://127.0.0.1:$PORT
