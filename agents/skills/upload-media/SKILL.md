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

Ryan requires R2 media to remain private. The bucket's custom domain and
`r2.dev` access are disabled. Keep captures local until authenticated sharing is
configured. Do not enable public access or use another host to make a PR embed
work without Ryan's permission.

The R2 uploader is `upload.sh` in this folder. Its public-link mode is disabled
by an empty `R2_PUBLIC_URL` in `~/.config/pr-media/r2.env`, so it stops before
uploading. Private R2 URLs cannot render directly in GitHub PR descriptions.
See [R2 setup](setup.md) for the account configuration.

Existing secret Gists remain unchanged. Secret Gist URLs are unlisted and can
be opened by anyone who has the URL.

## Embed

Put the lines under a `## Validation` section in the PR body. In Parallax, use
`pull_request_edit` and read back with `pull_request_status`; elsewhere, use
`gh pr edit` and `gh pr view <n> --json body`. Confirm each image renders.
