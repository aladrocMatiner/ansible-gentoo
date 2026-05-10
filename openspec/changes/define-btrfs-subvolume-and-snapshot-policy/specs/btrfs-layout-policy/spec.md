## ADDED Requirements

### Requirement: Btrfs Layout Policy
The project SHALL define a single Btrfs subvolume and snapshot policy reused by OpenRC and systemd workflows.

#### Scenario: Approved subvolumes
- **WHEN** `FILESYSTEM=btrfs` is selected
- **THEN** the approved layout SHALL include root `@`, home `@home`, var `@var`, var log `@var_log`, var cache `@var_cache`, and snapshots `@snapshots`
- **AND** the workflow SHALL document mountpoint mappings before destructive creation

#### Scenario: Root subvolume
- **WHEN** Btrfs root is mounted
- **THEN** the root mount SHALL use `subvol=@`

#### Scenario: Snapshot tooling
- **WHEN** the v1 Btrfs layout is created
- **THEN** automatic snapshot creation and snapshot management tooling SHALL NOT be enabled unless a later approved change adds it

#### Scenario: Shared implementation
- **WHEN** Btrfs behavior is implemented
- **THEN** OpenRC and systemd flows SHALL reuse the same shared Btrfs variables and tasks
