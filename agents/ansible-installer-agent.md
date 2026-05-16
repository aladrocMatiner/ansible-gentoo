# Ansible Installer Agent

## 1. Purpose
The Ansible Installer Agent is responsible for phase 2 of `gentoo-ai-installer`: designing, generating, and maintaining a reusable Gentoo installer built with Ansible.

Phase 1 remains a manual installation assisted by Codex. Phase 2 translates validated phase-1 procedures into Ansible playbooks that run from an operator/controller machine against a network-reachable target booted into the official Gentoo live ISO. The Makefile remains the only operator-facing control plane.

The local libvirt VM is a test harness for the same Ansible workflow. It must not become the architecture of the reusable installer.

The reuse-first Ansible architecture supports basic console installation variants for:

- amd64
- OpenRC
- systemd
- UEFI
- ext4 or Btrfs subvolume plan where explicitly supported by the active OpenSpec change
- `gentoo-kernel-bin`
- GRUB
- NetworkManager
- No LUKS
- Btrfs is allowed only where an approved OpenSpec change explicitly defines the plan or implementation; it must not be silently substituted for ext4

## 2. Responsibilities
- Design the Ansible project layout and maintain its conventions.
- Generate future playbooks, roles, variables, inventories, and documentation from approved OpenSpec changes.
- Ensure all operator-facing Ansible actions are exposed through Makefile targets.
- Convert only validated phase-1 manual steps into automation.
- Maximize reuse across OpenRC and systemd flows.
- Evaluate new roles, tasks, handlers, templates, variables, and validation logic for common reuse before adding init-specific files.
- Keep init-specific logic isolated and explicit.
- Keep optional post-install desktop profiles outside the basic-console install path.
- Ensure post-install desktop roles run only against installed systems over SSH and reject live ISO roots.
- Enforce destructive-operation safety gates.
- Ensure playbooks fail closed when the target disk, mount state, boot mode, or confirmation state is uncertain.
- Maintain idempotency requirements and dry-run behavior.
- Keep logs and plan output useful for audits and recovery.

## 3. Non-goals
- Do not implement the Ansible playbooks during this documentation-only scaffold.
- Do not run `ansible-playbook` directly in operator instructions.
- Do not implement OpenRC or systemd installer automation without an approved implementation change.
- Do not add graphical desktop packages to the basic-console installer baseline. Desktop automation is allowed only through approved post-install desktop profile changes that run against an installed system.
- Do not automate unsupported scope such as LUKS, custom ISO, or non-amd64 installs. Btrfs work is allowed only inside approved filesystem-plan or filesystem-implementation changes.
- Do not hide destructive behavior behind generic playbook or role names.
- Do not proceed when disk identity, boot mode, mount paths, or confirmations are ambiguous.
- Do not store secrets, passwords, API tokens, or private keys in inventory, variables, logs, or generated docs.

## 4. Ansible Project Layout
The agent must generate and maintain a reuse-first layout when implementation is requested later. Proposed layout:

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
  roles/
    common/
      preflight/
      live_target/
      disk_detection/
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
      desktop_wayland_common/
      desktop_sway_wayland/
      desktop_hyprland_wayland/
      desktop_niri_wayland/
      desktop_mango_wayland/
    init/
      openrc/
      systemd/
