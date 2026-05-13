## Why

The full Gentoo install flow performs many long and stateful phases over SSH. If a network timeout, controller interruption, or manual recovery step occurs, the operator needs a safe way to inspect what completed, determine the next valid phase, and resume without repeating destructive work blindly.

The project already records checkpoints, but the current contract does not yet define a complete resumable phase model with phase validation, skip rules, destructive safeguards, and operator-facing resume targets.

## What Changes

- Define a resumable installation phase model for the basic console installer.
- Add read-only resume planning that reports completed phases, current target facts, mismatches, and the next safe action.
- Add guarded resume execution through Makefile targets.
- Require every phase to define:
  - preconditions,
  - completion evidence,
  - idempotency or skip behavior,
  - mismatch handling,
  - destructive confirmation behavior.
- Ensure destructive phases are never skipped or repeated solely because a checkpoint exists.
- Preserve existing explicit confirmations for partitioning, formatting, and bootloader changes.
- Require manual interventions to be recorded and revalidated before automation resumes.
- Require long-running or fragile phases to use bounded retries or Ansible async/poll where appropriate.

## Capabilities

### New Capabilities

### Modified Capabilities

- `install-state-checkpoints`: extend checkpointing into a full resumable phase contract.
- `basic-console-install-orchestration`: add operator-facing resume planning and guarded resume execution for the shared OpenRC/systemd install flow.

## Impact

- Affected Makefile behavior:
  - likely add or complete `make install-resume-plan`.
  - add `make install-resume` if not already present.
  - document resume variables and required confirmations.
- Affected Ansible:
  - shared install orchestration playbook.
  - `common/install_state`.
  - phase roles for partitioning, filesystem, mount target, stage3, chroot, Portage, fstab, kernel, packages/services, users, bootloader, and final checks.
  - no OpenRC/systemd duplication; resume behavior must live in shared roles/tasks.
- Affected scripts:
  - install orchestration wrappers.
  - state inspection/resume helpers.
  - manual-step recording integration if needed.
- Affected documentation:
  - `docs/install-state-and-resume-checkpoints.md`.
  - `docs/manual-escape-hatch-policy.md`.
  - `docs/ansible-basic-console-install-orchestration.md`.
  - `docs/install-audit-bundle.md`.
  - quickstarts where full install retry/resume is described.
  - `skills/ansible-gentoo-installer.md`.
  - `agents/ansible-installer-agent.md` and `agents/safety-review-agent.md` if agent responsibilities change.
- Affected validation:
  - `make ansible-check`.
  - `make release-check`.
  - targeted libvirt smoke/e2e tests where practical.
  - `openspec validate implement-resumable-install-phases --strict`.
  - `openspec validate --all --strict`.
