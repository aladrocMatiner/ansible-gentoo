## ADDED Requirements

### Requirement: i3 X11 Post-Install Desktop Profile
The project SHALL define an optional post-install Ansible profile for installing and validating an i3 X11 desktop on an already stable Gentoo system.

#### Scenario: Require installed target
- **WHEN** the i3 desktop profile runs
- **THEN** it SHALL connect to an installed Gentoo target over SSH
- **AND** it SHALL fail if the target appears to be the official live ISO install environment
- **AND** it SHALL require an explicit desktop user

#### Scenario: Install i3 profile through Makefile
- **WHEN** an operator installs the i3 profile
- **THEN** the workflow SHALL be exposed through Makefile targets
- **AND** it SHALL pass `DESKTOP_PROFILE=i3-x11` into a shared post-install desktop Ansible flow
- **AND** it SHALL NOT require the operator to run undocumented ad-hoc package commands

#### Scenario: Reuse shared desktop architecture
- **WHEN** the i3 role is implemented
- **THEN** common desktop behavior SHALL live in a shared desktop role
- **AND** i3-specific behavior SHALL be isolated in an i3 X11 role
- **AND** OpenRC and systemd differences SHALL be isolated where service/session behavior differs

#### Scenario: Preserve base installer boundary
- **WHEN** the i3 profile runs
- **THEN** it SHALL NOT partition, format, mount target installation paths, extract stage3, run installer chroot phases, install GRUB, modify EFI boot entries, or change bootloader state

#### Scenario: Validate i3 desktop state
- **WHEN** desktop validation runs
- **THEN** it SHALL verify the selected user exists, i3 is installed, X11/startx support is available, session configuration launches i3, and no display manager is enabled unless explicitly requested