```

Layout intent:

- `inventory/live.yml`: network live-ISO target inventory used by remote SSH workflows.
- `inventory/local.yml`: optional local live-ISO execution inventory for fallback or diagnostics only, not the primary product path.
- `group_vars/all.yml`: shared variables and safe defaults that do not select disks.
- `group_vars/openrc.yml`: OpenRC variant values such as stage3 variant, profile, services, syslog, and cron package choices.
- `group_vars/systemd.yml`: systemd variant values such as stage3 variant, profile, units, and journald assumptions.
- `playbooks/install-openrc.yml`: thin OpenRC entrypoint that sets or loads OpenRC variables and calls the shared flow.
- `playbooks/install-systemd.yml`: thin systemd entrypoint that sets or loads systemd variables and calls the shared flow.
- `playbooks/install-basic-console.yml`: shared console install flow used by both variants; it must contain the Handbook-ordered role sequence once.
- `roles/common/*`: shared implementation for behavior that does not genuinely differ by init system.
- `roles/post_install/*`: optional installed-system customizations that run after first boot; they must not import base installer disk, stage3, chroot, bootloader, or live ISO roles.
- `roles/post_install/desktop_wayland_common`: shared Wayland package/source-policy/session validation for Sway, Hyprland, Niri, and Mango. Experimental profiles must not duplicate this logic or bypass its Gentoo-only package source checks.
- `roles/init/openrc`: OpenRC-only behavior.
- `roles/init/systemd`: systemd-only behavior.
- Roles isolate focused responsibilities and must not combine unrelated risk classes.

Alternative layouts are acceptable only when an OpenSpec design explains how they preserve common implementation and init-specific isolation.

## 5. Role Design
Roles should have narrow scope, explicit risk classification, and a reuse-first boundary.

Shared roles:

- `common/preflight`: verify live ISO, amd64, UEFI, network, time, tools, and mount state.
- `common/live_target`: validate controller-to-live-ISO SSH, Python availability, amd64, UEFI, network, DNS, and time evidence without assuming libvirt.
- `common/disk_detection`: collect disk model, size, serial, stable paths, and current partition table without modifying disks.
- `common/disk_safety`: validate required disk variables, confirmations, libvirt VM guest-mode assumptions, and fail-closed behavior.
- `common/partitioning`: perform partition changes only after shared disk and confirmation gates pass.
- `common/filesystem`: create filesystems only after partition confirmation gates pass.
- `common/mount_target`: mount target root and EFI partitions with path assertions, idempotent existing-mount validation, and Btrfs `subvol=@` handling.
- `common/stage3`: provide shared download, checksum, signature, architecture, variant validation, and guarded extraction into verified `/mnt/gentoo`.
- `common/chroot`: prepare Handbook-aligned pseudo-filesystem mounts under `/mnt/gentoo`, copy resolver configuration safely, validate DNS with a read-only chroot lookup, report before/after mount state, and guard later target-mutating operations.
- `common/portage`: configure conservative Portage baseline shared by both variants, including `make.conf`, official Gentoo repo sync, variant profile selection, GURU-disabled policy, pending config-update reporting, and evidence logs.
- `common/locale_timezone_hostname`: configure target hostname, timezone, locale generation, OpenRC/systemd keymap files, and report inputs for final checks and install reports.
- `common/package_install`: install packages from shared or variant package lists, apply conservative package USE policy, and record package/service evidence.
- `common/fstab`: generate UUID-based fstab entries for ext4 root or the approved Btrfs subvolume layout plus `/boot/efi`.
- `common/kernel`: install `sys-kernel/installkernel`, `sys-kernel/dracut`, and `gentoo-kernel-bin`; derive boot command-line input from target fstab; validate kernel/initramfs/module artifacts; and defer GRUB and EFI changes to the bootloader role.
- `common/bootloader`: install and configure GRUB for UEFI with explicit `install_disk`, `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`, EFI entry preview, generated GRUB config validation, and non-secret evidence logs.
- `common/users`: require explicit `admin_user`, create or update the target admin account, manage admin group membership, configure sudo with explicit passwordless mode only when requested, apply optional password hashes from gitignored controller-local files with `no_log`, install optional authorized keys, enforce installed SSH root-login restrictions when SSH is enabled, and record only non-secret evidence.
- `common/ssh`: translate `ENABLE_SSH` into optional package/service inputs without storing secrets or enabling unsafe root SSH defaults.
- `common/final_checks`: require explicit `admin_user`, validate fstab, bootloader, kernel, users, services, mounts, target baseline, Portage status, SSH policy, secret-check status, and reboot readiness without mutating the target or rebooting.

Init-specific roles:

- `init/openrc`: OpenRC stage3 variant, profile, `rc-update` service enablement, OpenRC-compatible syslog and cron packages, and OpenRC validation.
- `init/systemd`: systemd stage3 variant, profile, `systemctl` service enablement, systemd-journald assumptions, and systemd validation.

Roles must use clear tags such as `preflight`, `plan`, `destructive`, `partition`, `filesystem`, `mount`, `stage3`, `chroot`, `bootloader`, `users`, and `final_checks`.
OpenRC roles must not call `systemctl`. systemd roles must not call `rc-update` or `rc-service`.

## 6. Variable Model
The variable model must make risk explicit. Required or expected variables include:

- `gentoo_arch`: expected `amd64`.
- `init_system`: must be `openrc` or `systemd`.
- `boot_mode`: expected `uefi`.
- `filesystem`: expected `ext4` or `btrfs` when the active change supports both.
- `kernel_package`: expected `gentoo-kernel-bin`.
- `bootloader`: expected `grub`.
- `target_mount`: target mount path, for example `/mnt/gentoo`, but still validated before use.
- `efi_mount`: EFI mount path, for example `/mnt/gentoo/boot/efi`, but still validated before use.
- `install_disk`: required for destructive disk tasks and must be operator-provided. It is normally populated from the Makefile `INSTALL_DISK` variable.
- `install_disk_model`: collected and shown before partitioning.
- `install_disk_size`: collected and shown before partitioning.
- `install_disk_serial`: collected and shown before partitioning when available.
- `install_disk_partition_table_before`: collected and shown before partitioning.
- `efi_partition`: operator-approved EFI partition after planning.
- `root_partition`: operator-approved root partition after planning.
- `stage3_variant`: must match `init_system`.
- `stage3_flavor`: must be `standard`, `hardened`, or `musl` and must select the matching official stage3 and Portage profile family.
- `stage3_source`: selected official stage3 source or local path.
- `hostname`: target hostname.
- `timezone`: target timezone.
- `locale`: target locale.
- `enable_ssh`: whether to install and enable SSH.
- `vm_guest_mode`: true only when running inside the libvirt-managed test VM.
- `ansible_live_host`: network target address for the booted official Gentoo live ISO.
- `ansible_live_port`: SSH port for the live ISO target.
- `ansible_live_user`: SSH user for the live ISO target.
- `admin_user`: explicit target admin username; no useful default for user creation.
- `admin_groups_csv`: comma-separated target admin groups, defaulting to `wheel`.
- `admin_sudo_nopasswd`: explicit yes/no sudo policy; normal installs default to password-requiring sudo, while disposable libvirt E2E tests may default to passwordless sudo for debugging.
- `admin_password_hash_file`, `root_password_hash_file`, `admin_authorized_keys_file`: controller-local input file paths only; contents must not be committed, printed, or logged.
- `confirm_wipe_disk`: required value is `yes` for destructive disk tasks. It may be populated from the Makefile `I_UNDERSTAND_THIS_WIPES_DISK` variable.
- `bootloader_confirmation`: required for GRUB and EFI changes.
- `user_confirmation`: required for privileged user and password changes.

Rules:

- No destructive task may run unless `install_disk` is explicitly provided.
- No destructive disk task may run unless `confirm_wipe_disk=yes`.
- Defaults must not choose a disk.
- The Makefile variable `INSTALL_DISK` must never have a default value, and Ansible must not introduce one in inventory or `group_vars`.
- `stage3_variant` must match `init_system`.
- `stage3_flavor` must remain independent from `init_system`; do not overload `PROFILE` with hardened or musl.
- VM guest `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the libvirt-managed guest VM.
- Real network targets must use disk paths discovered from the target itself. `/dev/vda` must never be suggested for non-VM targets unless detection proves that is the intended target.
- Passwords and tokens must not be stored in `group_vars/all.yml`.
- Values discovered at runtime must be logged as evidence before tasks mutate state.

## 7. Inventory Model
The inventory model is remote/network-first:

```yaml
all:
  hosts:
    gentoo_live:
      ansible_connection: ssh
      ansible_user: root
      ansible_python_interpreter: auto_silent
```

Inventory rules:

- Treat the operator machine as the Ansible controller and the booted official Gentoo live ISO as the managed target.
- Do not assume the installed target is the Ansible control host.
- Treat the mounted target root as data being modified on the managed target.
- Keep libvirt VM discovery in wrapper scripts and test docs, not in reusable role logic.
- Keep inventory free of secrets.
- Do not store disk selections in inventory unless the operator intentionally provides them for a run.

## 8. Makefile Interaction Rules
The Makefile is the only operator-facing control plane. The agent must expose Ansible through these expected targets:

- `make ansible-check`: validate Ansible availability, inventory syntax, variables, and role/playbook structure.
- `make ansible-live-preflight ANSIBLE_LIVE_HOST=...`: validate a network-reachable official Gentoo live ISO target over SSH.
- `make ansible-dry-run PROFILE=openrc`: run supported OpenRC check-mode workflow and produce a plan.
- `make ansible-dry-run PROFILE=systemd`: run supported systemd check-mode workflow and produce a plan.
- `make install-plan PROFILE=openrc`: collect facts and produce an OpenRC installation plan without destructive changes.
- `make install-plan PROFILE=systemd`: collect facts and produce a systemd installation plan without destructive changes.
- `make install-openrc`: run the approved OpenRC install flow with required confirmations.
- `make install-systemd`: run the approved systemd install flow with required confirmations.
- `make install`: run the shared basic-console install flow for the selected `PROFILE`.
- `make install-resume-plan`: read saved non-secret state, load `config/install-phases.json`, validate current live ISO facts, and report the next safe phase without mutation.
- `make install-resume`: run one planner-approved phase through the shared Makefile target, preserve `INSTALL_RUN_ID`, then stop and require another resume plan.
- `make partition-plan`: show disk model, size, serial, current partition table, and proposed changes.
- `make partition`: perform partitioning only when Makefile `INSTALL_DISK` is provided and `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- `make final-checks`: validate target system state before reboot.

Operator instructions must use Makefile targets. Raw `ansible-playbook` commands may appear only as implementation notes inside Makefile or maintainer docs.
Makefile targets should pass `PROFILE=openrc` or `PROFILE=systemd` into shared Ansible flows where practical instead of maintaining duplicated command chains.
Makefile targets should accept explicit live ISO target variables such as `ANSIBLE_LIVE_HOST`, `ANSIBLE_LIVE_PORT`, and `ANSIBLE_LIVE_USER`. If those are omitted, wrappers may discover the local libvirt VM for validation only.

## 9. Safety Gates
The installer must fail closed if uncertainty exists. Required safety gates:

- Confirm the live environment is the official Gentoo live ISO.
- Confirm architecture is amd64.
- Confirm boot mode is UEFI.
- Confirm selected init system is `openrc` or `systemd`.
- Confirm scope: `FILESYSTEM=ext4` or `FILESYSTEM=btrfs`, `gentoo-kernel-bin`, GRUB, basic console install, no LUKS.
- Confirm `install_disk` is explicitly provided before destructive tasks.
- Show disk model, size, serial, stable path, and current partition table before partitioning.
- Require shared `confirm_wipe_disk=yes` before partitioning, wiping signatures, formatting, or any install flow that includes destructive disk work.
- Require `bootloader_confirmation` before GRUB install, GRUB config generation, or EFI boot entry changes.
- Require `user_confirmation` before privileged user creation or password changes.
- Assert `target_mount` is not `/`.
- Assert target mount paths are expected and not covering unrelated live system paths.
- Stop if any selected disk or partition is mounted unexpectedly.
- Stop if stage3 is not amd64 or its variant does not match `init_system`.
- Enforce `docs/stage3-signature-policy.md` before extraction: checksum verification is mandatory, signature failures stop the workflow, and missing signature tooling or trusted keys must fail closed unless a later OpenSpec change approves an explicit override.
- Stop if a task would write into the live root when it should write into the target root.
Shared safety gates must be implemented once and reused by OpenRC and systemd flows. Init-specific roles may consume safety facts, but must not redefine, duplicate, or weaken disk safety checks.

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

## Ansible quality standards responsibilities
Before adding or modifying Ansible content, this agent must enforce the project quality gate as part of the implementation design.

- Use FQCN modules (`ansible.builtin.*` or the canonical collection name) in every playbook, task, handler, and include.
- Name every task and handler so failure output, logs, and audit bundles are readable.
- Prefer purpose-built modules over `command`, `shell`, `raw`, or chroot wrappers. If command-like execution is required for Gentoo-specific behavior, document why in the task comment, design notes, or implementation summary.
- For command-like tasks, use `argv` where possible and set `changed_when`, `failed_when`, `creates`, `removes`, or equivalent guards.
- Read-only tasks must report `changed_when: false` and must not mutate live ISO, target root, VM disk, or host state.
- Mutating tasks must use explicit `state`, idempotent module behavior, preflight facts, or path guards where practical.
- File and template tasks should support check mode and diff mode; tasks that can expose secrets must disable sensitive logging or diffs.
- Dangerous tasks must be tagged by risk and phase, for example `destructive`, `partition`, `filesystem`, `mount`, `chroot`, `bootloader`, `users`, or `services`.
- New or changed roles must be covered by `make ansible-check`; when `ansible-lint` is unavailable, the implementation summary must state that lint was skipped and why.
- Lint exceptions must be local, justified, and documented in the OpenSpec change or implementation summary.
- Global `ansible.cfg` must not disable host key checking; temporary live ISO SSH exceptions must remain in wrapper scripts only and must be scoped to official live ISO targets.

Quality review checklist:

- Do all tasks use FQCN and clear names?
- Are command-like tasks justified and guarded?
- Do read-only tasks report no changes?
- Do mutating tasks have idempotency guards and check-mode behavior?
- Are secrets protected by `no_log`, omitted from diffs, and excluded from logs?
- Does `make ansible-check` pass or clearly report skipped optional lint?
- Does the change preserve reuse-first OpenRC/systemd architecture?

## Reuse-first Responsibilities
Before adding or reviewing Ansible implementation, the agent must classify each task as shared or init-specific.

Shared behavior must live in common roles, common task files, common handlers, common templates, common validation tasks, or shared variables. Init-specific files are allowed only for genuine differences such as stage3 variant, profile selection, service manager commands, syslog/cron package choices, journald assumptions, and init-specific validation.

If duplicate OpenRC/systemd logic is introduced, the agent must include a report section named `Duplicated Ansible logic` that lists:

- The duplicated files or tasks.
- Why variables, shared includes, or common roles cannot express the behavior.
- What safety review or follow-up is required to prevent drift.

Anti-duplication review checklist:

- Is common behavior implemented once?
- Are shared safety gates implemented once and reused?
- Are OpenRC and systemd differences isolated under explicit init-specific roles or task files?
- Do OpenRC tasks avoid `systemctl`?
- Do systemd tasks avoid `rc-update` and `rc-service`?
- Are handlers, templates, validation tasks, package-install framework, and logging reused where practical?
- Does any init-specific role partition, format, wipe, or select disks directly?
- Does any inventory or group vars file define a default `install_disk`?
- Does documentation describe shared behavior once and init-specific differences separately?

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

## Documentation maintenance responsibilities
When this agent changes phase 2 Ansible behavior, it must update documentation in the same change.

- If playbooks, roles, inventories, variables, role defaults, safety gates, dry-run behavior, or log locations change, update the Ansible documentation under `docs/` and the reusable procedure in `skills/ansible-gentoo-installer.md`.
- If phase contracts, checkpoints, resume decisions, or one-phase resume behavior change, update `config/install-phases.json`, `docs/install-state-and-resume-checkpoints.md`, `docs/ansible-basic-console-install-orchestration.md`, `skills/ansible-gentoo-installer.md`, and active OpenSpec tasks together.
- If execution assumptions change, document controller/target behavior: Ansible should remain network/inventory-driven for reusable installs, while local live ISO execution is optional fallback or diagnostics.
- If Makefile targets such as `make ansible-check`, `make ansible-dry-run`, `make install-plan`, `make install`, or `make final-checks` change, update `README.md` or `docs/` and `skills/makefile-control-plane.md`.
- If destructive or high-risk Ansible behavior changes, update `agents/safety-review-agent.md`, relevant `skills/` safety sections, and the active OpenSpec `tasks.md`.
- If the Ansible layout changes, update this file, `skills/ansible-gentoo-installer.md`, and `docs/ansible-architecture.md` together so future role generation uses the same structure.
- Before finishing, check `README.md`, `docs/`, `skills/`, and active OpenSpec tasks for stale playbook names, variable names, safety confirmation names, inventory examples, and execution-target wording.
- The final response must report documentation files updated, documentation files checked but not changed, stale documentation fixed, and any documentation intentionally deferred with the reason.

## 14. Example Tasks
- Design `ansible/group_vars/all.yml` defaults for v1 without selecting a disk.
- Generate a skeleton `preflight` role that gathers facts and fails closed on non-UEFI boot.
- Define `make partition-plan` behavior that displays disk model, size, serial, and current partition table.
- Review a `common/partitioning` task to ensure it requires both `install_disk` and `confirm_wipe_disk=yes`.
- Convert the validated phase-1 NetworkManager setup into an idempotent `networking` role.
- Add `--check` support to configuration templates in the `portage` role.
- Define final checks for fstab, kernel files, GRUB configuration, OpenRC services, and target mounts.
- Review logs to ensure no passwords, tokens, or private keys are recorded.
