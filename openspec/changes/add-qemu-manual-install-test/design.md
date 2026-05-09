# Design: QEMU Manual Install Test Environment

## Overview
This change defines a Makefile-controlled QEMU environment for testing phase 1 manual Gentoo installation workflows locally. The VM boots the official Gentoo live ISO and attaches a qcow2 disk image that is safe to partition and format inside the VM.

This design intentionally does not automate the Gentoo installation. It provides a safe test harness for the operator to exercise the same manual flow that would later be used on hardware.

## Expected Local Files
- `./gentoo.iso`
- `./var/qemu/gentoo-test.qcow2`

`./gentoo.iso` is operator-provided. It may be either an official Gentoo live ISO file or an ignored artifact directory containing exactly one official `.iso` file. The project must not build a custom ISO in v1.

`./var/qemu/gentoo-test.qcow2` is the default VM disk image. It must be created as qcow2 and must remain under `./var/qemu/`.

## Required Host Tools
- `qemu-system-x86_64`
- `qemu-img`
- `make`
- OVMF/UEFI firmware if UEFI boot is requested

`make qemu-check` should verify these tools before any QEMU run target is used.

## Suggested VM Defaults
- Architecture: x86_64
- RAM: 4096 MB
- CPUs: 2
- Disk size: 40G
- Disk format: qcow2
- Boot mode: UEFI only in v1
- Network: user-mode NAT
- Display: graphical by default

Defaults should be configurable through Makefile variables later, but the disk path safety rules must not be configurable away.

## Required Makefile Targets
- `make qemu-check`
- `make qemu-disk`
- `make qemu-boot`
- `make qemu-clean`

Target expectations:

- `make qemu-check`: resolve `./gentoo.iso`, verify `qemu-system-x86_64`, `qemu-img`, `make`, and UEFI firmware when UEFI boot is requested.
- `make qemu-disk`: create `./var/qemu/gentoo-test.qcow2` if missing.
- `make qemu-boot`: boot the resolved official ISO with the qcow2 disk attached using QEMU.
- `make qemu-clean`: remove generated QEMU artifacts only after explicit confirmation.

## Required Script
- `scripts/qemu-boot-gentoo-iso.sh`

The boot script should be called by `make qemu-boot`, not directly by the operator.

## Optional Script
- `scripts/qemu-create-disk.sh`

The disk creation script may be used by `make qemu-disk` if the Makefile should stay thin.

## Safety Design
The QEMU test environment is safe only if it never passes through host block devices.

Required checks:

- Reject VM disk paths beginning with `/dev/`.
- Reject common host or guest block-device paths such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, and similar.
- Reject wildcard disk paths.
- Reject QEMU `-drive` option separators such as commas in disk, artifact directory, and firmware paths passed to QEMU drive arguments.
- Reject parent traversal in VM disk paths.
- Reject symlinked QEMU artifact directories or symlinked path components.
- Require VM disk paths to be relative to the project or under `./var/qemu/`.
- Create `./var/qemu/` if missing.
- Use qcow2 by default.
- Fail if `./gentoo.iso` does not exist or cannot be resolved to exactly one ISO file.
- Fail if `qemu-system-x86_64` is missing.
- Fail if `qemu-img` is missing.
- Do not run with `sudo` by default.
- Log the ISO path, disk image path, disk format, RAM, CPU count, boot mode, and network mode.

`make qemu-clean` must display the files it will delete and require explicit confirmation before deleting VM disks. Cleanup must be limited to known generated artifacts: the configured `QEMU_DISK` and the generated per-VM OVMF vars file under `QEMU_DIR`. It must not delete unrelated `.qcow2` or `.fd` files stored in the artifact directory.

## UEFI Boot
UEFI is the only supported boot mode in v1. The QEMU boot design must support OVMF firmware and reject BIOS mode so QEMU rehearsals match the installer assumptions. If OVMF firmware cannot be found, `make qemu-check` and `make qemu-boot` must fail with a clear message rather than continuing without UEFI firmware.

## Manual Workflow Boundary
This change provides the VM shell and virtual disk. It does not partition the virtual disk, format filesystems, install stage3, configure Portage, install GRUB, create users, or reboot the installed system automatically.

Inside the VM, the operator may perform manual installation steps against the attached qcow2 disk. Those operations are intentionally isolated from host block devices.

## Future Automation Compatibility
The QEMU workflow should support future phase 2 Ansible testing by keeping paths and settings predictable:

- ISO path: `./gentoo.iso` as a file, or `./gentoo.iso/` containing exactly one `.iso`
- Disk directory: `./var/qemu/`
- Disk image: `./var/qemu/gentoo-test.qcow2`
- Makefile target entry points
- Logs suitable for debugging QEMU launch failures

The implementation must not assume Ansible is present or run Ansible automatically.
