# OpenSpec Workflow Skill

## 1. Purpose
This skill describes the OpenSpec workflow for the `gentoo-ai-installer` project.

OpenSpec controls project changes. Codex should not implement large changes without an OpenSpec proposal. The Makefile exposes OpenSpec commands. The project has two phases:

1. Official Gentoo live ISO plus temporary Codex.
2. Ansible-based Gentoo installer.

This skill defines the workflow. It does not implement OpenSpec changes.

## 2. When to Use This Skill
Use this skill:

- Before large or cross-cutting implementation.
- Before adding destructive functionality.
- Before adding or changing Makefile target behavior.
- Before adding scripts, Ansible playbooks, or Ansible roles.
- Before changing agent or skill rules.
- Before expanding v1 scope.
- When validating, reviewing, or archiving an OpenSpec change.

Small documentation-only edits may not require a full change if the operator explicitly requests the edit, but major behavior should be controlled by OpenSpec.

## 3. Required Context
- Project phase: phase 1 live ISO/Codex or phase 2 Ansible.
- Requested outcome.
- Existing OpenSpec config and changes.
- Affected files and directories.
- Makefile target implications.
- Safety risk level.
- v1 assumptions: amd64, OpenRC, UEFI, ext4, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS, no Btrfs.
- Whether the change is documentation-only or executable behavior.

## 4. Change Creation Workflow
1. Determine whether the request needs an OpenSpec change.
2. Choose one clear change purpose.
3. Pick a kebab-case change name.
4. Draft proposal with scope, non-goals, affected files, acceptance criteria, and safety notes.
5. Add design file when the change is risky or cross-cutting.
6. Add concrete, checkable tasks.
7. Add spec deltas for changed behavior.
8. Validate changes with `openspec validate --changes --strict`, preferably through `make openspec-validate`.
9. Review with safety-review-agent when destructive or high-risk behavior is involved.
10. Implement only after the operator approves or explicitly asks to proceed.
11. Mark tasks complete only when evidence exists.
12. Archive only after implementation and validation are complete.

Initial changes to recommend:

- `bootstrap-codex-on-live-iso`
- `define-agent-and-skill-rules`
- `define-makefile-control-plane`
- `document-manual-gentoo-install-flow`
- `scaffold-ansible-installer`
- `implement-safe-disk-detection`
- `implement-stage3-install`

## 5. Proposal Rules
Proposals must:

- Have one clear purpose.
- State project phase.
- State non-goals.
- Identify affected files.
- Define acceptance criteria.
- Identify Makefile targets.
- Include a safety section for destructive or high-risk behavior.
- State whether the change is documentation-only.
- Split large changes instead of bundling unrelated work.

Proposals for destructive functionality must describe required confirmations and safety review.

## 6. Design Rules
Design files are required for risky or cross-cutting changes.

Create a design file when a change involves:

- Disk partitioning, formatting, mounting, or deletion.
- Stage3 extraction into a target root.
- Chroot commands that mutate the target.
- Bootloader, EFI, user, password, or service changes.
- Makefile control-plane conventions.
- Ansible inventory, variables, roles, playbooks, dry-run, or idempotency.
- Secret handling.

Designs must explain:

- Why the approach fits the project phase.
- How the Makefile remains the operator-facing control plane.
- How safety gates work.
- How failures are detected.
- How logs or evidence are collected.
- How the system fails closed when uncertain.

## 7. Task Rules
Tasks must be concrete and checkable.

Task lists must:

- Use small implementation steps.
- Include affected files where practical.
- Include validation steps.
- Include safety review steps for high-risk or destructive behavior.
- Include documentation updates.
- Include final verification.
- Avoid vague tasks such as `build installer` or `make it work`.

Tasks must not be marked complete until implementation evidence and validation results exist.

## 8. Spec Delta Rules
Spec deltas must:

- Define observable behavior.
- Include acceptance scenarios.
- Preserve v1 assumptions unless explicitly changed.
- Identify operator-facing Makefile targets.
- Treat raw commands as implementation details behind targets.
- Include safety requirements for destructive behavior.
- Distinguish documentation-only scaffold work from runnable automation.

Spec deltas must be small enough to review.

## 9. Validation Rules
Every change must validate with:

```text
openspec validate --changes --strict
```

Prefer the Makefile target:

```text
make openspec-validate
```

Validation rules:

- Strict validation must pass before implementation proceeds.
- Strict validation must pass again after implementation.
- Failed validation blocks task completion.
- Validation output should be recorded as evidence.
- Safety review findings must be resolved or explicitly accepted by the operator before risky work proceeds.

## 10. Makefile Targets
Expected OpenSpec make targets:

- `make openspec-list`
- `make openspec-validate`
- `make openspec-show CHANGE=...`
- `make openspec-new CHANGE=...`
- `make openspec-archive CHANGE=...`

Target expectations:

- `make openspec-list`: list active and available changes.
- `make openspec-validate`: run strict OpenSpec validation.
- `make openspec-show CHANGE=...`: show one change and its artifacts.
- `make openspec-new CHANGE=...`: create a new change scaffold.
- `make openspec-archive CHANGE=...`: archive a completed validated change.

Operators should use Makefile targets rather than remembering raw OpenSpec commands.

## 11. Review Process
Before implementation, review:

- One clear purpose.
- Large changes split.
- Proposal includes non-goals.
- Acceptance criteria present.
- Affected files identified.
- Design file exists when required.
- Tasks are concrete and checkable.
- Spec deltas include Makefile targets.
- Destructive functionality has a safety section.
- Strict validation passes.

Safety-review-agent review is mandatory for destructive functionality and recommended for high-risk persistent changes.

## 12. Failure Modes
- Codex starts a large implementation without an OpenSpec proposal.
- One change tries to cover multiple unrelated outcomes.
- Proposal lacks non-goals.
- Acceptance criteria are missing.
- Affected files are not identified.
- Risky change lacks a design file.
- Destructive functionality lacks a safety section.
- Tasks are vague or not checkable.
- Spec deltas describe raw commands instead of Makefile targets.
- `openspec validate --changes --strict` fails.
- Tasks are marked complete without evidence.

## 13. Recovery Advice
- Stop implementation and create an OpenSpec change.
- Split broad changes into smaller focused changes.
- Add non-goals and acceptance criteria to proposals.
- Add a design file for risky or cross-cutting work.
- Convert raw command descriptions into Makefile target behavior.
- Add safety sections for destructive behavior.
- Rewrite vague tasks into concrete checklist items.
- Re-run `make openspec-validate` after fixes.
- Keep tasks incomplete until validation and implementation evidence exist.

## 14. Output Artifacts
This skill should produce or request:

- Change name.
- Proposal.
- Design file when required.
- Task list.
- Spec deltas.
- Affected files list.
- Acceptance criteria.
- Safety section.
- OpenSpec validation output.
- Review notes.
- Archive status when complete.
