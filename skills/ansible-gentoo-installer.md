# Ansible Gentoo Installer Skill

## 1. Purpose
This skill describes how `gentoo-ai-installer` should build the phase-2 Ansible-based Gentoo installer with reuse-first OpenRC and systemd support.

Phase 1 is manual installation with Codex assistance. Phase 2 creates a reproducible installer using Ansible running locally from the official Gentoo live ISO. The Makefile controls all operator-facing commands.

This skill defines standards for future Ansible implementation. It does not implement playbooks.

## 2. When to Use This Skill
Use this skill:

- When creating or reviewing phase-2 Ansible design.
- When translating validated phase-1 manual steps into roles.
- When adding Ansible inventories, variables, playbooks, or roles.
- When defining Makefile targets that wrap Ansible.
- When reviewing safety gates, dry-run behavior, idempotency, or logging.
- When adding or changing the read-only live ISO Ansible preflight used before installer automation.
- When adding or changing read-only disk detection or install-plan behavior.

Do not use this skill to bypass OpenSpec or safety review for destructive automation.

## 3. Required Context
- Approved OpenSpec change for Ansible work.
- Validated phase-1 manual workflow.
- Official Gentoo AMD64 Handbook baseline: <https://wiki.gentoo.org/wiki/Handbook:AMD64>.
- Official Gentoo live ISO preflight behavior.
- Libvirt VM SSH access for host-driven live ISO validation, when using `make ansible-live-ping` or `make ansible-live-preflight`.
- Basic console targets: amd64, OpenRC or systemd, UEFI, ext4 or planned Btrfs subvolumes, `gentoo-kernel-bin`, GRUB, NetworkManager or equivalent network setup, no LUKS.
- Makefile target contract.
- Safety review requirements.
- Target root path, expected `/mnt/gentoo`.
- Disk identity model and confirmation model.

## 4. Ansible Layout
Expected layout:

```text
ansible/
  inventory/
    local.yml
  group_vars/
    all.yml
    openrc.yml
    systemd.yml
  playbooks/
    install-openrc.yml
    install-systemd.yml
    install-basic-console.yml
  roles/
    common/
      preflight/
      disk_detection/
      install_plan/
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
    init/
      openrc/
      systemd/
```

The layout must keep shared behavior in common roles and init-specific behavior isolated under explicit OpenRC and systemd roles or task files. Alternative layouts are allowed only when an approved OpenSpec design preserves common implementation and init-specific isolation.

## 5. Inventory Model
Inventory is local-only in v1:

```yaml
all:
  hosts:
    live_iso:
      ansible_connection: local
      ansible_python_interpreter: auto_silent
```

Rules:

- Ansible runs from the official Gentoo live ISO.
- Do not support remote hosts in v1.
- Do not treat the installed target as the control host.
- Do not store secrets in inventory.
- Do not define a default install disk in inventory.

The live ISO VM preflight is an exception for test validation before phase-2 installer execution. It may use SSH from the host to the libvirt VM through `ansible/inventory/live.yml`, but it must remain read-only and must not select `install_disk`.

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
- `enable_ssh`: whether to install and enable SSH.
- `target_mount: /mnt/gentoo`
- `efi_mount: /mnt/gentoo/boot/efi`
- `vm_guest_mode`: true only in the libvirt-managed VM guest test environment.
- `install_disk`: required for destructive tasks, no default.
- `efi_partition`: set only after approved plan.
- `root_partition`: set only after approved plan.
- `confirm_wipe_disk`: required for destructive tasks. It may be populated from Makefile `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

Rules:

- No destructive task without `install_disk`.
- No destructive task without `confirm_wipe_disk=yes`.
- No default disk.
- No wildcard disk matching.
- `filesystem` must be `ext4` or `btrfs`.
- `stage3_variant` must match `init_system`.
- OpenRC variables belong in `group_vars/openrc.yml` or an equivalent variant file.
- systemd variables belong in `group_vars/systemd.yml` or an equivalent variant file.
- OpenRC workflows must not call `systemctl`.
- systemd workflows must not call `rc-update` or `rc-service`.
- VM guest `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the libvirt-managed guest VM.
- Do not store plaintext passwords, API keys, or login tokens in variables.
- Variables that select disks or partitions must be operator-provided or generated from an approved plan.

## 7. Role Model
Roles must have narrow responsibilities and a reuse-first boundary.

Shared roles:

- `common/preflight`: verify live ISO, amd64, UEFI, network, time, tools, and root privileges.
- `common/disk_detection`: read-only disk identity and partition reporting.
- `common/install_plan`: profile-aware read-only plan output that follows the official Gentoo AMD64 Handbook baseline and does not select a disk by default.
- `common/disk_safety`: shared assertions for `install_disk`, confirmation variables, disk identity, VM guest mode, and fail-closed behavior.
- `common/partitioning`: partition only after shared safety gates pass.
- `common/filesystem`: format approved partitions only after shared confirmation.
- `common/mount_target`: mount root and EFI partitions with path assertions.
- `common/stage3`: download, verify, validate variant, and extract official stage3.
- `common/chroot`: prepare chroot mounts and DNS, and guard target-mutating operations.
- `common/portage`: configure minimal Portage baseline shared by both init systems.
- `common/package_install`: install packages from shared and variant package lists.
- `common/fstab`: generate stable UUID-based fstab entries.
- `common/kernel`: install `gentoo-kernel-bin`.
- `common/bootloader`: install and configure GRUB for UEFI through shared safety gates.
- `common/users`: create users and credentials through secret-safe mechanisms.
- `common/ssh`: install SSH packages and dispatch service enablement through init-specific logic.
- `common/final_checks`: read-only validation before reboot.

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

