# Ansible Architecture

This document defines the planned Ansible architecture for `gentoo-ai-installer`. It is a policy and design document; it does not mean the Ansible roles or playbooks are implemented yet.

## Purpose
The Ansible installer phase should turn validated manual Gentoo installation steps into a reusable, network-capable installer. The normal execution model is an operator/controller machine running Ansible over SSH against a target booted into the official Gentoo live ISO.

Local libvirt/virsh workflows are a validation harness for that installer. They provide a safe VM target, serial-console SSH bootstrap, and disposable qcow2 disks so the same Ansible playbooks can be tested before real hardware. VM-specific paths, domain names, and `/dev/vda` assumptions must stay out of reusable roles except in test fixtures and examples.

Before destructive workflows are recommended for a physical machine, operators must run `make real-hardware-check` with an explicit network live ISO target and selected disk. That readiness report does not replace destructive or bootloader confirmations.

The architecture must support basic console installs for OpenRC and systemd while reusing as much implementation as possible.

Future installer roles and playbooks must use the official Gentoo AMD64 Handbook as the baseline procedure: <https://wiki.gentoo.org/wiki/Handbook:AMD64>. The project may translate Handbook steps into Ansible tasks, variables, templates, and validations, but deviations must be intentional, documented, and reviewed through OpenSpec.

Current deliberate project choices on top of the Handbook baseline:

- NetworkManager is the v1 network manager rather than the Handbook's simplest `dhcpcd` example.
- GRUB is the v1 bootloader for UEFI.
- The EFI system partition is mounted at `/boot/efi` inside the installed system, corresponding to `/mnt/gentoo/boot/efi` from the live ISO.
- `gentoo-kernel-bin` is the v1 kernel package, with required installkernel/initramfs support configured explicitly.
- ext4 and Btrfs are both planned filesystem variants; Btrfs requires `sys-fs/btrfs-progs` and explicit subvolume mount options.
- vfat/FAT32 EFI support requires `sys-fs/dosfstools`.

## Reuse-first Design
Common behavior must be implemented once and reused.

Shared behavior includes:

- preflight checks
- configuration schema validation
- controller and host requirement validation for Ansible and libvirt test workflows
- architecture and UEFI detection
- disk discovery and identity reporting
- safety confirmation validation
- partition planning
- mount planning
- filesystem planning
- filesystem checks
- mount target preparation
- stage3 download, verification, and extraction framework
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
- network target inventory and SSH connectivity validation
- install state checkpoints
- install audit bundle generation
- destructive command preview
- Handbook traceability reporting
- secret redaction and validation
- logging and error taxonomy
- cleanup/reset safety
- manual intervention recording

Do not duplicate OpenRC and systemd logic unless the behavior genuinely differs. If duplication is necessary, the implementing OpenSpec change must explain why shared roles, variables, handlers, templates, or includes cannot express the behavior.

Shared roles should correspond to Handbook phases where practical. For example, disk preparation, stage3 installation, chroot preparation, Portage configuration, kernel installation, bootloader setup, networking, users, and final checks should each preserve the Handbook order and safety assumptions unless an approved OpenSpec change explains the deviation.

## Ansible Quality Standards
Ansible code in this project must be reviewable, lintable, and rerunnable where practical.

Authoring baseline:

- Use FQCN module names such as `ansible.builtin.assert`.
- Name every task and handler.
- Prefer purpose-built modules over `command`, `shell`, `raw`, or chroot wrappers.
- Use `command.argv` instead of free-form command strings where practical.
- Use explicit module `state` values where supported.
- Keep tasks focused on one risk class.
- Use handlers for service restarts or reloads caused by managed configuration changes.

Command-like task baseline:

- Read-only command tasks must set `changed_when: false`.
- Command tasks that accept non-zero return codes must define `failed_when`.
- Mutating command tasks must use `creates`, `removes`, pre-check facts, path assertions, or equivalent guards where practical.
- Shell pipelines, redirects, globs, and chroot wrappers require extra review because they can hide risk.

