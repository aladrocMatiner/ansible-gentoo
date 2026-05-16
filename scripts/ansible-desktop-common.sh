#!/usr/bin/env bash

load_desktop_inputs() {
  desktop_profile=${DESKTOP_PROFILE:-i3-x11}
  desktop_target_host=${DESKTOP_TARGET_HOST:-}
  desktop_target_port=${DESKTOP_TARGET_PORT:-22}
  desktop_target_user=${DESKTOP_TARGET_USER:-}
  desktop_user=${DESKTOP_USER:-}
  desktop_install_recommends=${DESKTOP_INSTALL_RECOMMENDS:-yes}
  desktop_display_manager=${DESKTOP_DISPLAY_MANAGER:-none}
  desktop_session_start=${DESKTOP_SESSION_START:-startx}
  desktop_privilege_tool=${DESKTOP_PRIVILEGE_TOOL:-sudo}

  case "$desktop_profile" in
    i3-x11) ;;
    *) die_code CONFIG_INVALID "DESKTOP_PROFILE must be i3-x11 for the current implementation, got: $desktop_profile" ;;
  esac
  [[ -n "$desktop_target_host" ]] || die_code CONFIG_INVALID "DESKTOP_TARGET_HOST is required for post-install desktop targets"
  assert_host "$desktop_target_host"
  assert_port DESKTOP_TARGET_PORT "$desktop_target_port"
  [[ -n "$desktop_target_user" ]] || die_code CONFIG_INVALID "DESKTOP_TARGET_USER is required for post-install desktop targets"
  [[ "$desktop_target_user" =~ ^[A-Za-z0-9_.-]+$ ]] || die_code CONFIG_INVALID "DESKTOP_TARGET_USER must be a conservative SSH user"
  [[ -n "$desktop_user" ]] || die_code CONFIG_INVALID "DESKTOP_USER is required and must already exist on the installed target"
  [[ "$desktop_user" =~ ^[a-z_][a-z0-9_-]{0,31}\$?$ ]] || die_code CONFIG_INVALID "DESKTOP_USER must be a conservative installed-system user"
  case "$desktop_install_recommends" in
    yes|no) ;;
    *) die_code CONFIG_INVALID "DESKTOP_INSTALL_RECOMMENDS must be yes or no" ;;
  esac
  case "$desktop_display_manager" in
    none) ;;
    *) die_code CONFIG_INVALID "DESKTOP_DISPLAY_MANAGER must be none for the current i3 implementation" ;;
  esac
  case "$desktop_session_start" in
    startx) ;;
    *) die_code CONFIG_INVALID "DESKTOP_SESSION_START must be startx for the current i3 implementation" ;;
  esac
  case "$desktop_privilege_tool" in
    sudo) ;;
    *) die_code CONFIG_INVALID "DESKTOP_PRIVILEGE_TOOL must be sudo for the current implementation" ;;
  esac
}

desktop_ssh_common_args() {
  ensure_ansible_ssh_control_dir

  printf '%s' "-o ConnectTimeout=${ANSIBLE_SSH_CONNECT_TIMEOUT}"
  printf ' %s' "-o ServerAliveInterval=${ANSIBLE_SSH_SERVER_ALIVE_INTERVAL}"
  printf ' %s' "-o ServerAliveCountMax=${ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX}"

  if [[ "$ANSIBLE_SSH_CONTROL_MASTER" != no && "$ANSIBLE_SSH_CONTROL_PERSIST" != no ]]; then
    printf ' %s' "-o ControlMaster=${ANSIBLE_SSH_CONTROL_MASTER}"
    printf ' %s' "-o ControlPersist=${ANSIBLE_SSH_CONTROL_PERSIST}"
    printf ' %s' "-o ControlPath=${ANSIBLE_SSH_CONTROL_PATH_DIR}/%C"
  fi
}

write_desktop_inventory() {
  local inventory_file=$1

  cat >"$inventory_file" <<EOF
all:
  hosts:
    gentoo_desktop:
      ansible_connection: ssh
      ansible_host: ${desktop_target_host}
      ansible_port: ${desktop_target_port}
      ansible_user: ${desktop_target_user}
      ansible_python_interpreter: auto_silent
EOF
}

desktop_extra_vars_args() {
  printf '%s\0%s\0' -e "desktop_profile=${desktop_profile}"
  printf '%s\0%s\0' -e "desktop_user=${desktop_user}"
  printf '%s\0%s\0' -e "desktop_install_recommends=${desktop_install_recommends}"
  printf '%s\0%s\0' -e "desktop_display_manager=${desktop_display_manager}"
  printf '%s\0%s\0' -e "desktop_session_start=${desktop_session_start}"
  printf '%s\0%s\0' -e "desktop_privilege_tool=${desktop_privilege_tool}"
  printf '%s\0%s\0' -e "project_root=$(pwd -P)"
}

print_desktop_summary() {
  local action=$1

  printf 'Post-install desktop %s\n' "$action"
  printf 'DESKTOP_PROFILE=%s\n' "$desktop_profile"
  printf 'DESKTOP_TARGET_HOST=%s\n' "$desktop_target_host"
  printf 'DESKTOP_TARGET_PORT=%s\n' "$desktop_target_port"
  printf 'DESKTOP_TARGET_USER=%s\n' "$desktop_target_user"
  printf 'DESKTOP_USER=%s\n' "$desktop_user"
  printf 'DESKTOP_INSTALL_RECOMMENDS=%s\n' "$desktop_install_recommends"
  printf 'DESKTOP_DISPLAY_MANAGER=%s\n' "$desktop_display_manager"
  printf 'DESKTOP_SESSION_START=%s\n' "$desktop_session_start"
  printf '%s\n' 'This workflow targets an already installed Gentoo system over SSH.'
  printf '%s\n' 'It must not run against the official live ISO installer environment.'
}
