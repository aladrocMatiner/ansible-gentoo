## Summary

Add an optional post-install Ansible desktop profile for `i3` on X11.

The profile installs and validates a minimal tiling desktop after the base Gentoo system is already installed, booted, reachable over SSH, and validated as stable. It must not change the basic-console installer path or run during disk installation.

## Motivation

`i3` is a stable, lightweight tiling window manager that fits the project's reproducibility goals. It gives operators a practical graphical environment without pulling in a full desktop environment.

Adding it as a post-install role lets the project support a real workstation path while preserving the minimal basic-console baseline.

## Problem Statement

The current installer intentionally stops at a working console system. Operators who want a graphical environment need a documented, reproducible follow-up workflow instead of ad-hoc package commands.

The project needs a first desktop profile that:

- runs only against an installed Gentoo target over SSH,
- is reusable across OpenRC and systemd where practical,
- keeps init-specific service/session behavior isolated,
- avoids destructive disk, filesystem, bootloader, and stage3 operations,
- documents the difference between the base installer and optional post-install desktop customization.

## Scope

In scope:

- Define a post-install Ansible role for an `i3` X11 desktop.
- Define shared desktop profile conventions that later desktop roles can reuse.
- Define Makefile targets for planning, installing, and validating the `i3` profile.
- Define package policy for a minimal X11/i3 session.
- Define user/session expectations for starting i3 through `startx` by default.
- Define validation and documentation requirements.

## Non-Goals

- Do not add i3 to the basic-console installer baseline.
- Do not install a display manager by default.
- Do not configure a full GNOME, KDE, XFCE, or MATE desktop.
- Do not change partitioning, filesystems, bootloader, stage3, kernel, or user creation logic.
- Do not require a custom Gentoo ISO.
- Do not make X11 the default for other desktop profiles.

## Safety Considerations

This change is persistent target mutation, but it is not destructive disk work.

The future implementation must:

- run only after the installed target has passed final or first-boot validation,
- connect to the installed system over SSH, not to the live ISO install target,
- require an explicit installed target host and user,
- use privilege escalation through the configured admin user,
- never run partitioning, formatting, mounting target roots, stage3 extraction, chroot install phases, GRUB, or EFI commands,
- keep secrets out of docs, logs, and variables,
- support `--check`/dry-run behavior where package and file modules allow it,
- report exactly which packages, config files, and services it would change.

## Acceptance Criteria

- An OpenSpec capability defines the i3 post-install desktop profile.
- The design defines the role path, variables, package policy, Makefile targets, validation, and documentation.
- The i3 role is explicitly post-install and does not run against the live ISO install environment.
- The design keeps shared desktop logic reusable for other profiles.
- The design does not add destructive disk, filesystem, bootloader, or stage3 behavior.
- The design defaults to `startx` rather than a display manager.
- Makefile targets are planned for `desktop-plan`, `desktop-install`, `desktop-validate`, and an i3-specific convenience target.
- Documentation tasks cover README, desktop docs, Ansible docs, skills, and AGENTS.md if project-wide behavior changes.
- `openspec validate add-i3-x11-desktop-profile --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files

Expected future implementation files:

- `Makefile`
- `ansible/playbooks/post-install-desktop.yml`
- `ansible/playbooks/validate-desktop.yml`
- `ansible/roles/post_install/desktop_common/`
- `ansible/roles/post_install/desktop_i3_x11/`
- `ansible/group_vars/desktop_i3_x11.yml`
- `scripts/ansible-desktop-plan.sh`
- `scripts/ansible-desktop-install.sh`
- `scripts/ansible-desktop-validate.sh`
- `docs/desktop-profiles.md`
- `docs/desktop-i3-x11.md`
- `docs/ansible-architecture.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `AGENTS.md`
- `openspec/specs/desktop-i3-x11/spec.md`
