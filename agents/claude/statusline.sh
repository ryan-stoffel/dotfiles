#!/usr/bin/env bash
# Status line: model · dir branch · context % · cost

input=$(cat)

fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
reset=$'\033[0m'
grey=$(fg 122 132 120)
aqua=$(fg 131 192 146)
blue=$(fg 127 187 179)
fgc=$(fg 211 198 170)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Context color: green < 60, orange < 80, red otherwise
pct_color=$(fg 167 192 128)
[ "$pct" -ge 60 ] && pct_color=$(fg 230 152 117)
[ "$pct" -ge 80 ] && pct_color=$(fg 230 126 128)

branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  b=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || b="${b}*"
  branch=" ${aqua}${b}${reset}"
fi

sep=" ${grey}·${reset} "
printf '%s' "${fgc}${model}${reset}${sep}${blue}$(basename "$cwd")${reset}${branch}${sep}${pct_color}ctx ${pct}%${reset}${sep}${fgc}$(printf '$%.2f' "$cost")${reset}"
