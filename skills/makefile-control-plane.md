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
- Adding Ansible playbooks or roles.
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
- Do not require the operator to run scripts directly.
- For OpenRC and systemd Ansible flows, prefer parameterized shared Makefile targets or thin variant targets that pass variables into a shared Ansible flow.
- Avoid separate duplicated command chains when `PROFILE=openrc` or `PROFILE=systemd` can select the variant safely.
- Do not hide destructive behavior inside vague targets.
- Update `README.md` or `docs/` whenever operator-facing targets are added, changed, or removed.
- Update this skill when a reusable Makefile target convention changes.

## 5. Variable Conventions
Required project variables:

- `INSTALL_DISK`
- `HOSTNAME`
- `PROFILE`
- `FILESYSTEM`
- `BOOT_MODE`
- `CODEX_INSTALL_METHOD`
- `I_UNDERSTAND_THIS_WIPES_DISK`

Recommended defaults:

- `HOSTNAME=gentoo`
- `PROFILE=openrc`
- `FILESYSTEM=ext4`
- `BOOT_MODE=uefi`
- `CODEX_INSTALL_METHOD=npm`

Rules:

- `INSTALL_DISK` must not have a default value.
- `I_UNDERSTAND_THIS_WIPES_DISK` must not default to `yes`.
- Destructive targets must require `INSTALL_DISK` to be set explicitly.
- Destructive targets must require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Disk variables must not use wildcard matching.
- Disk selection must not use a fallback such as the first disk from `lsblk`.
- Variable names should be uppercase for operator-provided inputs.
- `PROFILE=openrc` should map to Ansible `init_system=openrc`.
- `PROFILE=systemd` should map to Ansible `init_system=systemd`.
- Variables containing secrets must not be printed or committed.

## 6. Safe Targets
Safe targets are read-only or validation-only. They must not modify disks, target root, boot entries, users, passwords, or services.

The target lists below define the project control-plane contract. A target is available only when it exists in the current `Makefile`; otherwise treat it as planned and do not present it in `README.md` as runnable.

Required safe targets:

- `make help`
- `make preflight`
- `make detect-disks`
- `make openspec-list`
- `make openspec-validate`
- `make ansible-check`
- `make install-plan`
- `make install-plan PROFILE=openrc`
- `make install-plan PROFILE=systemd`

Expected behavior:

- `make help`: list targets, variables, and risk level.
- `make preflight`: show live ISO state, architecture, boot mode, network, time, mounts, and required tools.
- `make detect-disks`: show disk path, model, serial, size, transport, current partitions, and mount state.
- `make openspec-list`: list OpenSpec changes.
- `make openspec-validate`: validate OpenSpec changes.
- `make ansible-check`: validate Ansible availability and project structure.
- `make install-plan`: summarize intended install flow without making changes.
- `make install-plan PROFILE=openrc`: summarize the planned OpenRC flow through the shared Ansible install path.
- `make install-plan PROFILE=systemd`: summarize the planned systemd flow through the shared Ansible install path.

## 7. Semi-dangerous Targets
Semi-dangerous targets may modify the live ISO environment or prepare target paths, but they should not partition, format, wipe, overwrite disks, install bootloaders, change passwords, or create privileged users.

Semi-dangerous targets:

- `make bootstrap-codex`
- `make prepare-live-env`
- `make download-stage3`
- `make mount-target`

Expected behavior:

- `make bootstrap-codex`: install Codex temporarily in the live ISO using `CODEX_INSTALL_METHOD`.
- `make prepare-live-env`: install or verify temporary live-session dependencies only.
- `make download-stage3`: download and verify the amd64 OpenRC stage3 without extracting over existing data.
- `make mount-target`: mount explicitly provided partitions to explicitly provided target paths after mount-state checks.

`make mount-target` must become destructive-adjacent if it can mount over an existing path. It must print current mounts and require confirmation when ambiguity exists.

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
- Use no wildcard disk matching.
- Stop if disk identity is ambiguous.
- Stop if the disk differs from the plan output.
- Stop if required confirmations are missing.
- OpenRC and systemd install targets must call shared safety gates before variant-specific roles run.

`make install-bootloader` may not wipe disks, but it changes persistent boot state and must use the same seriousness as destructive targets.

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
- `make ansible-dry-run PROFILE=openrc`
- `make ansible-dry-run PROFILE=systemd`
- `make final-checks`

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
- Separate long `make install-openrc` and `make install-systemd` recipes that duplicate the same Ansible command chain instead of passing variant variables into a shared flow.

## 13. Failure Modes
- The operator bypasses the Makefile and runs raw commands from documentation.
- `INSTALL_DISK` is accidentally defaulted.
- A target selects the first detected disk automatically.
- A target uses wildcard disk matching.
- A destructive target lacks `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- A destructive target does not print disk summary output.
- A target combines unrelated risk classes.
- A cleanup target deletes an unchecked path.
- An Ansible target runs without showing check/plan output first.
- Codex bootstrap stores tokens in tracked files.

## 14. Recovery Advice
- Replace raw command instructions with make targets.
- Split broad targets into detect, plan, confirm, and apply targets.
- Remove any default value for `INSTALL_DISK`.
- Add explicit assertions for required variables.
- Add disk summary output before destructive work.
- Add a safety confirmation script before destructive targets.
- Add `make install-plan` or `make partition-plan` before apply targets.
- Stop and rerun safe inventory targets if disk identity changes.
- Review dangerous targets with `agents/safety-review-agent.md` before use.
- If secrets are written to project files, remove them immediately and keep them out of commits.

## Documentation maintenance
When Makefile behavior changes, documentation must change in the same commit or OpenSpec implementation step.

- Every new, changed, or removed operator-facing target must be reflected in the Makefile `help` output and in `README.md` or a relevant file under `docs/`.
- Every target documented in `README.md`, `docs/`, `skills/`, or OpenSpec specs must match an actual Makefile target or be clearly labeled as planned.
- Required variables must be documented with their defaults. If no default is allowed, such as `INSTALL_DISK`, the documentation must explicitly say so.
- Destructive targets must document required confirmation variables, the safety confirmation script, disk summary output, forbidden defaults, and forbidden wildcard disk matching.
- Semi-dangerous targets must document what paths or live-environment state they may change.
- If target names, variable names, defaults, or confirmation values change, update this skill, `README.md` or `docs/`, and the active OpenSpec `tasks.md`.
- If failure modes or recovery behavior changes in implementation, update the `Failure Modes` and `Recovery Advice` sections here before finishing.