Check and diff baseline:

- Plan targets remain mutation-free.
- Apply roles support Ansible check mode where practical.
- Template and file tasks support diff mode unless output can expose secrets.
- Secret-sensitive tasks use `no_log` or equivalent redaction.

Quality gate:

- `make ansible-check` syntax-checks implemented playbooks.
- `make ansible-check` runs `ansible-lint` when it is installed.
- Missing `ansible-lint` is reported clearly until a future release or CI change makes it mandatory.
- Lint exceptions must be local and justified in the OpenSpec change or implementation summary.

Host-key policy:

- `ansible.cfg` must not disable host key checking globally.
- Controller-to-live-ISO wrappers may disable host key checking for that temporary official live ISO wrapper invocation because the live ISO host key changes after reboot.
- Local live ISO execution must not depend on globally disabled host-key checking.

## Proposed Directory Layout
Planned layout:

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
      config_validation/
      host_requirements/
      live_target/
      disk_detection/
      install_plan/
      partition_plan/
      mount_plan/
      filesystem_plan/
      disk_safety/
      destructive_preview/
      install_state/
      audit_bundle/
      handbook_traceability/
      secret_safety/
      logging/
      cleanup/
      manual_escape_hatch/
      partitioning/
      filesystem/
      mount_target/
      stage3/
      chroot/
      portage/
      system_baseline/
      locale_timezone_hostname/
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

Alternative layouts are allowed only when an approved OpenSpec change shows that common behavior is still implemented once and init-specific behavior remains isolated.

## Shared Roles
Shared roles live under `roles/common/` or an equivalent shared structure.

- `preflight`: live ISO, root privilege, amd64, UEFI, network, time, and tool checks.
- `config_validation`: validates operator variables against the install configuration schema.
- `host_requirements`: validates controller-side Ansible requirements and host-side libvirt requirements separately from live ISO and target checks.
- `live_target`: validates a network-reachable official Gentoo live ISO target, including SSH endpoint, Python availability, amd64, UEFI, network, DNS, and time evidence.
- `disk_detection`: read-only disk inventory and identity reporting.
- `install_plan`: profile-aware read-only plan output.
- `partition_plan`: read-only GPT layout planning.
- `mount_plan`: read-only root, EFI, and Btrfs subvolume mount layout planning.
- `filesystem_plan`: read-only EFI/root filesystem and Btrfs subvolume creation planning.
- `disk_safety`: required variables, confirmations, disk identity, libvirt VM guest mode, and fail-closed behavior.
- `destructive_preview`: read-only previews for destructive partition, format, mount-over, user, password, and bootloader actions.
- `install_state`: non-secret run ids, checkpoints, resume planning, and current-state comparison.
- `audit_bundle`: secret-safe evidence collection under project-local logs.
- `handbook_traceability`: maps roles and Makefile targets back to the Gentoo AMD64 Handbook or documented project deviations.
- `secret_safety`: shared checks for forbidden secret storage in variables, logs, state, audit bundles, and docs.
- `logging`: run ids, log paths, and shared error taxonomy.
- `cleanup`: safe cleanup/reset scope enforcement for generated project artifacts.
- `manual_escape_hatch`: records non-secret manual intervention notes and triggers revalidation before resume.
- `partitioning`: partition planning and approved execution.
- `filesystem`: filesystem checks and approved formatting.
- `mount_target`: target root and EFI mount preparation, idempotent existing-mount validation, and Btrfs `subvol=@` subvolume mounting.
- `stage3`: stage3 download, checksum, signature, architecture, and variant validation framework.
- `chroot`: pseudo-filesystem, DNS, and chroot readiness.
- `portage`: shared Portage baseline.
- `system_baseline`: validates the target basic-console contract.
- `locale_timezone_hostname`: target hostname, timezone, locale, and keymap configuration.
- `package_install`: shared package installation framework and conservative basic-console package USE policy.
- `fstab`: UUID-based fstab generation.
- `kernel`: `gentoo-kernel-bin` installation, installkernel/dracut support, fstab-derived kernel command line, and kernel/initramfs artifact evidence.
- `bootloader`: GRUB UEFI package installation, EFI/NVRAM preview, `grub-install`, `grub.cfg` generation, and boot command-line validation.
- `users`: admin user creation, sudo policy, optional password hash application, optional authorized_keys installation, and non-secret access evidence.
- `ssh`: optional installed SSH package/service policy and init-specific enablement dispatch.
- `final_checks`: read-only reboot readiness validation for mounts, fstab, kernel/initramfs, GRUB/EFI files, users, services, target baseline, Portage status, SSH policy, and secret-safe report inputs.

