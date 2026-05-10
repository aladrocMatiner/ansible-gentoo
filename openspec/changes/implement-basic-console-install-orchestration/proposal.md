# Change: implement-basic-console-install-orchestration

## Summary
Add the high-level basic console install orchestration that wires approved roles into OpenRC and systemd install flows.

## Motivation
After individual roles exist, operators need stable Makefile targets that execute the full sequence safely without duplicated OpenRC/systemd logic.

## Scope
- Add shared `install-basic-console.yml`.
- Add thin `install-openrc.yml` and `install-systemd.yml`.
- Add Makefile targets `install-openrc`, `install-systemd`, and possibly `install`.
- Require all destructive confirmations for full install.
- Integrate install-state checkpoints, audit bundle generation, and Handbook traceability where practical.
- Require config validation and target system baseline checks before full install orchestration.
- Require the shared flow and thin entrypoints to pass Ansible quality standards and `make ansible-check`.

## Non-goals
- Do not add new installer behavior beyond approved roles.
- Do not bypass role-level safety gates.

## Safety Requirements
- Full install must require explicit disk and destructive confirmation.
- Shared flow must call shared safety gates.
- Full install must not bypass preview, state, audit, or secret policies from their approved changes.
- Full install must use the canonical configuration schema.
- OpenRC/systemd targets must remain thin wrappers.
- Full install orchestration must not introduce unreviewed command-like tasks, unchecked lint exceptions, or global host-key disabling.

## Acceptance Criteria
- OpenRC and systemd install targets reuse the same shared role sequence.
- Shared orchestration records checkpoints and audit evidence for each phase.
- Shared orchestration reports target baseline coverage.
- Full install works in the libvirt VM.
- `openspec validate implement-basic-console-install-orchestration --strict` passes.

## Affected Files
- `Makefile`
- `ansible/playbooks/install-basic-console.yml`
- `ansible/playbooks/install-openrc.yml`
- `ansible/playbooks/install-systemd.yml`
- `docs/`
- `skills/`
