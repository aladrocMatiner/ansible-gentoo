## ADDED Requirements

### Requirement: Basic Console Install Orchestration
The project SHALL provide high-level Makefile targets for OpenRC and systemd basic console installs that reuse a shared Ansible flow.

#### Scenario: Shared OpenRC flow
- **WHEN** `make install-openrc` runs
- **THEN** it SHALL call the shared install flow with OpenRC variables
- **AND** it SHALL use the same checkpoint, audit, safety, secret, and traceability guardrails as the shared flow
- **AND** it SHALL use the canonical configuration schema and target baseline checks

#### Scenario: Shared systemd flow
- **WHEN** `make install-systemd` runs
- **THEN** it SHALL call the shared install flow with systemd variables
- **AND** it SHALL use the same checkpoint, audit, safety, secret, and traceability guardrails as the shared flow
- **AND** it SHALL use the canonical configuration schema and target baseline checks

#### Scenario: Shared flow passes quality gate
- **WHEN** basic console install orchestration is implemented
- **THEN** the shared flow and thin entrypoints SHALL satisfy the project Ansible quality standards
- **AND** `make ansible-check` SHALL validate implemented playbooks and run ansible-lint when available
