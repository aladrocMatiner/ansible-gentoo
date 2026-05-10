# Project Completion Roadmap

This roadmap orders the remaining OpenSpec changes needed to take `gentoo-ai-installer` from read-only planning to a reproducible basic-console Gentoo installation.

The project baseline remains:

- official Gentoo live ISO,
- temporary Codex bootstrap in the live environment,
- Makefile as the operator-facing control plane,
- Ansible for phase-2 reproducible network installation from an operator/controller machine,
- libvirt VM validation as the local test harness before real hardware,
- amd64, UEFI, GRUB, `gentoo-kernel-bin`, NetworkManager,
- OpenRC and systemd support through shared Ansible logic,
- ext4 and Btrfs filesystem variants,
- no LUKS in the current plan.

The official Gentoo AMD64 Handbook remains the baseline procedure. Project-specific decisions must be documented where they differ from the Handbook's simplest examples:

- NetworkManager is used for v1 networking.
- GRUB is used for UEFI boot.
- EFI is mounted at `/boot/efi` in the installed system.
- `gentoo-kernel-bin` requires explicit installkernel/initramfs support.
- FAT32/vfat tooling and Btrfs tooling must be installed when required.

## Current Implemented Foundation

Implemented read-only or test infrastructure:

1. libvirt VM workflow for safe official-ISO testing.
2. Live ISO Ansible preflight.
3. Disk detection.
4. Install plan.
5. Partition plan.
6. Mount plan.
7. Filesystem plan.

These workflows do not partition, format, mount target filesystems, extract stage3, chroot, create users, enable target services, or install bootloaders.

## Remaining Changes

### 0. `define-ansible-quality-standards-and-gates`
Define Ansible authoring standards before broad role implementation: FQCN modules, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff expectations, ansible-lint configuration, scoped live ISO host-key exceptions, and Makefile-mediated quality checks.

### 1. `define-remote-network-ansible-control-plane`
Define the primary controller-to-live-ISO Ansible execution model. The final product is reusable Ansible automation for network-reachable targets booted into the official Gentoo live ISO. libvirt remains a local harness for testing the same workflows.

### 1a. `implement-live-iso-local-ansible-control-plane`
Optionally add a local live ISO Ansible execution path for fallback and diagnostics. This must not become the primary architecture or force reusable roles to depend on local-only assumptions.

### 2. `implement-live-iso-network-bootstrap-hardening`
Make network, DNS, time, SSH, known_hosts, and project sync failures fail early before Ansible handoff.

### 3. `define-supported-host-requirements`
Define host-side requirements for libvirt validation, including tools, libvirt permissions, OVMF, network, storage, and ISO availability.

### 4. `define-install-configuration-schema`
Define one canonical variable contract for Makefile, scripts, and Ansible.

### 5. `implement-config-validation-report`
Add a read-only configuration report that validates variables, unsupported combinations, paths, and secret-policy issues before plan/apply workflows.

### 6. `implement-logging-and-error-taxonomy`
Standardize run ids, log paths, and actionable error categories across Makefile, scripts, and Ansible.

### 7. `define-target-system-baseline`
Define what "basic console install" means for shared behavior plus OpenRC/systemd-specific differences.

### 8. `define-installed-time-sync-policy`
Define installed target time synchronization policy for OpenRC and systemd, distinct from live ISO time checks.

### 9. `define-installed-ssh-policy`
Define optional installed SSH behavior, root SSH restrictions, authorized key input, and validation expectations.

### 10. `define-boot-kernel-commandline-policy`
Define root UUID, Btrfs `rootflags=subvol=@`, and v1 boot command line exclusions before GRUB implementation.

### 11. `define-download-cache-and-mirror-policy`
Define cache paths, mirror overrides, partial download handling, and verification expectations for stage3 and Portage inputs.

### 12. `define-portage-world-update-policy`
Define repository sync, default no broad `@world` update, and config-update handling for v1.

### 13. `implement-install-state-and-resume-checkpoints`
Record non-secret install checkpoints and support resume planning only when current facts match recorded state.

### 14. `implement-install-audit-bundle`
Create a secret-safe evidence bundle for install debugging and final review.

### 15. `implement-secret-input-policy`
Define how passwords, SSH keys, Codex tokens, and other secrets are passed, redacted, and kept out of git/logs.

### 16. `implement-handbook-traceability-report`
Map Makefile targets, Ansible roles, and project-specific deviations back to the Gentoo AMD64 Handbook.

### 17. `implement-destructive-command-preview`
Print exact read-only previews for destructive operations before accepting confirmations.

### 18. `implement-shared-destructive-safety-gates`
Implement common destructive safety gates before any apply workflow. This is the required foundation for partitioning, formatting, mounting, user creation, and bootloader work.

### 19. `implement-ansible-partition-apply`
First destructive disk step. Apply the approved GPT layout only after explicit disk selection and confirmation.

### 20. `define-btrfs-subvolume-and-snapshot-policy`
Define the approved Btrfs subvolume names, mountpoint mapping, root `subvol=@`, and conservative no-automatic-snapshots policy before destructive Btrfs creation.

