# Proposal: Define Ansible Reuse and Role Architecture

## Summary
Define the Ansible architecture rules for `gentoo-ai-installer` so OpenRC and systemd console installation flows share common roles, tasks, handlers, variables, templates, validation logic, safety gates, and documentation wherever behavior is the same.

This change defines architecture and reuse policy only. It does not implement Ansible roles or playbooks.

## Motivation
The project will support at least two basic Gentoo installation variants:

- OpenRC
- systemd

Both variants install Gentoo from the official Gentoo live ISO, use the Makefile as the operator-facing control plane, and must preserve the same disk safety model. The primary product is a reusable Ansible installer for network-reachable live ISO targets. Without a reuse-first architecture, OpenRC and systemd flows can drift into duplicated role trees with inconsistent safety checks, validation, variable names, logs, and documentation.

## Problem Statement
OpenRC and systemd differ in important places, such as stage3 selection, profile selection, service enablement, syslog or journald assumptions, and init-specific validation.

Most of the installer is not init-specific. Disk discovery, partition planning, filesystem checks, mount preparation, stage3 download and verification framework, chroot preparation, Portage baseline configuration, fstab generation, kernel installation, GRUB installation framework, user creation framework, SSH package installation framework, final checks, logging, libvirt VM validation, and safety gates should be implemented once and reused.

The project needs explicit rules that prevent duplicated OpenRC and systemd Ansible logic unless the behavior is genuinely different.

## Scope
- Define Ansible reuse principles.
- Define shared role architecture.
- Define init-specific role architecture.
- Define variable conventions for shared and init-specific values.
- Define task include/import strategy.
- Define handler reuse policy.
- Define template reuse policy.
- Define validation task reuse policy.
- Define safety gate reuse policy.
- Define documentation reuse policy.
- Define Makefile integration expectations.
- Define OpenSpec integration expectations.
- Define libvirt VM testing strategy for OpenRC and systemd flows.
- Define that libvirt/virsh is a local validation harness, while the reusable installer is network/inventory-driven.
- Define anti-duplication review rules.
- Define how Bash helpers may support low-level bootstrap or disk operations without bypassing Makefile or Ansible safety policy.
- Define that shared and init-specific Ansible implementation must pass the project Ansible quality standards and Makefile quality gates.

## Non-goals
- Do not implement Ansible roles or playbooks.
- Do not implement OpenRC or systemd installation automation.
- Do not change the current libvirt VM implementation.
- Do not create custom Gentoo ISO images.
- Do not add LUKS, graphical desktop, or advanced profiles.
- Do not implement filesystem behavior here; ext4 and Btrfs support must be implemented only through approved filesystem plan/apply changes.
- Do not weaken disk safety, confirmation, or Makefile control-plane rules.

## Design Principles
- Common behavior is implemented once and reused.
- Init-specific behavior is isolated, explicit, and small.
- Safety gates are shared and cannot be bypassed by init-specific roles.
- Variables use one shared schema with init-specific overlays.
- Makefile targets are the operator-facing entrypoint.
- Ansible runs from an operator/controller machine against a network-reachable official Gentoo live ISO target. Optional local live ISO execution may exist as fallback or diagnostics, but it is not the primary product path.
- Bash helpers may support low-level bootstrap or disk operations, but they must remain behind Makefile targets or Ansible tasks and must not become an undocumented operator workflow.
- libvirt VM tests exercise the same Makefile and Ansible entrypoints used by real installs, with VM-only discovery and `/dev/vda` assumptions isolated to the harness.
- Ansible implementation must remain lintable, idempotent where practical, check-mode aware, and explicit about command-like tasks.
- Documentation updates are required for architecture, variable, Makefile, and safety behavior changes.

## Safety Considerations
- `install_disk` must not have a default.
- `confirm_wipe_disk` must be explicitly set before destructive operations.
- Shared disk safety checks must run before any partitioning, formatting, mount-over, or bootloader operation.
- No init-specific role may perform destructive disk operations directly.
- No role may assume a default disk.
- OpenRC workflows must not call `systemctl`.
- systemd workflows must not call `rc-update` or `rc-service`.
- libvirt VM `/dev/vda` is acceptable only when explicitly passed as `install_disk=/dev/vda` inside the guest VM.
- Logs must not contain passwords, API keys, login tokens, private keys, or secret variable values.

## Acceptance Criteria
- `openspec validate define-ansible-reuse-and-role-architecture --strict` passes.
- `openspec validate --all --strict` passes.
- The change defines a clear reuse-first Ansible architecture.
- The change identifies shared roles and init-specific roles.
- The change defines variable conventions.
- The change defines anti-duplication rules.
- The change defines safety-gate reuse.
- The change defines Makefile integration.
- The change defines remote/network Ansible target selection and the local libvirt harness boundary.
- The change defines documentation updates.
- The change references the Ansible quality gate for future playbooks, roles, tasks, handlers, templates, and variables.
- The change does not implement the full installer.
- The change does not duplicate OpenRC and systemd playbook logic unnecessarily.

## Affected Files
- `openspec/changes/define-ansible-reuse-and-role-architecture/proposal.md`
- `openspec/changes/define-ansible-reuse-and-role-architecture/design.md`
- `openspec/changes/define-ansible-reuse-and-role-architecture/tasks.md`
- `openspec/changes/define-ansible-reuse-and-role-architecture/specs/ansible-architecture/spec.md`
- Future documentation updates:
  - `AGENTS.md`
  - `agents/ansible-installer-agent.md`
  - `skills/ansible-gentoo-installer.md`
  - `skills/makefile-control-plane.md`
  - `docs/ansible-architecture.md`
- Future implementation files, not created by this change:
  - `ansible/`
  - `Makefile`
