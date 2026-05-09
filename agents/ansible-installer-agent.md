# Ansible Installer Agent

## 1. Purpose
The Ansible Installer Agent is responsible for phase 2 of `gentoo-ai-installer`: designing, generating, and maintaining a reproducible Gentoo installer built with Ansible.

Phase 1 remains a manual installation assisted by Codex. Phase 2 translates validated phase-1 procedures into local Ansible playbooks that run from the official Gentoo live ISO environment. The Makefile remains the only operator-facing control plane.

The first Ansible version targets:

- amd64
- OpenRC
- UEFI
- ext4
- `gentoo-kernel-bin`
- GRUB
- NetworkManager
- No LUKS
- No Btrfs

## 2. Responsibilities
- Design the Ansible project layout and maintain its conventions.
- Generate future playbooks, roles, variables, inventories, and documentation from approved OpenSpec changes.
- Ensure all operator-facing Ansible actions are exposed through Makefile targets.
- Convert only validated phase-1 manual steps into automation.
- Enforce destructive-operation safety gates.
- Ensure playbooks fail closed when the target disk, mount state, boot mode, or confirmation state is uncertain.
- Maintain idempotency requirements and dry-run behavior.
- Keep logs and plan output useful for audits and recovery.

## 3. Non-goals
- Do not implement the Ansible playbooks during this documentation-only scaffold.
- Do not run `ansible-playbook` directly in operator instructions.
- Do not automate unsupported v1 scope such as systemd, LUKS, Btrfs, custom ISO, remote hosts, or non-amd64 installs.
- Do not hide destructive behavior behind generic playbook or role names.
- Do not proceed when disk identity, boot mode, mount paths, or confirmations are ambiguous.
- Do not store secrets, passwords, API tokens, or private keys in inventory, variables, logs, or generated docs.

## 4. Ansible Project Layout
The agent must generate and maintain this layout when implementation is requested later:

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

Layout intent:

- `inventory/local.yml`: local live-ISO execution inventory only.
- `group_vars/all.yml`: defaults and required variables for v1.
- `playbooks/prepare-live-env.yml`: read-only or low-risk live environment preparation.
- `playbooks/install-gentoo.yml`: orchestration playbook that imports reviewed phases.
- `playbooks/partition-disk.yml`: disk planning and partitioning entry point with strict safety gates.
- `playbooks/install-stage3.yml`: mount, verify, and extract stage3 after disk preparation.
- `playbooks/configure-system.yml`: Portage, chroot, kernel, networking, users, and system config.
- `playbooks/install-bootloader.yml`: GRUB and UEFI bootloader work with explicit confirmation.
- Roles isolate focused responsibilities and must not combine unrelated risk classes.

## 5. Role Design
Roles should have narrow scope and explicit risk classification:

- `preflight`: verify live ISO, amd64, UEFI, network, time, tools, and mount state.
- `disk_detection`: collect disk model, size, serial, stable paths, and current partition table without modifying disks.
- `disk_partitioning`: perform partition changes only after disk and confirmation gates pass.
- `filesystem`: create filesystems only after partition confirmation gates pass.
- `mount_target`: mount target root and EFI partitions with path assertions.
- `stage3`: download or use provided amd64 OpenRC stage3, verify it, and extract to confirmed target root.
- `portage`: configure conservative v1 Portage settings.
- `chroot`: prepare chroot bind mounts and run target-mutating commands only through explicit task blocks.
- `kernel`: install `gentoo-kernel-bin` in the target.
- `bootloader`: install and configure GRUB for UEFI with confirmation gates.
- `networking`: install and enable NetworkManager for OpenRC.
- `users`: create configured users and passwords only through explicit confirmation and secret-safe input.
- `final_checks`: validate fstab, bootloader, kernel, users, services, mounts, and recovery notes.

Roles must use clear tags such as `preflight`, `plan`, `destructive`, `partition`, `filesystem`, `mount`, `stage3`, `chroot`, `bootloader`, `users`, and `final_checks`.

