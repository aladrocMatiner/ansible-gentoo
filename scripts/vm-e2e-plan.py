#!/usr/bin/env python3
"""Plan libvirt end-to-end install validation without mutating VM state."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPORT_DIR = Path("logs/libvirt-e2e")
MATRIX_ENTRIES = [
    {"profile": "openrc", "filesystem": "ext4", "stage3_flavor": "standard"},
    {"profile": "openrc", "filesystem": "btrfs", "stage3_flavor": "standard"},
    {"profile": "systemd", "filesystem": "ext4", "stage3_flavor": "standard"},
    {"profile": "systemd", "filesystem": "btrfs", "stage3_flavor": "standard"},
    {"profile": "openrc", "filesystem": "ext4", "stage3_flavor": "hardened"},
    {"profile": "openrc", "filesystem": "btrfs", "stage3_flavor": "hardened"},
    {"profile": "systemd", "filesystem": "ext4", "stage3_flavor": "hardened"},
    {"profile": "systemd", "filesystem": "btrfs", "stage3_flavor": "hardened"},
    {"profile": "openrc", "filesystem": "ext4", "stage3_flavor": "musl"},
    {"profile": "openrc", "filesystem": "btrfs", "stage3_flavor": "musl"},
    {"profile": "systemd", "filesystem": "ext4", "stage3_flavor": "musl"},
    {"profile": "systemd", "filesystem": "btrfs", "stage3_flavor": "musl"},
]


def die(code: str, message: str) -> None:
    print(f"vm-e2e-plan: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def validate() -> dict[str, str]:
    profile = env("PROFILE", "openrc")
    filesystem = env("FILESYSTEM", "ext4")
    stage3_flavor = env("STAGE3_FLAVOR", "standard")
    install_disk = env("INSTALL_DISK")
    admin_user = env("ADMIN_USER")
    enable_ssh = env("ENABLE_SSH", "no")
    admin_sudo_nopasswd = env("ADMIN_SUDO_NOPASSWD") or env("VM_E2E_ADMIN_SUDO_NOPASSWD", "yes") or "yes"
    admin_authorized_keys_file = env("ADMIN_AUTHORIZED_KEYS_FILE")

    errors: list[str] = []
    if profile not in {"openrc", "systemd"}:
        errors.append(f"PROFILE must be openrc or systemd, got {profile}")
    if filesystem not in {"ext4", "btrfs"}:
        errors.append(f"FILESYSTEM must be ext4 or btrfs, got {filesystem}")
    if stage3_flavor not in {"standard", "hardened", "musl"}:
        errors.append(f"STAGE3_FLAVOR must be standard, hardened, or musl, got {stage3_flavor}")
    if install_disk != "/dev/vda":
        errors.append("INSTALL_DISK=/dev/vda must be passed explicitly for the disposable libvirt VM")
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}\$?", admin_user):
        errors.append("ADMIN_USER must be set to a conservative installed-system user name")
    if enable_ssh != "yes":
        errors.append("ENABLE_SSH=yes is required so first-boot validation can connect to the installed VM")
    if admin_sudo_nopasswd not in {"yes", "no"}:
        errors.append("ADMIN_SUDO_NOPASSWD must be yes or no when set")
    if not admin_authorized_keys_file:
        errors.append("ADMIN_AUTHORIZED_KEYS_FILE is required so first-boot validation can authenticate to the installed admin user")
    elif not Path(admin_authorized_keys_file).is_file() or not os.access(admin_authorized_keys_file, os.R_OK):
        errors.append(f"ADMIN_AUTHORIZED_KEYS_FILE must point at a readable public-key file: {admin_authorized_keys_file}")

    if errors:
        die("VM_E2E_INVALID", "; ".join(errors))

    return {
        "profile": profile,
        "filesystem": filesystem,
        "stage3_flavor": stage3_flavor,
        "install_disk": install_disk,
        "admin_user": admin_user,
        "enable_ssh": enable_ssh,
        "admin_sudo_nopasswd": admin_sudo_nopasswd,
        "admin_authorized_keys_file": "<set>",
    }


def run_matrix_plan(log_path: Path) -> dict[str, Any]:
    result = subprocess.run(
        ["scripts/vm-test-matrix-plan.py"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    log_path.write_text(result.stdout, encoding="utf-8")
    return {
        "status": "pass" if result.returncode == 0 else "fail",
        "returncode": result.returncode,
        "log": str(log_path),
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    if path.exists() and (path.is_symlink() or not path.is_file()):
        die("VM_E2E_INVALID", f"refusing to write unsafe report path: {path}")
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    selected = validate()
    REPORT_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    if REPORT_DIR.is_symlink() or not REPORT_DIR.is_dir():
        die("VM_E2E_INVALID", f"report directory is unsafe: {REPORT_DIR}")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    suffix = f"{selected['profile']}-{selected['filesystem']}"
    if selected["stage3_flavor"] != "standard":
        suffix = f"{suffix}-{selected['stage3_flavor']}"
    run_dir = REPORT_DIR / f"{timestamp}-{suffix}"
    run_dir.mkdir(mode=0o750)

    matrix_result = run_matrix_plan(run_dir / "matrix-plan.log")
    if matrix_result["status"] != "pass":
        die("VM_E2E_INVALID", f"matrix planning failed; see {matrix_result['log']}")

    phases = [
        "vm-check",
        "vm-disk",
        "vm-start",
        "vm-bootstrap-ssh",
        "vm-ansible-ping",
        "install",
        "vm-shutdown",
        "vm-validate-first-boot",
        "install-audit",
    ]
    report = {
        "project": "gentoo-ai-installer",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "selected_entry": selected,
        "matrix_entries": MATRIX_ENTRIES,
        "matrix_plan": matrix_result,
        "phases": phases,
        "result": "PASS",
        "safety": {
            "vm_storage": "project-local qcow2 only",
            "guest_install_disk": "/dev/vda",
            "host_block_devices": "forbidden",
            "destructive_execution": "requires vm-e2e-install with normal install confirmations",
            "first_boot_handoff": "requires clean live ISO shutdown before installed-disk boot",
        },
    }
    write_json(run_dir / "e2e-plan.json", report)
    write_json(REPORT_DIR / f"latest-plan-{suffix}.json", report)
    write_json(REPORT_DIR / "latest-plan.json", report)

    print("Libvirt end-to-end install validation plan")
    print(f"  report: {run_dir / 'e2e-plan.json'}")
    print(f"  selected: {selected['profile']}/{selected['filesystem']}/{selected['stage3_flavor']} on {selected['install_disk']}")
    print("  phases:")
    for phase in phases:
        print(f"    - {phase}")
    print("  result: PASS")


if __name__ == "__main__":
    main()
