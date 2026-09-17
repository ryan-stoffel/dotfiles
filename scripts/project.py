#!/usr/bin/env python3
"""Discover projects, open workspaces, and run consistent development commands."""
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tomllib

DOTS = Path(os.environ.get("DOTFILES", Path(__file__).resolve().parents[1]))
ROOT = Path(os.environ.get("PROJECT_ROOT", Path.home() / "Developer")).resolve()
TASKS = ("dev", "build", "test", "lint", "check")
MARKERS = (".git", "Package.swift", "Cargo.toml", "package.json", "pyproject.toml", "pom.xml", "flake.nix")


def configuration():
    """Tracked configuration plus untracked machine-local entries.

    This repository is public, so internal project paths belong in the local file.
    """
    merged = tomllib.loads((DOTS / "projects/config.toml").read_text())
    local = DOTS / "projects/config.local.toml"
    if local.exists():
        for table, entries in tomllib.loads(local.read_text()).items():
            merged.setdefault(table, {}).update(entries)
    return merged


def discover(root=ROOT):
    """Stop at repository roots; descend through school/group containers only."""
    found = set()

    def visit(path, depth):
        if path.is_symlink() or depth > 4:
            return
        children = sorted(p for p in path.iterdir() if p.is_dir() and not p.name.startswith("."))
        if path.parent.name == "FA26":
            found.add(path.relative_to(root).as_posix())
        if any((path / m).exists() for m in MARKERS) or any(path.glob("*.xcodeproj")) or (not children and path.name not in {"assignments", "projects"}):
            found.add(path.relative_to(root).as_posix())
            return
        for child in children:
            if child.name not in {"node_modules", "build", "dist", "target", "venv", "__pycache__"}:
                visit(child, depth + 1)

    for group in ("personal", "work", "school"):
        folder = root / group
        if folder.is_dir():
            for child in sorted(folder.iterdir()):
                if child.is_dir() and not child.name.startswith("."):
                    visit(child, 1)
    for name in configuration().get("projects", {}):
        if (root / name).is_dir():
            found.add(name)
    return sorted(found)


def select(query, names, current=False):
    if current and not query:
        cwd = Path.cwd().resolve()
        matches = [n for n in names if cwd == ROOT / n or ROOT / n in cwd.parents]
        if matches:
            return max(matches, key=len)
        raise ValueError("Run inside a project or provide its name.")
    query = configuration().get("aliases", {}).get(query, query)
    if query in names:
        return query
    matches = [n for n in names if query and (Path(n).name.lower() == query.lower())]
    if not matches:
        matches = [n for n in names if not query or query.lower() in n.lower()]
    if len(matches) == 1:
        return matches[0]
    if not matches:
        raise ValueError(f"No project matches {query!r}.")
    if not sys.stdin.isatty():
        raise ValueError("Use an exact project name. Matches: " + ", ".join(matches))
    result = subprocess.run(["fzf", "--prompt=Project > ", "--height=50%", "--reverse"],
                            input="\n".join(matches), text=True, stdout=subprocess.PIPE)
    if result.returncode:
        raise SystemExit(0)
    return result.stdout.strip()


def stack(path):
    for filename, name in (("Cargo.toml", "rust"), ("Package.swift", "swift"),
                           ("pyproject.toml", "python"), ("package.json", "node"), ("pom.xml", "java")):
        if (path / filename).exists():
            return name
    return None


