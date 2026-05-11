# Gentoo Portage Basics Skill

## 1. Purpose
This skill describes the minimum Portage configuration required for the v1 `gentoo-ai-installer` Gentoo installation.

The goal is a simple working Gentoo system, not a heavily optimized one. Prefer clarity, reliability, and repeatability over maximum performance.

This skill defines setup rules and expectations. It does not implement scripts.

## 2. When to Use This Skill
Use this skill:

- After amd64 OpenRC or systemd stage3 extraction.
- After chroot preparation is complete.
- Before installing `gentoo-kernel-bin`, GRUB, NetworkManager, users, and services.
- When designing future Ansible `portage` and package-installation roles.
- When reviewing `make.conf`, profile, repos, or package list changes.

## 3. Required Context
- Target root path, normally `/mnt/gentoo`.
- Confirmed chroot readiness.
- v1 architecture: amd64.
- v1 init system: OpenRC or systemd, selected with `PROFILE`.
- v1 boot mode: UEFI.
- v1 filesystem: ext4 by default, or Btrfs when explicitly planned with `FILESYSTEM=btrfs`.
- Required packages for `gentoo-kernel-bin`, GRUB, EFI boot support, NetworkManager, editor, privilege escalation, and init-specific syslog/cron policy.
- Network and DNS status.
- Mirror selection.
- Download cache and mirror policy in `docs/download-cache-and-mirror-policy.md`.
- Portage world update policy in `docs/portage-world-update-policy.md`.
- Whether Codex was bootstrapped in the live ISO only.

## 4. `make.conf` Principles
`make.conf` should stay minimal for v1:

- Use conservative compiler flags.
- Avoid CPU-specific tuning at first.
- Keep `USE` flags small and intentional.
- Prefer readable settings that are easy to reproduce in Ansible later.
- Do not copy host-specific tuning from another machine.
- Do not add settings just because they may improve performance.
- Set `GRUB_PLATFORMS="efi-64"` for the v1 UEFI GRUB path.
- Keep comments short and useful.
- Avoid storing secrets or tokens.

## 5. `COMMON_FLAGS` Guidance
Recommended initial policy:

- Use safe amd64-compatible flags.
- Avoid aggressive CPU-specific optimization at first.
- Do not start with unstable or exotic compiler flags.
- Prefer a baseline such as generic `-O2 -pipe` style guidance over host-specific tuning.
- Defer `-march=native` or CPU-specific flags until after the system boots reliably and a later OpenSpec change approves optimization.

The initial install should optimize for successful bootstrap, not maximum compile performance.

## 6. `MAKEOPTS` Guidance
`MAKEOPTS` should be conservative:

- Use CPU count and memory availability from live environment checks.
- Avoid setting job counts so high that the live environment or target system runs out of memory.
- Prefer a modest value for first install.
- Record the chosen value so Ansible can reproduce it later.
- Revisit after the installed system is stable.

If memory is low, reduce parallelism before package installation.

## 7. `ACCEPT_LICENSE` Guidance
Keep license policy explicit:

- Use an explicit minimal policy for v1: `-* @FREE @BINARY-REDISTRIBUTABLE`.
- Do not expand license acceptance beyond this baseline without operator approval.
- Document any broader license acceptance and why it is required.
- Do not accept licenses for Codex in the installed system unless Codex is explicitly being installed there, which is out of scope for v1.

## 8. USE Flags Policy
Policy:

- Keep v1 minimal.
- Do not over-customize global `USE` flags.
- Add only flags needed for the defined v1 system.
- Avoid broad desktop, server, or hardware assumptions unless explicitly required.
- Prefer package-specific flags later if needed instead of global flags.
- Record every non-default global flag and its reason.

The v1 target is a simple working OpenRC or systemd console system with GRUB, NetworkManager, and `gentoo-kernel-bin`.

## 9. Profile Selection
Profile selection must:

- Use an amd64 profile matching `PROFILE=openrc` or `PROFILE=systemd`.
- Avoid experimental profile changes during initial install.
- Be visible in logs and output artifacts.
- Be applied through shared `make configure-portage` logic, or a later `make select-profile` target if it is split out.

Current variant data:

- `PROFILE=openrc`: `default/linux/amd64/23.0`
- `PROFILE=systemd`: `default/linux/amd64/23.0/systemd`

If the selected profile is not clearly amd64 and does not match the requested init system, stop and reselect.

## 10. Mirrors and Repos
Mirrors and repository setup should:

- Use official Gentoo repository configuration.
- Select reliable mirrors suitable for the operator's network.
- Confirm DNS and HTTPS work before syncing.
- Avoid custom repositories in the installed system unless explicitly required.
- Record selected mirrors for reproducibility.

Repository sync is currently part of `make configure-portage`. A later `make sync-portage` target may split that operation if OpenSpec approves it.

## 11. GURU Overlay Policy
GURU overlay may be used for Codex in the live environment, but should not be blindly enabled in the installed Gentoo system.

Policy:

