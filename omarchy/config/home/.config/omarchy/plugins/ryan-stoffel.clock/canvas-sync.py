#!/usr/bin/env python3
"""Sync Canvas assignments for the clock panel and send due-date reminders.

Run every few minutes by canvas-sync.timer (systemd user unit).
  feed URL  ~/.config/canvas-calendar/feed-url   (private, never committed)
  output    ~/.cache/canvas-calendar/assignments.json, read by Panel.qml
  state     ~/.local/state/canvas-calendar/sent.json, reminders already sent

Reminders: 9 AM the day before, 9 AM the day of, and 1 hour before when the
assignment has a due time. Canvas's feed has no submission status, so
reminders fire whether or not the work is turned in.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

HOME = Path.home()
FEED_URL_FILE = HOME / ".config/canvas-calendar/feed-url"
CACHE_DIR = HOME / ".cache/canvas-calendar"
ICS_CACHE = CACHE_DIR / "feed.ics"
OUT = CACHE_DIR / "assignments.json"
SENT = HOME / ".local/state/canvas-calendar/sent.json"

FETCH_EVERY = 30 * 60  # seconds between feed downloads
MISSED_GRACE = timedelta(hours=6)  # skip reminders older than this (after sleep)
MAX_FEED_BYTES = 5 * 1024 * 1024


def unfold(text):
    """Join ICS continuation lines (lines starting with a space or tab)."""
    return re.sub(r"\r?\n[ \t]", "", text)


def unescape(value):
    return value.replace("\\n", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\").strip()


def parse_events(ics):
    """Return assignments as dicts: uid, title, course, url, date, due (aware dt or None)."""
    events = []
    for block in unfold(ics).split("BEGIN:VEVENT")[1:]:
        block = block.split("END:VEVENT")[0]
        fields = {}
        for line in block.splitlines():
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            name = key.split(";")[0]
            fields[name] = (key, value)
        if "DTSTART" not in fields or "SUMMARY" not in fields:
            continue
        key, raw = fields["DTSTART"]
        summary = unescape(fields["SUMMARY"][1])
        m = re.match(r"^(.*?)\s*\[([^\]]+)\]$", summary)
        title, section = (m.group(1), m.group(2)) if m else (summary, "")
        cm = re.search(r"([A-Z]{3,4}\d{3,4}[A-Z]?)", section)
        if "VALUE=DATE" in key and "T" not in raw:
            day, due = datetime.strptime(raw, "%Y%m%d").date(), None
        else:
            dt = datetime.strptime(raw.rstrip("Z"), "%Y%m%dT%H%M%S")
            dt = dt.replace(tzinfo=timezone.utc) if raw.endswith("Z") else dt.astimezone()
            due = dt.astimezone()
            day = due.date()
        events.append({
            "uid": fields.get("UID", ("", summary + raw))[1],
            "title": title,
            "course": cm.group(1) if cm else section,
            "url": fields["URL"][1] if "URL" in fields else "",
            "date": day,
            "due": due,
        })
    return events


def reminders(event):
    """(key, when, message) for each reminder of one assignment, in local time."""
    morning = lambda d: datetime.combine(d, datetime.min.time()).replace(hour=9).astimezone()
    due_text = event["due"].strftime("%-I:%M %p") if event["due"] else "today"
    out = [
        ("day-before", morning(event["date"] - timedelta(days=1)), "Due tomorrow"),
        ("day-of", morning(event["date"]), f"Due {due_text}"),
    ]
    if event["due"]:
        out.append(("hour-before", event["due"] - timedelta(hours=1), "Due in 1 hour"))
    return out


def fetch():
    """Download the feed when the cached copy is stale. Keeps the old copy on failure."""
    if ICS_CACHE.exists() and time.time() - ICS_CACHE.stat().st_mtime < FETCH_EVERY:
        return
    url = FEED_URL_FILE.read_text().strip()
    if not url.startswith("https://"):
        sys.exit("canvas-sync: feed URL must be https")
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            data = resp.read(MAX_FEED_BYTES + 1)
    except OSError as e:
        print(f"canvas-sync: fetch failed, using cached feed: {e}", file=sys.stderr)
        return
    if len(data) > MAX_FEED_BYTES or b"BEGIN:VCALENDAR" not in data[:200]:
        print("canvas-sync: feed rejected (too large or not iCalendar)", file=sys.stderr)
        return
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = ICS_CACHE.with_suffix(".tmp")
    tmp.write_bytes(data)
    tmp.replace(ICS_CACHE)


def write_output(events):
    by_day = {}
    for e in sorted(events, key=lambda e: (e["date"], e["due"] or datetime.max.replace(tzinfo=timezone.utc))):
        by_day.setdefault(e["date"].isoformat(), []).append({
            "title": e["title"][:200],
            "course": e["course"][:40],
            "time": e["due"].strftime("%-I:%M %p") if e["due"] else "",
            "url": e["url"] if e["url"].startswith("https://") else "",
        })
    tmp = OUT.with_suffix(".tmp")
    tmp.write_text(json.dumps(by_day))
    tmp.replace(OUT)


def notify(events, now):
    sent = set(json.loads(SENT.read_text())) if SENT.exists() else set()
    for e in events:
        for kind, when, label in reminders(e):
            key = f"{e['uid']}|{kind}|{e['date']}"
            if key in sent or not (now - MISSED_GRACE <= when <= now):
                continue
            subprocess.run(["notify-send", "-a", "Canvas", "-i", "x-office-calendar",
                            f"{label}: {e['title']}", e["course"]], check=False)
            sent.add(key)
    # Forget reminders for assignments more than a week past.
    cutoff = (now.date() - timedelta(days=7)).isoformat()
    sent = {k for k in sent if k.rsplit("|", 1)[-1] >= cutoff}
    SENT.parent.mkdir(parents=True, exist_ok=True)
    SENT.write_text(json.dumps(sorted(sent)))


def main():
    fetch()
    if not ICS_CACHE.exists():
        sys.exit("canvas-sync: no feed downloaded yet")
    events = parse_events(ICS_CACHE.read_text(errors="replace"))
    write_output(events)
    notify(events, datetime.now().astimezone())


def self_test():
    ics = (
        "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:a1\nDTSTART;VALUE=DATE;VALUE=DATE:20261007\n"
        "SUMMARY:Proof Partners 2 [202710.TS.CSCI4150.A]\nURL;VALUE=URI:https://x/cal\n"
        " endar#a1\nEND:VEVENT\nBEGIN:VEVENT\nUID:a2\nDTSTART:20261008T180000Z\n"
        "SUMMARY:Project\\, Proposal [202710.TS.CSCI4230.A]\nEND:VEVENT\nEND:VCALENDAR\n"
    )
    a, b = parse_events(ics)
    assert (a["title"], a["course"], a["date"], a["due"]) == ("Proof Partners 2", "CSCI4150", date(2026, 10, 7), None)
    assert a["url"] == "https://x/calendar#a1"
    assert b["title"] == "Project, Proposal" and b["due"] == datetime(2026, 10, 8, 18, tzinfo=timezone.utc)
    assert [k for k, _, _ in reminders(a)] == ["day-before", "day-of"]
    assert reminders(b)[2][1] == b["due"] - timedelta(hours=1)
    print("ok")


if __name__ == "__main__":
    self_test() if sys.argv[1:] == ["--self-test"] else main()
