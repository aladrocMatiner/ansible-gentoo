## ADDED Requirements

### Requirement: Installed Time Sync Policy
The project SHALL define time synchronization expectations for the installed Gentoo target.

#### Scenario: OpenRC time sync
- **WHEN** `PROFILE=openrc`
- **THEN** the target baseline SHALL include an OpenRC-compatible time synchronization service
- **AND** service enablement SHALL use OpenRC-specific logic

#### Scenario: systemd time sync
- **WHEN** `PROFILE=systemd`
- **THEN** the target baseline SHALL include a systemd-compatible time synchronization service or documented built-in systemd time sync behavior
- **AND** service enablement SHALL use systemd-specific logic

#### Scenario: Final checks
- **WHEN** final checks run
- **THEN** they SHALL report installed target time-sync package/service status
