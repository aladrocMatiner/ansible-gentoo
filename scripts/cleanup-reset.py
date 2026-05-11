#!/usr/bin/env python3
"""Safely clean generated gentoo-ai-installer artifacts by explicit scope."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any


DEFAULT_STATE_FILE = Path("var/state/current-install.json")
ALLOWED_SCOPES = {"state", "logs", "audit", "stage3-cache", "test-run"}
PROJECT_LOG_ROOT = Path("logs") / "install-runs"
STAGE3_ABS_ROOT = Path("/tmp/gentoo-ai-installer")


def die(code: str, message: str) -> None:
    print(f"cleanup-reset: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_relative(path: Path, root: tuple[str, ...], label: str) -> None:
    if path.is_absolute():
        die("CLEANUP_PATH_INVALID", f"{label} must be project-relative: {path}")
    if ".." in path.parts:
        die("CLEANUP_PATH_INVALID", f"{label} must not contain parent traversal: {path}")
    if path.parts[: len(root)] != root:
        die("CLEANUP_PATH_INVALID", f"{label} must stay under {'/'.join(root)}: {path}")
    reject_symlink_components(path, label)


def reject_symlink_components(path: Path, label: str) -> None:
    current = Path(path.anchor) if path.is_absolute() else Path()
    parts = path.parts[1:] if path.is_absolute() else path.parts
    for part in parts:
        current = current / part
        if current.is_symlink():
            die("CLEANUP_PATH_INVALID", f"{label} path component must not be a symlink: {current}")


def load_state(path: Path) -> dict[str, Any]:
    validate_relative(path, ("var", "state"), "state file")
    if not path.exists():
        return {}
    if not path.is_file() or path.is_symlink():
        die("CLEANUP_PATH_INVALID", f"state file must be a regular file: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("CLEANUP_STATE_INVALID", f"state file is not valid JSON: {exc}")
    if not isinstance(data, dict):
        die("CLEANUP_STATE_INVALID", "state file must contain a JSON object")
    return data


def safe_run_id(run_id: str) -> str:
    if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,80}", run_id):
        die("CLEANUP_RUN_INVALID", f"run id is unsafe: {run_id}")
    return run_id


def run_id_from_args(args: argparse.Namespace, state: dict[str, Any]) -> str:
    if args.run_id:
        return safe_run_id(args.run_id)
    run_id = str(state.get("run_id") or "")
    if not run_id:
        die("CLEANUP_RUN_INVALID", "CLEAN_RUN_ID is required when state has no run_id")
    return safe_run_id(run_id)


def safe_run_dir(run_id: str) -> Path:
    run_dir = PROJECT_LOG_ROOT / run_id
    validate_relative(run_dir / "state.json", ("logs", "install-runs"), "run directory")
    if run_dir.exists() and (not run_dir.is_dir() or run_dir.is_symlink()):
        die("CLEANUP_PATH_INVALID", f"run directory must be a real directory: {run_dir}")
    return run_dir


def safe_stage3_cache_dir(path: Path) -> Path:
    if not path.is_absolute():
        validate_relative(path, ("var", "cache"), "stage3 cache")
        return path
    resolved = path.resolve(strict=False)
    try:
        resolved.relative_to(STAGE3_ABS_ROOT)
    except ValueError:
        die("CLEANUP_PATH_INVALID", f"absolute STAGE3_CACHE_DIR must stay under {STAGE3_ABS_ROOT}: {path}")
    reject_symlink_components(path, "stage3 cache")
    return path


def collect_log_children(run_dir: Path, *, include_audit: bool) -> list[Path]:
    if not run_dir.exists():
        return []
    candidates: list[Path] = []
    for child in sorted(run_dir.iterdir()):
        if child.name == "audit-bundle" and not include_audit:
            continue
        reject_deletable_path(child)
        candidates.append(child)
    return candidates


def reject_deletable_path(path: Path) -> None:
    if path.is_absolute():
        if path.resolve(strict=False).is_relative_to(STAGE3_ABS_ROOT):
            reject_symlink_components(path, "deletable path")
            return
        die("CLEANUP_PATH_INVALID", f"absolute cleanup path is not approved: {path}")
    if path.parts[:2] == ("logs", "install-runs"):
        validate_relative(path, ("logs", "install-runs"), "deletable log path")
        return
    if path.parts[:2] == ("var", "state"):
        validate_relative(path, ("var", "state"), "deletable state path")
        return
    if path.parts[:2] == ("var", "cache"):
        validate_relative(path, ("var", "cache"), "deletable cache path")
        return
    die("CLEANUP_PATH_INVALID", f"cleanup path is outside approved roots: {path}")


def cleanup_candidates(args: argparse.Namespace) -> tuple[list[Path], list[str]]:
    scope = args.scope
    if scope not in ALLOWED_SCOPES:
        die("CLEANUP_SCOPE_INVALID", f"scope must be one of: {', '.join(sorted(ALLOWED_SCOPES))}")
    state = load_state(args.state_file)
    notes: list[str] = []
    candidates: list[Path] = []

    if scope in {"state", "test-run"}:
        if args.state_file.exists():
            candidates.append(args.state_file)
        else:
            notes.append(f"state file missing: {args.state_file}")

    if scope in {"logs", "audit", "test-run"}:
        run_id = run_id_from_args(args, state)
        run_dir = safe_run_dir(run_id)
        if scope == "audit":
            audit_dir = run_dir / "audit-bundle"
            reject_deletable_path(audit_dir)
            if audit_dir.exists():
                candidates.append(audit_dir)
            else:
                notes.append(f"audit bundle missing: {audit_dir}")
        else:
            candidates.extend(collect_log_children(run_dir, include_audit=False))
            notes.append("audit bundles are preserved by default")

    if scope == "stage3-cache":
        cache_dir = safe_stage3_cache_dir(args.stage3_cache_dir)
        if cache_dir.exists():
            reject_deletable_path(cache_dir)
            candidates.append(cache_dir)
        else:
            notes.append(f"stage3 cache missing: {cache_dir}")

    return candidates, notes


def print_plan(scope: str, candidates: list[Path], notes: list[str]) -> None:
    print(f"cleanup scope: {scope}")
    if candidates:
        print("eligible paths:")
        for path in candidates:
            print(f"  {path}")
    else:
        print("eligible paths: none")
    if notes:
        print("notes:")
        for note in notes:
            print(f"  {note}")


def delete_path(path: Path) -> None:
    reject_deletable_path(path)
    if not path.exists():
        return
    if path.is_symlink():
        die("CLEANUP_PATH_INVALID", f"refusing to delete symlink: {path}")
    if path.is_dir():
        shutil.rmtree(path)
    elif path.is_file():
        path.unlink()
    else:
        die("CLEANUP_PATH_INVALID", f"refusing to delete non-file/non-directory path: {path}")


def command_plan(args: argparse.Namespace) -> None:
    candidates, notes = cleanup_candidates(args)
    print_plan(args.scope, candidates, notes)


def command_clean(args: argparse.Namespace) -> None:
    if args.confirm != "DELETE":
        die("CONFIRMATION_MISSING", "cleanup requires I_UNDERSTAND_CLEANUP_DELETE=DELETE")
    candidates, notes = cleanup_candidates(args)
    print_plan(args.scope, candidates, notes)
    for path in candidates:
        delete_path(path)
    print(f"cleanup complete: removed {len(candidates)} path(s)")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scope", required=True, choices=sorted(ALLOWED_SCOPES))
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE)
    parser.add_argument("--run-id", default="")
    parser.add_argument("--stage3-cache-dir", type=Path, default=Path("/tmp/gentoo-ai-installer/stage3"))
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan_parser = subparsers.add_parser("plan", help="Show cleanup candidates without deleting them")
    plan_parser.set_defaults(func=command_plan)

    clean_parser = subparsers.add_parser("clean", help="Delete cleanup candidates after confirmation")
    clean_parser.add_argument("--confirm", default="")
    clean_parser.set_defaults(func=command_clean)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
