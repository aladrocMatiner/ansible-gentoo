# Ansible Gentoo Installer Skill

## 1. Purpose
This skill describes how `gentoo-ai-installer` should build the phase-2 Ansible-based Gentoo installer with reuse-first OpenRC and systemd support.

Phase 1 is manual installation with Codex assistance. Phase 2 creates a reproducible installer using Ansible from an operator/controller machine against a network-reachable target booted into the official Gentoo live ISO. The Makefile controls all operator-facing commands.

The local libvirt VM and remote Proxmox VMs are validation harnesses for the same Ansible workflows. They are not the final product architecture.

This skill defines standards for future Ansible implementation. It does not implement playbooks.

## 2. When to Use This Skill
Use this skill:

- When creating or reviewing phase-2 Ansible design.
- When translating validated phase-1 manual steps into roles.
- When adding Ansible inventories, variables, playbooks, or roles.
- When defining Makefile targets that wrap Ansible.
- When reviewing safety gates, dry-run behavior, idempotency, or logging.
- When adding or changing the read-only live ISO Ansible preflight used before installer automation.
- When deciding whether behavior belongs in reusable Ansible roles or only in the VM validation harnesses.
- When adding or changing read-only disk detection or install-plan behavior.
- When adding optional post-install Ansible profiles that run against an already installed Gentoo system over SSH.

Do not use this skill to bypass OpenSpec or safety review for destructive automation.

## 3. Required Context
- Approved OpenSpec change for Ansible work.
- Validated phase-1 manual workflow.
- Official Gentoo AMD64 Handbook baseline: <https://wiki.gentoo.org/wiki/Handbook:AMD64>.
- Official Gentoo live ISO preflight behavior.
- A network-reachable official Gentoo live ISO target over SSH, selected by inventory or Makefile variables such as `ANSIBLE_LIVE_HOST`.
- Libvirt VM SSH access only when using the local validation harness.
- Proxmox VM SSH access only when using the remote disposable Proxmox validation harness.
- Shared SSH transport wrapper policy for controller-to-live-ISO targets: `ANSIBLE_SSH_CONNECT_TIMEOUT=10`, `ANSIBLE_SSH_SERVER_ALIVE_INTERVAL=30`, `ANSIBLE_SSH_SERVER_ALIVE_COUNT_MAX=6`, `ANSIBLE_SSH_CONTROL_MASTER=auto`, `ANSIBLE_SSH_CONTROL_PERSIST=10m`, and `ANSIBLE_SSH_CONTROL_PATH_DIR=var/ssh-control` unless the operator overrides them through the Makefile.
- Basic console targets: amd64, OpenRC or systemd, UEFI, ext4 or planned Btrfs subvolumes, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS.
- Target system baseline: `docs/target-system-baseline.md`.
- Installed time synchronization policy: `docs/installed-time-sync-policy.md`.
- Installed SSH policy: `docs/installed-ssh-policy.md`.
- Boot kernel command line policy: `docs/boot-kernel-commandline-policy.md`.
- Download cache and mirror policy: `docs/download-cache-and-mirror-policy.md`.
- Portage world update policy: `docs/portage-world-update-policy.md`.
- Manual escape hatch policy: `docs/manual-escape-hatch-policy.md`.
- Real hardware readiness policy: `docs/real-hardware-readiness.md`.
- Btrfs policy, when `FILESYSTEM=btrfs`, is shared across init systems and documented in `docs/btrfs-layout-policy.md`: root `@`, `@home`, `@var`, `@var_log`, `@var_cache`, and `@snapshots`; root must mount with `subvol=@`.
- Project Handbook choices: NetworkManager for v1 networking, GRUB for UEFI, EFI mounted at `/boot/efi` in the installed system, and `gentoo-kernel-bin` with required installkernel/initramfs support.
- Planned shared guardrails: install configuration schema, config validation report, target system baseline, installed time sync policy, installed SSH policy, boot kernel command line policy, download/cache mirror policy, Portage world update policy, destructive previews, audit bundles, secret input policy, logging/error taxonomy, Handbook traceability, live ISO network bootstrap hardening, host requirements, cleanup/reset policy, manual escape hatch, libvirt matrix validation, first-boot validation, and install report summary. Implemented install state checkpoints are written through `common/install_state`.
- Makefile target contract.
- Safety review requirements.
- Target root path, expected `/mnt/gentoo`.
- Disk identity model and confirmation model.

## 4. Ansible Layout
Expected layout:

```text
ansible/
  inventory/
    live.yml
    local.yml
  group_vars/
    all.yml
    openrc.yml
    systemd.yml
  playbooks/
    install-openrc.yml
    install-systemd.yml
    install-basic-console.yml
    post-install-desktop.yml
    validate-desktop.yml
  roles/
    common/
      preflight/
      disk_detection/
      install_plan/
      partition_plan/
      mount_plan/
      filesystem_plan/
      disk_safety/
      partitioning/
      filesystem/
      mount_target/
      stage3/
      chroot/
      portage/
      package_install/
      fstab/
      kernel/
      bootloader/
      users/
      ssh/
      final_checks/
    post_install/
      desktop_common/
      desktop_i3_x11/
    init/
      openrc/
      systemd/
```

The layout must keep shared behavior in common roles and init-specific behavior isolated under explicit OpenRC and systemd roles or task files. Alternative layouts are allowed only when an approved OpenSpec design preserves common implementation and init-specific isolation.

