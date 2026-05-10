# Design: Ansible Disk Detection and Install Plan

## Overview
This change adds read-only Ansible planning roles that run against the booted official Gentoo live ISO over SSH.

The design follows the official Gentoo AMD64 Handbook as the baseline sequence for future installation work: prepare environment, inspect disks, plan partitions and filesystems, install stage3, configure the system, install kernel and bootloader, create users, configure networking, and perform final checks. This change implements only the inspection and planning boundary.

## Operator Flow
Expected sequence:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
make install-plan PROFILE=openrc
make install-plan PROFILE=systemd
make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda
make install-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make install-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

`INSTALL_DISK` is optional for read-only planning, but it must never have a default. When omitted, `install-plan` must explicitly say no install disk was selected.

## Makefile Targets
Add:

- `make ansible-check`: verify Ansible commands exist and syntax-check implemented playbooks.
- `make detect-disks`: run read-only disk detection against the live ISO.
- `make install-plan`: run read-only install planning with `PROFILE`, defaulting to `openrc`, and `FILESYSTEM`, defaulting to `ext4`.

Rules:

- Targets must discover the VM IP through `scripts/vm-ssh-target.sh` unless `VM_IP` is provided.
- Targets must not expose raw `ansible-playbook` as the normal operator workflow.
- Targets must not require `I_UNDERSTAND_THIS_WIPES_DISK`.
- Targets must fail clearly for unsupported `PROFILE` values.
- Targets must fail clearly for unsupported `FILESYSTEM` values.

## Ansible Layout
Add shared roles under `roles/common/`:

```text
ansible/
  playbooks/
    detect-disks.yml
    install-plan.yml
  roles/
    common/
      disk_detection/
        tasks/
          main.yml
      install_plan/
        tasks/
          main.yml
```

The roles are shared by OpenRC and systemd flows. Init-specific behavior in this change is limited to profile variables and descriptive plan output.

## Disk Detection
`common/disk_detection` must:

- use read-only commands only,
- gather `lsblk --json` output,
- report disk path, type, size, model, serial, filesystem, mountpoints, and children,
- identify whether `/dev/vda` is present in the VM,
- never select `install_disk`,
- never mutate disk state.

## Install Plan
`common/install_plan` must:

- require `PROFILE`/`profile` to be `openrc` or `systemd`,
- map `PROFILE=openrc` to `init_system=openrc` and `stage3_variant=openrc`,
- map `PROFILE=systemd` to `init_system=systemd` and `stage3_variant=systemd`,
- report the selected filesystem plan: `ext4` or `btrfs`,
- report the v1 assumptions: amd64, UEFI, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS,
- report the expected v1 layout as a plan only: 512 MiB EFI system partition and either ext4 root or Btrfs root using the remaining disk,
- for Btrfs, report planned subvolumes and mount options, including `subvol=@` for the root mount, without creating them,
- report whether `INSTALL_DISK` was explicitly provided,
- when `INSTALL_DISK` is provided, match it against detected block device paths and report its identity,
- fail closed if `INSTALL_DISK` is provided but not visible,
- avoid destructive commands and avoid confirmation variables.

## Variables
Makefile variable mapping:

- `PROFILE` maps to Ansible `profile`.
- `FILESYSTEM` maps to Ansible `filesystem`.
- `INSTALL_DISK`, if set, maps to Ansible `install_disk`.

Defaults:

- `PROFILE ?= openrc` is allowed.
- `FILESYSTEM ?= ext4` is allowed.
- `INSTALL_DISK` must not be assigned a default.

## Safety Rules
- No destructive commands.
- No `install_disk` default.
- No disk mutation.
- No target filesystem mount.
- No stage3 extraction.
- No chroot.
- No bootloader changes.
- No user or password changes.
- No service enablement.

## Documentation
Update:

- `docs/ansible-install-plan.md`.
- `docs/ansible-live-preflight.md`.
- `skills/ansible-gentoo-installer.md`.
- `skills/makefile-control-plane.md`.
- `skills/gentoo-disk-planning.md`.

Documentation must say that the workflow is read-only and that `INSTALL_DISK=/dev/vda` is valid only inside the VM when deliberately provided by the operator.

## Review Checklist
- Are all operator actions exposed through Makefile targets?
- Are disk facts read-only?
- Is `INSTALL_DISK` never defaulted?
- Does an explicit `INSTALL_DISK` only influence read-only matching?
- Are OpenRC and systemd handled by shared roles and variables?
- Does documentation distinguish plan-only behavior from future destructive implementation?
- Does OpenSpec validation pass?
