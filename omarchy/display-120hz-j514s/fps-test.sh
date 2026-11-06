#!/bin/bash
# Plays a 120 fps test pattern in mpv for 10 s and prints the display rate mpv
# measures from presentation feedback. About 60 is the stock driver, about 119 is
# this fix with early flip on.
set -euo pipefail

tmp=$(mktemp -d)
mpv --no-config --really-quiet --title=fps-test --vo=gpu-next --video-sync=display-resample \
  --input-ipc-server="$tmp/mpv.sock" 'av://lavfi:testsrc2=size=1280x720:rate=120' </dev/null >/dev/null 2>&1 &
mpv=$!
trap 'kill "$mpv" 2>/dev/null; sleep 1; kill -9 "$mpv" 2>/dev/null; rm -rf "$tmp"' EXIT
sleep 10
timeout 5 python3 -I - "$tmp/mpv.sock" <<'EOF'
import json, socket, sys
s = socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect(sys.argv[1]); f = s.makefile()
for p in ["estimated-display-fps", "vsync-jitter", "frame-drop-count"]:
    s.sendall((json.dumps({"command": ["get_property", p]}) + "\n").encode())
    while True:
        r = json.loads(f.readline())
        if "error" in r:
            print(f"{p}: {r.get('data')}")
            break
EOF