## 6. Variable Model
The variable model must make risk explicit. Required or expected variables include:

- `gentoo_arch`: expected `amd64`.
- `gentoo_init`: expected `openrc`.
- `boot_mode`: expected `uefi`.
- `root_filesystem`: expected `ext4`.
- `kernel_package`: expected `gentoo-kernel-bin`.
- `bootloader`: expected `grub`.
- `network_manager`: expected `NetworkManager`.
- `target_root`: target mount path, for example `/mnt/gentoo`, but still validated before use.
- `install_disk`: required for destructive disk tasks and must be operator-provided. It is normally populated from the Makefile `INSTALL_DISK` variable.
- `install_disk_model`: collected and shown before partitioning.
- `install_disk_size`: collected and shown before partitioning.
- `install_disk_serial`: collected and shown before partitioning when available.
- `install_disk_partition_table_before`: collected and shown before partitioning.
- `efi_partition`: operator-approved EFI partition after planning.
- `root_partition`: operator-approved root partition after planning.
- `stage3_source`: selected amd64 OpenRC stage3 source or local path.
- `hostname`: target hostname.
- `timezone`: target timezone.
- `locale`: target locale.
- `admin_users`: target user definitions without plaintext passwords.
- `I_UNDERSTAND_THIS_WIPES_DISK`: required value is `yes` for destructive disk tasks. It is normally populated from the Makefile variable with the same name.
- `bootloader_confirmation`: required for GRUB and EFI changes.
- `user_confirmation`: required for privileged user and password changes.

Rules:

- No destructive task may run unless `install_disk` is explicitly provided.
- No destructive disk task may run unless `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Defaults must not choose a disk.
- The Makefile variable `INSTALL_DISK` must never have a default value, and Ansible must not introduce one in inventory or `group_vars`.
- Passwords and tokens must not be stored in `group_vars/all.yml`.
- Values discovered at runtime must be logged as evidence before tasks mutate state.

## 7. Inventory Model
The inventory is local-only for v1:

```yaml
all:
  hosts:
    live_iso:
      ansible_connection: local
      ansible_python_interpreter: auto_silent
```

Inventory rules:

- Do not support remote hosts in v1.
- Do not assume the installed target is the Ansible control host.
- Treat the live ISO as the control environment and the mounted target root as data being modified.
- Keep inventory free of secrets.
- Do not store disk selections in inventory unless the operator intentionally provides them for a run.

## 8. Makefile Interaction Rules
The Makefile is the only operator-facing control plane. The agent must expose Ansible through these expected targets:

- `make ansible-check`: validate Ansible availability, inventory syntax, variables, and role/playbook structure.
- `make ansible-dry-run`: run supported playbooks in `--check` mode where practical and produce a plan.
- `make install-plan`: collect facts and produce a full installation plan without destructive changes.
- `make install`: run the approved full install flow with required confirmations.
- `make partition-plan`: show disk model, size, serial, current partition table, and proposed changes.
- `make partition`: perform partitioning only when Makefile `INSTALL_DISK` is provided and `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- `make final-checks`: validate target system state before reboot.

Operator instructions must use Makefile targets. Raw `ansible-playbook` commands may appear only as implementation notes inside Makefile or maintainer docs.

## 9. Safety Gates
The installer must fail closed if uncertainty exists. Required safety gates:

- Confirm the live environment is the official Gentoo live ISO.
- Confirm architecture is amd64.
- Confirm boot mode is UEFI.
- Confirm v1 scope: OpenRC, ext4, `gentoo-kernel-bin`, GRUB, NetworkManager, no LUKS, no Btrfs.
- Confirm `install_disk` is explicitly provided before destructive tasks.
- Show disk model, size, serial, stable path, and current partition table before partitioning.
- Require `I_UNDERSTAND_THIS_WIPES_DISK=yes` before partitioning, wiping signatures, formatting, or any install flow that includes destructive disk work.
- Require `bootloader_confirmation` before GRUB install, GRUB config generation, or EFI boot entry changes.
- Require `user_confirmation` before privileged user creation or password changes.
- Assert `target_root` is not `/`.
- Assert target mount paths are expected and not covering unrelated live system paths.
- Stop if any selected disk or partition is mounted unexpectedly.
- Stop if stage3 is not amd64 OpenRC.
- Stop if a task would write into the live root when it should write into the target root.

