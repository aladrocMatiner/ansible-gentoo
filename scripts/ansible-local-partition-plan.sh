#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-local-partition-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

require_command ansible-playbook

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die_code CONFIG_INVALID "PROFILE must be 'openrc' or 'systemd', got: $profile" ;;
esac

filesystem=${FILESYSTEM:-ext4}
case "$filesystem" in
  ext4|btrfs) ;;
  *) die_code CONFIG_INVALID "FILESYSTEM must be 'ext4' or 'btrfs', got: $filesystem" ;;
esac

[[ -n "${INSTALL_DISK:-}" ]] || die_code DISK_UNSAFE "INSTALL_DISK is required for local-partition-plan and has no default"
assert_install_disk_input "$INSTALL_DISK"

printf 'Generating read-only local %s/%s partition plan for %s with ansible_connection=local\n' "$profile" "$filesystem" "$INSTALL_DISK"
ansible-playbook \
  -i ansible/inventory/local.yml \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${INSTALL_DISK}" \
  -e "install_state_disabled=${INSTALL_STATE_DISABLED:-false}" \
  ansible/playbooks/partition-plan.yml
