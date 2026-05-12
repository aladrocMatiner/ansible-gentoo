# Tasks: define-ansible-reuse-and-role-architecture

## 1. OpenSpec Artifacts
- [x] Create `proposal.md` with summary, motivation, scope, non-goals, design principles, safety considerations, acceptance criteria, and affected files.
- [x] Create `design.md` defining the reuse-first Ansible architecture.
- [x] Create `tasks.md` with checkable architecture, documentation, review, and validation tasks.
- [x] Create `specs/ansible-architecture/spec.md` with an OpenSpec delta.

## 2. Ansible Architecture Definition
- [x] Define the core reuse principle: common behavior is implemented once and reused.
- [x] Define the proposed Ansible layout.
- [x] Define the shared role model.
- [x] Define the init-specific role model.
- [x] Define allowed alternatives to the proposed layout while preserving reuse.
- [x] Define remote/network Ansible as the primary product path and libvirt as a local validation harness.

## 3. Variable Model Definition
- [x] Define shared variables.
- [x] Define init-specific variable files or equivalent.
- [x] Require `install_disk` to have no default.
- [x] Require `confirm_wipe_disk` for destructive operations.
- [x] Require `init_system` to be either `openrc` or `systemd`.
- [x] Require `stage3_variant` to match `init_system` and `stage3_flavor` to select the official stage3/profile family.
- [x] Define libvirt VM `/dev/vda` handling as explicit guest-only input.
- [x] Define explicit network live ISO target variables and forbid default target hosts.

## 4. Reuse Policy Definition
- [x] Define task include/import strategy.
- [x] Define handler reuse policy.
- [x] Define template reuse policy.
- [x] Define validation task reuse policy.
- [x] Define safety gate reuse policy.
- [x] Define Bash helper boundaries for low-level bootstrap or disk operations.
- [x] Define anti-duplication rules.

## 5. Init-specific Rules
- [x] Define OpenRC-specific behavior.
- [x] Define systemd-specific behavior.
- [x] Forbid OpenRC workflows from calling `systemctl`.
- [x] Forbid systemd workflows from calling `rc-update` or `rc-service`.
- [x] Forbid init-specific roles from performing destructive disk operations directly.

## 6. Makefile Integration Definition
- [x] Define expected high-level Makefile targets for OpenRC and systemd flows.
- [x] Define `PROFILE=openrc` and `PROFILE=systemd` behavior.
- [x] Require Makefile targets to pass init-specific variables into shared Ansible flow where practical.
- [x] Require Makefile Ansible targets to support explicit network live ISO targets without requiring libvirt discovery.
- [x] Require existing-target documentation to distinguish implemented targets from planned targets.

## 7. Documentation Updates
- [x] Update `AGENTS.md` with the Ansible reuse rule.
- [x] Update `agents/ansible-installer-agent.md` with reuse-first architecture responsibilities.
- [x] Update `skills/ansible-gentoo-installer.md` with shared role and init-specific role rules.
- [x] Update `skills/makefile-control-plane.md` if Makefile behavior is affected.
- [x] Add or update `docs/ansible-architecture.md` with the reuse-first architecture.
- [x] Ensure documentation does not claim roles or playbooks exist before implementation.

## 8. Review Checklist
- [x] Add review criteria for duplicated OpenRC/systemd logic.
- [x] Add review criteria for shared safety gates.
- [x] Add review criteria for init-specific service manager separation.
- [x] Add review criteria for libvirt VM testing assumptions.
- [x] Add review criteria for documentation updates.
- [x] Cross-check against current OpenRC install documentation.
- [x] Cross-check against planned systemd install documentation.

## 9. Validation
- [x] Run `openspec validate define-ansible-reuse-and-role-architecture --strict`.
- [x] Run `openspec validate --all --strict`.
