## Why

The project should stay aligned with the official Gentoo AMD64 Handbook while translating the procedure into reusable Ansible roles. A traceability report makes deviations visible and reviewable.

## What Changes

- Add a Handbook traceability report mapping project phases, Makefile targets, Ansible roles, and checks back to Handbook sections.
- Require new installer roles to declare their Handbook phase or documented project-specific deviation.
- Expose traceability through Makefile or generated docs.
- Record project-specific choices such as NetworkManager, GRUB UEFI, `/boot/efi`, ext4/Btrfs variants, and libvirt testing.

## Capabilities

### New Capabilities
- `handbook-traceability`: Maps installer implementation and docs to the official Gentoo AMD64 Handbook baseline.

### Modified Capabilities

## Impact

- Future role metadata or documentation conventions.
- Docs under `docs/`.
- OpenSpec review checklist for installer changes.