Currently implemented shared roles and workflows:

- `make config-check` with `config/install-schema.yml`: validates operator configuration defaults, allowed values, no-default disk behavior, mount paths, destructive confirmation variables, and secret-risk inputs before any live target or disk workflow runs.
- `common/live_preflight`: validates the live ISO environment over SSH.
- `common/disk_detection`: reports visible block devices without selecting or modifying a disk.
- `common/disk_safety`: validates explicit disk input, conservative syntax, optional destructive confirmation, disk identity, disk type, disk mount state, mounted descendants, and opt-in resume checkpoint comparison without mutating disks.
- `common/install_state`: writes non-secret project-local run state, phase checkpoints, event lines, and the latest disk safety resume checkpoint under `var/state/` and `logs/install-runs/`.
- `common/install_plan`: prints a profile-aware OpenRC or systemd plan without defaulting `install_disk`; it supports `FILESYSTEM=ext4` and `FILESYSTEM=btrfs` as read-only plan variants.
- `common/partition_plan`: reuses `common/disk_safety`, requires explicit `INSTALL_DISK`, and prints the exact read-only GPT plan for ext4 or Btrfs without writing.
- `common/mount_plan`: requires explicit `INSTALL_DISK`, reuses partition-plan safety checks, and prints the read-only target root, EFI, and Btrfs subvolume mount layout without mounting or creating directories.
- `common/filesystem_plan`: reuses mount-plan output and prints the read-only EFI/root filesystem creation plan without running `mkfs.*`, `wipefs`, or Btrfs subvolume commands.
- `common/stage3`: selects the official amd64 OpenRC or systemd stage3, verifies signed metadata, verifies SHA512 checksum, and extracts only into mounted `/mnt/gentoo`.
- `common/chroot`: verifies extracted stage3 markers, prepares Handbook-aligned pseudo-filesystem mounts under `/mnt/gentoo`, copies resolver configuration safely, validates DNS with a read-only chroot lookup, and records before/after mount evidence.
- `common/portage`: manages conservative `make.conf`, official Gentoo repo configuration, repo sync, OpenRC/systemd profile selection from variant variables, GURU-disabled policy, pending config-update reporting, and Portage evidence logs.
- `common/locale_timezone_hostname`: configures target hostname, timezone, UTF-8 locale, OpenRC/systemd console keymap files, locale generation, env update, and evidence for final checks and install reports.
- `common/fstab`: generates UUID-based `/mnt/gentoo/etc/fstab` entries for ext4 root or the approved Btrfs subvolume layout plus `/boot/efi`, validates UUIDs, and records evidence for final checks and install reports.
- `common/kernel`: installs `sys-kernel/installkernel`, `sys-kernel/dracut`, and `sys-kernel/gentoo-kernel-bin`, writes Handbook-aligned command-line input derived from `/mnt/gentoo/etc/fstab`, validates `/boot` kernel/initramfs artifacts, and records evidence for final checks and install reports.
- `common/ssh`: converts `ENABLE_SSH` into package and service inputs without storing secrets or enabling root password login by default.
- `common/package_install`: installs the shared console package set, OpenRC/systemd variant packages, Btrfs tooling when selected, optional OpenSSH, and records package/service evidence for final checks and install reports.
- `common/users`: creates or updates the target admin user, configures sudo through `wheel` by default, applies optional password hashes from gitignored controller-local files with `no_log`, installs optional admin authorized keys, enforces installed SSH root-login restrictions when SSH is enabled, and records non-secret evidence.
- `common/bootloader`: requires explicit `install_disk` and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`, shows EFI entries before GRUB actions, installs `sys-boot/grub` and `sys-boot/efibootmgr`, runs guarded UEFI `grub-install`, generates `grub.cfg`, validates the approved root command line, and records bootloader evidence.
- `common/final_checks`: runs read-only reboot readiness checks, requires `ADMIN_USER`, validates fstab, kernel/initramfs, GRUB/EFI files, Btrfs subvolumes, services, users, target identity, Portage baseline, SSH policy, and writes a secret-safe readiness report.
- `ansible/playbooks/install-basic-console.yml`: shared destructive orchestration sequence that wires the implemented roles together in Handbook order and passes one `install_run_id` to per-phase evidence logs.
- `ansible/playbooks/install-openrc.yml` and `ansible/playbooks/install-systemd.yml`: thin entrypoints that select only the init variant and import the shared install flow.
- `init/openrc`: enables target services with `rc-update` only.
- `init/systemd`: enables target services with `systemctl` only.

## Init-specific Roles
Init-specific roles must be thin and explicit.

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

OpenRC workflows must not call `systemctl`. systemd workflows must not call `rc-update` or `rc-service`.

## Variable Model
Shared variables have one meaning across both flows:

- `install_disk`
- `hostname`
- `admin_user`
- `filesystem`
- `boot_mode`
- `stage3_variant`
- `init_system`
- `enable_ssh`
- `confirm_wipe_disk`
- `target_mount`
- `efi_mount`
- `vm_guest_mode`
- `ansible_live_host`
- `ansible_live_port`
- `ansible_live_user`

Rules:

- `install_disk` must not have a default.
- `confirm_wipe_disk` must be explicitly set for destructive disk operations.
- `init_system` must be `openrc` or `systemd`.
- `stage3_variant` must match `init_system`.
- Stage3 verification must follow `docs/stage3-signature-policy.md`: checksum verification is mandatory, signature verification must fail closed unless a later OpenSpec change approves an explicit override, and cached artifacts must be reverified before extraction.
- Variant values should live in `group_vars/openrc.yml`, `group_vars/systemd.yml`, or an equivalent documented mechanism.
- VM guest `/dev/vda` is allowed only when explicitly passed as `install_disk=/dev/vda` inside the libvirt-managed guest VM.
- `ansible_live_host` selects an explicit network target and must not default to a VM address.
- When `ansible_live_host` is omitted, Makefile wrappers may discover the configured local libvirt VM for test workflows only.

## Controller and Target Model
The controller is the machine where the operator runs Makefile targets and Ansible. The target is a network-reachable machine booted into the official Gentoo live ISO.

Rules:

- Reusable Ansible roles must be inventory-driven and must not depend on libvirt, virsh, VM names, local qcow2 paths, or project-local artifact directories.
- The live ISO target may be physical hardware, a remote VM, or the project libvirt VM.
- `ANSIBLE_LIVE_HOST` is the explicit Makefile-level target selector for a real network target.
- The local libvirt VM is used when `ANSIBLE_LIVE_HOST` is empty and the wrapper can discover the project-owned VM.
- Local VM labels such as `VM_TEST_IMAGE_NAME` are harness metadata only; reusable Ansible roles must not use them to select packages, disks, profiles, or target behavior.
- Temporary host-key relaxation is allowed only for official live ISO targets where host keys are ephemeral, and it must remain scoped to wrapper invocations.
- No inventory, group vars file, or role defaults may select an install disk.

## Makefile Integration
The Makefile remains the operator-facing control plane.

Planned Ansible targets:

```sh
make ansible-check
make ansible-live-preflight ANSIBLE_LIVE_HOST=192.0.2.10 ANSIBLE_LIVE_USER=root
make detect-disks ANSIBLE_LIVE_HOST=192.0.2.10
make ansible-dry-run PROFILE=openrc
make ansible-dry-run PROFILE=systemd
make install-plan PROFILE=openrc
make install-plan PROFILE=systemd
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make configure-users PROFILE=openrc ADMIN_USER=gentoo
make install-bootloader PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_BOOTLOADER_CHANGES=yes
make final-checks PROFILE=openrc FILESYSTEM=btrfs ADMIN_USER=gentoo
make install-openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda ADMIN_USER=gentoo I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
make install-systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda ADMIN_USER=gentoo I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

