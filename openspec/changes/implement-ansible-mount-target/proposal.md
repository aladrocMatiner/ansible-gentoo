# Change: implement-ansible-mount-target

## Summary
Implement target filesystem mounting for the formatted Gentoo target root.

## Motivation
Stage3 extraction requires the target root to be mounted at `/mnt/gentoo` with EFI mounted at `/mnt/gentoo/boot/efi`, matching the Gentoo AMD64 Handbook mount phase translated to this project's `/boot/efi` layout. Btrfs requires subvolume-aware mounting.

## Scope
- Add `make mount-target`.
- Add shared `common/mount_target` role.
- Mount ext4 root and EFI for ext4.
- Mount Btrfs root/subvolumes and EFI for Btrfs.
- Ensure Btrfs root uses `subvol=@`.
- Follow the approved Btrfs subvolume and snapshot policy.
- Create required mount directories only under `/mnt/gentoo`.

## Non-goals
- Do not partition or format.
- Do not extract stage3.
- Do not prepare chroot pseudo-filesystems.

## Safety Requirements
- Require explicit partition sources from approved plans.
- Print or call mount-over preview before changing mount state.
- Refuse mounting over unrelated mounted paths.
- Confirm `/mnt/gentoo` is not `/` and not ambiguous.
- Print current mounts before and after.

## Acceptance Criteria
- `make mount-target ...` mounts the formatted target root and ESP.
- Btrfs uses `subvol=@` for root.
- EFI is mounted at `/mnt/gentoo/boot/efi` before stage3 extraction.
- Mount actions record non-secret state/audit evidence.
- The workflow is idempotent for already-correct mounts.
- `openspec validate implement-ansible-mount-target --strict` passes.

## Affected Files
- `Makefile`
- `ansible/playbooks/mount-target.yml`
- `ansible/roles/common/mount_target/`
- `docs/`
- `skills/`
