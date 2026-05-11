## Why

Destructive and semi-destructive installer phases need a durable record of what was planned, confirmed, and completed so an operator can diagnose failures without guessing or repeating risky steps.

This is needed before broad apply workflows because partitioning, formatting, mounting, stage3 extraction, chroot work, user creation, and bootloader installation must be auditable and resumable only when the current machine state still matches the recorded state.

## What Changes

- Add an install run state model under project-local state/log paths such as `var/state/` and `logs/install-runs/`.
- Record phase checkpoints for preflight, disk detection, install plan, partition plan/apply, filesystem plan/apply, mount target, stage3, chroot, Portage, fstab, kernel, packages/services, users, bootloader, final checks, and VM validation.
- Add Makefile-mediated status/report targets, with no operator-facing ad-hoc state commands.
- Require resume checks to revalidate disk identity, filesystem UUIDs, mount state, selected profile, filesystem type, and confirmation state before continuing.
- Preserve recorded manual intervention markers and clear the revalidation flag only after a read-only resume validation succeeds.
- Ensure resume never bypasses destructive confirmations.
- Keep secrets out of state files and logs.

## Capabilities

### New Capabilities
- `install-state-checkpoints`: Records installation phase state and supports safe status/resume decisions.

### Modified Capabilities

## Impact

- Future `Makefile` targets for state reporting and guarded resume behavior.
- Future Ansible common role or callback/plugin for state writes.
- Future docs under `docs/` and relevant skills for state file layout and recovery.
- Shared safety gates and final checks will consume the recorded state.
