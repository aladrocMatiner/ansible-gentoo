#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-prepare-chroot
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target prepare-chroot

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

printf 'Preparing chroot mounts for %s target on %s@%s port %s\n' "$profile" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf '%s\n' 'This target mounts pseudo-filesystems under /mnt/gentoo and prepares DNS. It does not run package, Portage, kernel, user, or bootloader tasks.'

ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/prepare-chroot.yml
