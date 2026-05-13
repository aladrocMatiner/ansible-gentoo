# define-project-completion-roadmap Specification

## Purpose
TBD - created by archiving change define-ansible-quality-standards-and-gates. Update Purpose after archive.
## Requirements
### Requirement: Roadmap Includes Ansible Quality Guardrail
The project completion roadmap SHALL place Ansible quality standards before broad role implementation and destructive apply workflows.

#### Scenario: Roadmap is reviewed before implementation
- **WHEN** an agent selects the next Ansible implementation change
- **THEN** the roadmap SHALL identify Ansible quality standards as a cross-cutting guardrail
- **AND** future role implementation changes SHALL include lint, syntax, idempotency, check-mode, documentation, and safety review tasks where relevant

### Requirement: Project Completion Roadmap
The project SHALL maintain a roadmap that orders the remaining OpenSpec changes needed to complete a reproducible Gentoo basic-console installation.

#### Scenario: Roadmap lists dependencies
- **WHEN** an agent reviews the project roadmap
- **THEN** it SHALL identify the next safe implementation change
- **AND** it SHALL distinguish destructive changes from read-only and semi-dangerous changes
- **AND** it SHALL place cross-cutting guardrails before destructive workflows that depend on them

#### Scenario: Roadmap preserves project rules
- **WHEN** future work is planned
- **THEN** it SHALL preserve Makefile control-plane behavior
- **AND** it SHALL preserve official Gentoo live ISO usage
- **AND** it SHALL preserve OpenRC/systemd reuse-first Ansible architecture
- **AND** it SHALL preserve network-reachable live ISO Ansible as the primary product path
- **AND** it SHALL treat libvirt as local validation harness infrastructure

#### Scenario: Roadmap preserves Ansible quality gates
- **WHEN** future Ansible implementation work is planned
- **THEN** the roadmap SHALL place Ansible quality standards before broad role implementation
- **AND** Ansible implementation changes SHALL include syntax, lint, idempotency, check-mode, secret, and documentation review tasks where relevant

