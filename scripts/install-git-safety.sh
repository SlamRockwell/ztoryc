#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "ERROR: hooks directory not found: $HOOKS_DIR"
  exit 1
fi

chmod +x "$HOOKS_DIR/pre-push"
git config --local core.hooksPath .githooks

echo "Installed repository git safety hooks."
echo "Active hooksPath: $(git config --local core.hooksPath)"
