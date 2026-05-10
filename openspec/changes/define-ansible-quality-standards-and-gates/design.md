## Context

The project already has a reuse-first Ansible architecture and several read-only Ansible planning workflows. The next work will introduce broader roles and eventually destructive apply tasks, so the project needs quality gates before those roles become hard to review.

Research baseline:

- Official Ansible documentation recommends roles and reusable artifacts for maintainability, with roles grouping tasks, handlers, variables, files, and templates in a known structure.
- Ansible check mode and diff mode are the standard validation mechanisms for previewing changes where modules support them.
- Ansible supports task-specific `failed_when` and `changed_when` conditions for precise failure and change reporting.
- Ansible variable precedence can make command-line extra vars override other variable sources, so Makefile-to-Ansible variable mapping must be explicit and documented.
- Ansible Vault protects secret data at rest, but authors must still prevent secret disclosure at runtime with mechanisms such as `no_log`.
- `ansible-lint` is the community linting tool for proven practices such as FQCN use, avoiding command/shell where a module fits, and requiring explicit change reporting for command-like tasks.

Current repo observations:

- Implemented Ansible playbooks already use common roles and fully qualified `ansible.builtin.*` modules.
- Read-only command tasks mostly set `changed_when: false`, which matches the current planning-only behavior.
- `ansible.cfg` disables host key checking globally. That is too broad for a publishable project; temporary live ISO SSH exceptions should be scoped to VM/live ISO wrappers.
- `make ansible-check` syntax-checks implemented playbooks but does not invoke `ansible-lint`.

## Goals / Non-Goals

**Goals:**

- Define Ansible authoring standards for future roles, tasks, handlers, templates, variables, inventories, and playbooks.
- Add a project `ansible-lint` configuration that can grow stricter over time.
- Make `make ansible-check` run syntax checks and run `ansible-lint` when available.
- Keep live ISO SSH host-key exceptions explicit in wrapper scripts instead of global Ansible config.
- Update agents, skills, docs, and existing architecture proposals so future OpenSpec changes include Ansible quality tasks.

**Non-Goals:**

- Do not implement destructive installer roles.
- Do not rewrite the existing read-only planning roles beyond quality-related configuration.
- Do not require `ansible-lint` inside the official Gentoo live ISO before the project has an approved dependency bootstrap change.
- Do not introduce CI yet; release-readiness can later make lint mandatory in CI.

## Decisions

### Decision: Use a module-first Ansible policy

Ansible tasks must prefer purpose-built modules over `command`, `shell`, or `raw`. Command-like tasks are allowed for read-only inspection or Gentoo-specific operations that lack a reliable module, but they must include explicit change and failure reporting.

Rationale: module tasks usually provide better idempotency, check-mode behavior, argument validation, and clearer output. Gentoo installation still needs some command-like checks, such as `lsblk`, `findmnt`, `emerge`, `eselect`, and chroot wrappers, so the policy is not a blanket ban.

### Decision: Require FQCN and named tasks

All modules must use FQCN syntax such as `ansible.builtin.command`, and every task and handler must have a clear `name`.

Rationale: FQCN avoids ambiguous module resolution and makes reviews easier. Named tasks make logs, failed output, and audit bundles useful.

### Decision: Make idempotency explicit

Future tasks that mutate state must use module `state`, `creates`, `removes`, prior facts, guards, handlers, and validation checks where practical. Non-idempotent tasks must be isolated, tagged, documented, and guarded by confirmation.

Rationale: Gentoo installation has inherently one-time operations, but rerunnable behavior is critical for recovery and resume.

### Decision: Treat check mode and diff mode as first-class design inputs

Read-only plan roles must remain mutation-free. Configuration roles should support check mode and diff mode where modules support them. Destructive roles must provide plan/preview output and must not mutate in check mode.

Rationale: this matches the existing Makefile plan/apply split and helps safety review before destructive operations.

### Decision: Scope live ISO host-key relaxation to wrappers

Do not disable host key checking globally in `ansible.cfg`. Controller-to-live-ISO wrappers may set `ANSIBLE_HOST_KEY_CHECKING=False` and SSH options for the temporary official live ISO only, with comments explaining the exception.

Rationale: the official live ISO is ephemeral and its SSH host key is not stable, but global disabling would affect unrelated Ansible workflows and is not acceptable for a shared project.

### Decision: Start lint as a local quality gate, not a live ISO dependency

Add `.ansible-lint` and make `scripts/ansible-check.sh` run `ansible-lint` when it is installed. If it is missing, `ansible-check` should report that lint was skipped. A future release/CI change can make it mandatory.

Rationale: the current live ISO bootstrap does not define `ansible-lint` installation yet. Blocking all checks on a missing optional developer tool would slow safe planning work, but the project should already carry lint configuration and use it when available.

## Risks / Trade-offs

- `ansible-lint` can flag early scaffold code before the project has a final role layout. Mitigation: start with a documented baseline profile and tighten through future OpenSpec changes.
- Optional lint can be missed by contributors. Mitigation: document that release/CI readiness must make lint mandatory.
- Scoped host-key relaxation can still be risky if reused outside the temporary live ISO target. Mitigation: wrappers must print the live ISO target, docs must describe the exception, and unrelated Ansible workflows must not inherit it automatically.
- Some Gentoo workflows need `command` or chroot. Mitigation: require explicit guards, clear `changed_when`/`failed_when`, path assertions, and safety review for target mutation.

## Migration Plan

1. Add the Ansible quality standards OpenSpec change.
2. Add `.ansible-lint` and update `scripts/ansible-check.sh` to invoke it when available.
3. Remove global `host_key_checking = False` from `ansible.cfg`; keep temporary live ISO exceptions in wrappers that already set `ANSIBLE_HOST_KEY_CHECKING=False`.
4. Update agents, skills, and docs with the new Ansible quality rules.
5. Update existing architecture and roadmap proposals so future Ansible changes inherit the quality gate.
6. Validate OpenSpec and existing Ansible syntax.

## Open Questions

- Which future change will make `ansible-lint` mandatory in CI or release readiness?
- Should the live ISO bootstrap eventually install `ansible-lint`, or should lint remain a host/developer-only gate?

## References

- Ansible check mode and diff mode: <https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html>
- Ansible roles and role structure: <https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_reuse_roles.html>
- Ansible error handling, `failed_when`, and `changed_when`: <https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_error_handling.html>
- Ansible variable precedence: <https://docs.ansible.com/projects/ansible/latest/reference_appendices/general_precedence.html>
- Ansible sensitive-data logging guidance: <https://docs.ansible.com/ansible/8/reference_appendices/logging.html>
- Ansible Vault guidance: <https://docs.ansible.com/projects/ansible/latest/vault_guide/vault.html>
- ansible-lint rules: <https://docs.ansible.com/projects/lint/rules/>
- ansible-lint FQCN rule: <https://docs.ansible.com/projects/lint/rules/fqcn/>
- ansible-lint no-changed-when rule: <https://docs.ansible.com/projects/lint/rules/no-changed-when/>
- ansible-lint command-instead-of-shell rule: <https://docs.ansible.com/projects/lint/rules/command-instead-of-shell/>
