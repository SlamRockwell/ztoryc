#!/usr/bin/env python3
"""Read KEY=value assignments from ci-scripts/thirdparty_versions.sh (comments / blanks skipped)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

_SH = Path(__file__).resolve().parent / "thirdparty_versions.sh"


def load() -> dict[str, str]:
    out: dict[str, str] = {}
    text = _SH.read_text(encoding="utf-8")
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        if re.match(r"^[A-Z][A-Z0-9_]*$", key):
            out[key] = val
    return out


def main() -> None:
    cfg = load()
    if len(sys.argv) < 2:
        print("usage: read_thirdparty_version.py KEY", file=sys.stderr)
        sys.exit(2)
    key = sys.argv[1]
    if key not in cfg:
        print(f"unknown key: {key}", file=sys.stderr)
        sys.exit(1)
    print(cfg[key])


if __name__ == "__main__":
    main()
