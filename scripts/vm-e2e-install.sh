#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-e2e-install
source "$(dirname "$0")/vm-libvirt-common.sh"

validate_admin_user() {
  local value=$1
  [[ "$value" =~ ^[a-z_][a-z0-9_-]{0,31}\$?$ ]] || die_code CONFIG_INVALID "ADMIN_USER must be a conservative installed-system user name"
}

run_step() {
  local name=$1
  shift
  local log_file="$e2e_log_dir/${name}.log"
  printf 'vm-e2e-install: running %s\n' "$name"
  set +e
  "$@" 2>&1 | tee "$log_file"
  local status=${PIPESTATUS[0]}
  set -e
  if [[ "$status" -ne 0 ]]; then
    printf 'vm-e2e-install: %s failed; see %s\n' "$name" "$log_file" >&2
    exit "$status"
  fi
}

load_vm_config
require_command virsh
require_command qemu-img
require_command ansible-playbook
require_command ssh
require_command tee
validate_vm_config

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die_code CONFIG_INVALID "PROFILE must be openrc or systemd, got: $profile" ;;
esac

filesystem=${FILESYSTEM:-ext4}
case "$filesystem" in
  ext4|btrfs) ;;
  *) die_code CONFIG_INVALID "FILESYSTEM must be ext4 or btrfs, got: $filesystem" ;;
esac

install_disk=${INSTALL_DISK:-}
assert_install_disk_input "$install_disk"
[[ "$install_disk" == /dev/vda ]] || die_code DISK_UNSAFE "VM end-to-end validation must use INSTALL_DISK=/dev/vda inside the disposable libvirt guest"

admin_user=${ADMIN_USER:-}
validate_admin_user "$admin_user"
[[ "${ENABLE_SSH:-no}" == yes ]] || die_code CONFIG_INVALID "vm-e2e-install requires ENABLE_SSH=yes so first-boot validation can connect to the installed system"
admin_authorized_keys_file=${ADMIN_AUTHORIZED_KEYS_FILE:-}
[[ -n "$admin_authorized_keys_file" ]] || die_code CONFIG_INVALID "vm-e2e-install requires ADMIN_AUTHORIZED_KEYS_FILE so first-boot validation can authenticate to the installed admin user"
[[ -r "$admin_authorized_keys_file" && -f "$admin_authorized_keys_file" ]] || die_code CONFIG_INVALID "ADMIN_AUTHORIZED_KEYS_FILE must be a readable public-key file: $admin_authorized_keys_file"
if grep -Eq -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$admin_authorized_keys_file"; then
  die_code SECRET_INPUT_INVALID "ADMIN_AUTHORIZED_KEYS_FILE must contain public keys only, not private key material"
fi
if ! grep -Eq -- '^[[:space:]]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)[[:space:]]+' "$admin_authorized_keys_file"; then
  die_code CONFIG_INVALID "ADMIN_AUTHORIZED_KEYS_FILE must contain at least one supported OpenSSH public key"
fi

[[ "${I_UNDERSTAND_THIS_WIPES_DISK:-}" == yes ]] || die_code DESTRUCTIVE_CONFIRMATION_MISSING "vm-e2e-install requires I_UNDERSTAND_THIS_WIPES_DISK=yes"
[[ "${I_UNDERSTAND_BOOTLOADER_CHANGES:-}" == yes ]] || die_code DESTRUCTIVE_CONFIRMATION_MISSING "vm-e2e-install requires I_UNDERSTAND_BOOTLOADER_CHANGES=yes"

vm_e2e_reset_disk=${VM_E2E_RESET_DISK:-no}
case "$vm_e2e_reset_disk" in
  yes|no) ;;
  *) die_code CONFIG_INVALID "VM_E2E_RESET_DISK must be yes or no" ;;
esac

vm_e2e_admin_sudo_nopasswd=${ADMIN_SUDO_NOPASSWD:-${VM_E2E_ADMIN_SUDO_NOPASSWD:-yes}}
case "$vm_e2e_admin_sudo_nopasswd" in
  yes|no) ;;
  *) die_code CONFIG_INVALID "ADMIN_SUDO_NOPASSWD/VM_E2E_ADMIN_SUDO_NOPASSWD must be yes or no" ;;
esac
export ADMIN_SUDO_NOPASSWD="$vm_e2e_admin_sudo_nopasswd"

timestamp=$(date -u +%Y%m%dT%H%M%S%NZ)
e2e_log_dir="logs/libvirt-e2e/${timestamp}-${profile}-${filesystem}"
mkdir -p "$e2e_log_dir"
[[ -d "$e2e_log_dir" && ! -L "$e2e_log_dir" ]] || die_code VM_UNSAFE "E2E log directory is unsafe: $e2e_log_dir"

printf 'Libvirt end-to-end install validation\n' | tee "$e2e_log_dir/summary.txt"
printf 'profile=%s filesystem=%s install_disk=%s admin_user=%s\n' "$profile" "$filesystem" "$install_disk" "$admin_user" | tee -a "$e2e_log_dir/summary.txt"
printf 'admin_sudo_nopasswd=%s\n' "$vm_e2e_admin_sudo_nopasswd" | tee -a "$e2e_log_dir/summary.txt"
printf '%s\n' 'This workflow is destructive inside the disposable VM qcow2 disk and does not touch host block devices.' | tee -a "$e2e_log_dir/summary.txt"

run_step e2e-plan scripts/vm-e2e-plan.py

if [[ "$vm_e2e_reset_disk" == yes ]]; then
  [[ "${I_UNDERSTAND_CLEANUP_DELETE:-}" == DELETE ]] || die_code CONFIRMATION_MISSING "VM_E2E_RESET_DISK=yes requires I_UNDERSTAND_CLEANUP_DELETE=DELETE"
  run_step vm-clean scripts/vm-clean.sh
fi

run_step vm-check scripts/vm-check-libvirt.sh
run_step vm-disk scripts/vm-create-disk.sh
run_step vm-start scripts/vm-start.sh
run_step vm-bootstrap-ssh scripts/vm-bootstrap-live-ssh.py
run_step vm-ansible-ping scripts/vm-ansible-ping.sh
run_step install scripts/ansible-install-basic-console.sh
run_step vm-shutdown scripts/vm-shutdown.sh
run_step first-boot scripts/vm-validate-first-boot.sh
run_step install-audit scripts/install-audit-bundle.py --state-file "${INSTALL_STATE_FILE:-var/state/current-install.json}" generate

printf 'vm-e2e-install: completed successfully; logs: %s\n' "$e2e_log_dir" | tee -a "$e2e_log_dir/summary.txt"
