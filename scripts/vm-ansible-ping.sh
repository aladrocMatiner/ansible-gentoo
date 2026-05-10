#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ansible-ping
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible
validate_vm_config

if [[ "$VM_NET_MODE" == user ]]; then
  target_host=$VM_SSH_HOST
  target_port=$VM_SSH_HOST_PORT
else
  target_host=${VM_IP:-}
  if [[ -z "$target_host" ]]; then
    target_host=$(scripts/vm-ip.sh)
  fi
  target_port=${VM_SSH_GUEST_PORT}
fi

printf 'Running Ansible ping against %s@%s port %s\n' "$VM_SSH_USER" "$target_host" "$target_port"
ANSIBLE_HOST_KEY_CHECKING=False ansible all \
  -i "${target_host}," \
  -u "$VM_SSH_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -m ping \
  -e "ansible_port=${target_port}"
