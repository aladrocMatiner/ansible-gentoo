# gentoo-ai-installer

`gentoo-ai-installer` helps a human operator install Gentoo Linux safely, then gradually turns validated manual steps into reproducible automation.

## Project Shape
- Phase 1: boot the official Gentoo live ISO and use temporary Codex assistance.
- Phase 2: build a reusable Ansible installer for network-reachable Gentoo live ISO targets.
- libvirt/virsh: local validation harness for manual and Ansible workflow testing with a managed VM and qcow2 disk before using real hardware.
- OpenSpec: control project changes.
- Makefile: expose operator-facing workflows.

## Main Targets
Run `make help` to see available targets.

Check implemented Ansible content:

```sh
make ansible-check
```

This syntax-checks implemented playbooks and runs `ansible-lint` when it is installed.

Validate installer configuration before connecting to a target:

```sh
make config-check
```

Configuration rules are documented in `docs/install-configuration.md`.

Check for accidental high-risk secrets before committing:

```sh
make secret-check
```

Secret handling rules are documented in `docs/secret-input-policy.md`.

The first destructive targets are `make partition` and `make format`; read `docs/ansible-partition-apply.md` and `docs/ansible-filesystem-apply.md` before using them. After formatting, `make mount-target` mounts the approved target root and ESP for stage3 extraction; see `docs/ansible-mount-target.md`. `make stage3-install` then downloads, verifies, and extracts the official stage3; see `docs/ansible-stage3-install.md` and `docs/stage3-signature-policy.md`. `make prepare-chroot` prepares Handbook-aligned pseudo-filesystem mounts and DNS readiness for later chroot-based tasks; see `docs/ansible-chroot-preparation.md`. `make configure-portage` writes conservative Portage settings, syncs the official Gentoo repo, and selects the matching OpenRC/systemd profile without installing packages; see `docs/ansible-portage-baseline.md`. `make configure-system` writes target hostname, timezone, locale, and keymap; see `docs/ansible-locale-timezone-hostname.md`. `make generate-fstab` writes UUID-based ext4 or Btrfs target fstab entries; see `docs/ansible-fstab-generation.md`. `make install-kernel` installs `gentoo-kernel-bin`, configures installkernel/dracut command-line input, and validates target `/boot` artifacts without installing GRUB; see `docs/ansible-kernel-install.md`. `make install-system-packages` installs the minimal console package set and enables init-specific target services, including NetworkManager; see `docs/ansible-system-packages-and-services.md`. `make configure-users ADMIN_USER=<name>` creates the target admin account, sudo policy, and optional SSH access without logging secret values; see `docs/ansible-users-and-access.md`. `make install-bootloader INSTALL_DISK=<disk> I_UNDERSTAND_BOOTLOADER_CHANGES=yes` installs GRUB for UEFI and may update EFI boot entries; see `docs/ansible-bootloader-grub.md`. `make final-checks ADMIN_USER=<name>` runs read-only reboot readiness checks and does not reboot; see `docs/ansible-final-checks-and-reboot-readiness.md`. `make install-openrc` and `make install-systemd` run the full destructive shared install flow; see `docs/ansible-basic-console-install-orchestration.md`.

Installer phases write non-secret checkpoints under `var/state/` and `logs/install-runs/`. Use `make install-state` to inspect the current checkpoint and `make install-resume-plan` to validate current live ISO facts before continuing a partially completed run; see `docs/install-state-and-resume-checkpoints.md`.

Use `make install-audit` to generate a secret-safe evidence bundle for the current run under `logs/install-runs/<run-id>/audit-bundle/`; see `docs/install-audit-bundle.md`.

Use `make install-report` to generate a concise human-readable summary at `logs/install-runs/<run-id>/install-report.md`; see `docs/install-report-summary.md`.

Use `make cleanup-plan` before cleanup and `make clean-state`, `make clean-logs`, `make clean-audit`, `make clean-stage3-cache`, or `make reset-test-run` only with `I_UNDERSTAND_CLEANUP_DELETE=DELETE`; see `docs/cleanup-reset-policy.md`.

Use `make vm-validate-first-boot ADMIN_USER=<admin-user>` after a completed VM install to boot the installed qcow2 disk and run read-only first-boot checks over SSH; see `docs/first-boot-validation.md`.

Use `make handbook-trace` to regenerate the mapping from Makefile targets and Ansible roles to the Gentoo AMD64 Handbook; see `docs/handbook-traceability.md`.

The v1 installed-system completion contract is documented in `docs/target-system-baseline.md`.

Use `make host-check` before local libvirt validation to verify host tools, libvirt access, OVMF firmware, ISO availability, and controller resources; see `docs/supported-host-requirements.md`.

Use `make partition-preview`, `make format-preview`, `make mount-preview`, `make users-preview`, and `make bootloader-preview` to inspect destructive/high-risk operations without setting confirmations; see `docs/destructive-command-preview.md`.

Current Ansible planning targets run from the operator machine over SSH into a booted official Gentoo live ISO. For a real network target, pass `ANSIBLE_LIVE_HOST=<address>` and optionally `ANSIBLE_LIVE_USER=root ANSIBLE_LIVE_PORT=22`. When `ANSIBLE_LIVE_HOST` is empty, the wrapper targets discover the local libvirt VM as the test target.

Optional local live ISO fallback targets run inside the booted official Gentoo live ISO with `ansible_connection=local`: `make local-live-preflight`, `make local-detect-disks`, `make local-install-plan`, and `make local-partition-plan`. The SSH/network workflow remains the primary reusable installer path; see `docs/live-iso-local-ansible.md`.

Current libvirt manual test targets:

```sh
make vm-check
make vm-disk
make vm-define
make vm-start
make vm-console
make vm-viewer
make vm-ip
make vm-bootstrap-ssh
make vm-ssh
make vm-rsync
make vm-ansible-ping
make vm-shutdown
make vm-destroy
make vm-clean
```

Detailed VM usage is in `docs/libvirt-manual-install-test.md`. Legacy `qemu-*` targets are compatibility aliases for the libvirt workflow.

## Safety
Operator-facing actions should go through Makefile targets. Destructive workflows must require explicit confirmation and must document the target disk, paths, variables, failure modes, and recovery steps.

Documentation maintenance rules for agents are in `AGENTS.md`.
