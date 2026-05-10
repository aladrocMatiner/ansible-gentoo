#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ssh-target
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
validate_vm_config
require_project_owned_running_domain

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

[[ -n "$target_host" ]] || die "could not determine VM SSH host; run make vm-ip or set VM_IP"
assert_host "$target_host"
assert_port VM_SSH_TARGET_PORT "$target_port"

case "${1:-env}" in
  env)
    printf 'ANSIBLE_LIVE_HOST=%q\n' "$target_host"
    printf 'ANSIBLE_LIVE_PORT=%q\n' "$target_port"
    printf 'ANSIBLE_LIVE_USER=%q\n' "$VM_SSH_USER"
    ;;
  host)
    printf '%s\n' "$target_host"
    ;;
  port)
    printf '%s\n' "$target_port"
    ;;
  user)
    printf '%s\n' "$VM_SSH_USER"
    ;;
  *)
    die "usage: scripts/vm-ssh-target.sh [env|host|port|user]"
    ;;
esac
