## ADDED Requirements

### Requirement: Install State Checkpoints
The project SHALL record non-secret checkpoints for installer phases so operators can inspect progress and resume only when current facts match recorded facts.

#### Scenario: Record phase checkpoint
- **WHEN** a Makefile-mediated installer phase completes
- **THEN** the workflow SHALL record the completed phase, selected profile, filesystem, boot mode, relevant non-secret inputs, and validation evidence in project-local state
- **AND** state files SHALL NOT contain passwords, API keys, private keys, login tokens, or secret variable values

#### Scenario: Resume validation
- **WHEN** an operator requests a resume plan
- **THEN** the workflow SHALL compare current disk identity, partition state, filesystem UUIDs, mount state, profile, and filesystem selection against the recorded checkpoint
- **AND** it SHALL fail closed if any required fact is missing or inconsistent

#### Scenario: Destructive resume
- **WHEN** the next resumed phase is destructive
- **THEN** the workflow SHALL require the same explicit confirmations as a fresh destructive run
- **AND** it SHALL NOT treat previous state as confirmation to destroy data

#### Scenario: State inspection through Makefile
- **WHEN** an operator inspects install state
- **THEN** the action SHALL be exposed through a Makefile target
- **AND** the output SHALL summarize the current run id, completed checkpoints, and next safe action
