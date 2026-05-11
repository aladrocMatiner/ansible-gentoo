#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=ansible-local-live-preflight
source "$(dirname "$0")/vm-libvirt-common.sh"

require_command ansible-playbook

printf '%s\n' 'Running read-only local live ISO preflight with ansible_connection=local'
ansible-playbook \
  -i ansible/inventory/local.yml \
  ansible/playbooks/live-preflight.yml
