# Design: Agent Documentation Maintenance

## 1. Documentation Maintenance Policy
Any change that modifies operator behavior must update documentation in the same change.

Operator behavior includes:

- New Makefile targets.
- Changed Makefile targets.
- Removed Makefile targets.
- New scripts.
- Changed script arguments.
- Changed environment variables.
- Changed safety confirmations.
- Changed Ansible playbooks.
- Changed installation flow.
- Changed QEMU workflow.
- Changed Codex bootstrap method.
- Changed OpenSpec workflow.
- Changed disk safety model.

Documentation must be operational: prefer commands, expected outputs, failure modes, recovery advice, and safety checks over vague prose.

## 2. Which Files Agents Must Update
Agents must consider these documentation targets for behavior changes:

- `AGENTS.md` or `agents.md`: root agent instruction file.
- `README.md`: concise user-facing project overview.
- `docs/`: detailed workflows and operator procedures.
- `skills/`: reusable operational procedures.
- `agents/`: agent-specific behavior and responsibilities.
- `openspec/changes/*/tasks.md`: implementation and documentation task tracking.

Agents should update the narrowest appropriate set of files. Avoid duplicating the same procedure in many places.

## 3. When Documentation Updates Are Mandatory
Documentation updates are mandatory when a change affects:

- Operator commands.
- Makefile targets or variables.
- Script names, arguments, environment variables, output, or failure modes.
- Safety confirmations or safety model behavior.
- Disk, filesystem, mount, bootloader, chroot, or cleanup behavior.
- Codex bootstrap methods or authentication guidance.
- OpenSpec commands, validation workflow, or change lifecycle.
- QEMU VM workflow, disk image handling, ISO path, or cleanup.
- Ansible inventory, variables, roles, playbooks, dry-run, or execution targets.
- Agent or skill behavior rules.

If the implementation is behavior-neutral, documentation may be unnecessary, but the agent should state why.

## 4. Documentation Review Checklist
Before finishing a behavior-changing change, agents must check:

- Is the Makefile target list still accurate?
- Are required variables documented?
- Are safety confirmations documented?
- Are failure modes and recovery steps documented?
- Are scripts documented by behavior, not just filename?
- Are OpenSpec tasks updated to include documentation work?
- Are QEMU disk and ISO paths accurate?
- Are Ansible workflow docs still aligned with playbooks and roles?
- Are agent and skill instructions still current?
- Are secrets excluded from all documentation?
- Is detailed procedure in `docs/` or `skills/` rather than bloating `README.md`?

## 5. How Agents Should Detect Stale Documentation
Agents should look for stale documentation by:

- Searching for changed target names across `README.md`, `docs/`, `skills/`, `agents/`, and OpenSpec changes.
- Searching for removed script names or old variable names.
- Comparing `make help` output or Makefile targets against documented targets.
- Comparing script usage text against docs and skills.
- Comparing Ansible playbook and role names against Ansible docs.
- Comparing QEMU defaults and safety behavior against QEMU docs.
- Reviewing OpenSpec tasks for missing documentation tasks.
- Searching for obsolete safety confirmations.

Use fast repository search tools such as `rg` when available.

## 6. How Agents Should Update `agents.md` or `AGENTS.md`
The root agent instruction file must contain project-wide rules that apply to all agents.

It should include:

- Makefile as the operator-facing control plane.
- Documentation maintenance rule.
- Safety documentation rule.
- Secret handling rule.
- Phase separation rule.
- Pointer to detailed docs and skills.

Keep root agent instructions concise and directive. Do not duplicate full procedures from `docs/` or `skills/`.

## 7. How Agents Should Update `README.md`
`README.md` should remain concise and user-facing.

It should include:

- Project purpose.
- Main phases.
- Most important make targets.
- Where to find detailed docs.
- High-level safety warning.

Do not put long installation procedures in `README.md`. Link or point to `docs/` and `skills/` instead.

## 8. How Agents Should Update `docs/`
Use `docs/` for detailed workflows and operator procedures.

Examples:

- QEMU manual install testing.
- Manual Gentoo install flow.
- Codex bootstrap flow.
- Recovery procedures.
- Makefile target usage.

Docs should include commands, expected outputs, failure modes, and recovery advice.

## 9. How Agents Should Update `skills/`
Use `skills/` for reusable operational procedures that Codex should apply across tasks.

Update skills when:

- A workflow changes.
- A safety model changes.
- A Makefile target contract changes.
- Ansible or QEMU procedural behavior changes.
- OpenSpec workflow changes.

Skills should be practical and specific, not broad summaries.

## 10. How Agents Should Update OpenSpec Tasks
For implementation changes, `tasks.md` must include documentation tasks.

Examples:

- Update `README.md` target list.
- Update `docs/qemu-manual-install-test.md`.
- Update `skills/makefile-control-plane.md`.
- Update `agents/safety-review-agent.md`.
- Verify docs mention new safety confirmation.

Tasks should remain unchecked until documentation is actually updated and reviewed.

## 11. How Agents Should Document Makefile Targets
Makefile target documentation must include:

- Target name.
- Risk level.
- Required variables.
- Expected behavior.
- Failure modes.
- Safety confirmations.
- Whether the target is read-only, semi-dangerous, destructive, or cleanup.

Operator-facing docs must tell users to run make targets, not long undocumented commands.

## 12. How Agents Should Document Safety-impacting Changes
Safety-impacting changes must update safety documentation in the same change.

Document:

- What can be modified or destroyed.
- Required confirmations.
- Rejected unsafe inputs.
- Path or disk identity checks.
- Recovery advice.
- Logs or evidence operators should preserve.

Safety docs must never imply that a destructive action is automatic or safe without review.

## 13. How Agents Should Document QEMU Workflows
QEMU workflow docs must include:

- ISO path.
- qcow2 disk path.
- QEMU directory.
- Makefile targets.
- No host block devices.
- No sudo by default.
- UEFI/BIOS behavior.
- Cleanup confirmation.
- Manual installation boundary.

QEMU docs must clearly say the VM is for manual installation testing only.

## 14. How Agents Should Document Ansible Workflows
Ansible workflow docs must include:

- Local execution from the official Gentoo live ISO.
- Inventory model.
- Variable model.
- Dry-run strategy.
- Makefile targets.
- Safety gates.
- Logs.
- Idempotency expectations.

Do not document Ansible as replacing phase 1 manual installation unless an approved change does that.

## 15. What Agents Must Not Document
Agents must not document:

- Real API keys.
- Real tokens.
- Real private SSH keys.
- Local credentials.
- Password values.
- Host-specific secrets.
- Unapproved destructive shortcuts.
- Unsupported v1 features as if they are implemented.
- Long raw command sequences that bypass Makefile targets.

Agents should document `.env.example` variable names only when useful. Secret values must stay empty.
