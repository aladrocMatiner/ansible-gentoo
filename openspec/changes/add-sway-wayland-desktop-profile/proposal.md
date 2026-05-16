## Summary

Add an optional post-install Ansible desktop profile for Sway on Wayland.

Sway is the conservative Wayland option for users who like i3-style tiling but want a modern compositor. The profile must run only after the base system is installed, booted, and reachable over SSH.

## Motivation

Sway provides an i3-compatible workflow on Wayland and is a practical bridge between the project's minimal console baseline and a modern graphical workstation. It is a good default Wayland candidate because it is mature, simple, and easier to automate than more experimental compositors.

## Problem Statement

The project currently has no post-install graphical profile. Operators who want Wayland need a repeatable, documented path that preserves the SSH-driven Ansible architecture.

The Sway profile must share desktop setup with other profiles while isolating Wayland-specific package and session behavior.

## Scope

In scope:

- Define a post-install Ansible role for Sway.
- Reuse the shared desktop profile flow created for optional desktops.
- Define package policy for Sway, terminal, launcher/status bar, portal, and clipboard/screenshot helpers.
- Define user session expectations without making a display manager mandatory.
- Define Makefile targets and validation.

## Non-Goals

- Do not replace the basic-console installer.
- Do not install Sway during disk installation.
- Do not require a display manager.
- Do not install Hyprland, Niri, Mango, GNOME, KDE, or a full desktop environment.
- Do not enable experimental overlays by default.
- Do not change bootloader, partitioning, filesystem, kernel, stage3, or core user setup.

## Safety Considerations

The role mutates only the installed target's packages and user desktop configuration. It must:

- run over SSH against the installed system,
- require explicit target and user variables,
- fail if connected to the live ISO,
- avoid destructive installer commands,
- avoid global host-key changes,
- keep secrets out of logs and docs,
- support dry-run where practical.

## Acceptance Criteria

- An OpenSpec capability defines the Sway post-install desktop profile.
- The design defines role path, package groups, variables, Makefile targets, validation, and documentation.
- The Sway profile runs only after the installed target is stable.
- Shared desktop behavior is reused rather than duplicated.
- Wayland-specific logic is isolated in a Sway role.
- The profile is documented as the conservative Wayland option.
- The profile does not run destructive disk or bootloader operations.
- `openspec validate add-sway-wayland-desktop-profile --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected future implementation files:

- `Makefile`
- `ansible/playbooks/post-install-desktop.yml`
- `ansible/playbooks/validate-desktop.yml`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/post_install/desktop_sway_wayland/`
- `ansible/group_vars/desktop_sway_wayland.yml`
- `scripts/ansible-desktop-plan.sh`
- `scripts/ansible-desktop-install.sh`
- `scripts/ansible-desktop-validate.sh`
- `docs/desktop-profiles.md`
- `docs/desktop-sway-wayland.md`
- `docs/ansible-architecture.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/specs/desktop-sway-wayland/spec.md`
