# Destructive Safety Gates

`make destructive-safety-check` runs the shared disk safety gate without mutating disks. It is a rehearsal for future destructive apply targets and is intentionally stricter than read-only plan targets.

## Run

For the local libvirt VM only:

```sh
make destructive-safety-check INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

For a network target, use the disk path reported by that target:

```sh
make destructive-safety-check ANSIBLE_LIVE_HOST=192.0.2.10 INSTALL_DISK=/dev/<target-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes
```

This target does not run `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `grub-install`, or `efibootmgr`.

## Checks

The shared `common/disk_safety` role verifies:

- `INSTALL_DISK` is set explicitly and has no default,
- disk syntax is conservative and contains no wildcard or shell metacharacters,
- destructive confirmation is present when required,
- the selected path matches exactly one detected block device,
- the selected path is type `disk`,
- the selected disk itself is not mounted,
- descendants under the selected disk are not mounted,
- disk identity and existing descendants are reported before any future destructive action,
- resume checkpoints are compared when a resumed destructive workflow explicitly provides checkpoint input.

## Resume Checkpoint Validation

Resume checkpoint validation is opt-in until the install-state workflow owns durable state files. A caller enables it by setting one of these Ansible inputs for `common/disk_safety`:

- `disk_safety_resume_checkpoint_required=true`
- `disk_safety_resume_checkpoint_file=<controller-local-json-or-yaml-file>`
- `disk_safety_resume_checkpoint=<inline-mapping>`

When enabled, the role fails closed unless the checkpoint is present and contains selected disk identity plus descendant block state. It compares:

- selected disk path and size,
- selected disk model and serial when those were recorded,
- partition descendants,
- filesystem types,
- filesystem UUIDs,
- mountpoints,
- `profile` when the checkpoint records it,
- `filesystem` when the checkpoint records it.

Resume checkpoint success is not destructive confirmation. Destructive workflows still require `I_UNDERSTAND_THIS_WIPES_DISK=yes`; bootloader workflows still require `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

## Relationship To Plan Targets

`partition-plan`, `mount-plan`, and `filesystem-plan` reuse the same `common/disk_safety` role without requiring destructive confirmation. Apply targets such as `make partition` and `make format` reuse the same role with confirmation enabled before doing any disk mutation.

`make mount-target` and `make install-bootloader` are the current workflows allowed to set `disk_safety_allow_mounted_descendants=true`. For `mount-target`, the exception exists so the target remains idempotent after the approved root, Btrfs subvolumes, and ESP are already mounted. For `install-bootloader`, the exception exists because the target root and ESP must already be mounted before GRUB work. The caller must then validate each mounted descendant against the approved plan before continuing. No partitioning or formatting workflow may use this exception.

Preview output is not confirmation. Operators must still pass `I_UNDERSTAND_THIS_WIPES_DISK=yes` to destructive apply workflows.

Bootloader workflows do not use the disk-wipe confirmation variable. They must require `I_UNDERSTAND_BOOTLOADER_CHANGES=yes` because GRUB may update persistent EFI boot entries.

## Failure Modes

- `DISK_UNSAFE`: missing disk, unsafe syntax, no exact detected match, non-disk path, mounted disk, or mounted descendant.
- `DESTRUCTIVE_CONFIRMATION_MISSING`: confirmation is required but `I_UNDERSTAND_THIS_WIPES_DISK=yes` is absent.
- `RESUME_CHECKPOINT_INVALID`: resume validation was requested but no usable checkpoint was provided.
- `RESUME_CHECKPOINT_MISMATCH`: current disk, partition, filesystem, UUID, mount, profile, or filesystem-selection facts differ from the checkpoint.
- SSH target discovery failure: set `ANSIBLE_LIVE_HOST=...` for a network target or start/bootstrap the local libvirt VM.

## Recovery

- Re-run `make detect-disks` against the same target.
- Verify the disk model, size, serial, partitions, filesystems, and mountpoints.
- Unmount target descendants manually only when you are certain they belong to the test environment.
- Re-run `make destructive-safety-check` before any future destructive target.
