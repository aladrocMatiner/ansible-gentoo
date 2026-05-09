#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'qemu-disk: %s\n' "$*" >&2
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

QEMU_DIR=${QEMU_DIR:-var/qemu}
QEMU_DISK=${QEMU_DISK:-${QEMU_DIR}/gentoo-test.qcow2}
QEMU_DISK_SIZE=${QEMU_DISK_SIZE:-40G}

require_command qemu-img
assert_safe_dir "$QEMU_DIR"
assert_safe_disk "$QEMU_DIR" "$QEMU_DISK"

mkdir -p -- "$QEMU_DIR"
assert_safe_dir "$QEMU_DIR"
assert_safe_disk "$QEMU_DIR" "$QEMU_DISK"

if [[ -e "$QEMU_DISK" ]]; then
  [[ -f "$QEMU_DISK" ]] || die "QEMU_DISK exists but is not a regular file: $QEMU_DISK"
  assert_qcow2_image "$QEMU_DISK"
  printf 'qemu-disk: existing disk image preserved: %s\n' "$QEMU_DISK"
  exit 0
fi

printf 'qemu-disk: creating qcow2 disk %s (%s)\n' "$QEMU_DISK" "$QEMU_DISK_SIZE"
qemu-img create -f qcow2 -- "$QEMU_DISK" "$QEMU_DISK_SIZE"
