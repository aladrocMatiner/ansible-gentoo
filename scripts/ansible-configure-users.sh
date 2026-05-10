#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-configure-users
source "$(dirname "$0")/vm-libvirt-common.sh"

validate_username_input() {
  local label=$1
  local value=$2

  [[ "$value" =~ ^[a-z_][a-z0-9_-]{0,31}\$?$ ]] || die "$label must be a conservative local username: $value"
}

validate_group_list() {
  local value=$1

  [[ -n "$value" ]] || die "ADMIN_GROUPS must not be empty"
  [[ "$value" =~ ^[a-z_][a-z0-9_-]{0,31}(\,[a-z_][a-z0-9_-]{0,31})*$ ]] || die "ADMIN_GROUPS must be a comma-separated list of conservative group names"
}

validate_shell_path() {
  local value=$1

  [[ "$value" == /* ]] || die "ADMIN_SHELL must be an absolute target path"
  [[ "$value" != "/" ]] || die "ADMIN_SHELL must not be /"
  [[ "$value" != *".."* ]] || die "ADMIN_SHELL must not contain parent traversal"
  ! has_glob_chars "$value" || die "ADMIN_SHELL must not contain wildcard characters"
  ! has_unsafe_chars "$value" || die "ADMIN_SHELL contains unsafe characters"
}

validate_local_input_file() {
  local label=$1
  local path=$2
  local repo_root abs_path rel_path

  [[ -n "$path" ]] || return 0
  [[ "$path" != *".."* ]] || die "$label must not contain parent traversal"
  ! has_glob_chars "$path" || die "$label must not contain wildcard characters"
  ! has_unsafe_chars "$path" || die "$label contains unsafe characters"
  [[ ! -L "$path" ]] || die "$label must not be a symlink: $path"
  [[ -f "$path" ]] || die "$label must be a readable regular file: $path"
  [[ -r "$path" ]] || die "$label must be readable: $path"

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$repo_root" ]]; then
    abs_path=$(normalize_path "$path")
    case "$abs_path" in
      "$repo_root"/*)
        rel_path=${abs_path#"$repo_root"/}
        if git -C "$repo_root" ls-files --error-unmatch -- "$rel_path" >/dev/null 2>&1; then
          die "$label must not point to a git-tracked file: $path"
        fi
        ;;
    esac
  fi
}

reject_private_key_material() {
  local label=$1
  local path=$2

  [[ -n "$path" ]] || return 0
  if grep -Eq -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$path"; then
    die "$label must not contain private key material: $path"
  fi
}

load_vm_config
require_command ansible-playbook
require_command git
scripts/config-check.sh
require_ansible_live_target configure-users

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die "PROFILE must be 'openrc' or 'systemd', got: $profile" ;;
esac

enable_ssh=${ENABLE_SSH:-no}
case "$enable_ssh" in
  yes|no) ;;
  *) die "ENABLE_SSH must be 'yes' or 'no', got: $enable_ssh" ;;
esac

admin_user=${ADMIN_USER:-}
[[ -n "$admin_user" ]] || die "ADMIN_USER is required for configure-users"
validate_username_input ADMIN_USER "$admin_user"

admin_groups=${ADMIN_GROUPS:-wheel}
admin_shell=${ADMIN_SHELL:-/bin/bash}
privilege_tool=${PRIVILEGE_TOOL:-sudo}
admin_authorized_keys_file=${ADMIN_AUTHORIZED_KEYS_FILE:-}
admin_password_hash_file=${ADMIN_PASSWORD_HASH_FILE:-}
root_password_hash_file=${ROOT_PASSWORD_HASH_FILE:-}

validate_group_list "$admin_groups"
validate_shell_path "$admin_shell"
case "$privilege_tool" in
  sudo) ;;
  *) die "PRIVILEGE_TOOL must be 'sudo' for the current implementation, got: $privilege_tool" ;;
esac

validate_local_input_file ADMIN_AUTHORIZED_KEYS_FILE "$admin_authorized_keys_file"
validate_local_input_file ADMIN_PASSWORD_HASH_FILE "$admin_password_hash_file"
validate_local_input_file ROOT_PASSWORD_HASH_FILE "$root_password_hash_file"
reject_private_key_material ADMIN_AUTHORIZED_KEYS_FILE "$admin_authorized_keys_file"

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
admin_authorized_keys_file: "${admin_authorized_keys_file}"
admin_password_hash_file: "${admin_password_hash_file}"
root_password_hash_file: "${root_password_hash_file}"
project_root: "${project_root}"
EOF

printf 'Configuring installed-system users for %s target on %s@%s port %s\n' "$profile" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'ADMIN_USER=%s\n' "$admin_user"
printf 'ADMIN_GROUPS=%s\n' "$admin_groups"
printf 'ENABLE_SSH=%s\n' "$enable_ssh"
printf '%s\n' 'Password hash file paths and authorized_keys contents are not printed.'
printf '%s\n' 'This target creates or updates users under /mnt/gentoo and does not partition, format, install GRUB, or reboot.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "@${extra_vars_file}" \
  ansible/playbooks/configure-users.yml
