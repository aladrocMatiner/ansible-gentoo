## Summary

Add an optional post-install Ansible desktop profile for Niri on Wayland.

Niri is a modern scrollable-tiling Wayland compositor. This profile is intended as the project's innovative Wayland option while keeping the base installer stable and console-first.

## Motivation

Niri offers a different workflow from i3/Sway/Hyprland: windows are arranged in a scrollable column layout instead of shrinking every new window into a dense tile grid. That can be useful on laptops and smaller displays.

Adding Niri as an optional profile gives users a newer desktop path without making it part of the core Gentoo installation.

## Problem Statement

Operators may want to test newer Wayland workflows after the system is installed. The project needs a repeatable Niri role that:

- runs after a stable install,
- uses the shared desktop profile framework,
- validates package availability because Niri packaging may vary by Gentoo tree state,
- does not silently enable overlays or build from source,
- documents its experimental/innovative status clearly.

## Scope

In scope:

- Define a post-install Ansible role for Niri.
- Define package availability checks and optional Xwayland compatibility policy.
- Define user session config and validation.
- Define Makefile targets through the shared desktop profile flow.
- Define docs and failure modes.

## Non-Goals

- Do not make Niri the default desktop.
- Do not install Niri during base installation.
- Do not enable overlays automatically.
- Do not build from source unless a later explicit change adds a source-build policy.
- Do not replace Sway as the conservative Wayland option.
- Do not change destructive installer logic.

## Safety Considerations

The Niri role must be post-install only. It may install packages and write desktop configuration, but must not touch disks, bootloaders, EFI entries, stage3, chroot install phases, or live ISO automation.

If Niri is unavailable in the configured Gentoo repositories, the role must fail with a clear message instead of adding unreviewed overlays or running source builds.

## Acceptance Criteria

- An OpenSpec capability defines the Niri post-install desktop profile.
- The design identifies Niri as an innovative Wayland option.
- The design defines package availability checks and overlay/source-build boundaries.
- The design uses the shared desktop flow and isolates Niri-specific behavior.
- Makefile targets are planned through generic desktop plan/install/validate commands and a Niri convenience target.
- The profile does not alter the base console installer.
- `openspec validate add-niri-wayland-desktop-profile --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected future implementation files:

- `Makefile`
- `ansible/playbooks/post-install-desktop.yml`
- `ansible/playbooks/validate-desktop.yml`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/post_install/desktop_niri_wayland/`
- `ansible/group_vars/desktop_niri_wayland.yml`
- `scripts/ansible-desktop-plan.sh`
- `scripts/ansible-desktop-install.sh`
- `scripts/ansible-desktop-validate.sh`
- `docs/desktop-profiles.md`
- `docs/desktop-niri-wayland.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/specs/desktop-niri-wayland/spec.md`
