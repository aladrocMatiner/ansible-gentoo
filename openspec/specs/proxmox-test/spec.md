# proxmox-test Specification

## Purpose
TBD - created by archiving change add-proxmox-install-test-matrix. Update Purpose after archive.
## Requirements
### Requirement: Proxmox Install Test Matrix
The project SHALL define a Proxmox VE validation harness for running the same supported Gentoo installer matrix as the local libvirt harness.

#### Scenario: Plan Proxmox matrix cases
- **WHEN** Proxmox matrix planning is requested
- **THEN** the workflow SHALL enumerate the amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavor cases
- **AND** it SHALL produce VM names using the `gentoo-test-amd64-<profile>-<filesystem>[-<stage3-flavor>]` convention
- **AND** it SHALL produce a VMID-to-case mapping from an explicit operator-provided VMID or VMID base
- **AND** it SHALL NOT create, start, stop, delete, or mutate Proxmox VMs during planning

#### Scenario: Require explicit Proxmox context
- **WHEN** a Proxmox VM lifecycle target is requested
- **THEN** the workflow SHALL require explicit Proxmox storage, bridge, ISO, VMID, and node context as applicable
- **AND** it SHALL fail before mutation if any required Proxmox value is missing, malformed, or ambiguous

#### Scenario: Use official Gentoo live ISO
- **WHEN** a Proxmox validation VM is created
- **THEN** the VM SHALL boot the official Gentoo live ISO referenced by a Proxmox ISO volume
- **AND** the workflow SHALL NOT build, modify, or require a custom ISO

#### Scenario: Preserve reusable Ansible architecture
- **WHEN** the Proxmox VM is reachable over SSH
- **THEN** installer execution SHALL use the same Makefile-mediated SSH-driven Ansible installer used for network targets
- **AND** reusable Ansible roles SHALL NOT depend on Proxmox VMIDs, storage IDs, bridge names, or Proxmox-only discovery

#### Scenario: Provide installed SSH access
- **WHEN** a Proxmox E2E install is requested
- **THEN** the workflow SHALL require an explicit installed admin user
- **AND** it SHALL enable installed SSH when `ENABLE_SSH=yes`
- **AND** it SHALL install a controller-provided public SSH key into the admin user's `authorized_keys`
- **AND** it SHALL reject private key material and other secret-bearing key inputs
- **AND** it SHALL generate missing installed SSH host keys before first boot validation
- **AND** the installed `sshd` service SHALL be enabled for the selected init system by default

#### Scenario: Enable Proxmox guest integration
- **WHEN** a Proxmox E2E install is requested with `ENABLE_QEMU_GUEST_AGENT=yes`
- **THEN** the workflow SHALL enable the Proxmox guest-agent channel on the project-owned VM
- **AND** it SHALL install `app-emulation/qemu-guest-agent` in the target Gentoo system
- **AND** it SHALL enable the matching OpenRC or systemd guest-agent service
- **AND** reusable Ansible roles SHALL keep guest-agent behavior controlled by variables instead of Proxmox VMID, storage, or node assumptions

#### Scenario: Protect unrelated Proxmox resources
- **WHEN** a Proxmox workflow would stop, reset, destroy, or clean a VM
- **THEN** it SHALL verify the selected VMID, VM name, and project ownership marker before mutation
- **AND** it SHALL refuse unrelated VMs, templates, volumes, ISOs, and storage resources
- **AND** cleanup SHALL require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`

#### Scenario: Keep destructive install gates
- **WHEN** a Proxmox E2E install is requested
- **THEN** it SHALL require an explicit guest `INSTALL_DISK`
- **AND** it SHALL require `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- **AND** it SHALL require `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`
- **AND** the selected install disk SHALL be verified inside the live ISO before partitioning

#### Scenario: Report Proxmox evidence
- **WHEN** a Proxmox single-case or matrix validation completes
- **THEN** the workflow SHALL write logs and evidence containing the case, VMID, VM name, node, storage, ISO, bridge, guest disk, SSH endpoint, install run ID, and final status

