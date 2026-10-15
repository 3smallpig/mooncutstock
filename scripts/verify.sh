#!/usr/bin/env bash
set -euo pipefail
target="${1:-wasm-gc}"
moon info
moon fmt --check
git diff --exit-code -- '*.mbti'
moon check --deny-warn --target "$target"
moon test --deny-warn --target "$target"
moon build --deny-warn --target "$target"
for example in procurement rollover scenarios; do
  moon run "examples/$example" --target "$target"
done
moon run cmd/mooncutstock --target "$target" -- demo
moon run cmd/mooncutstock --target "$target" -- help
python3 scripts/audit.py
