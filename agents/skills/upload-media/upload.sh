#!/bin/bash
# Uploads PR media to R2 and prints one Markdown embed after checking its public URL.
# Usage: upload.sh <file> "<description>"
set -euo pipefail
file="${1:?usage: upload.sh <file> \"<description>\"}"
desc="${2:-$(basename -- "$file")}"
max=5000000 # keeps GIFs small enough for GitHub's image proxy to load

[ -f "$file" ] || { echo "upload: $file is not a file" >&2; exit 1; }
size=$(wc -c < "$file" | tr -d ' ')
[ "$size" -lt "$max" ] || { echo "upload: $file is $size bytes; keep it under $max" >&2; exit 1; }
file="$(cd "$(dirname -- "$file")" && pwd)/$(basename -- "$file")"

case "$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')" in
  png) mime=image/png ;;
  jpg | jpeg) mime=image/jpeg ;;
  gif) mime=image/gif ;;
  webp) mime=image/webp ;;
  mp4) mime=video/mp4 ;;
  mov) mime=video/quicktime ;;
  webm) mime=video/webm ;;
  *) echo "upload: unsupported media type: ${file##*.}" >&2; exit 1 ;;
esac

config="${PR_MEDIA_CONFIG:-$HOME/.config/pr-media/r2.env}"
[ ! -r "$config" ] || . "$config"
: "${CLOUDFLARE_ACCOUNT_ID:?upload: configure CLOUDFLARE_ACCOUNT_ID in ~/.config/pr-media/r2.env}"
: "${R2_BUCKET:?upload: configure R2_BUCKET in ~/.config/pr-media/r2.env}"
: "${R2_PUBLIC_URL:?upload: configure R2_PUBLIC_URL in ~/.config/pr-media/r2.env}"
[[ "$CLOUDFLARE_ACCOUNT_ID" =~ ^[a-f0-9]{32}$ ]] || { echo "upload: invalid Cloudflare account ID" >&2; exit 1; }
[[ "$R2_BUCKET" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]] || { echo "upload: invalid R2 bucket name" >&2; exit 1; }
R2_PUBLIC_URL="${R2_PUBLIC_URL%/}"
[[ "$R2_PUBLIC_URL" =~ ^https://[A-Za-z0-9.-]+$ ]] || { echo "upload: R2_PUBLIC_URL must be an HTTPS origin" >&2; exit 1; }
export CLOUDFLARE_ACCOUNT_ID

base=$(basename -- "$file" | sed 's/[^A-Za-z0-9._-]/-/g')
name="$(shasum -a 256 "$file" | cut -d ' ' -f1)-$base"
url="$R2_PUBLIC_URL/$name"

# Run outside the caller's project so its Wrangler config and .env files are ignored.
npx --yes wrangler@4.156.0 --cwd "$(dirname -- "$config")" r2 object put "$R2_BUCKET/$name" \
  --remote --file "$file" --content-type "$mime" \
  --cache-control 'public,max-age=31536000,immutable' >&2
curl --fail --silent --show-error --head --output /dev/null \
  --connect-timeout 10 --max-time 30 "$url"

desc=$(printf '%s' "$desc" | tr '\r\n' '  ' | sed 's/\\/\\\\/g; s/\[/\\[/g; s/\]/\\]/g')
case "$mime" in
  image/*) printf '![%s](%s)\n' "$desc" "$url" ;;
  video/*) printf '[%s](%s)\n' "$desc" "$url" ;;
esac
