# Makefile Control Plane Skill

## 1. Purpose
This skill defines how `gentoo-ai-installer` uses the Makefile as the central operator-facing control plane.

Codex, OpenSpec, helper scripts, and Ansible must be accessed through make targets so the operator does not need to remember long commands. Dangerous operations must be guarded by explicit variables, confirmation scripts, and visible preflight output.

This skill defines future Makefile behavior. It does not implement the Makefile.

## 2. When to Use This Skill
Use this skill when:

- Adding or changing any operator-facing workflow.
- Adding Codex bootstrap behavior.
- Adding OpenSpec maintenance commands.
- Adding scripts that an operator might run.
- Adding or changing VM/libvirt manual-install test targets.
- Adding Ansible playbooks or roles.
- Adding or changing network live ISO Ansible target selection.
- Adding disk, filesystem, mount, stage3, chroot, bootloader, user, password, or cleanup operations.
- Reviewing whether documentation should mention raw commands or make targets.

## 3. Design Principles
- The Makefile is the public control plane.
- Documentation should tell the operator to run make targets, not long raw commands.
- Scripts and Ansible playbooks are implementation details behind make targets.
- Targets must be small enough to understand and review.
- Read-only plan targets must exist before apply targets.
- Destructive targets must fail closed.
- Dangerous targets must print what they will affect before acting.
- Variables must be explicit when they identify disks, partitions, mount paths, or destructive intent.
- No target may silently select a disk.

## 4. Required Makefile Conventions
- Provide `make help`.
- Group targets by risk: safe, semi-dangerous, destructive.
- Print the selected project variables before actions that depend on them.
- Prefer plan/check targets before apply targets.
- Keep operator-facing target names stable.
- Route OpenSpec through make targets.
- Route Codex bootstrap through make targets.
- Route Ansible through make targets.
- Route scripts through make targets.
- Route VM/libvirt operations through make targets.
- Do not require the operator to run scripts directly.
- Treat Ansible as the main product path: Makefile targets should run reusable Ansible workflows against an explicit network live ISO target when `ANSIBLE_LIVE_HOST` is provided.
- Treat libvirt/VM targets as local validation harnesses for the same Ansible workflows, not as required production installer infrastructure.
- For OpenRC and systemd Ansible flows, prefer parameterized shared Makefile targets or thin variant targets that pass variables into a shared Ansible flow.
- Avoid separate duplicated command chains when `PROFILE=openrc` or `PROFILE=systemd` can select the variant safely.
- Ansible quality checks must be exposed through `make ansible-check`; operators and agents should not need to remember raw syntax-check or lint commands.
- Installer configuration validation must be exposed through `make config-check`; future destructive targets should call the same validation contract before running disk, mount, user, password, or bootloader actions.
- Expose config validation, host checks, state, audit, traceability, cleanup/reset, manual-step recording, real-hardware readiness, install report, test matrix, first-boot validation, and destructive-preview workflows through Makefile targets when implemented.
- Do not hide destructive behavior inside vague targets.
- Update `README.md` or `docs/` whenever operator-facing targets are added, changed, or removed.
- Update this skill when a reusable Makefile target convention changes.

## 5. Variable Conventions
Required project variables:

- `INSTALL_DISK`
- `HOSTNAME`
- `PROFILE`
- `FILESYSTEM`
- `STAGE3_FLAVOR`
- `BOOT_MODE`
- `CODEX_INSTALL_METHOD`
- `STAGE3_MIRROR`
- `STAGE3_CACHE_DIR`
- `PORTAGE_GENTOO_MIRRORS`
- `TIMEZONE`
- `LOCALE`
- `KEYMAP`
- `ADMIN_USER`
- `ADMIN_GROUPS`
- `ADMIN_SHELL`
- `PRIVILEGE_TOOL`
- `ADMIN_SUDO_NOPASSWD`
- `ADMIN_AUTHORIZED_KEYS_FILE`
- `ADMIN_PASSWORD_HASH_FILE`
- `ROOT_PASSWORD_HASH_FILE`
- `I_UNDERSTAND_BOOTLOADER_CHANGES`
- `I_UNDERSTAND_THIS_WIPES_DISK`
- `MANUAL_STEP_SUMMARY`
- `MANUAL_STEP_REASON`
- `MANUAL_STEP_NEXT_ACTION`
- `REAL_HARDWARE_BACKUPS_CONFIRMED`
- `REAL_HARDWARE_UEFI_CONFIRMED`
- `REAL_HARDWARE_NETWORK_CONFIRMED`
- `REAL_HARDWARE_POWER_CONFIRMED`
- `REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED`
- `REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED`
- `REAL_HARDWARE_LIBVIRT_VALIDATED`
- `REAL_HARDWARE_LIBVIRT_SKIP_REASON`

VM/libvirt variables:

- `LIBVIRT_URI`
- `VM_NET_MODE`
- `VM_NAME`
- `VM_TEST_IMAGE_NAME`
- `VM_ISO`
- `VM_DIR`
- `VM_DISK`
- `VM_DISK_SIZE`
- `VM_RAM`
- `VM_CPUS`
- `VM_NETWORK`
- `VM_SSH_HOST`
- `VM_SSH_HOST_PORT`
- `VM_SSH_GUEST_PORT`
- `VM_SSH_USER`
- `VM_BOOT_MODE`
- `VM_TEST_MATRIX_LOG_DIR`
- `VM_TEST_MATRIX_INSTALL_DISK`
- `VM_TEST_MATRIX_RUN_TARGET_PLANS`
- `VM_E2E_RESET_DISK`
- `VM_E2E_ADMIN_SUDO_NOPASSWD`

