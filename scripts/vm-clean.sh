#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-clean
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
require_command qemu-img
validate_vm_config
require_libvirt_connection

if domain_exists; then
  require_project_owned_domain_if_exists
fi

files=()
if [[ -f "$VM_DISK" ]]; then
  assert_qcow2_image "$VM_DISK"
  files+=("$VM_DISK")
fi
if [[ -e "$VM_XML" || -L "$VM_XML" ]]; then
  assert_safe_generated_file VM_XML "$VM_XML"
  files+=("$VM_XML")
fi
if [[ -e "$VM_NVRAM" || -L "$VM_NVRAM" ]]; then
  assert_safe_generated_file VM_NVRAM "$VM_NVRAM"
  files+=("$VM_NVRAM")
fi
if [[ -e "$VM_KERNEL" || -L "$VM_KERNEL" ]]; then
  assert_safe_generated_file VM_KERNEL "$VM_KERNEL"
  files+=("$VM_KERNEL")
fi
if [[ -e "$VM_INITRD" || -L "$VM_INITRD" ]]; then
  assert_safe_generated_file VM_INITRD "$VM_INITRD"
  files+=("$VM_INITRD")
fi

printf 'vm-clean will affect only this configured domain and generated files:\n'
printf '  domain: %s (%s)\n' "$VM_NAME" "$LIBVIRT_URI"
if ((${#files[@]})); then
  printf '  files:\n'
  printf '    %s\n' "${files[@]}"
else
  printf '  files: none\n'
fi
printf 'Type DELETE to continue: '
read -r confirmation
if [[ "$confirmation" != DELETE ]]; then
  printf 'vm-clean cancelled.\n'
  exit 1
fi

if domain_exists; then
  if virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null | grep -Eq 'running|paused'; then
    virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
  fi
  virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" --nvram 2>/dev/null || virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME"
fi

if ((${#files[@]})); then
  rm -f -- "${files[@]}"
fi
rmdir -- "$VM_NVRAM_DIR" "$VM_DIR" 2>/dev/null || true
printf 'vm-clean: removed configured project VM artifacts.\n'
