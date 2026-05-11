# Design: QEMU Manual Install Test Environment

## Overview
This change defines a Makefile-controlled QEMU environment for testing phase 1 manual Gentoo installation workflows locally. The VM boots the official Gentoo live ISO and attaches a qcow2 disk image that is safe to partition and format inside the VM.

This design intentionally does not automate the Gentoo installation. It provides a safe test harness for the operator to exercise the same manual flow that would later be used on hardware.

Status: the direct QEMU implementation described here has been superseded by `migrate-qemu-workflow-to-libvirt-virsh`. The active operator-facing VM workflow is libvirt/virsh through `vm-*` targets. The `qemu-*` targets from this change are retained only as compatibility aliases to `vm-*` targets.

## Expected Local Files
- `./gentoo.iso`
- `./var/libvirt/gentoo-test.qcow2` for the active libvirt workflow

`./gentoo.iso` is operator-provided. It may be either an official Gentoo live ISO file or an ignored artifact directory containing exactly one official `.iso` file. The project must not build a custom ISO in v1.

The active VM disk image must be created as qcow2 and must remain under the configured project-local VM artifact directory. The active default is `./var/libvirt/gentoo-test.qcow2`.

## Required Host Tools
- `qemu-system-x86_64`
- `qemu-img`
- `make`
- OVMF/UEFI firmware if UEFI boot is requested

`make qemu-check` should verify these tools before any QEMU run target is used.

## Active VM Defaults
- Architecture: x86_64
- RAM: 4096 MB
- CPUs: 2
- Disk size: 40G
- Disk format: qcow2
- Boot mode: UEFI only in v1
- Network: libvirt managed `default` network by default
- Display: serial console plus graphical viewer target

Defaults should be configurable through Makefile variables later, but the disk path safety rules must not be configurable away.

## Required Makefile Targets
- `make qemu-check`
- `make qemu-disk`
- `make qemu-boot`
- `make qemu-clean`

Target expectations:

- `make qemu-check`: compatibility alias for `make vm-check`.
- `make qemu-disk`: compatibility alias for `make vm-disk`.
- `make qemu-boot`: compatibility alias for `make vm-start`.
- `make qemu-clean`: compatibility alias for `make vm-clean`.

## Required Script Status
The original direct-QEMU scripts are no longer the active workflow. Active VM scripts are the libvirt `scripts/vm-*.sh` wrappers.

Operators should call Makefile targets only; they should not run direct QEMU or libvirt implementation scripts unless troubleshooting with project documentation.

## Safety Design
The VM test environment is safe only if it never passes through host block devices.

Required checks:

- Reject VM disk paths beginning with `/dev/`.
- Reject common host or guest block-device paths such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, and similar.
- Reject wildcard disk paths.
- Reject QEMU `-drive` option separators such as commas in disk, artifact directory, and firmware paths passed to QEMU drive arguments.
- Reject parent traversal in VM disk paths.
- Reject symlinked QEMU artifact directories or symlinked path components.
- Require VM disk paths to be relative to the project and under the configured VM artifact directory.
- Create the active VM artifact directory only from non-read-only targets.
- Use qcow2 by default.
- Fail if `./gentoo.iso` does not exist or cannot be resolved to exactly one ISO file.
- Fail if `qemu-system-x86_64` is missing.
- Fail if `qemu-img` is missing.
- Do not run with `sudo` by default.
- Log the ISO path, disk image path, disk format, RAM, CPU count, boot mode, libvirt URI, and network mode.

`make qemu-clean`, through `make vm-clean`, must display the files it will delete and require explicit confirmation before deleting VM disks. Cleanup must be limited to known generated artifacts for the configured project-owned domain. It must not delete unrelated `.qcow2`, `.fd`, ISO, secret, libvirt network, pool, volume, or unrelated domain artifacts.

## UEFI Boot
UEFI is the only supported boot mode in v1. The QEMU boot design must support OVMF firmware and reject BIOS mode so QEMU rehearsals match the installer assumptions. If OVMF firmware cannot be found, `make qemu-check` and `make qemu-boot` must fail with a clear message rather than continuing without UEFI firmware.

## Manual Workflow Boundary
This change provides the VM shell and virtual disk. It does not partition the virtual disk, format filesystems, install stage3, configure Portage, install GRUB, create users, or reboot the installed system automatically.

Inside the VM, the operator may perform manual installation steps against the attached qcow2 disk. Those operations are intentionally isolated from host block devices.

## Future Automation Compatibility
The active libvirt workflow supports future phase 2 Ansible testing by keeping paths and settings predictable:

- ISO path: `./gentoo.iso` as a file, or `./gentoo.iso/` containing exactly one `.iso`
- Disk directory: `./var/libvirt/` by default
- Disk image: `./var/libvirt/gentoo-test.qcow2` by default
- Makefile target entry points
- Logs suitable for debugging libvirt launch failures

The implementation must not assume Ansible is present or run Ansible automatically.
