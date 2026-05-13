# Agent Instructions

## 1. Project Overview
Project name: `gentoo-ai-installer`.

v1 uses the official Gentoo live ISO and installs Codex temporarily in the live environment. The Makefile is the operator-facing control plane. OpenSpec controls project changes. The primary phase-2 deliverable is a reusable Ansible installer that can run from an operator/controller machine against a network-reachable Gentoo live ISO target over SSH. libvirt/virsh is the local validation harness for testing the same Ansible workflows safely before real hardware. Optional local live ISO Ansible targets are fallback/diagnostic paths run inside the live ISO with `ansible_connection=local`; they must not replace the network SSH workflow. VM tests must avoid touching host disks.

## 2. Control Plane Rule
All operator-facing workflows must be exposed through Makefile targets.

Agents must not instruct users to run long undocumented commands directly when a Makefile target exists or should exist. If a new operator action is introduced, update the Makefile and documentation in the same change.

## 3. Documentation Maintenance Rule
Any change that modifies behavior must update documentation in the same change.

Agents must check documentation before finishing, correct stale documentation they notice, and avoid TODO-only documentation when behavior is implemented. If documentation is intentionally deferred, state why and leave a tracked OpenSpec task.

## 4. Required Documentation Updates by Change Type
- Makefile target added, changed, or removed: update `README.md` or `docs/`, and update `skills/makefile-control-plane.md` if the behavior is reusable.
- Script added or changed: update `docs/` or relevant `skills/`; document arguments, environment variables, safety checks, examples, and failure modes.
- Ansible playbook or role added or changed: update Ansible documentation; document variables, required inventory, safety gates, controller-to-target SSH assumptions, and execution target.
- VM/libvirt workflow changed: update VM docs; document ISO path, disk path, optional `VM_TEST_IMAGE_NAME` local test labels, libvirt URI, network mode, serial console behavior, SSH bootstrap, cleanup behavior, and whether behavior is implemented or planned.
- Manual intervention or resume behavior changed: update `docs/manual-escape-hatch-policy.md`, `docs/install-state-and-resume-checkpoints.md`, `docs/install-audit-bundle.md`, and relevant agent or skill files.
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
Playbooks and roles must document required variables. Dangerous playbooks must document safety gates. Controller-vs-target execution must be explicit.

The reusable network Ansible installer is the product. VM/libvirt scripts, SSH bootstrap helpers, and local artifact directories are test harness pieces used to validate the installer. Shared Ansible roles and Makefile targets must not depend on a libvirt domain name, VM-only IP discovery, `./var/libvirt/`, or `/dev/vda` except in VM-specific tests and examples.

Controller-to-live-ISO Ansible wrappers must use the shared SSH transport policy exposed through Makefile variables such as `ANSIBLE_SSH_CONNECT_TIMEOUT`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX`, `ANSIBLE_SSH_CONTROL_MASTER`, `ANSIBLE_SSH_CONTROL_PERSIST`, and `ANSIBLE_SSH_CONTROL_PATH_DIR`. Do not duplicate raw `--ssh-common-args` strings in wrapper scripts. Keep temporary live ISO host-key relaxation scoped to wrapper invocations; do not disable host-key checking globally.

Future Ansible installer behavior must use the official Gentoo AMD64 Handbook as the baseline installation procedure: <https://wiki.gentoo.org/wiki/Handbook:AMD64>. Agents may adapt Handbook steps into reusable Ansible roles, but must preserve the project safety model, Makefile control-plane rule, OpenSpec review flow, and v1 assumptions.

Manual intervention is a recovery path, not a safety bypass. If an operator changes installation state outside automation, agents must route the record through `make record-manual-step`, keep the note non-secret, require `make install-resume-plan` or the relevant read-only checks before resuming, and preserve destructive confirmations for later targets.

Real hardware workflows are higher risk than libvirt validation. Before agents suggest destructive physical-machine targets, they must direct the operator through `make real-hardware-check`, prefer stable disk paths such as `/dev/disk/by-id/...`, and state that readiness output never replaces destructive or bootloader confirmations.

Libvirt matrix workflows are local validation harnesses. Agents must keep `vm-test-matrix-plan` read-only. Full matrix execution is implemented only through `make vm-e2e-matrix`, which may run destructive install steps inside project-owned disposable qcow2 disks and must keep the normal destructive confirmations.

Libvirt end-to-end install validation may run the full installer only inside the project-owned disposable VM workflow. Agents must require explicit `INSTALL_DISK=/dev/vda`, `ADMIN_USER`, `ENABLE_SSH=yes`, `I_UNDERSTAND_THIS_WIPES_DISK=yes`, and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`, and must keep host block devices forbidden.

