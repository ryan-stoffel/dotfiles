#!/bin/bash
# Uploads a file to Ryan's file host and prints the Markdown that embeds it in a PR.
#   upload.sh <file> "<description>"
# Images print ![description](url). Videos print [description](url), since GitHub
# does not play externally hosted video inline.
set -eu
file="${1:?usage: upload.sh <file> \"<description>\"}"
desc="${2:-$(basename -- "$file")}"
max=4000000 # the Vercel endpoint rejects bodies at or above this size

[ -f "$file" ] || { echo "upload: $file is not a file" >&2; exit 1; }
size=$(wc -c < "$file" | tr -d ' ')
[ "$size" -lt "$max" ] || { echo "upload: $file is $size bytes; the host accepts under $max" >&2; exit 1; }

token="${FILE_HOST_TOKEN:-}"
if [ -z "$token" ] && [ -r "$HOME/.config/files.stoffel.org/upload-token" ]; then
  IFS= read -r token < "$HOME/.config/files.stoffel.org/upload-token"
fi
[ -n "$token" ] || { echo "upload: no FILE_HOST_TOKEN or ~/.config/files.stoffel.org/upload-token" >&2; exit 1; }

url=$(curl --silent --show-error --fail-with-body --request PUT --upload-file "$file" \
  --header "X-Upload-Token: $token" \
  "https://files-stoffel-org.vercel.app/$(basename -- "$file")")

case "$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')" in
  png | jpg | jpeg | gif | webp) printf '![%s](%s)\n' "$desc" "$url" ;;
  *) printf '[%s](%s)\n' "$desc" "$url" ;;
esac
