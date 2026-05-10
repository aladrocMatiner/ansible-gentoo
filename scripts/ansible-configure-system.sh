#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-configure-system
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target configure-system

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

target_hostname=${HOSTNAME:-gentoo}
timezone=${TIMEZONE:-UTC}
locale=${LOCALE:-en_US.UTF-8}
keymap=${KEYMAP:-us}
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

printf 'Configuring target system identity for %s target on %s@%s port %s\n' "$profile" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'Hostname: %s\n' "$target_hostname"
printf 'Timezone: %s\n' "$timezone"
printf 'Locale: %s\n' "$locale"
printf 'Keymap: %s\n' "$keymap"
printf '%s\n' 'This target writes hostname, timezone, locale, and console keymap under /mnt/gentoo. It does not install packages, users, services, kernel, or bootloader.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "hostname=${target_hostname}" \
  -e "timezone=${timezone}" \
  -e "locale=${locale}" \
  -e "keymap=${keymap}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/configure-system.yml
