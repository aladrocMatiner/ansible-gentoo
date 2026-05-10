#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-disk
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command qemu-img
validate_vm_config
ensure_artifact_dirs

if [[ -e "$VM_DISK" ]]; then
  [[ -f "$VM_DISK" ]] || die "VM_DISK exists but is not a regular file: $VM_DISK"
  assert_qcow2_image "$VM_DISK"
  printf 'vm-disk: existing qcow2 disk preserved: %s\n' "$VM_DISK"
  exit 0
fi

printf 'vm-disk: creating qcow2 disk %s (%s)\n' "$VM_DISK" "$VM_DISK_SIZE"
qemu-img create -f qcow2 -- "$VM_DISK" "$VM_DISK_SIZE"
