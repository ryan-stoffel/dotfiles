#!/usr/bin/env python3
"""Read-only workstation checks shared by the doctor CLI and the dashboard."""
import concurrent.futures
import dataclasses
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

DOTS = Path(__file__).resolve().parents[1]
HOME = Path.home()
HOST = "macbook"
LEVELS = {"ok": "PASS", "warn": "WARN", "fail": "FAIL"}
# Rendered in this order; each group is produced by exactly one task.
GROUPS = ("system", "git", "services", "tools", "links", "layout", "ssh", "editor", "security")


@dataclasses.dataclass(frozen=True)
class Check:
    group: str
    name: str
    status: str
    detail: str = ""
    fix: str = ""

    @property
    def level(self):
        return LEVELS[self.status]

    @property
    def line(self):
        return f"{self.name}: {self.detail}" if self.detail else self.name


def command(argv, timeout=30):
    try:
        # Probes get no stdin and their own session: an interactive login shell would
        # otherwise open /dev/tty and reset the terminal modes the dashboard relies on.
        return subprocess.run(argv, cwd=DOTS, capture_output=True, text=True, timeout=timeout,
                              stdin=subprocess.DEVNULL, start_new_session=True,
                              env={**os.environ, "GIT_OPTIONAL_LOCKS": "0", "HOMEBREW_NO_AUTO_UPDATE": "1"})
    except (OSError, subprocess.TimeoutExpired) as error:
        return subprocess.CompletedProcess(argv, 1, "", str(error))


def short(store_path):
    """The store hash alone identifies a generation without filling the row."""
    return Path(store_path).name.split("-")[0][:8]


def system():
    required = [
        *DOTS.glob("nix-darwin/**/*.nix"),
        *DOTS.glob("vscode/*"),
        DOTS / "ghostty/config",
        *DOTS.glob("raycast/*"),
        *DOTS.glob("scripts/*.py"),
        *DOTS.glob("tests/*.py"),
        DOTS / "projects/config.toml",
        DOTS / "ssh/config",
    ]
    listed = {p for p in command(["git", "ls-files", "-z"]).stdout.split("\0") if p}
    missing = sorted(p.relative_to(DOTS).as_posix() for p in required
                     if p.relative_to(DOTS).as_posix() not in listed)
    yield Check("system", "Required files tracked", "fail" if missing else "ok",
                ", ".join(missing), "git add " + " ".join(missing) if missing else "")

    flake = f"{DOTS / 'nix-darwin'}#darwinConfigurations.{HOST}.system.outPath"
    built = command(["nix", "eval", "--offline", "--no-write-lock-file", "--option", "eval-cache", "false",
                     "--raw", flake], 180)
    if built.returncode:
        tail = built.stderr.strip().splitlines()
        yield Check("system", "Flake evaluation", "fail", tail[-1] if tail else "failed", "dbuild")
        return
    yield Check("system", "Flake evaluates offline", "ok")
    current = Path("/run/current-system").resolve()
    target = Path(built.stdout.strip())
    if current == target:
        yield Check("system", "System matches the flake", "ok", short(target))
    else:
        yield Check("system", "Rebuild pending", "warn", f"{short(current)} -> {short(target)}", "rebuild")


def git():
    dirty = [l for l in command(["git", "status", "--porcelain"]).stdout.splitlines() if l.strip()]
    yield Check("git", "Working tree", "ok" if not dirty else "warn",
                "clean" if not dirty else f"{len(dirty)} uncommitted change(s)",
                "" if not dirty else "git status")

    counts = command(["git", "rev-list", "--left-right", "--count", "@{u}...HEAD"])
    fields = counts.stdout.split()
    if counts.returncode or len(fields) != 2:
        yield Check("git", "Branch tracking", "warn", "no upstream configured",
                    "git push -u origin $(git branch --show-current)")
    else:
        behind, ahead = int(fields[0]), int(fields[1])
        state = ", ".join(filter(None, [f"{ahead} to push" if ahead else "",
                                        f"{behind} to pull" if behind else ""])) or "in sync"
        yield Check("git", "Branch vs origin", "ok" if not (ahead or behind) else "warn", state,
                    "git push" if ahead else ("git pull" if behind else ""))

    head = DOTS / ".git/FETCH_HEAD"
    age = (time.time() - head.stat().st_mtime) / 3600 if head.exists() else None
    yield Check("git", "Remote state", "ok" if age is not None and age < 24 else "warn",
                "never fetched" if age is None else
                (f"fetched {age:.0f}h ago" if age >= 1 else "fetched under an hour ago"),
                "" if age is not None and age < 24 else "git fetch")


def services():
    docker = command(["docker", "info", "--format", "{{.ServerVersion}}"], 15)
    running = docker.returncode == 0 and docker.stdout.strip()
    yield Check("services", "docker", "ok" if running else "warn",
                f"engine {docker.stdout.strip()}" if running else "daemon not running",
                "" if running else "open -a Docker")


