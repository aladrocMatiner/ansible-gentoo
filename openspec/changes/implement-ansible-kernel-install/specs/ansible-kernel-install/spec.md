## ADDED Requirements

### Requirement: gentoo-kernel-bin Installation
The project SHALL install `gentoo-kernel-bin` into the target system using shared Ansible logic.

#### Scenario: installkernel support
- **WHEN** `gentoo-kernel-bin` is installed for a GRUB boot flow
- **THEN** installkernel/initramfs support SHALL be configured as required by the Gentoo Handbook guidance for distribution kernels

#### Scenario: Kernel artifacts exist
- **WHEN** kernel installation completes
- **THEN** target `/boot` SHALL contain kernel artifacts required for boot
