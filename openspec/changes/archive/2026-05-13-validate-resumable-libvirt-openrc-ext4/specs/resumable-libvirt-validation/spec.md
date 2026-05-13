## ADDED Requirements

### Requirement: Resumable Libvirt Single-case Validation
The project SHALL provide an operator-facing validation workflow for running the resumable installer one phase at a time in a disposable libvirt VM.

#### Scenario: Validate the first resumable VM case
- **WHEN** the resumable libvirt validation workflow is executed
- **THEN** it SHALL target the `amd64/openrc/ext4/standard` case by default
- **AND** it SHALL use the `gentoo-test-amd64-openrc-ext4` VM identity
- **AND** it SHALL use the official Gentoo live ISO boot path
- **AND** it SHALL use only project-local qcow2 storage for the VM

#### Scenario: Planner before every resumed phase
- **WHEN** an operator validates resumable installation in libvirt
- **THEN** the workflow SHALL run `make install-resume-plan` before each `make install-resume`
- **AND** it SHALL record the planner result or its log location before executing the next phase

#### Scenario: One phase per resume execution
- **WHEN** `make install-resume` runs during libvirt validation
- **THEN** it SHALL execute only the next planner-approved phase
- **AND** it SHALL stop before any later phase
- **AND** the next action SHALL be another `make install-resume-plan`

#### Scenario: Destructive VM phases remain confirmed
- **WHEN** the next resumed phase partitions, formats, overwrites filesystems, changes privileged users, or installs the bootloader inside the disposable VM
- **THEN** the workflow SHALL require the same explicit confirmation variables as the normal Makefile target
- **AND** it SHALL NOT treat VM disposability or existing checkpoints as confirmation

#### Scenario: Validation evidence is collected
- **WHEN** a resumed VM phase completes or fails
- **THEN** the workflow SHALL leave non-secret evidence under ignored project state or log paths
- **AND** the validation documentation SHALL identify the relevant state pointer, run id, phase, and log locations

#### Scenario: Validation does not expand installer scope
- **WHEN** this validation change is implemented
- **THEN** it SHALL NOT implement a new installer feature
- **AND** it SHALL NOT expand the matrix beyond the first `openrc/ext4/standard` resumable case
- **AND** any implementation fix found during validation SHALL be made in shared installer logic where the behavior is shared