def tool_path(name):
    path = shutil.which(name)
    if path:
        return path
    if name == "ghostty":
        bundled = Path("/Applications/Ghostty.app/Contents/MacOS/ghostty")
        if bundled.is_file():
            return str(bundled)
    return None


def tools():
    for tool in ("nix", "direnv", "node", "uv", "op", "xcodes", "docker", "code", "ghostty", "fzf"):
        path = tool_path(tool) if tool == "ghostty" else shutil.which(tool)
        yield Check("tools", tool, "ok" if path else "fail", path or "missing", "" if path else "rebuild")
    probe = command(["/bin/zsh", "-lic", "node -p 'JSON.stringify({version:process.version,path:process.execPath})'"])
    try:
        node = json.loads(probe.stdout.strip().splitlines()[-1])
        managed = node["version"].startswith("v22.") and node["path"].startswith("/nix/store/")
        yield Check("tools", "Interactive Node", "ok" if managed else "fail",
                    f"{node['version']} at {node['path']}", "" if managed else "rebuild")
    except (ValueError, IndexError, KeyError):
        yield Check("tools", "Interactive Node", "fail", "could not identify", "rebuild")


def links():
    managed = {".config/ghostty/config": "ghostty/config", ".local/bin/project": "scripts/project.py",
               ".ssh/config": "ssh/config", ".config/raycast/scripts": "raycast",
               "Library/Application Support/Code/User/settings.json": "vscode/settings.json",
               ".claude/CLAUDE.md": "agents/AGENTS.md", ".codex/AGENTS.md": "agents/AGENTS.md"}
    for dest, source in managed.items():
        path = HOME / dest
        ok = path.is_symlink() and path.exists() and path.resolve() == (DOTS / source).resolve()
        yield Check("links", f"~/{dest}", "ok" if ok else "fail", "", "" if ok else "rebuild")


LAYOUT = {
    "": {"Applications", "Desktop", "Developer", "Documents", "Downloads", "Library", "Movies", "Music",
         "Pictures", "Public"},
    "Documents": {"Career", "Personal", "School", "Work"},
    "Downloads": {"Code", "Documents", "Images", "Random", "Videos"},
}


def layout():
    for folder, allowed in LAYOUT.items():
        root = HOME / folder
        name = f"~/{folder}" if folder else "~"
        try:
            extra = sorted(p.name for p in root.iterdir() if not p.name.startswith(".") and p.name not in allowed)
        except OSError as error:
            yield Check("layout", name, "warn", str(error))
            continue
        yield Check("layout", name, "warn" if extra else "ok", ", ".join(extra) or "clean",
                    "move into ~/Developer or delete" if extra else "")


def ssh():
    socket = HOME / "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    yield Check("ssh", "1Password agent", "ok" if socket.is_socket() else "warn",
                "available" if socket.is_socket() else "not enabled",
                "" if socket.is_socket() else "1Password > Settings > Developer")
    for host in ("dev", "vm", "github-1password"):
        result = command(["/usr/bin/ssh", "-G", host])
        resolved = result.returncode == 0 and f"hostname {host}\n" not in result.stdout
        yield Check("ssh", host, "ok" if resolved else "fail", "" if resolved else "no matching Host block",
                    "" if resolved else "check ~/.ssh/config.local")


def editor():
    result = command(["code", "--list-extensions", "--show-versions"])
    expected = set((DOTS / "vscode/extensions.txt").read_text().lower().split())
    actual = set(result.stdout.lower().split())
    if result.returncode:
        yield Check("editor", "VS Code extensions", "warn", "code command unavailable", "")
    elif expected == actual:
        yield Check("editor", "VS Code extensions", "ok", f"{len(expected)} pinned")
    else:
        drift = len(expected ^ actual)
        yield Check("editor", "VS Code extensions", "warn", f"{drift} differ from the manifest", "dext")


def security():
    profile = command(["nix", "profile", "list", "--json"])
    try:
        names = list(json.loads(profile.stdout).get("elements", {}))
        yield Check("security", "Personal Nix profile", "warn" if names else "ok",
                    ", ".join(names) if names else "empty",
                    "nix profile remove " + " ".join(names) if names else "")
    except ValueError:
        yield Check("security", "Personal Nix profile", "warn", "could not inspect", "")
    vault = command(["/usr/bin/fdesetup", "status"]).stdout.strip()
    yield Check("security", "FileVault", "ok" if "FileVault is On" in vault else "warn",
                vault.rstrip(".") or "status unavailable",
                "" if "FileVault is On" in vault else "System Settings > Privacy & Security")
    free = shutil.disk_usage(HOME).free / (1024 ** 3)
    yield Check("security", "Disk free", "warn" if free < 50 else "ok", f"{free:.1f} GiB")


TASKS = (system, git, services, tools, links, layout, ssh, editor, security)


def collect(task):
    """Never let one failing probe take down the whole report."""
    try:
        return list(task())
    except Exception as error:
        return [Check(task.__name__, f"{task.__name__} checks", "fail", str(error))]


def run():
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(TASKS)) as pool:
        return [check for group in pool.map(collect, TASKS) for check in group]
