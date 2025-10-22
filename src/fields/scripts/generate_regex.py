#!/usr/bin/env python3

import yaml
import sys
from pathlib import Path

if __name__ == '__main__':
    print(sys.argv)
    if len(sys.argv) not in (2, 3):
        print("Usage: generate_regex.py <path-to-yaml> [exclude]", file=sys.stderr)
        sys.exit(1)

    filepath = Path(sys.argv[1])
    exclude = sys.argv[2] if len(sys.argv) == 3 else None

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
        
    exclude_list = [e.strip() for e in (exclude.split(",") if exclude else [])]
    

    codes = [
        entry["code"]
        for entry in entries
        if entry.get("status") == "active"
        and entry["code"] not in exclude_list
    ]

    regex = f"^({'|'.join(sorted(codes))})$"
    sys.stdout.write(regex)
