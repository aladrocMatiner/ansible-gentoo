# ansible-quality-standards Specification

## Purpose
TBD - created by archiving change define-ansible-quality-standards-and-gates. Update Purpose after archive.
## Requirements
### Requirement: Ansible Quality Standards
The project SHALL maintain Ansible authoring standards for playbooks, roles, tasks, handlers, templates, variables, inventories, and wrapper scripts.

#### Scenario: Quality rules apply to Ansible changes
- **WHEN** an implementation change adds or modifies Ansible content
- **THEN** the change SHALL follow the project Ansible quality standards
- **AND** the change SHALL update relevant docs, skills, agents, and OpenSpec tasks when operator behavior changes

### Requirement: Fully Qualified and Named Ansible Tasks
Ansible playbooks, roles, tasks, and handlers SHALL use clear names and fully qualified module names.

#### Scenario: Task is reviewable
- **WHEN** an Ansible task or handler is added
- **THEN** it SHALL have a clear `name`
- **AND** modules SHALL use fully qualified collection names such as `ansible.builtin.command`

### Requirement: Module-first Implementation
Ansible tasks SHALL use purpose-built modules instead of `command`, `shell`, or `raw` when a reliable module exists.

#### Scenario: Command-like task is necessary
- **WHEN** an Ansible task must use `command`, `shell`, `raw`, or a chroot wrapper
- **THEN** the task SHALL document why a purpose-built module is not used where the reason is not obvious
- **AND** the task SHALL include `changed_when`, `failed_when`, `creates`, `removes`, or equivalent guards where practical
- **AND** safety-sensitive command-like tasks SHALL include path and target assertions before mutation

### Requirement: Idempotency and State Reporting
Ansible tasks SHALL report change accurately and be rerunnable where practical.

#### Scenario: Task mutates target state
- **WHEN** an Ansible task modifies files, packages, services, users, mounts, bootloader state, or target system configuration
- **THEN** it SHALL use idempotent modules or explicit guards where practical
- **AND** non-idempotent behavior SHALL be isolated, tagged, documented, and guarded by confirmation when risk requires it

#### Scenario: Read-only task inspects state
- **WHEN** an Ansible task only reads state
- **THEN** it SHALL report `changed: false`
- **AND** it SHALL NOT mutate the live ISO, target root, VM disk, or host system

### Requirement: Check Mode and Diff Mode Policy
Ansible planning and configuration workflows SHALL define check-mode and diff-mode behavior.

#### Scenario: Planning workflow runs
- **WHEN** a Makefile plan or dry-run target invokes Ansible
- **THEN** Ansible tasks SHALL avoid mutation
- **AND** the output SHALL show what variables, confirmations, and target state are required before apply workflows

#### Scenario: Configuration workflow supports diffs
- **WHEN** an Ansible task manages templates, files, or line-based configuration
- **THEN** it SHALL support check mode and diff mode where the module supports them
- **AND** tasks handling secrets SHALL disable sensitive diff/log output

### Requirement: Ansible Lint Gate
The project SHALL define an ansible-lint configuration and expose Ansible quality checks through Makefile targets.

#### Scenario: Ansible check target runs
- **WHEN** the operator or maintainer runs `make ansible-check`
- **THEN** implemented playbooks SHALL be syntax-checked
- **AND** ansible-lint SHALL run when the tool is installed
- **AND** missing ansible-lint SHALL be reported clearly until a future release or CI change makes it mandatory

### Requirement: Scoped Host Key Exceptions
Ansible SSH host-key relaxation SHALL be scoped to temporary official live ISO wrapper invocations and SHALL NOT be disabled globally.

#### Scenario: Host-to-live-ISO wrapper connects over SSH
- **WHEN** a wrapper connects from the controller to a temporary official Gentoo live ISO target
- **THEN** it MAY disable host key checking for that wrapper invocation only
- **AND** it SHALL make the temporary target explicit
- **AND** global `ansible.cfg` SHALL NOT disable host key checking for all Ansible workflows

### Requirement: Secret-safe Ansible Behavior
Ansible variables, logs, diffs, facts, and audit artifacts SHALL avoid leaking secrets.

#### Scenario: Secret or credential is handled
- **WHEN** an Ansible task handles passwords, API tokens, private keys, SSH key material, or other secrets
- **THEN** the task SHALL use a non-committed input mechanism
- **AND** the task SHALL use `no_log` or equivalent redaction where sensitive values could appear
- **AND** logs, docs, OpenSpec artifacts, and generated reports SHALL NOT contain real secret values

### Requirement: Ansible Review Checklist
Ansible implementation changes SHALL include a quality review checklist before completion.

#### Scenario: Ansible implementation is reviewed
- **WHEN** a change adds or modifies Ansible behavior
- **THEN** review SHALL check FQCN usage, task names, module-first design, idempotency, check-mode behavior, diff safety, variable scope, secret handling, lint/syntax results, Makefile wrapping, and reuse-first OpenRC/systemd architecture

