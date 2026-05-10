#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-ip
source "$(dirname "$0")/vm-libvirt-common.sh"

extract_ip() {
  awk '/ipv4/ { split($4, a, "/"); print a[1]; exit }'
}

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
require_project_owned_domain_if_exists
domain_exists || die "domain is not defined; run make vm-define first: $VM_NAME"

if [[ "$VM_NET_MODE" == user ]]; then
  die "guest IP discovery is not available in default user-mode networking; use SSH endpoint ${VM_SSH_HOST}:${VM_SSH_HOST_PORT}"
fi

ip=$(virsh --connect "$LIBVIRT_URI" domifaddr "$VM_NAME" --source agent 2>/dev/null | extract_ip || true)
if [[ -z "$ip" ]]; then
  ip=$(virsh --connect "$LIBVIRT_URI" domifaddr "$VM_NAME" --source lease 2>/dev/null | extract_ip || true)
fi
if [[ -z "$ip" && -n "$VM_NETWORK" ]]; then
  ip=$(virsh --connect "$LIBVIRT_URI" net-dhcp-leases "$VM_NETWORK" 2>/dev/null | awk '/ipv4/ { split($5, a, "/"); print a[1]; exit }' || true)
fi
[[ -n "$ip" ]] || die "could not discover guest IP for $VM_NAME"
printf '%s\n' "$ip"
