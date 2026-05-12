#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-local-install-plan
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

stage3_flavor=${STAGE3_FLAVOR:-standard}
case "$stage3_flavor" in
  standard|hardened|musl) ;;
  *) die_code CONFIG_INVALID "STAGE3_FLAVOR must be 'standard', 'hardened', or 'musl', got: $stage3_flavor" ;;
esac

extra_vars=(
  -e "profile=${profile}"
  -e "filesystem=${filesystem}"
  -e "stage3_flavor=${stage3_flavor}"
)

if [[ -n "${INSTALL_DISK:-}" ]]; then
  assert_install_disk_input "$INSTALL_DISK"
  extra_vars+=(-e "install_disk=${INSTALL_DISK}")
fi

printf 'Generating read-only local %s/%s/%s install plan with ansible_connection=local\n' "$profile" "$filesystem" "$stage3_flavor"
if [[ -n "${INSTALL_DISK:-}" ]]; then
  printf 'Using explicit read-only INSTALL_DISK planning input: %s\n' "$INSTALL_DISK"
else
  printf '%s\n' 'No INSTALL_DISK provided; the plan will not select a disk.'
fi

ansible-playbook \
  -i ansible/inventory/local.yml \
  "${extra_vars[@]}" \
  ansible/playbooks/install-plan.yml
