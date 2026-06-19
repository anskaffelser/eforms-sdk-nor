#!/usr/bin/env python3
"""
Generate subset codelist YAML files from a master YAML file.

The script reads a TOML manifest that defines:
- paths.master_file
- paths.output_dir
- subsets.<name>.file
- subsets.<name>.keys

Usage:
    uv run bin/distribute-codelist-subsets.py path/to/distribution-manifest.toml
"""

from __future__ import annotations

import argparse
import sys
import tomllib
from pathlib import Path
from typing import Any

from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate subset codelist YAML files from a TOML manifest."
    )

    parser.add_argument(
        "manifest",
        type=Path,
        help="Path to TOML manifest, for example codelists/_manifest.toml",
    )

    return parser.parse_args()


def load_toml(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as file:
            return tomllib.load(file)
    except FileNotFoundError:
        raise SystemExit(f"ERROR: Manifest file not found: {path}")
    except tomllib.TOMLDecodeError as error:
        raise SystemExit(f"ERROR: Invalid TOML in {path}: {error}") from error


def load_yaml(path: Path, yaml: YAML) -> Any:
    try:
        with path.open("r", encoding="utf-8") as file:
            return yaml.load(file)
    except FileNotFoundError:
        raise SystemExit(f"ERROR: Master YAML file not found: {path}")


def write_yaml(path: Path, data: Any, yaml: YAML) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as file:
        yaml.dump(data, file)


def require_mapping(value: Any, name: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise SystemExit(f"ERROR: Expected '{name}' to be a TOML table.")
    return value


def require_string(value: Any, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"ERROR: Expected '{name}' to be a non-empty string.")
    return value


def require_list(value: Any, name: str) -> list[Any]:
    if not isinstance(value, list):
        raise SystemExit(f"ERROR: Expected '{name}' to be a list.")
    return value


def require_bool(value: Any, name: str) -> bool:
    if not isinstance(value, bool):
        raise SystemExit(f"ERROR: Expected '{name}' to be a boolean.")
    return value


def validate_complete_subset(
    *,
    validation: dict[str, Any],
    subsets: dict[str, Any],
    master_key_by_string: dict[str, Any],
) -> None:
    require_complete_subset = require_bool(
        validation.get("require_complete_subset", False),
        "validation.require_complete_subset",
    )

    if not require_complete_subset:
        return

    complete_subset_name = require_string(
        validation.get("complete_subset"),
        "validation.complete_subset",
    )

    if complete_subset_name not in subsets:
        raise SystemExit(
            f"ERROR: validation.complete_subset points to missing subset: "
            f"{complete_subset_name}"
        )

    complete_subset = require_mapping(
        subsets[complete_subset_name],
        f"subsets.{complete_subset_name}",
    )

    raw_keys = require_list(
        complete_subset.get("keys"),
        f"subsets.{complete_subset_name}.keys",
    )

    subset_keys = {str(key) for key in raw_keys}
    master_keys = set(master_key_by_string.keys())

    missing_keys = sorted(master_keys - subset_keys)
    extra_keys = sorted(subset_keys - master_keys)

    if missing_keys:
        raise SystemExit(
            f"ERROR: subsets.{complete_subset_name} does not cover all master keys. "
            f"Missing keys: {missing_keys}"
        )

    if extra_keys:
        raise SystemExit(
            f"ERROR: subsets.{complete_subset_name} contains keys not in master. "
            f"Extra keys: {extra_keys}"
        )

def main() -> int:
    args = parse_args()

    manifest_path = args.manifest.resolve()
    manifest_dir = manifest_path.parent

    manifest = load_toml(manifest_path)

    paths = require_mapping(manifest.get("paths"), "paths")

    master_file = require_string(paths.get("master_file"), "paths.master_file")
    output_dir = require_string(paths.get("output_dir", "."), "paths.output_dir")

    subsets = require_mapping(manifest.get("subsets"), "subsets")
    validation = require_mapping(manifest.get("validation", {}), "validation")

    master_path = manifest_dir / master_file
    output_base = manifest_dir / output_dir

    yaml = YAML()
    yaml.version = (1, 2)
    yaml.explicit_start = True
    yaml.preserve_quotes = True
    yaml.width = 4096

    master = load_yaml(master_path, yaml)

    if not isinstance(master, dict):
        raise SystemExit(f"ERROR: Expected master YAML to be a mapping: {master_path}")

    
    master_key_by_string = {str(key): key for key in master.keys()}

    validate_complete_subset(
        validation=validation,
        subsets=subsets,
        master_key_by_string=master_key_by_string,
    )

    had_errors = False

    for subset_name, config_value in subsets.items():
        config = require_mapping(config_value, f"subsets.{subset_name}")

        filename = require_string(
            config.get("file"),
            f"subsets.{subset_name}.file",
        )

        raw_keys = require_list(
            config.get("keys"),
            f"subsets.{subset_name}.keys",
        )

        requested_keys = [str(key) for key in raw_keys]
        output_path = output_base / filename
        
        unknown_keys = [
            key for key in requested_keys
            if key not in master_key_by_string
        ]
        
        if unknown_keys:
            had_errors = True
            print(
                f"ERROR: {filename} requests keys not in master: {unknown_keys}",
                file=sys.stderr,
            )
            continue
        
        updated = CommentedMap(
            (
                master_key_by_string[key],
                master[master_key_by_string[key]],
            )
            for key in requested_keys
        )

        updated.yaml_set_start_comment(
            f"This file is generated from {master_file}.\n"
            f"Do not edit manually. Update {manifest_path.name} instead."
        )

        write_yaml(output_path, updated, yaml)

        print(f"Updated: {output_path} ({len(updated)} keys)")

    if had_errors:
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
