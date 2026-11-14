#!/usr/bin/env python3
"""Build a macOS .icns container from PNG files (no macOS tooling required).

Usage: build-icns.py out.icns 16.png 32.png 64.png 128.png 256.png 512.png 1024.png
"""
import struct
import sys

# OSType -> pixel size of the PNG that belongs in it
TYPES = {
    16: b"icp4",
    32: b"icp5",
    64: b"icp6",
    128: b"ic07",
    256: b"ic08",
    512: b"ic09",
    1024: b"ic10",
}


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2

    out = sys.argv[1]
    entries = []
    for path in sys.argv[2:]:
        size = int(path.rsplit("-", 1)[1].split(".")[0])
        if size not in TYPES:
            continue
        entries.append((TYPES[size], open(path, "rb").read()))

    body = b"".join(t + struct.pack(">I", len(d) + 8) + d for t, d in entries)
    with open(out, "wb") as fh:
        fh.write(b"icns" + struct.pack(">I", len(body) + 8) + body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
