#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-rsync
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command rsync
require_command ssh
validate_vm_config

VM_RSYNC_DEST=${VM_RSYNC_DEST:-/root/gentoo-ai-installer/}
[[ "$VM_RSYNC_DEST" == /* ]] || die "VM_RSYNC_DEST must be an absolute guest path"

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

printf 'Rsync to %s@%s:%s over SSH port %s. SSH must be enabled inside the live ISO first.\n' "$VM_SSH_USER" "$target_host" "$VM_RSYNC_DEST" "$target_port"

rsync -az --delete \
  --exclude '.git/' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude 'gentoo.iso' \
  --exclude 'gentoo.iso/' \
  --exclude 'var/' \
  --exclude 'logs/' \
  --exclude 'tmp/' \
  -e "ssh -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=1 -p ${target_port}" \
  ./ "${VM_SSH_USER}@${target_host}:${VM_RSYNC_DEST}"
