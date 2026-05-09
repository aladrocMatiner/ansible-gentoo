# Ansible Gentoo Installer Skill

## 1. Purpose
This skill describes how `gentoo-ai-installer` should build the phase-2 Ansible-based Gentoo installer.

Phase 1 is manual installation with Codex assistance. Phase 2 creates a reproducible installer using Ansible running locally from the official Gentoo live ISO. The Makefile controls all operator-facing commands.

This skill defines standards for future Ansible implementation. It does not implement playbooks.

## 2. When to Use This Skill
Use this skill:

- When creating or reviewing phase-2 Ansible design.
- When translating validated phase-1 manual steps into roles.
- When adding Ansible inventories, variables, playbooks, or roles.
- When defining Makefile targets that wrap Ansible.
- When reviewing safety gates, dry-run behavior, idempotency, or logging.

Do not use this skill to bypass OpenSpec or safety review for destructive automation.

## 3. Required Context
- Approved OpenSpec change for Ansible work.
- Validated phase-1 manual workflow.
- Official Gentoo live ISO preflight behavior.
- v1 target: amd64, OpenRC, UEFI, ext4, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS, no Btrfs.
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
  playbooks/
    prepare-live-env.yml
    install-gentoo.yml
    partition-disk.yml
    install-stage3.yml
    configure-system.yml
    install-bootloader.yml
  roles/
    preflight/
    disk_detection/
    disk_partitioning/
    filesystem/
    mount_target/
    stage3/
    portage/
    chroot/
    kernel/
    bootloader/
    networking/
    users/
    final_checks/
```

The layout must keep planning, destructive work, configuration, bootloader work, and final checks understandable and reviewable.

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

## 6. Variable Model
Variables must make v1 assumptions and destructive intent explicit.

Expected variables:

- `gentoo_arch: amd64`
- `gentoo_init: openrc`
- `boot_mode: uefi`
- `filesystem: ext4`
- `kernel_package: gentoo-kernel-bin`
- `bootloader: grub`
- `network_manager: NetworkManager`
- `target_root: /mnt/gentoo`
- `install_disk`: required for destructive tasks, no default.
- `efi_partition`: set only after approved plan.
- `root_partition`: set only after approved plan.
- `stage3_variant: openrc`
- `I_UNDERSTAND_THIS_WIPES_DISK`: required for destructive tasks.

Rules:

- No destructive task without `install_disk`.
- No destructive task without `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- No default disk.
- No wildcard disk matching.
- Do not store plaintext passwords, API keys, or login tokens in variables.
- Variables that select disks or partitions must be operator-provided or generated from an approved plan.

## 7. Role Model
Roles must have narrow responsibilities:

- `preflight`: verify live ISO, amd64, UEFI, network, time, tools, and root privileges.
- `disk_detection`: read-only disk identity and partition reporting.
- `disk_partitioning`: partition only after explicit confirmation.
- `filesystem`: format approved partitions only after confirmation.
- `mount_target`: mount root and EFI partitions with path assertions.
- `stage3`: download, verify, and extract official amd64 OpenRC stage3.
- `portage`: configure minimal v1 Portage settings.
- `chroot`: prepare chroot mounts and DNS, and guard target-mutating operations.
- `kernel`: install `gentoo-kernel-bin`.
- `bootloader`: install and configure GRUB for UEFI.
- `networking`: install and enable NetworkManager for OpenRC.
- `users`: create users and credentials through secret-safe mechanisms.
- `final_checks`: read-only validation before reboot.

Roles must not combine unrelated risk classes. For example, disk partitioning, user creation, and GRUB installation must remain separate.

## 8. Playbook Model
Expected playbooks:

- `prepare-live-env.yml`: prepare and validate the live ISO environment.
- `install-gentoo.yml`: orchestrate the complete approved install flow.
- `partition-disk.yml`: run partition planning and partitioning gates.
- `install-stage3.yml`: verify target mount, download, verify, and extract stage3.
- `configure-system.yml`: configure Portage, chroot operations, kernel, networking, and users.
- `install-bootloader.yml`: install and configure GRUB for UEFI.

Rules:

- Planning playbooks must be runnable without mutation.
- Apply playbooks must require prior plan output and confirmations.
- Destructive work must be isolated in clearly named playbooks and tags.
- Shell and command tasks must be minimized and guarded.

## 9. Safety Gates
Required gates:

- No destructive task without `install_disk`.
- No destructive task without `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- No default disk.
- Show disk identity before destructive tasks.
- Fail closed on ambiguity.
- Separate planning from execution.
- Confirm official Gentoo live ISO context.
- Confirm amd64.
- Confirm UEFI.
- Confirm target root is not `/`.
- Confirm target root and EFI mount paths before writing.
- Confirm no mounted filesystem is formatted.
- Confirm stage3 is amd64 OpenRC.
- Confirm GRUB target disk is operator-provided.
- Confirm current EFI boot entries are shown before EFI changes.

Disk identity output must include path, model, serial when available, size, current partition table, current filesystems, and mountpoints.

## 10. Dry-run Strategy
Dry-run must be built into future playbooks:

- `make ansible-dry-run` should use Ansible check mode where practical.
- `make install-plan` should gather facts and show planned changes without mutation.
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

## 12. Logging Rules
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

## 13. Makefile Targets
Expected targets:

- `make ansible-check`
- `make ansible-dry-run`
- `make install-plan`
- `make install`
- `make final-checks`

Target expectations:

- `make ansible-check`: validate Ansible availability, inventory, variables, playbooks, roles, and syntax.
- `make ansible-dry-run`: run supported check-mode workflows and report planned changes.
- `make install-plan`: gather facts and create an operator-readable install plan.
- `make install`: execute the approved install with required confirmations.
- `make final-checks`: run read-only validation before reboot.

Operators should not run `ansible-playbook` directly.

## 14. Failure Modes
- No approved OpenSpec change for Ansible work.
- Playbook mutates state during plan or dry-run.
- Destructive task lacks `install_disk`.
- Destructive task lacks `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- A default disk is defined.
- Disk identity changes between plan and execution.
- A task writes to the live root instead of `/mnt/gentoo`.
- A role combines unrelated high-risk operations.
- Check mode output differs materially from apply behavior.
- Logs are missing or contain secrets.
- Ansible task hides dangerous commands in `shell` or `command`.
- Final checks are skipped before reboot.

## 15. Recovery Advice
- Stop if OpenSpec approval or safety review is missing.
- Re-run `make ansible-check` after structural changes.
- Re-run `make install-plan` if disk, mount, or variable state changes.
- Remove any default disk values.
- Split broad roles or playbooks into smaller reviewable units.
- Add asserts for target root, install disk, boot mode, and confirmation variables.
- Preserve logs after failure and inspect state before retrying.
- If a task writes to the wrong path, stop immediately and collect evidence before further mutation.
- If logs contain secrets, remove them from tracked files and do not commit them.

## 16. Output Artifacts
This skill should produce or request:

- Ansible layout plan.
- Inventory model.
- Variable schema.
- Role and playbook design notes.
- Safety gate checklist.
- Dry-run output.
- Idempotency review notes.
- Logs under `logs/`.
- Install plan.
- Final checks report.
- Safety review findings.
- OpenSpec validation evidence.
