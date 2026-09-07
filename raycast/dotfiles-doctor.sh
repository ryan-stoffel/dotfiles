#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Check Development Setup
# @raycast.mode fullOutput
# @raycast.packageName Development
# @raycast.description Read-only checks for dotfiles, tools, and system setup
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
exec python3 "$HOME/.dotfiles/scripts/doctor.py"
