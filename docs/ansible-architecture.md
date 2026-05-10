# Ansible Architecture

This document defines the planned Ansible architecture for `gentoo-ai-installer`. It is a policy and design document; it does not mean the Ansible roles or playbooks are implemented yet.

## Purpose
The Ansible installer phase should turn validated manual Gentoo installation steps into reproducible local automation from the official Gentoo live ISO.

The architecture must support basic console installs for OpenRC and systemd while reusing as much implementation as possible.

Future installer roles and playbooks must use the official Gentoo AMD64 Handbook as the baseline procedure: <https://wiki.gentoo.org/wiki/Handbook:AMD64>. The project may translate Handbook steps into Ansible tasks, variables, templates, and validations, but deviations must be intentional, documented, and reviewed through OpenSpec.

## Reuse-first Design
Common behavior must be implemented once and reused.

Shared behavior includes:

- preflight checks
- architecture and UEFI detection
- disk discovery and identity reporting
- safety confirmation validation
- partition planning
- mount planning
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
- libvirt VM validation flow

Do not duplicate OpenRC and systemd logic unless the behavior genuinely differs. If duplication is necessary, the implementing OpenSpec change must explain why shared roles, variables, handlers, templates, or includes cannot express the behavior.

Shared roles should correspond to Handbook phases where practical. For example, disk preparation, stage3 installation, chroot preparation, Portage configuration, kernel installation, bootloader setup, networking, users, and final checks should each preserve the Handbook order and safety assumptions unless an approved OpenSpec change explains the deviation.

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
      install_plan/
      partition_plan/
      mount_plan/
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
- `install_plan`: profile-aware read-only plan output.
- `partition_plan`: read-only GPT layout planning.
- `mount_plan`: read-only root, EFI, and Btrfs subvolume mount layout planning.
- `disk_safety`: required variables, confirmations, disk identity, libvirt VM guest mode, and fail-closed behavior.
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

Currently implemented read-only planning roles:

- `common/live_preflight`: validates the live ISO environment over SSH.
- `common/disk_detection`: reports visible block devices without selecting or modifying a disk.
- `common/install_plan`: prints a profile-aware OpenRC or systemd plan without defaulting `install_disk`; it supports `FILESYSTEM=ext4` and `FILESYSTEM=btrfs` as read-only plan variants.
- `common/partition_plan`: requires explicit `INSTALL_DISK` and prints the exact read-only GPT plan for ext4 or Btrfs without writing.
- `common/mount_plan`: requires explicit `INSTALL_DISK`, reuses partition-plan safety checks, and prints the read-only target root, EFI, and Btrfs subvolume mount layout without mounting or creating directories.

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
- `vm_guest_mode`

Rules:

- `install_disk` must not have a default.
- `confirm_wipe_disk` must be explicitly set for destructive disk operations.
- `init_system` must be `openrc` or `systemd`.
- `stage3_variant` must match `init_system`.
- Variant values should live in `group_vars/openrc.yml`, `group_vars/systemd.yml`, or an equivalent documented mechanism.
- VM guest `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the libvirt-managed guest VM.

## Makefile Integration
The Makefile remains the operator-facing control plane.

Planned Ansible targets:

```sh
make ansible-check
make ansible-dry-run PROFILE=openrc
make ansible-dry-run PROFILE=systemd
make install-plan PROFILE=openrc
make install-plan PROFILE=systemd
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
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
- VM guest mode does not disable confirmations or disk identity checks.

## VM Testing Expectations
libvirt/virsh is the first safe test environment for OpenRC and systemd install plans.

- Boot the official Gentoo live ISO from `./gentoo.iso`.
- Use qcow2 disks under `./var/libvirt/`.
- Use the libvirt managed `default` network for IP discovery when validating Ansible connectivity.
- Do not touch host block devices.
- Use `/dev/vda` only inside the guest VM and only when explicitly passed as `install_disk=/dev/vda`.
- Validate OpenRC and systemd install plans in the libvirt-managed VM before real hardware testing.
- Use `make vm-bootstrap-ssh` and `make vm-ansible-ping` only to validate access to the live ISO; installer playbooks remain separate approved work.

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

- Does the role or playbook follow the relevant official Gentoo AMD64 Handbook step unless a reviewed deviation is documented?
- Is common behavior implemented once?
- Are init-specific differences isolated and named clearly?
- Does `install_disk` have no default?
- Are shared safety gates reused by both flows?
- Do OpenRC tasks avoid `systemctl`?
- Do systemd tasks avoid `rc-update` and `rc-service`?
- Do Makefile targets call shared Ansible flows where practical?
- Are handlers, templates, validation tasks, and logs reused?
- Is VM guest `/dev/vda` limited to explicit guest-mode use?
- Does documentation distinguish implemented behavior from planned behavior?
