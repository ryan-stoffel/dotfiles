# ~/.dotfiles task runner — run `just` to list commands.
set shell := ["zsh", "-cu"]

flake := env_var('HOME') / ".dotfiles/nix-darwin"
host  := "macbook"

# List available commands
default:
    @just --list

# Rebuild and switch the system + home config
rebuild:
    "{{justfile_directory()}}/scripts/rebuild.sh"

# Build without switching (validate the config)
build:
    darwin-rebuild build --flake "{{flake}}#{{host}}"

# Update Nix inputs explicitly (review the lock diff, then just build)
update:
    nix flake update --flake "{{flake}}"

# Format all nix files
fmt:
    nixpkgs-fmt "{{flake}}"

# Garbage-collect generations older than 14 days
gc:
    sudo nix-collect-garbage --delete-older-than 14d
    nix-collect-garbage --delete-older-than 14d

# Inspect the workstation without installing, updating, or repairing anything
doctor:
    @python3 "{{justfile_directory()}}/scripts/doctor.py"

# Run syntax checks and focused workflow tests without switching the system
check:
    python3 -B -m unittest discover -s "{{justfile_directory()}}/tests" -v
    git -C "{{justfile_directory()}}" diff --check

# Explicit Homebrew maintenance, independent of configuration rebuilds
upgrade-apps:
    brew update
    brew upgrade

# Restore the reviewed VS Code extension set and versions
extensions:
    python3 "{{justfile_directory()}}/scripts/vscode-extensions.py" --prune

# Record extension versions after intentionally updating them in VS Code
record-extensions:
    code --list-extensions --show-versions > "{{justfile_directory()}}/vscode/extensions.txt"

# Scan the repo for leaked secrets
scan:
    gitleaks git "{{justfile_directory()}}" --redact --gitleaks-ignore-path "{{justfile_directory()}}/.gitleaksignore"
    gitleaks dir "{{justfile_directory()}}" --redact

# Provision a fresh machine from scratch
bootstrap:
    "{{justfile_directory()}}/scripts/bootstrap.sh"
