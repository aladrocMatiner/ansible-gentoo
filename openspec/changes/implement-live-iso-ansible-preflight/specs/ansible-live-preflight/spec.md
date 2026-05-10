## ADDED Requirements

### Requirement: Read-only Live ISO Ansible Preflight
The project SHALL provide a Makefile-mediated Ansible preflight workflow that validates the booted official Gentoo live ISO over SSH without modifying installation state.

#### Scenario: Validate Ansible connectivity
- **WHEN** the operator runs `make ansible-live-ping`
- **THEN** the workflow SHALL run an Ansible ping against the live ISO
- **AND** the workflow SHALL use `ANSIBLE_LIVE_HOST` when explicitly provided
- **AND** the workflow MAY use the VM IP discovered from libvirt when `ANSIBLE_LIVE_HOST` is omitted for local validation
- **AND** the workflow SHALL fail clearly when SSH is unavailable

#### Scenario: Run live preflight
- **WHEN** the operator runs `make ansible-live-preflight`
- **THEN** the workflow SHALL run a read-only Ansible playbook against the live ISO
- **AND** the workflow SHALL report architecture, kernel, Gentoo release information, UEFI availability, network addresses, DNS configuration, default route, and visible block devices
- **AND** the workflow SHALL fail when `/sys/firmware/efi` is missing
- **AND** the workflow SHALL NOT partition, format, mount target filesystems, chroot, extract stage3, install packages, create users, change passwords, install bootloaders, or run installer playbooks

#### Scenario: Keep VM assumptions out of reusable preflight
- **WHEN** the live ISO target is selected through `ANSIBLE_LIVE_HOST`
- **THEN** the workflow SHALL NOT require libvirt, VM IP discovery, qcow2 paths, or `/dev/vda`
- **AND** `/dev/vda` SHALL remain a local VM example only

#### Scenario: Preserve disk safety
- **WHEN** the preflight reports block devices
- **THEN** it SHALL treat disk information as read-only evidence
- **AND** it SHALL NOT select or default `install_disk`
- **AND** it SHALL NOT require destructive confirmation variables
