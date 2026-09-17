#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Open Project
# @raycast.mode compact
# @raycast.packageName Development
# @raycast.argument1 {"type": "text", "placeholder": "Project name (e.g. cadence or school/capstone)"}
# @raycast.description Open a project in VS Code and Ghostty
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
exec python3 "$HOME/.dotfiles/scripts/project.py" open "$1"
