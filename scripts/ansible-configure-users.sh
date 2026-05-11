#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-configure-users
source "$(dirname "$0")/vm-libvirt-common.sh"
source "$(dirname "$0")/ansible-users-inputs.sh"

load_vm_config
require_command ansible-playbook
require_command git
scripts/config-check.sh
require_ansible_live_target configure-users
load_and_validate_users_inputs yes

if [[ "$enable_ssh" == yes && -z "$admin_authorized_keys_file" ]]; then
  printf '%s\n' "Warning: ENABLE_SSH=yes but ADMIN_AUTHORIZED_KEYS_FILE is unset; installed SSH will be enabled without admin authorized_keys." >&2
fi

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
enable_ssh: "${enable_ssh}"
admin_user: "${admin_user}"
admin_groups_csv: "${admin_groups}"
admin_shell: "${admin_shell}"
privilege_tool: "${privilege_tool}"
admin_sudo_nopasswd: "${admin_sudo_nopasswd}"
admin_authorized_keys_file: "${admin_authorized_keys_file}"
admin_password_hash_file: "${admin_password_hash_file}"
root_password_hash_file: "${root_password_hash_file}"
project_root: "${project_root}"
EOF

printf 'Configuring installed-system users for %s target on %s@%s port %s\n' "$profile" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'ADMIN_USER=%s\n' "$admin_user"
printf 'ADMIN_GROUPS=%s\n' "$admin_groups"
printf 'ADMIN_SUDO_NOPASSWD=%s\n' "$admin_sudo_nopasswd"
printf 'ENABLE_SSH=%s\n' "$enable_ssh"
printf '%s\n' 'Password hash file paths and authorized_keys contents are not printed.'
printf '%s\n' 'This target creates or updates users under /mnt/gentoo and does not partition, format, install GRUB, or reboot.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "@${extra_vars_file}" \
  ansible/playbooks/configure-users.yml
