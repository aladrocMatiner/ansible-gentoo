# Change: implement-shared-destructive-safety-gates

## Summary
Implement shared destructive safety gates used by all future disk, filesystem, mount, user, and bootloader apply workflows.

## Motivation
The project is about to introduce destructive operations. Safety confirmation logic must be centralized before individual apply roles are added.

## Scope
- Add shared Ansible `common/disk_safety` role.
- Add Makefile/script confirmation behavior.
- Require explicit `INSTALL_DISK`.
- Require `I_UNDERSTAND_THIS_WIPES_DISK=yes` for destructive disk work.
- Print disk model, serial, size, current partitions, filesystems, and mountpoints.
- Reject mounted selected disk descendants.
- Integrate with `implement-destructive-command-preview` so destructive targets show an exact read-only preview before confirmation.
- Integrate with `implement-install-state-and-resume-checkpoints` so destructive gates compare current facts with recorded checkpoints when resuming.
- Consume the install configuration schema and config validation report for variable checks.
- Use shared logging/error taxonomy for fail-closed messages.

## Non-goals
- Do not partition or format.
- Do not mount target filesystems.
- Do not install Gentoo.

## Safety Requirements
- Fail closed on missing variables or ambiguity.
- No default install disk anywhere.
- No wildcard disk matching.
- Confirmation logic must be reused by later destructive roles.

## Acceptance Criteria
- A shared safety role exists.
- Destructive targets can consume one shared safety result.
- Destructive targets print or call a read-only preview before accepting confirmation.
- Resume does not bypass destructive confirmation or disk identity checks.
- Variable validation uses the canonical configuration schema.
- Safety docs and review instructions are updated.
- `openspec validate implement-shared-destructive-safety-gates --strict` passes.

## Affected Files
- `ansible/roles/common/disk_safety/`
- `scripts/`
- `Makefile`
- `docs/`
- `skills/`
