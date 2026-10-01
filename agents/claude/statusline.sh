#!/usr/bin/env bash

input=$(cat)

fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
reset=$'\033[0m'

green=$(fg 167 192 128)
aqua=$(fg 131 192 146)
blue=$(fg 127 187 179)
yellow=$(fg 219 188 127)
orange=$(fg 230 152 117)
red=$(fg 230 126 128)
grey=$(fg 122 132 120)
grey1=$(fg 133 146 137)
fgc=$(fg 211 198 170)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

dir=$(basename "$cwd")

branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  b=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  dirty=""
  if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null; then
    dirty="*"
  fi
  branch=" ${grey}on${reset} ${aqua}${b}${dirty}${reset}"
fi

bar_color=$green
if [ "$pct" -ge 80 ]; then
  bar_color=$red
elif [ "$pct" -ge 60 ]; then
  bar_color=$orange
elif [ "$pct" -ge 40 ]; then
  bar_color=$yellow
fi

cells=10
filled=$((pct * cells / 100))
[ "$filled" -gt "$cells" ] && filled=$cells
empty=$((cells - filled))
bar=$(printf '%*s' "$filled" '' | tr ' ' '█')
pad=$(printf '%*s' "$empty" '' | tr ' ' '░')

sep=" ${grey}·${reset} "

printf '%s' \
  "${aqua}●${reset} ${fgc}${model}${reset}${sep}${blue}${dir}${reset}${branch}${sep}${bar_color}${bar}${grey}${pad}${reset} ${bar_color}${pct}%${reset}${sep}${yellow}\$${cost}${reset}"
