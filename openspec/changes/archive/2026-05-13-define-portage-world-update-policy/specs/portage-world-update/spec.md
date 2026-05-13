## ADDED Requirements

### Requirement: Portage World Update Policy
The project SHALL define whether and how Portage sync, world update, and config file updates run during v1 installation.

#### Scenario: Repository sync
- **WHEN** Portage baseline runs
- **THEN** official Gentoo repository sync SHALL run through documented logic or fail clearly

#### Scenario: World update default
- **WHEN** v1 package installation runs
- **THEN** broad `@world` update SHALL NOT run by default unless a later approved change enables it

#### Scenario: Config file updates
- **WHEN** package operations leave pending config file updates
- **THEN** the workflow SHALL report them and avoid unsafe unattended overwrites

#### Scenario: Evidence
- **WHEN** Portage operations complete
- **THEN** sync/update/config-update status SHALL be logged for audit and install report output
