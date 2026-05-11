# Change: implement-ansible-fstab-generation

## Summary
Generate target `/etc/fstab` using stable UUID-based entries for EFI, ext4 root, or Btrfs subvolumes.

## Motivation
The installed system must mount root, EFI, and optional Btrfs subvolumes consistently after reboot.

This change maps to the Gentoo AMD64 Handbook system configuration phase. The Handbook commonly discusses fstab after chroot setup; this project may generate fstab once filesystems and UUIDs exist, before or after kernel installation, as long as validation confirms the final target file is correct before bootloader and final checks.

## Scope
- Add shared `common/fstab` role.
- Detect UUIDs after filesystems exist.
- Generate ext4 fstab.
- Generate Btrfs subvolume fstab.
- Generate EFI mount entry for `/boot/efi` to match the project mount layout.
- Use the approved Btrfs subvolume policy for names, mountpoints, and options.
- Provide the root UUID data consumed by the boot kernel command line policy.
- Validate entries before final checks.

## Non-goals
- Do not mount filesystems.
- Do not install bootloader.

## Safety Requirements
- Refuse missing UUIDs.
- Refuse writing fstab outside `/mnt/gentoo/etc/fstab`.
- Preserve backup or diff of existing fstab if present.

## Acceptance Criteria
- ext4 fstab uses root and EFI UUIDs.
- Btrfs fstab includes `subvol=@` and planned subvolume entries.
- Btrfs fstab entries match the approved Btrfs policy.
- Generated fstab uses `/boot/efi` for the EFI mount inside the installed system.
- `openspec validate implement-ansible-fstab-generation --strict` passes.

## Affected Files
- `ansible/roles/common/fstab/`
- `docs/`
- `skills/`
