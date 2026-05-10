#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-install-system-packages
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target install-system-packages

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

enable_ssh=${ENABLE_SSH:-no}
case "$enable_ssh" in
  yes|no) ;;
  *) die "ENABLE_SSH must be 'yes' or 'no', got: $enable_ssh" ;;
esac

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

printf 'Installing minimal console packages for %s %s target on %s@%s port %s\n' "$profile" "$filesystem" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'ENABLE_SSH=%s\n' "$enable_ssh"
printf '%s\n' 'This target installs packages and enables target-system services under /mnt/gentoo.'
printf '%s\n' 'It does not create users, install GRUB, change EFI boot entries, partition, format, or reboot.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "enable_ssh=${enable_ssh}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/install-system-packages.yml