Optional post-install roles live under `roles/post_install/`. They run after the installed system has booted from disk and is reachable over SSH. They must not modify the basic-console install sequence or run against the official live ISO.

## 5. Inventory Model
Inventory is remote/network-first:

```yaml
all:
  hosts:
    gentoo_live:
      ansible_connection: ssh
      ansible_user: root
      ansible_python_interpreter: auto_silent
```

Rules:

- Ansible normally runs from the operator/controller machine and manages a booted official Gentoo live ISO target over SSH.
- Controller-side Ansible wrappers must use the shared SSH transport helper instead of repeating raw `--ssh-common-args`.
- Temporary live ISO wrappers may disable strict host-key persistence per invocation, but global `ansible.cfg` must keep host key checking enabled.
- Long-running install commands should be launched from `tmux` or `screen` on the controller; this protects the operator session but does not replace SSH keepalives or resumable phase logic.
- Do not treat the installed target as the control host.
- Reusable roles must not depend on libvirt, Proxmox, VM names, VMIDs, storage IDs, qcow2 paths, or VM-only guest disk names.
- Do not store secrets in inventory.
- Do not define a default install disk in inventory.
- Explicit network target variables such as `ANSIBLE_LIVE_HOST`, `ANSIBLE_LIVE_PORT`, and `ANSIBLE_LIVE_USER` belong in Makefile wrappers, inventory, or documented operator inputs, not in role defaults.

The live ISO VM preflight is the local test-harness path. It may use SSH from the controller to the libvirt VM through `ansible/inventory/live.yml`, but it must remain read-only and must not select `install_disk`.

## 6. Variable Model
Variables must make init selection, shared behavior, and destructive intent explicit.

Expected variables:

