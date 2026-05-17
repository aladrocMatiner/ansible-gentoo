#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-desktop-login-validate
source "$(dirname "$0")/vm-libvirt-common.sh"
source "$(dirname "$0")/ansible-desktop-common.sh"

require_command ansible-playbook
load_desktop_login_inputs validate

inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT
write_desktop_inventory "$inventory_file"

print_desktop_login_summary validate
printf '%s\n' 'Login manager validation is read-only and checks managed post-install state.'

ssh_common_args=$(desktop_ssh_common_args)
mapfile -d '' -t desktop_extra_vars < <(desktop_login_extra_vars_args)

ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "desktop_action=validate" \
  "${desktop_extra_vars[@]}" \
  ansible/playbooks/validate-desktop-login.yml
