#!/bin/bash
# Moves folders that apps drop into ~ into ~/Developer/scratch; empty ones are removed.
set -u
scratch="$HOME/Developer/scratch"

relocate() {
  local src="$1" dest="$2"
  [ -d "$src" ] && [ ! -L "$src" ] || return 0
  rm -f "$src/.DS_Store"
  if rmdir "$src" 2>/dev/null; then
    return 0
  fi
  mkdir -p "$dest"
  mv "$src" "$dest/$(basename "$src")-$(date +%Y%m%d-%H%M%S)"
}

relocate "$HOME/Claude outputs" "$scratch/claude"
