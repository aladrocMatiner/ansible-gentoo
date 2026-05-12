#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=host-check
source "$(dirname "$0")/vm-libvirt-common.sh"

size_to_mib() {
  local value=$1
  local number suffix

  [[ "$value" =~ ^([0-9]+)([KMGTP]?)$ ]] || die_code CONFIG_INVALID "VM_DISK_SIZE must be a simple size such as 40G: $value"
  number=${BASH_REMATCH[1]}
  suffix=${BASH_REMATCH[2]}
  case "$suffix" in
    K) printf '%s\n' $(( (number + 1023) / 1024 )) ;;
    M|'') printf '%s\n' "$number" ;;
    G) printf '%s\n' $(( number * 1024 )) ;;
    T) printf '%s\n' $(( number * 1024 * 1024 )) ;;
    P) printf '%s\n' $(( number * 1024 * 1024 * 1024 )) ;;
  esac
}

load_vm_config
require_command awk
require_command df
require_command grep
require_command make
require_command virsh
require_command qemu-img
require_command qemu-system-x86_64
require_command isoinfo
require_command ssh
require_command rsync
require_command ansible
validate_vm_config

available_mem_mib=$(awk '/^MemTotal:/ { print int($2 / 1024); exit }' /proc/meminfo 2>/dev/null || printf '0\n')
required_mem_mib=$(( VM_RAM + 512 ))
if (( available_mem_mib < required_mem_mib )); then
  die_code HOST_REQUIREMENT_MISSING "host memory is below VM_RAM plus overhead: available=${available_mem_mib}MiB required=${required_mem_mib}MiB"
fi

required_disk_mib=$(size_to_mib "$VM_DISK_SIZE")
available_disk_mib=$(df -Pm . | awk 'NR == 2 { print $4 }')
if (( available_disk_mib < required_disk_mib )); then
  die_code HOST_REQUIREMENT_MISSING "project filesystem free space is below VM_DISK_SIZE: available=${available_disk_mib}MiB required=${required_disk_mib}MiB"
fi

if [[ -e /dev/kvm ]]; then
  if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    kvm_status="direct /dev/kvm access available"
  else
    kvm_status="/dev/kvm exists but direct access is limited; relying on libvirt access"
  fi
elif ! grep -Eq '(^flags|^Features)[[:space:]]*:.*(vmx|svm|virt)' /proc/cpuinfo 2>/dev/null; then
  die_code HOST_REQUIREMENT_MISSING "could not confirm CPU virtualization support from /dev/kvm or /proc/cpuinfo"
else
  kvm_status="CPU virtualization flag present; /dev/kvm not visible"
fi

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

domain_status="not defined"
if domain_exists; then
  require_project_marker_and_no_host_block_devices
  require_project_domain_metadata_matches_case
  domain_status=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || printf 'unknown')
fi

printf 'host-check: OK\n'
printf '  selected case: %s\n' "$VM_CASE_KEY"
printf '  ISO: %s\n' "$resolved_iso"
printf '  VM_NAME: %s\n' "$VM_NAME"
printf '  domain status: %s\n' "$domain_status"
printf '  VM_NET_MODE: %s\n' "$VM_NET_MODE"
printf '  VM_KERNEL_ARGS: %s\n' "$resolved_kernel_args"
printf '  memory available: %s MiB\n' "$available_mem_mib"
printf '  memory required: %s MiB\n' "$required_mem_mib"
printf '  disk space available: %s MiB\n' "$available_disk_mib"
printf '  disk space required: %s MiB\n' "$required_disk_mib"
printf '  KVM status: %s\n' "$kvm_status"
printf '  OVMF_CODE: %s\n' "$OVMF_CODE"
printf '  OVMF_VARS_TEMPLATE: %s\n' "$OVMF_VARS_TEMPLATE"
