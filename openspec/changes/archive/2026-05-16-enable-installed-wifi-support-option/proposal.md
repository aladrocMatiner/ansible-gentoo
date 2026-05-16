## Summary

Add an explicit installed-system WiFi support option controlled by `ENABLE_WIFI=yes`.

When enabled, the installer will include the target packages and Portage USE policy required for NetworkManager-managed WiFi after first boot. The option is intended for laptops and other real hardware that must remain reachable over WiFi after the official live ISO is rebooted into the installed Gentoo system.

## Motivation

Real hardware validation exposed a gap: the base console package policy installs NetworkManager but intentionally disables WiFi support. That is appropriate for many VM and wired targets, but it can leave laptop installs unreachable after first boot when the operator expects to configure or preserve WiFi connectivity on the installed target.

The project needs a documented, Makefile-controlled option for installed WiFi support that does not make WiFi mandatory for every install.

## Problem Statement

The current installed target baseline assumes NetworkManager but does not provide a first-class way to request WiFi capability. Operators can work around this manually by adding firmware, supplicant packages, and USE flags, but that violates the project goal of reproducible Ansible installation through Makefile targets.

The workflow should support:

- `ENABLE_WIFI=no` by default for existing VM/server flows,
- `ENABLE_WIFI=yes` for laptops or WiFi-only targets,
- package and USE policy changes through the existing system package role,
- final checks that verify the WiFi package policy when requested,
- documentation that explains the live ISO WiFi profile still needs to be configured/copied separately when needed.

## Scope

In scope:

- Add `ENABLE_WIFI=yes|no` to the configuration schema and validation output.
- Pass `ENABLE_WIFI` through package installation, final checks, and full install wrappers.
- Add WiFi package groups for `sys-kernel/linux-firmware`, `net-wireless/wpa_supplicant`, and related dependencies selected by Portage.
- Adjust NetworkManager and wpa_supplicant USE policy when `ENABLE_WIFI=yes`.
- Keep WiFi disabled by default when `ENABLE_WIFI=no`.
- Update documentation, skills, and OpenSpec tasks.

## Non-Goals

- Do not configure a real SSID or WiFi password in the repository.
- Do not log or store WiFi secrets.
- Do not guarantee WiFi for every hardware chipset beyond installing the approved firmware/supplicant baseline.
- Do not enable Bluetooth, modem, PPP, desktop, or display-manager stacks.
- Do not change disk, filesystem, stage3, kernel, GRUB, or EFI behavior.
- Do not make WiFi mandatory for libvirt or Proxmox validation.

## Safety Considerations

This change installs packages and writes target Portage package policy. It is persistent target mutation but not destructive disk work.

The implementation must:

- use Makefile targets only for operator-facing actions,
- keep `ENABLE_WIFI` explicit and validated as `yes|no`,
- never store WiFi SSIDs or passwords in docs, logs, state, or audit bundles,
- avoid broad package policy changes unrelated to WiFi,
- preserve `ENABLE_WIFI=no` as the default,
- keep final checks read-only,
- avoid partitioning, formatting, mount-over operations, bootloader installation, or EFI changes.

## Acceptance Criteria

- `ENABLE_WIFI` exists in `config/install-schema.yml` with default `no` and allowed values `yes|no`.
- `scripts/config-check.sh` validates and reports `ENABLE_WIFI`.
- `scripts/ansible-install-system-packages.sh`, `scripts/ansible-final-checks.sh`, and full install wrappers pass `enable_wifi` to Ansible.
- `ansible/roles/common/package_install` includes WiFi packages only when `enable_wifi=yes`.
- NetworkManager is built with WiFi support only when `enable_wifi=yes`.
- wpa_supplicant is built with required D-Bus support when `enable_wifi=yes`.
- `ansible/roles/common/final_checks` validates requested WiFi packages and reports `enable_wifi`.
- Documentation explains how `ENABLE_WIFI=yes` differs from live ISO WiFi bootstrap and does not document secrets.
- `openspec validate enable-installed-wifi-support-option --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected implementation files:

- `Makefile`
- `config/install-schema.yml`
- `scripts/config-check.sh`
- `scripts/ansible-install-system-packages.sh`
- `scripts/ansible-final-checks.sh`
- `scripts/ansible-install-basic-console.sh`
- `ansible/group_vars/all.yml`
- `ansible/roles/common/package_install/tasks/main.yml`
- `ansible/roles/common/final_checks/tasks/main.yml`
- `docs/install-configuration.md`
- `docs/ansible-system-packages-and-services.md`
- `docs/target-system-baseline.md`
- `docs/installed-wifi-policy.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/changes/enable-installed-wifi-support-option/specs/installed-wifi-policy/spec.md`
