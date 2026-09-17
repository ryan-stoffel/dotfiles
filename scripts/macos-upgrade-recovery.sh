#!/usr/bin/env bash
# macOS major-upgrade recovery for this nix-darwin setup.
# Run after upgrading (e.g. to macOS 27) if `nix` is missing or rebuild fails.
# Safe to run repeatedly; diagnoses first, then repairs only what is broken.
#
#   ~/.dotfiles/scripts/macos-upgrade-recovery.sh
#
set -uo pipefail

REPO="${DOTFILES:-$HOME/.dotfiles}"
FLAKE="$REPO/nix-darwin#macbook"
DARWIN_STORE=/Library/LaunchDaemons/org.nixos.darwin-store.plist
NIX_DAEMON=/Library/LaunchDaemons/org.nixos.nix-daemon.plist

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok() { printf ' \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf ' \033[33m!\033[0m %s\n' "$*"; }
bad() { printf ' \033[31m✗\033[0m %s\n' "$*"; }

bold "== 1. Diagnostics =="

NIX_MOUNTED=0
if mount | grep -q ' on /nix '; then
  NIX_MOUNTED=1
  ok "/nix is mounted"
else
  bad "/nix is not mounted (store may still exist on disk)"
fi

if command -v nix >/dev/null 2>&1; then
  ok "nix: $(nix --version)"
else
  bad "nix not on PATH"
fi

bold "== 2. Background Task Management (BTM) =="
BTM="$(sudo sfltool dumpbtm 2>/dev/null | grep -iA6 -E 'nixos|darwin-store' || true)"
if echo "$BTM" | grep -qi disallowed; then
  bad "Nix-related background items are disallowed — this often breaks Nix after reboot."
  echo
  echo "  System Settings → General → Login Items & Extensions"
  echo "  → Allow in the Background"
  echo "  → enable the \"sh\" / unidentified-developer items tied to Nix (often two)"
  echo
  echo "  Reboot, then run this script again."
elif [ -n "$BTM" ]; then
  ok "BTM entries found for Nix (review above if daemons still fail)"
  printf '%s\n' "$BTM" | sed 's/^/    /'
else
  warn "No BTM entries matched nixos/darwin-store (may be fine on this macOS version)"
fi

bold "== 3. Mount /nix and bootstrap system daemons =="
if [ "$NIX_MOUNTED" -eq 0 ] && [ -f "$DARWIN_STORE" ]; then
  warn "Bootstrapping org.nixos.darwin-store…"
  sudo launchctl bootstrap system "$DARWIN_STORE" 2>/dev/null || true
  sudo launchctl kickstart -k system/org.nixos.darwin-store 2>/dev/null || true
  if mount | grep -q ' on /nix '; then
    ok "/nix mounted"
    NIX_MOUNTED=1
  else
    bad "/nix still not mounted — fix BTM, reboot, re-run this script"
  fi
fi

if [ -f "$NIX_DAEMON" ]; then
  if ! sudo launchctl print system/org.nixos.nix-daemon >/dev/null 2>&1; then
    warn "Bootstrapping org.nixos.nix-daemon…"
    sudo launchctl bootstrap system "$NIX_DAEMON" 2>/dev/null || true
    sudo launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null || true
  fi
fi

if ! command -v nix >/dev/null 2>&1 && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if command -v nix >/dev/null 2>&1; then
  ok "nix available: $(nix --version)"
else
  bad "nix still unavailable — complete BTM step and reboot before rebuild"
  exit 1
fi

bold "== 4. Refresh flake inputs (optional but recommended on new macOS) =="
if [ -d "$REPO/nix-darwin" ]; then
  warn "Updating lockfile: nix flake update --flake $REPO/nix-darwin"
  nix flake update --flake "$REPO/nix-darwin" || bad "flake update failed"
else
  bad "Missing $REPO/nix-darwin — clone dotfiles first"
  exit 1
fi

bold "== 5. darwin-rebuild =="
if [ -x "$REPO/scripts/rebuild.sh" ]; then
  "$REPO/scripts/rebuild.sh" && ok "rebuild finished"
else
  warn "Using darwin-rebuild switch --flake $FLAKE"
  sudo darwin-rebuild switch --flake "$FLAKE"
fi

bold "== 6. Health check =="
if [ -f "$REPO/scripts/doctor.py" ]; then
  python3 "$REPO/scripts/doctor.py" || warn "doctor reported issues — review output"
else
  warn "doctor.py not found"
fi

bold "Done. Open Docker Desktop if needed, then: dbrew && docker info"
