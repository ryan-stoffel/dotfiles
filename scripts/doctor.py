#!/usr/bin/env python3
"""Read-only setup checks: no installs, updates, repairs, or lockfile changes."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from health import GROUPS, run


def main():
    checks = sorted(run(), key=lambda c: GROUPS.index(c.group))
    for check in checks:
        print(f"{check.level:4} {check.line}", flush=True)
    failures = sum(c.status == "fail" for c in checks)
    print(f"\n{failures} failed checks. Warnings identify manual setup or drift.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
