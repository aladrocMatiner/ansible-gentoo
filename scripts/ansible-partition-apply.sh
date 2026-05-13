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

printf 'Applying GPT partition layout for %s/%s to %s on %s@%s port %s\n' "$profile" "$filesystem" "$INSTALL_DISK" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf '%s\n' 'This target partitions only. It does not format, mount, chroot, install packages, or install a bootloader.'

ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${INSTALL_DISK}" \
  -e "confirm_wipe_disk=${confirm_wipe_disk}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/partition-apply.yml
