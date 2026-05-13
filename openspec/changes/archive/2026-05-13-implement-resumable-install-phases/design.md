## Context

The installer runs from an operator/controller machine against the official Gentoo live ISO over SSH. The shared Ansible flow supports OpenRC and systemd, ext4 and Btrfs, and standard/hardened/musl stage3 flavors. Local libvirt VMs test the same SSH-driven workflow against disposable qcow2 disks.

The current implementation records non-secret install state and per-phase evidence, but resume behavior needs a stricter contract. A checkpoint alone cannot prove it is safe to skip or repeat a phase. The installer must re-check current target facts and fail closed on ambiguity.

This change defines that contract before expanding implementation.

## Goals / Non-Goals

**Goals:**

- Make resume behavior operator-facing through Makefile targets.
- Provide a read-only resume plan before any resumed mutation.
- Define phase preconditions and completion evidence.
- Validate current target state against recorded state before resuming.
- Preserve destructive confirmations for destructive phases.
- Prevent accidental repeated partitioning, formatting, or bootloader installation.
- Support both local libvirt tests and remote network live ISO targets.
- Keep resume logic shared between OpenRC and systemd flows.
- Update documentation and skills so operators know how to recover after interruption.

**Non-Goals:**

- Do not bypass safety confirmations.
- Do not make manual changes invisible to the installer.
- Do not support arbitrary rollback of already-applied destructive operations.
- Do not replace the remote SSH Ansible architecture with a local-only runner.
- Do not duplicate resume logic separately for OpenRC and systemd.
- Do not resume if disk identity, filesystem UUIDs, mount state, profile, filesystem, stage3 flavor, or phase evidence cannot be verified.

## Decisions

### Use a read-only resume planner before execution

`make install-resume-plan` should inspect the state file, live target facts, selected variables, and phase evidence. It should print:

- run id,
- selected profile/filesystem/stage3 flavor,
- selected disk identity,
- completed phases,
- current target facts,
- detected mismatches,
- next safe phase,
- required confirmations for the next phase,
- whether resume execution is allowed.

Rationale: operators need a non-destructive way to understand state before continuing.

Alternative considered: run resume directly and let Ansible fail inside the next role. This is rejected because it hides context and increases risk around destructive phases.

### Resume executes one safe phase by default

`make install-resume` must execute only the next safe phase selected by the resume planner by default. It must stop after that phase records completion evidence and tell the operator to rerun `make install-resume-plan` before continuing.

Rationale: one-phase resume keeps recovery reviewable, limits blast radius, and avoids racing through a risk boundary after a partial failure.

Alternative considered: continue automatically until the next destructive or high-risk boundary. This may be useful later, but it is deferred because it increases implementation complexity and operator surprise.

Alternative considered: continue all remaining phases automatically. This is rejected for the first resumable implementation.

### Treat checkpoints as evidence, not authority

A checkpoint proves that a phase claimed completion at a point in time. It does not by itself prove the target still matches. Resume planning must compare current facts to recorded facts before allowing a skip or continuation.

Rationale: manual changes, reboot, remount, disk replacement, or partial failures can invalidate old checkpoints.

Alternative considered: skip phases only based on checkpoint names. This is rejected as unsafe.

### Define phase contracts

Each install phase must have a shared contract:

- `phase_id`
- preconditions,
- target paths it may read/write,
- whether it is read-only, mutating, high-risk, or destructive,
- required variables,
- required confirmations,
- completion evidence,
- validation checks,
- skip criteria,
- re-run criteria,
- failure recovery advice.

Rationale: resume cannot be reliable unless phases have explicit boundaries.

Alternative considered: embed ad hoc skip logic in each role. This is rejected because it will drift between roles and variants.

### Shared implementation only

Resume planning and execution must live in shared roles, shared tasks, or shared helper scripts. Init-specific roles may only provide init-specific validation, package/service state, or profile evidence.

Rationale: OpenRC and systemd differ in stage3/profile/service behavior, not in disk safety, stage3 extraction, chroot preparation, Portage baseline, kernel, bootloader framework, users, or final checks.

Alternative considered: separate OpenRC and systemd resume playbooks. Thin entrypoints are acceptable, but duplicated logic is rejected.

### Destructive phases remain explicitly confirmed

Partitioning, filesystem creation, bootloader installation, and other destructive/high-risk operations must require the same confirmations during resume as they do during a fresh run.

Rationale: previous checkpoints must never become implicit consent to destroy or rewrite target state.

Alternative considered: treat a recorded run id as confirmation. This is rejected.

### Manual intervention requires recording and revalidation

If an operator manually changes target state, the workflow must use the existing manual-step recording path and then require resume planning before continuing.

Rationale: manual recovery is necessary for real installations, but the system must not pretend it knows state that was changed outside automation.

Alternative considered: allow manual changes without state notes. This is rejected because it weakens audit and resume safety.

### Long-running tasks get bounded resilience

Network downloads, Portage sync, package installation, and other long-running tasks should use bounded retries or Ansible async/poll where practical. This change defines the rule; implementation must choose per phase where async is safe.

Rationale: not every long task should be async, but the project should avoid fragile one-shot operations for expected long-running steps.

Alternative considered: wrap the entire installer in one long retry. This is rejected because retrying the entire flow can repeat unsafe work.

## Proposed Phase Order

The resumable model should follow the current shared basic console flow:

1. `live-preflight`
2. `disk-detection`
3. `disk-safety`
4. `install-plan`
5. `partition-plan`
6. `partition-apply`
7. `filesystem-plan`
8. `filesystem-apply`
9. `mount-plan`
10. `mount-target`
11. `stage3-install`
12. `chroot-preparation`
13. `portage-baseline`
14. `system-config`
15. `fstab-generation`
16. `kernel-install`
17. `system-packages`
18. `users-and-access`
19. `bootloader`
20. `final-checks`

