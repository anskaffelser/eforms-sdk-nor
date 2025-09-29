#!/usr/bin/env python3

import yaml
import sys
from pathlib import Path

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: generate_regex.py <path-to-yaml>", file=sys.stderr)
        sys.exit(1)
    filepath = Path(sys.argv[1])

    if not filepath.is_file():
        print(f"Error: File '{filepath} not found.", file=sys.stderr)
        sys.exit(1)

    with open(filepath, encoding='utf-8', mode='r') as f:
        data = yaml.safe_load(f)

    stem = filepath.stem

    entries = data.get(stem)
    if not isinstance(entries, list):
        print(f"Error: Top-level key '{stem}' not found or not a list.",
              file=sys.stderr)
        sys.exit(1)

    codes = [
        entry["code"]
        for entry in entries
        if entry.get("status") == "active"
    ]

    regex = f"^({'|'.join(sorted(codes))})$"
    sys.stdout.write(regex)
