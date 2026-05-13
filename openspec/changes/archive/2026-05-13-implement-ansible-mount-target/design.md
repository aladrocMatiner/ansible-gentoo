# Design: implement-ansible-mount-target

## Handbook Alignment
Follow the Gentoo AMD64 Handbook mount phase while applying the project mount layout:

- target root: `/mnt/gentoo`
- EFI system partition before chroot: `/mnt/gentoo/boot/efi`
- EFI system partition inside target: `/boot/efi`

## Sequence
1. Reuse mount and filesystem plans.
2. Verify filesystem paths exist.
3. Verify target mount path is safe.
4. Create directories under `/mnt/gentoo` only.
5. Mount root.
6. Mount Btrfs subvolumes if selected.
7. Mount EFI.
8. Report mount table.

## Btrfs
Root must mount with `subvol=@`. Other subvolumes use their planned mountpoints.

## Safety
The role must fail if a target path is already mounted to an unexpected source.
