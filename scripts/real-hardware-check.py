#!/usr/bin/env python3
"""Generate a read-only real hardware readiness report."""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPORT_DIR = Path("logs/real-hardware-readiness")
SECRET_VALUE_RE = re.compile(
    r"(BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,})"
)


def die(code: str, message: str) -> None:
    print(f"real-hardware-check: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def require_yes(name: str, description: str, errors: list[str]) -> str:
    value = env(name, "no")
    if value != "yes":
        errors.append(f"{name}: set to yes after confirming {description}")
    return value


def validate_text(name: str, value: str, errors: list[str]) -> str:
    if "\x00" in value:
        errors.append(f"{name}: contains a NUL byte")
    if len(value) > 1000:
        errors.append(f"{name}: keep acknowledgement text under 1000 characters")
    if SECRET_VALUE_RE.search(value):
        errors.append(f"{name}: appears to contain secret material")
    return value


def validate_install_disk(value: str, errors: list[str], warnings: list[str]) -> None:
    if not value:
        errors.append("INSTALL_DISK: required for real hardware readiness checks and has no default")
        return
    if not value.startswith("/dev/") or value in {"/dev", "/dev/"}:
        errors.append(f"INSTALL_DISK: expected an explicit /dev path from the target live ISO, got {value}")
    for token in ("..", "=", ",", ";", "|", "&", " ", "*", "?", "[", "]"):
        if token in value:
            errors.append(f"INSTALL_DISK: contains unsafe syntax token {token!r}")
    if value in {"/dev/vda", "/dev/xvda"}:
        errors.append(f"INSTALL_DISK: {value} is a VM example path and must not be used for real hardware readiness")
    if value.startswith("/dev/sd") or value.startswith("/dev/nvme") or value.startswith("/dev/mmcblk"):
        warnings.append(
            "INSTALL_DISK_STABILITY: prefer /dev/disk/by-id/... or another stable identity path when available"
        )


def write_report(report: dict[str, Any]) -> Path:
    REPORT_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    if REPORT_DIR.is_symlink() or not REPORT_DIR.is_dir():
        die("REAL_HARDWARE_CHECK_INVALID", f"report directory is unsafe: {REPORT_DIR}")
    report_path = REPORT_DIR / "latest.json"
    if report_path.exists() and (report_path.is_symlink() or not report_path.is_file()):
        die("REAL_HARDWARE_CHECK_INVALID", f"report path is unsafe: {report_path}")
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return report_path


def main() -> None:
    errors: list[str] = []
    warnings: list[str] = []

    profile = env("PROFILE", "openrc")
    filesystem = env("FILESYSTEM", "ext4")
    boot_mode = env("BOOT_MODE", "uefi")
    ansible_live_host = env("ANSIBLE_LIVE_HOST")
    install_disk = env("INSTALL_DISK")
    skip_reason = validate_text("REAL_HARDWARE_LIBVIRT_SKIP_REASON", env("REAL_HARDWARE_LIBVIRT_SKIP_REASON"), errors)

    if profile not in {"openrc", "systemd"}:
        errors.append(f"PROFILE: expected openrc or systemd, got {profile}")
    if filesystem not in {"ext4", "btrfs"}:
        errors.append(f"FILESYSTEM: expected ext4 or btrfs, got {filesystem}")
    if boot_mode != "uefi":
        errors.append(f"BOOT_MODE: real hardware readiness requires uefi, got {boot_mode}")
    if not ansible_live_host:
        errors.append("ANSIBLE_LIVE_HOST: set the network-reachable official live ISO target")

    validate_install_disk(install_disk, errors, warnings)

    checks = {
        "backups_confirmed": require_yes("REAL_HARDWARE_BACKUPS_CONFIRMED", "current data is backed up", errors),
        "uefi_confirmed": require_yes("REAL_HARDWARE_UEFI_CONFIRMED", "the machine booted the live ISO in UEFI mode", errors),
        "network_confirmed": require_yes("REAL_HARDWARE_NETWORK_CONFIRMED", "SSH/network access is stable", errors),
        "power_confirmed": require_yes("REAL_HARDWARE_POWER_CONFIRMED", "power is stable for a long install", errors),
        "recovery_media_confirmed": require_yes("REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED", "recovery media is available", errors),
        "destructive_preview_reviewed": require_yes(
            "REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED",
            "destructive previews and disk identity output were reviewed",
            errors,
        ),
    }

    libvirt_validated = env("REAL_HARDWARE_LIBVIRT_VALIDATED", "no")
    if libvirt_validated == "yes":
        libvirt_status = "validated"
    elif skip_reason:
        libvirt_status = "skipped-with-acknowledgement"
        warnings.append("LIBVIRT_VALIDATION_SKIPPED: operator provided a skip reason; destructive confirmations remain required")
    else:
        libvirt_status = "missing"
        errors.append(
            "REAL_HARDWARE_LIBVIRT_VALIDATED: set yes after matching libvirt validation, or set REAL_HARDWARE_LIBVIRT_SKIP_REASON"
        )

    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    report = {
        "project": "gentoo-ai-installer",
        "generated_at": generated_at,
        "result": "FAIL" if errors else ("WARN" if warnings else "PASS"),
        "profile": profile,
        "filesystem": filesystem,
        "boot_mode": boot_mode,
        "ansible_live_host_set": bool(ansible_live_host),
        "install_disk": install_disk,
        "libvirt_validation": libvirt_status,
        "libvirt_skip_reason": skip_reason,
        "checks": checks,
        "warnings": warnings,
        "errors": errors,
        "safety_note": "This report is read-only and does not satisfy destructive or bootloader confirmations.",
    }
    report_path = write_report(report)

    print("Real hardware readiness report")
    print(f"  report: {report_path}")
    print(f"  result: {report['result']}")
    print(f"  PROFILE/FILESYSTEM: {profile}/{filesystem}")
    print(f"  BOOT_MODE: {boot_mode}")
    print(f"  ANSIBLE_LIVE_HOST: {'<set>' if ansible_live_host else '<unset>'}")
    print(f"  INSTALL_DISK: {install_disk or '<unset>'}")
    print(f"  libvirt validation: {libvirt_status}")

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"  {warning}")
    if errors:
        print("\nErrors:", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        print("\nResult: FAIL", file=sys.stderr)
        raise SystemExit(1)

    print("\nResult:", report["result"])
    print("Next: run the relevant read-only preview again before any destructive Makefile target.")


if __name__ == "__main__":
    main()
