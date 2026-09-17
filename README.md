# dotfiles

This Mac is managed with nix-darwin and Home Manager. GUI apps come from Homebrew;
command-line tools and development environments come from the pinned Nix flake.
Editable configurations are linked live from this repository.

## Everyday commands

Zsh aliases (defined in `nix-darwin/modules/home/shell.nix`):

```sh
rebuild                       # apply system + home configuration (administrator)
dbuild                        # build without activation
dup                           # explicitly update flake inputs
dbrew                         # explicitly update Homebrew packages
dext                          # restore recorded VS Code versions; remove extras
dscan                         # redacted history and working-tree secret scans
dgc                           # remove Nix generations older than 14 days
ddoctor                       # read-only workstation checks
dtui                          # live health dashboard (read-only)
dcheck                        # focused workflow tests and whitespace checks
dbootstrap                    # provision a fresh machine from this repo
```

Rebuilds do not upgrade Homebrew packages. Removing a cask from the list uninstalls
it without `zap` deletion of its associated application data. Nix input versions
remain pinned until `dup`; VS Code extensions remain at the versions in
`vscode/extensions.txt` until deliberately updated and recorded.

New files must be visible to Git before Nix can import them. Review and add new
files before building. Local configuration edits through symlinks take effect
immediately; a Nix rollback alone does not revert those edits. Use Git to restore
configuration content when necessary.

## One project launcher

```sh
p list
p cadence                     # VS Code + Ghostty; aliases live in projects/config.toml
p school/capstone             # opens the multi-root VS Code workspace
p forge --mode terminal
p run test cadence
p run check ember-sync-poc --dry-run
p run check                   # select the repository containing the current directory
```

Discovery walks personal/work/school containers, recognizes nested repositories,
and stops before traversing their dependency/build trees. Hidden directories are
excluded. Ambiguous names require selection in a terminal or an exact path in
Raycast. Named shell aliases are generated from the shared registry.

`projects/config.toml` holds aliases, workspace choices, and explicit argument
arrays for task overrides. A repository's Justfile takes precedence over inferred
commands when `just` is available on PATH. Otherwise `dev`, `build`, `test`, `lint`,
and `check` dispatch to the project's stack. Node checks run its declared
lint/typecheck/test scripts in that order (or its explicit check script).
Unsupported tasks fail with an explanation; they are not treated as passing tests.
Add a real project command when needed. Python `dev` requires an explicit entry
point; ember-bench currently shows its CLI help. Xcode-only projects open in Xcode
and need project-specific task definitions.

No application test, build, or dev server is started just by opening a project.

## Development environments

Home Manager enables direnv + nix-direnv and its Zsh hook. The flake provides
`node` (Node 22), `python` (Python 3.12, uv, Ruff), `rust`, `java`, and `swift`
shells. Project tasks enter the appropriate pinned shell automatically, or use
an existing `.envrc` through `direnv exec`. For pnpm/yarn/bun projects, supply that
package manager in the project's own environment; it is not installed implicitly.

For automatic environments in interactive shells and VS Code:

```sh
p env files-stoffel            # creates .envrc only if absent
# Read the generated file, then approve this project's environment:
direnv allow ~/Developer/personal/files.stoffel.org
```

The generated `.envrc` references this machine's dotfiles flake. If the project
already has its own flake, it references that instead. This is a local workstation
convenience; a team project should commit a self-contained dev shell and lockfile.
The launcher never auto-approves an existing `.envrc`.

Swift uses the selected Apple Xcode toolchain. `xcodes installed` lists versions;
`xcodes select` selects one. Use a project `.xcode-version` when maintaining multiple
SDK versions. The existing App Store Xcode remains declared; xcodes is available
for deliberate additional versions, not an automatic second installation.

Java, Maven, and PostgreSQL clients are declared in Nix; PostgreSQL is not
automatically started as a server.

## Raycast

Scripts live in `raycast/`, linked at `~/.config/raycast/scripts`. In Raycast
Settings > Extensions > Script Commands, add that directory once. It provides
**Open Project** and **Check Development Setup**. Assign hotkeys in Raycast.
Scripts set a deterministic PATH because GUI processes do not read interactive
shell setup. Raycast preferences and account state remain application-owned.

## Authentication, services, and backups

1Password CLI and its VS Code extension are installed. In 1Password Settings >
Developer, enable **Integrate with 1Password CLI** and **Use the SSH agent**.
Unlock/sign in to the app, then `op whoami` can verify CLI integration.

`ssh/config` preserves existing local-key hosts and adds `github-1password` as
an opt-in host for the agent. `~/.ssh/config.local` can override it. Test the alias
with `ssh -T github-1password` after placing the desired key in 1Password; existing
Git remotes and private key files are not changed. Commit signing is not forced
without selecting an actual signing key. A 1Password agent socket alone is not
proof that the correct key is present.

Secrets can be supplied at runtime with `op run`, e.g. using an environment file
containing `op://` references. Do not commit plaintext credentials. `sops`, `age`,
and `.sops.yaml` remain available for manual encryption, but this configuration
does not use sops-nix or decrypt secrets at activation.

In System Settings > Privacy & Security > FileVault, enable FileVault and choose
an account/recovery-key recovery method. Keep recovery material off this Mac.
Configure Time Machine with your chosen backup disk/network destination and test
restoring a file. Dotfiles Git history does not back up uncommitted projects, keys,
databases, or application state. `ddoctor` reports unfinished setup steps.

## Fresh machine

```sh
git clone https://github.com/RyanStoffel/dotfiles.git ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh
```

Bootstrap installs command-line tools (rerun after Apple's installer completes),
upstream Nix, and Homebrew, then builds the locked configuration as your normal
user and activates its concrete store output with sudo. This avoids root Git
repository-ownership failures without weakening Git trust settings.
Sign into the App Store for Xcode/Windows App installation. Restore local SSH keys
or configure 1Password, register Raycast scripts, and open Docker Desktop to
complete its setup and start its engine. macOS may request administrator
authentication and application permissions.

## Layout

- `nix-darwin/`: system and Home Manager modules, pinned inputs, dev shells.
- `scripts/`: bootstrap, shared project launcher, health checks, dashboard, extension synchronizer.
- `projects/`: launcher registry.
- `raycast/`: launcher and diagnostic Script Commands.
- `ssh/`: connection settings, with no private keys.
- `vscode/`, `zed/`, `ghostty/`: editable app settings.
- `zellij/`: terminal multiplexer layouts.
- `docs/git-workflow.md`: worktree organization and GitButler tradeoffs.

The terminal background remains true black. Application settings can write into
this repo through the live links; review those changes before committing.