Rules:

- Future installer playbooks and roles must be derived from the official Gentoo AMD64 Handbook flow unless an approved OpenSpec change documents a deliberate deviation.
- Planning playbooks must be runnable without mutation.
- Apply playbooks must require prior plan output and confirmations.
- Destructive work must be isolated in clearly named playbooks and tags.
- Shell and command tasks must be minimized and guarded.
- Do not duplicate OpenRC and systemd playbook logic when a shared playbook can be parameterized safely.

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
- Confirm `target_mount` is not `/`.
- Confirm target root and EFI mount paths before writing.
- Confirm no mounted filesystem is formatted.
- Confirm GRUB target disk is operator-provided.
- Confirm current EFI boot entries are shown before EFI changes.
- Confirm OpenRC flows do not call `systemctl`.
- Confirm systemd flows do not call `rc-update` or `rc-service`.

Disk identity output must include path, model, serial when available, size, current partition table, current filesystems, and mountpoints.
Safety gates must be implemented once and reused by both OpenRC and systemd flows.

## 10. Dry-run Strategy
Dry-run must be built into future playbooks:

- `make ansible-dry-run` should use Ansible check mode where practical.
- `make ansible-dry-run PROFILE=openrc` and `make ansible-dry-run PROFILE=systemd` should use Ansible check mode where practical.
- `make install-plan PROFILE=openrc` and `make install-plan PROFILE=systemd` should gather facts and show planned changes without mutation.
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
- `make ansible-check`
- `make detect-disks`
- `make ansible-dry-run PROFILE=openrc`
- `make ansible-dry-run PROFILE=systemd`
- `make install-plan`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`
- `make install-openrc`
- `make install-systemd`
- `make final-checks`

Target expectations:

- `make ansible-live-ping`: validate SSH-based Ansible connectivity to the booted official live ISO VM.
- `make ansible-live-preflight`: run read-only live ISO checks for architecture, kernel, Gentoo release evidence, UEFI availability, network, DNS, routes, block devices, and `/dev/vda`.
- `make ansible-check`: validate Ansible availability, inventory, variables, playbooks, roles, and syntax.
- `make detect-disks`: run read-only Ansible disk inventory from inside the live ISO without selecting an install disk.
- `make ansible-dry-run PROFILE=openrc`: run the supported OpenRC check-mode workflow through the shared flow.
- `make ansible-dry-run PROFILE=systemd`: run the supported systemd check-mode workflow through the shared flow.
- `make install-plan`: default to `PROFILE=openrc` and `FILESYSTEM=ext4`, and produce a read-only plan without defaulting `INSTALL_DISK`.
- `make install-plan PROFILE=openrc`: gather facts and create an operator-readable OpenRC install plan.
- `make install-plan PROFILE=systemd`: gather facts and create an operator-readable systemd install plan.
- `make install-openrc`: execute the approved OpenRC install with required confirmations.
- `make install-systemd`: execute the approved systemd install with required confirmations.
- `make final-checks`: run read-only validation before reboot.

Operators should not run `ansible-playbook` directly.
Makefile targets should pass init-specific variables into shared Ansible flows where practical.

`make ansible-live-preflight` is not an installer target. It must not set `install_disk`, consume destructive confirmation variables, or mutate target filesystems.
`make detect-disks` and `make install-plan` are also read-only at this stage. `INSTALL_DISK` may be passed for identity matching only, and the playbook must explicitly report when it is omitted. `FILESYSTEM=btrfs` may report planned subvolumes, but must not create a Btrfs filesystem or subvolumes until a later destructive change is approved.

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
- If filesystem plan options change, document `FILESYSTEM`, defaults, Btrfs subvolumes, and ext4 behavior in docs and skills together.
- If a role or playbook intentionally differs from the official Gentoo AMD64 Handbook flow, document the reason in the relevant OpenSpec change and `docs/ansible-architecture.md`.
- If the live ISO preflight role, inventory, SSH targeting, checks, or Makefile targets change, update `docs/ansible-live-preflight.md`, `docs/libvirt-manual-install-test.md`, and the active OpenSpec `tasks.md`.
- If shared role boundaries or init-specific behavior changes, update `docs/ansible-architecture.md`.
- If local execution assumptions change, document whether playbooks run locally from the official Gentoo live ISO or against a remote target; v1 documentation must keep local live ISO execution explicit.
- If Makefile targets such as `make ansible-check`, `make ansible-dry-run PROFILE=...`, `make install-plan PROFILE=...`, `make install-openrc`, `make install-systemd`, or `make final-checks` change, update this skill and `skills/makefile-control-plane.md`.
- If destructive Ansible tasks change, update `agents/safety-review-agent.md`, disk safety skills, and OpenSpec `tasks.md` before marking implementation complete.
- If variables such as `install_disk`, `confirm_wipe_disk`, or the Makefile confirmation variable `I_UNDERSTAND_THIS_WIPES_DISK` change, update variable documentation, safety gates, examples, failure modes, and recovery advice together.
- Before finishing, confirm logs documentation still states where logs are stored and that secrets must not be logged.
