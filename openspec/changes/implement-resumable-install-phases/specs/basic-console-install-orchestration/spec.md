## ADDED Requirements

### Requirement: Makefile-mediated Install Resume
The shared basic console install flow SHALL expose resume planning and guarded resume execution through Makefile targets.

#### Scenario: Operator requests resume plan
- **WHEN** the operator runs `make install-resume-plan`
- **THEN** the target SHALL run a read-only resume planner for the selected live ISO target
- **AND** it SHALL print the current run id, selected profile, filesystem, stage3 flavor, install disk identity, completed phases, mismatches, next safe phase, and required confirmations

#### Scenario: Operator requests resume execution
- **WHEN** the operator runs `make install-resume`
- **THEN** the target SHALL require a successful compatible resume plan or perform equivalent preflight validation before mutation
- **AND** it SHALL resume only through shared Ansible phase logic
- **AND** it SHALL execute only the next safe phase by default
- **AND** it SHALL stop after that phase records completion evidence
- **AND** it SHALL require the operator to run `make install-resume-plan` again before continuing to another phase
- **AND** it SHALL fail closed when required state or confirmations are missing

#### Scenario: Resume works for local and remote targets
- **WHEN** `ANSIBLE_LIVE_HOST` is set to a network live ISO target or omitted for local libvirt discovery
- **THEN** resume planning and execution SHALL use the same shared Ansible phase model
- **AND** libvirt-specific disk examples such as `/dev/vda` SHALL remain local test examples only

### Requirement: Resumable Shared Install Orchestration
The basic console installer SHALL be structured so each shared phase can be validated, skipped, or resumed according to the shared phase contract.

#### Scenario: Fresh install records phase evidence
- **WHEN** a fresh install phase completes
- **THEN** the shared flow SHALL record non-secret completion evidence sufficient for later resume planning
- **AND** the evidence SHALL be associated with the install run id

#### Scenario: Resume avoids OpenRC/systemd duplication
- **WHEN** resume behavior is implemented for OpenRC and systemd installs
- **THEN** common resume behavior SHALL live in shared roles, task files, or helpers
- **AND** init-specific resume behavior SHALL be limited to genuinely init-specific facts such as profile, stage3 variant, service manager state, and service enablement validation

#### Scenario: Long-running phases are bounded
- **WHEN** a phase performs long-running network, Portage, package, kernel, or filesystem work
- **THEN** the phase SHALL use bounded retries, timeouts, or Ansible async/poll where practical
- **AND** failure output SHALL identify the failed phase and recommended resume or recovery action
