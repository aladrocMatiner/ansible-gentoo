# ansible-stage3-install Specification

## Purpose
TBD - created by archiving change implement-ansible-stage3-install. Update Purpose after archive.
## Requirements
### Requirement: Official Stage3 Install
The project SHALL install an official Gentoo amd64 stage3 matching the selected init system into the verified target root.

#### Scenario: Select init-specific stage3
- **WHEN** `PROFILE=openrc`
- **THEN** the workflow SHALL select an official amd64 OpenRC stage3
- **WHEN** `PROFILE=systemd`
- **THEN** the workflow SHALL select an official amd64 systemd stage3

#### Scenario: Verify before extraction
- **WHEN** a stage3 tarball is selected
- **THEN** checksum verification SHALL pass before extraction
- **AND** signature verification SHALL follow the approved stage3 signature policy
- **AND** verification failure SHALL stop extraction
- **AND** cached artifacts SHALL be reverified before reuse according to the download cache and mirror policy

#### Scenario: Extract to target root
- **WHEN** `/mnt/gentoo` is mounted as the verified target root
- **THEN** the workflow SHALL extract the verified stage3 into `/mnt/gentoo`
- **AND** it SHALL preserve ownership and permissions required by Gentoo

