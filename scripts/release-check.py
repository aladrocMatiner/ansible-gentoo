#!/usr/bin/env python3
"""Run project release readiness checks and write a local report."""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPORT_DIR = Path("logs/release-readiness")
REQUIRED_DOCS = [
    "README.md",
    "AGENTS.md",
    ".gitignore",
    "docs/ansible-architecture.md",
    "docs/libvirt-manual-install-test.md",
    "docs/libvirt-install-test-matrix.md",
    "docs/libvirt-end-to-end-install-validation.md",
    "docs/first-boot-validation.md",
    "docs/secret-input-policy.md",
    "docs/install-audit-bundle.md",
    "docs/install-report-summary.md",
    "docs/handbook-traceability.md",
    "docs/real-hardware-readiness.md",
    "docs/cleanup-reset-policy.md",
    "docs/supported-host-requirements.md",
    "docs/manual-escape-hatch-policy.md",
]
FORBIDDEN_TRACKED_PREFIXES = (
    "gentoo.iso/",
    "logs/",
    "tmp/",
    "var/state/",
    "var/secrets/",
    "var/libvirt/",
    "var/qemu/",
)
FORBIDDEN_TRACKED_SUFFIXES = (
    ".qcow2",
    ".fd",
    ".iso",
)


def run_command(name: str, command: list[str]) -> dict[str, Any]:
    result = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return {
        "name": name,
        "command": command,
        "returncode": result.returncode,
        "status": "pass" if result.returncode == 0 else "fail",
        "output": result.stdout[-12000:],
    }


def git_ls_files() -> list[str]:
    result = subprocess.run(["git", "ls-files"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git ls-files failed")
    return [line for line in result.stdout.splitlines() if line]


def check_docs() -> dict[str, Any]:
    missing = [path for path in REQUIRED_DOCS if not Path(path).is_file()]
    return {
        "status": "pass" if not missing else "fail",
        "missing": missing,
        "checked": REQUIRED_DOCS,
    }


def check_tracked_artifacts() -> dict[str, Any]:
    tracked = git_ls_files()
    forbidden: list[str] = []
    for path in tracked:
        if path == "gentoo.iso" or path.startswith(FORBIDDEN_TRACKED_PREFIXES):
            forbidden.append(path)
            continue
        if path.endswith(FORBIDDEN_TRACKED_SUFFIXES):
            forbidden.append(path)
            continue
        if path.startswith(".env") and path != ".env.example":
            forbidden.append(path)
    return {
        "status": "pass" if not forbidden else "fail",
        "forbidden_tracked_files": forbidden,
    }


def openspec_status() -> dict[str, Any]:
    result = subprocess.run(["openspec", "list", "--json"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode != 0:
        return {
            "status": "fail",
            "error": result.stderr.strip() or result.stdout.strip(),
        }
    data = json.loads(result.stdout)
    changes = data.get("changes", [])
    active_complete = [
        item["name"]
        for item in changes
        if item.get("status") == "complete"
    ]
    active_incomplete = [
        item["name"]
        for item in changes
        if item.get("status") != "complete"
    ]
    return {
        "status": "pass",
        "active_complete_changes": active_complete,
        "active_incomplete_changes": active_incomplete,
        "archive_policy": "completed changes may remain active until the operator runs the approved OpenSpec archive workflow",
    }


def main() -> None:
    REPORT_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    if REPORT_DIR.is_symlink() or not REPORT_DIR.is_dir():
        print(f"release-check: invalid report directory: {REPORT_DIR}", file=sys.stderr)
        raise SystemExit(1)

    checks: list[dict[str, Any]] = [
        run_command("make-help", ["make", "help"]),
        run_command("git-diff-check", ["git", "diff", "--check"]),
        run_command("secret-check", ["scripts/secret-check.sh"]),
        run_command("ansible-check", ["scripts/ansible-check.sh"]),
        run_command("openspec-all", ["openspec", "validate", "--all", "--strict"]),
    ]
    doc_check = check_docs()
    artifact_check = check_tracked_artifacts()
    spec_status = openspec_status()

    failed = [item["name"] for item in checks if item["status"] != "pass"]
    if doc_check["status"] != "pass":
        failed.append("required-docs")
    if artifact_check["status"] != "pass":
        failed.append("tracked-artifacts")
    if spec_status["status"] != "pass":
        failed.append("openspec-status")

    report = {
        "project": "gentoo-ai-installer",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "result": "FAIL" if failed else "PASS",
        "checks": checks,
        "required_docs": doc_check,
        "tracked_artifacts": artifact_check,
        "openspec_status": spec_status,
        "guardrail_status": {
            "audit_bundle": "documented",
            "secret_input_policy": "documented and checked by secret-check",
            "handbook_traceability": "documented and generated by make handbook-trace",
            "libvirt_matrix": "planned by make vm-test-matrix-plan; full disposable E2E validation implemented by make vm-e2e-matrix",
            "first_boot_validation": "implemented by make vm-validate-first-boot",
            "install_report": "implemented by make install-report",
            "real_hardware_readiness": "implemented by make real-hardware-check",
            "cleanup_reset": "implemented by cleanup targets",
            "supported_host_requirements": "implemented by make host-check",
            "manual_escape_hatch": "implemented by make record-manual-step",
        },
        "failed": failed,
    }
    report_path = REPORT_DIR / "latest.json"
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("Project release readiness")
    print(f"  report: {report_path}")
    print(f"  result: {report['result']}")
    print(f"  checks: {len(checks)} command checks, {len(REQUIRED_DOCS)} required docs")
    if spec_status.get("active_complete_changes"):
        print(f"  active complete OpenSpec changes: {len(spec_status['active_complete_changes'])}")
    if failed:
        print("  failed:")
        for item in failed:
            print(f"    - {item}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