- `gentoo_arch: amd64`
- `init_system`: must be `openrc` or `systemd`.
- `boot_mode: uefi`
- `filesystem`: must be `ext4` or `btrfs` for current read-only planning.
- `kernel_package: gentoo-kernel-bin`
- `bootloader: grub`
- `stage3_variant`: must match `init_system`.
- `stage3_flavor`: must be `standard`, `hardened`, or `musl` and must select the matching official Gentoo stage3/profile family.
- `portage_profile_path`: variant profile path selected by shared `common/portage`.
- `portage_gentoo_mirrors`: HTTPS distfiles mirror written to target `make.conf`.
- `timezone`: target timezone under `/usr/share/zoneinfo`.
- `locale`: target UTF-8 locale.
- `keymap`: target console keymap.
- `enable_ssh`: whether to install and enable SSH.
- `enable_wifi`: whether to install target WiFi firmware and supplicant support; defaults to `no` and must not store SSIDs, passphrases, or NetworkManager connection profiles.
- `enable_qemu_guest_agent`: whether to install and enable `app-emulation/qemu-guest-agent`; normal installs default to `no`, Proxmox validation may set it to `yes`.
- `admin_user`: required for user/access configuration and must not have a useful default.
- `admin_groups_csv`: comma-separated admin groups, defaulting to `wheel`.
- `admin_shell`: target admin shell, defaulting to `/bin/bash`.
- `privilege_tool`: currently `sudo`; doas requires a later OpenSpec change.
- `admin_sudo_nopasswd`: explicit `yes` or `no` sudo policy; normal installs default to password-requiring sudo, while disposable libvirt E2E tests may set it to `yes`.
- `admin_password_hash_file`, `root_password_hash_file`: optional controller-local gitignored files; contents must use `no_log`.
- `admin_authorized_keys_file`: optional controller-local gitignored authorized_keys file; private key material must be rejected.
- `bootloader_confirmation`: required value is `yes` for GRUB/EFI workflows that may update EFI boot entries.
- `target_mount: /mnt/gentoo`
- `efi_mount: /mnt/gentoo/boot/efi`
- `vm_guest_mode`: true only in the libvirt-managed VM guest test environment.
- `ansible_live_host`: network target address for the booted official Gentoo live ISO.
- `ansible_live_port`: SSH port for the live ISO target.
- `ansible_live_user`: SSH user for the live ISO target.
- `install_disk`: required for destructive tasks, no default.
- `efi_partition`: set only after approved plan.
- `root_partition`: set only after approved plan.
- `confirm_wipe_disk`: required for destructive tasks. It may be populated from Makefile `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- `desktop_profile`: post-install desktop profile, currently `i3-x11`.
- `desktop_user`: existing installed user that receives session files.
- `desktop_install_recommends`: `yes` or `no` package recommendation policy.
- `desktop_display_manager`: currently `none` only.
- `desktop_session_start`: currently `startx` only.

Rules:

- No destructive task without `install_disk`.
- No destructive task without `confirm_wipe_disk=yes`.
- No default disk.
- No wildcard disk matching.
- `filesystem` must be `ext4` or `btrfs`.
- Btrfs subvolume names, mountpoints, and root `subvol=@` behavior must come from the shared Btrfs policy, not from OpenRC/systemd-specific roles.
- `stage3_variant` must match `init_system`.
- `stage3_flavor` must remain independent from `init_system`; do not encode hardened or musl as `PROFILE`.
- Stage3 verification must follow `docs/stage3-signature-policy.md`: checksum verification is mandatory, signature verification must fail closed unless an approved OpenSpec change defines an explicit override, and cached artifacts must be reverified before extraction.
- OpenRC variables belong in `group_vars/openrc.yml` or an equivalent variant file.
- systemd variables belong in `group_vars/systemd.yml` or an equivalent variant file.
- OpenRC workflows must not call `systemctl`.
- systemd workflows must not call `rc-update` or `rc-service`.
- VM guest disk examples such as `/dev/vda` or `/dev/sda` are allowed only when explicitly passed as `install_disk` inside disposable VM harnesses. They must not become defaults for reusable roles or physical hosts.
- Real network targets must use disk paths from `make detect-disks` output. VM example paths such as `/dev/vda` must not be reused as defaults for physical hosts.
- Do not store plaintext passwords, API keys, or login tokens in variables.
- Do not pass password hashes or SSH key contents directly as Makefile variables or inventory values; pass only approved local file paths and redact contents with `no_log`.
- Variables that select disks or partitions must be operator-provided or generated from an approved plan.
- Post-install desktop variables must not select a live ISO target. Wrapper variables use `DESKTOP_TARGET_HOST`, `DESKTOP_TARGET_PORT`, `DESKTOP_TARGET_USER`, and `DESKTOP_USER` because the workflow targets the installed system after reboot.

## 7. Role Model
Roles must have narrow responsibilities and a reuse-first boundary.

Shared roles:

- `common/preflight`: verify live ISO, amd64, UEFI, network, time, tools, and root privileges.
- `common/live_target`: verify controller-to-target SSH, Python availability, official live ISO evidence, amd64, UEFI, network, DNS, and time without assuming libvirt.
- `common/disk_detection`: read-only disk identity and partition reporting.
- `common/disk_safety`: shared disk safety gates for explicit disk input, conservative disk syntax, disk identity, mount-state checks, mounted-descendant rejection, destructive confirmation validation, and opt-in resume checkpoint comparison.
- `common/install_state`: write non-secret state under `var/state/current-install.json` and `logs/install-runs/<run-id>/`, load the shared phase contract from `config/install-phases.json`, track completed ordered phases, preserve the latest disk safety checkpoint for `make install-resume-plan`, and record resume decisions without treating checkpoints as confirmations.
- `common/install_plan`: profile-aware read-only plan output that follows the official Gentoo AMD64 Handbook baseline and does not select a disk by default.
- `common/partition_plan`: read-only GPT partition plan that reuses `common/disk_safety`, requires explicit `install_disk`, and reports ext4 or Btrfs root layout without writing.
- `common/mount_plan`: read-only mount layout plan that reuses partition-plan safety checks and reports root, EFI, and Btrfs subvolume mountpoints without running `mount`, `umount`, or `mkdir`.
- `common/filesystem_plan`: read-only filesystem creation plan that reuses mount-plan output and reports EFI/root filesystems and Btrfs subvolumes without running `mkfs.*`, `wipefs`, or Btrfs subvolume commands.
- `common/partitioning`: partition only after shared safety gates pass.
- `common/filesystem`: format approved partitions only after shared confirmation.
- `common/mount_target`: mount root and EFI partitions with path assertions, validate already-mounted paths for idempotency, and mount Btrfs root with `subvol=@` plus the approved subvolumes.
- `common/stage3`: download, verify, validate variant, and extract official stage3 into verified `/mnt/gentoo`.
- `common/chroot`: prepare Handbook-aligned pseudo-filesystem mounts under `/mnt/gentoo`, copy resolver configuration safely, validate DNS with a read-only chroot lookup, report before/after mount state, and guard later target-mutating operations.
- `common/portage`: configure minimal Portage baseline shared by both init systems, including conservative `make.conf`, official Gentoo repo sync, variant profile selection, GURU-disabled policy, pending config-update reporting, and evidence logs.
- `common/locale_timezone_hostname`: configure target hostname, timezone, locale generation, OpenRC/systemd keymap files, and report inputs for final checks and install reports.
- `common/package_install`: install packages from shared and variant package lists, optionally install WiFi firmware/supplicant support through `ENABLE_WIFI`, optionally install QEMU guest agent for VM validation, apply conservative package USE policy, and record package/service evidence.
- `common/fstab`: generate stable UUID-based fstab entries for ext4 root or the approved Btrfs subvolume layout plus `/boot/efi`, validate UUIDs, and write only under `/mnt/gentoo`.
- `common/kernel`: install `sys-kernel/installkernel`, `sys-kernel/dracut`, and `gentoo-kernel-bin`; derive the kernel command line from `/mnt/gentoo/etc/fstab`; write installkernel/dracut command-line input; validate kernel, initramfs, and module artifacts; and leave GRUB installation to `common/bootloader`.
- `common/bootloader`: require explicit `install_disk` plus bootloader confirmation, show current EFI entries before changes, install `sys-boot/grub` and `sys-boot/efibootmgr`, run guarded UEFI `grub-install`, generate `grub.cfg`, validate root UUID and Btrfs `rootflags=subvol=@`, and record bootloader evidence.
- `common/users`: require explicit `admin_user`, create or update the target admin account under `/mnt/gentoo`, manage admin group membership, configure sudo through `wheel` by default, support explicit `admin_sudo_nopasswd` for disposable test convenience or operator policy, apply optional password hashes from gitignored controller-local files with `no_log`, install optional authorized keys, enforce installed SSH root-login restrictions when SSH is enabled, and record only non-secret evidence.
- `common/ssh`: translate `ENABLE_SSH` into optional package/service inputs without storing secrets, enabling root password login, or assuming SSH is enabled by default.
- `common/final_checks`: require explicit `admin_user`, run read-only reboot readiness validation for target mounts, chroot mounts, fstab, Btrfs subvolumes, kernel/initramfs, GRUB/EFI files, services, users, target identity, Portage baseline, SSH policy, and secret-safe report inputs.
- `post_install/desktop_common`: validate installed-target boundaries, reject live ISO roots, require an existing desktop user, verify root/passwordless sudo elevation, normalize desktop variables, and report shared desktop plan output.
- `post_install/desktop_i3_x11`: manage i3/X11 package policy, `startx` session templates, package installed-state checks, i3/startx command validation, and display-manager-disabled validation.

Init-specific roles:

- `init/openrc`: OpenRC stage3 selection, OpenRC profile, `rc-update` service enablement, OpenRC syslog/cron package choices, and OpenRC validation.
- `init/systemd`: systemd stage3 selection, systemd profile, `systemctl` service enablement, journald assumptions, and systemd validation.

Roles must not combine unrelated risk classes. For example, disk partitioning, user creation, and GRUB installation must remain separate.
Init-specific roles must not partition, format, wipe, select disks, or redefine shared disk safety.

## 8. Playbook Model
Expected playbooks:

- `install-basic-console.yml`: shared console installation flow.
- `install-openrc.yml`: thin OpenRC entrypoint that loads OpenRC variables and calls the shared flow.
- `install-systemd.yml`: thin systemd entrypoint that loads systemd variables and calls the shared flow.
- `post-install-desktop.yml`: shared post-install desktop entrypoint. It targets an installed Gentoo system over SSH and must call `post_install/desktop_common` before profile-specific roles.
- `validate-desktop.yml`: read-only validation entrypoint for installed desktop profile state.

Rules:

- The shared flow must call implemented roles in Gentoo Handbook order: preflight, disk safety, partitioning, filesystem, mount target, stage3, chroot, Portage, identity, fstab, kernel, packages/services, users, bootloader, and final checks.
- Thin OpenRC/systemd entrypoints must select variant variables only; they must not duplicate the shared role sequence.
- Future installer playbooks and roles must be derived from the official Gentoo AMD64 Handbook flow unless an approved OpenSpec change documents a deliberate deviation.
- Planning playbooks must be runnable without mutation.
- Apply playbooks must require prior plan output and confirmations.
- Destructive work must be isolated in clearly named playbooks and tags.
- Shell and command tasks must be minimized and guarded.
- Do not duplicate OpenRC and systemd playbook logic when a shared playbook can be parameterized safely.
- Desktop playbooks must not import base installer roles such as partitioning, filesystem, stage3, chroot, bootloader, users, or final checks. They may validate the installed boundary and manage post-install desktop packages/config only.

## Ansible quality standards
Future Ansible implementation must be written so it can be reviewed, linted, and rerun safely.

Authoring rules:

- Use fully qualified module names, for example `ansible.builtin.assert`, `ansible.builtin.command`, and `ansible.builtin.template`.
- Give every task and handler a clear `name`.
- Prefer modules over `command`, `shell`, `raw`, or chroot wrappers.
- Use `command.argv` instead of free-form command strings where practical.
- Use explicit module `state` values when modules support them.
- Keep tasks narrow; do not combine unrelated risk classes in one task or shell pipeline.
- Use handlers for service restarts or reloads triggered by managed configuration changes.
- Use tags consistently for risk and phase, such as `preflight`, `plan`, `destructive`, `partition`, `filesystem`, `mount`, `stage3`, `chroot`, `portage`, `kernel`, `bootloader`, `users`, `services`, and `final_checks`.

Command-like task rules:

- A command-like task that only inspects state must set `changed_when: false`.
- A command-like task that can fail for acceptable reasons must define `failed_when` explicitly.
- A command-like task that mutates state must use `creates`, `removes`, pre-check facts, path assertions, or another idempotency guard where practical.
- Shell-specific features such as pipes, redirects, and globbing require a documented reason and safety review when target state can change.
- Chroot wrappers must assert the target root and preserve the risk classification of the command executed inside the chroot.

Check and diff rules:

- Plan targets must remain read-only and mutation-free.
- Apply roles should support Ansible check mode where modules support it.
- Template and file changes should support diff mode unless the output contains secrets.
- Secret-sensitive tasks must set `no_log` or otherwise redact values from output, logs, facts, and diffs.

Quality gates:

- `make ansible-check` must syntax-check implemented playbooks.
- `make ansible-check` must run `ansible-lint` when it is installed.
- If `ansible-lint` is unavailable, the result must say lint was skipped; future release or CI changes may make lint mandatory.
- Lint exceptions must be local, justified, and documented in the OpenSpec change or implementation summary.
- Global `ansible.cfg` must not disable host key checking. Host-to-live-ISO wrappers may disable host key checking only for temporary VM SSH sessions.

## 9. Safety Gates
Required gates:

- No destructive task without `install_disk`.
- No destructive task without `confirm_wipe_disk=yes`.
- No default disk.
- Show disk identity before destructive tasks.
- Fail closed on ambiguity.
- Separate planning from execution.
- Confirm official Gentoo live ISO context.
- Confirm amd64.
- Confirm UEFI.
- Confirm `init_system` is `openrc` or `systemd`.
- Confirm `stage3_variant` matches `init_system`.
- Confirm `stage3_flavor` selects the matching official stage3 metadata and Portage profile path.
- Confirm `target_mount` is not `/`.
- Confirm target root and EFI mount paths before writing.
- Confirm `/mnt/gentoo/boot/efi` in the live ISO maps to `/boot/efi` in the target system.
- Confirm no mounted filesystem is formatted.
- Confirm Btrfs formatting creates only the approved shared subvolumes and verifies them with Btrfs tooling when generic block inspection does not report Btrfs metadata.
- Confirm GRUB target disk is operator-provided.
- Confirm current EFI boot entries are shown before EFI changes.
- Confirm OpenRC flows do not call `systemctl`.
- Confirm systemd flows do not call `rc-update` or `rc-service`.
- Confirm destructive workflows print or call the shared preview before accepting confirmation.
- Confirm preview targets are read-only, use `make partition-preview`, `make format-preview`, `make mount-preview`, `make users-preview`, `make bootloader-preview`, or an equivalent documented preview, and never set confirmation variables.
- Confirm resume checkpoints do not replace destructive confirmations, and resumed destructive workflows compare current disk identity, descendant partition state, filesystem UUIDs, mountpoints, and recorded profile/filesystem/stage3 flavor values through `common/disk_safety`.
- Confirm state output is curated and secret-safe; do not write passwords, password hashes, tokens, API keys, private keys, or local credentials into `var/state/` or `logs/install-runs/`.
- Confirm wrapper failures and Ansible `fail_msg` values use the shared error taxonomy from `docs/logging-and-error-taxonomy.md`; new scripts should use `die_code` when they source `scripts/vm-libvirt-common.sh`.
- Confirm audit bundle generation uses `make install-audit` or the final-check/full-install wrappers, reads only project-local `var/state/` and `logs/install-runs/` inputs, and rejects secret-like evidence before copying.
- Confirm install report generation uses `make install-report`, reads only project-local `var/state/` and `logs/install-runs/` inputs, marks missing evidence as unavailable, and rejects secret-like evidence before writing the summary.
- Confirm cleanup/reset work uses `make cleanup-plan` before deletion, requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`, preserves audit bundles by default, and restricts deletion to approved generated artifact roots.
- Confirm first-boot validation uses documented VM harness targets, boots only project-owned disposable VM disks, requires completed install state and SSH access to the installed system, and writes read-only evidence under `logs/install-runs/<run-id>/first-boot/` or the relevant VM harness log directory.
- Confirm installer roles and Makefile targets remain represented in `config/handbook-traceability.json`; regenerate `docs/handbook-traceability.md` with `make handbook-trace` when phases, roles, targets, safety gates, or project deviations change.
- Confirm logs, state files, and audit bundles do not contain secrets.
- Confirm operator variables pass the shared config validation before apply workflows.
- Confirm manual intervention is recorded through `make record-manual-step`, preserved as non-secret run evidence, and revalidated with `make install-resume-plan` before `make install-resume` executes exactly one planner-approved phase.
- Confirm physical-machine destructive workflows are preceded by `make real-hardware-check`, stable disk identity is preferred, and readiness output is not treated as destructive confirmation.
- Confirm libvirt matrix planning covers amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavors without creating disks or running destructive install steps.
- Confirm `VM_TEST_IMAGE_NAME`, when used, is treated only as local libvirt test-harness metadata for naming generated artifacts and never as an ISO path, package selector, disk selector, or reusable Ansible variable.
- Confirm libvirt end-to-end validation runs only through `make vm-e2e-plan` and `make vm-e2e-install`, uses explicit `/dev/vda` inside the disposable VM, requires installed SSH, and preserves wipe plus bootloader confirmations.
- Confirm bootloader/kernel tasks follow the shared boot command line policy.
- Confirm SSH and time-sync behavior follows target policies and remains init-specific only where needed.

