#!/usr/bin/env bash
# Refuse a prompt file that does not start with CADRE-LEGAL.md verbatim.
set -euo pipefail
M=/home/user/Tracking_Body/optimism-bedrock-u21-megahunt
n=$(wc -c < "$M/CADRE-LEGAL.md")
for f in "$@"; do
  if cmp -s -n "$n" "$M/CADRE-LEGAL.md" "$f"; then echo "OK  $f"; else echo "MISSING CADRE-LEGAL: $f"; exit 1; fi
done
