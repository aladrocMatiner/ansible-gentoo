#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ansible-ping
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible
validate_vm_config
require_ansible_live_target vm-ansible-ping

printf 'Running Ansible ping against %s@%s port %s\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
ANSIBLE_HOST_KEY_CHECKING=False ansible all \
  -i "${ANSIBLE_LIVE_HOST}," \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -m ping \
  -e "ansible_python_interpreter=auto_silent" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}"
