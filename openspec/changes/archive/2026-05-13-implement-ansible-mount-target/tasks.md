# Tasks: implement-ansible-mount-target

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-mount-target --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `make mount-target`.
- [x] Add wrapper, playbook, and role.
- [x] Implement ext4 mounts.
- [x] Implement Btrfs subvolume mounts.
- [x] Ensure root Btrfs mount uses `subvol=@`.
- [x] Ensure EFI mounts at `/mnt/gentoo/boot/efi`.
- [x] Follow the approved Btrfs subvolume policy.
- [x] Record install-state checkpoint and audit evidence.
- [x] Update docs and skills.
- [x] Validate idempotency in VM.
