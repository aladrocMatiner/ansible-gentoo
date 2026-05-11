#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=vm-validate-first-boot
source "$(dirname "$0")/vm-libvirt-common.sh"

discover_installed_ip() {
  local ip= mac=

  ip=$(virsh --connect "$LIBVIRT_URI" domifaddr "$VM_NAME" --source agent 2>/dev/null | awk '/ipv4/ { split($4, a, "/"); print a[1]; exit }' || true)
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return 0
  fi
  ip=$(virsh --connect "$LIBVIRT_URI" domifaddr "$VM_NAME" --source lease 2>/dev/null | awk '/ipv4/ { split($4, a, "/"); print a[1]; exit }' || true)
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return 0
  fi
  if [[ "$VM_NET_MODE" == network ]]; then
    mac=$(virsh --connect "$LIBVIRT_URI" domiflist "$VM_NAME" | awk '$5 ~ /^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/ { print tolower($5); exit }')
    [[ -n "$mac" ]] || return 1
    virsh --connect "$LIBVIRT_URI" net-dhcp-leases "$VM_NETWORK" 2>/dev/null |
      awk -v mac="$mac" 'tolower($3) == mac && $4 == "ipv4" { split($5, a, "/"); print a[1]; exit }'
  fi
}

wait_for_ssh() {
  local host=$1
  local port=$2
  local user=$3
  local timeout=$4
  local start now

  start=$(date +%s)
  while true; do
    if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p "$port" "$user@$host" true >/dev/null 2>&1; then
      return 0
    fi
    now=$(date +%s)
    (( now - start < timeout )) || return 1
    sleep 5
  done
}

load_vm_config
require_command virsh
require_command qemu-img
require_command qemu-system-x86_64
require_command ansible-playbook
require_command ssh
validate_vm_config
require_libvirt_connection

install_state_file=${INSTALL_STATE_FILE:-var/state/current-install.json}
expected_hostname=${HOSTNAME:-gentoo}
enable_ssh=${ENABLE_SSH:-no}
admin_sudo_nopasswd=${ADMIN_SUDO_NOPASSWD:-no}
case "$admin_sudo_nopasswd" in
  yes|no) ;;
  *) die_code CONFIG_INVALID "ADMIN_SUDO_NOPASSWD must be yes or no" ;;
esac

state_vars=$(scripts/install-state.py --state-file "$install_state_file" resume-vars)
eval "$state_vars"

case "${INSTALL_STATE_LAST_PHASE:-}" in
  final-checks|install|first-boot-validation) ;;
  *) die_code INSTALL_STATE_INVALID "first-boot validation requires completed install state; last phase is ${INSTALL_STATE_LAST_PHASE:-unset}" ;;
esac

profile=${PROFILE:-${INSTALL_STATE_PROFILE}}
filesystem=${FILESYSTEM:-${INSTALL_STATE_FILESYSTEM}}
admin_user=${ADMIN_USER:-}
[[ -n "$admin_user" ]] || die_code CONFIG_INVALID "ADMIN_USER is required for first-boot validation"
first_boot_user=${FIRST_BOOT_USER:-$admin_user}
first_boot_timeout=${FIRST_BOOT_TIMEOUT:-180}
assert_positive_int FIRST_BOOT_TIMEOUT "$first_boot_timeout"

start_installed_domain=yes
if domain_exists; then
  require_project_marker_and_no_host_block_devices
  require_project_domain_metadata_matches_case
  state=$(virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null || true)
  xml=$(domain_xml)
  if [[ "$state" == running && "$xml" == *"<boot-mode>installed-disk</boot-mode>"* ]]; then
    start_installed_domain=no
  fi
fi

if [[ "$start_installed_domain" == yes ]]; then
  scripts/vm-start-installed.sh
else
  printf 'vm-validate-first-boot: using already-running installed VM: %s\n' "$VM_NAME"
fi

if [[ "$VM_NET_MODE" == user ]]; then
  first_boot_host=$VM_SSH_HOST
  first_boot_port=$VM_SSH_HOST_PORT
else
  first_boot_port=$VM_SSH_GUEST_PORT
  first_boot_host=
  start=$(date +%s)
  while [[ -z "$first_boot_host" ]]; do
    first_boot_host=$(discover_installed_ip || true)
    now=$(date +%s)
    (( now - start < first_boot_timeout )) || die_code NETWORK_UNAVAILABLE "timed out waiting for installed VM DHCP lease"
    [[ -n "$first_boot_host" ]] || sleep 5
  done
fi

assert_host "$first_boot_host"
assert_port FIRST_BOOT_PORT "$first_boot_port"
[[ "$first_boot_user" =~ ^[A-Za-z0-9_.-]+$ ]] || die_code CONFIG_INVALID "FIRST_BOOT_USER contains unsafe characters: $first_boot_user"

printf 'Waiting for installed VM SSH: %s@%s:%s\n' "$first_boot_user" "$first_boot_host" "$first_boot_port"
if ! wait_for_ssh "$first_boot_host" "$first_boot_port" "$first_boot_user" "$first_boot_timeout"; then
  die_code NETWORK_UNAVAILABLE "installed VM did not accept SSH as $first_boot_user within ${first_boot_timeout}s; first-boot validation requires installed SSH access"
fi

inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT
cat >"$inventory_file" <<EOF
all:
  hosts:
    gentoo_installed:
      ansible_connection: ssh
      ansible_host: ${first_boot_host}
      ansible_port: ${first_boot_port}
      ansible_user: ${first_boot_user}
      ansible_python_interpreter: auto_silent
EOF

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "expected_hostname=${expected_hostname}" \
  -e "admin_user=${admin_user}" \
  -e "admin_sudo_nopasswd=${admin_sudo_nopasswd}" \
  -e "enable_ssh=${enable_ssh}" \
  -e "install_run_id=${INSTALL_STATE_RUN_ID}" \
  -e "project_root=$(pwd -P)" \
  ansible/playbooks/first-boot-validate.yml
