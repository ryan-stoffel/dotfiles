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

Uploads are publicly readable at `files.stoffel-thomas-ryan.workers.dev`.
Never upload secrets, credentials, private URLs, private logs, or anything
outside the change. The host serves individual files and has no directory listing.

```bash
~/.dotfiles/agents/skills/upload-media/upload.sh shot.png "Settings page after the fix"
```

The script uploads directly to R2 using Wrangler's Cloudflare login and
`~/.config/pr-media/r2.env`. Node.js/npm must be installed. It verifies the
public URL before printing one Markdown line to paste into the PR. Images print
as embeds; videos print as links, so include a GIF preview with a video.

Files must be under 5,000,000 bytes. Object names include the file's SHA-256 hash:
unchanged files reuse their URL, while changed files get a new URL. If setup is
missing, follow [R2 setup](setup.md). Report upload failures to Ryan rather than
switching hosts or committing media to a repository branch.

The Worker provides public reads while direct R2 public endpoints remain disabled.
Existing Gists and their links remain unchanged. The Parallax domain stays disconnected.

## Embed

Put the lines under a `## Validation` section in the PR body. In Parallax, use
`pull_request_edit` and read back with `pull_request_status`; elsewhere, use
`gh pr edit` and `gh pr view <n> --json body`. Confirm each image renders.
