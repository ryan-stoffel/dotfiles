---
name: upload-media-pr
description: Capture a screenshot or GIF of a change and embed it inline in a GitHub PR or GitLab MR body, so reviewers see the image itself instead of a link. Use when opening or updating a PR/MR that changes anything visible (UI, CLI output, TUI), or when asked to add screenshots, GIFs, or visual validation to a PR.
---

# upload-media-pr

Goal: the PR/MR body shows the actual image or GIF. A link to a local file, an artifact, or a download is a failure.

## 1. Capture

Show the change, not the whole desktop. Crop to the relevant window or region.

- Still image of a web page: `npx playwright screenshot --full-page <url> shot.png`
- Still image of a window/region: `screencapture -x -R <x,y,w,h> shot.png` (or `-w` to pick a window)
- Flow in the browser: use the claude-in-chrome `gif_creator` tool. Its export downloads to `~/Downloads`.
- Flow outside the browser: record with `screencapture -v -V <seconds> clip.mov`, then convert:

  ```sh
  nix shell nixpkgs#ffmpeg -c ffmpeg -i clip.mov \
    -vf "fps=10,scale=900:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" clip.gif
  ```

Keep GIFs under 10 MB. Lower `fps` or `scale` if larger. Before/after pairs beat a single shot when behavior changed.

Open the file with Read and confirm it shows what you claim before uploading.

## 2. Upload

From inside the repo checkout:

```sh
~/.dotfiles/agents/skills/upload-media-pr/upload.sh shot.png "Settings page after fix"
```

It prints one markdown line. Paste it into the body as-is.

- GitHub: commits the file to a `pr-media` branch (created from the default branch on first use) and embeds it by commit SHA, so it never lands in the PR diff and the link never moves.
- GitLab: uses the project uploads API. The returned `/uploads/...` path renders in that project's MRs.

Never use `raw.githubusercontent.com` URLs with tokens or temporary `download_url` values. They expire.

## 3. Embed

Put media under a `## Validation` section at the end of the body, before the harness blurb. One line of caption per image.

- GitHub: `gh pr edit <n> --body-file body.md`
- GitLab: `glab mr update <n> --description "$(cat body.md)"`

## 4. Verify

Fetch the body back (`gh pr view <n> --json body` or `glab mr view <n>`) and confirm each embed starts with `![`. Then open the PR in the browser and confirm the images render. Report failure instead of claiming success if any image is broken.
