#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-live-ping
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible
require_ansible_live_target ansible-live-ping

printf 'Running Ansible live ping against %s@%s port %s\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
ANSIBLE_HOST_KEY_CHECKING=False ansible gentoo_live \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -m ping \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}"
