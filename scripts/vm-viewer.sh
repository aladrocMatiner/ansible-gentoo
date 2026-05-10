#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-viewer
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
if command -v virt-viewer >/dev/null 2>&1; then
  viewer=(virt-viewer --connect "$LIBVIRT_URI" "$VM_NAME")
elif command -v remote-viewer >/dev/null 2>&1; then
  display=$(virsh --connect "$LIBVIRT_URI" domdisplay "$VM_NAME" 2>/dev/null || true)
  [[ -n "$display" ]] || die "libvirt display endpoint is unavailable; start the VM or use make vm-console"
  viewer=(remote-viewer "$display")
else
  die "required graphical viewer not found: install virt-viewer or remote-viewer"
fi

validate_vm_config
require_libvirt_connection
require_project_owned_domain_if_exists
domain_exists || die "domain is not defined; run make vm-define first: $VM_NAME"
exec "${viewer[@]}"
