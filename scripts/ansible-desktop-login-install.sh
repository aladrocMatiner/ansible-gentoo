#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-desktop-login-install
source "$(dirname "$0")/vm-libvirt-common.sh"
source "$(dirname "$0")/ansible-desktop-common.sh"

require_command ansible-playbook
load_desktop_login_inputs install

inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT
write_desktop_inventory "$inventory_file"

print_desktop_login_summary install
printf '%s\n' 'This may install packages, write session/login-manager files, and enable the selected login manager service.'

ssh_common_args=$(desktop_ssh_common_args)
mapfile -d '' -t desktop_extra_vars < <(desktop_login_extra_vars_args)

ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "desktop_action=validate" \
  "${desktop_extra_vars[@]}" \
  ansible/playbooks/post-install-desktop-login.yml
