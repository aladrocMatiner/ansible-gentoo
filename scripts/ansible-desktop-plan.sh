#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-desktop-plan
source "$(dirname "$0")/vm-libvirt-common.sh"
source "$(dirname "$0")/ansible-desktop-common.sh"

require_command ansible-playbook
load_desktop_inputs plan

inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT
write_desktop_inventory "$inventory_file"

print_desktop_summary plan
printf '%s\n' 'The plan is read-only and runs Ansible check mode.'

ssh_common_args=$(desktop_ssh_common_args)
mapfile -d '' -t desktop_extra_vars < <(desktop_extra_vars_args)

ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  --check \
  -e "desktop_action=plan" \
  "${desktop_extra_vars[@]}" \
  ansible/playbooks/post-install-desktop.yml
