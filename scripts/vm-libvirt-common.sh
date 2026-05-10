#!/usr/bin/env bash

PROJECT_MARKER="gentoo-ai-installer-managed-domain"

die() {
  printf '%s: %s\n' "${SCRIPT_NAME:-vm-libvirt}" "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

has_glob_chars() {
  [[ "$1" == *"*"* || "$1" == *"?"* || "$1" == *"["* || "$1" == *"]"* ]]
}

has_unsafe_chars() {
  local value=$1
  [[ "$value" == *" "* || "$value" == *","* || "$value" == *";"* || "$value" == *"|"* || "$value" == *"&"* || "$value" == *"\\"* || "$value" == *"'"* || "$value" == *"\""* || "$value" == *"<"* || "$value" == *">"* || "$value" == *'$'* || "$value" == *$'\n'* || "$value" == *$'\r'* || "$value" == *$'\t'* ]]
}

normalize_path() {
  local path=$1
  if [[ "$path" != /* ]]; then
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

  [[ "$path" != /* ]] || die "path must be project-relative for symlink checks: $path"
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

assert_safe_rel_dir() {
  local name=$1
  local dir=$2
  local abs_project abs_dir

  [[ -n "$dir" ]] || die "$name is empty"
  [[ "$dir" != /* ]] || die "$name must be relative to the project: $dir"
  [[ "$dir" != *".."* ]] || die "$name must not contain parent traversal: $dir"
  [[ "$dir" != /dev && "$dir" != /dev/* ]] || die "$name must not be under /dev: $dir"
  ! has_glob_chars "$dir" || die "$name must not contain wildcard characters: $dir"
  ! has_unsafe_chars "$dir" || die "$name contains unsafe characters: $dir"
  abs_project=$(normalize_path ".")
  abs_dir=$(normalize_path "$dir")
  [[ "$abs_dir" != "$abs_project" ]] || die "$name must not be the project root: $dir"
  [[ ! -L "$dir" ]] || die "$name must not be a symlink: $dir"
  assert_no_symlink_components "$dir"
}

assert_safe_disk() {
  local dir=$1
  local disk=$2
  local abs_dir abs_disk disk_parent

  [[ -n "$disk" ]] || die "VM_DISK is empty"
  [[ "$disk" != /* ]] || die "VM_DISK must be relative to the project: $disk"
  [[ "$disk" != /dev && "$disk" != /dev/* ]] || die "refusing host block-device path for VM_DISK: $disk"
  [[ "$disk" != *".."* ]] || die "VM_DISK must not contain parent traversal: $disk"
  ! has_glob_chars "$disk" || die "VM_DISK must not contain wildcard characters: $disk"
  ! has_unsafe_chars "$disk" || die "VM_DISK contains unsafe characters: $disk"
  [[ "$disk" == *.qcow2 ]] || die "VM_DISK must use .qcow2 extension: $disk"

  abs_dir=$(normalize_path "$dir")
  abs_disk=$(normalize_path "$disk")
  case "$abs_disk" in
    "$abs_dir"/*) ;;
    *) die "VM_DISK must stay under VM_DIR ($dir): $disk" ;;
  esac

  [[ ! -L "$disk" ]] || die "VM_DISK must not be a symlink: $disk"
  disk_parent=$(dirname -- "$disk")
  [[ ! -L "$disk_parent" ]] || die "VM_DISK parent directory must not be a symlink: $disk_parent"
  assert_no_symlink_components "$disk_parent"
}

assert_qcow2_image() {
  local disk=$1
  local line

  while IFS= read -r line; do
    [[ "$line" == "file format: qcow2" ]] && return 0
  done < <(qemu-img info --force-share -- "$disk" 2>/dev/null)

  die "VM_DISK exists but is not a qcow2 image: $disk"
}

assert_safe_generated_file() {
  local label=$1
  local path=$2
  local parent

  [[ -n "$path" ]] || die "$label path is empty"
  [[ "$path" != /* ]] || die "$label path must be relative to the project: $path"
  [[ "$path" != *".."* ]] || die "$label path must not contain parent traversal: $path"
  ! has_glob_chars "$path" || die "$label path must not contain wildcard characters: $path"
  ! has_unsafe_chars "$path" || die "$label path contains unsafe characters: $path"
  parent=$(dirname -- "$path")
  assert_no_symlink_components "$parent"
  [[ ! -L "$path" ]] || die "$label path must not be a symlink: $path"
  if [[ -e "$path" ]]; then
    [[ -f "$path" ]] || die "$label path exists but is not a regular file: $path"
  fi
}

assert_safe_name() {
  local name=$1
  [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,62}$ ]] || die "VM_NAME must be a conservative libvirt domain name: $name"
}

assert_port() {
  local label=$1
  local port=$2
  [[ "$port" =~ ^[0-9]+$ ]] || die "$label must be numeric: $port"
  (( port >= 1 && port <= 65535 )) || die "$label must be between 1 and 65535: $port"
}

assert_positive_int() {
  local label=$1
  local value=$2
  [[ "$value" =~ ^[0-9]+$ ]] || die "$label must be numeric: $value"
  (( value >= 1 )) || die "$label must be greater than zero: $value"
}

assert_disk_size() {
  local size=$1
  [[ "$size" =~ ^[0-9]+([KMGTP]?)$ ]] || die "VM_DISK_SIZE must be a simple qemu-img size such as 40G: $size"
}

assert_host() {
  local host=$1
  [[ "$host" =~ ^[A-Za-z0-9_.:-]+$ ]] || die "VM_SSH_HOST contains unsafe characters: $host"
}

assert_network_name() {
  local network=$1
  [[ "$network" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,62}$ ]] || die "VM_NETWORK must be a conservative libvirt network name: $network"
}

resolve_iso_path() {
  local iso=$1
  [[ -n "$iso" ]] || die "VM_ISO is empty"
  [[ "$iso" != /dev && "$iso" != /dev/* ]] || die "VM_ISO must not point under /dev: $iso"
  ! has_glob_chars "$iso" || die "VM_ISO must not contain wildcard characters: $iso"
  ! has_unsafe_chars "$iso" || die "VM_ISO contains unsafe characters: $iso"

  if [[ -f "$iso" ]]; then
    normalize_path "$iso"
    return 0
  fi

  if [[ -d "$iso" ]]; then
    local matches=()
    while IFS= read -r -d '' candidate; do
      matches+=("$candidate")
    done < <(find "$iso" -maxdepth 1 -type f -name '*.iso' -print0 | sort -z)
    case "${#matches[@]}" in
      1) normalize_path "${matches[0]}"; return 0 ;;
      0) die "VM_ISO directory contains no .iso file: $iso" ;;
      *) die "VM_ISO directory contains multiple .iso files; set VM_ISO to one file: $iso" ;;
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

load_vm_config() {
  LIBVIRT_URI=${LIBVIRT_URI:-qemu:///system}
  VM_NET_MODE=${VM_NET_MODE:-network}
  VM_NAME=${VM_NAME:-gentoo-ai-installer}
  VM_ISO=${VM_ISO:-gentoo.iso}
  VM_DIR=${VM_DIR:-var/libvirt}
  VM_DISK=${VM_DISK:-${VM_DIR}/gentoo-ai-installer.qcow2}
  VM_DISK_SIZE=${VM_DISK_SIZE:-40G}
  VM_RAM=${VM_RAM:-4096}
  VM_CPUS=${VM_CPUS:-2}
  VM_NETWORK=${VM_NETWORK:-default}
  VM_SSH_HOST=${VM_SSH_HOST:-127.0.0.1}
  VM_SSH_HOST_PORT=${VM_SSH_HOST_PORT:-2222}
  VM_SSH_GUEST_PORT=${VM_SSH_GUEST_PORT:-22}
  VM_SSH_USER=${VM_SSH_USER:-root}
  VM_BOOT_MODE=${VM_BOOT_MODE:-uefi}
  VM_KERNEL_ARGS=${VM_KERNEL_ARGS:-"dokeymap nodhcp root=live:CDLABEL=Gentoo-amd64-20260426 rd.live.dir=/ rd.live.squashimg=image.squashfs cdroot console=tty0 console=ttyS0,115200n8"}

  VM_XML="${VM_DIR}/${VM_NAME}.xml"
  VM_NVRAM_DIR="${VM_DIR}/nvram"
  VM_NVRAM="${VM_NVRAM_DIR}/${VM_NAME}_VARS.fd"
  VM_KERNEL="${VM_DIR}/${VM_NAME}-gentoo-kernel"
  VM_INITRD="${VM_DIR}/${VM_NAME}-gentoo-initrd"
  VM_LOG_DIR="logs/libvirt"
}

validate_vm_config() {
  assert_safe_name "$VM_NAME"
  assert_safe_rel_dir VM_DIR "$VM_DIR"
  assert_safe_disk "$VM_DIR" "$VM_DISK"
  case "$VM_BOOT_MODE" in
    uefi) ;;
    bios) die "VM_BOOT_MODE=bios is not supported in v1; this project targets UEFI only" ;;
    *) die "VM_BOOT_MODE must be 'uefi', got: $VM_BOOT_MODE" ;;
  esac
  case "$VM_NET_MODE" in
    user) ;;
    network)
      [[ -n "$VM_NETWORK" ]] || die "VM_NETWORK is required when VM_NET_MODE=network"
      assert_network_name "$VM_NETWORK"
      ;;
    *) die "VM_NET_MODE must be 'user' or 'network', got: $VM_NET_MODE" ;;
  esac
  assert_host "$VM_SSH_HOST"
  assert_port VM_SSH_HOST_PORT "$VM_SSH_HOST_PORT"
  assert_port VM_SSH_GUEST_PORT "$VM_SSH_GUEST_PORT"
  assert_positive_int VM_RAM "$VM_RAM"
  assert_positive_int VM_CPUS "$VM_CPUS"
  assert_disk_size "$VM_DISK_SIZE"
  [[ "$VM_SSH_USER" =~ ^[A-Za-z0-9_.-]+$ ]] || die "VM_SSH_USER contains unsafe characters: $VM_SSH_USER"
}

require_libvirt_connection() {
  virsh --connect "$LIBVIRT_URI" uri >/dev/null 2>&1 || die "cannot connect to libvirt URI: $LIBVIRT_URI"
}

domain_exists() {
  virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1
}

domain_xml() {
  virsh --connect "$LIBVIRT_URI" dumpxml "$VM_NAME" 2>/dev/null
}

domain_is_project_owned() {
  domain_xml | grep -Fq "$PROJECT_MARKER"
}

require_project_owned_domain_if_exists() {
  if domain_exists && ! domain_is_project_owned; then
    die "libvirt domain exists but is not marked as project-owned: $VM_NAME"
  fi
}

ensure_artifact_dirs() {
  mkdir -p -- "$VM_DIR" "$VM_NVRAM_DIR"
  assert_safe_rel_dir VM_DIR "$VM_DIR"
  assert_safe_disk "$VM_DIR" "$VM_DISK"
  assert_safe_generated_file VM_XML "$VM_XML"
  assert_safe_generated_file VM_NVRAM "$VM_NVRAM"
  assert_safe_generated_file VM_KERNEL "$VM_KERNEL"
  assert_safe_generated_file VM_INITRD "$VM_INITRD"
}

print_config() {
  printf 'libvirt VM configuration:\n'
  printf '  LIBVIRT_URI: %s\n' "$LIBVIRT_URI"
  printf '  VM_NAME: %s\n' "$VM_NAME"
  printf '  VM_ISO: %s\n' "$(resolve_iso_path "$VM_ISO")"
  printf '  VM_DIR: %s\n' "$VM_DIR"
  printf '  VM_DISK: %s\n' "$VM_DISK"
  printf '  VM_DISK_SIZE: %s\n' "$VM_DISK_SIZE"
  printf '  VM_RAM: %s MB\n' "$VM_RAM"
  printf '  VM_CPUS: %s\n' "$VM_CPUS"
  printf '  VM_BOOT_MODE: %s\n' "$VM_BOOT_MODE"
  printf '  VM_NET_MODE: %s\n' "$VM_NET_MODE"
  printf '  VM_KERNEL_ARGS: %s\n' "$VM_KERNEL_ARGS"
  if [[ "$VM_NET_MODE" == user ]]; then
    printf '  SSH forwarding: %s:%s -> guest port %s\n' "$VM_SSH_HOST" "$VM_SSH_HOST_PORT" "$VM_SSH_GUEST_PORT"
  else
    printf '  VM_NETWORK: %s\n' "$VM_NETWORK"
  fi
}
