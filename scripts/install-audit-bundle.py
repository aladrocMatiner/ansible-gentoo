#!/usr/bin/env python3
"""Generate a secret-safe local audit bundle for an install run."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
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
EVIDENCE_PATHS = [
    "state.json",
    "events.jsonl",
    "partition/before.json",
    "partition/after.json",
    "filesystem/before.json",
    "filesystem/after.json",
    "mount-target/before.json",
    "mount-target/after.json",
    "stage3/verification.json",
    "stage3/extraction.json",
    "chroot/prepare.json",
    "portage/baseline.json",
    "system-config/identity.json",
    "fstab/fstab.json",
    "kernel/kernel.json",
    "system-packages/packages-services.json",
    "users/users-access.json",
    "bootloader/grub.json",
    "final-checks/reboot-readiness.json",
    "first-boot/validation.json",
]


def die(code: str, message: str) -> None:
    print(f"install-audit-bundle: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_project_relative(path: Path, root: tuple[str, ...], label: str) -> None:
    if path.is_absolute():
        die("INSTALL_AUDIT_INVALID", f"{label} must be project-relative: {path}")
    if ".." in path.parts:
        die("INSTALL_AUDIT_INVALID", f"{label} must not contain parent traversal: {path}")
    if path.parts[: len(root)] != root:
        die("INSTALL_AUDIT_INVALID", f"{label} must stay under {'/'.join(root)}: {path}")

    current = Path()
    for part in path.parts[:-1]:
        current = current / part
        if current.is_symlink():
            die("INSTALL_AUDIT_INVALID", f"{label} path component must not be a symlink: {current}")


def load_state(path: Path) -> dict[str, Any]:
    validate_project_relative(path, ("var", "state"), "state file")
    if not path.is_file() or path.is_symlink():
        die("INSTALL_STATE_INVALID", f"state file is missing or unsafe: {path}")
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("INSTALL_STATE_INVALID", f"state file is not valid JSON: {exc}")
    if not isinstance(state, dict):
        die("INSTALL_STATE_INVALID", "state file must contain a JSON object")
    secret_hits = find_secret_like_fields(state)
    if secret_hits:
        die("INSTALL_AUDIT_SECRET_RISK", f"state contains secret-like fields: {', '.join(secret_hits[:8])}")
    return state


def find_secret_like_fields(value: Any, path: str = "$", *, allow_boolean_status: bool = False) -> list[str]:
    hits: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            key_text = str(key)
            child_path = f"{path}.{key_text}"
            if SECRET_KEY_RE.search(key_text) and not (allow_boolean_status and isinstance(item, bool)):
                hits.append(child_path)
            hits.extend(find_secret_like_fields(item, child_path, allow_boolean_status=allow_boolean_status))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            hits.extend(find_secret_like_fields(item, f"{path}[{index}]", allow_boolean_status=allow_boolean_status))
    elif isinstance(value, str) and SECRET_VALUE_RE.search(value):
        hits.append(path)
    return hits


def reject_secret_text(path: Path, text: str) -> None:
    if path.suffix == ".json":
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError as exc:
            die("INSTALL_AUDIT_INVALID", f"JSON evidence is malformed: {path}: {exc}")
        secret_hits = find_secret_like_fields(parsed, allow_boolean_status=True)
        if secret_hits:
            die("INSTALL_AUDIT_SECRET_RISK", f"evidence contains secret-like fields or values: {path}: {', '.join(secret_hits[:8])}")
        return

    if SECRET_VALUE_RE.search(text):
        die("INSTALL_AUDIT_SECRET_RISK", f"evidence contains secret-like value: {path}")


def safe_run_dir(run_id: str) -> Path:
    if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,80}", run_id):
        die("INSTALL_AUDIT_INVALID", f"run id is unsafe: {run_id}")
    run_dir = Path("logs") / "install-runs" / run_id
    validate_project_relative(run_dir / "state.json", ("logs", "install-runs"), "run directory")
    if not run_dir.is_dir() or run_dir.is_symlink():
        die("INSTALL_AUDIT_INVALID", f"run directory is missing or unsafe: {run_dir}")
    return run_dir


def copy_evidence(run_dir: Path, bundle_dir: Path) -> tuple[list[str], list[str]]:
    included: list[str] = []
    missing: list[str] = []
    evidence_root = bundle_dir / "evidence"
    evidence_root.mkdir(parents=True, exist_ok=True)

    for relative in EVIDENCE_PATHS:
        source = run_dir / relative
        if not source.exists():
            missing.append(relative)
            continue
        if not source.is_file() or source.is_symlink():
            die("INSTALL_AUDIT_INVALID", f"evidence path is not a regular file: {source}")
        text = source.read_text(encoding="utf-8", errors="replace")
        reject_secret_text(source, text)
        destination = evidence_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        included.append(relative)

    manual_dir = run_dir / "manual-steps"
    if manual_dir.exists():
        if not manual_dir.is_dir() or manual_dir.is_symlink():
            die("INSTALL_AUDIT_INVALID", f"manual steps path is not a safe directory: {manual_dir}")
        for source in sorted(manual_dir.glob("*.json")):
            if not source.is_file() or source.is_symlink():
                die("INSTALL_AUDIT_INVALID", f"manual step evidence path is not a regular file: {source}")
            text = source.read_text(encoding="utf-8", errors="replace")
            reject_secret_text(source, text)
            relative = str(source.relative_to(run_dir))
            destination = evidence_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
            included.append(relative)

    return included, missing


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def command_generate(args: argparse.Namespace) -> None:
    state = load_state(args.state_file)
    run_id = str(state.get("run_id") or "")
    if not run_id:
        die("INSTALL_AUDIT_INVALID", "state does not contain run_id")

    run_dir = safe_run_dir(run_id)
    bundle_dir = run_dir / "audit-bundle"
    if bundle_dir.is_symlink():
        die("INSTALL_AUDIT_INVALID", f"audit bundle path must not be a symlink: {bundle_dir}")
    bundle_dir.mkdir(mode=0o750, parents=True, exist_ok=True)

    included, missing = copy_evidence(run_dir, bundle_dir)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "project": "gentoo-ai-installer",
        "run_id": run_id,
        "generated_at": generated_at,
        "profile": state.get("profile") or "",
        "filesystem": state.get("filesystem") or "",
        "boot_mode": state.get("boot_mode") or "",
        "install_disk": state.get("install_disk") or "",
        "last_completed_phase": state.get("last_completed_phase") or "",
        "included_evidence": included,
        "missing_evidence": missing,
        "secret_safety": "source evidence scanned; bundle generation fails on secret-like fields or values",
    }
    write_json(bundle_dir / "manifest.json", manifest)
    summary = [
        "gentoo-ai-installer audit bundle",
        f"run_id: {run_id}",
        f"generated_at: {generated_at}",
        f"profile: {manifest['profile'] or '<unset>'}",
        f"filesystem: {manifest['filesystem'] or '<unset>'}",
        f"install_disk: {manifest['install_disk'] or '<unset>'}",
        f"last_completed_phase: {manifest['last_completed_phase'] or '<unset>'}",
        f"included_evidence_count: {len(included)}",
        f"missing_evidence_count: {len(missing)}",
        "secret_safety: generated only after secret-like evidence scan",
    ]
    (bundle_dir / "summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    print(f"Audit bundle written: {bundle_dir}")
    print(f"Included evidence files: {len(included)}")
    print(f"Missing optional evidence files: {len(missing)}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE)
    subparsers = parser.add_subparsers(dest="command", required=True)
    generate_parser = subparsers.add_parser("generate", help="Generate audit bundle for current install state")
    generate_parser.set_defaults(func=command_generate)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