- Codex does not need to be installed into the final Gentoo system in v1.
- Do not enable GURU in the installed system unless an approved change explicitly requires it.
- If GURU is used for live Codex bootstrap, keep that separate from target Portage configuration.
- Any installed-system overlay must have a clear purpose, affected packages, and safety review.
- Broad `@world` update must not run by default in v1 unless a later approved OpenSpec change enables it.
- Portage sync and mirror/cache behavior must follow the approved download/cache and Portage world update policies.

## 12. Package Installation Policy
Install only the base packages needed for v1:

- `gentoo-kernel-bin`
- `grub`
- `efibootmgr`
- `networkmanager`
- `dosfstools` for the FAT32 EFI system partition
- `btrfs-progs` when `FILESYSTEM=btrfs`
- `e2fsprogs` verified or installed for ext4 tooling
- `sudo` for v1 admin privilege escalation; `doas` requires a later approved change.
- `vim` or `nano`
- Syslog package
- Cron package

Policy:

- Prefer `gentoo-kernel-bin` to avoid kernel compilation complexity in v1.
- Keep package set small.
- Do not install Codex into the final Gentoo system in v1.
- Do not add desktop environments, broad toolchains, or convenience packages unless approved.
- Record package names and reasons.
- Package installation mutates the target system and should be run only after chroot and target-root checks pass.

## 13. Makefile Targets
Expected targets:

These targets define the expected control-plane contract for Portage setup. If a target is not present in the current `Makefile`, treat it as planned and do not document it as runnable in user-facing docs.

- `make configure-portage`
- `make select-profile`
- `make sync-portage`
- `make install-system-packages`
- `make install-base-packages` as a compatibility alias when present

Target expectations:

- `make configure-portage`: implemented target that writes minimal `make.conf`, installs official Gentoo repo settings, syncs official Gentoo repository metadata, selects the amd64 OpenRC or systemd profile matching `PROFILE`, reports pending protected config updates, and confirms GURU is disabled.
- `make select-profile`: planned split target that would select and show the amd64 profile.
- `make sync-portage`: planned split target that would sync official Gentoo repository metadata.
- `make install-system-packages`: install the v1 base console package set, apply the approved package USE policy, and enable init-specific target services.
- `make install-base-packages`: compatibility alias for `make install-system-packages` when present.

The operator should not be asked to run raw `emerge`, `eselect profile`, or repository commands when Makefile targets exist.

User creation and sudo policy are handled later by `make configure-users`; `make install-system-packages` installs the privilege package but must not create users or set passwords.

## 14. Failure Modes
- Wrong profile selected for the requested init system.
- Network or DNS fails during repository sync.
- Mirrors are unreachable or stale.
- `make.conf` contains overly aggressive CPU-specific flags.
- `MAKEOPTS` is too high for available memory.
- Broad `USE` flags pull in unwanted dependencies.
- License settings block required packages.
- GURU overlay is accidentally enabled in the installed system.
- Codex is accidentally installed into the target system.
- Package conflicts or keyword issues appear.
- Disk space is insufficient for package installation.

## 15. Recovery Advice
- Re-check the selected profile and confirm it is amd64 and matches `PROFILE`.
- Re-run network, DNS, and time checks before syncing.
- Switch mirrors through documented targets if sync fails.
- Reduce `MAKEOPTS` if builds fail due to memory pressure.
- Remove unnecessary global `USE` flags before troubleshooting package conflicts.
- Keep license changes narrow and documented.
- Remove accidental installed-system GURU configuration unless an approved change requires it.
- Keep Codex in the live environment for v1.
- Record package conflicts for OpenSpec follow-up instead of improvising broad changes.

## 16. Output Artifacts
This skill should produce or request:

- `make.conf` summary.
- Selected `COMMON_FLAGS`.
- Selected `MAKEOPTS`.
- `ACCEPT_LICENSE` policy.
- Global `USE` flag list and reasons.
- Selected amd64 OpenRC or systemd profile.
- Mirror and repository summary.
- Confirmation that GURU is not blindly enabled in the installed system.
- Base package list with reasons.
- Repository sync result.
- Package installation result.
- Notes for future Ansible variables.

## Documentation maintenance
When Portage setup behavior changes, documentation must change in the same implementation step.

- If `make.conf`, `COMMON_FLAGS`, `MAKEOPTS`, `ACCEPT_LICENSE`, USE flag policy, profile selection, mirrors, repositories, overlays, or base package policy changes, update this skill and the relevant manual install documentation under `docs/`.
- If GURU overlay policy changes, document whether the change applies only to the live Codex bootstrap environment or to the installed Gentoo system.
- If Codex installation policy changes, update `skills/codex-bootstrap-on-gentoo-live.md` and Codex bootstrap docs; v1 documentation must not imply Codex is installed into the final Gentoo system unless an approved change does that.
- If Makefile targets such as `make configure-portage`, `make select-profile`, `make sync-portage`, `make install-system-packages`, or `make install-base-packages` change, update this skill and `skills/makefile-control-plane.md`.
- If failure modes or recovery advice change, keep package-conflict, license, overlay, and memory-pressure guidance synchronized with implementation.
- If Ansible later maps these settings to variables, update `skills/ansible-gentoo-installer.md` and the active OpenSpec `tasks.md`.
