#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-configure-portage
source "$(dirname "$0")/vm-libvirt-common.sh"

load_vm_config
require_command ansible-playbook
scripts/config-check.sh
require_ansible_live_target configure-portage

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

stage3_flavor=${STAGE3_FLAVOR:-standard}
case "$stage3_flavor" in
  standard|hardened|musl) ;;
  *) die "STAGE3_FLAVOR must be 'standard', 'hardened', or 'musl', got: $stage3_flavor" ;;
esac

portage_gentoo_mirrors=${PORTAGE_GENTOO_MIRRORS:-https://distfiles.gentoo.org}
project_root=$(pwd -P)
inventory_file=$(mktemp --suffix=.yml)
trap 'rm -f "$inventory_file"' EXIT

cat >"$inventory_file" <<EOF
all:
  hosts:
    gentoo_live:
      ansible_connection: ssh
      ansible_host: ${ANSIBLE_LIVE_HOST}
      ansible_port: ${ANSIBLE_LIVE_PORT}
      ansible_user: ${ANSIBLE_LIVE_USER}
      ansible_python_interpreter: auto_silent
EOF

printf 'Configuring Portage baseline for %s/%s target on %s@%s port %s\n' "$profile" "$stage3_flavor" "$ANSIBLE_LIVE_USER" "$ANSIBLE_LIVE_HOST" "$ANSIBLE_LIVE_PORT"
printf 'Portage Gentoo mirrors: %s\n' "$portage_gentoo_mirrors"
printf '%s\n' 'This target writes conservative Portage configuration, syncs the official Gentoo repo, and selects the matching profile. It does not install packages or run @world.'

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "$inventory_file" \
  --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10" \
  -e "profile=${profile}" \
  -e "filesystem=${filesystem}" \
  -e "stage3_flavor=${stage3_flavor}" \
  -e "portage_gentoo_mirrors=${portage_gentoo_mirrors}" \
  -e "project_root=${project_root}" \
  ansible/playbooks/configure-portage.yml
