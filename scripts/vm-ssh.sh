#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ssh
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ssh
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

printf 'Connecting to %s@%s port %s. SSH must be enabled inside the live ISO first.\n' "$VM_SSH_USER" "$target_host" "$target_port"
exec ssh \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=10 \
  -o ServerAliveCountMax=1 \
  -p "$target_port" \
  "$VM_SSH_USER@$target_host"
