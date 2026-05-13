# ansible-remote-control-plane Specification

## Purpose
TBD - created by archiving change define-remote-network-ansible-control-plane. Update Purpose after archive.
## Requirements
### Requirement: Remote Network Ansible Control Plane
The project SHALL treat reusable Ansible execution against a network-reachable official Gentoo live ISO target as the primary phase-2 installer path.

#### Scenario: Explicit network live ISO target
- **WHEN** the operator provides a live ISO target such as `ANSIBLE_LIVE_HOST=192.0.2.10`
- **THEN** Makefile-mediated Ansible targets SHALL use that target over SSH
- **AND** the workflow SHALL NOT require libvirt VM discovery
- **AND** the workflow SHALL NOT infer an install disk

#### Scenario: Local libvirt harness fallback
- **WHEN** `ANSIBLE_LIVE_HOST` is omitted
- **THEN** wrapper targets MAY discover the configured local libvirt VM for validation
- **AND** the behavior SHALL be documented as a local test harness convenience
- **AND** reusable Ansible roles SHALL NOT depend on libvirt-specific details

#### Scenario: VM-only assumptions stay isolated
- **WHEN** a workflow references libvirt domain names, qcow2 paths, `./var/libvirt/`, VM IP discovery, or `/dev/vda`
- **THEN** that reference SHALL be limited to local harness scripts, VM docs, examples, or validation fixtures
- **AND** reusable Ansible roles SHALL use target facts and explicit operator variables instead

#### Scenario: No default target disk
- **WHEN** a network live ISO target is used
- **THEN** `install_disk` and `INSTALL_DISK` SHALL remain unset until explicitly provided by the operator
- **AND** `/dev/vda` SHALL NOT be treated as a default outside explicit local VM examples

