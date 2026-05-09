## ADDED Requirements

### Requirement: Documentation Maintenance for Behavior Changes
Agents SHALL update project documentation in the same change whenever they modify operator behavior.

Operator behavior includes Makefile targets, scripts, script arguments, environment variables, safety confirmations, Ansible playbooks, installation flow, QEMU workflow, Codex bootstrap method, OpenSpec workflow, and disk safety model.

#### Scenario: Makefile target changes require documentation
- **WHEN** an agent adds, changes, or removes a Makefile target
- **THEN** the change SHALL update `README.md` or appropriate files under `docs/`
- **AND** the change SHALL update related `skills/` or `agents/` guidance when reusable procedures or agent behavior are affected

#### Scenario: Script changes require documentation
- **WHEN** an agent adds a script or changes script arguments, environment variables, output, or failure modes
- **THEN** the change SHALL update `docs/` or `skills/` with operational usage and failure guidance

#### Scenario: Safety changes require safety documentation
- **WHEN** an agent changes safety confirmations, destructive-operation handling, disk checks, cleanup behavior, QEMU disk handling, bootloader behavior, or secret handling
- **THEN** the change SHALL update safety documentation in `agents/`, `skills/`, `docs/`, or root agent instructions as appropriate
- **AND** the documentation SHALL describe required confirmations, rejected unsafe inputs, and recovery advice

#### Scenario: Codex bootstrap changes require documentation
- **WHEN** an agent changes Codex bootstrap methods, authentication guidance, environment variables, temporary filesystem behavior, or cleanup behavior
- **THEN** the change SHALL update Codex bootstrap documentation in `docs/`, `skills/`, `agents/`, or root agent instructions as appropriate
- **AND** the documentation SHALL preserve secret-handling rules and the temporary-live-environment boundary

#### Scenario: OpenSpec tasks track documentation work
- **WHEN** an OpenSpec change implements behavior
- **THEN** `openspec/changes/<change>/tasks.md` SHALL include documentation tasks
- **AND** those tasks SHALL remain incomplete until the documentation is updated and reviewed

#### Scenario: Root agent documentation exists
- **WHEN** the documentation maintenance rule is implemented
- **THEN** the repository SHALL contain `AGENTS.md` or `agents.md`
- **AND** that file SHALL include the documentation maintenance rule for all agents

#### Scenario: Documentation excludes secrets
- **WHEN** agents update documentation
- **THEN** documentation SHALL NOT include real API keys, real tokens, real private SSH keys, passwords, local credentials, or host-specific secrets
- **AND** documentation MAY include placeholders or `.env.example` variable names when useful

#### Scenario: Documentation remains operational and scoped
- **WHEN** agents update project documentation
- **THEN** documentation SHALL prefer commands, expected outputs, failure modes, recovery advice, and safety checks over vague prose
- **AND** detailed procedures SHALL live under `docs/` or `skills/`
- **AND** `README.md` SHALL remain concise
