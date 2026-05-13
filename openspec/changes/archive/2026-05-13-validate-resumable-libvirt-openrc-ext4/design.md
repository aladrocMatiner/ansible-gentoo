## Context

The project now supports resumable installer phases through `make install-resume-plan` and `make install-resume`. The next risk is not feature coverage; it is proving the phase-by-phase contract against a real disposable libvirt guest before relying on it for the full matrix or remote hardware.

This change validates the smallest representative case:

- architecture: `amd64`
- profile: `openrc`
- filesystem: `ext4`
- stage3 flavor: `standard`
- VM domain: `gentoo-test-amd64-openrc-ext4`
- guest install disk: `/dev/vda`

The VM is disposable. The workflow may wipe the VM qcow2 after the normal explicit confirmations, but it must never operate on host block devices.

## Goals / Non-Goals

**Goals:**

- Document the exact resumable libvirt validation workflow.
- Validate that the planner is run before each resumed phase.
- Validate that each `make install-resume` invocation executes only one phase.
- Confirm destructive resume phases still require the same confirmations as fresh targets.
- Confirm evidence is written under ignored state/log paths.
- Fix any shared implementation bug found during validation.

**Non-goals:**

- Do not add new installer features.
- Do not expand the validation matrix beyond `openrc/ext4/standard`.
- Do not replace full `vm-e2e-install` validation.
- Do not weaken destructive confirmations because the VM is disposable.
- Do not add OpenRC-only fixes for shared behavior.
- Do not touch real host block devices.

## Validation Workflow

The runbook SHALL use the Makefile as the operator-facing control plane. The expected high-level sequence is:

1. Prepare a disposable libvirt VM for `PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard`.
2. Boot the official Gentoo live ISO.
3. Bootstrap SSH in the live ISO.
4. Confirm Ansible connectivity.
5. Run `make install-resume-plan`.
6. Run `make install-resume` for exactly one planner-approved phase.
7. Repeat planning and one-phase execution until final checks or until a documented blocker is reached.
8. Preserve logs and state evidence.
9. Shut down or pause the VM after validation.

The validation MUST pass the same variables that the normal installer requires. For destructive VM phases, the workflow uses:

```text
INSTALL_DISK=/dev/vda
I_UNDERSTAND_THIS_WIPES_DISK=yes
I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

`/dev/vda` is valid only inside the guest VM and only for this disposable validation target.

## Evidence Requirements

The validation report or runbook notes SHALL record:

- VM case identity and libvirt domain name.
- Selected `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, and `INSTALL_DISK`.
- State pointer path.
- Run id when available.
- Every `install-resume-plan` invocation.
- Every executed phase.
- Required confirmations for destructive or high-risk phases.
- Evidence directories under `logs/install-runs/`.
- Any failure, fix, or intentionally deferred phase.

The report MUST NOT include private keys, API tokens, password hashes, or local credentials.

## Safety

This validation remains inside the libvirt safety boundary:

- VM storage is a project-local qcow2 under `var/libvirt/`.
- The guest install disk is `/dev/vda`; host `/dev/*` paths are never VM disk inputs.
- VM cleanup requires the existing cleanup confirmation.
- Destructive installer phases require the same confirmations as non-resumable install targets.
- The planner must run before each resumed phase.
- Resume state is evidence, not authority.

## Documentation

Add a practical runbook under `docs/` and link it from the existing resume or libvirt documentation. The runbook should be operational: commands, variables, expected outputs, logs, failure modes, and recovery.

Do not over-expand `README.md`. If a README update is needed, add only a short pointer to the detailed document.

## Review Checklist

- The change validates only `openrc/ext4/standard`.
- The workflow uses `make` targets, not undocumented command chains.
- The planner is rerun before each phase.
- `install-resume` stops after one phase.
- Destructive phases preserve confirmations.
- Evidence is stored under ignored paths.
- Any bug fix is shared, not OpenRC-specific.
- Documentation describes both success and failure handling.
