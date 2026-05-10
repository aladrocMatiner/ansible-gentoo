# Tasks: implement-ansible-mount-target

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-mount-target --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `make mount-target`.
- [ ] Add wrapper, playbook, and role.
- [ ] Implement ext4 mounts.
- [ ] Implement Btrfs subvolume mounts.
- [ ] Ensure root Btrfs mount uses `subvol=@`.
- [ ] Ensure EFI mounts at `/mnt/gentoo/boot/efi`.
- [ ] Follow the approved Btrfs subvolume policy.
- [ ] Record install-state checkpoint and audit evidence.
- [ ] Update docs and skills.
- [ ] Validate idempotency in VM.
