## ADDED Requirements

### Requirement: First Boot Validation
The project SHALL validate completed libvirt installs by booting from the installed disk and running read-only checks.

#### Scenario: Boot from installed disk
- **WHEN** first-boot validation starts
- **THEN** the VM SHALL boot from the installed qcow2 disk
- **AND** the live ISO SHALL NOT be required as the primary boot path

#### Scenario: Validate installed system
- **WHEN** the installed system is reachable
- **THEN** the workflow SHALL verify hostname, root filesystem UUID, kernel presence, NetworkManager status, admin user presence, and optional SSH access

#### Scenario: Host safety
- **WHEN** first-boot validation runs
- **THEN** it SHALL NOT reboot or modify the host system
