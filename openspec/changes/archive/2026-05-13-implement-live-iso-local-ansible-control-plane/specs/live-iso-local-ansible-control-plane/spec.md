## ADDED Requirements

### Requirement: Optional Local Live ISO Ansible Control Plane
If the project provides a Makefile-mediated way to run Ansible locally inside the official Gentoo live ISO, it SHALL treat that path as fallback or diagnostics while keeping the primary installer network/inventory-driven.

#### Scenario: Run local live ISO planning
- **WHEN** the project is available inside the live ISO
- **THEN** the operator SHALL be able to run documented Makefile targets using a local Ansible inventory
- **AND** the workflow SHALL NOT require controller-to-target SSH
- **AND** the workflow SHALL be documented as optional fallback or diagnostics, not the primary product path
- **AND** live ISO network/bootstrap readiness SHALL be checked before Ansible handoff where relevant

#### Scenario: Preserve VM testing
- **WHEN** the operator runs libvirt validation workflows
- **THEN** controller-to-VM SSH targets SHALL remain available for testing
- **AND** they SHALL be documented separately from local live ISO execution
- **AND** both local and VM modes SHALL remain subordinate to the reusable network Ansible installer architecture

#### Scenario: Local mode keeps host-key policy scoped
- **WHEN** Ansible runs locally inside the official Gentoo live ISO
- **THEN** the workflow SHALL NOT depend on globally disabled Ansible host-key checking
- **AND** temporary host-key exceptions SHALL remain limited to controller-to-live-ISO SSH wrappers

#### Scenario: Local mode passes quality gate
- **WHEN** local live ISO Ansible playbooks or inventories are implemented
- **THEN** they SHALL satisfy the project Ansible quality standards
- **AND** `make ansible-check` SHALL validate implemented playbooks and run ansible-lint when available
