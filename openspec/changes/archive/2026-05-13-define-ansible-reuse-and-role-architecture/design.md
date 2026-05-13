# Design: Ansible Reuse and Role Architecture

## 1. Ansible Reuse Principles
The installer must optimize for reuse between OpenRC and systemd flows.

Rules:

- Do not duplicate Ansible logic between OpenRC and systemd unless behavior is genuinely different.
- Shared behavior must be implemented once under common roles, common task files, common handlers, common validation logic, or common templates.
- Init-specific roles must be thin adapters around init-specific choices.
- Safety gates must be shared and must run before init-specific work can perform target mutation.
- Playbooks may differ by entrypoint, but they should call a shared install flow where practical.
- Bash helpers may be used for low-level bootstrap or disk operations only when they are called through Makefile targets or Ansible tasks with the same shared safety gates.
- Bash helpers must not duplicate OpenRC/systemd Ansible logic or become undocumented operator-facing workflows.
- Reusable roles and playbooks must be inventory-driven and must not depend on libvirt domain names, VM-only IP discovery, qcow2 paths, or `/dev/vda`.
- The primary Ansible path runs from an operator/controller machine over SSH to a target booted into the official Gentoo live ISO.
- libvirt/virsh is a local validation harness for that path, not the final installer architecture.
- Documentation must describe shared behavior once and call out init-specific differences explicitly.

Shared behavior includes:

- preflight checks
- architecture detection
- UEFI detection
- disk discovery
- disk identity reporting
- safety confirmation validation
- partition planning
- filesystem checks
- mount target preparation
- stage3 download framework
- stage3 verification framework
- stage3 extraction
- chroot preparation
- Portage baseline configuration
- package installation framework
- fstab generation
- kernel installation
- GRUB installation framework
- user creation framework
- SSH package installation framework
- final validation checks
- logging
- libvirt VM validation flow
- network live ISO target validation

## 2. Shared Role Architecture
Proposed layout:

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
    init/
      openrc/
      systemd/
```

The exact file layout may change if a future OpenSpec design proves a better reuse boundary, but the final architecture must preserve the rule that common behavior is implemented once.

Common roles own shared behavior:

- `common/preflight`: live ISO, root privilege, architecture, UEFI, network, time, and required tool checks.
- `common/live_target`: controller-to-target SSH, Python, official live ISO evidence, architecture, UEFI, network, DNS, and time checks without assuming libvirt.
- `common/disk_detection`: read-only disk inventory and identity reporting.
- `common/disk_safety`: required variables, confirmation checks, host block-device guardrails, VM guest mode checks, and fail-closed behavior.
- `common/partitioning`: partition plan generation and approved execution.
- `common/filesystem`: filesystem checks and approved formatting.
- `common/mount_target`: target and EFI mount preparation.
- `common/stage3`: stage3 download, checksum, signature, architecture, and variant validation framework.
- `common/chroot`: pseudo-filesystem, DNS, and chroot readiness preparation.
- `common/portage`: baseline Portage configuration shared by both init systems.
- `common/package_install`: shared package installation framework.
- `common/fstab`: UUID-based fstab generation.
- `common/kernel`: `gentoo-kernel-bin` installation.
- `common/bootloader`: GRUB installation framework and EFI checks.
- `common/users`: user creation framework with secret-safe input.
- `common/ssh`: SSH package and enablement framework.
- `common/final_checks`: final read-only validation.

## 3. Init-specific Role Architecture
Init-specific behavior must live under `roles/init/openrc/` and `roles/init/systemd/` or an equivalent isolated structure.

OpenRC-specific behavior:

- OpenRC stage3 selection.
- OpenRC profile selection.
- `rc-update` service enablement.
- OpenRC-compatible syslog and cron packages.
- OpenRC-specific validation.

systemd-specific behavior:

- systemd stage3 selection.
- systemd profile selection.
- `systemctl` service enablement.
- systemd-journald assumptions.
- systemd-specific validation.

Forbidden cross-calls:

- OpenRC workflows must not call `systemctl`.
- systemd workflows must not call `rc-update` or `rc-service`.
- Init-specific roles must not partition, format, wipe, or select disks directly.

## 4. Variable Model
Shared variables should be defined once in `group_vars/all.yml` or equivalent:

- `install_disk`
- `hostname`
- `admin_user`
- `filesystem`
- `boot_mode`
- `stage3_variant`
- `stage3_flavor`
- `init_system`
- `enable_ssh`
- `confirm_wipe_disk`
- `target_mount`
- `efi_mount`
- `vm_guest_mode`
- `ansible_live_host`
- `ansible_live_port`
- `ansible_live_user`

Init-specific variables should live in variant files:

- `group_vars/openrc.yml`
- `group_vars/systemd.yml`

Required variable rules:

- `install_disk` must not have a default.
- `confirm_wipe_disk` must be explicitly set for destructive operations.
- `init_system` must be either `openrc` or `systemd`.
- `stage3_variant` must match `init_system`.
- `stage3_flavor` must be `standard`, `hardened`, or `musl` and select the matching official stage3/profile family.
- `filesystem` defaults may remain simple, such as `ext4`, but must be documented.
- `boot_mode` defaults may remain `uefi`, but BIOS fallback must be explicit if supported later.
- `vm_guest_mode=true` may relax only host-specific assumptions that do not weaken disk safety.
- libvirt VM `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the guest VM.
- `ansible_live_host` must not default to a VM IP or physical host.
- When `ansible_live_host` is omitted, Makefile wrappers may use local libvirt VM discovery for validation only.

