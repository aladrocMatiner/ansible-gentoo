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
[[ "$VM_RSYNC_DEST" != *".."* && "$VM_RSYNC_DEST" != *"//"* ]] || die "VM_RSYNC_DEST must not contain parent traversal or repeated slashes: $VM_RSYNC_DEST"
[[ "$VM_RSYNC_DEST" =~ ^/root/gentoo-ai-installer(/|/[A-Za-z0-9._/-]*)?$ ]] || die "VM_RSYNC_DEST must stay under /root/gentoo-ai-installer/: $VM_RSYNC_DEST"

require_ansible_live_target vm-rsync

printf 'Rsync to %s@%s:%s over SSH port %s. SSH must be enabled inside the live ISO first.\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$VM_RSYNC_DEST" "$ANSIBLE_LIVE_PORT"

rsync -az --delete \
  --exclude '.git/' \
  --exclude '.ssh/' \
  --exclude '**/.ssh/' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.netrc' \
  --exclude '**/.netrc' \
  --exclude '.npmrc' \
  --exclude '**/.npmrc' \
  --exclude '.pypirc' \
  --exclude '**/.pypirc' \
  --exclude '.kube/' \
  --exclude '**/.kube/' \
  --exclude '.aws/' \
  --exclude '**/.aws/' \
  --exclude '.azure/' \
  --exclude '**/.azure/' \
  --exclude 'secrets/' \
  --exclude '**/secrets/' \
  --exclude 'secret/' \
  --exclude '**/secret/' \
  --exclude 'credentials/' \
  --exclude '**/credentials/' \
  --exclude 'tokens/' \
  --exclude '**/tokens/' \
  --exclude 'authorized_keys' \
  --exclude 'known_hosts' \
  --exclude 'id_rsa' \
  --exclude 'id_rsa.pub' \
  --exclude 'id_ed25519' \
  --exclude 'id_ed25519.pub' \
  --exclude '*.pem' \
  --exclude '*.key' \
  --exclude '*.p12' \
  --exclude '*.pfx' \
  --exclude '*.gpg' \
  --exclude '*.age' \
  --exclude 'credentials' \
  --exclude 'credentials.*' \
  --exclude 'secret' \
  --exclude 'secret.*' \
  --exclude 'token' \
  --exclude 'token.*' \
  --exclude '*.secret' \
  --exclude '*.token' \
  --exclude 'gentoo.iso' \
  --exclude 'gentoo.iso/' \
  --exclude 'var/' \
  --exclude 'logs/' \
  --exclude 'tmp/' \
  -e "ssh -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${ANSIBLE_LIVE_PORT}" \
  ./ "${ANSIBLE_LIVE_USER}@${ANSIBLE_LIVE_HOST}:${VM_RSYNC_DEST}"
