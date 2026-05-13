## ADDED Requirements

### Requirement: Legacy QEMU Target Compatibility
The project SHALL retain legacy `qemu-*` Makefile targets only as compatibility aliases for the active libvirt/virsh VM workflow after `migrate-qemu-workflow-to-libvirt-virsh` supersedes direct `qemu-system-x86_64` operation.

#### Scenario: Check VM prerequisites through compatibility alias
- **WHEN** the operator runs `make qemu-check`
- **THEN** the workflow SHALL route to the active `vm-check` behavior
- **AND** the workflow SHALL verify libvirt tools, `qemu-img`, `qemu-system-x86_64`, `make`, official ISO resolution, OVMF/UEFI firmware, libvirt connectivity, network mode configuration, and safe project-local paths
- **AND** the workflow SHALL fail with a clear message when a required tool, file, firmware path, network, or libvirt connection is missing
- **AND** the workflow SHALL fail instead of guessing when the ISO directory contains zero or multiple `.iso` files
- **AND** the workflow SHALL be read-only and SHALL NOT create VM artifact directories, disk images, domains, kernels, initrds, or OVMF vars files

#### Scenario: Create the VM disk through compatibility alias
- **WHEN** the operator runs `make qemu-disk`
- **THEN** the workflow SHALL route to the active `vm-disk` behavior
- **AND** the workflow SHALL create only the configured project-local VM artifact directory if missing
- **AND** the workflow SHALL create the configured project-local qcow2 disk if missing
- **AND** the disk image SHALL use qcow2 format by default
- **AND** the disk image SHALL use a default size of 40G
- **AND** an existing disk file SHALL be preserved only when it is a regular qcow2 image
- **AND** an existing non-qcow2 file at the configured disk path SHALL be rejected

#### Scenario: Start the official live ISO through compatibility alias
- **WHEN** the operator runs `make qemu-boot`
- **THEN** the workflow SHALL route to the active `vm-start` behavior
- **AND** the workflow SHALL start a project-owned libvirt domain from the resolved official ISO
- **AND** the workflow SHALL attach the configured project-local qcow2 disk as the VM disk
- **AND** the VM SHALL default to x86_64, 4096 MB RAM, 2 CPUs, UEFI boot, managed libvirt networking, and graphical access through `make vm-viewer`

#### Scenario: Reject unsupported BIOS boot
- **WHEN** the operator sets `VM_BOOT_MODE=bios`
- **THEN** the workflow SHALL fail before defining or starting the VM
- **AND** the workflow SHALL state that v1 supports UEFI only

#### Scenario: Refuse host block devices
- **WHEN** a VM disk path points to a host block device such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, `/dev/xvda`, or another `/dev/*` block-device path
- **THEN** the workflow SHALL fail before starting libvirt or modifying files
- **AND** no Makefile target or script SHALL use a real host block device as a VM disk

#### Scenario: Refuse disk paths that escape the VM artifact directory
- **WHEN** a VM disk path contains parent traversal or would not remain under the configured VM artifact directory
- **THEN** the workflow SHALL fail before creating or attaching the disk image
- **AND** generated VM disks SHALL remain under the configured project-local artifact directory

#### Scenario: Refuse project-root VM artifact directory
- **WHEN** the configured VM artifact directory is `.`, `./`, `./.`, or another dot-equivalent form of the project root
- **THEN** the workflow SHALL fail before creating, attaching, or cleaning VM artifacts
- **AND** generated VM disks SHALL NOT be created in the project root

#### Scenario: Refuse option injection in VM paths
- **WHEN** a VM disk path, artifact directory, or firmware path contains an option separator or shell metacharacter that could alter QEMU/libvirt arguments
- **THEN** the workflow SHALL fail before defining or starting the VM
- **AND** libvirt/QEMU SHALL NOT receive an operator-provided path that can be parsed as additional drive or command suboptions

#### Scenario: Refuse cleanup through symlinked path components
- **WHEN** the configured VM artifact directory or one of its path components is a symlink
- **THEN** cleanup SHALL fail before listing or deleting generated artifacts
- **AND** cleanup SHALL NOT operate outside the project artifact directory through symlink traversal

#### Scenario: Refuse symlinked writable OVMF vars
- **WHEN** UEFI boot is requested and the generated per-VM OVMF vars path already exists as a symlink or non-regular file
- **THEN** the workflow SHALL fail before defining or starting the VM
- **AND** libvirt SHALL NOT attach a symlinked path as writable pflash
- **AND** cleanup SHALL reject the symlinked or non-regular OVMF vars path instead of deleting it

#### Scenario: Clean generated VM artifacts through compatibility alias
- **WHEN** the operator runs `make qemu-clean`
- **THEN** the workflow SHALL route to the active `vm-clean` behavior
- **AND** the workflow SHALL show the generated VM artifacts that would be removed
- **AND** the workflow SHALL require explicit confirmation before deleting VM disks
- **AND** the workflow SHALL remove only generated artifacts for the configured project-owned domain
- **AND** the workflow SHALL reject the configured VM disk path if it exists but is not a qcow2 image
- **AND** the workflow SHALL NOT delete unrelated `.qcow2`, `.fd`, ISO, secret, libvirt network, pool, volume, or unrelated domain artifacts

#### Scenario: Preserve manual installation boundary
- **WHEN** the VM boots successfully
- **THEN** the workflow SHALL leave Gentoo installation steps manual unless a separate approved Ansible installer change is running
- **AND** the VM boot workflow SHALL NOT partition, format, install stage3, configure the target, or install a bootloader automatically
