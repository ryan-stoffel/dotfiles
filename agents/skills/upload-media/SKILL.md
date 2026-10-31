---
name: upload-media
description: Capture a screenshot, GIF, or recording of a change and embed it in a GitHub PR so reviewers see the image itself, not a link. Use when a PR changes anything visible, or when asked to add screenshots, GIFs, or visual validation to a PR.
---

# Upload Media

Goal: the PR body shows the actual image or GIF. A bare link to an image, a
local path, or an artifact is a failure.

## Capture

Show the change, not the whole desktop.

- Web UI in Parallax: the `preview_*` tools. `preview_recording_start` and
  `preview_recording_stop` record a flow.
- iOS Simulator or Android Emulator in Parallax: `device_screenshot`.
- A window or region: `screencapture -x -R <x,y,w,h> shot.png`.
- A recording to GIF (under about 30 seconds):

  ```bash
  nix shell nixpkgs#ffmpeg -c ffmpeg -i clip.mov \
    -vf "fps=10,scale=800:-1:flags=lanczos" -loop 0 clip.gif
  ```

Before and after shots beat one shot when behavior changed. Open each file with
Read and confirm it shows what you claim before uploading.

## Upload

Every upload is public. Never upload secrets, credentials, private URLs, private
logs, or anything outside the change.

```bash
~/.dotfiles/agents/skills/upload-media/upload.sh shot.png "Settings page after the fix"
```

It uploads directly to Cloudflare R2 using Wrangler's Cloudflare login and
`~/.config/pr-media/r2.env`. Node.js/npm must be installed. The script checks
the public URL before printing one Markdown line. Paste that line into the PR
body as is. Images print as `![...](url)` so GitHub renders them. Videos print
as a link, so embed a GIF preview above the video link.

Object names include the file's SHA-256 hash. Re-uploading the same file uses
the same URL; changed files get new URLs. Existing Gist media stays in place
so older PR links keep working.

Files must be under 5,000,000 bytes. If a file is larger, lower the GIF's `fps`
or `scale` and try again. If the upload fails, report the error to Ryan. Never
upload somewhere else without permission, and never commit media to a branch of
the repository. If R2 is not configured, follow [R2 setup](setup.md).

## Embed

Put the lines under a `## Validation` section in the PR body. In Parallax, use
`pull_request_edit` and read back with `pull_request_status`; elsewhere, use
`gh pr edit` and `gh pr view <n> --json body`. Confirm each image renders.
