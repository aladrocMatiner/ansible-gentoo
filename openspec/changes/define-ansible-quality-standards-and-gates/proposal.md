## Why

The project is moving from read-only Ansible planning toward reusable installer roles that will eventually mutate disks and installed systems. Before those roles grow, the project needs explicit Ansible quality standards so shared OpenRC/systemd automation remains idempotent, reviewable, lintable, and safe to publish.

## What Changes

- Define project-wide Ansible quality rules based on official Ansible and ansible-lint practices.
- Require fully qualified module names, named tasks, explicit state, and module-first implementation.
- Require `changed_when`, `failed_when`, `creates`, `removes`, or equivalent guards for command-like tasks.
- Require check-mode and diff-mode expectations for plan, template, and apply workflows.
- Require Ansible lint/syntax quality gates through Makefile targets where practical.
- Require Ansible variable, inventory, role, handler, template, tag, logging, and secret-handling policies.
- Scope temporary live ISO SSH host-key exceptions to the VM/live ISO wrappers instead of disabling host-key checking globally.
- Update agent, skill, docs, and OpenSpec planning rules so future Ansible changes include quality-gate tasks.

## Capabilities

### New Capabilities
- `ansible-quality-standards`: Defines Ansible authoring, linting, idempotency, check-mode, secret, and Makefile quality-gate requirements for future installer automation.

### Modified Capabilities
- `ansible-architecture`: Adds quality standards, lint gates, host-key scope, and idempotency review requirements to the existing reuse-first Ansible architecture.
- `define-project-completion-roadmap`: Adds Ansible quality standards as an early cross-cutting guardrail before broad role implementation.

## Impact

- `AGENTS.md`
- `agents/ansible-installer-agent.md`
- `agents/safety-review-agent.md`
- `agents/openspec-agent.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `docs/ansible-architecture.md`
- `docs/project-completion-roadmap.md`
- `ansible.cfg`
- `.ansible-lint`
- `scripts/ansible-check.sh`
- OpenSpec changes that define Ansible architecture and roadmap expectations.