Ansible live target variables:

- `ANSIBLE_LIVE_HOST`
- `ANSIBLE_LIVE_PORT`
- `ANSIBLE_LIVE_USER`
- `ANSIBLE_SSH_CONNECT_TIMEOUT`
- `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL`
- `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX`
- `ANSIBLE_SSH_CONTROL_MASTER`
- `ANSIBLE_SSH_CONTROL_PERSIST`
- `ANSIBLE_SSH_CONTROL_PATH_DIR`

Recommended defaults:

- `HOSTNAME=gentoo`
- `PROFILE=openrc`
- `FILESYSTEM=ext4`
- `STAGE3_FLAVOR=standard`
- `BOOT_MODE=uefi`
- `CODEX_INSTALL_METHOD=npm`
- `STAGE3_MIRROR=https://distfiles.gentoo.org/releases/amd64/autobuilds`
- `STAGE3_CACHE_DIR=/tmp/gentoo-ai-installer/stage3`
- `PORTAGE_GENTOO_MIRRORS=https://distfiles.gentoo.org`
- `TIMEZONE=UTC`
- `LOCALE=en_US.UTF-8`
- `KEYMAP=us`
- `ADMIN_GROUPS=wheel`
- `ADMIN_SHELL=/bin/bash`
- `PRIVILEGE_TOOL=sudo`

Recommended VM/libvirt defaults:

- `LIBVIRT_URI=qemu:///system`
- `VM_NET_MODE=network`
- `VM_NAME=gentoo-test` as the base name; VM targets derive `gentoo-test[-VM_TEST_IMAGE_NAME]-amd64-<profile>-<filesystem>[-<stage3-flavor>]`.
- `VM_TEST_IMAGE_NAME` empty by default; optional conservative label for the manual test image or test line.
- `VM_ISO=gentoo.iso`
- `VM_DIR=var/libvirt`
- `VM_DISK=$(VM_DIR)/gentoo-test.qcow2` as a compatibility default; VM targets derive a case-specific disk when this default is not overridden.
- `VM_DISK_SIZE=40G`
- `VM_RAM=4096`
- `VM_CPUS=2`
- `VM_NETWORK=default`
- `VM_SSH_HOST=127.0.0.1`
- `VM_SSH_HOST_PORT=2222`
- `VM_SSH_GUEST_PORT=22`
- `VM_SSH_USER=root`
- `VM_BOOT_MODE=uefi`
- `VM_TEST_MATRIX_LOG_DIR=logs/libvirt-matrix`
- `VM_TEST_MATRIX_INSTALL_DISK=/dev/vda`
- `VM_TEST_MATRIX_RUN_TARGET_PLANS=no`
- `VM_E2E_RESET_DISK=no`
- `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`

Recommended Ansible live target defaults:

- `ANSIBLE_LIVE_HOST` has no default; if omitted, current wrapper targets may discover the configured local libvirt VM for testing.
- `ANSIBLE_LIVE_PORT=22`
- `ANSIBLE_LIVE_USER=root`
- `ANSIBLE_SSH_CONNECT_TIMEOUT=10`
- `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL=30`
- `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX=6`
- `ANSIBLE_SSH_CONTROL_MASTER=auto`
- `ANSIBLE_SSH_CONTROL_PERSIST=10m`
- `ANSIBLE_SSH_CONTROL_PATH_DIR=var/ssh-control`

Rules:

