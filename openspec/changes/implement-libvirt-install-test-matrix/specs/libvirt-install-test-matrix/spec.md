## ADDED Requirements

### Requirement: Libvirt Install Test Matrix
The project SHALL validate supported init/filesystem variants in libvirt before real hardware use.

#### Scenario: Plan matrix
- **WHEN** matrix planning is requested
- **THEN** the workflow SHALL enumerate OpenRC/ext4, OpenRC/Btrfs, systemd/ext4, and systemd/Btrfs entries
- **AND** it SHALL identify which validation phases are implemented for each entry

#### Scenario: Run matrix safely
- **WHEN** a matrix entry runs a destructive install test
- **THEN** it SHALL use a disposable project-local qcow2 disk
- **AND** it SHALL NOT use host block devices
- **AND** it SHALL require the same destructive confirmations as single-variant installs

#### Scenario: Matrix evidence
- **WHEN** a matrix entry completes
- **THEN** it SHALL write logs and status evidence associated with that profile/filesystem pair
