## ADDED Requirements

### Requirement: QEMU Manual Install Test Environment
The project SHALL provide a local QEMU test environment for manually rehearsing the Gentoo installation flow from the official Gentoo live ISO without touching host block devices.

#### Scenario: Check QEMU prerequisites
- **WHEN** the operator runs `make qemu-check`
- **THEN** the workflow SHALL verify `qemu-system-x86_64`, `qemu-img`, `make`, and resolve `./gentoo.iso` as either a regular ISO file or a directory containing exactly one `.iso` file
- **AND** the workflow SHALL verify OVMF/UEFI firmware when UEFI boot is requested
- **AND** the workflow SHALL fail with a clear message when a required tool or file is missing
- **AND** the workflow SHALL fail instead of guessing when the ISO directory contains zero or multiple `.iso` files
- **AND** the workflow SHALL be read-only and SHALL NOT create the QEMU artifact directory, disk image, or OVMF vars file

#### Scenario: Create the qcow2 VM disk
- **WHEN** the operator runs `make qemu-disk`
- **THEN** the workflow SHALL create `./var/qemu/` if missing
- **AND** the workflow SHALL create `./var/qemu/gentoo-test.qcow2` if missing
- **AND** the disk image SHALL use qcow2 format by default
- **AND** the disk image SHALL use a default size of 40G
- **AND** an existing disk file SHALL be preserved only when it is a regular qcow2 image
- **AND** an existing non-qcow2 file at the configured disk path SHALL be rejected

#### Scenario: Boot the official live ISO
- **WHEN** the operator runs `make qemu-boot`
- **THEN** the workflow SHALL boot QEMU from the resolved official ISO
- **AND** the workflow SHALL attach `./var/qemu/gentoo-test.qcow2` as the VM disk
- **AND** the VM SHALL default to x86_64, 4096 MB RAM, 2 CPUs, UEFI boot, user-mode NAT networking, and graphical display

#### Scenario: Reject unsupported BIOS boot
- **WHEN** the operator sets `QEMU_BOOT_MODE=bios`
- **THEN** the workflow SHALL fail before launching QEMU
- **AND** the workflow SHALL state that v1 supports UEFI only

#### Scenario: Refuse host block devices
- **WHEN** a QEMU disk path points to a host block device such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, or another `/dev/*` block-device path
- **THEN** the workflow SHALL fail before launching QEMU or modifying files
- **AND** no Makefile target or script SHALL use a real host block device as a VM disk

#### Scenario: Refuse disk paths that escape QEMU directory
- **WHEN** a QEMU disk path contains parent traversal or would not remain under the configured QEMU artifact directory
- **THEN** the workflow SHALL fail before creating or attaching the disk image
- **AND** generated VM disks SHALL remain under the configured QEMU artifact directory

#### Scenario: Refuse project-root QEMU artifact directory
- **WHEN** `QEMU_DIR` is `.`, `./`, `./.`, or another dot-equivalent form of the project root
- **THEN** the workflow SHALL fail before creating, attaching, or cleaning QEMU artifacts
- **AND** generated VM disks SHALL NOT be created in the project root

#### Scenario: Refuse QEMU drive option injection
- **WHEN** a QEMU disk path, artifact directory, or firmware path used in a QEMU `-drive` argument contains a QEMU option separator such as a comma
- **THEN** the workflow SHALL fail before launching QEMU
- **AND** QEMU SHALL NOT receive an operator-provided path that can be parsed as additional drive suboptions

#### Scenario: Refuse cleanup through symlinked path components
- **WHEN** the configured QEMU artifact directory or one of its path components is a symlink
- **THEN** cleanup SHALL fail before listing or deleting generated artifacts
- **AND** cleanup SHALL NOT operate outside the project artifact directory through symlink traversal

#### Scenario: Refuse symlinked writable OVMF vars
- **WHEN** UEFI boot is requested and the generated per-VM OVMF vars path already exists as a symlink or non-regular file
- **THEN** the workflow SHALL fail before launching QEMU
- **AND** QEMU SHALL NOT attach a symlinked path as writable pflash
- **AND** cleanup SHALL reject the symlinked or non-regular OVMF vars path instead of deleting it

#### Scenario: Clean generated QEMU artifacts
- **WHEN** the operator runs `make qemu-clean`
- **THEN** the workflow SHALL show the generated QEMU artifacts that would be removed
- **AND** the workflow SHALL require explicit confirmation before deleting VM disks
- **AND** the workflow SHALL remove only the configured QEMU disk image and generated per-VM OVMF vars file under the configured QEMU artifact directory
- **AND** the workflow SHALL reject the configured QEMU disk path if it exists but is not a qcow2 image
- **AND** the workflow SHALL NOT delete unrelated `.qcow2` or `.fd` files stored in the artifact directory

#### Scenario: Preserve manual installation boundary
- **WHEN** the QEMU VM boots successfully
- **THEN** the workflow SHALL leave Gentoo installation steps manual
- **AND** the workflow SHALL NOT partition, format, install stage3, configure the target, or install a bootloader automatically
