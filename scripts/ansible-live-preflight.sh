#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-live-preflight
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
require_ansible_live_target ansible-live-preflight

printf 'Running read-only live ISO preflight against %s@%s port %s\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
ssh_common_args=$(ansible_ssh_common_args)

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="$ssh_common_args" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  ansible/playbooks/live-preflight.yml
