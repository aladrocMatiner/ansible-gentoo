## Why

Installer failures need a compact evidence bundle for debugging. Without a standard bundle, operators must manually collect logs, disk facts, fstab, package choices, bootloader evidence, and final checks.

## What Changes

- Add a project-local install audit bundle produced at key checkpoints and final readiness.
- Include non-secret variables, hardware/disk summaries, UUIDs, fstab, package policy, service enablement status, bootloader evidence, Ansible logs, OpenSpec change id, and final checks.
- Include stage3 download verification evidence from the download cache/mirror policy without bundling downloaded tarballs.
- Include recorded manual intervention notes after the same secret-like content scan used for other evidence.
- Redact or reject secrets before writing bundle files.
- Expose bundle generation through Makefile targets.

## Capabilities

### New Capabilities
- `install-audit-bundle`: Produces a secret-safe, project-local evidence bundle for install debugging and review.

### Modified Capabilities

## Impact

- Future logging paths under `logs/install-runs/`.
- Final checks and release readiness docs.
- Secret handling rules and documentation.
