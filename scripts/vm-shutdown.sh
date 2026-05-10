#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-shutdown
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
require_project_marker_and_no_host_block_devices_if_exists
domain_exists || die "domain is not defined: $VM_NAME"
state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
if [[ "$state" == running || "$state" == paused ]]; then
  virsh --connect "$LIBVIRT_URI" shutdown "$VM_NAME"
else
  printf 'vm-shutdown: domain is already inactive: %s is %s\n' "$VM_NAME" "${state:-unknown}"
fi
