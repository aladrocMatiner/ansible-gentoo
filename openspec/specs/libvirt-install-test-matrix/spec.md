# libvirt-install-test-matrix Specification

## Purpose
TBD - created by archiving change implement-libvirt-install-test-matrix. Update Purpose after archive.
## Requirements
### Requirement: Libvirt Install Test Matrix
The project SHALL validate supported platform/init/filesystem/stage3-flavor variants in libvirt before real hardware use.

#### Scenario: Plan matrix
- **WHEN** matrix planning is requested
- **THEN** the workflow SHALL enumerate amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavor entries
- **AND** standard entries SHALL preserve the existing case keys without an explicit `standard` suffix
- **AND** hardened and musl entries SHALL include the stage3 flavor in their case keys
- **AND** the workflow SHALL identify which validation phases are implemented for each entry

#### Scenario: Plan matrix with manual image label
- **WHEN** matrix planning is requested with `VM_TEST_IMAGE_NAME=<image-name>`
- **THEN** planned domain names, qcow2 paths, and matrix evidence SHALL include `<image-name>`
- **AND** the workflow SHALL reject unsafe image labels

#### Scenario: Run matrix safely
- **WHEN** a matrix entry runs a destructive install test
- **THEN** it SHALL use a disposable project-local qcow2 disk
- **AND** it SHALL NOT use host block devices
- **AND** it SHALL require the same destructive confirmations as single-variant installs
- **AND** stage3 flavor selection SHALL NOT bypass shared destructive safety gates

#### Scenario: Matrix evidence
- **WHEN** a matrix entry completes
- **THEN** it SHALL write logs and status evidence associated with that platform/profile/filesystem/stage3-flavor case

#### Scenario: Reject shared matrix SSH port override
- **WHEN** matrix listing or full matrix execution is requested with a manual `VM_SSH_HOST_PORT` value other than the default `2222`
- **THEN** the workflow SHALL fail before creating, starting, or reinstalling any VM
- **AND** the error SHALL explain that matrix workflows derive unique per-case SSH host ports

### Requirement: Stage3 Flavor Selector
The project SHALL model Gentoo stage3 flavor separately from init system and filesystem.

#### Scenario: Validate stage3 flavor
- **WHEN** configuration validation runs
- **THEN** `STAGE3_FLAVOR` SHALL be accepted only as `standard`, `hardened`, or `musl`
- **AND** `STAGE3_FLAVOR` SHALL default to `standard`

#### Scenario: Select official stage3
- **WHEN** stage3 installation runs
- **THEN** the selected official Gentoo latest-stage3 index SHALL match both `PROFILE` and `STAGE3_FLAVOR`

#### Scenario: Select matching Portage profile
- **WHEN** Portage configuration runs
- **THEN** the selected Gentoo profile SHALL match both `PROFILE` and `STAGE3_FLAVOR`

