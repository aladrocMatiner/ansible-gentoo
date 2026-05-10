# Change: implement-ansible-chroot-preparation

## Summary
Implement chroot preparation for the extracted Gentoo target root, including pseudo-filesystem mounts and DNS readiness.

## Motivation
Portage, kernel, services, users, and bootloader steps require a prepared target environment. This maps to the Gentoo AMD64 Handbook chroot preparation phase, where pseudo-filesystems and DNS are prepared before entering the new environment. Chroot preparation must be explicit, guarded, and reversible.

## Scope
- Add `make prepare-chroot`.
- Add shared `common/chroot` role.
- Mount or bind required pseudo-filesystems under `/mnt/gentoo`, including `/proc`, `/sys`, `/dev`, and `/run` handling as required by the approved implementation.
- Prepare DNS resolver access without leaking host-specific secrets into the repository.
- Provide a documented chroot command wrapper if needed.

## Non-goals
- Do not run arbitrary commands inside chroot.
- Do not configure Portage.
- Do not install packages.

## Safety Requirements
- Require `/mnt/gentoo` mounted.
- Only mount under `/mnt/gentoo`.
- Refuse target root `/`.
- Show before/after mounts.
- Be idempotent for existing correct pseudo-filesystem mounts.

## Acceptance Criteria
- Required chroot mount points are prepared.
- DNS works or failure is reported before package operations.
- The workflow reports the exact pseudo-filesystem mounts it prepared.
- No mounts occur outside target root.
- `openspec validate implement-ansible-chroot-preparation --strict` passes.

## Affected Files
- `Makefile`
- `ansible/roles/common/chroot/`
- `docs/`
- `skills/`
