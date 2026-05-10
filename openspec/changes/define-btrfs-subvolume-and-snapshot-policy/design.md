# Design: define-btrfs-subvolume-and-snapshot-policy

## Approved Subvolumes

Initial approved subvolumes:

- `@` mounted as `/`
- `@home` mounted as `/home`
- `@var` mounted as `/var`
- `@var_log` mounted as `/var/log`
- `@var_cache` mounted as `/var/cache`
- `@snapshots` mounted as `/.snapshots`

Planning, filesystem creation, mount target, fstab generation, and final checks must all use the same names and mountpoint mapping.

## Mount Policy

Root must mount with `subvol=@`.

All Btrfs subvolume mount options must be generated from a shared variable set. The implementation must document default options before destructive Btrfs work is enabled.

## Snapshot Policy

Create `@snapshots` as a mount location for future snapshot tooling, but do not create automatic snapshots or install snapshot management tools in v1 unless a later approved change adds that behavior.

## Safety

- Btrfs creation requires the same destructive confirmation as ext4 formatting.
- Subvolume creation must happen only on the approved root partition.
- Temporary setup mounts must be under a documented safe path and unmounted before completion.
- Final checks must verify root uses `subvol=@`.
