#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-filesystem-plan
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook

profile=${PROFILE:-openrc}
case "$profile" in
  openrc|systemd) ;;
  *) die "PROFILE must be 'openrc' or 'systemd', got: $profile" ;;
esac

filesystem=${FILESYSTEM:-ext4}
case "$filesystem" in
  ext4|btrfs) ;;
  *) die "FILESYSTEM must be 'ext4' or 'btrfs', got: $filesystem" ;;
esac

[[ -n "${INSTALL_DISK:-}" ]] || die "INSTALL_DISK is required for filesystem-plan and has no default"
[[ "$INSTALL_DISK" != *"*"* && "$INSTALL_DISK" != *"?"* && "$INSTALL_DISK" != *"["* && "$INSTALL_DISK" != *"]"* ]] || die "INSTALL_DISK must not contain wildcard characters: $INSTALL_DISK"

validate_vm_config
if ! ssh_target_env="$(scripts/vm-ssh-target.sh env)"; then
  die "Unable to discover VM SSH target. Start the Gentoo live VM and verify libvirt DHCP/console networking before running filesystem-plan."
fi
eval "$ssh_target_env"
[[ -n "${ANSIBLE_LIVE_USER:-}" ]] || die "VM SSH target discovery did not provide ANSIBLE_LIVE_USER"
[[ -n "${ANSIBLE_LIVE_HOST:-}" ]] || die "VM SSH target discovery did not provide ANSIBLE_LIVE_HOST"
[[ -n "${ANSIBLE_LIVE_PORT:-}" ]] || die "VM SSH target discovery did not provide ANSIBLE_LIVE_PORT"

printf 'Generating read-only %s/%s filesystem plan for %s against %s@%s port %s\n' "$profile" "$filesystem" "$INSTALL_DISK" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory/live.yml \
  -u "$ANSIBLE_LIVE_USER" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "ansible_host=${ANSIBLE_LIVE_HOST}" \
  -e "ansible_port=${ANSIBLE_LIVE_PORT}" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "install_disk=${INSTALL_DISK}" \
  ansible/playbooks/filesystem-plan.yml
