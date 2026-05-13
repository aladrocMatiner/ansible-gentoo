## MODIFIED Requirements

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

#### Scenario: Resumable validation reruns planning
- **WHEN** a disposable libvirt validation run uses `make install-resume`
- **THEN** the operator workflow SHALL run `make install-resume-plan` before every one-phase resume execution
- **AND** evidence SHALL show which planned phase was executed
- **AND** the workflow SHALL fail closed if the current plan does not allow resume execution
