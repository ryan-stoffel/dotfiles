#!/usr/bin/env python3
"""Read-only dashboard for dotfiles, system, and service health."""
import concurrent.futures
import curses
from pathlib import Path
import socket
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))

from health import GROUPS, TASKS, collect

# Long, uniform groups collapse to a single line while everything passes.
COMPACT = {"tools", "links"}
STATUS = {"ok": 1, "warn": 2, "fail": 3}
NAME_WIDTH = 34


def draw(screen, rows, offset, footer, title):
    screen.erase()
    height, width = screen.getmaxyx()

    def put(y, x, text, attr=0):
        if 0 <= y < height and x < width:
            try:
                screen.addnstr(y, x, text, max(0, width - x - 1), attr)
            except curses.error:
                pass

    put(0, 1, "dotfiles health", curses.A_BOLD)
    put(0, max(16, width - len(title) - 1), title, curses.A_DIM)
    body = max(1, height - 3)
    for index, (text, kind) in enumerate(rows[offset:offset + body]):
        put(index + 2, 0, text, attribute(kind))
    put(height - 1, 1, footer, curses.A_DIM)
    screen.noutrefresh()
    curses.doupdate()


def build(results, expand):
    """Rows as (text, kind); kind is mapped to a curses attribute at draw time."""
    rows = []
    for group in GROUPS:
        checks = results.get(group)
        if checks is None:
            rows.append((f"  {group.upper()}", "pending"))
            rows.append(("      checking...", "pending"))
            rows.append(("", "blank"))
            continue
        if group in COMPACT and not expand and all(c.status == "ok" for c in checks):
            rows.append((f"  {group.upper():<12}{len(checks)} ok", "ok"))
            rows.append(("", "blank"))
            continue
        rows.append((f"  {group.upper()}", "head"))
        for check in checks:
            label = check.name if len(check.name) <= NAME_WIDTH else check.name[:NAME_WIDTH - 1] + "-"
            rows.append((f"    {check.status:<6}{label:<{NAME_WIDTH}}{check.detail}".rstrip(), check.status))
            if check.fix and check.status != "ok":
                rows.append((f"    {'':<6}{'':<{NAME_WIDTH}}run: {check.fix}", "fix"))
        rows.append(("", "blank"))
    return rows


def attribute(kind):
    if kind in STATUS:
        return curses.color_pair(STATUS[kind])
    return {"head": curses.A_BOLD, "pending": curses.A_DIM, "fix": curses.A_DIM}.get(kind, 0)


def summarise(results, pending):
    checks = [c for group in results.values() for c in group]
    failed = sum(c.status == "fail" for c in checks)
    warned = sum(c.status == "warn" for c in checks)
    if pending:
        state = f"checking {len(pending)} group(s)"
    elif failed or warned:
        state = f"{failed} failed, {warned} warnings"
    else:
        state = "all checks passing"
    return f"{state}   r refresh   a all   j/k scroll   q quit"


def loop(screen):
    curses.curs_set(0)
    if curses.has_colors():
        curses.use_default_colors()
        for pair, colour in ((1, curses.COLOR_GREEN), (2, curses.COLOR_YELLOW), (3, curses.COLOR_RED)):
            curses.init_pair(pair, colour, -1)
    screen.timeout(150)
    host = socket.gethostname().split(".")[0]

    results, offset, expand = {}, 0, False
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=len(TASKS))
    pending = {pool.submit(collect, task): task.__name__ for task in TASKS}
    stamp = time.strftime("%H:%M:%S")

    while True:
        for future in [f for f in pending if f.done()]:
            results[pending.pop(future)] = future.result()
            if not pending:
                stamp = time.strftime("%H:%M:%S")

        rows = build(results, expand)
        height = max(1, screen.getmaxyx()[0] - 3)
        offset = max(0, min(offset, max(0, len(rows) - height)))
        draw(screen, rows, offset, summarise(results, pending), f"{host}  {stamp}")

        key = screen.getch()
        if key in (ord("q"), ord("Q"), 27):
            break
        if key in (ord("j"), curses.KEY_DOWN):
            offset += 1
        elif key in (ord("k"), curses.KEY_UP):
            offset -= 1
        elif key in (curses.KEY_NPAGE, ord(" ")):
            offset += height
        elif key == curses.KEY_PPAGE:
            offset -= height
        elif key == ord("g"):
            offset = 0
        elif key == ord("G"):
            offset = len(rows)
        elif key in (ord("a"), ord("A")):
            expand = not expand
        elif key in (ord("r"), ord("R")) and not pending:
            results, offset = {}, 0
            pending = {pool.submit(collect, task): task.__name__ for task in TASKS}
        elif key == curses.KEY_RESIZE:
            screen.erase()
    pool.shutdown(wait=False)


if __name__ == "__main__":
    try:
        curses.wrapper(loop)
    except KeyboardInterrupt:
        pass
