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

Every upload is public and permanent: the gist is unlisted, but anyone with a
link can open it. Never upload secrets, credentials, private URLs, private logs,
or anything outside the change.

```bash
~/.dotfiles/agents/skills/upload-media/upload.sh shot.png "Settings page after the fix"
```

It commits the file to Ryan's secret media gist with the `gh` login (another
gist's ID in `MEDIA_GIST_ID` or `~/.config/pr-media/gist-id` overrides it), and
prints one Markdown line. It works for any repository. Paste that line into the
PR body as is. Images print as `![...](url)` so GitHub renders them. Videos
print as a link, because GitHub does not play externally hosted video, so embed
a GIF preview above the video link.

Files must be under 5,000,000 bytes. If a file is larger, lower the GIF's `fps`
or `scale` and try again. If the upload fails, report the error to Ryan. Never
upload somewhere else without permission, and never commit media to a branch of
the repository.

## Embed

Put the lines under a `## Validation` section in the PR body. Read the body back
with `gh pr view <n> --json body` and confirm each image line starts with `![`.
