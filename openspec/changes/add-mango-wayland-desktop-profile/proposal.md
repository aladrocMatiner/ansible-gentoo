## Summary

Add an optional post-install Ansible desktop profile for Mango/MangoWC on Wayland.

Mango is a newer Wayland compositor option inspired by lightweight tiling workflows. This profile is experimental and must be gated strongly because Gentoo package availability may not be stable.

## Motivation

Mango gives the project a place to evaluate a novel compositor without compromising the conservative installer path. It may be useful for users who want a Wayland tiling desktop with a lighter or different design than Hyprland.

## Problem Statement

The project can support experimental desktop profiles as long as they are clearly separated from the stable base installer and do not introduce unreviewed source builds, overlays, or unsafe package behavior.

Mango needs a proposal that defines:

- package availability checks,
- experimental acknowledgement,
- strict no-implicit-overlay/source-build behavior,
- shared desktop flow reuse,
- clear documentation that the profile may not be installable on every Gentoo tree without later package policy work.

## Scope

In scope:

- Define a Mango Wayland post-install Ansible role.
- Define package availability and experimental gates.
- Define Makefile integration through the shared desktop flow.
- Define validation and documentation.

## Non-Goals

- Do not make Mango a default or recommended stable desktop.
- Do not add Mango to the base installer.
- Do not automatically enable overlays, unstable keywords, or source builds.
- Do not replace Sway or Niri.
- Do not mutate disks, bootloader, EFI entries, stage3, or live ISO install phases.

## Safety Considerations

The Mango profile must fail closed when packages are unavailable. It may install packages and write desktop configuration only after the system is installed and reachable over SSH.

No implementation may run arbitrary build commands, clone upstream repositories, or install untracked binaries without a later explicit OpenSpec change.

## Acceptance Criteria

- An OpenSpec capability defines the Mango post-install desktop profile.
- The design marks Mango as experimental.
- The design defines package availability checks and source/overlay boundaries.
- The profile uses the shared desktop flow.
- Makefile targets are planned and documented.
- No destructive installer behavior is introduced.
- `openspec validate add-mango-wayland-desktop-profile --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected future implementation files:

- `Makefile`
- `ansible/playbooks/post-install-desktop.yml`
- `ansible/playbooks/validate-desktop.yml`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/post_install/desktop_mango_wayland/`
- `ansible/group_vars/desktop_mango_wayland.yml`
- `scripts/ansible-desktop-plan.sh`
- `scripts/ansible-desktop-install.sh`
- `scripts/ansible-desktop-validate.sh`
- `docs/desktop-profiles.md`
- `docs/desktop-mango-wayland.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `openspec/specs/desktop-mango-wayland/spec.md`
