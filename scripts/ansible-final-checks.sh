#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-final-checks
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
require_command git
scripts/config-check.sh
scripts/secret-check.sh
require_ansible_live_target final-checks

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

admin_user=${ADMIN_USER:-}
[[ -n "$admin_user" ]] || die "ADMIN_USER is required for final-checks so the admin account can be verified"

project_root=$(pwd -P)
inventory_file=$(mktemp --suffix=.yml)
extra_vars_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file" "$extra_vars_file"' EXIT

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

cat >"$extra_vars_file" <<EOF
profile: "${profile}"
filesystem: "${filesystem}"
hostname: "${HOSTNAME:-gentoo}"
timezone: "${TIMEZONE:-UTC}"
locale: "${LOCALE:-en_US.UTF-8}"
keymap: "${KEYMAP:-us}"
enable_ssh: "${enable_ssh}"
admin_user: "${admin_user}"
admin_groups_csv: "${ADMIN_GROUPS:-wheel}"
admin_shell: "${ADMIN_SHELL:-/bin/bash}"
privilege_tool: "${PRIVILEGE_TOOL:-sudo}"
admin_authorized_keys_file: "${ADMIN_AUTHORIZED_KEYS_FILE:-}"
project_root: "${project_root}"
controller_secret_check: "passed"
EOF

printf 'Running read-only final checks for %s %s target on %s@%s port %s\n' "$profile" "$filesystem" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'ADMIN_USER=%s\n' "$admin_user"
printf 'ENABLE_SSH=%s\n' "$enable_ssh"
printf '%s\n' 'This target validates reboot readiness and does not install packages, modify the target, change EFI entries, or reboot.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "@${extra_vars_file}" \
  ansible/playbooks/final-checks.yml

scripts/install-audit-bundle.py --state-file "${INSTALL_STATE_FILE:-var/state/current-install.json}" generate
