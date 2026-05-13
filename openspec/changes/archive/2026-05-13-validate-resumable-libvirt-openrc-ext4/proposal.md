## Why

The project now has a resumable install phase contract and a one-phase `make install-resume` target, but it needs a real disposable VM validation run before using the pattern for the full matrix or remote hardware. The first validation should prove that `openrc/ext4/standard` can advance safely phase by phase through libvirt without relying on one long `make install` run.

## What Changes

- Add a validation runbook for the `openrc/ext4/standard` resumable libvirt path.
- Execute the flow against a disposable `gentoo-test-amd64-openrc-ext4` VM using the official Gentoo live ISO and a qcow2 disk.
- Use `make install-resume-plan` before each `make install-resume` phase.
- Record which phases were validated, which confirmations were required, and where evidence was written.
- Fix any implementation bugs found by the validation run, keeping fixes shared and not OpenRC-specific.
- Do not add new installer features beyond fixes required for the validation to pass.

## Capabilities

### New Capabilities
- `resumable-libvirt-validation`: Defines the operator-facing validation contract for running the resumable installer one phase at a time in a disposable libvirt VM.

### Modified Capabilities
- `install-state-checkpoints`: Clarifies that resumable validation evidence must show the planner was rerun before each executed phase.
- `libvirt-end-to-end-install-validation`: Adds the resumable single-case validation path as the preferred first VM check before broader matrix runs.

## Impact

- Affected Makefile behavior: existing `vm-*`, `install-resume-plan`, and `install-resume` targets are exercised; new targets are not expected unless the validation reveals a gap.
- Affected Ansible: fixes may touch shared roles only if a phase-by-phase run exposes an issue.
- Affected documentation: add or update docs for resumable libvirt validation and link from README or existing libvirt/resume docs.
- Affected OpenSpec: add validation requirements and tasks for the disposable `openrc/ext4/standard` case.
- Affected runtime artifacts: disposable VM files under `var/libvirt/`, state under `var/state/`, and logs under `logs/`; these remain ignored by git.
