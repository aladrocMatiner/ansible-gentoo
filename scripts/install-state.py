#!/usr/bin/env python3
"""Inspect and prepare non-secret gentoo-ai-installer install state."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from pathlib import Path
from typing import Any


DEFAULT_STATE_FILE = Path("var/state/current-install.json")
SECRET_KEY_RE = re.compile(
    r"(api[_-]?key|access[_-]?token|refresh[_-]?token|private[_-]?key|password|passwd)",
    re.IGNORECASE,
)
SECRET_VALUE_RE = re.compile(
    r"(BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,})"
)


def die(code: str, message: str) -> None:
    print(f"install-state: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_state_file_path(path: Path) -> None:
    if path.is_absolute():
        die("INSTALL_STATE_INVALID", f"state file must be project-relative under var/state: {path}")
    if ".." in path.parts:
        die("INSTALL_STATE_INVALID", f"state file must not contain parent traversal: {path}")
    if len(path.parts) < 3 or path.parts[0] != "var" or path.parts[1] != "state":
        die("INSTALL_STATE_INVALID", f"state file must be under var/state: {path}")

    current = Path()
    for part in path.parts[:-1]:
        current = current / part
        if current.is_symlink():
            die("INSTALL_STATE_INVALID", f"state path component must not be a symlink: {current}")


def load_state(path: Path, *, required: bool) -> dict[str, Any] | None:
    validate_state_file_path(path)
    if not path.exists():
        if required:
            die("INSTALL_STATE_INVALID", f"state file not found: {path}")
        return None
    if not path.is_file():
        die("INSTALL_STATE_INVALID", f"state path is not a regular file: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("INSTALL_STATE_INVALID", f"state file is not valid JSON: {path}: {exc}")
    if not isinstance(data, dict):
        die("INSTALL_STATE_INVALID", f"state file must contain a JSON object: {path}")
    secret_hits = find_secret_like_fields(data)
    if secret_hits:
        joined = ", ".join(secret_hits[:8])
        die("INSTALL_STATE_SECRET_RISK", f"state file contains secret-like fields or values: {joined}")
    return data


def find_secret_like_fields(value: Any, path: str = "$") -> list[str]:
    hits: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            key_text = str(key)
            child_path = f"{path}.{key_text}"
            if SECRET_KEY_RE.search(key_text):
                hits.append(child_path)
            hits.extend(find_secret_like_fields(item, child_path))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            hits.extend(find_secret_like_fields(item, f"{path}[{index}]"))
    elif isinstance(value, str) and SECRET_VALUE_RE.search(value):
        hits.append(path)
    return hits


def checkpoint_from_state(state: dict[str, Any]) -> dict[str, Any]:
    checkpoint = state.get("resume_checkpoint")
    if not isinstance(checkpoint, dict) or not checkpoint:
        die("RESUME_CHECKPOINT_INVALID", "state does not contain a usable resume_checkpoint")
    selected_disk = checkpoint.get("selected_disk")
    if not isinstance(selected_disk, dict):
        die("RESUME_CHECKPOINT_INVALID", "resume_checkpoint is missing selected_disk")
    descendants = checkpoint.get("descendants")
    if not isinstance(descendants, list):
        die("RESUME_CHECKPOINT_INVALID", "resume_checkpoint is missing descendant block state")
    return checkpoint


def command_show(args: argparse.Namespace) -> None:
    state = load_state(args.state_file, required=False)
    if state is None:
        print(f"No install state found at {args.state_file}")
        return

    completed = state.get("completed_phases") or []
    if not isinstance(completed, list):
        completed = []

    print(f"State file: {args.state_file}")
    print(f"Run id: {state.get('run_id', '<unknown>')}")
    print(f"Updated at: {state.get('updated_at', '<unknown>')}")
    print(f"Profile: {state.get('profile') or '<unset>'}")
    print(f"Filesystem: {state.get('filesystem') or '<unset>'}")
    print(f"Boot mode: {state.get('boot_mode') or '<unset>'}")
    print(f"Install disk: {state.get('install_disk') or '<unset>'}")
    print(f"Last completed phase: {state.get('last_completed_phase') or '<none>'}")
    print(f"Completed phases: {', '.join(str(item) for item in completed) if completed else '<none>'}")
    print(f"Resume checkpoint: {'available' if state.get('resume_checkpoint') else 'missing'}")
    manual_interventions = state.get("manual_interventions")
    if not isinstance(manual_interventions, list):
        manual_interventions = []
    print(f"Manual interventions recorded: {len(manual_interventions)}")
    print(f"Manual revalidation required: {'yes' if state.get('manual_intervention_requires_revalidation') else 'no'}")
    print(f"Next safe action: {state.get('next_safe_action') or '<review docs>'}")
    print("Resume policy: destructive confirmations are still required; state never acts as confirmation.")


def command_resume_vars(args: argparse.Namespace) -> None:
    state_path = args.state_file.resolve()
    state = load_state(args.state_file, required=True)
    assert state is not None
    checkpoint = checkpoint_from_state(state)
    selected_disk = checkpoint["selected_disk"]

    install_disk = state.get("install_disk") or checkpoint.get("install_disk") or selected_disk.get("path")
    profile = state.get("profile") or checkpoint.get("profile")
    filesystem = state.get("filesystem") or checkpoint.get("filesystem")
    run_id = state.get("run_id")

    if not install_disk:
        die("INSTALL_STATE_INVALID", "state does not contain install_disk")
    if not profile:
        die("INSTALL_STATE_INVALID", "state does not contain profile")
    if not filesystem:
        die("INSTALL_STATE_INVALID", "state does not contain filesystem")
    if not run_id:
        die("INSTALL_STATE_INVALID", "state does not contain run_id")

    values = {
        "INSTALL_STATE_FILE": str(state_path),
        "INSTALL_STATE_RUN_ID": str(run_id),
        "INSTALL_STATE_INSTALL_DISK": str(install_disk),
        "INSTALL_STATE_PROFILE": str(profile),
        "INSTALL_STATE_FILESYSTEM": str(filesystem),
        "INSTALL_STATE_LAST_PHASE": str(state.get("last_completed_phase") or ""),
        "INSTALL_STATE_MANUAL_REVALIDATION_REQUIRED": "yes" if state.get("manual_intervention_requires_revalidation") else "no",
    }
    for key, value in values.items():
        print(f"{key}={shlex.quote(value)}")


def command_clean(args: argparse.Namespace) -> None:
    if args.confirm != "DELETE":
        die("CONFIRMATION_MISSING", "clean requires I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE")
    state_path = args.state_file
    validate_state_file_path(state_path)
    if not state_path.exists():
        print(f"No install state found at {state_path}")
        return
    resolved = state_path.resolve()
    allowed_root = Path("var/state").resolve()
    try:
        resolved.relative_to(allowed_root)
    except ValueError:
        die("INSTALL_STATE_INVALID", f"refusing to delete state outside var/state: {state_path}")
    if state_path.is_symlink() or not state_path.is_file():
        die("INSTALL_STATE_INVALID", f"refusing to delete non-regular state path: {state_path}")
    state_path.unlink()
    print(f"Deleted install state pointer: {state_path}")
    print("Run logs under logs/install-runs/ were not deleted.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE)
    subparsers = parser.add_subparsers(dest="command", required=True)

    show_parser = subparsers.add_parser("show", help="Show current install state summary")
    show_parser.set_defaults(func=command_show)

    resume_parser = subparsers.add_parser("resume-vars", help="Print shell variables for resume validation")
    resume_parser.set_defaults(func=command_resume_vars)

    clean_parser = subparsers.add_parser("clean", help="Delete current install state pointer after confirmation")
    clean_parser.add_argument("--confirm", default="")
    clean_parser.set_defaults(func=command_clean)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
