# target-system-baseline Specification

## Purpose
TBD - created by archiving change define-target-system-baseline. Update Purpose after archive.
## Requirements
### Requirement: Target System Baseline
The project SHALL define the final state expected from a v1 basic console Gentoo installation.

#### Scenario: Shared baseline
- **WHEN** final checks evaluate the installed target
- **THEN** they SHALL verify the shared baseline for architecture, UEFI boot, kernel, bootloader, filesystem, networking, hostname, locale/timezone, time sync, access, logs, and package policy

#### Scenario: Init-specific baseline
- **WHEN** `PROFILE=openrc` or `PROFILE=systemd`
- **THEN** final checks SHALL evaluate init-specific service and profile expectations separately

#### Scenario: Scope boundary
- **WHEN** a feature is outside the baseline
- **THEN** it SHALL NOT be documented as implemented unless a later approved OpenSpec change adds it

#### Scenario: Optional SSH
- **WHEN** SSH is enabled
- **THEN** baseline validation SHALL follow the installed SSH policy

