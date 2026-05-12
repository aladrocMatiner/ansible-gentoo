## ADDED Requirements

### Requirement: Case-Specific Libvirt VM Identity
The local libvirt validation harness SHALL provide deterministic VM identities for each supported platform/profile/filesystem/stage3 flavor case.

#### Scenario: Derive OpenRC ext4 VM identity
- **WHEN** the operator selects `PROFILE=openrc` and `FILESYSTEM=ext4`
- **THEN** the VM domain name SHALL include `amd64-openrc-ext4`
- **AND** generated libvirt artifacts SHALL use the same case identity

#### Scenario: Derive OpenRC Btrfs VM identity
- **WHEN** the operator selects `PROFILE=openrc` and `FILESYSTEM=btrfs`
- **THEN** the VM domain name SHALL include `amd64-openrc-btrfs`
- **AND** generated libvirt artifacts SHALL use the same case identity

#### Scenario: Derive systemd ext4 VM identity
- **WHEN** the operator selects `PROFILE=systemd` and `FILESYSTEM=ext4`
- **THEN** the VM domain name SHALL include `amd64-systemd-ext4`
- **AND** generated libvirt artifacts SHALL use the same case identity

#### Scenario: Derive systemd Btrfs VM identity
- **WHEN** the operator selects `PROFILE=systemd` and `FILESYSTEM=btrfs`
- **THEN** the VM domain name SHALL include `amd64-systemd-btrfs`
- **AND** generated libvirt artifacts SHALL use the same case identity

#### Scenario: Include manual test image label
- **WHEN** the operator provides `VM_TEST_IMAGE_NAME=<image-name>`
- **THEN** the VM domain name and generated artifacts SHALL include `<image-name>` before the `amd64` platform segment
- **AND** the workflow SHALL reject image names that are empty after trimming, path-like, secret-like, or contain unsafe characters
- **AND** `VM_TEST_IMAGE_NAME` SHALL NOT replace `VM_ISO` as the official Gentoo live ISO path selector

### Requirement: Case-Specific Makefile Control Plane
Operator-facing libvirt VM actions SHALL be exposed through Makefile targets that accept the selected profile and filesystem.

#### Scenario: List supported cases
- **WHEN** the operator runs the safe case listing target
- **THEN** the workflow SHALL list amd64 OpenRC/systemd, ext4/Btrfs, and supported stage3 flavor cases
- **AND** it SHALL print the derived VM domain name, qcow2 path, and state path for each case without creating, starting, stopping, or deleting any VM artifact
- **AND** it SHALL include the selected manual test image label in derived names when `VM_TEST_IMAGE_NAME` is set

#### Scenario: Start selected case VM
- **WHEN** the operator runs a VM start target with a supported `PROFILE` and `FILESYSTEM`
- **THEN** the Makefile workflow SHALL start the libvirt VM for that exact case
- **AND** it SHALL NOT require the operator to manually construct domain names or disk paths
- **AND** it SHALL print the selected case, domain name, disk path, network mode, and libvirt URI before starting the VM

#### Scenario: Plan matrix with executable names
- **WHEN** the operator runs `make vm-test-matrix-plan`
- **THEN** the report SHALL list the case-specific VM name and qcow2 disk path for every supported case
- **AND** those names SHALL match the executable VM target naming rules
- **AND** the report SHALL record `VM_TEST_IMAGE_NAME` when it is set

### Requirement: Case-Specific Artifact Safety
Case-specific libvirt VM workflows SHALL keep generated artifacts within approved project-local directories and SHALL not touch host block devices.

#### Scenario: Reject unsafe VM disk path
- **WHEN** a selected case computes or receives a VM disk path
- **THEN** the workflow SHALL reject `/dev/*`, parent traversal, symlink escapes, unsafe option separators, and paths outside the approved `VM_DIR`

#### Scenario: Clean selected case only
- **WHEN** the operator runs cleanup for a selected case
- **THEN** the workflow SHALL require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`
- **AND** it SHALL delete only validated artifacts for that selected case
- **AND** it SHALL NOT delete artifacts for other cases unless a separate matrix cleanup workflow explicitly lists and confirms those cases

#### Scenario: Verify domain ownership and case metadata
- **WHEN** a libvirt domain already exists for a generated case name
- **THEN** normal VM workflows SHALL verify project ownership metadata and matching image-name/platform/profile/filesystem/stage3 flavor metadata before operating on it
- **AND** they SHALL refuse unrelated or conflicting domains with a clear recovery message

#### Scenario: Avoid shared case state
- **WHEN** a local VM validation workflow records install state or connection evidence
- **THEN** the default generated paths SHALL be specific to the selected case
- **AND** a validation run for one case SHALL NOT overwrite another case's default state pointer

#### Scenario: Avoid simultaneous VM network collisions
- **WHEN** multiple case VMs are used on the same host
- **THEN** the workflow SHALL avoid duplicate generated domain identities
- **AND** it SHALL avoid duplicate generated MAC addresses or user-mode SSH host ports for simultaneously runnable VMs

### Requirement: Remote Ansible Independence
Case-specific libvirt VM naming SHALL remain local validation harness behavior and SHALL NOT become a reusable Ansible role dependency.

#### Scenario: Remote network target
- **WHEN** the operator provides `ANSIBLE_LIVE_HOST` for a remote or physical live ISO target
- **THEN** reusable Ansible roles SHALL use explicit inventory and variables
- **AND** they SHALL NOT require libvirt domain names, qcow2 paths, or local VM discovery

#### Scenario: Local VM target fallback
- **WHEN** `ANSIBLE_LIVE_HOST` is omitted for a local validation workflow
- **THEN** wrapper scripts MAY discover the selected case VM through libvirt
- **AND** the behavior SHALL be documented as local test harness behavior only

#### Scenario: Explicit network target remains primary
- **WHEN** `ANSIBLE_LIVE_HOST` is set
- **THEN** the workflow SHALL use that network target over SSH instead of case VM discovery
- **AND** it SHALL NOT derive the target host from the selected libvirt case

### Requirement: Per-Case Quickstart Documentation
The project SHALL document a separate Makefile-driven quickstart for each supported local libvirt validation case.

#### Scenario: Quickstart exists for every case
- **WHEN** an operator wants to validate one supported case at a time
- **THEN** documentation SHALL provide one quickstart for every supported case
- **AND** each quickstart SHALL include the platform, optional manual test image label, selected profile, filesystem, stage3 flavor, VM name, qcow2 path, install-state path, `/dev/vda` VM-only warning, read-only plans, disposable install command, validation command, cleanup command, and failure modes

#### Scenario: Quickstarts use generated case artifacts
- **WHEN** quickstart documentation references local libvirt VM artifacts
- **THEN** the documentation SHALL use `PROFILE` and `FILESYSTEM` as the normal case selectors
- **AND** it SHALL show the derived case domain, qcow2 disk path, and install-state path as expected output
- **AND** it SHALL NOT require operators to hand-build full `VM_NAME`, `VM_DISK`, or `INSTALL_STATE_FILE` values for normal VM workflows
