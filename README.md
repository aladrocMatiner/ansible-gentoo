# gentoo-ai-installer

`gentoo-ai-installer` helps a human operator install Gentoo Linux safely, then gradually turns validated manual steps into reproducible automation.

## Project Shape
- Phase 1: boot the official Gentoo live ISO and use temporary Codex assistance.
- Phase 2: build a reusable Ansible installer for network-reachable Gentoo live ISO targets.
- libvirt/virsh: local validation harness for manual and Ansible workflow testing with a managed VM and qcow2 disk before using real hardware.
- Proxmox: remote disposable VM validation harness for the same SSH-driven Ansible installer.
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

Check release readiness without running installer tasks:

```sh
make release-check
```

Release checks are documented in `docs/release-readiness.md`.

The first destructive targets are `make partition` and `make format`; read `docs/ansible-partition-apply.md` and `docs/ansible-filesystem-apply.md` before using them. After formatting, `make mount-target` mounts the approved target root and ESP for stage3 extraction; see `docs/ansible-mount-target.md`. `make stage3-install` then downloads, verifies, and extracts the official stage3; see `docs/ansible-stage3-install.md` and `docs/stage3-signature-policy.md`. `make prepare-chroot` prepares Handbook-aligned pseudo-filesystem mounts and DNS readiness for later chroot-based tasks; see `docs/ansible-chroot-preparation.md`. `make configure-portage` writes conservative Portage settings, syncs the official Gentoo repo, and selects the matching OpenRC/systemd profile without installing packages; see `docs/ansible-portage-baseline.md`. `make configure-system` writes target hostname, timezone, locale, and keymap; see `docs/ansible-locale-timezone-hostname.md`. `make generate-fstab` writes UUID-based ext4 or Btrfs target fstab entries; see `docs/ansible-fstab-generation.md`. `make install-kernel` installs `gentoo-kernel-bin`, configures installkernel/dracut command-line input, and validates target `/boot` artifacts without installing GRUB; see `docs/ansible-kernel-install.md`. `make install-system-packages` installs the minimal console package set and enables init-specific target services, including NetworkManager; optional installed WiFi support is controlled by `ENABLE_WIFI=yes` and documented in `docs/installed-wifi-policy.md`. `make configure-users ADMIN_USER=<name>` creates the target admin account, sudo policy, and optional SSH access without logging secret values; see `docs/ansible-users-and-access.md`. `make install-bootloader INSTALL_DISK=<disk> I_UNDERSTAND_BOOTLOADER_CHANGES=yes` installs GRUB for UEFI and may update EFI boot entries; see `docs/ansible-bootloader-grub.md`. `make final-checks ADMIN_USER=<name>` runs read-only reboot readiness checks and does not reboot; see `docs/ansible-final-checks-and-reboot-readiness.md`. `make install-openrc` and `make install-systemd` run the full destructive shared install flow; see `docs/ansible-basic-console-install-orchestration.md`.

Installer phases write non-secret checkpoints under `var/state/` and `logs/install-runs/`. Use `make install-state` to inspect the current checkpoint, `make install-resume-plan` to validate current live ISO facts, and `make install-resume` to run exactly one planner-approved phase before planning again; see `docs/install-state-and-resume-checkpoints.md`.

For the first disposable VM validation of resumable execution, use the OpenRC/ext4 runbook in [docs/resumable-libvirt-openrc-ext4-validation.md](docs/resumable-libvirt-openrc-ext4-validation.md).

Use `make install-audit` to generate a secret-safe evidence bundle for the current run under `logs/install-runs/<run-id>/audit-bundle/`; see `docs/install-audit-bundle.md`.

Use `make install-report` to generate a concise human-readable summary at `logs/install-runs/<run-id>/install-report.md`; see `docs/install-report-summary.md`.

Use `make cleanup-plan` before cleanup and `make clean-state`, `make clean-logs`, `make clean-audit`, `make clean-stage3-cache`, or `make reset-test-run` only with `I_UNDERSTAND_CLEANUP_DELETE=DELETE`; see `docs/cleanup-reset-policy.md`.

Use `make record-manual-step MANUAL_STEP_SUMMARY=... MANUAL_STEP_REASON=...` to record non-secret manual recovery notes before resuming automation; see `docs/manual-escape-hatch-policy.md`.

Use `make vm-validate-first-boot ADMIN_USER=<admin-user>` after a completed VM install to boot the installed qcow2 disk and run read-only first-boot checks over SSH; see `docs/first-boot-validation.md`.

Optional post-install desktop profiles run only after the base system is installed, booted, SSH-reachable, and validated. Implemented profiles are `i3-x11`, `sway-wayland`, `hyprland-wayland`, `niri-wayland`, and `mango-wayland`:

```sh
make desktop-plan DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=<host> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
make desktop-install DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=<host> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
make desktop-validate DESKTOP_PROFILE=sway-wayland DESKTOP_TARGET_HOST=<host> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
```

Experimental profiles require `DESKTOP_EXPERIMENTAL_OK=yes` for install. See `docs/desktop-profiles.md` and the profile-specific docs.

Use `make vm-test-matrix-plan` to plan OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl libvirt validation entries without creating disks or running destructive installs; see `docs/libvirt-install-test-matrix.md`.

Use `make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>` before running disposable full-VM validation with `make vm-e2e-install`; see `docs/libvirt-end-to-end-install-validation.md`.