The `/dev/vda` examples are VM-only examples for the local libvirt harness. For real network targets, use the explicit disk path reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.

Targets should pass `PROFILE=openrc` or `PROFILE=systemd` into a shared Ansible flow where practical. Avoid duplicated OpenRC and systemd command chains when a shared command can be parameterized safely.

Targets should pass network target variables into Ansible through the documented wrapper layer. VM/libvirt discovery is a convenience for local testing and must not be required by the reusable installer.

Only targets present in the current `Makefile` should be documented as runnable in user-facing quick-start instructions.

## Handbook Alignment
The remaining implementation changes map to the Handbook order as follows:

- disk preparation: partition apply, filesystem apply, mount target,
- stage file: stage3 selection, verification, extraction,
- base system and chroot: chroot preparation and Portage baseline,
- kernel: `gentoo-kernel-bin` with installkernel/initramfs support,
- system configuration: fstab, hostname, networking, system packages,
- tools: filesystem utilities, networking tools, editor, sudo/doas, syslog/cron where needed,
- bootloader: GRUB UEFI,
- finalizing: final checks and manual reboot readiness.

Some roles may run earlier than the Handbook presents them when automation can safely do so, such as generating fstab after UUIDs exist. Final checks must verify that the final installed state still matches the Handbook requirements.

