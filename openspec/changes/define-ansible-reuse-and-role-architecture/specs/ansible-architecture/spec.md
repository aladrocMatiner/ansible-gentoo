## ADDED Requirements

### Requirement: Reuse-first Ansible Architecture
The project SHALL define Ansible installation flows so common behavior is implemented once and reused across OpenRC and systemd variants.

Shared behavior includes preflight checks, network live ISO target validation, architecture detection, UEFI detection, disk discovery, disk identity reporting, safety confirmation validation, partition planning, filesystem checks, mount target preparation, stage3 download framework, stage3 verification framework, stage3 extraction, chroot preparation, Portage baseline configuration, package installation framework, fstab generation, kernel installation, GRUB installation framework, user creation framework, SSH package installation framework, final validation checks, logging, and libvirt VM validation flow.

The reusable installer SHALL be network/inventory-driven. libvirt VM behavior is a local validation harness for the same Ansible workflows.

#### Scenario: Shared roles own common behavior
- **WHEN** an Ansible implementation adds behavior used by both OpenRC and systemd flows
- **THEN** the behavior SHALL be implemented in a shared role, shared task file, shared handler, shared template, shared validation task, or shared variable model
- **AND** the behavior SHALL NOT be duplicated separately in OpenRC and systemd role trees unless the change documents a genuine behavioral difference

#### Scenario: Init-specific roles stay explicit and narrow
- **WHEN** an Ansible implementation adds OpenRC-specific or systemd-specific behavior
- **THEN** the behavior SHALL be isolated in init-specific roles, task files, handlers, templates, variables, or validation tasks
- **AND** the implementation SHALL document why the behavior is init-specific

#### Scenario: Network target remains primary
- **WHEN** an Ansible implementation adds or changes installer behavior
- **THEN** reusable roles and playbooks SHALL work against a network-reachable official Gentoo live ISO target selected by inventory or Makefile variables
- **AND** they SHALL NOT depend on libvirt domain names, VM-only IP discovery, qcow2 paths, or `/dev/vda`
- **AND** VM-specific assumptions SHALL be isolated to local test harness scripts, docs, examples, or validation fixtures

### Requirement: Init-specific Service Manager Separation
OpenRC and systemd flows SHALL use only their own service management commands.

#### Scenario: OpenRC flow avoids systemd commands
- **WHEN** the selected init system is `openrc`
- **THEN** Ansible tasks and handlers SHALL NOT call `systemctl`
- **AND** service enablement SHALL use OpenRC-specific logic such as `rc-update` where service enablement is required

#### Scenario: systemd flow avoids OpenRC commands
- **WHEN** the selected init system is `systemd`
- **THEN** Ansible tasks and handlers SHALL NOT call `rc-update` or `rc-service`
- **AND** service enablement SHALL use systemd-specific logic such as `systemctl` where service enablement is required

### Requirement: Shared Variable Model
The Ansible architecture SHALL use a shared variable model with init-specific overlays.

#### Scenario: Shared variables are defined consistently
- **WHEN** an Ansible install flow runs
- **THEN** variables such as `install_disk`, `hostname`, `admin_user`, `filesystem`, `boot_mode`, `stage3_variant`, `init_system`, `enable_ssh`, `confirm_wipe_disk`, `target_mount`, `efi_mount`, and `vm_guest_mode` SHALL have one documented meaning across OpenRC and systemd flows
- **AND** init-specific values SHALL live in `group_vars/openrc.yml`, `group_vars/systemd.yml`, or an equivalent documented variant mechanism

#### Scenario: Init system and stage3 variant match
- **WHEN** `init_system` is set to `openrc` or `systemd`
- **THEN** `stage3_variant` SHALL match the selected init system
- **AND** validation SHALL fail closed when the variant does not match

### Requirement: Shared Safety Gates
Safety gates SHALL be implemented once and reused by OpenRC and systemd flows.

#### Scenario: Destructive operations require shared safety checks
- **WHEN** an Ansible task would partition, format, wipe, mount over existing target paths, install a bootloader, or otherwise perform destructive or high-risk target mutation
- **THEN** the task SHALL depend on shared safety validation
- **AND** `install_disk` SHALL be explicitly provided
- **AND** `install_disk` SHALL NOT have a default value
- **AND** `confirm_wipe_disk` SHALL be explicitly set where destructive disk operations are involved

#### Scenario: Init-specific roles cannot bypass disk safety
- **WHEN** an init-specific role runs
- **THEN** it SHALL NOT partition, format, wipe, or select disks directly
- **AND** it SHALL NOT redefine or weaken shared disk safety checks

#### Scenario: libvirt VM guest disk is explicit
- **WHEN** libvirt VM testing uses `/dev/vda` inside the guest VM
- **THEN** `/dev/vda` SHALL be accepted only when explicitly passed as `install_disk=/dev/vda`
- **AND** VM guest mode SHALL NOT disable destructive confirmations or disk identity checks

### Requirement: Makefile-mediated Ansible Entrypoints
Operator-facing Ansible workflows SHALL be exposed through Makefile targets.

#### Scenario: Init-specific install targets use shared flow
- **WHEN** the project adds OpenRC and systemd Ansible entrypoints
- **THEN** Makefile targets such as `make install-openrc`, `make install-systemd`, `make install-plan PROFILE=openrc`, `make install-plan PROFILE=systemd`, `make ansible-check`, `make ansible-dry-run PROFILE=openrc`, and `make ansible-dry-run PROFILE=systemd` SHALL pass init-specific variables into a shared Ansible flow where practical
- **AND** destructive targets SHALL require the same shared confirmation and disk safety variables
- **AND** Ansible targets SHALL support an explicit network live ISO target such as `ANSIBLE_LIVE_HOST=...` without requiring local libvirt discovery

### Requirement: Bash Helper Boundary
Bash helpers MAY support low-level bootstrap or disk operations, but they SHALL NOT bypass Makefile control-plane or shared Ansible safety policy.

#### Scenario: Bash helpers remain controlled implementation details
- **WHEN** a Bash helper is used for low-level bootstrap, disk inspection, disk safety, or disk execution behavior
- **THEN** it SHALL be invoked through a Makefile target or an Ansible task
- **AND** it SHALL use the same documented variables, confirmations, path checks, disk checks, and failure behavior as the shared Ansible safety model
- **AND** it SHALL NOT become an undocumented operator-facing workflow

### Requirement: Documentation Tracks Ansible Architecture
Ansible architecture changes SHALL update documentation in the same change.

#### Scenario: Documentation changes with architecture
- **WHEN** an Ansible architecture, role, variable, Makefile target, safety gate, or init-specific behavior changes
- **THEN** the change SHALL update relevant documentation such as `AGENTS.md`, `agents/ansible-installer-agent.md`, `skills/ansible-gentoo-installer.md`, `skills/makefile-control-plane.md`, and `docs/`
- **AND** OpenSpec `tasks.md` SHALL include documentation tasks
- **AND** documentation SHALL distinguish implemented Ansible behavior from planned behavior

### Requirement: Architecture Uses Ansible Quality Gates
Future Ansible architecture and implementation changes SHALL follow the project Ansible quality standards.

#### Scenario: Ansible behavior is implemented
- **WHEN** a change adds or modifies Ansible roles, playbooks, tasks, handlers, templates, variables, or inventories
- **THEN** the change SHALL use FQCN module names and named tasks
- **AND** command-like tasks SHALL be justified and guarded
- **AND** idempotency, check-mode behavior, diff safety, secret handling, host-key scope, and `make ansible-check` results SHALL be reviewed before completion