Disk identity output must include path, model, serial when available, size, current partition table, current filesystems, and mountpoints.
Safety gates must be implemented once and reused by both OpenRC and systemd flows.

## 10. Dry-run Strategy
Dry-run must be built into future playbooks:

- `make ansible-dry-run` should use Ansible check mode where practical.
- `make ansible-dry-run PROFILE=openrc` and `make ansible-dry-run PROFILE=systemd` should use Ansible check mode where practical.
- `make install-plan PROFILE=openrc` and `make install-plan PROFILE=systemd` should gather facts and show planned changes without mutation.
- `make mount-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` should report target root, EFI, and Btrfs subvolume mount layout without mutation.
- `make filesystem-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` should report planned EFI/root filesystem creation and Btrfs subvolumes without mutation.
- Destructive tasks must not run in check mode.
- Tasks that cannot support check mode must provide plan output and skip changes.
- Dry-run output must show missing required variables and confirmations.
- Diff output should be used for templates and config files where useful.
- Dry-run results must be clear enough for safety review.

## 11. Idempotency Rules
Future Ansible implementation must be rerunnable where practical:

- Read-only roles report no changes.
- Disk detection never changes state.
- Partitioning fails closed if the disk does not match the approved plan.
- Formatting detects existing filesystems and refuses unexpected state.
- Mount tasks verify current mount state before acting.
- Stage3 extraction does not overwrite an existing root without confirmation.
- Portage config uses templates or managed file blocks with predictable diffs.
- Chroot tasks use guards and explicit changed conditions.
- Kernel and package tasks avoid unnecessary reinstall work.
- Bootloader tasks verify UEFI, target disk, EFI mount, and root UUID before changes.
- Final checks remain read-only.