Use `make vm-e2e-matrix` only when you intend to reset and reinstall all 12 disposable libvirt cases. It runs the same single-case workflow for OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavors, and requires the normal VM destructive confirmations.

Disposable VM E2E installs default `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`, so the installed admin user can SSH in with the configured key and run `sudo su -` without a password. Real installs keep password-requiring sudo unless `ADMIN_SUDO_NOPASSWD=yes` is set explicitly.

Per-case libvirt quickstarts are indexed in [docs/quickstarts/README.md](docs/quickstarts/README.md):

- [amd64 OpenRC + ext4](docs/quickstarts/openrc-ext4.md)
- [amd64 OpenRC + Btrfs](docs/quickstarts/openrc-btrfs.md)
- [amd64 systemd + ext4](docs/quickstarts/systemd-ext4.md)
- [amd64 systemd + Btrfs](docs/quickstarts/systemd-btrfs.md)
- [amd64 OpenRC + ext4 + hardened](docs/quickstarts/openrc-ext4-hardened.md)
- [amd64 OpenRC + Btrfs + hardened](docs/quickstarts/openrc-btrfs-hardened.md)
- [amd64 systemd + ext4 + hardened](docs/quickstarts/systemd-ext4-hardened.md)
- [amd64 systemd + Btrfs + hardened](docs/quickstarts/systemd-btrfs-hardened.md)
- [amd64 OpenRC + ext4 + musl](docs/quickstarts/openrc-ext4-musl.md)
- [amd64 OpenRC + Btrfs + musl](docs/quickstarts/openrc-btrfs-musl.md)
- [amd64 systemd + ext4 + musl](docs/quickstarts/systemd-ext4-musl.md)
- [amd64 systemd + Btrfs + musl](docs/quickstarts/systemd-btrfs-musl.md)

VM targets derive case-specific domains and artifacts from platform `amd64`, `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR`; use `make vm-list-cases` to inspect them before creating anything. `STAGE3_FLAVOR=standard` preserves the original case names without a `standard` suffix.

For manual image/test-line labels, `VM_TEST_IMAGE_NAME=<name>` inserts `<name>` into the generated VM and disk names. `VM_TEST_IMAGE_NAME` is a label, not an ISO path; use `VM_ISO` for the official Gentoo live ISO location.

Use `make handbook-trace` to regenerate the mapping from Makefile targets and Ansible roles to the Gentoo AMD64 Handbook; see `docs/handbook-traceability.md`.

The v1 installed-system completion contract is documented in `docs/target-system-baseline.md`.

Use `make host-check` before local libvirt validation to verify host tools, libvirt access, OVMF firmware, ISO availability, and controller resources; see `docs/supported-host-requirements.md`.

Use `make real-hardware-check ANSIBLE_LIVE_HOST=... INSTALL_DISK=/dev/disk/by-id/...` before destructive physical-machine workflows; see `docs/real-hardware-readiness.md`.

Use `make partition-preview`, `make format-preview`, `make mount-preview`, `make users-preview`, and `make bootloader-preview` to inspect destructive/high-risk operations without setting confirmations; see `docs/destructive-command-preview.md`.

Current Ansible planning targets run from the operator machine over SSH into a booted official Gentoo live ISO. For a real network target, pass `ANSIBLE_LIVE_HOST=<address>` and optionally `ANSIBLE_LIVE_USER=root ANSIBLE_LIVE_PORT=22`. When `ANSIBLE_LIVE_HOST` is empty, the wrapper targets discover the local libvirt VM as the test target.

Ansible SSH wrappers use configurable keepalives and connection reuse. Defaults are `ANSIBLE_SSH_CONNECT_TIMEOUT=10`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL=30`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX=6`, `ANSIBLE_SSH_CONTROL_MASTER=auto`, `ANSIBLE_SSH_CONTROL_PERSIST=10m`, and `ANSIBLE_SSH_CONTROL_PATH_DIR=var/ssh-control`. For long install runs, start the controller-side `make ...` command inside `tmux` or `screen`; that protects the operator session while the wrapper keepalives protect the controller-to-live-ISO SSH connection.

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
make vm-e2e-matrix
make vm-shutdown
make vm-destroy
make vm-clean
```

Detailed VM usage is in `docs/libvirt-manual-install-test.md`. Legacy `qemu-*` targets are compatibility aliases for the libvirt workflow.

Proxmox validation targets are documented in `docs/proxmox-validation.md`. Use `make proxmox-list-cases` to inspect the 12-case Proxmox matrix and `make proxmox-e2e-matrix` when you intend to reinstall the disposable Proxmox cases. Matrix details are in `docs/proxmox-install-test-matrix.md`; single-case E2E usage is in `docs/proxmox-end-to-end-install-validation.md`. After a Proxmox E2E install, use `make proxmox-vm-start-installed PROFILE=<profile> FILESYSTEM=<filesystem> STAGE3_FLAVOR=<flavor>` to switch a project-owned VM from live ISO boot arguments to the installed disk `scsi0`. Use `make proxmox-ensure-installed-access-all` to ensure every project-owned Proxmox matrix VM has the default installed `aladroc` SSH/sudo access with the controller public key.

## Safety
Operator-facing actions should go through Makefile targets. Destructive workflows must require explicit confirmation and must document the target disk, paths, variables, failure modes, and recovery steps.

Documentation maintenance rules for agents are in `AGENTS.md`.
