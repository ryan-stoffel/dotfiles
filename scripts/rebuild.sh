#!/usr/bin/env bash
# Evaluate/build as the repository owner, then activate the concrete store output.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(id -u)" -eq 0 ]; then
  echo "Run just rebuild as your normal user; only activation needs sudo." >&2
  exit 1
fi
system=$(nix --extra-experimental-features 'nix-command flakes' build \
  --no-write-lock-file --out-link "$repo/nix-darwin/result" --print-out-paths \
  "$repo/nix-darwin#darwinConfigurations.macbook.system")
sudo "$repo/scripts/activate.sh" "$system"