- `INSTALL_DISK` must not have a default value.
- `I_UNDERSTAND_THIS_WIPES_DISK` must not default to `yes`.
- Destructive targets must require `INSTALL_DISK` to be set explicitly.
- Destructive targets must require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Disk variables must not use wildcard matching, parent traversal, whitespace, shell metacharacters, or values that can inject additional Ansible extra variables.
- Disk selection must not use a fallback such as the first disk from `lsblk`.
- Variable names should be uppercase for operator-provided inputs.
- `PROFILE=openrc` should map to Ansible `init_system=openrc`.
- `PROFILE=systemd` should map to Ansible `init_system=systemd`.
- `FILESYSTEM=ext4` should map to the ext4 root layout.
- `FILESYSTEM=btrfs` should map to the Btrfs root layout with planned subvolumes; it must not create a filesystem or subvolumes in read-only planning targets.
- `STAGE3_FLAVOR=standard|hardened|musl` should select the official stage3 metadata and matching Portage profile family without changing disk safety gates.
- `STAGE3_MIRROR` must be an HTTPS Gentoo stage3 metadata base URL; mirror overrides must not bypass verification.
- `STAGE3_CACHE_DIR` must be a live-ISO-local absolute path outside `TARGET_MOUNT`.
- `PORTAGE_GENTOO_MIRRORS` must be an HTTPS Gentoo distfiles mirror URL written to target `make.conf`; v1 treats it as a single URL value.
- `TIMEZONE` must be a relative target zoneinfo path such as `UTC` or `Europe/Stockholm`.
- `LOCALE` must be a UTF-8 locale such as `en_US.UTF-8`.
- `KEYMAP` must be a simple console keymap name such as `us`.
- `ADMIN_USER` must have no useful default for user-creation workflows; `make configure-users` must require it explicitly.
- `ADMIN_SUDO_NOPASSWD` is treated as `no` for normal installs unless explicitly set to `yes`; disposable libvirt E2E installs may default it through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`.
- `ADMIN_PASSWORD_HASH_FILE`, `ROOT_PASSWORD_HASH_FILE`, and `ADMIN_AUTHORIZED_KEYS_FILE` are local input file paths only. The Makefile may report whether they are set, but it must not print their contents.
- `I_UNDERSTAND_BOOTLOADER_CHANGES=yes` is required for GRUB/EFI workflows that may update persistent EFI boot entries.
- `MANUAL_STEP_SUMMARY` and `MANUAL_STEP_REASON` are required only for `make record-manual-step`; they must describe non-secret operator intervention and should not be printed by help output.
- `MANUAL_STEP_NEXT_ACTION` may override the default revalidation instruction for `make record-manual-step`; it must remain non-secret and should point back to Makefile-mediated checks or plans.
- `REAL_HARDWARE_*` acknowledgement variables default to `no` or unset; `make real-hardware-check` requires them before physical-machine destructive workflows are recommended.
- Variables containing secrets must not be printed or committed.
- `VM_DISK` must be a project-relative qcow2 path under `VM_DIR`.
- `VM_TEST_IMAGE_NAME`, when set, must be a conservative label, not a path or secret; it may be inserted into generated VM domain, qcow2, log, and state names for manual validation images.
- `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR` are the source of truth for local libvirt case selection; Makefile VM targets must not require operators to construct full case VM names manually.
- `make vm-list-cases` must remain read-only and show generated domain, disk, state, log, and status for every supported amd64 profile/filesystem/stage3 flavor case.
- `VM_DIR` must not be the project root, `/dev`, absolute, symlinked, or contain parent traversal.
- `VM_BOOT_MODE=bios` must be rejected in v1.
- `ANSIBLE_LIVE_HOST` must not default to a VM IP or a physical host.
- When `ANSIBLE_LIVE_HOST` is set, Ansible targets must use it as the network-reachable official live ISO target instead of requiring libvirt discovery.
- When `ANSIBLE_LIVE_HOST` is empty, VM/libvirt discovery is allowed only for local testing.
- Ansible SSH wrapper targets must build SSH transport options through the shared wrapper helper rather than duplicating raw `--ssh-common-args`.
- `ANSIBLE_SSH_CONTROL_PATH_DIR` must be project-relative, ignored by git, and must not be a symlink, the project root, `/dev`, or contain parent traversal.
- Documentation for long-running Ansible install targets should recommend running the controller-side Makefile command inside `tmux` or `screen`.
- `local-*` Ansible targets run inside the official Gentoo live ISO with `ansible_connection=local`; they are fallback/diagnostic targets and must not replace the primary SSH/network workflow.
- Local Ansible targets must not disable host-key checking globally, because they do not use SSH to the live ISO.
- `VM_NETWORK` is required only when `VM_NET_MODE=network`.
- `VM_RAM`, `VM_CPUS`, ports, and `VM_DISK_SIZE` must be validated before generated XML or disk creation uses them.
- VM definitions should pass serial console kernel args so `make vm-console` is usable with the official live ISO.
- `VM_TEST_MATRIX_INSTALL_DISK=/dev/vda` is allowed only inside the disposable libvirt matrix guest plan.
- `VM_TEST_MATRIX_RUN_TARGET_PLANS=yes` may run read-only Ansible plan targets after the live ISO VM is booted and SSH-enabled; it must not run destructive install steps.
- `VM_E2E_RESET_DISK=yes` may reset generated VM artifacts only when `I_UNDERSTAND_CLEANUP_DELETE=DELETE` is also provided.

## 6. Safe Targets
Safe targets are read-only, validation-only, or local evidence writers. They must not modify disks, target root, boot entries, users, passwords, or services.

The target lists below define the project control-plane contract. A target is available only when it exists in the current `Makefile`; otherwise treat it as planned and do not present it in `README.md` as runnable.

Required safe targets:

- `make help`
- `make preflight`
- `make detect-disks`
- `make openspec-list`
- `make openspec-validate`
- `make ansible-check`
- `make config-check`
- `make host-check`
- `make handbook-trace`
- `make real-hardware-check`
- `make release-check`
- `make ansible-live-ping`
- `make ansible-live-preflight`
- `make install-plan`
- `make partition-plan`
- `make mount-plan`
- `make filesystem-plan`
- `make destructive-preview`
- `make partition-preview`
- `make format-preview`
- `make mount-preview`
- `make bootloader-preview`
- `make users-preview`
- `make destructive-safety-check`
- `make final-checks`
- `make install-state`
- `make install-resume-plan`
- `make record-manual-step`
- `make install-audit`
- `make install-report`
- `make cleanup-plan`
- `make clean-state`
- `make clean-logs`
- `make clean-audit`
- `make clean-stage3-cache`
- `make reset-test-run`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`
- `make vm-list-cases`
- `make vm-check`
- `make vm-e2e-plan`
- `make vm-test-matrix-plan`

Expected behavior:

