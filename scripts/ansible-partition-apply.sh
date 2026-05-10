#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-partition-apply
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
CONFIG_DESTRUCTIVE=yes CONFIG_REQUIRE_INSTALL_DISK=yes scripts/config-check.sh
require_ansible_live_target partition

[[ -n "${INSTALL_DISK:-}" ]] || die "INSTALL_DISK is required for partition and has no default"
assert_install_disk_input "$INSTALL_DISK"

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

confirm_wipe_disk=${I_UNDERSTAND_THIS_WIPES_DISK:-}

printf 'Applying GPT partition layout for %s/%s to %s on %s@%s port %s\n' "$profile" "$filesystem" "$INSTALL_DISK" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf '%s\n' 'This target partitions only. It does not format, mount, chroot, install packages, or install a bootloader.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${INSTALL_DISK}" \
  -e "confirm_wipe_disk=${confirm_wipe_disk}" \
  ansible/playbooks/partition-apply.yml
