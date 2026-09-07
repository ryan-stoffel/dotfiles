#!/usr/bin/env python3
"""Read-only setup checks: no installs, updates, repairs, or lockfile changes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

DOTS = Path(__file__).resolve().parents[1]
HOME = Path.home()
failures = 0


def report(level, message):
    global failures
    failures += level == "FAIL"
    print(f"{level:4} {message}", flush=True)


def command(argv, timeout=30):
    try:
        return subprocess.run(argv, cwd=DOTS, capture_output=True, text=True, timeout=timeout,
                              env={**os.environ, "GIT_OPTIONAL_LOCKS": "0", "HOMEBREW_NO_AUTO_UPDATE": "1"})
    except (OSError, subprocess.TimeoutExpired) as error:
        return subprocess.CompletedProcess(argv, 1, "", str(error))


def main():
    required = [*DOTS.glob("nix-darwin/**/*.nix"), *DOTS.glob("vscode/*"),
                *DOTS.glob("scripts/*.py"), DOTS / "projects/config.toml", DOTS / "ssh/config"]
    untracked = [str(p.relative_to(DOTS)) for p in required if command(
        ["git", "ls-files", "--error-unmatch", str(p)]).returncode]
    report("FAIL" if untracked else "PASS", "Required files tracked" + (": " + ", ".join(untracked) if untracked else ""))
    result = command(["nix", "eval", "--offline", "--no-write-lock-file", "--option", "eval-cache", "false",
                      str(DOTS / "nix-darwin") + "#darwinConfigurations.macbook.system.drvPath", "--raw"], 120)
    report("PASS" if result.returncode == 0 else "FAIL", "Flake evaluates offline" if not result.returncode else
           "Flake evaluation: " + (result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "failed"))
    for tool in ("nix", "just", "direnv", "node", "uv", "op", "xcodes", "docker", "code", "cmux", "fzf"):
        path = shutil.which(tool)
        report("PASS" if path else "FAIL", f"{tool}: {path or 'missing'}")
    result = command(["/bin/zsh", "-lic", "node -p 'JSON.stringify({version:process.version,path:process.execPath})'"])
    try:
        node = json.loads(result.stdout.strip().splitlines()[-1])
        managed = node["version"].startswith("v22.") and node["path"].startswith("/nix/store/")
        report("PASS" if managed else "FAIL", f"Interactive Node: {node['version']} at {node['path']}")
    except (ValueError, IndexError, KeyError):
        report("FAIL", "Could not identify interactive Node")
    links = {".config/ghostty/config": "ghostty/config", ".config/cmux/cmux.json": "cmux/cmux.json",
             ".tmux.conf": "tmux/tmux.conf", ".local/bin/project": "scripts/project.py",
             ".ssh/config": "ssh/config", ".config/raycast/scripts": "raycast",
             "Library/Application Support/Code/User/settings.json": "vscode/settings.json"}
    for dest, source in links.items():
        p = HOME / dest
        ok = p.is_symlink() and p.exists() and p.resolve() == (DOTS / source).resolve()
        report("PASS" if ok else "FAIL", f"Config link: ~/{dest}")
    socket = HOME / "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    report("PASS" if socket.is_socket() else "WARN", "1Password SSH agent " + ("available" if socket.is_socket() else "needs enabling in Settings > Developer"))
    for host in ("dev", "vm", "github-1password"):
        r = command(["/usr/bin/ssh", "-G", host])
        report("PASS" if r.returncode == 0 and f"hostname {host}\n" not in r.stdout else "FAIL", f"SSH configuration: {host}")
    profile = command(["nix", "profile", "list", "--json"])
    try:
        names = list(json.loads(profile.stdout).get("elements", {}))
        report("WARN" if names else "PASS", "Personal Nix profile: " + (", ".join(names) if names else "empty"))
    except ValueError:
        report("WARN", "Could not inspect personal Nix profile")
    ext = command(["code", "--list-extensions", "--show-versions"])
    expected = set((DOTS / "vscode/extensions.txt").read_text().lower().splitlines())
    actual = set(ext.stdout.lower().splitlines())
    report("PASS" if ext.returncode == 0 and expected == actual else "WARN", "VS Code extension versions match" if expected == actual else "VS Code extension drift; run just extensions")
    fv = command(["/usr/bin/fdesetup", "status"])
    report("PASS" if "FileVault is On" in fv.stdout else "WARN", fv.stdout.strip() or "FileVault status unavailable")
    backup = command(["/usr/bin/tmutil", "destinationinfo"])
    report("PASS" if backup.returncode == 0 and "Mount Point" in backup.stdout else "WARN", "Time Machine destination configured" if backup.returncode == 0 and "Mount Point" in backup.stdout else "Time Machine needs a backup destination (or verify your alternative backup)")
    free = shutil.disk_usage(HOME).free / (1024 ** 3)
    report("WARN" if free < 50 else "PASS", f"Disk free: {free:.1f} GiB")
    print(f"\n{failures} failed checks. Warnings identify manual setup or drift.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
