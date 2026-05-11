#!/usr/bin/env python3
"""Record a non-secret manual intervention note for the current install run."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_STATE_FILE = Path("var/state/current-install.json")
SECRET_VALUE_RE = re.compile(
    r"(BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,})"
)


def die(code: str, message: str) -> None:
    print(f"record-manual-step: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_state_file_path(path: Path) -> None:
    if path.is_absolute():
        die("MANUAL_STEP_INVALID", f"state file must be project-relative under var/state: {path}")
    if ".." in path.parts:
        die("MANUAL_STEP_INVALID", f"state file must not contain parent traversal: {path}")
    if len(path.parts) < 3 or path.parts[0] != "var" or path.parts[1] != "state":
        die("MANUAL_STEP_INVALID", f"state file must be under var/state: {path}")
    current = Path()
    for part in path.parts[:-1]:
        current = current / part
        if current.is_symlink():
            die("MANUAL_STEP_INVALID", f"state path component must not be a symlink: {current}")


def validate_run_dir(run_id: str) -> Path:
    if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,80}", run_id):
        die("MANUAL_STEP_INVALID", f"run id is unsafe: {run_id}")
    run_dir = Path("logs") / "install-runs" / run_id
    if ".." in run_dir.parts or run_dir.is_absolute():
        die("MANUAL_STEP_INVALID", f"run directory is unsafe: {run_dir}")
    current = Path()
    for part in run_dir.parts:
        current = current / part
        if current.is_symlink():
            die("MANUAL_STEP_INVALID", f"run directory component must not be a symlink: {current}")
    return run_dir


def validate_text(label: str, value: str) -> str:
    value = value.strip()
    if not value:
        die("MANUAL_STEP_INVALID", f"{label} is required")
    if len(value) > 4000:
        die("MANUAL_STEP_INVALID", f"{label} is too long; keep manual notes concise")
    if "\x00" in value:
        die("MANUAL_STEP_INVALID", f"{label} contains a NUL byte")
    if SECRET_VALUE_RE.search(value):
        die("MANUAL_STEP_SECRET_RISK", f"{label} appears to contain secret material")
    return value


def text_from_arg_or_env(args: argparse.Namespace, argument: str, env_name: str, default: str = "") -> str:
    value = getattr(args, argument)
    if value is not None:
        return value
    return os.environ.get(env_name, default)


def load_state(path: Path) -> dict[str, Any]:
    validate_state_file_path(path)
    if not path.is_file() or path.is_symlink():
        die("INSTALL_STATE_INVALID", f"state file is missing or unsafe: {path}")
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("INSTALL_STATE_INVALID", f"state file is not valid JSON: {exc}")
    if not isinstance(state, dict):
        die("INSTALL_STATE_INVALID", "state file must contain a JSON object")
    return state


def write_json(path: Path, data: dict[str, Any]) -> None:
    if path.exists() and (path.is_symlink() or not path.is_file()):
        die("MANUAL_STEP_INVALID", f"refusing to write unsafe JSON path: {path}")
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def command_record(args: argparse.Namespace) -> None:
    state = load_state(args.state_file)
    run_id = str(state.get("run_id") or "")
    if not run_id:
        die("INSTALL_STATE_INVALID", "state does not contain run_id; run a Makefile-mediated plan or install phase first")

    summary = validate_text("MANUAL_STEP_SUMMARY", text_from_arg_or_env(args, "summary", "MANUAL_STEP_SUMMARY"))
    reason = validate_text("MANUAL_STEP_REASON", text_from_arg_or_env(args, "reason", "MANUAL_STEP_REASON"))
    next_action = validate_text(
        "MANUAL_STEP_NEXT_ACTION",
        text_from_arg_or_env(
            args,
            "next_action",
            "MANUAL_STEP_NEXT_ACTION",
            "Run make install-resume-plan and relevant read-only checks before resuming automation.",
        ),
    )

    run_dir = validate_run_dir(run_id)
    manual_dir = run_dir / "manual-steps"
    manual_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
    if manual_dir.is_symlink() or not manual_dir.is_dir():
        die("MANUAL_STEP_INVALID", f"manual step directory is unsafe: {manual_dir}")

    now = datetime.now(timezone.utc)
    recorded_at = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    note_path = manual_dir / f"manual-step-{now.strftime('%Y%m%dT%H%M%S%fZ')}.json"
    if note_path.exists():
        die("MANUAL_STEP_INVALID", f"manual step record already exists: {note_path}")
    record = {
        "project": "gentoo-ai-installer",
        "run_id": run_id,
        "recorded_at": recorded_at,
        "last_completed_phase": state.get("last_completed_phase") or "",
        "profile": state.get("profile") or "",
        "filesystem": state.get("filesystem") or "",
        "install_disk": state.get("install_disk") or "",
        "summary": summary,
        "reason": reason,
        "next_action": next_action,
        "requires_revalidation": True,
        "secret_safety": "operator-provided note scanned for high-risk secret patterns; do not record secrets",
    }
    write_json(note_path, record)

    events_path = run_dir / "events.jsonl"
    with events_path.open("a", encoding="utf-8") as events:
        events.write(json.dumps({
            "timestamp": recorded_at,
            "event": "manual-step-recorded",
            "path": str(note_path),
            "requires_revalidation": True,
        }, sort_keys=True) + "\n")

    interventions = state.get("manual_interventions")
    if not isinstance(interventions, list):
        interventions = []
    interventions.append(str(note_path))
    state["manual_interventions"] = interventions
    state["manual_intervention_requires_revalidation"] = True
    state["updated_at"] = recorded_at
    state["next_safe_action"] = "Run make install-resume-plan and relevant read-only checks before resuming automation."
    write_json(args.state_file, state)
    write_json(run_dir / "state.json", state)

    print(f"Manual step recorded: {note_path}")
    print("Revalidation required before resuming automation.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE)
    subparsers = parser.add_subparsers(dest="command", required=True)
    record = subparsers.add_parser("record", help="Record a non-secret manual intervention note")
    record.add_argument("--summary", default=None)
    record.add_argument("--reason", default=None)
    record.add_argument(
        "--next-action",
        default=None,
    )
    record.set_defaults(func=command_record)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
