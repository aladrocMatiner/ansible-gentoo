#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-start
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
require_command qemu-img
require_command qemu-system-x86_64
require_command isoinfo
validate_vm_config
require_libvirt_connection
print_vm_identity

if ! domain_exists; then
  resolved_iso=$(resolve_iso_path "$VM_ISO")
  resolve_kernel_args "$resolved_iso" >/dev/null
  require_uefi_firmware
  if [[ "$VM_NET_MODE" == network ]]; then
    virsh --connect "$LIBVIRT_URI" net-info "$VM_NETWORK" >/dev/null 2>&1 || die "libvirt network not found on $LIBVIRT_URI: $VM_NETWORK"
  fi
  scripts/vm-create-disk.sh
  scripts/vm-define-libvirt-domain.sh
fi

require_project_owned_domain_if_exists
domain_exists || die "domain is not defined; run make vm-define first: $VM_NAME"

state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
if [[ "$state" == running || "$state" == paused ]]; then
  printf 'vm-start: domain already active: %s\n' "$VM_NAME"
else
  [[ -f "$VM_DISK" ]] || die "VM_DISK is missing or not a regular file; run make vm-disk or make vm-define: $VM_DISK"
  assert_qcow2_image "$VM_DISK"
  [[ -f "$VM_NVRAM" && ! -L "$VM_NVRAM" ]] || die "VM_NVRAM is missing or unsafe; run make vm-define to regenerate it: $VM_NVRAM"
  [[ -f "$VM_KERNEL" && ! -L "$VM_KERNEL" ]] || die "VM kernel artifact is missing or unsafe; run make vm-define to regenerate it: $VM_KERNEL"
  [[ -f "$VM_INITRD" && ! -L "$VM_INITRD" ]] || die "VM initrd artifact is missing or unsafe; run make vm-define to regenerate it: $VM_INITRD"
  virsh --connect "$LIBVIRT_URI" start "$VM_NAME"
fi

print_config
