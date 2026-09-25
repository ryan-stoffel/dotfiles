#!/bin/bash
# Links the shared agent instructions and personal skills into each agent's home.
set -eu
src="$HOME/.dotfiles/agents"

link_file() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ] && [ ! -L "$target" ] && ! cmp -s "$target" "$src/AGENTS.md"; then
    echo "link-agents: $target differs from $src/AGENTS.md; merge it there first" >&2
    return 0
  fi
  ln -sfn "$src/AGENTS.md" "$target"
}

link_file "$HOME/.claude/CLAUDE.md"
link_file "$HOME/.codex/AGENTS.md"

for dest in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  mkdir -p "$dest"
  for entry in "$dest"/*; do
    if [ -L "$entry" ] && [ ! -e "$entry" ]; then
      case "$(readlink "$entry")" in "$src"/*) rm "$entry" ;; esac
    fi
  done
  for skill in "$src"/skills/*/; do
    [ -f "$skill/SKILL.md" ] || continue
    name="$(basename "$skill")"
    if [ -e "$dest/$name" ] && [ ! -L "$dest/$name" ]; then
      echo "link-agents: $dest/$name already exists and is not a link; skipped" >&2
      continue
    fi
    ln -sfn "${skill%/}" "$dest/$name"
  done
done