- `make help`: list targets, variables, and risk level.
- `make preflight`: show live ISO state, architecture, boot mode, network, time, mounts, and required tools.
- `make detect-disks`: show disk path, model, serial, size, transport, current partitions, and mount state.
- `make openspec-list`: list OpenSpec changes.
- `make openspec-validate`: validate OpenSpec changes.
- `make ansible-check`: validate Ansible availability, syntax-check implemented playbooks, and run ansible-lint when available.
- `make config-check`: validate `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, `BOOT_MODE`, `HOSTNAME`, mount paths, optional `INSTALL_DISK`, and destructive confirmation variables without touching live targets or disks.
- `make handbook-trace`: regenerate the read-only Gentoo AMD64 Handbook traceability report from project metadata.
- `make real-hardware-check`: run config validation with explicit `INSTALL_DISK`, record a local read-only physical-machine readiness report, and require backup/UEFI/network/power/recovery-media/preview/libvirt-validation acknowledgements without granting destructive permission.
- `make release-check`: run local non-destructive release readiness checks for docs, OpenSpec validation, Ansible syntax/lint, secrets, tracked artifacts, and guardrail status.
- `make ansible-live-ping`: validate SSH-based Ansible connectivity to the booted official live ISO target. It should use `ANSIBLE_LIVE_HOST` for network targets and libvirt discovery only for local tests.
- `make ansible-live-preflight`: run read-only live ISO checks without selecting an install disk or mutating target disks.
- `make host-check`: validate controller-side host requirements for local libvirt workflows, including tools, resources, OVMF firmware, ISO availability, libvirt access, safe VM paths, and project-owned domain metadata. It must remain read-only and must not fail merely because the selected project-owned domain is currently in installed-disk boot mode.
- `make local-live-preflight`: optional fallback target run inside the official live ISO with `ansible_connection=local`.
- `make local-detect-disks`: optional fallback read-only disk detection target run inside the official live ISO.
- `make local-install-plan`: optional fallback read-only install plan target run inside the official live ISO.
- `make local-partition-plan`: optional fallback read-only partition plan target run inside the official live ISO; it still requires explicit `INSTALL_DISK`.
- `make install-plan`: summarize intended install flow without making changes; default `PROFILE=openrc`, `FILESYSTEM=ext4`, and `STAGE3_FLAVOR=standard`, but never default `INSTALL_DISK`.
- `make partition-plan`: require explicit `INSTALL_DISK` and summarize the exact GPT partition layout without writing.
- `make mount-plan`: require explicit `INSTALL_DISK` and summarize the future root and EFI mount layout without running `mount`, `umount`, or `mkdir`.
- `make filesystem-plan`: require explicit `INSTALL_DISK` and summarize the future EFI/root filesystem creation plan without running `mkfs.*`, `wipefs`, `mount`, `umount`, or `mkdir`.
- `make destructive-preview`: dispatch to a read-only preview for `PREVIEW_TARGET=partition|format|mount|bootloader|users` without setting confirmation variables.
- `make partition-preview`: reuse the partition plan as the destructive partition preview.
- `make format-preview`: reuse the filesystem plan as the destructive filesystem preview.
- `make mount-preview`: reuse the mount plan as the mount-over preview before `make mount-target`.
- `make bootloader-preview`: show target disk, EFI mountpoint, current EFI boot entries when readable, planned GRUB steps, and required bootloader confirmation without changing EFI state.
- `make users-preview`: show planned admin user, group, sudo, password-hash, authorized_keys, and SSH policy changes without printing secrets or writing the target root.
- `make destructive-safety-check`: require explicit `INSTALL_DISK` and `I_UNDERSTAND_THIS_WIPES_DISK=yes`, then run the shared read-only disk safety role without mutating disks.
- `make final-checks`: require explicit `ADMIN_USER`, run read-only reboot readiness checks, write a secret-safe local report, and never reboot automatically.
- `make install-state`: print the current non-secret install state summary from `var/state/current-install.json`.
- `make install-resume-plan`: read saved install state, reject secret-like state content, and validate current live ISO disk/profile/filesystem/stage3 flavor facts without resuming or satisfying destructive confirmations.
- `make record-manual-step`: record a non-secret manual intervention note under `logs/install-runs/<run-id>/manual-steps/`, mark current state as requiring revalidation, and require `MANUAL_STEP_SUMMARY` plus `MANUAL_STEP_REASON`.
- `make install-audit`: generate a secret-scanned local audit bundle under `logs/install-runs/<run-id>/audit-bundle/` from the current install state.
- `make install-report`: generate a human-readable, secret-safe Markdown summary under `logs/install-runs/<run-id>/install-report.md` from current state and evidence.
- `make cleanup-plan`: print cleanup candidates for `CLEAN_SCOPE=state|logs|audit|stage3-cache|test-run` without deleting.
- `make clean-state`: delete only the configured install state pointer after `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- `make clean-logs`: delete non-audit logs for the current run or `CLEAN_RUN_ID` after confirmation; preserve `audit-bundle/`.
- `make clean-audit`: delete only the selected run's `audit-bundle/` after confirmation.
- `make clean-stage3-cache`: delete only approved target-local `STAGE3_CACHE_DIR` paths under `/tmp/gentoo-ai-installer/` over Ansible against the live ISO target.
- `make reset-test-run`: delete the configured state file and non-audit logs for the selected run after confirmation.
- `make install-run-clean`: delete only the current state pointer after `I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE`; it must not delete run logs or target filesystems.
- `make format`: require explicit `INSTALL_DISK` and `I_UNDERSTAND_THIS_WIPES_DISK=yes`, then create only the approved ESP/root filesystems for `FILESYSTEM=ext4` or `FILESYSTEM=btrfs` after printing a destructive preview.
- `make mount-target`: require explicit `INSTALL_DISK`, reuse the approved mount/filesystem plans, mount only `/mnt/gentoo` and `/mnt/gentoo/boot/efi`, and validate existing mounts for idempotency.
- `make stage3-install`: download, verify, and extract official Gentoo stage3 for `PROFILE` and `STAGE3_FLAVOR` into verified `/mnt/gentoo` without chrooting or configuring Portage.
- `make install-plan PROFILE=openrc`: summarize the planned OpenRC flow through the shared Ansible install path.
- `make install-plan PROFILE=systemd`: summarize the planned systemd flow through the shared Ansible install path.
- `make vm-list-cases`: read-only listing of amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl local libvirt case domains, disks, state paths, logs, ports, and current domain status.
- `make vm-check`: read-only validation of libvirt tools, ISO resolution, UEFI firmware, network mode, and safe project-local paths.
- `make vm-e2e-plan`: plan a full disposable libvirt install validation, require explicit `/dev/vda`, `ADMIN_USER`, and `ENABLE_SSH=yes`, integrate matrix planning, and avoid VM mutation.
- `make vm-test-matrix-plan`: enumerate OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl libvirt validation entries, validate each entry's configuration, write local matrix evidence, and avoid creating disks or domains.

