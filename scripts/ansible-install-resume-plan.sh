#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-resume-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
require_command python3
require_ansible_live_target install-resume-plan

state_file=${INSTALL_STATE_FILE:-var/state/current-install.json}
plan_vars=$(scripts/install-state.py --state-file "$state_file" resume-plan --format shell) || exit $?
eval "$plan_vars"

if [[ -n "${INSTALL_RESUME_INSTALL_DISK:-}" ]]; then
  assert_install_disk_input "$INSTALL_RESUME_INSTALL_DISK"
fi

case "$INSTALL_RESUME_PROFILE" in
  openrc|systemd) ;;
  *) die "install state PROFILE/profile must be 'openrc' or 'systemd', got: $INSTALL_RESUME_PROFILE" ;;
esac

case "$INSTALL_RESUME_FILESYSTEM" in
  ext4|btrfs) ;;
  *) die "install state FILESYSTEM/filesystem must be 'ext4' or 'btrfs', got: $INSTALL_RESUME_FILESYSTEM" ;;
esac

case "${INSTALL_RESUME_STAGE3_FLAVOR:-standard}" in
  standard|hardened|musl) ;;
  *) die "install state STAGE3_FLAVOR/stage3_flavor must be 'standard', 'hardened', or 'musl', got: ${INSTALL_RESUME_STAGE3_FLAVOR}" ;;
esac

printf 'Validating install resume plan for run %s\n' "$INSTALL_RESUME_RUN_ID"
printf 'Install disk from state: %s\n' "${INSTALL_RESUME_INSTALL_DISK:-<unset>}"
printf 'Profile/filesystem/stage3 flavor from state: %s/%s/%s\n' "$INSTALL_RESUME_PROFILE" "$INSTALL_RESUME_FILESYSTEM" "${INSTALL_RESUME_STAGE3_FLAVOR:-standard}"
printf 'Next phase candidate: %s via make %s\n' "${INSTALL_RESUME_NEXT_PHASE:-<none>}" "${INSTALL_RESUME_NEXT_TARGET:-<none>}"
printf 'Resume execution currently allowed: %s\n' "$INSTALL_RESUME_ALLOWED"
if [[ -n "${INSTALL_RESUME_BLOCKERS:-}" ]]; then
  printf 'Resume blockers: %s\n' "$INSTALL_RESUME_BLOCKERS"
fi
printf '%s\n' 'This target is read-only for the live ISO target.'
printf '%s\n' 'Resume validation does not satisfy destructive confirmations for later targets.'
scripts/install-state.py --state-file "$state_file" resume-plan

ssh_common_args=$(ansible_ssh_common_args)
export INSTALL_RESUME_BLOCKERS INSTALL_RESUME_MISMATCHES

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="$ssh_common_args" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "install_state_checkpoint_file=${state_file}" \
  -e "install_run_id=${INSTALL_RESUME_RUN_ID}" \
  -e "install_disk=${INSTALL_RESUME_INSTALL_DISK}" \
  -e "profile=${INSTALL_RESUME_PROFILE}" \
  -e "filesystem=${INSTALL_RESUME_FILESYSTEM}" \
  -e "stage3_flavor=${INSTALL_RESUME_STAGE3_FLAVOR:-standard}" \
  -e "resume_plan_next_phase=${INSTALL_RESUME_NEXT_PHASE}" \
  -e "resume_plan_next_target=${INSTALL_RESUME_NEXT_TARGET}" \
  -e "resume_plan_execution_allowed=${INSTALL_RESUME_ALLOWED}" \
  -e "resume_plan_run_disk_safety=${INSTALL_RESUME_RUN_DISK_SAFETY}" \
  -e "resume_plan_requires_disk_safety=${INSTALL_RESUME_REQUIRES_DISK_SAFETY}" \
  ansible/playbooks/install-resume-plan.yml