Non-idempotent tasks must be isolated, tagged, documented, and explicitly confirmed.

## 12. Reuse-first Rules
Future Ansible implementation must follow these rules:

- Map shared roles to the relevant Gentoo AMD64 Handbook phase where practical.
- Document project-specific Handbook choices, including NetworkManager, GRUB UEFI, `/boot/efi`, required filesystem tools, and installkernel/initramfs support for `gentoo-kernel-bin`.
- Document optional installed WiFi support when `ENABLE_WIFI` behavior changes, including packages, USE flags, validation, and the rule that wireless credentials are not stored by the installer.
- Document shared guardrails when introduced: configuration schema, config validation output, target policies, state checkpoints, audit bundle paths, destructive preview output, secret input channels, error codes, cleanup/reset scope, manual escape hatch, and Handbook traceability.
- Implement common behavior once under `roles/common/` or equivalent shared task, handler, template, validation, or variable files.
- Add init-specific files only for behavior that genuinely differs between OpenRC and systemd.
- Use variant variables for package lists, profile names, service names, and stage3 variant values where that avoids duplicated tasks.
- Reuse handlers unless service manager behavior differs.
- Reuse templates unless rendered content genuinely differs by init system.
- Reuse validation tasks for architecture, UEFI, disk identity, mount state, fstab, kernel, GRUB, logs, and safety confirmations.
- Keep safety gates shared; init-specific roles may consume safety facts but must not redefine them.
- If duplication is introduced, document why shared roles, variables, includes, handlers, or templates cannot express the behavior.

