# Tasks: define-agent-documentation-maintenance

## 1. Change Artifacts
- [x] Create `proposal.md`.
- [x] Create `design.md`.
- [x] Create `tasks.md`.
- [x] Create `specs/agent-documentation/spec.md`.

## 2. Root Agent Instructions
- [x] Create `AGENTS.md` or `agents.md`.
- [x] Add the project-wide documentation maintenance rule.
- [x] Add guidance to update documentation whenever operator behavior changes.
- [x] Add safety and secret documentation rules.

## 3. User-facing Documentation
- [x] Create or update `README.md` with concise project overview and documentation pointers.
- [x] Add or update a documentation checklist under `docs/`.
- [x] Ensure Makefile target changes require `README.md` or `docs/` updates.

## 4. Agent and Skill Documentation
- [x] Update `agents/` guidance to require documentation updates for behavior changes.
- [x] Update `skills/` guidance to require documentation updates for reusable procedure changes.
- [x] Ensure safety-impacting changes require safety documentation updates.
- [x] Ensure QEMU changes require QEMU documentation updates.
- [x] Ensure Ansible changes require Ansible documentation updates.
- [x] Ensure Codex bootstrap changes require Codex bootstrap documentation updates.

## 5. OpenSpec Workflow
- [x] Update OpenSpec workflow guidance so implementation changes include documentation tasks.
- [x] Ensure future `openspec/changes/*/tasks.md` files track documentation updates.

## 6. Validation
- [x] Run `openspec validate define-agent-documentation-maintenance --strict`.
- [x] Run `openspec validate --all --strict`.
