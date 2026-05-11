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

scripts/vm-check-libvirt.sh

printf 'host-check: OK\n'
printf '  memory available: %s MiB\n' "$available_mem_mib"
printf '  memory required: %s MiB\n' "$required_mem_mib"
printf '  disk space available: %s MiB\n' "$available_disk_mib"
printf '  disk space required: %s MiB\n' "$required_disk_mib"
printf '  KVM status: %s\n' "$kvm_status"
