#!/usr/bin/env bash
# Compatibility entry point for the shared project launcher.
set -euo pipefail
exec "$HOME/.local/bin/project" open --mode tmux "$@"
