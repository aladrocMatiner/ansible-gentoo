## ADDED Requirements

### Requirement: Libvirt Install Test Matrix
The project SHALL validate supported platform/init/filesystem variants in libvirt before real hardware use.

#### Scenario: Plan matrix
- **WHEN** matrix planning is requested
- **THEN** the workflow SHALL enumerate amd64 OpenRC/ext4, amd64 OpenRC/Btrfs, amd64 systemd/ext4, and amd64 systemd/Btrfs entries
- **AND** it SHALL identify which validation phases are implemented for each entry

#### Scenario: Plan matrix with manual image label
- **WHEN** matrix planning is requested with `VM_TEST_IMAGE_NAME=<image-name>`
- **THEN** planned domain names, qcow2 paths, and matrix evidence SHALL include `<image-name>`
- **AND** the workflow SHALL reject unsafe image labels

#### Scenario: Run matrix safely
- **WHEN** a matrix entry runs a destructive install test
- **THEN** it SHALL use a disposable project-local qcow2 disk
- **AND** it SHALL NOT use host block devices
- **AND** it SHALL require the same destructive confirmations as single-variant installs

#### Scenario: Matrix evidence
- **WHEN** a matrix entry completes
- **THEN** it SHALL write logs and status evidence associated with that platform/profile/filesystem case
