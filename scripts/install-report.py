#!/usr/bin/env python3
"""Generate a secret-safe human-readable install report summary."""

from __future__ import annotations

import argparse
import json
import re
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


def die(code: str, message: str) -> None:
    print(f"install-report: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_project_relative(path: Path, root: tuple[str, ...], label: str) -> None:
    if path.is_absolute():
        die("INSTALL_REPORT_INVALID", f"{label} must be project-relative: {path}")
    if ".." in path.parts:
        die("INSTALL_REPORT_INVALID", f"{label} must not contain parent traversal: {path}")
    if path.parts[: len(root)] != root:
        die("INSTALL_REPORT_INVALID", f"{label} must stay under {'/'.join(root)}: {path}")

    current = Path()
    for part in path.parts[:-1]:
        current = current / part
        if current.is_symlink():
            die("INSTALL_REPORT_INVALID", f"{label} path component must not be a symlink: {current}")


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


def load_json(path: Path, *, required: bool, label: str, allow_boolean_secret_keys: bool = False) -> dict[str, Any]:
    if not path.exists():
        if required:
            die("INSTALL_REPORT_INVALID", f"{label} is missing: {path}")
        return {}
    if not path.is_file() or path.is_symlink():
        die("INSTALL_REPORT_INVALID", f"{label} must be a regular file: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("INSTALL_REPORT_INVALID", f"{label} is not valid JSON: {path}: {exc}")
    if not isinstance(data, dict):
        die("INSTALL_REPORT_INVALID", f"{label} must contain a JSON object: {path}")
    secret_hits = find_secret_like_fields(data, allow_boolean_status=allow_boolean_secret_keys)
    if secret_hits:
        die("INSTALL_REPORT_SECRET_RISK", f"{label} contains secret-like fields or values: {', '.join(secret_hits[:8])}")
    return data


def safe_run_dir(run_id: str) -> Path:
    if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,80}", run_id):
        die("INSTALL_REPORT_INVALID", f"run id is unsafe: {run_id}")
    run_dir = Path("logs") / "install-runs" / run_id
    validate_project_relative(run_dir / "state.json", ("logs", "install-runs"), "run directory")
    if not run_dir.is_dir() or run_dir.is_symlink():
        die("INSTALL_REPORT_INVALID", f"run directory is missing or unsafe: {run_dir}")
    return run_dir


def value_or_unavailable(value: Any) -> str:
    if value is None or value == "":
        return "unavailable"
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, list):
        return ", ".join(str(item) for item in value) if value else "none"
    return str(value)


def status_line(label: str, value: Any) -> str:
    return f"- {label}: {value_or_unavailable(value)}"


def boot_cmdline_status(cmdline: str, filesystem: str) -> str:
    if not cmdline:
        return "unavailable"
    checks = [
        ("root UUID", "pass" if "root=UUID=" in cmdline else "fail"),
        ("no /dev root", "pass" if "/dev/" not in cmdline else "fail"),
    ]
    if filesystem == "btrfs":
        checks.append(("Btrfs rootflags", "pass" if "rootflags=subvol=@" in cmdline else "fail"))
    return ", ".join(f"{name}: {result}" for name, result in checks)


def audit_bundle_status(run_dir: Path) -> tuple[str, str]:
    manifest_path = run_dir / "audit-bundle" / "manifest.json"
    if not manifest_path.exists():
        return ("unavailable", "Run `make install-audit` after final checks or a completed run.")
    manifest = load_json(manifest_path, required=False, label="audit manifest", allow_boolean_secret_keys=True)
    included = manifest.get("included_evidence")
    missing = manifest.get("missing_evidence")
    included_count = len(included) if isinstance(included, list) else "unavailable"
    missing_count = len(missing) if isinstance(missing, list) else "unavailable"
    return (str(manifest_path), f"included evidence: {included_count}; missing optional evidence: {missing_count}")


def load_evidence(run_dir: Path) -> dict[str, dict[str, Any]]:
    paths = {
        "identity": "system-config/identity.json",
        "fstab": "fstab/fstab.json",
        "kernel": "kernel/kernel.json",
        "packages": "system-packages/packages-services.json",
        "users": "users/users-access.json",
        "bootloader": "bootloader/grub.json",
        "final": "final-checks/reboot-readiness.json",
        "portage": "portage/baseline.json",
        "first_boot": "first-boot/validation.json",
    }
    evidence: dict[str, dict[str, Any]] = {}
    for key, relative in paths.items():
        evidence[key] = load_json(
            run_dir / relative,
            required=False,
            label=f"{key} evidence",
            allow_boolean_secret_keys=True,
        )
    return evidence


