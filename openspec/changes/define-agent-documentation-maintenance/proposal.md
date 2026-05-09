# define-agent-documentation-maintenance

## Summary
Define a project-wide documentation maintenance rule for `gentoo-ai-installer`: agents must create, update, and correct documentation whenever they modify project behavior, scripts, Makefile targets, OpenSpec changes, Ansible playbooks, skills, or agent instructions.

## Motivation
The project relies on `agents/`, `skills/`, OpenSpec changes, docs, and Makefile targets to guide Codex and human operators through high-risk Gentoo installation workflows. If implementation changes without matching documentation, agents and operators can follow stale instructions that are unsafe, incomplete, or misleading.

## Problem Statement
The repository has several documentation surfaces:

- Root agent guidance.
- `agents/` behavior documents.
- `skills/` reusable procedures.
- `docs/` user and workflow documentation.
- OpenSpec proposals, designs, tasks, and spec deltas.
- Makefile target help and behavior.

Without a project-wide rule, changes to scripts, Makefile targets, Ansible workflows, QEMU workflows, safety confirmations, or installation procedures can leave these surfaces inconsistent.

## Scope
- Define mandatory documentation maintenance rules for all agents.
- Define when documentation updates are required.
- Define the documentation targets agents must consider.
- Define a documentation review checklist.
- Require OpenSpec tasks for documentation work when implementation changes behavior.
- Require root `AGENTS.md` or `agents.md` to contain documentation maintenance rules.
- Cover Makefile, scripts, QEMU, Ansible, OpenSpec, skills, agents, safety, and installation workflows.

## Non-goals
- Do not implement unrelated installer behavior.
- Do not modify the QEMU implementation except future documentation references.
- Do not modify Ansible installer logic.
- Do not generate excessive documentation.
- Do not duplicate the same documentation in many files.
- Do not add real secrets, API keys, private SSH keys, tokens, or local credentials to documentation.

## Safety Considerations
- Stale safety documentation can cause data loss, especially around disk partitioning, formatting, bootloader installation, chroot operations, QEMU disk handling, and cleanup targets.
- Safety-impacting changes must update safety documentation in the same change.
- Documentation must not include secrets, tokens, private keys, or real local credentials.
- Documentation must clearly distinguish host disks from VM disk images.
- Documentation must preserve the Makefile as the operator-facing control plane.

## Acceptance Criteria
- A root `AGENTS.md` or `agents.md` file exists.
- The root agents file contains documentation maintenance rules.
- Agents are instructed to update documentation whenever behavior changes.
- A documentation checklist exists.
- Makefile target changes require `README.md` or `docs/` updates.
- Script changes require `docs/` or skill updates.
- Ansible changes require Ansible documentation updates.
- QEMU changes require QEMU documentation updates.
- Codex bootstrap changes require Codex bootstrap documentation updates.
- Safety changes require safety documentation updates.
- OpenSpec tasks must include documentation tasks for implementation changes.
- `openspec validate define-agent-documentation-maintenance --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files
- `AGENTS.md` or `agents.md`
- `README.md`
- `docs/`
- `skills/`
- `agents/`
- `openspec/changes/*/tasks.md`
- `openspec/changes/define-agent-documentation-maintenance/proposal.md`
- `openspec/changes/define-agent-documentation-maintenance/design.md`
- `openspec/changes/define-agent-documentation-maintenance/tasks.md`
- `openspec/changes/define-agent-documentation-maintenance/specs/agent-documentation/spec.md`
