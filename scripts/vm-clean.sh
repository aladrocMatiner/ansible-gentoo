#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-clean
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
require_command qemu-img
validate_vm_config
require_libvirt_connection

[[ "${I_UNDERSTAND_CLEANUP_DELETE:-}" == DELETE ]] || die "set I_UNDERSTAND_CLEANUP_DELETE=DELETE to clean selected VM artifacts"

if domain_exists; then
  require_project_marker_and_no_host_block_devices
  require_project_domain_metadata_matches_case
fi

files=()
case_state_file="var/state/libvirt/${VM_NAME}/current-install.json"
state_file_normalized=$(normalize_path "${INSTALL_STATE_FILE:-}")
case_state_file_normalized=$(normalize_path "$case_state_file")

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
if [[ -e "$VM_KNOWN_HOSTS" || -L "$VM_KNOWN_HOSTS" ]]; then
  assert_safe_generated_file VM_KNOWN_HOSTS "$VM_KNOWN_HOSTS"
  files+=("$VM_KNOWN_HOSTS")
fi
if [[ "$state_file_normalized" == "$case_state_file_normalized" && ( -e "$INSTALL_STATE_FILE" || -L "$INSTALL_STATE_FILE" ) ]]; then
  assert_safe_generated_file INSTALL_STATE_FILE "$INSTALL_STATE_FILE"
  files+=("$INSTALL_STATE_FILE")
fi

printf 'vm-clean will affect only this configured domain and generated files:\n'
printf '  selected case: %s\n' "$VM_CASE_KEY"
printf '  domain: %s (%s)\n' "$VM_NAME" "$LIBVIRT_URI"
if ((${#files[@]})); then
  printf '  files:\n'
  printf '    %s\n' "${files[@]}"
else
  printf '  files: none\n'
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
rmdir -- "$(dirname -- "$case_state_file")" "var/state/libvirt" 2>/dev/null || true
rmdir -- "$VM_LOG_DIR" "$VM_NVRAM_DIR" "$VM_DIR" 2>/dev/null || true
printf 'vm-clean: removed configured project VM artifacts.\n'
