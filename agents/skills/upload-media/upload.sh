#!/bin/bash
# Uploads a file to Ryan's media gist and prints the Markdown that embeds it in a PR.
#   upload.sh <file> "<description>"
# Images print ![description](url). Videos print [description](url), since GitHub
# does not play externally hosted video inline.
#
# The gist is Ryan's secret media gist, unless MEDIA_GIST_ID or ~/.config/pr-media/gist-id
# names another. Its clone lives in ~/.cache/pr-media/<id>, and a lock beside it keeps
# parallel uploads from racing. Each file is stored as <sha256 prefix>-<name>, so the same bytes are
# pushed once, and its link is pinned to the file's git blob, so it never changes.
set -eu
file="${1:?usage: upload.sh <file> \"<description>\"}"
desc="${2:-$(basename -- "$file")}"
max=5000000 # keeps GIFs small enough for GitHub's image proxy to load

[ -f "$file" ] || { echo "upload: $file is not a file" >&2; exit 1; }
size=$(wc -c < "$file" | tr -d ' ')
[ "$size" -lt "$max" ] || { echo "upload: $file is $size bytes; keep it under $max" >&2; exit 1; }

gist="${MEDIA_GIST_ID:-}"
if [ -z "$gist" ] && [ -r "$HOME/.config/pr-media/gist-id" ]; then
  IFS= read -r gist < "$HOME/.config/pr-media/gist-id"
fi
gist="${gist:-066c6f34ff254c7c239767d21a0df91e}"

repo="$HOME/.cache/pr-media/$gist"
lock="$repo.lock"
mkdir -p "$(dirname "$repo")"
for _ in $(seq 120); do mkdir "$lock" 2>/dev/null && break; sleep 0.5; done
[ -d "$lock" ] || { echo "upload: $lock is held; remove it if no upload is running" >&2; exit 1; }
trap 'rmdir "$lock"' EXIT

helper="credential.https://gist.github.com.helper"
if [ ! -d "$repo/.git" ]; then
  git -c "$helper=" -c "$helper=!gh auth git-credential" clone -q "https://gist.github.com/$gist.git" "$repo"
  git -C "$repo" config "$helper" ""
  git -C "$repo" config --add "$helper" "!gh auth git-credential"
  git -C "$repo" config pr-media.owner "$(gh api "gists/$gist" --jq .owner.login)"
fi
git -C "$repo" pull -q --rebase

# Gists have no folders, and raw links need no escaping with these characters only.
base=$(basename -- "$file" | sed 's/[^A-Za-z0-9._-]/-/g')
name="$(shasum -a 256 "$file" | cut -c1-12)-$base"
if [ ! -e "$repo/$name" ]; then
  cp "$file" "$repo/$name"
  git -C "$repo" add "$name"
  git -C "$repo" commit -q -m "Add $name"
  git -C "$repo" push -q || { git -C "$repo" pull -q --rebase && git -C "$repo" push -q; }
fi

owner=$(git -C "$repo" config pr-media.owner)
url="https://gist.githubusercontent.com/$owner/$gist/raw/$(git -C "$repo" hash-object "$repo/$name")/$name"

case "$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')" in
  png | jpg | jpeg | gif | webp) printf '![%s](%s)\n' "$desc" "$url" ;;
  *) printf '[%s](%s)\n' "$desc" "$url" ;;
esac
