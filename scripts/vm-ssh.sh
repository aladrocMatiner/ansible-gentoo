#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ssh
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ssh
validate_vm_config
require_ansible_live_target vm-ssh

printf 'Connecting to %s@%s port %s. SSH must be enabled inside the live ISO first.\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
exec ssh \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=10 \
  -o ServerAliveCountMax=1 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -p "$ANSIBLE_LIVE_PORT" \
  "$ANSIBLE_LIVE_USER@$ANSIBLE_LIVE_HOST"
