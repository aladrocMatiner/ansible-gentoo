#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-desktop-install
source "$(dirname "$0")/vm-libvirt-common.sh"
source "$(dirname "$0")/ansible-desktop-common.sh"

require_command ansible-playbook
load_desktop_inputs

inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT
write_desktop_inventory "$inventory_file"

print_desktop_summary install
printf '%s\n' 'This mutates only post-install packages and user session files on the installed target.'
printf '%s\n' 'It must not partition, format, mount target roots, extract stage3, chroot, install GRUB, or modify EFI entries.'

ssh_common_args=$(desktop_ssh_common_args)
mapfile -d '' -t desktop_extra_vars < <(desktop_extra_vars_args)

ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="$ssh_common_args" \
  -e "desktop_action=install" \
  "${desktop_extra_vars[@]}" \
  ansible/playbooks/post-install-desktop.yml
