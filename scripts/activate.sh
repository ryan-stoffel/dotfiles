#!/bin/bash
# Same profile switch and activation used by darwin-rebuild, without root Git reads.
set -euo pipefail
system="${1:?Provide the built darwin-system store path}"
if [ "$(id -u)" -ne 0 ]; then
  echo "System activation requires administrator authentication." >&2
  exit 1
fi
case "$system" in
  /nix/store/*-darwin-system-*) ;;
  *) echo "Expected a built darwin-system store path." >&2; exit 1 ;;
esac
test -x "$system/sw/bin/darwin-rebuild"
test -x "$system/activate"
"$system/sw/bin/nix-env" -p /nix/var/nix/profiles/system --set "$system"
"$system/sw/bin/darwin-rebuild" activate
