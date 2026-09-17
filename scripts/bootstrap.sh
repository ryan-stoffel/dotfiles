#!/usr/bin/env bash
# Provision a fresh Mac from this repo.
# Assumes macOS and internet access. Authentication is completed in the apps.
set -euo pipefail

REPO="$HOME/.dotfiles"
FLAKE="$REPO/nix-darwin"
HOST="macbook"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# 1. Xcode command line tools (git, etc.)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode command line tools..."
  xcode-select --install || true
  echo "Finish the CLT install, then re-run this script." && exit 1
fi

# 2. Upstream Nix; nix-darwin owns its daemon and configuration.
if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://nixos.org/nix/install | sh -s -- --daemon
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# 3. nix-darwin manages Homebrew packages, but does not install Homebrew.
if [ ! -x /opt/homebrew/bin/brew ]; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 4. Clone the repo if it isn't here yet
if [ ! -d "$REPO/.git" ]; then
  log "Cloning dotfiles..."
  git clone https://github.com/RyanStoffel/dotfiles.git "$REPO"
fi

# 5. Build as the owner using the lockfile, then activate the resulting system.
log "Running first darwin-rebuild switch..."
"$REPO/scripts/rebuild.sh"

log "Done. From now on use: rebuild"
log "Complete the app and security steps documented in README.md, then run ddoctor."