def commands(path, task):
    """Prefer a repository's own task contract; never silently pass missing tasks."""
    for file in sorted(path.iterdir()):
        if file.name.lower() == "justfile" and file.is_file():
            return [["just", "--justfile", str(file), task]]
    kind = stack(path)
    if kind == "node":
        package = json.loads((path / "package.json").read_text())
        scripts = package.get("scripts", {})
        manager = package.get("packageManager", "npm").split("@")[0]
        if manager not in {"npm", "pnpm", "yarn", "bun"}:
            raise ValueError(f"Unsupported package manager: {manager}")
        if task == "check" and task not in scripts:
            checks = [n for n in ("lint", "typecheck", "test") if n in scripts]
            if checks:
                return [[manager, "run", n] for n in checks]
        if task in scripts:
            return [[manager, "run", task]]
    elif kind == "rust":
        mapping = {
            "dev": [["cargo", "run"]], "build": [["cargo", "build", "--workspace"]],
            "test": [["cargo", "test", "--workspace"]],
            "lint": [["cargo", "fmt", "--all", "--", "--check"],
                     ["cargo", "clippy", "--workspace", "--all-targets", "--", "-D", "warnings"]],
        }
        mapping["check"] = mapping["lint"] + mapping["test"]
        return mapping[task]
    elif kind == "python":
        mapping = {"build": [["uv", "build"]], "test": [["uv", "run", "pytest"]],
                   "lint": [["ruff", "check", "."], ["ruff", "format", "--check", "."]]}
        mapping["check"] = mapping["lint"] + mapping["test"]
        if task in mapping:
            return mapping[task]
    elif kind == "swift":
        sources = [str(p.name) for p in (path / "Sources", path / "Tests") if p.is_dir()]
        mapping = {"dev": [["/usr/bin/swift", "run"]], "build": [["/usr/bin/swift", "build"]],
                   "test": [["/usr/bin/swift", "test"]],
                   "lint": [["/usr/bin/swift", "format", "lint", "--strict", "--recursive", "Package.swift", *sources]]}
        mapping["check"] = mapping["lint"] + mapping["test"]
        return mapping[task]
    elif kind == "java":
        mapping = {"build": "package", "test": "test", "check": "verify"}
        if task in mapping:
            return [["./mvnw" if (path / "mvnw").exists() else "mvn", mapping[task]]]
    raise ValueError(f"No {task!r} command for {path.name}. Define it in projects/config.toml or a project Justfile.")


def environment(path, argv):
    if (path / ".envrc").is_file():
        return ["direnv", "exec", str(path), *argv]
    kind = stack(path)
    if kind:
        return ["nix", "develop", "--no-write-lock-file", str(DOTS / "nix-darwin") + "#" + kind, "--command", *argv]
    return argv


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("list")
    op = sub.add_parser("open")
    op.add_argument("query", nargs="?")
    op.add_argument("--mode", choices=["both", "editor", "terminal"], default="both")
    op.add_argument("--dry-run", action="store_true")
    run = sub.add_parser("run")
    run.add_argument("task", choices=TASKS)
    run.add_argument("query", nargs="?")
    run.add_argument("--dry-run", action="store_true")
    setup = sub.add_parser("env", help="Add a direnv file for a project; never overwrite one")
    setup.add_argument("query", nargs="?")
    argsv = sys.argv[1:]
    if not argsv or argsv[0] not in {"open", "list", "run", "env", "-h", "--help"}:
        argsv.insert(0, "open")
    args = parser.parse_args(argsv)
    names = discover()
    if args.action == "list":
        print("\n".join(names))
        return
    name = select(args.query, names, current=args.action in {"run", "env"})
    path = ROOT / name
    settings = configuration().get("projects", {}).get(name, {})
    if args.action == "env":
        kind = stack(path)
        if not kind:
            raise ValueError("No supported runtime detected; add a project-specific .envrc manually.")
        # Do not replace a project's own flake or existing environment policy.
        target = "." if (path / "flake.nix").is_file() else f'$HOME/.dotfiles/nix-darwin#{kind}'
        with (path / ".envrc").open("x") as file:
            file.write(f'# Development environment managed by ~/.dotfiles\nuse flake "{target}"\n')
        print(f"Created {path / '.envrc'}. Review it, then run: direnv allow {shlex.quote(str(path))}")
        return
    if args.action == "run":
        override = settings.get("commands", {}).get(args.task)
        steps = [override] if override else commands(path, args.task)
        for argv in steps:
            if not isinstance(argv, list) or not argv or not all(isinstance(s, str) for s in argv):
                raise ValueError("Commands must be nonempty arrays of strings.")
            cmd = environment(path, argv)
            print(f"{name}: {shlex.join(cmd)}", flush=True)
            if not args.dry_run:
                subprocess.run(cmd, cwd=path, check=True)
        return
    steps = []
    if args.mode in {"both", "editor"}:
        workspace = settings.get("workspace")
        xcode = sorted(path.glob("*.xcworkspace")) or sorted(path.glob("*.xcodeproj"))
        if xcode and not workspace:
            steps.append(["/usr/bin/open", str(xcode[0])])
        else:
            steps.append(["code", "--new-window", str(DOTS / workspace if workspace else path)])
    if args.mode in {"both", "terminal"}:
        steps.append(["open", "-a", "Ghostty", str(path)])
    for argv in steps:
        print(shlex.join(argv), flush=True)
        if not args.dry_run:
            subprocess.run(argv, cwd=path, check=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, FileExistsError, FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"project: {error}", file=sys.stderr)
        sys.exit(1)