Before release-oriented work is considered complete, agents should run or prepare `make release-check`. The check is local and non-destructive; it reports documentation coverage, tracked artifact hygiene, secret checks, Ansible checks, and OpenSpec validation.

## 11. Ansible reuse-first architecture
Future Ansible implementation must reuse shared roles, tasks, variables, handlers, templates, validation logic, safety gates, and documentation across OpenRC and systemd console installation flows whenever behavior is common.

- Reuse shared Ansible roles and tasks whenever behavior is common.
- Do not duplicate OpenRC and systemd logic unless the behavior genuinely differs.
- Shared safety gates must be implemented once and reused by both init flows.
- Init-specific behavior must be isolated under explicit OpenRC or systemd roles, task files, handlers, templates, variables, or validation tasks.
- New Ansible tasks must first be evaluated for reuse in the common flow before adding init-specific logic.
- Shared Ansible roles should map back to the relevant official Gentoo AMD64 Handbook phase where practical, with deviations documented in the OpenSpec change or implementation summary.
- If duplication is introduced, the agent must justify it in the OpenSpec change notes or implementation summary.
- Makefile targets should call shared Ansible flows where practical and pass `PROFILE=openrc|systemd`, `FILESYSTEM=ext4|btrfs`, and `STAGE3_FLAVOR=standard|hardened|musl` into the shared flow.
- Makefile targets should support explicit network live ISO targets through documented variables such as `ANSIBLE_LIVE_HOST`, while keeping libvirt discovery as a local testing convenience.
- Documentation must describe shared behavior once and call out init-specific behavior clearly.

## 12. Ansible quality standards
Before adding or changing Ansible playbooks, roles, tasks, handlers, templates, variables, or inventories, agents must apply the project Ansible quality standards.

- Use fully qualified module names such as `ansible.builtin.command`.
- Give every task and handler a clear `name`.
- Prefer purpose-built modules over `command`, `shell`, `raw`, or chroot wrappers.
- When command-like tasks are necessary, use `argv` where possible and define `changed_when`, `failed_when`, `creates`, `removes`, or equivalent guards.
- Read-only inspection tasks must report `changed: false`.
- Mutating tasks must be idempotent where practical, or isolated, tagged, documented, and guarded by confirmation.
- Planning and dry-run workflows must remain mutation-free and should support Ansible check mode where practical.
- File/template tasks should support diff mode unless the output can reveal secrets; secret-sensitive tasks must use `no_log` or equivalent redaction.
- `make ansible-check` is the operator-facing quality target for implemented Ansible content. It must syntax-check implemented playbooks and run `ansible-lint` when available.
- Global Ansible config must not disable host key checking. Temporary official live ISO SSH wrappers may disable host key checking only for that wrapper invocation because live ISO host keys are ephemeral.
- Any unavoidable duplication, command-like mutation, check-mode limitation, or lint exception must be explained in the implementation summary or OpenSpec change notes.

## 13. VM/libvirt Documentation Rule
VM docs must explain:

- `./gentoo.iso`.
- `./var/libvirt/`.
- Case-specific VM naming from fixed platform `amd64`, `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, and optional `VM_TEST_IMAGE_NAME`.
- qcow2 disk safety.
- Optional `VM_TEST_IMAGE_NAME` labels when manual test image or test-line names affect generated VM artifacts.
- libvirt URI and network mode.
- managed-network IP discovery or SSH forwarding behavior.
- `make vm-bootstrap-ssh`.
- `make vm-ansible-ping`.
- `make vm-start`.
- `make vm-console`.
- `make vm-viewer`.
- `make vm-ssh`.
- `make vm-rsync`.
- `make vm-clean`.
- That `/dev/vda` is the expected guest virtual disk inside the VM.

Compatibility `qemu-*` targets may exist only as aliases to the libvirt workflow. Planned VM behavior must be clearly labeled as planned and not documented as available.

## 14. Codex Bootstrap Documentation Rule
Codex bootstrap docs must explain:

- Install method.
- Temporary live ISO nature.
- Authentication and token safety.
- Cleanup behavior.
- Validation commands.

## 15. What Not to Document
Do not document real secrets, real API keys, private SSH keys, real tokens, local credentials, or passwords. Do not document local-only personal paths unless they are examples. Do not duplicate large blocks of the same content across many files. Do not document behavior that does not exist yet as if it already exists. Clearly label planned behavior as planned.

## 16. Review Requirements Before Finishing a Task
At the end of each implementation task, report:

- Documentation files updated.
- Documentation files checked but not changed.
- Any stale documentation fixed.
- Any documentation intentionally deferred and why.
