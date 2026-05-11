#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-check
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
require_command qemu-img
require_command qemu-system-x86_64
require_command isoinfo
require_command ssh
require_command rsync
require_command ansible
require_command make
validate_vm_config

resolved_iso=$(resolve_iso_path "$VM_ISO")
resolved_kernel_args=$(resolve_kernel_args "$resolved_iso")
require_uefi_firmware

if [[ -e "$VM_DISK" ]]; then
  [[ -f "$VM_DISK" ]] || die "VM_DISK exists but is not a regular file: $VM_DISK"
  assert_qcow2_image "$VM_DISK"
fi

require_libvirt_connection

if [[ "$VM_NET_MODE" == network ]]; then
  virsh --connect "$LIBVIRT_URI" net-info "$VM_NETWORK" >/dev/null 2>&1 || die "libvirt network not found on $LIBVIRT_URI: $VM_NETWORK"
fi

if domain_exists; then
  require_project_owned_domain_if_exists
fi

printf 'vm-check: OK\n'
printf '  selected case: %s\n' "$VM_CASE_KEY"
printf '  VM_BASE_NAME: %s\n' "$VM_BASE_NAME"
printf '  VM_TEST_IMAGE_NAME: %s\n' "${VM_TEST_IMAGE_NAME:-}"
printf '  ISO: %s\n' "$resolved_iso"
printf '  LIBVIRT_URI: %s\n' "$LIBVIRT_URI"
printf '  VM_NAME: %s\n' "$VM_NAME"
printf '  VM_DIR: %s\n' "$VM_DIR"
printf '  VM_DISK: %s\n' "$VM_DISK"
printf '  INSTALL_STATE_FILE: %s\n' "${INSTALL_STATE_FILE:-}"
printf '  VM_LOG_DIR: %s\n' "$VM_LOG_DIR"
printf '  VM_BOOT_MODE: %s\n' "$VM_BOOT_MODE"
printf '  OVMF_CODE: %s\n' "$OVMF_CODE"
printf '  OVMF_VARS_TEMPLATE: %s\n' "$OVMF_VARS_TEMPLATE"
printf '  VM_NET_MODE: %s\n' "$VM_NET_MODE"
printf '  VM_KERNEL_ARGS: %s\n' "$resolved_kernel_args"
if [[ "$VM_NET_MODE" == user ]]; then
  printf '  SSH forwarding: %s:%s -> guest port %s\n' "$VM_SSH_HOST" "$VM_SSH_HOST_PORT" "$VM_SSH_GUEST_PORT"
else
  printf '  VM_NETWORK: %s\n' "$VM_NETWORK"
fi