Anti-duplication checklist:

- Does the implementation preserve the Handbook order for shared installation phases unless a deviation is documented?
- Are OpenRC and systemd playbooks thin wrappers around the shared flow?
- Are shared roles used for disk, mount, stage3, chroot, Portage, package framework, fstab, kernel, bootloader, users, SSH, final checks, and logging?
- Are init-specific service commands isolated?
- Are package differences represented as variables where practical?
- Are safety gates shared and impossible for init-specific roles to bypass?
- Does documentation describe shared behavior once?

## 13. Logging Rules
Store logs under `logs/`.

Logs should include:

- Makefile target invoked.
- Playbook name, tags, and check/apply mode.
- Live ISO, architecture, and UEFI status.
- Disk identity before destructive tasks.
- Install plan and partition plan.
- Stage3 filenames, checksums, signatures, and timestamps.
- Portage profile and package summary.
- Kernel files and version.
- GRUB and EFI changes.
- NetworkManager enablement.
- Final check results.

Logs must not include plaintext passwords, API keys, login tokens, private keys, or secret variable values.

## 14. Makefile Targets
Expected targets:

These targets define the expected control-plane contract for future Ansible installation work. If a target is not present in the current `Makefile`, treat it as planned and do not document it as runnable in user-facing docs.

- `make ansible-live-ping`
- `make ansible-live-preflight`
- `make local-live-preflight`
- `make local-detect-disks`
- `make local-install-plan`
- `make local-partition-plan INSTALL_DISK=...`
- `make ansible-check`
- `make detect-disks`
- `make ansible-dry-run PROFILE=openrc`
- `make ansible-dry-run PROFILE=systemd`
- `make install-plan`
- `make partition-plan INSTALL_DISK=...`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`
- `make desktop-plan DESKTOP_TARGET_HOST=... DESKTOP_TARGET_USER=... DESKTOP_USER=...`
- `make desktop-install DESKTOP_TARGET_HOST=... DESKTOP_TARGET_USER=... DESKTOP_USER=...`
- `make desktop-validate DESKTOP_TARGET_HOST=... DESKTOP_TARGET_USER=... DESKTOP_USER=...`
- `make install-openrc`
- `make install-systemd`
- `make final-checks`

Target expectations:

- `make ansible-live-ping`: validate SSH-based Ansible connectivity to the booted official live ISO target. Use `ANSIBLE_LIVE_HOST=...` for real network targets; omit it only for local libvirt VM discovery.
- `make ansible-live-preflight`: run read-only live ISO checks for architecture, kernel, Gentoo release evidence, UEFI availability, root SSH access, global IP address, DNS resolution, default route, clock sanity, and block devices.
- `make local-live-preflight`: optional fallback target run from inside the official live ISO with `ansible_connection=local`; it reuses the live preflight playbook and must not require SSH.
- `make local-detect-disks`: optional fallback target run from inside the official live ISO for read-only disk inventory.
- `make local-install-plan`: optional fallback target run from inside the official live ISO for read-only install planning; it must not select a disk unless `INSTALL_DISK` is explicit.
- `make local-partition-plan INSTALL_DISK=...`: optional fallback target run from inside the official live ISO; it remains read-only but must require explicit `INSTALL_DISK`.
- `make ansible-check`: validate Ansible availability, inventory, variables, playbooks, roles, and syntax.
- `make detect-disks`: run read-only Ansible disk inventory from inside the live ISO without selecting an install disk.
- `make ansible-dry-run PROFILE=openrc`: run the supported OpenRC check-mode workflow through the shared flow.
- `make ansible-dry-run PROFILE=systemd`: run the supported systemd check-mode workflow through the shared flow.
- `make install-plan`: default to `PROFILE=openrc` and `FILESYSTEM=ext4`, and produce a read-only plan without defaulting `INSTALL_DISK`.
- `make partition-plan INSTALL_DISK=...`: require an explicit disk and produce a read-only GPT partition plan without partitioning.
- `make install-plan PROFILE=openrc`: gather facts and create an operator-readable OpenRC install plan.
- `make install-plan PROFILE=systemd`: gather facts and create an operator-readable systemd install plan.
- `make desktop-plan`: connect to an installed Gentoo target, reject live ISO roots, check selected desktop package availability and session plan, and avoid target mutation.
- `make desktop-install`: install the selected post-install desktop profile on an installed Gentoo target only; it may install packages and user session files but must not run base installer roles.
- `make desktop-validate`: validate the installed desktop profile state without mutating the target.
- `make partition`: destructive target that applies only the approved GPT ESP/root layout after shared disk safety gates and explicit wipe confirmation.
- `make final-checks`: run read-only validation before manual reboot; require `ADMIN_USER` so the installed admin account and sudo policy can be checked.
- `make install`: execute the shared destructive basic-console install flow for the selected `PROFILE`.
- `make install-openrc`: thin destructive target that runs the shared flow with `PROFILE=openrc` and required confirmations.
- `make install-systemd`: thin destructive target that runs the shared flow with `PROFILE=systemd` and required confirmations.

Operators should not run `ansible-playbook` directly.
Makefile targets should pass init-specific variables into shared Ansible flows where practical.

`make ansible-live-preflight` is not an installer target. It must not set `install_disk`, consume destructive confirmation variables, or mutate target filesystems.
Local `local-*` targets are fallback/diagnostic paths for running Ansible inside the live ISO. They must reuse the same playbooks, avoid global host-key relaxation, keep the SSH/network workflow as the primary product path, and preserve every disk safety rule.
`make detect-disks` and `make install-plan` are also read-only at this stage. `INSTALL_DISK` may be passed for identity matching only, and the playbook must explicitly report when it is omitted. `FILESYSTEM=btrfs` may report planned subvolumes, but must not create a Btrfs filesystem or subvolumes until the approved filesystem apply workflow is implemented with the shared safety gates.
`make partition-plan` is read-only but stricter than `install-plan`: it requires `INSTALL_DISK`, fails if selected disk children are mounted, and reports the exact GPT layout that a future destructive target would apply.

## 15. Failure Modes
- No approved OpenSpec change for Ansible work.
- Playbook mutates state during plan or dry-run.
- Destructive task lacks `install_disk`.
- Destructive task lacks `confirm_wipe_disk=yes`.
- A default disk is defined.
- Disk identity changes between plan and execution.
- A task writes to the live root instead of `/mnt/gentoo`.
- A role combines unrelated high-risk operations.
- OpenRC and systemd task logic is duplicated without justification.
- Init-specific role bypasses common disk safety.
- OpenRC role calls `systemctl`.
- systemd role calls `rc-update` or `rc-service`.
- Check mode output differs materially from apply behavior.
- Logs are missing or contain secrets.
- Manual intervention occurred but was not recorded before automation resumed.
- Manual revalidation was skipped after state was marked as requiring revalidation.
- Physical-machine destructive work is attempted without the real hardware readiness check.
- Libvirt matrix planning omits a supported amd64 platform/profile/filesystem/stage3 flavor case or treats `/dev/vda` as valid outside the disposable VM context.
- End-to-end VM validation bypasses the plan target, first-boot validation, audit bundle generation, or normal destructive confirmations.
- Ansible task hides dangerous commands in `shell` or `command`.
- Final checks are skipped before reboot.

## 16. Recovery Advice
- Stop if OpenSpec approval or safety review is missing.
- Re-run `make ansible-check` after structural changes.
- Re-run `make install-plan PROFILE=openrc` or `make install-plan PROFILE=systemd` if disk, mount, or variable state changes.
- Remove any default disk values.
- Split broad roles or playbooks into smaller reviewable units.
- Move duplicated OpenRC/systemd logic into common roles or variant variables before continuing.
- Add asserts for target root, install disk, boot mode, and confirmation variables.
- Preserve logs after failure and inspect state before retrying.
- For long-running stage3 downloads, Portage sync, package installation, kernel installation, and bootloader package installation, use bounded retries or equivalent phase-scoped resilience rather than retrying the whole installer.
- If manual recovery is needed, record the non-secret reason and next action with `make record-manual-step`, rerun `make install-resume-plan`, then use `make install-resume` for one planner-approved phase at a time.
- If moving from libvirt to physical hardware, run `make real-hardware-check` with `ANSIBLE_LIVE_HOST` and an explicit stable `INSTALL_DISK` before destructive targets.
- If validating variants locally, run `make vm-list-cases` and `make vm-test-matrix-plan` first; VM targets derive local harness domains from `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, fixed platform `amd64`, and optional `VM_TEST_IMAGE_NAME`.
- Enable `VM_TEST_MATRIX_RUN_TARGET_PLANS=yes` only after the selected case live ISO VM has SSH connectivity.
- If validating a complete disposable VM install, run `make vm-e2e-plan` first, then `make vm-e2e-install` only with explicit `/dev/vda`, `ADMIN_USER`, `ENABLE_SSH=yes`, wipe confirmation, and bootloader confirmation.
- Before release-oriented handoff, run `make release-check` to verify Ansible syntax, OpenSpec validation, secrets, tracked artifacts, and release documentation.
- If a task writes to the wrong path, stop immediately and collect evidence before further mutation.
- If logs contain secrets, remove them from tracked files and do not commit them.

