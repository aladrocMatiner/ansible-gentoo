#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-destructive-safety-check
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
CONFIG_DESTRUCTIVE=yes CONFIG_REQUIRE_INSTALL_DISK=yes scripts/config-check.sh
require_ansible_live_target destructive-safety-check

[[ -n "${INSTALL_DISK:-}" ]] || die "INSTALL_DISK is required for destructive-safety-check and has no default"
assert_install_disk_input "$INSTALL_DISK"

confirm_wipe_disk=${I_UNDERSTAND_THIS_WIPES_DISK:-}

printf 'Running read-only destructive safety gate check for %s against %s@%s port %s\n' "$INSTALL_DISK" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "install_disk=${INSTALL_DISK}" \
  -e "confirm_wipe_disk=${confirm_wipe_disk}" \
  ansible/playbooks/destructive-safety-check.yml
