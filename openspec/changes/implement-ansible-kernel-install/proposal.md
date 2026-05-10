# Change: implement-ansible-kernel-install

## Summary
Install `gentoo-kernel-bin` in the target Gentoo system and validate boot artifacts.

## Motivation
The v1 installer uses `gentoo-kernel-bin` to avoid manual kernel compilation and keep the first reproducible install simple.

This change maps to the Gentoo AMD64 Handbook kernel phase. The Handbook notes that distribution kernels such as `gentoo-kernel-bin` expect installkernel/initramfs handling; this project must configure the required kernel installation support explicitly.

## Scope
- Add shared `common/kernel` role.
- Configure required installkernel/initramfs support for the selected profile where needed.
- Install `gentoo-kernel-bin`.
- Verify kernel and initramfs artifacts in `/boot`.
- Record kernel/initramfs evidence needed by the boot kernel command line policy.
- Support OpenRC and systemd through shared logic.

## Non-goals
- Do not build a custom kernel.
- Do not install GRUB.
- Do not alter EFI boot entries.

## Safety Requirements
- Run only after chroot and Portage baseline are ready.
- Fail if `/boot` or EFI paths are ambiguous.
- Preserve package logs.

## Acceptance Criteria
- `gentoo-kernel-bin` is installed.
- Required installkernel/initramfs support is configured for GRUB.
- Kernel files exist in target `/boot`.
- Kernel/initramfs artifacts support the approved boot command line policy.
- `openspec validate implement-ansible-kernel-install --strict` passes.

## Affected Files
- `ansible/roles/common/kernel/`
- `docs/`
- `skills/`
