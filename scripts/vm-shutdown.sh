#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-shutdown
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command virsh
validate_vm_config
require_libvirt_connection
if domain_exists; then
  require_project_marker_and_no_host_block_devices
  require_project_domain_metadata_matches_case
fi
domain_exists || die "domain is not defined: $VM_NAME"
state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
if [[ "$state" == running || "$state" == paused ]]; then
  shutdown_timeout=${VM_SHUTDOWN_TIMEOUT:-120}
  assert_positive_int VM_SHUTDOWN_TIMEOUT "$shutdown_timeout"
  shutdown_ssh=${VM_SHUTDOWN_SSH:-auto}
  case "$shutdown_ssh" in
    auto|yes|no) ;;
    *) die "VM_SHUTDOWN_SSH must be auto, yes, or no" ;;
  esac

  ssh_shutdown_requested=no
  if [[ "$shutdown_ssh" != no ]] && command -v ssh >/dev/null 2>&1; then
    set +e
    target_env=$(VM_IP_WAIT_TIMEOUT=${VM_IP_WAIT_TIMEOUT:-20} scripts/vm-ssh-target.sh env 2>/dev/null)
    target_status=$?
    set -e
    if [[ "$target_status" -eq 0 && -n "$target_env" ]]; then
      eval "$target_env"
      ssh_common_args=$(ansible_ssh_common_args)
      read -r -a ssh_args <<< "$ssh_common_args"
      if ssh -o BatchMode=yes "${ssh_args[@]}" -p "$ANSIBLE_LIVE_PORT" "$ANSIBLE_LIVE_USER@$ANSIBLE_LIVE_HOST" true >/dev/null 2>&1; then
        printf 'vm-shutdown: requesting guest sync and poweroff over SSH: %s@%s:%s\n' "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
        ssh_shutdown_requested=yes
        ssh -o BatchMode=yes "${ssh_args[@]}" -p "$ANSIBLE_LIVE_PORT" "$ANSIBLE_LIVE_USER@$ANSIBLE_LIVE_HOST" 'sync; poweroff' >/dev/null 2>&1 || true
      elif [[ "$shutdown_ssh" == yes ]]; then
        die "VM_SHUTDOWN_SSH=yes but SSH did not accept a batch connection for $VM_NAME"
      fi
    elif [[ "$shutdown_ssh" == yes ]]; then
      die "VM_SHUTDOWN_SSH=yes but SSH target discovery failed for $VM_NAME"
    fi
  elif [[ "$shutdown_ssh" == yes ]]; then
    die "VM_SHUTDOWN_SSH=yes but ssh is not available"
  fi

  if [[ "$ssh_shutdown_requested" == no ]]; then
    virsh --connect "$LIBVIRT_URI" shutdown "$VM_NAME"
  fi
  start=$(date +%s)
  while true; do
    state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
    case "$state" in
      shut\ off|shutoff|crashed)
        printf 'vm-shutdown: domain is inactive: %s is %s\n' "$VM_NAME" "$state"
        break
        ;;
    esac
    now=$(date +%s)
    (( now - start < shutdown_timeout )) || die "timed out waiting for clean guest shutdown of $VM_NAME within ${shutdown_timeout}s"
    sleep 2
  done
else
  printf 'vm-shutdown: domain is already inactive: %s is %s\n' "$VM_NAME" "${state:-unknown}"
fi
