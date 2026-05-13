#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-bootloader
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
CONFIG_REQUIRE_INSTALL_DISK=yes scripts/config-check.sh
require_ansible_live_target install-bootloader

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

install_disk=${INSTALL_DISK:-}
assert_install_disk_input "$install_disk"

bootloader_confirmation=${I_UNDERSTAND_BOOTLOADER_CHANGES:-}
[[ "$bootloader_confirmation" == yes ]] || die "install-bootloader requires I_UNDERSTAND_BOOTLOADER_CHANGES=yes"

project_root=$(pwd -P)
inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT

cat >"$inventory_file" <<EOF
all:
  hosts:
    gentoo_live:
      ansible_connection: ssh
      ansible_host: ${ANSIBLE_LIVE_HOST}
      ansible_port: ${ANSIBLE_LIVE_PORT}
      ansible_user: ${ANSIBLE_LIVE_USER}
      ansible_python_interpreter: auto_silent
EOF

printf 'Installing GRUB bootloader for %s %s target on %s@%s port %s\n' "$profile" "$filesystem" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'INSTALL_DISK=%s\n' "$install_disk"
printf 'I_UNDERSTAND_BOOTLOADER_CHANGES=%s\n' "$bootloader_confirmation"
printf '%s\n' 'This target may install GRUB EFI files and create/update EFI NVRAM boot entries.'
printf '%s\n' 'It does not partition, format, wipe filesystems, create users, or reboot.'

ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${install_disk}" \
  -e "bootloader_confirmation=${bootloader_confirmation}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/install-bootloader.yml
