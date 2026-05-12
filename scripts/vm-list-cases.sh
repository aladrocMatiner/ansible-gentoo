#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-list-cases
source "$(dirname "$0")/vm-libvirt-common.sh"

base_vm_name=${VM_NAME:-gentoo-test}
base_vm_disk=${VM_DISK:-}
base_state_file=${INSTALL_STATE_FILE:-}
base_ssh_port=${VM_SSH_HOST_PORT:-2222}
base_ansible_live_host=${ANSIBLE_LIVE_HOST:-}
vm_dir=${VM_DIR:-var/libvirt}

assert_conservative_name VM_NAME "$base_vm_name"
assert_safe_test_image_name "${VM_TEST_IMAGE_NAME:-}"
if ! is_default_disk_path "$base_vm_disk" "$vm_dir" "$base_vm_name"; then
  die "vm-list-cases does not accept manual VM_DISK overrides; unset VM_DISK to list generated case disks"
fi
if ! is_default_state_path "$base_state_file"; then
  die "vm-list-cases does not accept manual INSTALL_STATE_FILE overrides; unset INSTALL_STATE_FILE to list generated case state paths"
fi
if [[ "$base_ssh_port" != 2222 ]]; then
  die "vm-list-cases derives unique SSH host ports per case; leave VM_SSH_HOST_PORT at the default 2222"
fi

printf 'Supported libvirt VM cases:\n'
printf '  base name: %s\n' "$base_vm_name"
if [[ -n "${VM_TEST_IMAGE_NAME:-}" ]]; then
  printf '  test image label: %s\n' "$VM_TEST_IMAGE_NAME"
fi
printf '  platform: %s\n' "$VM_PLATFORM"
printf '  VM_DIR: %s\n' "$vm_dir"
printf '\n'

for stage3_flavor in standard hardened musl; do
  for profile in openrc systemd; do
    for filesystem in ext4 btrfs; do
      PROFILE=$profile
      FILESYSTEM=$filesystem
      STAGE3_FLAVOR=$stage3_flavor
      VM_NAME=$base_vm_name
      VM_DISK=$base_vm_disk
      VM_SSH_HOST_PORT=$base_ssh_port
      INSTALL_STATE_FILE=$base_state_file
      ANSIBLE_LIVE_HOST=
      VM_CASE_DERIVED=no
      load_vm_config
      validate_vm_config

      domain_status="unknown"
      if command -v virsh >/dev/null 2>&1 && virsh --connect "$LIBVIRT_URI" uri >/dev/null 2>&1; then
        if domain_exists; then
          domain_status="defined"
        else
          domain_status="not defined"
        fi
      else
        domain_status="unknown"
      fi

      printf '%s\n' "$VM_CASE_KEY"
      printf '  domain: %s\n' "$VM_NAME"
      printf '  profile: %s\n' "$PROFILE"
      printf '  filesystem: %s\n' "$FILESYSTEM"
      printf '  stage3 flavor: %s\n' "$STAGE3_FLAVOR"
      printf '  disk: %s\n' "$VM_DISK"
      printf '  xml: %s\n' "$VM_XML"
      printf '  nvram: %s\n' "$VM_NVRAM"
      printf '  log dir: %s\n' "$VM_LOG_DIR"
      printf '  state: %s\n' "$INSTALL_STATE_FILE"
      printf '  user-mode SSH port: %s\n' "$VM_SSH_HOST_PORT"
      printf '  domain status: %s\n' "$domain_status"
      printf '\n'
    done
  done
done

ANSIBLE_LIVE_HOST=$base_ansible_live_host
