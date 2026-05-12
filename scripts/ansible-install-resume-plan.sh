#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-resume-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
require_command python3
require_ansible_live_target install-resume-plan

resume_vars=$(scripts/install-state.py --state-file "${INSTALL_STATE_FILE:-var/state/current-install.json}" resume-vars) || exit $?
eval "$resume_vars"

assert_install_disk_input "$INSTALL_STATE_INSTALL_DISK"

case "$INSTALL_STATE_PROFILE" in
  openrc|systemd) ;;
  *) die "install state PROFILE/profile must be 'openrc' or 'systemd', got: $INSTALL_STATE_PROFILE" ;;
esac

case "$INSTALL_STATE_FILESYSTEM" in
  ext4|btrfs) ;;
  *) die "install state FILESYSTEM/filesystem must be 'ext4' or 'btrfs', got: $INSTALL_STATE_FILESYSTEM" ;;
esac

case "${INSTALL_STATE_STAGE3_FLAVOR:-standard}" in
  standard|hardened|musl) ;;
  *) die "install state STAGE3_FLAVOR/stage3_flavor must be 'standard', 'hardened', or 'musl', got: ${INSTALL_STATE_STAGE3_FLAVOR}" ;;
esac

printf 'Validating install resume plan for run %s\n' "$INSTALL_STATE_RUN_ID"
printf 'Last completed phase: %s\n' "$INSTALL_STATE_LAST_PHASE"
printf 'Install disk from state: %s\n' "$INSTALL_STATE_INSTALL_DISK"
printf 'Profile/filesystem/stage3 flavor from state: %s/%s/%s\n' "$INSTALL_STATE_PROFILE" "$INSTALL_STATE_FILESYSTEM" "${INSTALL_STATE_STAGE3_FLAVOR:-standard}"
if [[ "${INSTALL_STATE_MANUAL_REVALIDATION_REQUIRED:-no}" == "yes" ]]; then
  printf '%s\n' 'Manual intervention was recorded; this resume plan is the required revalidation step.'
fi
printf '%s\n' 'This target is read-only for the live ISO target.'
printf '%s\n' 'Resume validation does not satisfy destructive confirmations for later targets.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "install_state_checkpoint_file=${INSTALL_STATE_FILE}" \
  -e "install_run_id=${INSTALL_STATE_RUN_ID}" \
  -e "install_disk=${INSTALL_STATE_INSTALL_DISK}" \
  -e "profile=${INSTALL_STATE_PROFILE}" \
  -e "filesystem=${INSTALL_STATE_FILESYSTEM}" \
  -e "stage3_flavor=${INSTALL_STATE_STAGE3_FLAVOR:-standard}" \
  ansible/playbooks/install-resume-plan.yml
