# ansible-system-packages-and-services Specification

## Purpose
TBD - created by archiving change implement-ansible-system-packages-and-services. Update Purpose after archive.
## Requirements
### Requirement: Minimal Console Packages and Services
The project SHALL install and enable the minimal packages and services needed for a bootable console Gentoo system.

#### Scenario: OpenRC services
- **WHEN** `PROFILE=openrc`
- **THEN** service enablement SHALL use OpenRC commands only

#### Scenario: systemd services
- **WHEN** `PROFILE=systemd`
- **THEN** service enablement SHALL use systemd commands only

#### Scenario: Filesystem utilities
- **WHEN** system packages are installed
- **THEN** vfat/FAT32 tooling SHALL be available for the EFI system partition
- **AND** Btrfs tooling SHALL be installed when `FILESYSTEM=btrfs`

#### Scenario: NetworkManager policy
- **WHEN** network services are configured
- **THEN** NetworkManager SHALL be installed and enabled as the v1 network manager
- **AND** the documentation SHALL state that this is a project policy rather than the only Handbook-supported networking option

#### Scenario: Time sync service
- **WHEN** system packages and services are configured
- **THEN** installed target time synchronization SHALL follow the installed time-sync policy

#### Scenario: SSH service
- **WHEN** `ENABLE_SSH=yes`
- **THEN** installed SSH package and service behavior SHALL follow the installed SSH policy

