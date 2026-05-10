## Why

Btrfs support needs a clear layout policy before destructive formatting and fstab generation are implemented. Without that, subvolume, mount option, and snapshot behavior can drift across roles.

## What Changes

- Define the approved Btrfs subvolume layout for the basic console installer.
- Define root subvolume mount behavior, including `subvol=@`.
- Define initial snapshot policy as explicit and conservative.
- Require Btrfs behavior to be shared across OpenRC and systemd.
- Require docs and plans to show Btrfs subvolumes and mount options before destructive work.

## Capabilities

### New Capabilities
- `btrfs-layout-policy`: Defines approved Btrfs subvolumes, mount options, and snapshot policy.

### Modified Capabilities

## Impact

- Future filesystem apply, mount target, fstab generation, final checks, and docs.
- Existing filesystem/mount planning changes.
