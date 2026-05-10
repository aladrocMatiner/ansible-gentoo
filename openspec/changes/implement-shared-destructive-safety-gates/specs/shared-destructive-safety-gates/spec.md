## ADDED Requirements

### Requirement: Shared Destructive Safety Gates
The project SHALL implement shared safety gates that every destructive Ansible workflow must reuse.

#### Scenario: Missing destructive confirmation
- **WHEN** a destructive disk workflow runs without `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- **THEN** it SHALL fail before modifying disks

#### Scenario: Mounted descendant
- **WHEN** the selected disk or any descendant is mounted
- **THEN** destructive workflows SHALL fail closed
- **AND** report the mounted paths

#### Scenario: Preview before confirmation
- **WHEN** a destructive workflow is requested
- **THEN** the workflow SHALL print or call an exact read-only preview before accepting destructive confirmation
- **AND** preview success SHALL NOT satisfy the confirmation requirement

#### Scenario: Resumed destructive workflow
- **WHEN** a destructive workflow resumes from a recorded checkpoint
- **THEN** shared safety gates SHALL compare current disk and mount facts with recorded state
- **AND** fail closed if the checkpoint is missing or inconsistent

#### Scenario: Schema-backed safety
- **WHEN** shared safety gates validate operator input
- **THEN** they SHALL use the canonical configuration schema where available
- **AND** failures SHALL use the shared error taxonomy where practical