## 17. Output Artifacts
This skill should produce or request:

- Ansible layout plan.
- Inventory model.
- Variable schema.
- Role and playbook design notes.
- Reuse analysis identifying shared and init-specific behavior.
- Safety gate checklist.
- Dry-run output.
- Idempotency review notes.
- Logs under `logs/`.
- Install plan.
- Final checks report.
- Safety review findings.
- OpenSpec validation evidence.

## Documentation maintenance
When phase 2 Ansible behavior changes, documentation must change in the same implementation step.

- If the Ansible layout, inventory model, variable model, roles, playbooks, safety gates, dry-run behavior, idempotency rules, or log locations change, update this skill and the relevant Ansible documentation under `docs/`.
- If disk detection or install-plan behavior changes, update `docs/ansible-install-plan.md`, `skills/gentoo-disk-planning.md`, and the active OpenSpec `tasks.md`.
- If partition-plan behavior changes, update `docs/ansible-partition-plan.md`, `skills/gentoo-disk-planning.md`, `skills/makefile-control-plane.md`, and active OpenSpec tasks.
- If filesystem plan options change, document `FILESYSTEM`, defaults, Btrfs subvolumes, and ext4 behavior in docs and skills together.
- If fstab generation changes, update `docs/ansible-fstab-generation.md`, `docs/btrfs-layout-policy.md` if Btrfs entries change, `skills/makefile-control-plane.md`, and the active OpenSpec tasks together.
- If a role or playbook intentionally differs from the official Gentoo AMD64 Handbook flow, document the reason in the relevant OpenSpec change and `docs/ansible-architecture.md`.
- If the live ISO preflight role, inventory, SSH targeting, checks, or Makefile targets change, update `docs/ansible-live-preflight.md`, `docs/libvirt-manual-install-test.md`, and the active OpenSpec `tasks.md`.
- If shared role boundaries or init-specific behavior changes, update `docs/ansible-architecture.md`.
- If Ansible quality standards change, update `.ansible-lint`, `scripts/ansible-check.sh`, `docs/ansible-architecture.md`, this skill, and the active OpenSpec tasks together.
- If configuration schema or validation behavior changes, update `config/install-schema.yml`, `docs/install-configuration.md`, this skill, `skills/makefile-control-plane.md`, and the active OpenSpec tasks together.
- If execution assumptions change, document controller/target behavior. Reusable installer docs must remain remote/network-first; local VM/libvirt docs must remain clearly labeled as test harness docs.
- If Makefile targets such as `make ansible-check`, `make ansible-dry-run PROFILE=...`, `make install-plan PROFILE=...`, `make install-openrc`, `make install-systemd`, or `make final-checks` change, update this skill and `skills/makefile-control-plane.md`.
- If post-install desktop roles, playbooks, wrappers, package policy, or targets change, update `docs/desktop-profiles.md`, the profile-specific desktop document, `docs/ansible-architecture.md`, `skills/makefile-control-plane.md`, and active OpenSpec tasks together.
- If destructive Ansible tasks change, update `agents/safety-review-agent.md`, disk safety skills, and OpenSpec `tasks.md` before marking implementation complete.
- If variables such as `install_disk`, `confirm_wipe_disk`, or the Makefile confirmation variable `I_UNDERSTAND_THIS_WIPES_DISK` change, update variable documentation, safety gates, examples, failure modes, and recovery advice together.
- If manual intervention handling changes, update `docs/manual-escape-hatch-policy.md`, `docs/install-state-and-resume-checkpoints.md`, `docs/install-audit-bundle.md`, this skill, `skills/makefile-control-plane.md`, and active OpenSpec tasks together.
- If real hardware readiness handling changes, update `docs/real-hardware-readiness.md`, `docs/destructive-safety-gates.md`, `docs/install-configuration.md`, this skill, `skills/makefile-control-plane.md`, and active OpenSpec tasks together.
- If libvirt matrix behavior changes, update `docs/libvirt-install-test-matrix.md`, `docs/libvirt-manual-install-test.md`, `docs/ansible-architecture.md`, this skill, `skills/makefile-control-plane.md`, and active OpenSpec tasks together. If `VM_TEST_IMAGE_NAME` or another local test label changes, document its allowed characters, artifact naming effect, and non-role boundary.
- If Proxmox validation behavior changes, update `docs/proxmox-validation.md`, `docs/proxmox-install-test-matrix.md`, `docs/proxmox-end-to-end-install-validation.md`, `docs/supported-host-requirements.md`, this skill, `skills/makefile-control-plane.md`, and active OpenSpec tasks together. Document host/node, ISO volume, storage, bridge, VLAN, VMID/IP mapping, expected guest disk, SSH bootstrap, logs, cleanup, and the boundary that reusable roles must not depend on Proxmox details.
- If libvirt end-to-end validation changes, update `docs/libvirt-end-to-end-install-validation.md`, `docs/libvirt-manual-install-test.md`, `docs/libvirt-install-test-matrix.md`, this skill, `skills/makefile-control-plane.md`, safety review rules, and active OpenSpec tasks together.
- If release readiness checks change, update `docs/release-readiness.md`, README, `skills/makefile-control-plane.md`, this skill, and active OpenSpec tasks together.
- Before finishing, confirm logs documentation still states where logs are stored and that secrets must not be logged.