## Safety Gate Reuse
Safety gates must be implemented once and reused by both init flows.

Required shared gates:

- `install_disk` is explicitly provided.
- No default disk exists in inventory, group vars, role defaults, or Makefile variables.
- Disk path, model, serial when available, size, current partition table, current filesystems, and mountpoints are shown before destructive tasks.
- `confirm_wipe_disk=yes` is required before destructive disk operations.
- Destructive tasks fail closed on ambiguity.
- Init-specific roles cannot partition, format, wipe, select disks, or redefine disk safety.
- VM guest mode does not disable confirmations or disk identity checks.
- Destructive apply targets print or call a read-only preview before accepting confirmation.
- Resume checkpoints never replace destructive confirmations.
- Resumed destructive workflows must route checkpoint comparison through `common/disk_safety`; the role compares current disk identity, descendant partition state, filesystem UUIDs, mountpoints, and recorded profile/filesystem values before allowing later mutation.
- Logs, state files, and audit bundles must reject or redact secrets.
- Audit bundle generation must stay local to `var/state/` and `logs/install-runs/`, copy only known evidence files, and fail closed on secret-like content.
- Handbook traceability must be regenerated with `make handbook-trace` when installer phases, Makefile targets, Ansible roles, safety gates, or project-specific deviations change.

## Cross-Cutting Guardrails
Before broad destructive implementation, the project should add:

- install configuration schema,
- config validation report,
- target system baseline,
- installed time synchronization policy,
- installed SSH policy,
- boot kernel command line policy,
- download cache and mirror policy,
- Portage world update policy,
- install state and resume checkpoints,
- destructive command preview,
- install audit bundle,
- secret input policy,
- logging and error taxonomy,
- Handbook traceability report,
- live ISO network bootstrap hardening.

These guardrails are shared behavior. OpenRC and systemd implementations must not create parallel versions of them.

The project should also define real hardware readiness, supported host requirements, cleanup/reset behavior, manual escape-hatch behavior, locale/timezone/hostname configuration, and a human-readable install report before the first usable release milestone.

## Installed Target Policies
Future implementation must keep these policy areas shared across OpenRC and systemd:

