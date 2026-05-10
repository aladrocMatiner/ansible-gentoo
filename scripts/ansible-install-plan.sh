#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
validate_vm_config
eval "$(scripts/vm-ssh-target.sh env)"

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

extra_vars=(
  -e "ansible_host=${ANSIBLE_LIVE_HOST}"
  -e "ansible_port=${ANSIBLE_LIVE_PORT}"
  -e "profile=${profile}"
  -e "filesystem=${filesystem}"
)

if [[ -n "${INSTALL_DISK:-}" ]]; then
  extra_vars+=(-e "install_disk=${INSTALL_DISK}")
fi

printf 'Generating read-only %s/%s install plan against %s@%s port %s\n' "$profile" "$filesystem" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
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
