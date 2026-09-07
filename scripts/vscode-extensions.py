#!/usr/bin/env python3
"""Restore the explicitly recorded extension versions; retain bundled dependencies."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--prune", action="store_true", help="also remove extensions absent from the manifest")
args = parser.parse_args()

# Activation runs without Homebrew on PATH, so resolve the launcher explicitly.
code = shutil.which("code") or next(
    (p for p in ("/opt/homebrew/bin/code", "/usr/local/bin/code") if Path(p).is_file()), None
)
if code is None:
    sys.exit("VS Code command line tool not found; skipping extension sync.")

manifest = Path(__file__).resolve().parents[1] / "vscode/extensions.txt"
expected = set(line.strip().lower() for line in manifest.read_text().splitlines() if line.strip())
actual = set(subprocess.check_output([code, "--list-extensions", "--show-versions"], text=True).lower().splitlines())
for extension in sorted(expected - actual):
    subprocess.run([code, "--install-extension", extension, "--force"], check=True)
extras = {e.split("@")[0] for e in actual} - {e.split("@")[0] for e in expected}
for extension in sorted(extras):
    if args.prune:
        subprocess.run([code, "--uninstall-extension", extension], check=True)
    else:
        print(f"Unrecorded extension: {extension} (record it, or use --prune)")
