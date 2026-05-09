# Ansible Architecture

This document defines the planned Ansible architecture for `gentoo-ai-installer`. It is a policy and design document; it does not mean the Ansible roles or playbooks are implemented yet.

## Purpose
The Ansible installer phase should turn validated manual Gentoo installation steps into reproducible local automation from the official Gentoo live ISO.

The architecture must support basic console installs for OpenRC and systemd while reusing as much implementation as possible.

## Reuse-first Design
Common behavior must be implemented once and reused.

Shared behavior includes:

- preflight checks
- architecture and UEFI detection
- disk discovery and identity reporting
- safety confirmation validation
- partition planning
- filesystem checks
- mount target preparation
- stage3 download, verification, and extraction framework
- chroot preparation
- Portage baseline configuration
- package installation framework
- fstab generation
- kernel installation
- GRUB installation framework
- user creation framework
- SSH package installation framework
- final validation checks
- logging
- QEMU validation flow

Do not duplicate OpenRC and systemd logic unless the behavior genuinely differs. If duplication is necessary, the implementing OpenSpec change must explain why shared roles, variables, handlers, templates, or includes cannot express the behavior.

## Proposed Directory Layout
Planned layout:

```text
ansible/
  inventory/
    local.yml
  group_vars/
    all.yml
    openrc.yml
    systemd.yml
  playbooks/
    install-openrc.yml
    install-systemd.yml
    install-basic-console.yml
  roles/
    common/
      preflight/
      disk_detection/
      disk_safety/
      partitioning/
      filesystem/
      mount_target/
      stage3/
      chroot/
      portage/
      package_install/
      fstab/
      kernel/
      bootloader/
      users/
      ssh/
      final_checks/
    init/
      openrc/
      systemd/
```

Alternative layouts are allowed only when an approved OpenSpec change shows that common behavior is still implemented once and init-specific behavior remains isolated.

## Shared Roles
Shared roles live under `roles/common/` or an equivalent shared structure.

- `preflight`: live ISO, root privilege, amd64, UEFI, network, time, and tool checks.
- `disk_detection`: read-only disk inventory and identity reporting.
- `disk_safety`: required variables, confirmations, disk identity, QEMU mode, and fail-closed behavior.
- `partitioning`: partition planning and approved execution.
- `filesystem`: filesystem checks and approved formatting.
- `mount_target`: target root and EFI mount preparation.
- `stage3`: stage3 download, checksum, signature, architecture, and variant validation framework.
- `chroot`: pseudo-filesystem, DNS, and chroot readiness.
- `portage`: shared Portage baseline.
- `package_install`: shared package installation framework.
- `fstab`: UUID-based fstab generation.
- `kernel`: `gentoo-kernel-bin` installation.
- `bootloader`: GRUB and EFI framework.
- `users`: user creation framework with secret-safe input.
- `ssh`: SSH package framework and init-specific enablement dispatch.
- `final_checks`: read-only validation before reboot.

## Init-specific Roles
Init-specific roles must be thin and explicit.

OpenRC-specific behavior:

- OpenRC stage3 selection.
- OpenRC profile selection.
- `rc-update` service enablement.
- OpenRC-compatible syslog and cron packages.
- OpenRC-specific validation.

systemd-specific behavior:

- systemd stage3 selection.
- systemd profile selection.
- `systemctl` service enablement.
- systemd-journald assumptions.
- systemd-specific validation.

OpenRC workflows must not call `systemctl`. systemd workflows must not call `rc-update` or `rc-service`.

## Variable Model
Shared variables have one meaning across both flows:

- `install_disk`
- `hostname`
- `admin_user`
- `filesystem`
- `boot_mode`
- `stage3_variant`
- `init_system`
- `enable_ssh`
- `confirm_wipe_disk`
- `target_mount`
- `efi_mount`
- `qemu_mode`

Rules:

- `install_disk` must not have a default.
- `confirm_wipe_disk` must be explicitly set for destructive disk operations.
- `init_system` must be `openrc` or `systemd`.
- `stage3_variant` must match `init_system`.
- Variant values should live in `group_vars/openrc.yml`, `group_vars/systemd.yml`, or an equivalent documented mechanism.
- QEMU `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the guest VM.

## Makefile Integration
The Makefile remains the operator-facing control plane.

Planned Ansible targets:

```sh
make ansible-check
make ansible-dry-run PROFILE=openrc
make ansible-dry-run PROFILE=systemd
make install-plan PROFILE=openrc
make install-plan PROFILE=systemd
make install-openrc
make install-systemd
```

Targets should pass `PROFILE=openrc` or `PROFILE=systemd` into a shared Ansible flow where practical. Avoid duplicated OpenRC and systemd command chains when a shared command can be parameterized safely.

Only targets present in the current `Makefile` should be documented as runnable in user-facing quick-start instructions.

## Safety Gate Reuse
Safety gates must be implemented once and reused by both init flows.

Required shared gates:

- `install_disk` is explicitly provided.
- No default disk exists in inventory, group vars, role defaults, or Makefile variables.
- Disk path, model, serial when available, size, current partition table, current filesystems, and mountpoints are shown before destructive tasks.
- `confirm_wipe_disk=yes` is required before destructive disk operations.
- Destructive tasks fail closed on ambiguity.
- Init-specific roles cannot partition, format, wipe, select disks, or redefine disk safety.
- QEMU mode does not disable confirmations or disk identity checks.

## QEMU Testing Expectations
QEMU is the first safe test environment for OpenRC and systemd install plans.

- Boot the official Gentoo live ISO from `./gentoo.iso`.
- Use qcow2 disks under `./var/qemu/`.
- Do not touch host block devices.
- Use `/dev/vda` only inside the guest VM and only when explicitly passed as `install_disk=/dev/vda`.
- Validate OpenRC and systemd install plans in QEMU before real hardware testing.

## Acceptable Reuse
Acceptable patterns:

- One shared `stage3` role with `stage3_variant` selecting OpenRC or systemd assets.
- One shared `package_install` role using variant package lists.
- One shared `ssh` role dispatching service enablement to init-specific tasks.
- One shared `disk_safety` role used before partitioning, formatting, mounting, and bootloader work.
- Thin `install-openrc.yml` and `install-systemd.yml` playbooks that load variables and call `install-basic-console.yml`.

## Unacceptable Duplication
Unacceptable patterns:

- Separate OpenRC and systemd disk detection roles with the same logic.
- Separate OpenRC and systemd partitioning roles with copied safety assertions.
- Separate full install playbooks that duplicate the same role order.
- OpenRC tasks calling `systemctl`.
- systemd tasks calling `rc-update` or `rc-service`.
- Init-specific roles that choose or mutate disks directly.
- Repeating full shared procedures in both OpenRC and systemd documentation sections.

## Review Checklist
Before approving future Ansible implementation:

- Is common behavior implemented once?
- Are init-specific differences isolated and named clearly?
- Does `install_disk` have no default?
- Are shared safety gates reused by both flows?
- Do OpenRC tasks avoid `systemctl`?
- Do systemd tasks avoid `rc-update` and `rc-service`?
- Do Makefile targets call shared Ansible flows where practical?
- Are handlers, templates, validation tasks, and logs reused?
- Is QEMU `/dev/vda` limited to explicit guest-mode use?
- Does documentation distinguish implemented behavior from planned behavior?