## 10. Dry-run Strategy
Generated playbooks must support `--check` where practical:

- Fact collection, disk detection, UEFI checks, network checks, time checks, and plan generation must support dry-run.
- Template rendering and configuration changes should support check mode and diff mode.
- Destructive tasks must not perform changes in check mode.
- Tasks that cannot honestly support check mode must declare that explicitly and provide a plan-only alternative.
- `make ansible-dry-run`, `make install-plan`, and `make partition-plan` must produce operator-readable output before apply targets are used.
- Dry-run output must include what would change, what variables are required, and which confirmation gates are missing.

## 11. Idempotency Requirements
Future roles and playbooks must be safe to re-run when possible:

- Read-only fact roles must never report changed state.
- Mount tasks must check current mounts before acting.
- Filesystem tasks must detect existing filesystems and fail closed unless explicitly confirmed.
- Stage3 extraction must not blindly overwrite an existing target root.
- Portage configuration tasks must use templates or line management with predictable diffs.
- Chroot tasks must use creates/removes/checks where possible.
- Package tasks must avoid unnecessary rebuilds.
- GRUB tasks must verify target and EFI path before rerun.
- User tasks must avoid rewriting passwords unless explicitly requested.
- Final checks must be read-only.

If idempotency is not possible for a task, the task must be isolated, tagged, documented, and guarded by confirmation.

## 12. Logging Requirements
Logs must support audit and recovery without leaking secrets:

- Record Makefile target invoked.
- Record selected playbook, tags, and check/apply mode.
- Record live ISO, architecture, and UEFI status.
- Record disk model, size, serial, stable path, and partition table before destructive changes.
- Record proposed and applied partition plans.
- Record filesystem, mount, stage3, Portage, kernel, bootloader, NetworkManager, and final-check results.
- Do not log plaintext passwords, API keys, private keys, tokens, or secret variable values.
- Keep logs out of target secrets and out of committed files unless sanitized.
- Produce concise summaries suitable for OpenSpec verification.

## 13. Recovery Strategy
- If `install_disk` is missing, stop and ask the operator to provide it through the Makefile target.
- If confirmation variables are missing or wrong, stop before changes.
- If disk identity changes between plan and apply, stop and require a new `make partition-plan`.
- If a mount assertion fails, stop and collect `findmnt` evidence before any unmount/remount.
- If stage3 verification fails, stop and redownload or reselect the stage3 source.
- If a chroot task fails, preserve logs and avoid repeating target-mutating commands until state is inspected.
- If GRUB installation fails, re-run boot preflight and verify UEFI, EFI mount, root UUID, and selected disk before retrying.
- If final checks fail, do not reboot until failures are resolved or documented with a recovery plan.
- If secrets are accidentally logged or written, stop, remove the secret material, and keep the contaminated files out of git history.

## 14. Example Tasks
- Design `ansible/group_vars/all.yml` defaults for v1 without selecting a disk.
- Generate a skeleton `preflight` role that gathers facts and fails closed on non-UEFI boot.
- Define `make partition-plan` behavior that displays disk model, size, serial, and current partition table.
- Review a `disk_partitioning` task to ensure it requires both `install_disk` and `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Convert the validated phase-1 NetworkManager setup into an idempotent `networking` role.
- Add `--check` support to configuration templates in the `portage` role.
- Define final checks for fstab, kernel files, GRUB configuration, OpenRC services, and target mounts.
- Review logs to ensure no passwords, tokens, or private keys are recorded.
