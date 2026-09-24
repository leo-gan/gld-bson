#!/usr/bin/env bash
# Byte-compare this library with pymongo. Python is the oracle only.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
python3 tests_interop/oracle.py
