#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-resume
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command make
require_command python3

state_file=${INSTALL_STATE_FILE:-var/state/current-install.json}

printf '%s\n' 'Preparing read-only resume plan before executing any phase.'
scripts/ansible-install-resume-plan.sh

plan_vars=$(scripts/install-state.py --state-file "$state_file" resume-plan --format shell) || exit $?
eval "$plan_vars"

if [[ "${INSTALL_RESUME_ALLOWED:-no}" != yes ]]; then
  if [[ -n "${INSTALL_RESUME_BLOCKERS:-}" ]]; then
    die "install resume is blocked: ${INSTALL_RESUME_BLOCKERS}"
  fi
  die "install resume is blocked; run make install-resume-plan for details"
fi

case "${INSTALL_RESUME_NEXT_TARGET:-}" in
  ansible-live-preflight|detect-disks|destructive-safety-check|install-plan|partition-plan|partition|filesystem-plan|format|mount-plan|mount-target|stage3-install|prepare-chroot|configure-portage|configure-system|generate-fstab|install-kernel|install-system-packages|configure-users|install-bootloader|final-checks) ;;
  *) die "resume planner returned an unsupported target: ${INSTALL_RESUME_NEXT_TARGET:-<empty>}" ;;
esac

if [[ -n "${INSTALL_RESUME_INSTALL_DISK:-}" ]]; then
  assert_install_disk_input "$INSTALL_RESUME_INSTALL_DISK"
  export INSTALL_DISK="$INSTALL_RESUME_INSTALL_DISK"
fi
export PROFILE="$INSTALL_RESUME_PROFILE"
export FILESYSTEM="$INSTALL_RESUME_FILESYSTEM"
export STAGE3_FLAVOR="$INSTALL_RESUME_STAGE3_FLAVOR"
export INSTALL_STATE_FILE="$state_file"
export INSTALL_RUN_ID="$INSTALL_RESUME_RUN_ID"

printf 'Executing one resume phase: %s via make %s\n' "$INSTALL_RESUME_NEXT_PHASE" "$INSTALL_RESUME_NEXT_TARGET"
printf '%s\n' 'Resume execution stops after this one phase; rerun make install-resume-plan before continuing.'
make --no-print-directory "$INSTALL_RESUME_NEXT_TARGET"
printf 'Resume phase complete: %s\n' "$INSTALL_RESUME_NEXT_PHASE"
printf '%s\n' 'Next step: rerun make install-resume-plan before any further resume execution.'
