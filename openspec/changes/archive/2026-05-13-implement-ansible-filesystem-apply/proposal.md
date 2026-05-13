# Change: implement-ansible-filesystem-apply

## Summary
Implement guarded filesystem creation for the approved partition layout, including FAT32 EFI and ext4 or Btrfs root.

## Motivation
After partitioning, the installer must create filesystems safely before mounting. This maps to the Gentoo AMD64 Handbook disk preparation phase, while extending the project plan to support both ext4 and Btrfs variants. Ext4 and Btrfs must share safety checks while keeping filesystem-specific behavior explicit.

## Scope
- Add `make format`.
- Add shared `common/filesystem` role.
- Create FAT32/vfat on ESP.
- Create ext4 root when `FILESYSTEM=ext4`.
- Create Btrfs root and planned subvolumes when `FILESYSTEM=btrfs`.
- Follow `define-btrfs-subvolume-and-snapshot-policy` for Btrfs subvolume names, mountpoint mapping, and snapshot policy.
- Verify required formatting tools are present before running destructive commands.
- Refuse mounted target partitions.

## Non-goals
- Do not partition disks.
- Do not perform final target mounts except a controlled temporary Btrfs setup mount if needed for subvolume creation.
- Do not extract stage3.

## Safety Requirements
- Require explicit `INSTALL_DISK`.
- Require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Print or call destructive preview before accepting confirmation.
- Refuse mounted target partitions.
- Show current filesystem state before formatting.
- Do not overwrite unexpected filesystems unless explicitly confirmed by the same destructive gate.

## Acceptance Criteria
- `make format PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes` creates vfat + ext4 only.
- `make format PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes` creates vfat + Btrfs + planned subvolumes.
- Formatting fails clearly if required tools such as `mkfs.vfat`, `mkfs.ext4`, or `mkfs.btrfs` are missing for the selected filesystem.
- Btrfs creation follows the approved Btrfs layout policy.
- Missing confirmation fails.
- `openspec validate implement-ansible-filesystem-apply --strict` passes.

## Affected Files
- `Makefile`
- `scripts/`
- `ansible/playbooks/filesystem-apply.yml`
- `ansible/roles/common/filesystem/`
- `docs/`
- `skills/`
