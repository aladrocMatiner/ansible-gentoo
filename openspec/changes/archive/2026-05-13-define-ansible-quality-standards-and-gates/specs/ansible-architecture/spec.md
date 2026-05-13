## ADDED Requirements

### Requirement: Reuse-first Architecture Includes Quality Gates
The reuse-first Ansible architecture SHALL include shared quality standards for all OpenRC and systemd flows.

#### Scenario: Shared Ansible behavior is added
- **WHEN** an Ansible change adds shared behavior for OpenRC and systemd
- **THEN** the behavior SHALL use common roles, shared variables, shared handlers, shared templates, and shared validation where practical
- **AND** it SHALL also satisfy project Ansible quality standards for FQCN, idempotency, check mode, lintability, secret handling, and task naming

#### Scenario: Init-specific behavior is added
- **WHEN** OpenRC-specific or systemd-specific Ansible behavior is added
- **THEN** the behavior SHALL remain isolated in explicit init-specific roles, task files, handlers, templates, variables, or validation tasks
- **AND** it SHALL NOT duplicate shared quality, safety, disk, stage3, chroot, Portage, kernel, bootloader, user, SSH, logging, or final-check logic

### Requirement: Ansible Host Key Policy
The Ansible architecture SHALL keep host-key verification enabled by default and scope temporary exceptions to official live ISO SSH wrappers.

#### Scenario: Optional local live ISO Ansible fallback runs
- **WHEN** an optional fallback workflow runs Ansible locally inside the official Gentoo live ISO
- **THEN** it SHALL NOT depend on global `host_key_checking = False`

#### Scenario: Controller validates temporary live ISO over SSH
- **WHEN** controller-driven Ansible uses SSH to a temporary official live ISO target
- **THEN** wrapper scripts MAY set per-invocation host-key options
- **AND** those options SHALL NOT become the default for unrelated Ansible workflows
- **AND** libvirt VM discovery SHALL be treated as a local test harness convenience rather than a dependency of reusable roles
