## 1. OpenSpec Artifacts

- [x] 1.1 Create the proposal, design, tasks, and spec deltas for resumable libvirt validation.
- [x] 1.2 Validate the change with `openspec validate validate-resumable-libvirt-openrc-ext4 --strict`.
- [x] 1.3 Validate all active specs with `openspec validate --all --strict`.

## 2. Documentation

- [x] 2.1 Add a detailed runbook for the `openrc/ext4/standard` resumable libvirt validation case.
- [x] 2.2 Link the runbook from the relevant resume or libvirt documentation.
- [x] 2.3 Document required variables, confirmations, evidence paths, failure modes, and recovery.

## 3. VM Preparation

- [x] 3.1 Prepare or reset the disposable `gentoo-test-amd64-openrc-ext4` VM through Makefile targets.
- [x] 3.2 Boot the VM from the official Gentoo live ISO.
- [x] 3.3 Bootstrap SSH and verify Ansible connectivity through Makefile targets.

## 4. Resumable Phase Validation

- [x] 4.1 Run `make install-resume-plan` before the first resumed phase.
- [x] 4.2 Execute one planner-approved phase with `make install-resume`.
- [x] 4.3 Repeat planning and one-phase execution through the supported `openrc/ext4/standard` flow, or document the first blocker with logs.
- [x] 4.4 Confirm destructive or high-risk phases still require their normal Makefile confirmations.
- [x] 4.5 Confirm state and logs identify completed phases, run id, and next action.

## 5. Fixes Found During Validation

- [x] 5.1 Fix any implementation issue found during validation in shared roles, scripts, or Makefile targets.
- [x] 5.2 Update relevant docs, skills, or OpenSpec tasks when behavior changes.
- [x] 5.3 Re-run targeted validation after any fix.

## 6. Completion Review

- [x] 6.1 Record validation results and remaining issues.
- [x] 6.2 Shut down or pause the validation VM when the run is complete.
- [x] 6.3 Run `make ansible-check`.
- [x] 6.4 Run `make secret-check`.
- [x] 6.5 Run `openspec validate validate-resumable-libvirt-openrc-ext4 --strict`.
- [x] 6.6 Run `openspec validate --all --strict`.
