#!/usr/bin/env bash
# Install pixi + Mojo 1.1.0 for this repo.
# The Modular conda channel may require PREFIX_API_KEY.
# Never commit .env. PREFIX_API_KEY stays in CI secrets or a local .env.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [[ -f "$root/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$root/.env"
  set +a
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi not found; installing to ~/.pixi/bin" >&2
  curl -fsSL https://pixi.sh/install.sh | bash
  export PATH="${HOME}/.pixi/bin:${PATH}"
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi install failed: pixi is still not on PATH" >&2
  exit 1
fi

echo "pixi: $(pixi --version)"
echo "pin: mojo == 1.1.0"

if ! pixi install; then
  echo "pixi install failed." >&2
  echo "If the error is 401/403 on conda.modular.com, set PREFIX_API_KEY and re-run." >&2
  exit 1
fi

pixi run mojo --version
echo "ok: $(pixi run mojo --version)"