## 5. Task Include/Import Strategy
Use shared task includes for shared behavior and init-specific task files only for genuine differences.

Rules:

- `install-openrc.yml` and `install-systemd.yml` should set or load init-specific variables, then invoke `install-basic-console.yml` or an equivalent shared flow.
- Shared flow tasks must call common roles in a stable order: preflight, disk detection, safety gates, partitioning, filesystem, mount target, stage3, chroot, Portage, packages, fstab, kernel, bootloader, users, SSH, final checks.
- Use `import_role` for static role ordering where practical.
- Use `include_tasks` for variant-specific task selection based on `init_system`.
- Avoid duplicated task files whose only difference is package names or service manager commands; use variables and shared tasks instead.

## 6. Handler Reuse Policy
Handlers must be shared unless the handler action differs by init system.

Rules:

- Shared handlers belong in common roles.
- Init-specific handlers belong under `init/openrc` or `init/systemd`.
- Service enablement or restart handlers must select the correct service manager through explicit init-specific dispatch.
- OpenRC handler files must not call `systemctl`.
- systemd handler files must not call `rc-update` or `rc-service`.

## 7. Template Reuse Policy
Templates must be shared unless rendered content genuinely differs by init system.

Rules:

- Shared templates belong in common roles.
- Init-specific templates must have explicit names, such as `openrc-*` or `systemd-*`, or live under init-specific template directories.
- Template variables must come from the shared variable model where possible.
- Do not copy a template just to change one package name; use variables.
- Generated files that affect boot, mounts, users, or services must have validation tasks.

## 8. Validation Task Reuse Policy
Validation tasks must be reusable and run for both OpenRC and systemd flows.

Shared validation includes:

- architecture is amd64
- boot mode is UEFI unless explicitly configured otherwise
- target disk identity is displayed
- disk confirmation is present before destructive tasks
- target mount exists
- EFI mount exists
- stage3 variant matches `init_system`
- fstab uses UUIDs or stable identifiers
- kernel files exist
- GRUB files exist
- expected services are enabled through the correct init system
- logs exist and contain no known secret values

Init-specific validation includes:

- OpenRC profile and services for OpenRC.
- systemd profile and units for systemd.
- No forbidden service-manager command appears in the wrong flow.

## 9. Safety Gate Reuse Policy
Safety gates must be implemented once and reused by both OpenRC and systemd flows.

Required shared gates:

- `install_disk` is explicitly provided.
- `install_disk` has no default.
- Disk model, serial, size, partition table, filesystems, and mountpoints are shown before destructive tasks.
- `confirm_wipe_disk` is explicitly set before destructive operations.
- libvirt VM guest disk `/dev/vda` is accepted only with explicit `install_disk=/dev/vda` inside the VM.
- Host block devices are never selected automatically.
- Destructive tasks fail closed on ambiguity.

No role may bypass shared safety checks. Init-specific roles may consume safety facts, but they must not redefine or weaken safety gates.

## 10. Documentation Reuse Policy
Documentation must follow the same reuse-first model.

Rules:

