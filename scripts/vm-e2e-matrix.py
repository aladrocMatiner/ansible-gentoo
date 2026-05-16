#!/usr/bin/env python3
"""Run the full disposable libvirt E2E matrix through make vm-e2e-install."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


MATRIX_PLATFORM = "amd64"
MATRIX_ENTRIES = [
    ("openrc", "ext4", "standard"),
    ("openrc", "btrfs", "standard"),
    ("systemd", "ext4", "standard"),
    ("systemd", "btrfs", "standard"),
    ("openrc", "ext4", "hardened"),
    ("openrc", "btrfs", "hardened"),
    ("systemd", "ext4", "hardened"),
    ("systemd", "btrfs", "hardened"),
    ("openrc", "ext4", "musl"),
    ("openrc", "btrfs", "musl"),
    ("systemd", "ext4", "musl"),
    ("systemd", "btrfs", "musl"),
]
PUBLIC_KEY_RE = re.compile(
    r"^[ \t]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)|"
    r"sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)[ \t]+"
)


def die(code: str, message: str) -> None:
    print(f"vm-e2e-matrix: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def has_unsafe_chars(value: str) -> bool:
    return any(token in value for token in (" ", ",", ";", "|", "&", "\\", "'", '"', "<", ">", "$", "\n", "\r", "\t"))


def validate_conservative_name(label: str, value: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,62}", value):
        die("VM_E2E_MATRIX_INVALID", f"{label} must be a conservative name: {value}")


def validate_optional_test_image_name(value: str) -> None:
    if not value:
        return
    validate_conservative_name("VM_TEST_IMAGE_NAME", value)
    if ".." in value:
        die("VM_E2E_MATRIX_INVALID", f"VM_TEST_IMAGE_NAME must not contain parent traversal-like segments: {value}")
    lowered = value.lower()
    secret_terms = ("secret", "token", "passwd", "password", "apikey", "api_key", "api-key", "private", "credential")
    if any(term in lowered for term in secret_terms):
        die("VM_E2E_MATRIX_INVALID", "VM_TEST_IMAGE_NAME looks secret-like; use a non-sensitive label")


def validate_project_dir(label: str, value: str) -> Path:
    if not value:
        die("VM_E2E_MATRIX_INVALID", f"{label} must not be empty")
    path = Path(value)
    if path.is_absolute():
        die("VM_E2E_MATRIX_INVALID", f"{label} must be project-relative: {value}")
    if ".." in path.parts:
        die("VM_E2E_MATRIX_INVALID", f"{label} must not contain parent traversal: {value}")
    if has_unsafe_chars(value):
        die("VM_E2E_MATRIX_INVALID", f"{label} contains unsafe characters: {value}")
    if path in {Path("."), Path("./")}:
        die("VM_E2E_MATRIX_INVALID", f"{label} must not be the project root")

    current = Path()
    for part in path.parts:
        current = current / part
        if current.is_symlink():
            die("VM_E2E_MATRIX_INVALID", f"{label} path component must not be a symlink: {current}")
    return path


def validate_admin_user(value: str) -> None:
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}\$?", value):
        die("VM_E2E_MATRIX_INVALID", "ADMIN_USER must be a conservative installed-system user name")


def validate_public_key_file(path_text: str) -> None:
    if not path_text:
        die("VM_E2E_MATRIX_INVALID", "ADMIN_AUTHORIZED_KEYS_FILE is required")
    path = Path(path_text).expanduser()
    if not path.is_file() or not os.access(path, os.R_OK):
        die("VM_E2E_MATRIX_INVALID", f"ADMIN_AUTHORIZED_KEYS_FILE must be a readable public-key file: {path_text}")
    text = path.read_text(encoding="utf-8")
    if "-----BEGIN " in text and "PRIVATE KEY-----" in text:
        die("SECRET_INPUT_INVALID", "ADMIN_AUTHORIZED_KEYS_FILE must contain public keys only, not private key material")
    if not any(PUBLIC_KEY_RE.match(line) for line in text.splitlines()):
        die("VM_E2E_MATRIX_INVALID", "ADMIN_AUTHORIZED_KEYS_FILE must contain at least one supported OpenSSH public key")


def validate_no_manual_vm_disk(vm_dir: Path, vm_base_name: str) -> None:
    configured = env("VM_DISK")
    allowed = {
        "",
        str(vm_dir / f"{vm_base_name}.qcow2"),
        str(vm_dir / "gentoo-test.qcow2"),
        "var/libvirt/gentoo-test.qcow2",
    }
    if configured not in allowed:
        die("VM_E2E_MATRIX_INVALID", "vm-e2e-matrix rejects manual VM_DISK overrides; unset VM_DISK so each case derives its own qcow2")


def validate_inputs() -> dict[str, str | int | Path]:
    vm_base_name = env("VM_NAME", "gentoo-test")
    vm_test_image_name = env("VM_TEST_IMAGE_NAME")
    vm_dir = validate_project_dir("VM_DIR", env("VM_DIR", "var/libvirt"))
    log_root = validate_project_dir("VM_E2E_MATRIX_LOG_DIR", env("VM_E2E_MATRIX_LOG_DIR", "logs/libvirt-e2e-matrix"))
    install_disk = env("VM_TEST_MATRIX_INSTALL_DISK", "/dev/vda")
    parallel_text = env("VM_E2E_MATRIX_PARALLEL", "4")
    ssh_host_port = env("VM_SSH_HOST_PORT", "2222")

    validate_conservative_name("VM_NAME", vm_base_name)
    if "-amd64-" in vm_base_name:
        die("VM_E2E_MATRIX_INVALID", "VM_NAME must be the base name; use PROFILE, FILESYSTEM, and STAGE3_FLAVOR for case selection")
    validate_optional_test_image_name(vm_test_image_name)
    validate_no_manual_vm_disk(vm_dir, vm_base_name)

    if ssh_host_port != "2222":
        die(
            "VM_E2E_MATRIX_INVALID",
            "vm-e2e-matrix derives unique SSH host ports per case; leave VM_SSH_HOST_PORT at the default 2222",
        )
    if env("ANSIBLE_LIVE_HOST"):
        die("VM_E2E_MATRIX_INVALID", "vm-e2e-matrix is local-libvirt only; unset ANSIBLE_LIVE_HOST")
    if install_disk != "/dev/vda":
        die("DISK_UNSAFE", "VM_TEST_MATRIX_INSTALL_DISK must be /dev/vda for disposable libvirt matrix installs")
    if env("ENABLE_SSH", "no") != "yes":
        die("VM_E2E_MATRIX_INVALID", "vm-e2e-matrix requires ENABLE_SSH=yes")
    if env("ENABLE_WIFI", "no") not in {"yes", "no"}:
        die("VM_E2E_MATRIX_INVALID", "ENABLE_WIFI must be yes or no when set")
    validate_admin_user(env("ADMIN_USER"))
    validate_public_key_file(env("ADMIN_AUTHORIZED_KEYS_FILE"))
    if env("VM_E2E_RESET_DISK", "no") != "yes":
        die("CONFIRMATION_MISSING", "vm-e2e-matrix requires VM_E2E_RESET_DISK=yes for fresh case disks and state")
    if env("I_UNDERSTAND_CLEANUP_DELETE") != "DELETE":
        die("CONFIRMATION_MISSING", "vm-e2e-matrix requires I_UNDERSTAND_CLEANUP_DELETE=DELETE")
    if env("I_UNDERSTAND_THIS_WIPES_DISK") != "yes":
        die("DESTRUCTIVE_CONFIRMATION_MISSING", "vm-e2e-matrix requires I_UNDERSTAND_THIS_WIPES_DISK=yes")
    if env("I_UNDERSTAND_BOOTLOADER_CHANGES") != "yes":
        die("DESTRUCTIVE_CONFIRMATION_MISSING", "vm-e2e-matrix requires I_UNDERSTAND_BOOTLOADER_CHANGES=yes")

    if not parallel_text.isdigit():
        die("VM_E2E_MATRIX_INVALID", f"VM_E2E_MATRIX_PARALLEL must be numeric: {parallel_text}")
    parallel = int(parallel_text)
    if parallel < 1 or parallel > len(MATRIX_ENTRIES):
        die("VM_E2E_MATRIX_INVALID", f"VM_E2E_MATRIX_PARALLEL must be between 1 and {len(MATRIX_ENTRIES)}")

    return {
        "vm_base_name": vm_base_name,
        "vm_test_image_name": vm_test_image_name,
        "vm_dir": vm_dir,
        "log_root": log_root,
        "install_disk": install_disk,
        "parallel": parallel,
    }


def case_key(profile: str, filesystem: str, stage3_flavor: str) -> str:
    if stage3_flavor == "standard":
        return f"{MATRIX_PLATFORM}-{profile}-{filesystem}"
    return f"{MATRIX_PLATFORM}-{profile}-{filesystem}-{stage3_flavor}"


def case_name(vm_base_name: str, vm_test_image_name: str, profile: str, filesystem: str, stage3_flavor: str) -> str:
    prefix = f"{vm_base_name}-{vm_test_image_name}" if vm_test_image_name else vm_base_name
    name = f"{prefix}-{case_key(profile, filesystem, stage3_flavor)}"
    validate_conservative_name("case VM name", name)
    return name


def run_id_from_state(state_file: Path) -> dict[str, Any]:
    if not state_file.exists() or state_file.is_symlink() or not state_file.is_file():
        return {"state_file": str(state_file), "state_available": False}
    try:
        state = json.loads(state_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return {"state_file": str(state_file), "state_available": False, "state_error": str(exc)}
    run_id = state.get("run_id", "")
    evidence_file = Path("logs/install-runs") / run_id / "first-boot" / "validation.json" if run_id else None
    evidence: dict[str, Any] = {}
    if evidence_file and evidence_file.exists() and evidence_file.is_file() and not evidence_file.is_symlink():
        try:
            evidence = json.loads(evidence_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            evidence = {"evidence_error": str(exc)}
    return {
        "state_file": str(state_file),
        "state_available": True,
        "run_id": run_id,
        "last_completed_phase": state.get("last_completed_phase", ""),
        "first_boot_evidence": str(evidence_file) if evidence_file else "",
        "first_boot_status": evidence.get("status", ""),
        "kernel": evidence.get("kernel", ""),
        "hostname": evidence.get("hostname", ""),
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    if path.exists() and (path.is_symlink() or not path.is_file()):
        die("VM_E2E_MATRIX_INVALID", f"refusing to write unsafe report path: {path}")
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def start_case(entry: dict[str, Any]) -> subprocess.Popen[str]:
    env_vars = {
        **os.environ,
        "PROFILE": entry["profile"],
        "FILESYSTEM": entry["filesystem"],
        "STAGE3_FLAVOR": entry["stage3_flavor"],
        "INSTALL_DISK": entry["install_disk"],
        "VM_E2E_RESET_DISK": "yes",
    }
    log_handle = entry["log_path"].open("w", encoding="utf-8")
    entry["log_handle"] = log_handle
    entry["started_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"vm-e2e-matrix: starting {entry['case']} -> {entry['log_path']}", flush=True)
    return subprocess.Popen(
        ["make", "--no-print-directory", "vm-e2e-install"],
        env=env_vars,
        stdout=log_handle,
        stderr=subprocess.STDOUT,
        text=True,
    )


def finish_case(entry: dict[str, Any], process: subprocess.Popen[str]) -> dict[str, Any]:
    returncode = process.wait()
    entry["log_handle"].close()
    entry.pop("log_handle", None)
    state_details = run_id_from_state(entry["state_file"])
    first_boot_status = state_details.get("first_boot_status", "")
    status = "pass" if returncode == 0 and first_boot_status == "PASS" else "fail"
    finished_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"vm-e2e-matrix: completed {entry['case']} status={status} returncode={returncode}", flush=True)
    return {
        "case": entry["case"],
        "platform": MATRIX_PLATFORM,
        "profile": entry["profile"],
        "filesystem": entry["filesystem"],
        "stage3_flavor": entry["stage3_flavor"],
        "vm_name": entry["vm_name"],
        "vm_disk": str(entry["vm_disk"]),
        "install_disk": entry["install_disk"],
        "log": str(entry["log_path"]),
        "returncode": returncode,
        "status": status,
        "started_at": entry["started_at"],
        "finished_at": finished_at,
        **state_details,
    }


def main() -> None:
    config = validate_inputs()
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    run_dir = Path(config["log_root"]) / timestamp
    run_dir.mkdir(mode=0o750, parents=True, exist_ok=False)
    if run_dir.is_symlink() or not run_dir.is_dir():
        die("VM_E2E_MATRIX_INVALID", f"matrix run directory is unsafe: {run_dir}")

    pending: deque[dict[str, Any]] = deque()
    for profile, filesystem, stage3_flavor in MATRIX_ENTRIES:
        matrix_case = case_key(profile, filesystem, stage3_flavor)
        vm_name = case_name(str(config["vm_base_name"]), str(config["vm_test_image_name"]), profile, filesystem, stage3_flavor)
        vm_disk = Path(config["vm_dir"]) / f"{vm_name}.qcow2"
        if vm_disk.is_absolute() or ".." in vm_disk.parts or vm_disk.parts[: len(Path(config["vm_dir"]).parts)] != Path(config["vm_dir"]).parts:
            die("VM_E2E_MATRIX_INVALID", f"case VM disk escaped VM_DIR: {vm_disk}")
        case_dir = run_dir / matrix_case
        case_dir.mkdir(mode=0o750)
        pending.append(
            {
                "case": matrix_case,
                "profile": profile,
                "filesystem": filesystem,
                "stage3_flavor": stage3_flavor,
                "vm_name": vm_name,
                "vm_disk": vm_disk,
                "state_file": Path("var/state/libvirt") / vm_name / "current-install.json",
                "install_disk": str(config["install_disk"]),
                "log_path": case_dir / "vm-e2e-install.log",
            }
        )

    running: list[tuple[dict[str, Any], subprocess.Popen[str]]] = []
    results: list[dict[str, Any]] = []
    parallel = int(config["parallel"])

    print("Libvirt E2E matrix validation")
    print(f"  run directory: {run_dir}")
    print(f"  parallelism: {parallel}")
    print(f"  this will reset disposable qcow2 disks and install all {len(MATRIX_ENTRIES)} supported cases")

    while pending or running:
        while pending and len(running) < parallel:
            entry = pending.popleft()
            running.append((entry, start_case(entry)))

        still_running: list[tuple[dict[str, Any], subprocess.Popen[str]]] = []
        for entry, process in running:
            if process.poll() is None:
                still_running.append((entry, process))
            else:
                results.append(finish_case(entry, process))
        running = still_running
        if pending or running:
            time.sleep(5)

    failures = [result for result in results if result["status"] != "pass"]
    report = {
        "project": "gentoo-ai-installer",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "run_dir": str(run_dir),
        "result": "FAIL" if failures else "PASS",
        "parallelism": parallel,
        "entries": results,
        "safety": {
            "host_block_devices": "forbidden",
            "guest_install_disk": "/dev/vda",
            "reset_required": "VM_E2E_RESET_DISK=yes",
            "cleanup_confirmation": "I_UNDERSTAND_CLEANUP_DELETE=DELETE",
            "install_confirmation": "I_UNDERSTAND_THIS_WIPES_DISK=yes",
            "bootloader_confirmation": "I_UNDERSTAND_BOOTLOADER_CHANGES=yes",
        },
    }
    write_json(run_dir / "matrix-e2e.json", report)
    write_json(Path(config["log_root"]) / "latest-matrix-e2e.json", report)

    print("Libvirt E2E matrix summary")
    print(f"  report: {run_dir / 'matrix-e2e.json'}")
    print(f"  result: {report['result']}")
    for result in results:
        print(
            f"  {result['case']}: {result['status']} "
            f"run_id={result.get('run_id', '')} first_boot={result.get('first_boot_status', '')} log={result['log']}"
        )
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
