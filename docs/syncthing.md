# Syncthing

Syncthing keeps `~/Downloads` and `~/Documents` in sync between the MacBook and the Mac mini.

## What is managed where

| Piece | Managed by | File |
| --- | --- | --- |
| Syncthing.app | Homebrew cask `syncthing-app` | `nix-darwin/modules/darwin/homebrew.nix` |
| `.stignore` in Downloads and Documents | Home Manager activation | `nix-darwin/modules/home/syncthing.nix` |
| Device pairing, shared folders, versioning | Syncthing GUI | `~/Library/Application Support/Syncthing` (not in repo) |

### Why the cask and not `services.syncthing`

macOS privacy permissions (Files and Folders, Full Disk Access) are tied to the
identity of the binary that asks. A Nix-built Syncthing binary looks like a new
program after every nixpkgs update, so its access to Documents and Downloads
would silently break. The signed `Syncthing.app` from the cask keeps a stable
identity, so permissions survive updates. The tradeoff is that pairing and
folder setup live in the app, not in Nix.

## Ignore patterns

`syncthing.nix` copies (not symlinks) this file to `~/Downloads/.stignore` and
`~/Documents/.stignore` on every rebuild:

```
(?d).DS_Store
(?d)._*
(?d).localized
(?d)Icon?
*.crdownload
*.download
*.part
*.partial
*.icloud
.obsidian/workspace*.json
```

- `(?d)` lets Syncthing delete a directory that only contains these files.
- `*.crdownload`, `*.download`, `*.part`, `*.partial` are in-progress browser downloads (Chrome, Safari, Firefox/Zen).
- `.obsidian/workspace*.json` is rewritten by Obsidian on every click. The School vault lives in `~/Documents/School`, and syncing this file between two open copies produces endless conflicts. Notes and plugin settings still sync.

Edit the list in `syncthing.nix`, not in the `.stignore` files. Rebuilds overwrite them.

## iCloud

Keep iCloud **Desktop & Documents Folders** off on both Macs. If it is on,
iCloud and Syncthing both sync `~/Documents`, which causes conflicts and
trouble with offloaded (cloud-only) files. iCloud Drive itself can stay on.

## Setting up a Mac

1. Build the host. On a fresh machine, follow "Fresh machine" in the README:

   ```sh
   git clone https://github.com/ryan-stoffel/dotfiles.git ~/.dotfiles
   DOTFILES_HOST=macmini ~/.dotfiles/scripts/bootstrap.sh   # or macbook
   ```

   On an existing machine, `git pull --rebase --autostash` then `rebuild`.
   The output should include `syncthing-app` and `Activating syncthingIgnores`.

2. Open Syncthing.app.
   - Allow access to Documents and Downloads when macOS asks.
   - Menu bar icon > enable **Start at login**.
   - Menu bar icon > **Open Dashboard**.

## Pairing the Macs (one time)

1. On the mini: Actions > Show ID. Copy the device ID.
2. On the MacBook: **Add Remote Device**, paste the ID, name it `macmini`, save.
3. On the MacBook: **Add Folder** twice.

   | Label | Folder ID | Path | Versioning |
   | --- | --- | --- | --- |
   | Downloads | `downloads` | `~/Downloads` | Trash Can |
   | Documents | `documents` | `~/Documents` | Staggered |

   On the Sharing tab of each, check `macmini`.

4. On the mini: accept the MacBook as a device, then accept both folders.
   Make sure each path points to the mini's own `~/Downloads` or `~/Documents`,
   not a new folder Syncthing suggests.

Done when both folders show **Up to Date** on both Macs.

Existing files on both sides are merged. If the same file name exists on both
with different contents, Syncthing keeps both and renames one with
`.sync-conflict` in its name.

## Gotchas

- **New files must be tracked by Git before Nix sees them.** A new module fails
  with "is not tracked by Git" until you `git add` it. Staging is enough; a
  commit is not required.
- **`homebrew.onActivation.cleanup = "uninstall"`** removes any Homebrew app not
  listed in the flake. Uncommitted edits to `homebrew.nix` on one Mac will
  uninstall apps on the other once they are committed and pulled. Commit only
  the files you mean to share (`git commit <path> -m ...`), not a whole folder.
- **Office casks are large.** If `brew bundle` fails with
  `curl: (18) Transferred a partial file`, install them one at a time with
  `brew install --cask microsoft-word` (and excel, powerpoint), then `rebuild`.
  A failed bundle stops activation before Home Manager runs.
- **Usernames differ per host.** The MacBook is `ryanstoffel`, the mini is
  `ryan-stoffel`. `syncthing.nix` uses `$HOME`, so it works on both.
