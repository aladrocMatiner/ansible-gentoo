# Agent Instructions

## 1. Project Overview
Project name: `gentoo-ai-installer`.

v1 uses the official Gentoo live ISO and installs Codex temporarily in the live environment. The Makefile is the operator-facing control plane. OpenSpec controls project changes. Ansible is used for reproducible installation in phase 2. QEMU is used to test manual installation flows safely before real hardware. QEMU tests must avoid touching host disks.

## 2. Control Plane Rule
All operator-facing workflows must be exposed through Makefile targets.

Agents must not instruct users to run long undocumented commands directly when a Makefile target exists or should exist. If a new operator action is introduced, update the Makefile and documentation in the same change.

## 3. Documentation Maintenance Rule
Any change that modifies behavior must update documentation in the same change.

Agents must check documentation before finishing, correct stale documentation they notice, and avoid TODO-only documentation when behavior is implemented. If documentation is intentionally deferred, state why and leave a tracked OpenSpec task.

## 4. Required Documentation Updates by Change Type
- Makefile target added, changed, or removed: update `README.md` or `docs/`, and update `skills/makefile-control-plane.md` if the behavior is reusable.
- Script added or changed: update `docs/` or relevant `skills/`; document arguments, environment variables, safety checks, examples, and failure modes.
- Ansible playbook or role added or changed: update Ansible documentation; document variables, required inventory, safety gates, and execution target.
- QEMU workflow changed: update QEMU docs; document ISO path, disk path, SSH forwarding, ports, cleanup behavior, and whether behavior is implemented or planned.
- Codex bootstrap changed: update Codex bootstrap docs; document install method, token handling, validation, and cleanup.
- Safety rule changed: update safety docs and relevant agent or skill files.
- OpenSpec workflow changed: update OpenSpec workflow docs.
- Agent or skill changed: update this file if project-wide behavior changes.

## 5. Documentation Checklist
Before finishing any task, verify:

- Are new commands documented?
- Are new Makefile targets documented?
- Are changed variables documented?
- Are default values documented?
- Are required confirmations documented?
- Are safety risks documented?
- Are failure modes documented?
- Are recovery steps documented?
- Are examples still correct?
- Are old instructions now stale?
- Does `README.md` still match the actual workflow?
- Do relevant skills still match implementation?
- Do relevant OpenSpec tasks mention documentation work?

## 6. Safety Documentation Rule
Any destructive or safety-sensitive operation must document:

- What it can change.
- What confirmation is required.
- What variables are required.
- What paths it may touch.
- What paths it must never touch.
- How to verify before running.
- How to recover or stop safely.

## 7. OpenSpec Documentation Rule
Implementation changes must include documentation tasks in `tasks.md`.

A change is not complete if documentation tasks are missing or unchecked. If implementation changes operator behavior, the OpenSpec task list must include documentation updates.

## 8. Makefile Documentation Rule
Every operator-facing make target must have a help entry. Every dangerous make target must document required variables. Destructive targets must document confirmation variables. Makefile variables must have documented defaults or explicitly state that no default is allowed.

## 9. Script Documentation Rule
Scripts must document usage in `docs/` or relevant `skills/`. Scripts must print clear errors. Scripts must not require reading source code to understand basic usage.

## 10. Ansible Documentation Rule
Playbooks and roles must document required variables. Dangerous playbooks must document safety gates. Local-vs-remote execution must be explicit.

## 11. Ansible reuse-first architecture
Future Ansible implementation must reuse shared roles, tasks, variables, handlers, templates, validation logic, safety gates, and documentation across OpenRC and systemd console installation flows whenever behavior is common.

- Reuse shared Ansible roles and tasks whenever behavior is common.
- Do not duplicate OpenRC and systemd logic unless the behavior genuinely differs.
- Shared safety gates must be implemented once and reused by both init flows.
- Init-specific behavior must be isolated under explicit OpenRC or systemd roles, task files, handlers, templates, variables, or validation tasks.
- New Ansible tasks must first be evaluated for reuse in the common flow before adding init-specific logic.
- If duplication is introduced, the agent must justify it in the OpenSpec change notes or implementation summary.
- Makefile targets should call shared Ansible flows where practical and pass `PROFILE=openrc` or `PROFILE=systemd` into the shared flow.
- Documentation must describe shared behavior once and call out init-specific behavior clearly.

## 12. QEMU Documentation Rule
QEMU docs must explain:

- `./gentoo.iso`.
- `./var/qemu/`.
- qcow2 disk safety.
- SSH forwarding and ports when implemented.
- `make qemu-boot`.
- `make qemu-ssh` when implemented.
- `make qemu-rsync` when implemented.
- `make qemu-clean`.
- That `/dev/vda` is the expected guest virtual disk inside the VM.

Planned QEMU behavior must be clearly labeled as planned and not documented as available.

## 13. Codex Bootstrap Documentation Rule
Codex bootstrap docs must explain:

- Install method.
- Temporary live ISO nature.
- Authentication and token safety.
- Cleanup behavior.
- Validation commands.

## 14. What Not to Document
Do not document real secrets, real API keys, private SSH keys, real tokens, local credentials, or passwords. Do not document local-only personal paths unless they are examples. Do not duplicate large blocks of the same content across many files. Do not document behavior that does not exist yet as if it already exists. Clearly label planned behavior as planned.

## 15. Review Requirements Before Finishing a Task
At the end of each implementation task, report:

- Documentation files updated.
- Documentation files checked but not changed.
- Any stale documentation fixed.
- Any documentation intentionally deferred and why.
