## ADDED Requirements

### Requirement: Mango Wayland Post-Install Desktop Profile
The project SHALL define an optional post-install Ansible profile for installing and validating Mango/MangoWC as an experimental Wayland desktop option.

#### Scenario: Require installed target
- **WHEN** the Mango profile runs
- **THEN** it SHALL require an installed Gentoo target reachable over SSH
- **AND** it SHALL fail if the target is the live ISO install environment

#### Scenario: Fail closed on package availability
- **WHEN** the Mango compositor package is unavailable in the configured Gentoo package source
- **THEN** the workflow SHALL fail with an actionable package-availability message
- **AND** it SHALL NOT add overlays, clone upstream repositories, install prebuilt binaries, or build from source by default

#### Scenario: Require experimental acknowledgement
- **WHEN** Mango installation is requested
- **THEN** the workflow SHALL require `DESKTOP_EXPERIMENTAL_OK=yes`

#### Scenario: Use shared desktop flow
- **WHEN** Mango is installed
- **THEN** the workflow SHALL use Makefile-mediated desktop targets with `DESKTOP_PROFILE=mango-wayland`
- **AND** common desktop behavior SHALL be reused from shared roles

#### Scenario: Preserve installer boundary
- **WHEN** the Mango profile runs
- **THEN** it SHALL NOT partition, format, modify bootloader state, modify EFI entries, extract stage3, or run live ISO installer phases
