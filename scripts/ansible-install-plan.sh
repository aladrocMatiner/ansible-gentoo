#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
require_ansible_live_target install-plan

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die "PROFILE must be 'openrc' or 'systemd', got: $profile" ;;
esac

filesystem=${FILESYSTEM:-ext4}
case "$filesystem" in
  ext4|btrfs) ;;
  *) die "FILESYSTEM must be 'ext4' or 'btrfs', got: $filesystem" ;;
esac

stage3_flavor=${STAGE3_FLAVOR:-standard}
case "$stage3_flavor" in
  standard|hardened|musl) ;;
  *) die "STAGE3_FLAVOR must be 'standard', 'hardened', or 'musl', got: $stage3_flavor" ;;
esac

extra_vars=(
  -e "ansible_host=${ANSIBLE_LIVE_HOST}"
  -e "ansible_port=${ANSIBLE_LIVE_PORT}"
  -e "profile=${profile}"
  -e "filesystem=${filesystem}"
  -e "stage3_flavor=${stage3_flavor}"
)

if [[ -n "${INSTALL_DISK:-}" ]]; then
  assert_install_disk_input "$INSTALL_DISK"
  extra_vars+=(-e "install_disk=${INSTALL_DISK}")
fi

printf 'Generating read-only %s/%s/%s install plan against %s@%s port %s\n' "$profile" "$filesystem" "$stage3_flavor" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
if [[ -n "${INSTALL_DISK:-}" ]]; then
  printf 'Using explicit read-only INSTALL_DISK planning input: %s\n' "$INSTALL_DISK"
else
  printf '%s\n' 'No INSTALL_DISK provided; the plan will not select a disk.'
fi

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  "${extra_vars[@]}" \
  ansible/playbooks/install-plan.yml
