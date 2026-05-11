#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-destroy
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
if domain_exists; then
  require_project_marker_and_no_host_block_devices
  require_project_domain_metadata_matches_case
fi
domain_exists || die "domain is not defined: $VM_NAME"
state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
if [[ "$state" == running || "$state" == paused ]]; then
  virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
else
  printf 'vm-destroy: domain is already inactive: %s is %s\n' "$VM_NAME" "${state:-unknown}"
fi
