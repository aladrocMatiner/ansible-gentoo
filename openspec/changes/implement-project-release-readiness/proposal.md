# Change: implement-project-release-readiness

## Summary
Define and implement project release readiness for the first usable Gentoo AI installer milestone.

## Motivation
After the installer works end-to-end in libvirt, the project needs clear release docs, archived completed changes, and operator runbooks before broader use.

## Scope
- Add release checklist.
- Update README quickstart.
- Archive completed OpenSpec changes.
- Verify docs do not overstate planned behavior.
- Verify no secrets or large artifacts are tracked.
- Verify audit bundle, secret input policy, Handbook traceability, and libvirt matrix status are documented.
- Verify real hardware readiness, cleanup/reset, install report, supported host requirements, and manual escape-hatch documentation.

## Non-goals
- Do not add installer features.
- Do not publish artifacts automatically.

## Safety Requirements
- Release docs must warn about destructive disk operations.
- Real hardware instructions must require explicit disk confirmation.
- Secrets and ISO/qcow2 artifacts must not be committed.
- Release checks must include secret-safety and ignored-artifact verification.

## Acceptance Criteria
- README points to concise runnable workflow.
- Detailed docs cover VM and live ISO flows.
- Release checklist reports audit bundle, Handbook traceability, matrix validation, and first-boot validation status.
- Release checklist reports real hardware readiness, cleanup/reset policy, install report, supported host requirements, and manual escape-hatch status.
- Completed changes are archived or intentionally left active.
- `openspec validate implement-project-release-readiness --strict` passes.

## Affected Files
- `README.md`
- `docs/`
- `openspec/changes/`
- `.gitignore`
