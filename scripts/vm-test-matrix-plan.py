#!/usr/bin/env python3
"""Plan and optionally run read-only validation for the libvirt install matrix."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


MATRIX_ENTRIES = [
    ("openrc", "ext4"),
    ("openrc", "btrfs"),
    ("systemd", "ext4"),
    ("systemd", "btrfs"),
]
PLAN_PHASES = [
    ("install-plan", "scripts/ansible-install-plan.sh"),
    ("partition-plan", "scripts/ansible-partition-plan.sh"),
    ("mount-plan", "scripts/ansible-mount-plan.sh"),
    ("filesystem-plan", "scripts/ansible-filesystem-plan.sh"),
]


def die(code: str, message: str) -> None:
    print(f"vm-test-matrix-plan: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def has_unsafe_chars(value: str) -> bool:
    return any(token in value for token in (" ", ",", ";", "|", "&", "\\", "'", '"', "<", ">", "$", "\n", "\r", "\t"))


def validate_name(label: str, value: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,62}", value):
        die("VM_MATRIX_INVALID", f"{label} must be a conservative name: {value}")


def validate_project_dir(label: str, value: str) -> Path:
    if not value:
        die("VM_MATRIX_INVALID", f"{label} must not be empty")
    path = Path(value)
    if path.is_absolute():
        die("VM_MATRIX_INVALID", f"{label} must be project-relative: {value}")
    if ".." in path.parts:
        die("VM_MATRIX_INVALID", f"{label} must not contain parent traversal: {value}")
    if has_unsafe_chars(value):
        die("VM_MATRIX_INVALID", f"{label} contains unsafe characters: {value}")
    if path in {Path("."), Path("./")}:
        die("VM_MATRIX_INVALID", f"{label} must not be the project root")
    current = Path()
    for part in path.parts:
        current = current / part
        if current.is_symlink():
            die("VM_MATRIX_INVALID", f"{label} path component must not be a symlink: {current}")
    return path


def validate_install_disk(value: str) -> None:
    if value != "/dev/vda":
        die("VM_MATRIX_INVALID", "VM_TEST_MATRIX_INSTALL_DISK must be /dev/vda for disposable libvirt qcow2 tests")


def entry_name(profile: str, filesystem: str) -> str:
    return f"{profile}-{filesystem}"


def run_command(command: list[str], env_vars: dict[str, str], log_path: Path) -> dict[str, Any]:
    result = subprocess.run(
        command,
        env={**os.environ, **env_vars},
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    log_path.write_text(result.stdout, encoding="utf-8")
    return {
        "command": command,
        "log": str(log_path),
        "returncode": result.returncode,
        "status": "pass" if result.returncode == 0 else "fail",
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    if path.exists() and (path.is_symlink() or not path.is_file()):
        die("VM_MATRIX_INVALID", f"refusing to write unsafe path: {path}")
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    vm_name = env("VM_NAME", "gentoo-ai-installer")
    vm_dir = validate_project_dir("VM_DIR", env("VM_DIR", "var/libvirt"))
    log_root = validate_project_dir("VM_TEST_MATRIX_LOG_DIR", env("VM_TEST_MATRIX_LOG_DIR", "logs/libvirt-matrix"))
    install_disk = env("VM_TEST_MATRIX_INSTALL_DISK", "/dev/vda")
    run_target_plans = env("VM_TEST_MATRIX_RUN_TARGET_PLANS", "no")

    validate_name("VM_NAME", vm_name)
    validate_install_disk(install_disk)
    if run_target_plans not in {"yes", "no"}:
        die("VM_MATRIX_INVALID", "VM_TEST_MATRIX_RUN_TARGET_PLANS must be yes or no")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = log_root / timestamp
    run_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
    if run_dir.is_symlink() or not run_dir.is_dir():
        die("VM_MATRIX_INVALID", f"matrix log directory is unsafe: {run_dir}")

    entries: list[dict[str, Any]] = []
    failures = 0

    for profile, filesystem in MATRIX_ENTRIES:
        name = entry_name(profile, filesystem)
        matrix_vm_name = f"{vm_name}-{name}"
        validate_name("matrix VM name", matrix_vm_name)
        matrix_disk = vm_dir / f"{matrix_vm_name}.qcow2"
        if matrix_disk.is_absolute() or ".." in matrix_disk.parts or matrix_disk.parts[: len(vm_dir.parts)] != vm_dir.parts:
            die("VM_MATRIX_INVALID", f"matrix disk escaped VM_DIR: {matrix_disk}")

        entry_dir = run_dir / name
        entry_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
        env_vars = {
            "PROFILE": profile,
            "FILESYSTEM": filesystem,
            "INSTALL_DISK": install_disk,
            "VM_NAME": matrix_vm_name,
            "VM_DISK": str(matrix_disk),
        }

        validations = {
            "config-check": run_command(
                ["scripts/config-check.sh"],
                env_vars,
                entry_dir / "config-check.txt",
            )
        }

        target_plan_status = "skipped"
        if run_target_plans == "yes":
            target_plan_status = "run"
            for phase, script in PLAN_PHASES:
                validations[phase] = run_command([script], env_vars, entry_dir / f"{phase}.txt")
        else:
            validations["target-plans"] = {
                "status": "skipped",
                "reason": "set VM_TEST_MATRIX_RUN_TARGET_PLANS=yes after booting and SSH-enabling the target live ISO",
            }

        entry_failed = any(item.get("status") == "fail" for item in validations.values())
        if entry_failed:
            failures += 1

        entry_report = {
            "entry": name,
            "profile": profile,
            "filesystem": filesystem,
            "vm_name": matrix_vm_name,
            "vm_disk": str(matrix_disk),
            "guest_install_disk": install_disk,
            "target_plan_status": target_plan_status,
            "validations": validations,
            "status": "fail" if entry_failed else "pass",
        }
        write_json(entry_dir / "entry.json", entry_report)
        entries.append(entry_report)

    report = {
        "project": "gentoo-ai-installer",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "result": "FAIL" if failures else "PASS",
        "run_dir": str(run_dir),
        "run_target_plans": run_target_plans,
        "entries": entries,
        "safety": {
            "host_block_devices": "forbidden",
            "planned_guest_install_disk": install_disk,
            "artifacts": "planned under project-local VM_DIR; this plan target does not create disks or domains",
            "destructive_install_matrix": "not implemented by this target",
        },
    }
    write_json(run_dir / "matrix-plan.json", report)

    print("Libvirt install test matrix plan")
    print(f"  report: {run_dir / 'matrix-plan.json'}")
    print(f"  result: {report['result']}")
    for entry in entries:
        print(
            f"  {entry['entry']}: {entry['status']} "
            f"vm={entry['vm_name']} disk={entry['vm_disk']} guest_disk={entry['guest_install_disk']}"
        )
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
