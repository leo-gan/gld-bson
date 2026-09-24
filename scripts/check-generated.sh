#!/usr/bin/env bash
# Fail if generated Mojo is out of date.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  MOJO=(pixi run mojo)
fi
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --schema testdata/schema/benchmark_v2.json --out "$tmp"
for name in Message Document Telemetry Event; do
  if ! diff -u "tests/generated/${name}.mojo" "$tmp/${name}.mojo"; then
    echo "generated ${name}.mojo is stale; run scripts/generate.sh" >&2
    exit 1
  fi
done
echo "generated sources match"
