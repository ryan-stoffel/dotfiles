#!/usr/bin/env python3
"""Dump a Mac's Apple Device Tree (ADT) as "path: prop = value" lines.

The SEP, DART, mailbox and Mesa sensor values in the J514s patch come from
this output. It reads DeviceTree.<board>ap.im4p out of an Apple restore IPSW
over HTTP range requests (no 15+ GB download), or from a local .im4p file.

  python3 -m venv venv && venv/bin/pip install remotezip pyimg4
  venv/bin/python -I adt-dump.py --ipsw URL --board j514s > j514s.adt.txt
  grep -E '^/arm-io/(sep|dart-sep|spi2)' j514s.adt.txt

IPSW URLs: https://api.ipsw.me/v4/device/Mac15,6?type=ipsw. ADT reg values are
relative to /arm-io's ranges (0x210000000 on T6030), so spi2's 0x79108000 is
0x289108000 in the Linux device tree.
"""

import argparse
import struct
import sys

from pyimg4 import IM4P


def fetch(ipsw, board):
    from remotezip import RemoteZip

    with RemoteZip(ipsw) as z:
        name = f"Firmware/all_flash/DeviceTree.{board}ap.im4p"
        return z.read(name)


def fmt(v):
    if v and v[-1:] == b"\0" and v[0] != 0 and all(32 <= c < 127 or c == 0 for c in v[:-1]):
        return repr(v.rstrip(b"\0").split(b"\0"))
    if len(v) % 4 == 0 and len(v) <= 256:
        return " ".join(f"{w:#x}" for w in struct.unpack(f"<{len(v) // 4}I", v))
    return v[:128].hex() + ("..." if len(v) > 128 else "")


# ADT node: u32 property count, u32 child count, properties, then children.
# Property: 32-byte name, u32 size (top bit is a template flag), data padded to 4.
def walk(data, off, parent, out):
    nprops, nchild = struct.unpack_from("<II", data, off)
    off += 8
    props, name = [], None
    for _ in range(nprops):
        pname = data[off:off + 32].split(b"\0")[0].decode()
        size = struct.unpack_from("<I", data, off + 32)[0] & 0x7FFFFFFF
        value = data[off + 36:off + 36 + size]
        off += 36 + ((size + 3) & ~3)
        if pname == "name":
            name = value.rstrip(b"\0").decode()
        props.append((pname, value))
    path = "" if parent == "" and name == "device-tree" else f"{parent}/{name}"
    for pname, value in props:
        out.write(f"{path or '/'}: {pname} = {fmt(value)}\n")
    for _ in range(nchild):
        off = walk(data, off, path, out)
    return off


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--ipsw", help="restore IPSW URL")
    src.add_argument("--im4p", help="local DeviceTree .im4p")
    ap.add_argument("--board", default="j514s", help="board, e.g. j514s, j613")
    a = ap.parse_args()
    raw = fetch(a.ipsw, a.board) if a.ipsw else open(a.im4p, "rb").read()
    payload = IM4P(raw).payload
    payload.decompress()  # no-op when the payload is stored uncompressed
    walk(bytes(payload.data), 0, "", sys.stdout)


if __name__ == "__main__":
    main()
