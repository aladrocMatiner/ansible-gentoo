## 1. Phase Contract Definition

- [x] 1.1 Define the canonical phase ids for the shared basic console install flow.
- [x] 1.2 Implement the phase contract table metadata for each phase: preconditions, risk level, variables, confirmations, evidence, validation, skip criteria, re-run criteria, and recovery advice.
- [x] 1.3 Confirm phase names map to the existing shared OpenRC/systemd orchestration and Gentoo Handbook traceability docs.

## 2. Resume Planner

- [x] 2.1 Implement or complete the read-only `install-resume-plan` workflow.
- [x] 2.2 Compare recorded checkpoint state against current live ISO facts.
- [x] 2.3 Report completed phases, mismatches, next safe phase, and required confirmations.
- [x] 2.4 Fail closed when required facts or evidence are missing.

## 3. Resume Execution

- [x] 3.1 Add `make install-resume` or complete the existing target if already present.
- [x] 3.2 Ensure resume execution requires a compatible resume plan or equivalent validation before mutation.
- [x] 3.3 Ensure destructive phases preserve `INSTALL_DISK`, `I_UNDERSTAND_THIS_WIPES_DISK=yes`, bootloader confirmation, and other required safety gates.
- [x] 3.4 Ensure resume execution does not repeat destructive phases unless explicitly requested with confirmations.
- [x] 3.5 Ensure `make install-resume` executes only the next safe phase by default, stops after recording evidence, and tells the operator to rerun `make install-resume-plan`.

## 4. Shared Role Integration

- [x] 4.1 Update `common/install_state` to support phase contracts and resume decisions.
- [x] 4.2 Add skip/re-run validation to shared roles without duplicating OpenRC and systemd logic.
- [x] 4.3 Keep init-specific resume checks limited to profile, stage3 variant, service manager, and service enablement facts.
- [x] 4.4 Review long-running phases and add bounded retries or async/poll where practical.

## 5. Manual Intervention Integration

- [x] 5.1 Ensure recorded manual steps are included in resume planning output.
- [x] 5.2 Require relevant read-only validation after manual intervention before mutating phases.
- [x] 5.3 Confirm manual steps never bypass destructive confirmations.

## 6. Documentation

- [x] 6.1 Update `docs/install-state-and-resume-checkpoints.md` with the phase contract and resume plan output.
- [x] 6.2 Update `docs/manual-escape-hatch-policy.md` with resume-after-manual-step behavior.
- [x] 6.3 Update `docs/ansible-basic-console-install-orchestration.md` with resume targets and limits.
- [x] 6.4 Update `docs/install-audit-bundle.md` with resume evidence expectations.
- [x] 6.5 Update quickstarts where retry or resume behavior is described.
- [x] 6.6 Update `skills/ansible-gentoo-installer.md` and relevant agent files.

## 7. Validation

- [x] 7.1 Run `make ansible-check`.
- [x] 7.2 Run `make secret-check`.
- [x] 7.3 Run `make release-check`.
- [x] 7.4 Run targeted libvirt resume smoke tests where practical.
- [x] 7.5 Run `openspec validate implement-resumable-install-phases --strict`.
- [x] 7.6 Run `openspec validate --all --strict`.