- Time sync: OpenRC and systemd may use different service managers, but the target must have a documented time synchronization plan.
- SSH: optional installed SSH is controlled by `ENABLE_SSH`; root password login and passwordless root SSH are not enabled by default.
- Boot command line: root is identified by stable UUID where practical; Btrfs requires `rootflags=subvol=@` or equivalent verified behavior.
- Downloads/cache: cached stage3 artifacts must still pass checksum/signature verification before extraction.
- Portage updates: broad `@world` update is not run by default in v1 unless a later approved change enables it.

## VM Testing Expectations
libvirt/virsh is the first safe test environment for OpenRC and systemd install plans, but it is not the product architecture.

- Boot the official Gentoo live ISO from `./gentoo.iso`.
- Use qcow2 disks under `./var/libvirt/`.
- Select local VM cases with `PROFILE=openrc|systemd` and `FILESYSTEM=ext4|btrfs`; VM targets derive `gentoo-test[-VM_TEST_IMAGE_NAME]-amd64-<profile>-<filesystem>` domains and case-specific disks.
- Use the libvirt managed `default` network for IP discovery when validating Ansible connectivity.
- Do not touch host block devices.
- Use `/dev/vda` only inside the guest VM and only when explicitly passed as `install_disk=/dev/vda`.
- Validate OpenRC and systemd install plans in the libvirt-managed VM before real hardware testing.
- Use `make vm-bootstrap-ssh` and `make vm-ansible-ping` only to validate access to the local live ISO test target; installer playbooks remain network/inventory-driven and separate approved work.
- `make vm-test-matrix-plan` covers amd64 OpenRC/ext4, amd64 OpenRC/Btrfs, amd64 systemd/ext4, and amd64 systemd/Btrfs at the read-only planning layer.
- `VM_TEST_IMAGE_NAME=<label>` may be used by local VM planning to label a manually tested image or test line in generated domain, disk, state, and log names. It is not an ISO path and must not affect reusable Ansible role behavior.
- Reusable Ansible roles must not derive behavior from `VM_NAME`, libvirt XML, qcow2 paths, or the case domain; those are local harness details only.
- `make vm-e2e-plan` and `make vm-e2e-install` validate a selected full disposable VM install path, including first boot and audit evidence, while keeping host block devices forbidden.
- First-boot validation boots from the installed disk and verifies network, hostname, root UUID, admin user, NetworkManager, and optional SSH.

## Acceptable Reuse
Acceptable patterns:

- One shared `stage3` role with `stage3_variant` selecting OpenRC or systemd assets.
- One shared `package_install` role using variant package lists.
- One shared `ssh` role dispatching service enablement to init-specific tasks.
- One shared `disk_safety` role used before partitioning, formatting, mounting, and bootloader work.
- Thin `install-openrc.yml` and `install-systemd.yml` playbooks that load variables and call `install-basic-console.yml`.

## Unacceptable Duplication
Unacceptable patterns:

- Separate OpenRC and systemd disk detection roles with the same logic.
- Separate OpenRC and systemd partitioning roles with copied safety assertions.
- Separate full install playbooks that duplicate the same role order.
- OpenRC tasks calling `systemctl`.
- systemd tasks calling `rc-update` or `rc-service`.
- Init-specific roles that choose or mutate disks directly.
- Repeating full shared procedures in both OpenRC and systemd documentation sections.

## Review Checklist
Before approving future Ansible implementation:

- Does the role or playbook follow the relevant official Gentoo AMD64 Handbook step unless a reviewed deviation is documented?
- Is common behavior implemented once?
- Are init-specific differences isolated and named clearly?
- Does `install_disk` have no default?
- Are shared safety gates reused by both flows?
- Do OpenRC tasks avoid `systemctl`?
- Do systemd tasks avoid `rc-update` and `rc-service`?
- Do Makefile targets call shared Ansible flows where practical?
- Are handlers, templates, validation tasks, and logs reused?
- Is VM guest `/dev/vda` limited to explicit guest-mode use?
- Does documentation distinguish implemented behavior from planned behavior?
