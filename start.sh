#!/bin/bash
# Phase 1 demo 本地 http server
set -e
cd "$(dirname "$0")"
PORT="${PORT:-8765}"
echo "▶ Serving http://localhost:$PORT  (Ctrl+C to stop)"
# 优先 python3，回退 npx serve
if command -v python3 >/dev/null 2>&1; then
  python3 -m http.server "$PORT"
elif command -v npx >/dev/null 2>&1; then
  npx --yes serve -l "$PORT"
else
  echo "需要 python3 或 npx" >&2
  exit 1
fi
