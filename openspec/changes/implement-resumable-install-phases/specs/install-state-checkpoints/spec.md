## ADDED Requirements

### Requirement: Resumable Install Phase Contract
The project SHALL define a resumable phase contract for each shared basic console installation phase.

#### Scenario: Phase contract exists
- **WHEN** a shared install phase is implemented or modified
- **THEN** the phase SHALL define its phase id, preconditions, required variables, required confirmations, risk level, completion evidence, validation checks, skip criteria, re-run criteria, and recovery advice
- **AND** the contract SHALL be documented in code-adjacent docs or generated state metadata

#### Scenario: Shared phase logic is reused
- **WHEN** OpenRC and systemd installs use the same phase
- **THEN** resume validation and skip logic for that phase SHALL be implemented once in shared roles, tasks, or helpers
- **AND** init-specific roles SHALL NOT duplicate disk, filesystem, stage3, chroot, Portage, kernel, bootloader, user, SSH, or final-check resume logic

### Requirement: Read-only Resume Plan
The project SHALL provide a read-only resume plan that determines whether a previous install run can safely continue.

#### Scenario: Resume plan inspects current state
- **WHEN** the operator runs the resume planning workflow
- **THEN** it SHALL read recorded non-secret checkpoints and inspect current live ISO target facts
- **AND** it SHALL report completed phases, current facts, mismatches, the next safe phase, and required confirmations
- **AND** it SHALL NOT mutate disks, filesystems, mounts, target root files, boot entries, users, services, or secrets

#### Scenario: Resume plan fails closed
- **WHEN** disk identity, partition state, filesystem UUIDs, mount state, profile, filesystem, stage3 flavor, boot mode, or required phase evidence is missing or inconsistent
- **THEN** the resume plan SHALL fail closed
- **AND** it SHALL require operator review or manual-step recording before resume execution

### Requirement: One-phase Resume Execution
Resume execution SHALL run only one planner-approved phase by default before requiring a new read-only resume plan.

#### Scenario: Resume phase completes
- **WHEN** `make install-resume` completes the next safe phase
- **THEN** it SHALL record completion evidence for that phase
- **AND** it SHALL stop before starting the following phase
- **AND** it SHALL direct the operator to run `make install-resume-plan` again

#### Scenario: Resume phase reaches a risk boundary
- **WHEN** the next phase requires destructive or high-risk confirmation
- **THEN** resume execution SHALL require the same confirmation variables as a fresh run before starting that phase
- **AND** it SHALL NOT continue into any later phase until the operator runs resume planning again

### Requirement: Checkpoints Are Evidence Not Authority
Recorded checkpoints SHALL be treated as evidence that must be revalidated, not as automatic permission to skip or repeat work.

#### Scenario: Current facts match checkpoint evidence
- **WHEN** the current target facts match the recorded checkpoint evidence for a completed phase
- **THEN** the resume planner MAY mark the phase as safely completed
- **AND** it MAY allow the next phase to be considered

#### Scenario: Current facts differ from checkpoint evidence
- **WHEN** current target facts differ from recorded checkpoint evidence
- **THEN** the resume planner SHALL report the mismatch
- **AND** it SHALL NOT skip, repeat, or continue past the affected phase automatically

### Requirement: Destructive Resume Preserves Confirmations
Resume execution SHALL preserve the same destructive and high-risk confirmations required by fresh execution.

#### Scenario: Next phase is destructive
- **WHEN** the next resumed phase would partition, format, wipe, overwrite filesystems, mount over target paths, install a bootloader, modify boot entries, or change privileged users
- **THEN** the workflow SHALL require the same explicit confirmation variables as a fresh run
- **AND** it SHALL NOT treat previous checkpoints as confirmation

#### Scenario: Destructive phase already completed
- **WHEN** a destructive phase has a checkpoint
- **THEN** the workflow SHALL verify current target facts before deciding that the phase is complete
- **AND** it SHALL NOT re-run the destructive operation unless the operator explicitly requests the relevant destructive target with required confirmations

### Requirement: Manual Intervention Revalidation
Manual intervention during installation SHALL be recorded and revalidated before automation resumes.

#### Scenario: Operator records manual step
- **WHEN** an operator uses the manual-step recording workflow during an install
- **THEN** the note SHALL be non-secret and associated with the relevant run id or target state
- **AND** subsequent resume planning SHALL include the manual intervention in its report

#### Scenario: Resume after manual intervention
- **WHEN** automation resumes after a recorded manual intervention
- **THEN** relevant read-only validation SHALL run before any mutating phase
- **AND** destructive confirmations SHALL still be required for later destructive phases
