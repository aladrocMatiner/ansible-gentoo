## ADDED Requirements

### Requirement: Roadmap Includes Ansible Quality Guardrail
The project completion roadmap SHALL place Ansible quality standards before broad role implementation and destructive apply workflows.

#### Scenario: Roadmap is reviewed before implementation
- **WHEN** an agent selects the next Ansible implementation change
- **THEN** the roadmap SHALL identify Ansible quality standards as a cross-cutting guardrail
- **AND** future role implementation changes SHALL include lint, syntax, idempotency, check-mode, documentation, and safety review tasks where relevant