- Shared Ansible architecture is documented once under `docs/` and `skills/ansible-gentoo-installer.md`.
- Init-specific differences are documented as short OpenRC and systemd subsections.
- Makefile target changes update `skills/makefile-control-plane.md`.
- Agent behavior changes update `agents/ansible-installer-agent.md`.
- Project-wide reuse rules update `AGENTS.md`.
- OpenSpec implementation tasks must include documentation updates.

Documentation must not claim Ansible roles or playbooks exist until they are implemented.

## 11. Makefile Integration
The Makefile should expose high-level operator-facing targets:

- `make install-openrc`
- `make install-systemd`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`
- `make ansible-check`
- `make ansible-dry-run PROFILE=openrc`
- `make ansible-dry-run PROFILE=systemd`

Makefile rules:

- The Makefile should pass init-specific variables into a shared Ansible flow where practical.
- `PROFILE=openrc` maps to `init_system=openrc`.
- `PROFILE=systemd` maps to `init_system=systemd`.
- Destructive targets must require explicit disk and confirmation variables.
- Operator-facing docs must list only targets that exist in the current Makefile; future targets must be labeled planned.
- Bash helper scripts used by Makefile targets must be documented as implementation details unless the Makefile exposes them as operator-facing behavior.
- Makefile Ansible targets must accept an explicit network live ISO target such as `ANSIBLE_LIVE_HOST=...` and must not require libvirt for real network installs.

## 12. OpenSpec Integration
Future Ansible implementation changes must:

- Reference this architecture rule.
- Reference the Ansible quality standards and describe how syntax/lint checks, FQCN usage, command-like tasks, idempotency, check mode, diff safety, secret handling, and host-key scope are handled.
- Identify shared roles affected.
- Identify init-specific roles affected.
- Explain why any duplicated logic is necessary.
- Include safety review tasks for destructive behavior.
- Include documentation tasks for operator behavior changes.
- Validate with `openspec validate <change> --strict` and `openspec validate --all --strict`.

## 13. Testing Strategy with libvirt VM
libvirt VM testing is the safe first test environment for both OpenRC and systemd flows, but it is not the product architecture.

Rules:

- libvirt VM tests boot the official Gentoo live ISO from `./gentoo.iso`.
- libvirt VM tests use qcow2 disks under `./var/libvirt/`.
- libvirt VM tests must not touch host block devices.
- Reusable roles and playbooks must also work for non-libvirt network live ISO targets selected through inventory or Makefile variables.
- OpenRC and systemd install plans should be validated in libvirt before real hardware testing.
- `vm_guest_mode=true` can be used to document that `/dev/vda` is expected inside the guest VM.
- `vm_guest_mode=true` must not disable destructive confirmation or disk identity checks.

## 14. Anti-duplication Rules
A review must reject or require changes when:

- OpenRC and systemd roles duplicate shared disk, mount, stage3, kernel, bootloader, user, SSH, logging, or validation logic.
- Two task files differ only by variable values that could be supplied through variant variables.
- Safety checks are copied into multiple roles and can drift.
- Init-specific roles perform destructive disk operations directly.
- Bash helpers bypass Makefile targets, shared Ansible safety gates, or documentation requirements.
- Ansible tasks omit FQCN, task names, idempotency guards, or command-like task justification.
- Ansible lint/syntax gates are skipped without explanation.
- OpenRC tasks call `systemctl`.
- systemd tasks call `rc-update` or `rc-service`.
- Documentation repeats full shared procedures in both OpenRC and systemd sections.

Allowed duplication:

- Small init-specific task files for service manager commands.
- Variant variable files.
- Init-specific validation tasks.
- Init-specific package lists where package choices genuinely differ.

## 15. Review Checklist
Before approving future Ansible implementation:

- Are shared behaviors implemented in common roles?
- Are init-specific differences isolated and explicit?
- Does `install_disk` have no default?
- Are destructive confirmations shared and required?
- Does the Makefile expose operator-facing actions?
- Do OpenRC flows avoid `systemctl`?
- Do systemd flows avoid `rc-update` and `rc-service`?
- Are libvirt VM `/dev/vda` assumptions limited to explicit guest-mode configuration?
- Are handlers, templates, validation tasks, and safety gates reused?
- Do tasks satisfy FQCN, task-name, module-first, idempotency, check-mode, diff, and secret-redaction standards?
- Did `make ansible-check` run or was any unavailable lint gate reported clearly?
- Are documentation updates included and accurate?
- Does OpenSpec validation pass?
