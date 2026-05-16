## ADDED Requirements

### Requirement: Niri Wayland Post-Install Desktop Profile
The project SHALL define an optional post-install Ansible profile for installing and validating Niri as an innovative Wayland desktop option.

#### Scenario: Require installed target
- **WHEN** the Niri profile runs
- **THEN** it SHALL require an installed Gentoo target reachable over SSH
- **AND** it SHALL fail if the target is the live ISO install environment

#### Scenario: Acknowledge experimental package policy
- **WHEN** Niri package availability is not classified as stable by the project policy
- **THEN** installation SHALL require an explicit acknowledgement variable
- **AND** the workflow SHALL NOT add overlays, unmask packages, or build from source by default

#### Scenario: Use shared desktop flow
- **WHEN** Niri is installed
- **THEN** the workflow SHALL use Makefile-mediated desktop targets with `DESKTOP_PROFILE=niri-wayland`
- **AND** common desktop behavior SHALL be reused from shared roles

#### Scenario: Preserve installer boundary
- **WHEN** the Niri profile runs
- **THEN** it SHALL NOT partition, format, modify bootloader state, modify EFI entries, extract stage3, or run live ISO installer phases

#### Scenario: Validate Niri state
- **WHEN** desktop validation runs
- **THEN** it SHALL verify the selected user exists, Niri is installed, session configuration exists, and optional Xwayland compatibility is present when requested
