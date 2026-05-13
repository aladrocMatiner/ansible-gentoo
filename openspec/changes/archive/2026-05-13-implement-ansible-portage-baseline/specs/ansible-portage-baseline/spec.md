## ADDED Requirements

### Requirement: Portage Baseline
The project SHALL configure a minimal, reliable Portage baseline for the target Gentoo system.

#### Scenario: Select matching profile
- **WHEN** `PROFILE=openrc` or `PROFILE=systemd`
- **THEN** Portage profile selection SHALL match the requested init system
- **AND** profile names SHALL be variant data reused by shared tasks

#### Scenario: Conservative configuration
- **WHEN** `make.conf` is generated
- **THEN** it SHALL avoid aggressive CPU-specific optimization
- **AND** it SHALL avoid broad global USE customization

#### Scenario: Repository policy
- **WHEN** the Portage baseline is configured
- **THEN** the official Gentoo repository SHALL be synced through documented logic
- **AND** GURU SHALL NOT be enabled in the installed system unless a later approved change requires it
- **AND** mirror/cache behavior SHALL follow the approved download cache and mirror policy

#### Scenario: World update policy
- **WHEN** the Portage baseline is configured for v1
- **THEN** broad `@world` update SHALL NOT run by default
- **AND** pending config file updates SHALL be reported without unsafe unattended overwrites
