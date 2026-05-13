#!/usr/bin/env python3
"""Inspect and prepare non-secret gentoo-ai-installer install state."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import sys
from pathlib import Path
from typing import Any


DEFAULT_STATE_FILE = Path("var/state/current-install.json")
DEFAULT_PHASE_CONTRACTS_FILE = Path("config/install-phases.json")
SECRET_KEY_RE = re.compile(
    r"(api[_-]?key|access[_-]?token|refresh[_-]?token|private[_-]?key|password|passwd)",
    re.IGNORECASE,
)


def load_phase_contracts(path: Path) -> dict[str, Any]:
    if path.is_absolute():
        die("PHASE_CONTRACT_INVALID", f"phase contracts path must be project-relative: {path}")
    if ".." in path.parts:
        die("PHASE_CONTRACT_INVALID", f"phase contracts path must not contain parent traversal: {path}")
    if not path.is_file() or path.is_symlink():
        die("PHASE_CONTRACT_INVALID", f"phase contracts file is missing or unsafe: {path}")
    try:
        contracts = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die("PHASE_CONTRACT_INVALID", f"phase contracts file is not valid JSON: {path}: {exc}")
    if not isinstance(contracts, dict):
        die("PHASE_CONTRACT_INVALID", "phase contracts file must contain a JSON object")
    phase_order = contracts.get("phase_order")
    phases = contracts.get("phases")
    if not isinstance(phase_order, list) or not phase_order:
        die("PHASE_CONTRACT_INVALID", "phase contracts must define a non-empty phase_order list")
    if not isinstance(phases, dict) or not phases:
        die("PHASE_CONTRACT_INVALID", "phase contracts must define phases")
    for phase_id in phase_order:
        if not isinstance(phase_id, str) or phase_id not in phases:
            die("PHASE_CONTRACT_INVALID", f"phase_order references missing phase: {phase_id}")
    for phase_id, contract in phases.items():
        if not isinstance(contract, dict):
            die("PHASE_CONTRACT_INVALID", f"phase contract must be an object: {phase_id}")
        for required_key in (
            "make_target",
            "risk",
            "preconditions",
            "required_variables",
            "required_confirmations",
            "completion_evidence",
            "validation",
            "skip_criteria",
            "rerun_criteria",
            "recovery_advice",
        ):
            if required_key not in contract:
                die("PHASE_CONTRACT_INVALID", f"phase {phase_id} is missing {required_key}")
    return contracts


def shell_join(items: list[str]) -> str:
    return "; ".join(str(item) for item in items if str(item))


def confirmation_present(confirmation: str) -> bool:
    if "=" not in confirmation:
        return bool(os.environ.get(confirmation))
    name, expected = confirmation.split("=", 1)
    return os.environ.get(name, "") == expected


def state_install_disk(state: dict[str, Any]) -> str:
    checkpoint = state.get("resume_checkpoint")
    selected_disk: dict[str, Any] = {}
    if isinstance(checkpoint, dict):
        maybe_disk = checkpoint.get("selected_disk")
        if isinstance(maybe_disk, dict):
            selected_disk = maybe_disk
    return str(state.get("install_disk") or (checkpoint or {}).get("install_disk") or selected_disk.get("path") or "")


def sorted_completed_phases(state: dict[str, Any], phase_order: list[str]) -> tuple[list[str], list[str]]:
    completed = state.get("completed_phases")
    if not isinstance(completed, list):
        completed = []
    completed_set = {str(item) for item in completed}
    ordered = [phase_id for phase_id in phase_order if phase_id in completed_set]
    unknown = sorted(item for item in completed_set if item not in set(phase_order) and item != "resume-plan")
    return ordered, unknown


def build_resume_plan(state: dict[str, Any], contracts: dict[str, Any]) -> dict[str, Any]:
    phase_order = [str(item) for item in contracts["phase_order"]]
    phases: dict[str, Any] = contracts["phases"]
    completed, unknown_completed = sorted_completed_phases(state, phase_order)
    completed_set = set(completed)
    checkpoints = state.get("checkpoints") if isinstance(state.get("checkpoints"), dict) else {}
    resume_checkpoint = state.get("resume_checkpoint") if isinstance(state.get("resume_checkpoint"), dict) else {}
    recorded_install_disk = state_install_disk(state)
    env_install_disk = os.environ.get("INSTALL_DISK", "")
    install_disk = recorded_install_disk or env_install_disk
    run_id = str(state.get("run_id") or "")
    profile = str(state.get("profile") or "")
    filesystem = str(state.get("filesystem") or "")
    stage3_flavor = str(state.get("stage3_flavor") or "standard")
    boot_mode = str(state.get("boot_mode") or "")
    manual_interventions = state.get("manual_interventions")
    if not isinstance(manual_interventions, list):
        manual_interventions = []

    missing_checkpoints: list[str] = []
    missing_evidence: list[str] = []
    for phase_id in completed:
        checkpoint = checkpoints.get(phase_id)
        if not isinstance(checkpoint, dict):
            missing_checkpoints.append(phase_id)
            continue
        evidence_paths = checkpoint.get("evidence_paths")
        if isinstance(evidence_paths, list):
            for evidence_path in evidence_paths:
                evidence = Path(str(evidence_path))
                if evidence.is_absolute() or ".." in evidence.parts:
                    missing_evidence.append(f"{phase_id}: unsafe evidence path {evidence_path}")
                    continue
                if not evidence.exists():
                    risk = str(phases[phase_id].get("risk", ""))
                    if risk in {"destructive", "high", "medium-high"}:
                        missing_evidence.append(f"{phase_id}: missing evidence {evidence_path}")

    next_phase = ""
    for phase_id in phase_order:
        if phase_id not in completed_set:
            next_phase = phase_id
            break

    next_contract = phases.get(next_phase, {}) if next_phase else {}
    required_variables = [str(item) for item in next_contract.get("required_variables", [])]
    required_confirmations = [str(item) for item in next_contract.get("required_confirmations", [])]
    missing_variables: list[str] = []
    for variable in required_variables:
        if variable == "INSTALL_DISK":
            if not install_disk:
                missing_variables.append(variable)
        elif not os.environ.get(variable):
            missing_variables.append(variable)

    missing_confirmations = [item for item in required_confirmations if not confirmation_present(item)]

    mismatches: list[str] = []
    if missing_checkpoints:
        mismatches.append("missing checkpoint for completed phases: " + ", ".join(missing_checkpoints))
    if missing_evidence:
        mismatches.extend(missing_evidence)
    if unknown_completed:
        mismatches.append("unknown completed phases in state: " + ", ".join(unknown_completed))
    if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,96}", run_id) or ".." in run_id:
        mismatches.append("state run_id is missing or unsafe")
    if not profile:
        mismatches.append("state is missing profile")
    if filesystem not in {"ext4", "btrfs"}:
        mismatches.append("state filesystem must be ext4 or btrfs")
    if stage3_flavor not in {"standard", "hardened", "musl"}:
        mismatches.append("state stage3_flavor must be standard, hardened, or musl")
    if boot_mode and boot_mode != "uefi":
        mismatches.append("state boot_mode must be uefi for v1")
    if recorded_install_disk and env_install_disk and recorded_install_disk != env_install_disk:
        mismatches.append(
            f"INSTALL_DISK differs from recorded state: environment={env_install_disk} state={recorded_install_disk}"
        )

    manual_revalidation_required = bool(state.get("manual_intervention_requires_revalidation"))
    blockers = list(mismatches)
    if missing_variables:
        blockers.append("missing required variables for next phase: " + ", ".join(missing_variables))
    if missing_confirmations:
        blockers.append("missing required confirmations for next phase: " + ", ".join(missing_confirmations))
    if manual_revalidation_required:
        blockers.append("manual intervention requires successful read-only revalidation before resume execution")

    run_disk_safety = bool(install_disk and next_phase not in {"live-preflight", "disk-detection", "install-plan"})
    requires_disk_safety = bool(run_disk_safety and resume_checkpoint and next_phase != "disk-safety")
    execution_allowed = bool(next_phase and not blockers)
    if not next_phase:
        blockers.append("all known phases are complete")
        execution_allowed = False

    return {
        "schema_version": 1,
        "run_id": run_id,
        "state_file": str(state.get("current_state_file") or ""),
        "profile": profile,
        "filesystem": filesystem,
        "stage3_flavor": stage3_flavor,
        "boot_mode": boot_mode,
        "install_disk": install_disk,
        "recorded_install_disk": recorded_install_disk,
        "completed_phases": completed,
        "unknown_completed_phases": unknown_completed,
        "last_completed_phase": state.get("last_completed_phase") or "",
        "manual_interventions": manual_interventions,
        "manual_intervention_requires_revalidation": manual_revalidation_required,
        "mismatches": mismatches,
        "next_phase": next_phase,
        "next_make_target": str(next_contract.get("make_target") or ""),
        "next_risk": str(next_contract.get("risk") or ""),
        "required_variables": required_variables,
        "required_confirmations": required_confirmations,
        "missing_variables": missing_variables,
        "missing_confirmations": missing_confirmations,
        "requires_disk_safety_checkpoint": requires_disk_safety,
        "run_disk_safety_validation": run_disk_safety,
        "resume_checkpoint_available": bool(resume_checkpoint),
        "resume_execution_allowed": execution_allowed,
        "blockers": blockers,
        "operator_instruction": (
            f"Run make {next_contract.get('make_target')} for phase {next_phase}, then rerun make install-resume-plan."
            if execution_allowed
            else "Resolve blockers, rerun make install-resume-plan, then use make install-resume for one planner-approved phase."
        ),
        "phase_contract": next_contract,
    }
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
    print(f"Stage3 flavor: {state.get('stage3_flavor') or 'standard'}")
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
    stage3_flavor = state.get("stage3_flavor") or checkpoint.get("stage3_flavor") or "standard"
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
        "INSTALL_STATE_STAGE3_FLAVOR": str(stage3_flavor),
        "INSTALL_STATE_LAST_PHASE": str(state.get("last_completed_phase") or ""),
        "INSTALL_STATE_MANUAL_REVALIDATION_REQUIRED": "yes" if state.get("manual_intervention_requires_revalidation") else "no",
    }
    for key, value in values.items():
        print(f"{key}={shlex.quote(value)}")


def print_resume_plan_human(plan: dict[str, Any]) -> None:
    print("Install resume plan")
    print(f"Run id: {plan['run_id'] or '<unknown>'}")
    print(f"Profile: {plan['profile'] or '<unset>'}")
    print(f"Filesystem: {plan['filesystem'] or '<unset>'}")
    print(f"Stage3 flavor: {plan['stage3_flavor'] or 'standard'}")
    print(f"Boot mode: {plan['boot_mode'] or '<unset>'}")
    print(f"Install disk: {plan['install_disk'] or '<unset>'}")
    completed = plan.get("completed_phases") or []
    print(f"Completed phases: {', '.join(completed) if completed else '<none>'}")
    manual_interventions = plan.get("manual_interventions") or []
    print(f"Manual interventions: {len(manual_interventions)}")
    for manual_path in manual_interventions:
        print(f"  - {manual_path}")
    print(f"Manual revalidation required: {'yes' if plan.get('manual_intervention_requires_revalidation') else 'no'}")
    print(f"Resume checkpoint: {'available' if plan.get('resume_checkpoint_available') else 'missing'}")
    print(f"Next safe phase: {plan['next_phase'] or '<none>'}")
    print(f"Next make target: {plan['next_make_target'] or '<none>'}")
    print(f"Next phase risk: {plan['next_risk'] or '<unknown>'}")
    print(
        "Required variables: "
        + (", ".join(plan.get("required_variables") or []) if plan.get("required_variables") else "<none>")
    )
    print(
        "Required confirmations: "
        + (", ".join(plan.get("required_confirmations") or []) if plan.get("required_confirmations") else "<none>")
    )
    mismatches = plan.get("mismatches") or []
    print(f"Mismatches: {shell_join(mismatches) if mismatches else '<none>'}")
    blockers = plan.get("blockers") or []
    print(f"Resume execution allowed: {'yes' if plan.get('resume_execution_allowed') else 'no'}")
    print(f"Blockers: {shell_join(blockers) if blockers else '<none>'}")
    print(f"Instruction: {plan.get('operator_instruction') or '<none>'}")
    print("Resume policy: one phase only; destructive confirmations are never inferred from state.")


def print_resume_plan_shell(plan: dict[str, Any]) -> None:
    values = {
        "INSTALL_RESUME_RUN_ID": str(plan.get("run_id") or ""),
        "INSTALL_RESUME_PROFILE": str(plan.get("profile") or ""),
        "INSTALL_RESUME_FILESYSTEM": str(plan.get("filesystem") or ""),
        "INSTALL_RESUME_STAGE3_FLAVOR": str(plan.get("stage3_flavor") or "standard"),
        "INSTALL_RESUME_INSTALL_DISK": str(plan.get("install_disk") or ""),
        "INSTALL_RESUME_NEXT_PHASE": str(plan.get("next_phase") or ""),
        "INSTALL_RESUME_NEXT_TARGET": str(plan.get("next_make_target") or ""),
        "INSTALL_RESUME_NEXT_RISK": str(plan.get("next_risk") or ""),
        "INSTALL_RESUME_ALLOWED": "yes" if plan.get("resume_execution_allowed") else "no",
        "INSTALL_RESUME_RUN_DISK_SAFETY": "yes" if plan.get("run_disk_safety_validation") else "no",
        "INSTALL_RESUME_REQUIRES_DISK_SAFETY": "yes" if plan.get("requires_disk_safety_checkpoint") else "no",
        "INSTALL_RESUME_HAS_CHECKPOINT": "yes" if plan.get("resume_checkpoint_available") else "no",
        "INSTALL_RESUME_MISMATCHES": shell_join(plan.get("mismatches") or []),
        "INSTALL_RESUME_BLOCKERS": shell_join(plan.get("blockers") or []),
        "INSTALL_RESUME_REQUIRED_CONFIRMATIONS": shell_join(plan.get("required_confirmations") or []),
    }
    for key, value in values.items():
        print(f"{key}={shlex.quote(value)}")


def command_resume_plan(args: argparse.Namespace) -> None:
    state = load_state(args.state_file, required=True)
    assert state is not None
    contracts = load_phase_contracts(args.phase_contracts)
    plan = build_resume_plan(state, contracts)
    if args.format == "json":
        print(json.dumps(plan, indent=2, sort_keys=True))
    elif args.format == "shell":
        print_resume_plan_shell(plan)
    else:
        print_resume_plan_human(plan)


def command_phase_contracts(args: argparse.Namespace) -> None:
    contracts = load_phase_contracts(args.phase_contracts)
    if args.format == "json":
        print(json.dumps(contracts, indent=2, sort_keys=True))
        return
    print(f"Phase contract schema: {contracts.get('schema_version')}")
    for phase_id in contracts["phase_order"]:
        contract = contracts["phases"][phase_id]
        print(f"{phase_id}: target={contract['make_target']} risk={contract['risk']}")


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
    parser.add_argument("--phase-contracts", type=Path, default=DEFAULT_PHASE_CONTRACTS_FILE)
    subparsers = parser.add_subparsers(dest="command", required=True)

    show_parser = subparsers.add_parser("show", help="Show current install state summary")
    show_parser.set_defaults(func=command_show)

    resume_parser = subparsers.add_parser("resume-vars", help="Print shell variables for resume validation")
    resume_parser.set_defaults(func=command_resume_vars)

    resume_plan_parser = subparsers.add_parser("resume-plan", help="Print the read-only resume plan from saved state")
    resume_plan_parser.add_argument("--format", choices=["human", "json", "shell"], default="human")
    resume_plan_parser.set_defaults(func=command_resume_plan)

    contracts_parser = subparsers.add_parser("phase-contracts", help="Show resumable install phase contracts")
    contracts_parser.add_argument("--format", choices=["human", "json"], default="human")
    contracts_parser.set_defaults(func=command_phase_contracts)

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