## 7. Semi-dangerous Targets
Semi-dangerous and high-risk target-root targets may modify the live ISO environment or the mounted target root, but they must not partition, format, wipe, overwrite disks, install bootloaders, or reboot unless they are listed as destructive targets. User and password workflows are high-risk persistent target-root changes and require secret-safe input handling instead of disk-wipe confirmation.

Semi-dangerous targets:

- `make bootstrap-codex`
- `make prepare-live-env`
- `make download-stage3`
- `make mount-target`
- `make stage3-install`
- `make prepare-chroot`
- `make configure-portage`
- `make configure-system`
- `make generate-fstab`
- `make install-kernel`
- `make install-system-packages`
- `make install-base-packages`
- `make configure-users`
- `make vm-disk`
- `make vm-define`
- `make vm-start`
- `make vm-start-installed`
- `make vm-validate-first-boot`
- `make vm-e2e-install`
- `make vm-console`
- `make vm-viewer`
- `make vm-ip`
- `make vm-bootstrap-ssh`
- `make vm-ssh`
- `make vm-rsync`
- `make vm-ansible-ping`
- `make vm-shutdown`
- `make vm-destroy`
- `make vm-clean`

Expected behavior:

- `make bootstrap-codex`: install Codex temporarily in the live ISO using `CODEX_INSTALL_METHOD`.
- `make prepare-live-env`: install or verify temporary live-session dependencies only.
- `make download-stage3`: download the official amd64 stage3 and verification metadata for the selected `PROFILE` and `STAGE3_FLAVOR` without extracting over existing data.
- `make verify-stage3`: verify checksum and signature policy from `docs/stage3-signature-policy.md` before any extraction target can run.
- `make stage3-install`: use `STAGE3_MIRROR` and `STAGE3_CACHE_DIR`, verify official metadata and SHA512/signatures, then extract only into mounted `/mnt/gentoo`.
- `make mount-target`: mount explicitly provided partitions to explicitly provided target paths after mount-state checks; for Btrfs it must mount root with `subvol=@` and the approved subvolumes from `docs/btrfs-layout-policy.md`.
- `make prepare-chroot`: require mounted `/mnt/gentoo` with extracted stage3 markers, mount or verify pseudo-filesystems only under `/mnt/gentoo`, prepare target DNS, validate DNS with a read-only chroot lookup, and print before/after mount state.
- `make configure-portage`: manage conservative target `make.conf`, install official Gentoo repo configuration, run official Gentoo repo sync, select the matching OpenRC/systemd profile from variant variables, keep GURU disabled, report pending config updates, and skip broad `@world`.
- `make configure-system`: configure target hostname, timezone, UTF-8 locale, and OpenRC/systemd console keymap files under `/mnt/gentoo`; generate the locale and refresh target env only when locale files change.
- `make generate-fstab`: require explicit `INSTALL_DISK`, verify mounted target filesystems and UUIDs, and write only `/mnt/gentoo/etc/fstab` with ext4 or approved Btrfs subvolume entries plus `/boot/efi`.
- `make install-kernel`: require prepared `/mnt/gentoo`, prepared chroot pseudo-filesystems, mounted `/mnt/gentoo/boot/efi`, and generated fstab; install `gentoo-kernel-bin` with installkernel/dracut support; write target kernel command-line input; validate `/boot` artifacts; and avoid GRUB or EFI boot-entry changes.
- `make install-system-packages`: require prepared `/mnt/gentoo` and chroot pseudo-filesystems; install the minimal console package set; apply conservative package USE policy; enable services through init-specific roles; and avoid users, passwords, GRUB, EFI boot entries, disk partitioning, formatting, and reboot.
- `make install-base-packages`: compatibility alias for `make install-system-packages` when present.
- `make configure-users`: require explicit `ADMIN_USER`, prepared `/mnt/gentoo`, installed sudo tooling, and secret-safe optional file inputs; configure the admin user, sudo policy including optional `ADMIN_SUDO_NOPASSWD=yes`, optional password hashes, optional authorized keys, and installed SSH root-login restrictions without printing secret values.
- `make vm-disk`: create or preserve the project-local qcow2 VM disk.
- `make vm-define`: define the project-owned libvirt domain from reviewed project-local inputs.
- `make vm-start`: start the project-owned VM from the official Gentoo live ISO.
- `make vm-start-installed`: redefine and start the project-owned VM from the installed qcow2 disk without live ISO kernel/initrd boot.
- `make vm-validate-first-boot`: boot the installed VM disk, wait for SSH, and run read-only first-boot validation; it requires completed install state and explicit `ADMIN_USER`.
- `make vm-e2e-install`: run the full disposable libvirt install validation sequence. It is destructive inside the VM qcow2 disk, requires explicit `/dev/vda`, `ADMIN_USER`, `ENABLE_SSH=yes`, wipe confirmation, bootloader confirmation, and optional cleanup confirmation when resetting artifacts. It may default `ADMIN_SUDO_NOPASSWD=yes` through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes` so SSH-key-only test admins can run `sudo su -`.
- `make vm-console`: attach to `virsh console`; it may fail if the ISO does not expose a serial login.
- `make vm-viewer`: open graphical access through a libvirt viewer.
- `make vm-ip`: discover the guest IP only when the configured network mode supports discovery.
- `make vm-bootstrap-ssh`: use the serial console to install a public SSH key into the temporary live ISO and start `sshd`.
- `make vm-ssh`: connect after the operator enables SSH inside the live ISO.
- `make vm-rsync`: copy non-secret project files after SSH is available; filters must exclude `.env`, private key patterns, token/credential files, ISO artifacts, runtime artifacts, logs, and temporary files.
- `make vm-ansible-ping`: validate Ansible SSH connectivity to the local libvirt live ISO test target without configuring Gentoo.
- `make vm-shutdown`: request guest shutdown.
- `make vm-destroy`: stop the configured project-owned domain without deleting artifacts.
- `make vm-clean`: undefine the selected project-owned case domain and delete generated VM artifacts only when `I_UNDERSTAND_CLEANUP_DELETE=DELETE` is set.

`make mount-target` is destructive-adjacent because mounting over a wrong path can hide data. It must print current mounts, refuse unrelated existing mounts, remain idempotent for already-correct mounts, and fail closed when ambiguity exists.

`make prepare-chroot` is destructive-adjacent because it creates bind/pseudo-filesystem mounts and writes target resolver configuration under `/mnt/gentoo`. It must refuse target roots other than `/mnt/gentoo`, never mount outside the target root, avoid arbitrary chroot execution, and remain idempotent for already-correct mounts.

`make configure-portage` is target-mutating because it writes Portage configuration, syncs repository metadata, and changes profile selection in the mounted target root. It must require prepared `/mnt/gentoo`, use variant variables for profile selection, avoid overlays unless approved, and never run `emerge @world` by default.

`make configure-system` is target-mutating because it writes identity and locale files under `/mnt/gentoo`. It must refuse target roots other than `/mnt/gentoo`, validate hostname/timezone/locale/keymap inputs, avoid changing the live ISO hostname, and record evidence for final checks and install reports.

`make generate-fstab` is target-mutating because it writes `/mnt/gentoo/etc/fstab`. It must require explicit `INSTALL_DISK`, refuse target roots other than `/mnt/gentoo`, validate root and EFI UUIDs, preserve a backup of an existing fstab, and keep Btrfs entries aligned with `docs/btrfs-layout-policy.md`.

`make configure-users` is high-risk persistent target-root work because it creates users, changes group membership, configures sudo, may enable passwordless sudo, may apply password hashes, and may install SSH authorized keys. It must reject missing `ADMIN_USER`, reject git-tracked secret input files, treat password and key contents as `no_log`, enforce installed SSH root-login policy when SSH is enabled, validate `ADMIN_SUDO_NOPASSWD=yes|no`, and write only non-secret audit evidence.

Future destructive targets should print or call a read-only preview before accepting confirmation. Preview output must not set `I_UNDERSTAND_THIS_WIPES_DISK=yes` or any equivalent confirmation.

VM targets are not allowed to touch host block devices. They must reject `/dev/*`, absolute VM disk paths, parent traversal, wildcard paths, symlinked artifact directories, non-qcow2 existing disk files, project-root artifact directories, and project root paths that would make generated libvirt XML unsafe. Existing libvirt domains with the configured effective case name must be rejected for start, SSH, rsync, Ansible, and inspection unless they are project-owned, UEFI-configured, and match the configured official ISO plus generated artifacts for disk, NVRAM, kernel, initrd, artifact directory, and selected case metadata. Cleanup must require `I_UNDERSTAND_CLEANUP_DELETE=DELETE` and delete only validated artifacts for the selected case. Legacy `qemu-*` targets may exist only as compatibility aliases to `vm-*` targets.

## 8. Destructive Targets
Destructive targets can destroy data, alter boot behavior, or perform broad persistent changes. They require strict gates.

Destructive targets:

- `make partition`
- `make format`
- `make install`
- `make install-bootloader`
- `make install-openrc`
- `make install-systemd`

Required behavior:

- Require `INSTALL_DISK` set explicitly.
- Require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Run a safety confirmation script.
- Print disk model, serial, size, and current partitions.
- Use no default disk.
- `make partition` may write the GPT layout only.
- `make format` may create vfat plus ext4 or Btrfs filesystems only; Btrfs must use the shared subvolume policy and clean up its temporary setup mount.
- Use no wildcard disk matching.
- Stop if disk identity is ambiguous.
- Stop if the disk differs from the plan output.
- Stop if required confirmations are missing.
- OpenRC and systemd install targets must call shared safety gates before variant-specific roles run.
- `make partition` must partition only; it must not format, mount, chroot, install packages, or install bootloaders.
- `make install-bootloader` must require explicit `INSTALL_DISK` and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`; show disk identity and current EFI entries; install GRUB for UEFI; generate `grub.cfg`; validate the boot command line; and avoid partitioning, formatting, wiping, user changes, or reboot.
- `make install`, `make install-openrc`, and `make install-systemd` must run the shared basic-console Ansible flow rather than duplicating OpenRC/systemd command chains; they require explicit `INSTALL_DISK`, `ADMIN_USER`, `I_UNDERSTAND_THIS_WIPES_DISK=yes`, and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

`make install-bootloader` may not wipe disks, but it changes persistent boot state and must use the same seriousness as destructive targets. It must use `/mnt/gentoo/boot/efi` as the live ISO path and `/boot/efi` inside chroot, and record bootloader evidence.

## 9. Required Confirmations
Before destructive or persistent-risk targets run:

- `INSTALL_DISK` must be provided by the operator.
- `I_UNDERSTAND_THIS_WIPES_DISK=yes` must be present for disk-wiping, partitioning, formatting, or install flows that include them.
- A safety confirmation script must display the disk summary and require deliberate operator acknowledgement.
- The target must print the final variables it will use.
- The target must print the exact disk or path affected.
- The target must stop on empty variables.
- The target must stop on wildcard patterns.
- The target must stop if the selected disk has changed since the plan target.

Confirmation values must not be inferred from defaults.

## 10. Target Naming Rules
Good target names:

- Are short but explicit.
- Describe the action and risk.
- Separate plan and apply phases.
- Use verbs when useful.
- Avoid bundling unrelated operations.

Rules:

- Use `*-plan` for read-only planning targets.
- Use `*-check` for validation targets.
- Use destructive names plainly: `partition`, `format`, `install-bootloader`.
- Avoid names that hide risk, such as `setup`, `init`, `do-it`, `fix`, or `install-all`.
- Avoid one target that performs disk partitioning, formatting, stage3 extraction, bootloader install, and reboot without visible checkpoints.

## 11. Examples of Good Targets
- `make help`
- `make preflight`
- `make detect-disks`
- `make install-plan`
- `make partition-plan INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk>`
- `make partition INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `make format INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk> I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `make bootstrap-codex CODEX_INSTALL_METHOD=npm`
- `make openspec-validate`
- `make ansible-check`
- `make ansible-live-ping`
- `make ansible-live-preflight`
- `make real-hardware-check ANSIBLE_LIVE_HOST=<live-iso-ip> INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk>`
- `make release-check`
- `make ansible-dry-run PROFILE=openrc`
- `make ansible-dry-run PROFILE=systemd`
- `make vm-check`
- `make vm-e2e-plan`
- `make vm-disk`
- `make vm-start`
- `make vm-ssh`
- `make vm-clean`
- `make vm-test-matrix-plan`
- `make final-checks`
- `make record-manual-step MANUAL_STEP_SUMMARY="Reviewed target state" MANUAL_STEP_REASON="Automation paused for manual inspection"`

## 12. Examples of Bad Targets
- `make setup`
- `make install-all`
- `make wipe`
- `make fix`
- `make partition INSTALL_DISK=/dev/sda` when `/dev/sda` was not explicitly confirmed by the operator.
- `make partition` with a default disk.
- `make install` that partitions and formats without printing disk identity.
- `make clean` that runs broad recursive deletion without path validation.
- `make bootstrap-codex` that writes secrets into the repository.
- `make ansible-run` that hides which playbook and tags will run.
- `make qemu-boot` that invokes `qemu-system-x86_64` directly instead of aliasing the active libvirt workflow.
- `make vm-clean` that deletes every `.qcow2` or `.fd` file under an artifact directory instead of only generated files for the configured domain.
- Separate long `make install-openrc` and `make install-systemd` recipes that duplicate the same Ansible command chain instead of passing variant variables into a shared flow.

## 13. Failure Modes
- The operator bypasses the Makefile and runs raw commands from documentation.
- `INSTALL_DISK` is accidentally defaulted.
- A target selects the first detected disk automatically.
- A target uses wildcard disk matching.
- A destructive target lacks `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- A destructive target does not print disk summary output.
- A target combines unrelated risk classes.
- Manual intervention is performed but not recorded with `make record-manual-step` before automation resumes.
- Manual notes include secrets or command transcripts with credentials.
- Physical-machine destructive workflows are recommended without a successful `make real-hardware-check`.
- Matrix validation skips supported OpenRC/systemd or ext4/Btrfs combinations, or accidentally creates/deletes VM artifacts in the plan target.
- End-to-end VM validation runs without explicit `/dev/vda`, admin user, `ENABLE_SSH=yes`, wipe confirmation, or bootloader confirmation.
- Release readiness passes while required docs are missing, local artifacts are tracked, or OpenSpec strict validation fails.
- A cleanup target deletes an unchecked path.
- An Ansible target runs without showing check/plan output first.
- Codex bootstrap stores tokens in tracked files.
- A VM target defines, destroys, or cleans an unrelated libvirt domain with the same name.
- `vm-check` creates artifact directories even though it is documented as read-only.
- `vm-disk` creates a disk outside `VM_DIR`.
- `vm-clean` deletes operator-provided ISO, firmware, qcow2, or secret files.

## 14. Recovery Advice
- Replace raw command instructions with make targets.
- Split broad targets into detect, plan, confirm, and apply targets.
- Remove any default value for `INSTALL_DISK`.
- Add explicit assertions for required variables.
- Add disk summary output before destructive work.
- Add a safety confirmation script before destructive targets.
- Add `make install-plan` or `make partition-plan` before apply targets.
- Record non-secret manual recovery notes with `make record-manual-step`, then rerun `make install-resume-plan` and the relevant read-only plan before continuing.
- Run `make real-hardware-check` before destructive physical-machine workflows and prefer `/dev/disk/by-id/...` for `INSTALL_DISK`.
- Stop and rerun safe inventory targets if disk identity changes.
- Review dangerous targets with `agents/safety-review-agent.md` before use.
- If secrets are written to project files, remove them immediately and keep them out of commits.
- If a VM/libvirt target fails, run `make vm-check` first and verify `virsh`, `qemu-img`, UEFI firmware, ISO location, `LIBVIRT_URI`, and network mode.
- If `vm-ssh` fails, verify SSH has been enabled inside the official live ISO and that the configured forwarded port is reachable.
- If cleanup is needed, use `make vm-clean` and confirm that the printed generated artifact list contains only the configured disk, XML, NVRAM, and logs.

## Documentation maintenance
When Makefile behavior changes, documentation must change in the same commit or OpenSpec implementation step.

- Every new, changed, or removed operator-facing target must be reflected in the Makefile `help` output and in `README.md` or a relevant file under `docs/`.
- Every target documented in `README.md`, `docs/`, `skills/`, or OpenSpec specs must match an actual Makefile target or be clearly labeled as planned.
- Required variables must be documented with their defaults. If no default is allowed, such as `INSTALL_DISK`, the documentation must explicitly say so.
- Destructive targets must document required confirmation variables, the safety confirmation script, disk summary output, forbidden defaults, and forbidden wildcard disk matching.
- Semi-dangerous targets must document what paths or live-environment state they may change.
- If target names, variable names, defaults, or confirmation values change, update this skill, `README.md` or `docs/`, and the active OpenSpec `tasks.md`.
- If VM/libvirt targets change, update `docs/libvirt-manual-install-test.md`, any QEMU migration note, and active OpenSpec tasks. Document ISO path, qcow2 path, libvirt URI, network mode, serial console, SSH bootstrap, guest `/dev/vda`, Ansible connectivity validation, and cleanup behavior.
- If VM test matrix targets change, update `docs/libvirt-install-test-matrix.md`, `docs/libvirt-manual-install-test.md`, this skill, and active OpenSpec tasks. Document matrix entries, optional manual test image labels, generated domain/disk names, logs, and which phases are implemented.
- If VM end-to-end validation changes, update `docs/libvirt-end-to-end-install-validation.md`, `docs/libvirt-manual-install-test.md`, `docs/libvirt-install-test-matrix.md`, this skill, safety review rules, and active OpenSpec tasks. Document confirmations, logs, audit references, and first-boot expectations.
- If release readiness behavior changes, update `docs/release-readiness.md`, README, this skill, and active OpenSpec tasks together.
- If host requirement checks change, update `docs/supported-host-requirements.md`, `docs/libvirt-manual-install-test.md`, `docs/install-configuration.md`, and active OpenSpec tasks.
- If live ISO Ansible preflight targets change, update `docs/ansible-live-preflight.md`, `docs/libvirt-manual-install-test.md`, `skills/ansible-gentoo-installer.md`, and the active OpenSpec tasks.
- If local live ISO Ansible fallback targets change, update `docs/live-iso-local-ansible.md`, `docs/ansible-live-preflight.md`, `skills/ansible-gentoo-installer.md`, and the active OpenSpec tasks. Keep network Ansible documented as the primary product path.
- If read-only Ansible disk detection or install-plan targets change, update `docs/ansible-install-plan.md`, `skills/ansible-gentoo-installer.md`, `skills/gentoo-disk-planning.md`, and the active OpenSpec tasks.
- If read-only partition-plan targets change, update `docs/ansible-partition-plan.md`, disk-planning skills, safety docs, and active OpenSpec tasks.
- If `make ansible-check` behavior changes, update Ansible docs, `.ansible-lint` expectations, `skills/ansible-gentoo-installer.md`, and active OpenSpec tasks.
- If `FILESYSTEM` behavior changes, update target help, variable defaults, install-plan docs, disk-planning docs, and safety notes in the same change.
- If failure modes or recovery behavior changes in implementation, update the `Failure Modes` and `Recovery Advice` sections here before finishing.
- If manual intervention, resume-state, or audit evidence behavior changes, update `docs/manual-escape-hatch-policy.md`, `docs/install-state-and-resume-checkpoints.md`, `docs/install-audit-bundle.md`, this skill, and active OpenSpec tasks together.
- If real hardware readiness behavior changes, update `docs/real-hardware-readiness.md`, safety docs, this skill, `agents/safety-review-agent.md`, and active OpenSpec tasks together.
