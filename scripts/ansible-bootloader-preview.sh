#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-bootloader-preview
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
CONFIG_REQUIRE_INSTALL_DISK=yes scripts/config-check.sh
require_ansible_live_target bootloader-preview

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

install_disk=${INSTALL_DISK:-}
assert_install_disk_input "$install_disk"

printf 'Previewing GRUB bootloader install for %s %s target on %s@%s port %s\n' "$profile" "$filesystem" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'INSTALL_DISK=%s\n' "$install_disk"
printf '%s\n' 'This target is read-only. It does not run grub-install, efibootmgr changes, package installation, or grub-mkconfig.'
printf '%s\n' 'A successful preview does not satisfy I_UNDERSTAND_BOOTLOADER_CHANGES=yes.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${install_disk}" \
  ansible/playbooks/bootloader-preview.yml