def render_report(state: dict[str, Any], run_dir: Path, evidence: dict[str, dict[str, Any]]) -> str:
    run_id = str(state.get("run_id") or "")
    filesystem = str(state.get("filesystem") or evidence["final"].get("filesystem") or evidence["fstab"].get("filesystem") or "")
    audit_path, audit_detail = audit_bundle_status(run_dir)
    identity = evidence["identity"]
    final = evidence["final"]
    fstab = evidence["fstab"]
    kernel = evidence["kernel"]
    packages = evidence["packages"]
    users = evidence["users"]
    bootloader = evidence["bootloader"]
    portage = evidence["portage"]
    first_boot = evidence["first_boot"]
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    cmdline = str(final.get("kernel_cmdline") or kernel.get("kernel_cmdline") or bootloader.get("kernel_cmdline") or "")
    services = final.get("services") if isinstance(final.get("services"), list) else packages.get("services")
    service_names = []
    if isinstance(services, list):
        for item in services:
            if isinstance(item, dict):
                service_names.append(str(item.get("name") or item))
            else:
                service_names.append(str(item))

    sections = [
        "# Gentoo Install Report",
        "",
        "## Run",
        status_line("project", state.get("project") or "gentoo-ai-installer"),
        status_line("run id", run_id),
        status_line("generated at", generated_at),
        status_line("updated at", state.get("updated_at")),
        status_line("last completed phase", state.get("last_completed_phase")),
        status_line("completed phases", state.get("completed_phases") if isinstance(state.get("completed_phases"), list) else []),
        "",
        "## Target",
        status_line("profile/init", state.get("profile") or final.get("profile") or identity.get("profile")),
        status_line("filesystem", filesystem),
        status_line("boot mode", state.get("boot_mode")),
        status_line("install disk", state.get("install_disk") or fstab.get("install_disk") or bootloader.get("install_disk")),
        status_line("target root", state.get("target_mount")),
        status_line("EFI mount", state.get("efi_mount") or bootloader.get("efi_mount")),
        "",
        "## Identity",
        status_line("hostname", identity.get("hostname") or final.get("hostname")),
        status_line("timezone", identity.get("timezone") or final.get("timezone")),
        status_line("locale", identity.get("locale") or final.get("locale")),
        status_line("keymap", identity.get("keymap") or final.get("keymap")),
        "",
        "## Filesystems",
        status_line("root UUID", fstab.get("root_uuid") or final.get("root_uuid")),
        status_line("EFI UUID", fstab.get("efi_uuid")),
        status_line("fstab entries", [entry.get("mountpoint") for entry in fstab.get("entries", [])] if isinstance(fstab.get("entries"), list) else []),
        "",
        "## Kernel And Boot",
        status_line("kernel artifacts", final.get("kernel_artifacts") or kernel.get("kernel_artifacts")),
        status_line("module directories", final.get("module_directories") or kernel.get("module_directories")),
        status_line("kernel command line", cmdline),
        status_line("command line policy", boot_cmdline_status(cmdline, filesystem)),
        status_line("bootloader", (bootloader.get("bootloader_id") or "grub") if bootloader else ""),
        status_line("GRUB install ran", bootloader.get("grub_install_ran")),
        status_line("GRUB config changed", bootloader.get("grub_config_changed")),
        "",
        "## Network, Time, And Access",
        status_line("network manager policy", packages.get("network_manager_policy") or "NetworkManager"),
        status_line("enabled services", service_names),
        status_line("time sync", final.get("time_sync") or packages.get("time_sync_policy")),
        status_line("SSH enabled", packages.get("ssh_policy_enabled") if "ssh_policy_enabled" in packages else final.get("enable_ssh")),
        status_line("SSH policy checked", final.get("ssh_policy_checked")),
        status_line("admin user", users.get("admin_user") or final.get("admin_user")),
        status_line("admin groups", users.get("admin_groups") or final.get("admin_groups")),
        status_line("privilege tool", users.get("privilege_tool")),
        status_line("admin sudo NOPASSWD", users.get("admin_sudo_nopasswd")),
        status_line("authorized keys installed", users.get("authorized_keys_installed")),
        status_line("admin password hash applied", users.get("admin_password_hash_applied")),
        status_line("root password hash applied", users.get("root_password_hash_applied")),
        "",
        "## Portage",
        status_line("selected profile", portage.get("selected_profile") or final.get("portage_profile")),
        status_line("COMMON_FLAGS", portage.get("common_flags")),
        status_line("USE flags", portage.get("use_flags")),
        status_line("repository sync rc", portage.get("repo_sync_rc")),
        status_line("world update run", portage.get("world_update_run")),
        status_line("pending config updates", final.get("pending_portage_config_updates") or portage.get("pending_config_updates")),
        "",
        "## Validation",
        status_line("final checks", final.get("status")),
        status_line("controller secret check", final.get("controller_secret_check")),
        status_line("first boot validation", first_boot.get("status")),
        status_line("audit bundle", audit_path),
        status_line("audit detail", audit_detail),
        "",
        "## Next Action",
        status_line("recommended action", state.get("next_safe_action") or next_action(final, first_boot)),
        "- not automated: physical reboot decision, firmware boot-order review on real hardware, and any manual recovery notes.",
        "",
    ]
    return "\n".join(sections)


def next_action(final: dict[str, Any], first_boot: dict[str, Any]) -> str:
    if first_boot.get("status") == "PASS":
        return "Archive evidence and proceed with post-install review."
    if final.get("status") == "PASS":
        return "Reboot into the installed disk, then run first-boot validation when available for the target."
    return "Run missing install phases, then run make final-checks and make install-audit."


def command_generate(args: argparse.Namespace) -> None:
    validate_project_relative(args.state_file, ("var", "state"), "state file")
    state = load_json(args.state_file, required=True, label="state file")
    run_id = str(state.get("run_id") or "")
    if not run_id:
        die("INSTALL_REPORT_INVALID", "state file does not contain run_id")
    run_dir = safe_run_dir(run_id)
    evidence = load_evidence(run_dir)
    report = render_report(state, run_dir, evidence)
    report_path = run_dir / "install-report.md"
    if report_path.is_symlink():
        die("INSTALL_REPORT_INVALID", f"report path must not be a symlink: {report_path}")
    report_path.write_text(report + "\n", encoding="utf-8")
    print(report)
    print(f"Report written: {report_path}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE)
    subparsers = parser.add_subparsers(dest="command", required=True)
    generate_parser = subparsers.add_parser("generate", help="Generate install report summary")
    generate_parser.set_defaults(func=command_generate)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
