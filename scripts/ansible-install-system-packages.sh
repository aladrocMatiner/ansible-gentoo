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

stage3_flavor=${STAGE3_FLAVOR:-standard}
case "$stage3_flavor" in
  standard|hardened|musl) ;;
  *) die "STAGE3_FLAVOR must be 'standard', 'hardened', or 'musl', got: $stage3_flavor" ;;
esac

enable_ssh=${ENABLE_SSH:-no}
case "$enable_ssh" in
  yes|no) ;;
  *) die "ENABLE_SSH must be 'yes' or 'no', got: $enable_ssh" ;;
esac

enable_wifi=${ENABLE_WIFI:-no}
case "$enable_wifi" in
  yes|no) ;;
  *) die "ENABLE_WIFI must be 'yes' or 'no', got: $enable_wifi" ;;
esac

enable_qemu_guest_agent=${ENABLE_QEMU_GUEST_AGENT:-no}
case "$enable_qemu_guest_agent" in
  yes|no) ;;
  *) die "ENABLE_QEMU_GUEST_AGENT must be 'yes' or 'no', got: $enable_qemu_guest_agent" ;;
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

printf 'Installing minimal console packages for %s %s %s target on %s@%s port %s\n' "$profile" "$filesystem" "$stage3_flavor" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'ENABLE_SSH=%s\n' "$enable_ssh"
printf 'ENABLE_WIFI=%s\n' "$enable_wifi"
printf 'ENABLE_QEMU_GUEST_AGENT=%s\n' "$enable_qemu_guest_agent"
printf '%s\n' 'This target installs packages and enables target-system services under /mnt/gentoo.'
printf '%s\n' 'It does not create users, install GRUB, change EFI boot entries, partition, format, or reboot.'

ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "stage3_flavor=${stage3_flavor}" \
  -e "enable_ssh=${enable_ssh}" \
  -e "enable_wifi=${enable_wifi}" \
  -e "enable_qemu_guest_agent=${enable_qemu_guest_agent}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/install-system-packages.yml
