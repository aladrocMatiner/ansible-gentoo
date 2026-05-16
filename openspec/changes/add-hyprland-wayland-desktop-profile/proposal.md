## Summary

Add an optional post-install Ansible desktop profile for Hyprland on Wayland.

Hyprland is the project's advanced visual Wayland profile. It should be available for operators who want animations, effects, and rich compositor features, but it must remain explicit and experimental until package stability is proven.

## Motivation

Hyprland is popular among tiling Wayland users and provides a modern, highly configurable desktop experience. It is useful to support as an optional profile, especially for users evaluating graphical Gentoo workstations.

Because Hyprland changes quickly and may have overlay/package constraints, the profile needs stronger gating than Sway.

## Problem Statement

The project needs a reproducible Hyprland path without letting fast-moving desktop packages destabilize the core installer.

The role must:

- run only post-install,
- require explicit experimental acknowledgement when needed,
- avoid automatic overlays or source builds,
- reuse common Wayland/desktop setup,
- isolate Hyprland-specific configuration and validation.

## Scope

In scope:

- Define a Hyprland post-install Ansible role.
- Define experimental package policy.
- Define package and helper groups for a minimal Hyprland setup.
- Define Makefile plan/install/validate targets.
- Define validation and documentation.

## Non-Goals

- Do not make Hyprland the default desktop profile.
- Do not add Hyprland to the basic-console installer.
- Do not automatically enable overlays, accept unstable keywords, or build from source.
- Do not configure GPU vendor-specific stacks beyond a documented minimal baseline.
- Do not change disk, bootloader, stage3, or chroot installer behavior.

## Safety Considerations

Hyprland installation must be a persistent but non-destructive post-install operation.

The implementation must:

- require installed-target SSH access,
- fail if connected to the live ISO,
- require explicit `DESKTOP_EXPERIMENTAL_OK=yes` when package policy requires it,
- refuse implicit overlays/source builds,
- keep secrets out of logs,
- avoid all destructive installer commands.

## Acceptance Criteria

- An OpenSpec capability defines the Hyprland post-install profile.
- The design classifies Hyprland as advanced/experimental.
- The design defines explicit package policy and acknowledgement variables.
- The profile uses shared desktop/Wayland tasks where practical.
- Hyprland-specific behavior is isolated.
- Makefile targets are planned and documented.
- The profile does not alter base installation behavior.
- `openspec validate add-hyprland-wayland-desktop-profile --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected future implementation files:

- `Makefile`
- `ansible/playbooks/post-install-desktop.yml`
- `ansible/playbooks/validate-desktop.yml`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/post_install/desktop_hyprland_wayland/`
- `ansible/group_vars/desktop_hyprland_wayland.yml`
- `scripts/ansible-desktop-plan.sh`
- `scripts/ansible-desktop-install.sh`
- `scripts/ansible-desktop-validate.sh`
- `docs/desktop-profiles.md`
- `docs/desktop-hyprland-wayland.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/specs/desktop-hyprland-wayland/spec.md`
