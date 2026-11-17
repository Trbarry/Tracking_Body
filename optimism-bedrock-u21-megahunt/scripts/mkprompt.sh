#!/usr/bin/env bash
# Build a worker prompt: CADRE-LEGAL.md verbatim, then the brief(s) given as arguments.
# Usage: scripts/mkprompt.sh brief.md [more.md ...] > prompt.md
set -euo pipefail
M=/home/user/Tracking_Body/optimism-bedrock-u21-megahunt
cat "$M/CADRE-LEGAL.md"
printf '\n=========================== WORKER BRIEF ===========================\n\n'
for f in "$@"; do cat "$f"; printf '\n'; done
