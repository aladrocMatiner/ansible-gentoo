# Ansible Disk Detection and Install Plan

This workflow is the first read-only planning layer for the future Ansible installer. It runs from the operator/controller machine against a booted official Gentoo live ISO target over SSH and follows the official Gentoo AMD64 Handbook as the baseline procedure: <https://wiki.gentoo.org/wiki/Handbook:AMD64>.

The target can be selected explicitly with `ANSIBLE_LIVE_HOST=...`. When that variable is empty, the wrappers may discover the local libvirt VM as the validation target.

It does not install Gentoo. It does not partition, format, mount target filesystems, extract stage3, chroot, install packages, create users, change passwords, enable services, or install bootloaders.

## Required State

For a network target, boot the official Gentoo live ISO, enable SSH, and run the live ISO preflight with the target address:

```sh
make ansible-live-preflight ANSIBLE_LIVE_HOST=192.0.2.10
```

For the local validation VM, boot the VM, bootstrap temporary SSH, and run the live ISO preflight first:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
```

For optional fallback/diagnostics when running from inside the official Gentoo live ISO itself, use the local targets:

```sh
make local-live-preflight
make local-detect-disks
make local-install-plan PROFILE=openrc FILESYSTEM=ext4
make local-partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

Local targets use `ansible/inventory/local.yml` with `ansible_connection=local`. They are read-only at this stage and do not replace the primary SSH/network workflow.

## Check Ansible

Verify Ansible tooling and syntax for implemented playbooks:

```sh
make ansible-check
```

This target validates local Ansible commands and syntax-checks the implemented playbooks. It does not connect to disks or run installer tasks.

When `ansible-lint` is installed, `make ansible-check` also runs the project lint configuration. If `ansible-lint` is missing, the target reports that lint was skipped; syntax checks still run.

## Detect Disks

Run read-only disk detection from inside the live ISO:

```sh
make detect-disks
```

The output reports visible block devices, including path, type, size, model, serial when available, filesystem, mountpoints, UUID, partition type name, and children. In the libvirt VM, `/dev/vda` is the expected virtual disk attached from the project-local qcow2 image; on real network targets, use only the disk path shown by `make detect-disks`.

`make detect-disks` never selects an install disk.

## Generate Install Plans

Generate a read-only OpenRC plan:

```sh
make install-plan PROFILE=openrc
```

Generate a read-only systemd plan:

```sh
make install-plan PROFILE=systemd
```

`PROFILE` defaults to `openrc`. Supported values are `openrc` and `systemd`.

Select the filesystem plan with `FILESYSTEM`. Supported values are `ext4` and `btrfs`; the default is `ext4`:

```sh
make install-plan PROFILE=openrc FILESYSTEM=ext4
make install-plan PROFILE=openrc FILESYSTEM=btrfs
```

`INSTALL_DISK` has no default. If it is omitted, the plan explicitly reports that no install disk was selected:

```sh
make install-plan PROFILE=openrc
```

To plan against the VM disk, pass it deliberately:

```sh
make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda
```

This only matches `/dev/vda` against read-only disk inventory and reports its identity. It does not modify the disk.

For a real network target, replace `/dev/vda` with the explicit disk path reported by `make detect-disks`:

```sh
make install-plan ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=openrc INSTALL_DISK=/dev/<target-disk>
```

## Plan Contents

The plan reports:

- selected profile and init system,
- stage3 variant,
- official Handbook baseline URL,
- v1 assumptions: amd64, UEFI, selected filesystem, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS, no custom ISO,
- whether `INSTALL_DISK` was explicitly provided,
- matched disk identity when `INSTALL_DISK` is visible,
- planned v1 partition layout: 512 MiB EFI system partition and root using the remaining disk,
- for `FILESYSTEM=ext4`, an ext4 root partition mounted at `/mnt/gentoo`,
- for `FILESYSTEM=btrfs`, a Btrfs root partition plus planned subvolumes for `/`, `/home`, `/var`, `/var/log`, `/var/cache`, and `/.snapshots`; the root mount options include `subvol=@`,
- safety boundary confirming no destructive commands ran.

## Safety

Forbidden commands in this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

The workflow does not require `I_UNDERSTAND_THIS_WIPES_DISK` because it is read-only. A later destructive OpenSpec change must introduce explicit confirmation before partitioning or formatting.

When `INSTALL_DISK` is provided, the wrapper accepts only an explicit `/dev/...` path without wildcard, parent-traversal, whitespace, shell metacharacter, or extra-var injection characters. The Ansible role still verifies that the path matches exactly one visible live ISO disk before using it for read-only planning.

## Failure Modes

- `make detect-disks ANSIBLE_LIVE_HOST=...` cannot connect: verify SSH is enabled on the live ISO, the address is reachable, and the port/user are correct.
- Local VM detection cannot connect: run `make vm-ip`, then rerun `make vm-bootstrap-ssh`.
- `make install-plan PROFILE=<value>` fails: use only `PROFILE=openrc` or `PROFILE=systemd`.
- `INSTALL_DISK` is not found: rerun `make detect-disks` and pass one exact visible disk path.
- The plan shows no `INSTALL_DISK`: this is expected when the variable is omitted; no disk was inferred.
- Ansible cannot find roles: run targets from the repository root so `ansible.cfg` is loaded.

## Recovery

Stay on Makefile targets:

```sh
make ansible-check
make detect-disks
make install-plan PROFILE=openrc
make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda
```

Do not run disk commands manually to fix a planning failure. Fix connectivity, profile selection, or explicit disk input first.

After the install plan is correct, continue with the read-only partition plan:

```sh
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Those partition-plan examples are for the local VM harness. For real network targets, include `ANSIBLE_LIVE_HOST=...` and use the explicit disk reported by `make detect-disks`.
