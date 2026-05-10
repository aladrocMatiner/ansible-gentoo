#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-start
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
require_project_owned_domain_if_exists
domain_exists || die "domain is not defined; run make vm-define first: $VM_NAME"

if virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null | grep -Eq 'running|paused'; then
  printf 'vm-start: domain already active: %s\n' "$VM_NAME"
else
  virsh --connect "$LIBVIRT_URI" start "$VM_NAME"
fi

print_config