The implementation may refine names, but each phase must map back to the shared flow and documentation.

## Phase Contract Table

The first implementation should use this table as the baseline contract. `safe_to_rerun` means safe only after the listed validation passes; it does not bypass required confirmations.

| phase_id | risk | required confirmations | completion evidence | safe_to_rerun | skip criteria |
| --- | --- | --- | --- | --- | --- |
| `live-preflight` | read-only | none | live ISO facts: architecture, UEFI, network, DNS, clock, root user | yes | current live facts satisfy the same checks |
| `disk-detection` | read-only | none | disk inventory with path, model, serial, size, partitions, filesystems, mountpoints | yes | current disk inventory is available and selected disk facts match recorded facts when selected |
| `disk-safety` | read-only | `INSTALL_DISK` when evaluating a selected disk | selected disk identity, mounted-descendant check, ambiguity checks | yes | current selected disk identity and safety checks match the expected state |
| `install-plan` | read-only | `INSTALL_DISK` for disk-specific plans | profile, filesystem, stage3 flavor, boot mode, selected disk, planned layout | yes | current inputs match recorded plan inputs |
| `partition-plan` | read-only | `INSTALL_DISK` | planned GPT layout and current disk state | yes | current disk state still matches the plan preconditions |
| `partition-apply` | destructive | `INSTALL_DISK`, `I_UNDERSTAND_THIS_WIPES_DISK=yes` | before/after partition tables, selected disk identity | no by default | partition table exactly matches expected layout and disk identity matches |
| `filesystem-plan` | read-only | `INSTALL_DISK` | planned filesystems, labels, mount options, Btrfs subvolumes when applicable | yes | current inputs and partition layout match plan preconditions |
| `filesystem-apply` | destructive | `INSTALL_DISK`, `I_UNDERSTAND_THIS_WIPES_DISK=yes` | before/after filesystem signatures, UUIDs, labels, Btrfs subvolumes when applicable | no by default | expected filesystems exist on expected partitions with matching UUID/type evidence |
| `mount-plan` | read-only | `INSTALL_DISK` | planned mountpoints, source devices, filesystem-specific options | yes | expected filesystems and mount options can still be derived |
| `mount-target` | medium | `INSTALL_DISK` | `/mnt/gentoo` and `/boot/efi` mount state, Btrfs subvolume mount evidence when applicable | yes | target mountpoints are already mounted exactly as planned |
| `stage3-install` | medium | target root confirmation through mount validation | stage3 filename, checksum/signature status, extraction marker, timestamp | conditionally | verified stage3 extraction marker and target root baseline exist |
| `chroot-preparation` | medium | target root confirmation through mount validation | bind mount state for proc/sys/dev/run and DNS configuration evidence | yes | required chroot mounts and DNS state already match |
| `portage-baseline` | medium | none beyond mounted target root validation | make.conf, repos.conf, selected profile, sync evidence | conditionally | target Portage config and selected profile match expected values |
| `system-config` | medium | none beyond mounted target root validation | hostname, timezone, locale, keymap evidence | yes | files in target root match expected values |
| `fstab-generation` | medium | none beyond mounted target root validation | generated fstab entries and source UUIDs | yes | fstab entries match current filesystem UUIDs and planned mounts |
| `kernel-install` | medium | none beyond mounted target root validation | installed kernel package and `/boot` kernel/initramfs evidence | conditionally | expected kernel package and boot files exist |
| `system-packages` | medium/high | none beyond mounted target root validation | installed packages and init-specific service enablement plan/evidence | conditionally | package set and service enablement match expected profile/init system |
| `users-and-access` | high | admin user variables and non-secret public key/password-hash input validation | user/group/shell/sudo or doas/authorized_keys evidence without secrets | conditionally | user and access state match expected non-secret policy |
| `bootloader` | high | `I_UNDERSTAND_BOOTLOADER_CHANGES=yes` and selected disk/root/EFI validation | GRUB install/config evidence, EFI files, boot entries when available | no by default | bootloader evidence already matches expected disk, EFI mount, and config |
| `final-checks` | read-only | none | reboot-readiness report and audit bundle reference | yes | current target state passes final checks |

## Risks / Trade-offs

- False confidence from checkpoints -> Revalidate current target facts before skipping or resuming.
- Incomplete evidence for early phases -> Add minimum evidence requirements before allowing resume.
- Repeating destructive work -> Require explicit confirmation and exact state matching before any destructive phase can run.
- Excessively complex skip logic -> Keep phase contracts small and explicit.
- Drift between OpenRC and systemd -> Implement resume in shared roles and require review for duplication.
- Async tasks may hide failure details -> Use bounded polling, clear logs, and phase-specific failure output.
- Real hardware risk -> Require stable disk identity and fail closed when disk facts are missing.

## Migration Plan

1. Define phase contract data and update the state schema.
2. Implement or complete read-only resume planning.
3. Add guarded resume execution.
4. Add per-phase skip/re-run validation in shared roles.
5. Update docs and skills.
6. Validate with libvirt disposable VMs first.
7. Document real hardware readiness requirements before suggesting use on physical machines.

Rollback is to use the existing fresh install targets and ignore resume targets. No existing completed install should depend on the new resume path.

## Open Questions

- Should a later change add `RESUME_UNTIL=next-risk-boundary` after one-phase resume is proven safe?
- Should operators be able to specify `RESUME_FROM_PHASE`, or should the planner always choose the next safe phase?
- Which long-running tasks should use Ansible async in the first implementation versus ordinary retries?
