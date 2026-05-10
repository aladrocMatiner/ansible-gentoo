# Design: implement-shared-destructive-safety-gates

## Shared Role
`common/disk_safety` validates explicit disk intent, destructive confirmation, disk identity, mount state, and VM guest context.

## Confirmation Inputs
- `install_disk`
- `confirm_wipe_disk`
- `I_UNDERSTAND_THIS_WIPES_DISK=yes` from Makefile
- optional approved plan checksum, timestamp, or install-state checkpoint

## Preview Integration
Destructive apply targets must call the preview capability or print equivalent read-only preview data before accepting confirmation. Preview success is not confirmation and must not set confirmation variables.

## State Integration
When resuming, safety gates must compare current disk identity, partition state, filesystem UUIDs, and mount state against the recorded install-state checkpoint before allowing the next step.

## Fail-closed Cases
- Missing disk.
- Default or wildcard disk.
- Disk path not found.
- Disk not type `disk`.
- Mounted disk or descendant.
- Missing destructive confirmation.
- Resume checkpoint missing or inconsistent.
- Init-specific role attempts disk mutation directly.

## Output
Produce structured safety facts for later roles and print a human-readable disk summary.
