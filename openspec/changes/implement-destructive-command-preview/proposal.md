## Why

The project is about to move from read-only planning into destructive disk and bootloader actions. Operators need an exact preview of what will change before they type destructive confirmations.

## What Changes

- Add a Makefile-mediated destructive preview capability for partitioning, formatting, mount-over operations, user/password changes, and bootloader actions.
- Preview task names, variables, target disk identity, partitions, filesystems, mountpoints, and confirmation requirements before execution.
- Ensure preview is read-only and cannot mutate disks, mounts, users, services, EFI entries, or target files.
- Require destructive apply targets to either call the preview or print equivalent preview output before confirmation.

## Capabilities

### New Capabilities
- `destructive-command-preview`: Produces read-only, operator-facing previews for destructive installer actions.

### Modified Capabilities

## Impact

- Shared destructive safety gates.
- Future Makefile targets for partition, format, mount, bootloader, user, and password workflows.
- Future docs explaining preview output and confirmation boundaries.
