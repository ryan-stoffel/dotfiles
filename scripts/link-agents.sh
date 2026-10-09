#!/bin/bash
# Keeps editable agent settings, instructions, and personal skills in dotfiles.
set -eu
src="$HOME/.dotfiles/agents"

link_config() {
  local target="$1" source="$2"
  mkdir -p "$(dirname "$source")"
  if [ ! -e "$source" ] && [ -f "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$source"
  fi
  if [ -e "$source" ]; then
    # App-written configs embed absolute paths; another machine's home would break the app.
    if grep -o '/Users/[^/"]*' "$source" 2>/dev/null | grep -qv "^$HOME\$"; then
      echo "link-agents: $source references another machine's home; skipped" >&2
      return 0
    fi
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "link-agents: $target already exists; skipped" >&2
    elif [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
      return
    else
      mkdir -p "$(dirname "$target")"
      ln -sfn "$source" "$target"
    fi
  fi
}

link_file() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ] && [ ! -L "$target" ] && ! cmp -s "$target" "$src/AGENTS.md"; then
    echo "link-agents: $target differs from $src/AGENTS.md; merge it there first" >&2
    return 0
  fi
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src/AGENTS.md" ]; then
    return
  fi
  ln -sfn "$src/AGENTS.md" "$target"
}

link_file "$HOME/.claude/CLAUDE.md"
link_file "$HOME/.codex/AGENTS.md"
link_file "$HOME/.cursor/rules/shared/RULE.md"

link_config "$HOME/.claude/settings.json" "$src/claude/settings.json"
link_config "$HOME/.claude/settings.local.json" "$src/claude/settings.local.json"
link_config "$HOME/.claude/statusline.sh" "$src/claude/statusline.sh"
link_config "$HOME/.claude/hooks/herdr-agent-state.sh" "$src/claude/hooks/herdr-agent-state.sh"
link_config "$HOME/.codex/config.toml" "$src/codex/config.toml"
link_config "$HOME/.codex/hooks.json" "$src/codex/hooks.json"
link_config "$HOME/.codex/herdr-agent-state.sh" "$src/codex/herdr-agent-state.sh"
link_config "$HOME/.codex/browser/config.toml" "$src/codex/browser/config.toml"
link_config "$HOME/.cursor/cli-config.json" "$src/cursor/cli-config.json"
link_config "$HOME/.cursor/argv.json" "$src/cursor/argv.json"
[ "$(uname)" = Darwin ] &&
  link_config "$HOME/Library/Application Support/Cursor/User/settings.json" "$src/cursor/settings.json"

for dest in "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.cursor/skills"; do
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
