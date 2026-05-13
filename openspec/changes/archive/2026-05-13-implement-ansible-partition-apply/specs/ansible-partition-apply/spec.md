## ADDED Requirements

### Requirement: Destructive Partition Apply
The project SHALL provide a guarded Makefile-mediated partition apply workflow that writes the approved GPT layout only after explicit confirmation.

#### Scenario: Confirmation required
- **WHEN** `make partition` runs without `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- **THEN** it SHALL fail before disk writes

#### Scenario: Apply VM partition layout
- **WHEN** the operator runs `make partition INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes` inside the VM workflow
- **THEN** the workflow SHALL create a 512 MiB EFI system partition and a root partition using the remaining disk
- **AND** it SHALL NOT format or mount filesystems
