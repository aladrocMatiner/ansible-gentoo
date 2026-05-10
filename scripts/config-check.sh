#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=config-check
SCHEMA_PATH=${INSTALL_CONFIG_SCHEMA:-config/install-schema.yml}

errors=()
warnings=()

add_error() {
  local code=$1
  local message=$2
  errors+=("${code}: ${message}")
}

add_warning() {
  local code=$1
  local message=$2
  warnings+=("${code}: ${message}")
}

has_unsafe_chars() {
  local value=$1
  [[ "$value" == *" "* || "$value" == *","* || "$value" == *";"* || "$value" == *"|"* || "$value" == *"&"* || "$value" == *"\\"* || "$value" == *"'"* || "$value" == *"\""* || "$value" == *"<"* || "$value" == *">"* || "$value" == *'$'* || "$value" == *$'\n'* || "$value" == *$'\r'* || "$value" == *$'\t'* ]]
}

has_glob_chars() {
  local value=$1
  [[ "$value" == *"*"* || "$value" == *"?"* || "$value" == *"["* || "$value" == *"]"* ]]
}

is_yes_no() {
  case "$1" in
    yes|no) return 0 ;;
    *) return 1 ;;
  esac
}

validate_hostname() {
  local value=$1

  [[ -n "$value" ]] || {
    add_error CONFIG_INVALID "HOSTNAME must not be empty"
    return
  }
  [[ "${#value}" -le 63 ]] || add_error CONFIG_INVALID "HOSTNAME must be 63 characters or shorter"
  [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || add_error CONFIG_INVALID "HOSTNAME must be a simple Linux hostname using letters, digits, and hyphens"
}

validate_username() {
  local label=$1
  local value=$2

  [[ -z "$value" ]] && return
  [[ "$value" =~ ^[a-z_][a-z0-9_-]{0,31}\$?$ ]] || add_error CONFIG_INVALID "${label} must be a conservative local username"
}

validate_mount_path() {
  local label=$1
  local value=$2

  [[ "$value" == /* ]] || add_error CONFIG_INVALID "${label} must be an absolute path"
  [[ "$value" != "/" ]] || add_error CONFIG_INVALID "${label} must not be /"
  [[ "$value" != *".."* ]] || add_error CONFIG_INVALID "${label} must not contain parent traversal"
  ! has_unsafe_chars "$value" || add_error CONFIG_INVALID "${label} contains unsafe characters"
  ! has_glob_chars "$value" || add_error CONFIG_INVALID "${label} must not contain glob characters"
}

validate_url() {
  local label=$1
  local value=$2

  [[ "$value" == https://* ]] || add_error CONFIG_INVALID "${label} must be an https:// URL"
  [[ "$value" != *".."* ]] || add_error CONFIG_INVALID "${label} must not contain parent traversal"
  ! has_unsafe_chars "$value" || add_error CONFIG_INVALID "${label} contains unsafe characters"
  ! has_glob_chars "$value" || add_error CONFIG_INVALID "${label} must not contain glob characters"
}

validate_install_disk_if_set() {
  local value=$1

  [[ -z "$value" ]] && return
  [[ "$value" == /dev/* ]] || add_error DISK_UNSAFE "INSTALL_DISK must be an explicit /dev path from the target live ISO"
  [[ "$value" != "/dev/" && "$value" != "/dev" ]] || add_error DISK_UNSAFE "INSTALL_DISK must name a concrete disk, not /dev"
  [[ "$value" != *".."* ]] || add_error DISK_UNSAFE "INSTALL_DISK must not contain parent traversal"
  [[ "$value" != *"="* ]] || add_error DISK_UNSAFE "INSTALL_DISK must not contain '='"
  ! has_unsafe_chars "$value" || add_error DISK_UNSAFE "INSTALL_DISK contains unsafe characters"
  ! has_glob_chars "$value" || add_error DISK_UNSAFE "INSTALL_DISK must not contain wildcard characters"
}

validate_no_secret_like_values() {
  local label value

  for label in HOSTNAME ADMIN_USER TARGET_MOUNT EFI_MOUNT INSTALL_DISK STAGE3_MIRROR STAGE3_CACHE_DIR; do
    value=${!label:-}
    [[ -z "$value" ]] && continue
    if [[ "$value" == *"-----BEGIN "* || "$value" == sk-* || "$value" == *" API KEY "* ]]; then
      add_error SECRET_LEAK_RISK "${label} appears to contain secret material; use the approved secret input workflow instead"
    fi
  done

  for label in ROOT_PASSWORD ADMIN_PASSWORD USER_PASSWORD SSH_PRIVATE_KEY; do
    if [[ -n "${!label:-}" ]]; then
      add_error SECRET_LEAK_RISK "${label} is set in the environment; do not pass installer secrets through Makefile or logged environment variables"
    fi
  done
}

schema_exists() {
  [[ -f "$SCHEMA_PATH" ]] || add_error CONFIG_INVALID "schema file is missing: ${SCHEMA_PATH}"
}

profile=${PROFILE:-openrc}
filesystem=${FILESYSTEM:-ext4}
boot_mode=${BOOT_MODE:-uefi}
target_hostname=${HOSTNAME:-gentoo}
admin_user=${ADMIN_USER:-}
enable_ssh=${ENABLE_SSH:-no}
target_mount=${TARGET_MOUNT:-/mnt/gentoo}
efi_mount=${EFI_MOUNT:-${target_mount}/boot/efi}
install_disk=${INSTALL_DISK:-}
confirm_wipe_disk=${I_UNDERSTAND_THIS_WIPES_DISK:-}
stage3_mirror=${STAGE3_MIRROR:-https://distfiles.gentoo.org/releases/amd64/autobuilds}
stage3_cache_dir=${STAGE3_CACHE_DIR:-/tmp/gentoo-ai-installer/stage3}
config_requires_install_disk=${CONFIG_REQUIRE_INSTALL_DISK:-no}
config_destructive=${CONFIG_DESTRUCTIVE:-no}

schema_exists

case "$profile" in
  openrc|systemd) ;;
  *) add_error CONFIG_INVALID "PROFILE must be openrc or systemd" ;;
esac

case "$filesystem" in
  ext4|btrfs) ;;
  *) add_error CONFIG_INVALID "FILESYSTEM must be ext4 or btrfs" ;;
esac

case "$boot_mode" in
  uefi) ;;
  bios) add_error UNSUPPORTED_CONFIGURATION "BOOT_MODE=bios is outside v1 scope; UEFI is required" ;;
  *) add_error CONFIG_INVALID "BOOT_MODE must be uefi" ;;
esac

is_yes_no "$enable_ssh" || add_error CONFIG_INVALID "ENABLE_SSH must be yes or no"
is_yes_no "$config_requires_install_disk" || add_error CONFIG_INVALID "CONFIG_REQUIRE_INSTALL_DISK must be yes or no"
is_yes_no "$config_destructive" || add_error CONFIG_INVALID "CONFIG_DESTRUCTIVE must be yes or no"

validate_hostname "$target_hostname"
validate_username ADMIN_USER "$admin_user"
validate_mount_path TARGET_MOUNT "$target_mount"
validate_mount_path EFI_MOUNT "$efi_mount"
validate_mount_path STAGE3_CACHE_DIR "$stage3_cache_dir"
validate_url STAGE3_MIRROR "$stage3_mirror"

if [[ "$efi_mount" != "$target_mount"/* ]]; then
  add_error CONFIG_INVALID "EFI_MOUNT must be below TARGET_MOUNT"
fi

if [[ "$stage3_cache_dir" == "$target_mount" || "$stage3_cache_dir" == "$target_mount"/* ]]; then
  add_error CONFIG_INVALID "STAGE3_CACHE_DIR must not be inside TARGET_MOUNT"
fi

validate_install_disk_if_set "$install_disk"

if [[ "$config_requires_install_disk" == yes && -z "$install_disk" ]]; then
  add_error DISK_UNSAFE "INSTALL_DISK is required for this workflow and has no default"
fi

if [[ -z "$install_disk" ]]; then
  add_warning DISK_UNSET "INSTALL_DISK is unset; this is valid for read-only planning but destructive apply workflows must set it explicitly"
fi

if [[ "$config_destructive" == yes ]]; then
  [[ -n "$install_disk" ]] || add_error DISK_UNSAFE "destructive workflows require INSTALL_DISK"
  [[ "$confirm_wipe_disk" == yes ]] || add_error DESTRUCTIVE_CONFIRMATION_MISSING "destructive workflows require I_UNDERSTAND_THIS_WIPES_DISK=yes"
elif [[ "$confirm_wipe_disk" == yes ]]; then
  add_warning DESTRUCTIVE_CONFIRMATION_IGNORED "I_UNDERSTAND_THIS_WIPES_DISK=yes is set for a non-destructive config check"
fi

validate_no_secret_like_values

printf 'Configuration validation report\n'
printf '  schema: %s\n' "$SCHEMA_PATH"
printf '  PROFILE: %s\n' "$profile"
printf '  FILESYSTEM: %s\n' "$filesystem"
printf '  STAGE3_MIRROR: %s\n' "$stage3_mirror"
printf '  STAGE3_CACHE_DIR: %s\n' "$stage3_cache_dir"
printf '  BOOT_MODE: %s\n' "$boot_mode"
printf '  HOSTNAME: %s\n' "$target_hostname"
printf '  ADMIN_USER: %s\n' "${admin_user:-<unset>}"
printf '  ENABLE_SSH: %s\n' "$enable_ssh"
printf '  TARGET_MOUNT: %s\n' "$target_mount"
printf '  EFI_MOUNT: %s\n' "$efi_mount"
printf '  INSTALL_DISK: %s\n' "${install_disk:-<unset>}"
printf '  destructive mode: %s\n' "$config_destructive"

if [[ "${#warnings[@]}" -gt 0 ]]; then
  printf '\nWarnings:\n'
  printf '  %s\n' "${warnings[@]}"
fi

if [[ "${#errors[@]}" -gt 0 ]]; then
  printf '\nErrors:\n' >&2
  printf '  %s\n' "${errors[@]}" >&2
  printf '\nResult: FAIL\n' >&2
  exit 1
fi

printf '\nResult: PASS\n'
printf 'Next: run make ansible-live-preflight for a booted live ISO target, then make detect-disks.\n'
