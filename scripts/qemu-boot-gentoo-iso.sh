#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'qemu-boot: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

assert_qcow2_image() {
  local disk=$1
  local line

  while IFS= read -r line; do
    [[ "$line" == "file format: qcow2" ]] && return 0
  done < <(qemu-img info -- "$disk" 2>/dev/null)

  die "QEMU_DISK exists but is not a qcow2 image: $disk"
}

has_glob_chars() {
  [[ "$1" == *"*"* || "$1" == *"?"* || "$1" == *"["* ]]
}

has_qemu_option_separator() {
  [[ "$1" == *","* ]]
}

normalize_path() {
  local path=$1
  if [[ "$path" = /* ]]; then
    :
  else
    path="$PWD/$path"
  fi
  while [[ "$path" == *"/./"* ]]; do
    path=${path//\/.\//\/}
  done
  while [[ "$path" == *"//"* ]]; do
    path=${path//\/\//\/}
  done
  while [[ "$path" != "/" && "$path" == */. ]]; do
    path=${path%/.}
  done
  while [[ "$path" != "/" && "$path" == */ ]]; do
    path=${path%/}
  done
  printf '%s\n' "$path"
}

assert_no_symlink_components() {
  local path=$1
  local current=
  local component

  [[ "$path" != /* ]] || die "path must be relative to check symlink components: $path"
  path=${path#./}
  path=${path%/}
  IFS=/ read -ra components <<< "$path"
  for component in "${components[@]}"; do
    [[ -n "$component" && "$component" != "." ]] || continue
    if [[ -z "$current" ]]; then
      current=$component
    else
      current="$current/$component"
    fi
    [[ ! -L "$current" ]] || die "path component must not be a symlink: $current"
  done
}

assert_safe_dir() {
  local dir=$1
  local abs_project abs_dir

  [[ -n "$dir" ]] || die "QEMU_DIR is empty"
  [[ "$dir" != /* ]] || die "QEMU_DIR must be relative to the project: $dir"
  [[ "$dir" != *".."* ]] || die "QEMU_DIR must not contain parent traversal: $dir"
  [[ "$dir" != / ]] || die "QEMU_DIR must not be /"
  [[ "$dir" != /dev && "$dir" != /dev/* ]] || die "QEMU_DIR must not be under /dev"
  ! has_glob_chars "$dir" || die "QEMU_DIR must not contain wildcard characters"
  ! has_qemu_option_separator "$dir" || die "QEMU_DIR must not contain QEMU option separators: $dir"
  abs_project=$(normalize_path ".")
  abs_dir=$(normalize_path "$dir")
  [[ "$abs_dir" != "$abs_project" ]] || die "QEMU_DIR must not be the project root: $dir"
  [[ ! -L "$dir" ]] || die "QEMU_DIR must not be a symlink: $dir"
  assert_no_symlink_components "$dir"
}

assert_safe_disk() {
  local dir=$1
  local disk=$2

  [[ -n "$disk" ]] || die "QEMU_DISK is empty"
  [[ "$disk" != /* ]] || die "QEMU_DISK must be relative to the project: $disk"
  [[ "$disk" != /dev && "$disk" != /dev/* ]] || die "refusing host block-device path for QEMU_DISK: $disk"
  [[ "$disk" != *".."* ]] || die "QEMU_DISK must not contain parent traversal: $disk"
  ! has_glob_chars "$disk" || die "QEMU_DISK must not contain wildcard characters"
  ! has_qemu_option_separator "$disk" || die "QEMU_DISK must not contain QEMU option separators: $disk"

  local abs_dir abs_disk
  abs_dir=$(normalize_path "$dir")
  abs_disk=$(normalize_path "$disk")

  case "$abs_disk" in
    "$abs_dir"/*) ;;
    *) die "QEMU_DISK must be under QEMU_DIR ($dir): $disk" ;;
  esac

  [[ "$disk" == *.qcow2 ]] || die "QEMU_DISK must use .qcow2 extension by default: $disk"
  [[ ! -L "$disk" ]] || die "QEMU_DISK must not be a symlink: $disk"

  local disk_parent
  disk_parent=$(dirname -- "$disk")
  [[ ! -L "$disk_parent" ]] || die "QEMU_DISK parent directory must not be a symlink: $disk_parent"
  assert_no_symlink_components "$disk_parent"
}

assert_safe_firmware_file() {
  local name=$1
  local path=$2

  [[ -n "$path" ]] || die "$name is empty"
  [[ "$path" != /dev && "$path" != /dev/* ]] || die "$name must not point under /dev: $path"
  ! has_glob_chars "$path" || die "$name must not contain wildcard characters"
  ! has_qemu_option_separator "$path" || die "$name must not contain QEMU option separators"
  [[ -f "$path" && -r "$path" ]] || die "$name is not a readable regular file: $path"
}

resolve_iso_path() {
  local iso=$1
  [[ -n "$iso" ]] || die "QEMU_ISO is empty"
  ! has_glob_chars "$iso" || die "QEMU_ISO must not contain wildcard characters"
  [[ "$iso" != /dev && "$iso" != /dev/* ]] || die "QEMU_ISO must not point under /dev: $iso"

  if [[ -f "$iso" ]]; then
    printf '%s\n' "$iso"
    return 0
  fi

  if [[ -d "$iso" ]]; then
    local matches=()
    while IFS= read -r -d '' candidate; do
      matches+=("$candidate")
    done < <(find "$iso" -maxdepth 1 -type f -name '*.iso' -print0 | sort -z)

    case "${#matches[@]}" in
      1)
        printf '%s\n' "${matches[0]}"
        return 0
        ;;
      0)
        die "QEMU_ISO directory contains no .iso file: $iso"
        ;;
      *)
        die "QEMU_ISO directory contains multiple .iso files; set QEMU_ISO to one file: $iso"
        ;;
    esac
  fi

  die "ISO file not found or not a regular file/directory: $iso"
}

find_ovmf_code() {
  local candidate
  for candidate in \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
    /usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd \
    /usr/share/qemu/OVMF_CODE.fd \
    /usr/share/qemu/edk2-x86_64-code.fd; do
    [[ -r "$candidate" ]] && printf '%s\n' "$candidate" && return 0
  done
  return 1
}

find_ovmf_vars_template() {
  local candidate
  for candidate in \
    /usr/share/OVMF/OVMF_VARS.fd \
    /usr/share/OVMF/OVMF_VARS_4M.fd \
    /usr/share/edk2-ovmf/x64/OVMF_VARS.fd \
    /usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd \
    /usr/share/qemu/OVMF_VARS.fd \
    /usr/share/qemu/edk2-x86_64-vars.fd; do
    [[ -r "$candidate" ]] && printf '%s\n' "$candidate" && return 0
  done
  return 1
}

QEMU_ISO=${QEMU_ISO:-gentoo.iso}
QEMU_DIR=${QEMU_DIR:-var/qemu}
QEMU_DISK=${QEMU_DISK:-${QEMU_DIR}/gentoo-test.qcow2}
QEMU_RAM=${QEMU_RAM:-4096}
QEMU_CPUS=${QEMU_CPUS:-2}
QEMU_BOOT_MODE=${QEMU_BOOT_MODE:-uefi}
QEMU_OVMF_CODE=${QEMU_OVMF_CODE:-}
QEMU_OVMF_VARS=${QEMU_OVMF_VARS:-}
QEMU_CHECK_ONLY=${QEMU_CHECK_ONLY:-0}

require_command qemu-system-x86_64
require_command qemu-img
assert_safe_dir "$QEMU_DIR"
assert_safe_disk "$QEMU_DIR" "$QEMU_DISK"
if [[ -e "$QEMU_DISK" ]]; then
  [[ -f "$QEMU_DISK" ]] || die "QEMU_DISK exists but is not a regular file: $QEMU_DISK"
  assert_qcow2_image "$QEMU_DISK"
fi

case "$QEMU_BOOT_MODE" in
  uefi) ;;
  bios) die "QEMU_BOOT_MODE=bios is not supported in v1; this project targets UEFI only" ;;
  *) die "QEMU_BOOT_MODE must be 'uefi', got: $QEMU_BOOT_MODE" ;;
esac

resolved_iso=$(resolve_iso_path "$QEMU_ISO")
if [[ "$QEMU_CHECK_ONLY" != 1 ]]; then
  mkdir -p -- "$QEMU_DIR"
  assert_safe_dir "$QEMU_DIR"
  assert_safe_disk "$QEMU_DIR" "$QEMU_DISK"
fi

ovmf_code=
ovmf_vars=
ovmf_vars_template=
if [[ "$QEMU_BOOT_MODE" == uefi ]]; then
  if [[ -n "$QEMU_OVMF_CODE" ]]; then
    assert_safe_firmware_file QEMU_OVMF_CODE "$QEMU_OVMF_CODE"
    ovmf_code=$QEMU_OVMF_CODE
  else
    ovmf_code=$(find_ovmf_code) || die "UEFI boot requested but OVMF code firmware was not found; set QEMU_OVMF_CODE"
  fi

  ovmf_vars="${QEMU_DIR}/gentoo-test-OVMF_VARS.fd"
  if [[ -n "$QEMU_OVMF_VARS" ]]; then
    assert_safe_firmware_file QEMU_OVMF_VARS "$QEMU_OVMF_VARS"
    ovmf_vars_template=$QEMU_OVMF_VARS
  else
    ovmf_vars_template=$(find_ovmf_vars_template) || die "UEFI boot requested but OVMF vars template was not found; set QEMU_OVMF_VARS"
  fi

  [[ ! -L "$ovmf_vars" ]] || die "per-VM OVMF vars file must not be a symlink: $ovmf_vars"
  [[ ! -e "$ovmf_vars" || -f "$ovmf_vars" ]] || die "per-VM OVMF vars path exists but is not a regular file: $ovmf_vars"
  if [[ "$QEMU_CHECK_ONLY" != 1 && ! -e "$ovmf_vars" ]]; then
    if [[ -n "$QEMU_OVMF_VARS" ]]; then
      cp -- "$QEMU_OVMF_VARS" "$ovmf_vars"
    else
      cp -- "$ovmf_vars_template" "$ovmf_vars"
    fi
    chmod u+rw -- "$ovmf_vars"
  fi
  [[ "$QEMU_CHECK_ONLY" == 1 || -f "$ovmf_vars" ]] || die "per-VM OVMF vars path was not created as a regular file: $ovmf_vars"
fi

if [[ "$QEMU_CHECK_ONLY" == 1 ]]; then
  printf 'qemu-check: OK\n'
  printf '  ISO: %s\n' "$resolved_iso"
  printf '  QEMU_DIR: %s\n' "$QEMU_DIR"
  printf '  QEMU_DISK: %s\n' "$QEMU_DISK"
  printf '  boot mode: %s\n' "$QEMU_BOOT_MODE"
  if [[ "$QEMU_BOOT_MODE" == uefi ]]; then
    printf '  OVMF code: %s\n' "$ovmf_code"
    printf '  OVMF vars template: %s\n' "$ovmf_vars_template"
    printf '  per-VM OVMF vars path: %s\n' "$ovmf_vars"
  fi
  exit 0
fi

[[ -f "$QEMU_DISK" ]] || die "disk image not found: $QEMU_DISK; run make qemu-disk first"
assert_qcow2_image "$QEMU_DISK"

qemu_args=(
  -name gentoo-ai-installer-test
  -machine q35,accel=kvm:tcg
  -m "$QEMU_RAM"
  -smp "$QEMU_CPUS"
  -cdrom "$resolved_iso"
  -boot d
  -drive "file=${QEMU_DISK},if=virtio,format=qcow2"
  -nic user,model=virtio-net-pci
)

if [[ "$QEMU_BOOT_MODE" == uefi ]]; then
  qemu_args+=(
    -drive "if=pflash,format=raw,readonly=on,file=${ovmf_code}"
    -drive "if=pflash,format=raw,file=${ovmf_vars}"
  )
fi

printf 'QEMU manual install test VM configuration:\n'
printf '  ISO: %s\n' "$resolved_iso"
printf '  disk: %s\n' "$QEMU_DISK"
printf '  disk format: qcow2\n'
printf '  RAM: %s MB\n' "$QEMU_RAM"
printf '  CPUs: %s\n' "$QEMU_CPUS"
printf '  boot mode: %s\n' "$QEMU_BOOT_MODE"
printf '  network: user-mode NAT\n'
printf '  display: graphical\n'
if [[ "$QEMU_BOOT_MODE" == uefi ]]; then
  printf '  OVMF code: %s\n' "$ovmf_code"
  printf '  per-VM OVMF vars: %s\n' "$ovmf_vars"
fi

exec qemu-system-x86_64 "${qemu_args[@]}"
