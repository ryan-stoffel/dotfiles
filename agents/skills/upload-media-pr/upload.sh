#!/usr/bin/env bash
# Uploads an image or GIF so it renders inline in a PR/MR body, then prints the markdown embed.
# Usage: upload.sh <file> [alt text]   (run inside the repo checkout)
# GitHub: commits the file to a `pr-media` branch and embeds it by commit SHA.
# GitLab: uses the project uploads API, which returns a ready-made embed.
set -euo pipefail

file=${1:?usage: upload.sh <file> [alt text]}
alt=${2:-$(basename "$file")}
[ -f "$file" ] || { echo "upload.sh: no such file: $file" >&2; exit 1; }

remote=$(git remote get-url origin)

case "$remote" in
  *github.com*)
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    branch=pr-media
    if ! gh api "repos/$repo/git/ref/heads/$branch" >/dev/null 2>&1; then
      base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
      sha=$(gh api "repos/$repo/commits/$base" -q .sha)
      gh api "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$sha" >/dev/null
    fi
    path="pr-media/$(date +%Y%m%d-%H%M%S)-$(basename "$file")"
    # Body goes through a file because base64 GIFs exceed the shell argument limit.
    body=$(mktemp)
    trap 'rm -f "$body"' EXIT
    base64 < "$file" | tr -d '\n' \
      | jq -Rs --arg m "pr media: $path" --arg b "$branch" '{message: $m, branch: $b, content: .}' > "$body"
    commit=$(gh api -X PUT "repos/$repo/contents/$path" --input "$body" -q .commit.sha)
    echo "![$alt](https://github.com/$repo/blob/$commit/$path?raw=true)"
    ;;
  *)
    host=$(echo "$remote" | sed -E 's#^(https?://|ssh://)?([^@]+@)?([^:/]+).*#\3#')
    id=$(glab api projects/:id | jq -r .id)
    token=$(glab config get token --host "$host")
    curl -sf --header "PRIVATE-TOKEN: $token" --form "file=@$file" \
      "https://$host/api/v4/projects/$id/uploads" \
      | jq -r --arg alt "$alt" '"![\($alt)](\(.url))"'
    ;;
esac
