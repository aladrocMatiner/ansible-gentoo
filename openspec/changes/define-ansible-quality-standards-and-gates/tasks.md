## 1. OpenSpec

- [x] 1.1 Create `proposal.md`.
- [x] 1.2 Create `design.md`.
- [x] 1.3 Create spec deltas for Ansible quality standards, Ansible architecture, and project roadmap.
- [x] 1.4 Validate with `openspec validate define-ansible-quality-standards-and-gates --strict`.
- [x] 1.5 Validate with `openspec validate --all --strict`.

## 2. Current Configuration

- [x] 2.1 Add project `ansible-lint` configuration.
- [x] 2.2 Update `make ansible-check` implementation to run syntax checks and ansible-lint when available.
- [x] 2.3 Scope live ISO SSH host-key relaxation to wrappers by removing global `host_key_checking = False` from `ansible.cfg`.

## 3. Documentation and Agent Rules

- [x] 3.1 Update `AGENTS.md` with Ansible quality standards.
- [x] 3.2 Update `agents/ansible-installer-agent.md` with quality responsibilities and review checklist.
- [x] 3.3 Update `agents/safety-review-agent.md` with Ansible quality and secret/lint review rules.
- [x] 3.4 Update `agents/openspec-agent.md` so Ansible implementation changes include quality-gate tasks.
- [x] 3.5 Update `skills/ansible-gentoo-installer.md` with FQCN, module-first, idempotency, check-mode, lint, secret, host-key, and review rules.
- [x] 3.6 Update `skills/makefile-control-plane.md` with Ansible quality gate expectations for Makefile targets.
- [x] 3.7 Update `docs/ansible-architecture.md` with the Ansible quality standards.
- [x] 3.8 Update `docs/project-completion-roadmap.md` to place Ansible quality standards before broad role implementation.

## 4. Existing OpenSpec Alignment

- [x] 4.1 Update `define-ansible-reuse-and-role-architecture` to reference quality gates and libvirt VM terminology.
- [x] 4.2 Update `define-project-completion-roadmap` to include the Ansible quality guardrail.
- [x] 4.3 Review existing Ansible implementation proposals for stale QEMU terminology or missing quality-gate expectations.

## 5. Verification

- [x] 5.1 Run `make ansible-check`.
- [x] 5.2 Run syntax checks for implemented Ansible playbooks if `make ansible-check` cannot complete.
- [x] 5.3 Report whether ansible-lint was run or skipped because the tool is unavailable.
- [x] 5.4 Review `git diff` for accidental destructive or installer-automation changes.