### 21. `implement-ansible-filesystem-apply`
Create the EFI filesystem and root filesystem. Support ext4 and Btrfs, including the approved Btrfs subvolumes.

### 22. `implement-ansible-mount-target`
Mount the target root and EFI filesystem at `/mnt/gentoo` and `/mnt/gentoo/boot/efi`. For Btrfs, mount `subvol=@` and the approved subvolumes.

### 23. `implement-stage3-signature-policy`
Define mandatory checksum verification and signature verification/fail-closed behavior for official stage3 artifacts.

### 24. `implement-ansible-stage3-install`
Download, verify, and extract the official amd64 Gentoo stage3 matching the selected init system.

OpenRC must select the official amd64 OpenRC stage3. systemd must select the official amd64 systemd stage3.

### 25. `implement-ansible-chroot-preparation`
Prepare pseudo-filesystem mounts and DNS readiness for target chroot operations.

### 26. `implement-ansible-portage-baseline`
Configure conservative Portage defaults, mirrors, repo sync, and OpenRC/systemd profile selection.

### 27. `implement-locale-timezone-hostname`
Configure target hostname, timezone, locale, and keymap as a shared Handbook-aligned system configuration role.

### 28. `implement-ansible-fstab-generation`
Generate UUID-based fstab entries for EFI, ext4 root, or Btrfs subvolumes.

This may run once UUIDs exist even if automation orders it before kernel installation; final checks must validate the final fstab before reboot.

### 29. `implement-ansible-kernel-install`
Install `gentoo-kernel-bin` and verify kernel artifacts under target `/boot`.

Configure installkernel/initramfs support needed by the GRUB boot flow.

### 30. `implement-ansible-system-packages-and-services`
Install minimal console packages and enable required services. Keep OpenRC and systemd service management isolated.

Install `sys-fs/dosfstools` for EFI/vfat and `sys-fs/btrfs-progs` when `FILESYSTEM=btrfs`.

### 31. `implement-ansible-users-and-access`
Create admin access safely without committing secrets. Configure sudo or doas and optional SSH authorized keys.

### 32. `implement-ansible-bootloader-grub`
Install GRUB for UEFI and generate configuration. This is high-risk because it can modify persistent EFI boot state.

Use `/boot/efi` inside the target system, corresponding to `/mnt/gentoo/boot/efi` before chroot.

### 33. `implement-ansible-final-checks-and-reboot-readiness`
Run read-only final checks for fstab, kernel, GRUB, EFI files, networking, users, and target state. Do not reboot automatically.

### 34. `implement-basic-console-install-orchestration`
Wire approved roles into thin OpenRC/systemd entrypoints over a shared install flow.

### 35. `implement-libvirt-install-test-matrix`
Validate OpenRC/systemd and ext4/Btrfs combinations in libvirt, first as read-only plans and later as destructive full-install runs.

### 36. `implement-first-boot-validation`
After a VM install, boot from the installed disk without relying on the live ISO and verify network, hostname, root UUID, admin user, and optional SSH.

### 37. `implement-libvirt-end-to-end-install-validation`
Run the full installer in libvirt using the official ISO and project-local qcow2 disks, then validate boot and network.

### 38. `define-manual-escape-hatch-policy`
Define how manual recovery steps are recorded, audited, and revalidated before automation resumes.

### 39. `implement-install-report-summary`
Generate a concise human-readable summary of what was installed, where logs are, and what to do next.

### 40. `define-real-hardware-readiness-policy`
Define the checklist and warnings required before running destructive workflows on physical hardware.

### 41. `implement-cleanup-and-reset-policy`
Define what generated artifacts can be cleaned, what is preserved by default, and what confirmations are required.

### 42. `implement-project-release-readiness`
Prepare the first usable milestone: README quickstart, release checklist, OpenSpec archive state, safety warnings, and ignored artifact verification.

## Risk Order

Read-only:

- local control-plane validation,
- Ansible syntax/lint quality gates,
- network/bootstrap hardening,
- host requirement checks,
- config validation,
- logging/error taxonomy,
- target baseline definition,
- install-state inspection,
- audit bundle generation,
- secret checks,
- Handbook traceability,
- final checks,
- test matrix planning,
- first-boot validation,
- install report generation,
- real hardware readiness checks,
- release readiness checks.

Semi-dangerous:

- mount target,
- stage3 extraction,
- chroot preparation.

High-risk:

- users and privileged access,
- service enablement,
- bootloader installation.

Destructive:

- partition apply,
- filesystem apply.

## Implementation Rule

Each change must be implemented independently, validated against a network-reachable live ISO target, validated in libvirt when practical, and documented in the same change. OpenRC and systemd behavior must share common roles unless the behavior genuinely differs. Ansible changes must also satisfy the project quality gate: FQCN, named tasks, module-first implementation, guarded command-like tasks, idempotency review, check/diff behavior, secret redaction, and `make ansible-check`.
