#!/usr/bin/env bash

desktop_default_session_start() {
  case "$1" in
    i3-x11) printf '%s\n' startx ;;
    sway-wayland|hyprland-wayland|niri-wayland|mango-wayland) printf '%s\n' manual ;;
    *) die_code CONFIG_INVALID "unsupported DESKTOP_PROFILE: $1" ;;
  esac
}

desktop_profile_is_experimental() {
  case "$1" in
    hyprland-wayland|niri-wayland|mango-wayland) return 0 ;;
    *) return 1 ;;
  esac
}

load_desktop_inputs() {
  desktop_action=${1:-install}
  desktop_profile=${DESKTOP_PROFILE:-i3-x11}
  desktop_target_host=${DESKTOP_TARGET_HOST:-}
  desktop_target_port=${DESKTOP_TARGET_PORT:-22}
  desktop_target_user=${DESKTOP_TARGET_USER:-}
  desktop_user=${DESKTOP_USER:-}
  desktop_install_recommends=${DESKTOP_INSTALL_RECOMMENDS:-yes}
  desktop_enable_portal=${DESKTOP_ENABLE_PORTAL:-yes}
  desktop_enable_xwayland=${DESKTOP_ENABLE_XWAYLAND:-yes}
  desktop_experimental_ok=${DESKTOP_EXPERIMENTAL_OK:-no}
  desktop_package_source=${DESKTOP_PACKAGE_SOURCE:-gentoo}
  desktop_display_manager=${DESKTOP_DISPLAY_MANAGER:-none}
  desktop_session_start=${DESKTOP_SESSION_START:-$(desktop_default_session_start "$desktop_profile")}
  desktop_privilege_tool=${DESKTOP_PRIVILEGE_TOOL:-sudo}

  case "$desktop_profile" in
    i3-x11|sway-wayland|hyprland-wayland|niri-wayland|mango-wayland) ;;
    *) die_code CONFIG_INVALID "DESKTOP_PROFILE must be one of i3-x11, sway-wayland, hyprland-wayland, niri-wayland, or mango-wayland; got: $desktop_profile" ;;
  esac
  case "$desktop_action" in
    plan|install|validate) ;;
    *) die_code CONFIG_INVALID "desktop action must be plan, install, or validate: $desktop_action" ;;
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
  case "$desktop_enable_portal" in
    yes|no) ;;
    *) die_code CONFIG_INVALID "DESKTOP_ENABLE_PORTAL must be yes or no" ;;
  esac
  case "$desktop_enable_xwayland" in
    yes|no) ;;
    *) die_code CONFIG_INVALID "DESKTOP_ENABLE_XWAYLAND must be yes or no" ;;
  esac
  case "$desktop_experimental_ok" in
    yes|no) ;;
    *) die_code CONFIG_INVALID "DESKTOP_EXPERIMENTAL_OK must be yes or no" ;;
  esac
  case "$desktop_package_source" in
    gentoo) ;;
    *) die_code CONFIG_INVALID "DESKTOP_PACKAGE_SOURCE must be gentoo; overlays, source builds, and binary downloads require a later OpenSpec change" ;;
  esac
  case "$desktop_display_manager" in
    none) ;;
    *) die_code CONFIG_INVALID "DESKTOP_DISPLAY_MANAGER must be none for the current desktop implementation" ;;
  esac
  case "$desktop_session_start" in
    startx|manual) ;;
    *) die_code CONFIG_INVALID "DESKTOP_SESSION_START must be startx or manual" ;;
  esac
  if [[ "$desktop_profile" == i3-x11 && "$desktop_session_start" != startx ]]; then
    die_code CONFIG_INVALID "DESKTOP_SESSION_START must be startx for i3-x11"
  fi
  if [[ "$desktop_profile" != i3-x11 && "$desktop_session_start" != manual ]]; then
    die_code CONFIG_INVALID "DESKTOP_SESSION_START must be manual for Wayland desktop profiles"
  fi
  if [[ "$desktop_action" == install ]] && desktop_profile_is_experimental "$desktop_profile" && [[ "$desktop_experimental_ok" != yes ]]; then
    die_code CONFIG_INVALID "DESKTOP_EXPERIMENTAL_OK=yes is required to install experimental profile: $desktop_profile"
  fi
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
  printf '%s\0%s\0' -e "desktop_enable_portal=${desktop_enable_portal}"
  printf '%s\0%s\0' -e "desktop_enable_xwayland=${desktop_enable_xwayland}"
  printf '%s\0%s\0' -e "desktop_experimental_ok=${desktop_experimental_ok}"
  printf '%s\0%s\0' -e "desktop_package_source=${desktop_package_source}"
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
  printf 'DESKTOP_ENABLE_PORTAL=%s\n' "$desktop_enable_portal"
  printf 'DESKTOP_ENABLE_XWAYLAND=%s\n' "$desktop_enable_xwayland"
  printf 'DESKTOP_EXPERIMENTAL_OK=%s\n' "$desktop_experimental_ok"
  printf 'DESKTOP_PACKAGE_SOURCE=%s\n' "$desktop_package_source"
  printf 'DESKTOP_DISPLAY_MANAGER=%s\n' "$desktop_display_manager"
  printf 'DESKTOP_SESSION_START=%s\n' "$desktop_session_start"
  printf '%s\n' 'This workflow targets an already installed Gentoo system over SSH.'
  printf '%s\n' 'It must not run against the official live ISO installer environment.'
}
