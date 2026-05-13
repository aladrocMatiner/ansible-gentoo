# live-iso-network-bootstrap Specification

## Purpose
TBD - created by archiving change implement-live-iso-network-bootstrap-hardening. Update Purpose after archive.
## Requirements
### Requirement: Live ISO Network Bootstrap
The project SHALL validate network and access readiness in the official Gentoo live ISO before Ansible installer workflows depend on it.

#### Scenario: Network readiness
- **WHEN** live ISO network bootstrap runs
- **THEN** it SHALL verify IP address, default route, DNS resolution, and sane system time
- **AND** failures SHALL provide actionable messages

#### Scenario: SSH readiness
- **WHEN** controller-to-live-ISO Ansible mode is used
- **THEN** the workflow SHALL verify SSH reachability and known_hosts behavior before running installer playbooks

#### Scenario: Scope boundary
- **WHEN** network bootstrap runs
- **THEN** it SHALL NOT partition, format, mount target filesystems, chroot, create target users, or install bootloaders

