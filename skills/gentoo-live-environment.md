# Gentoo Live Environment Skill

## 1. Purpose
This skill describes how to prepare and verify the official Gentoo live ISO environment before installing Codex or starting a Gentoo installation.

The project uses the official Gentoo live ISO, does not use a custom ISO in v1, installs Codex temporarily after boot, and exposes operator-facing actions through the Makefile.

This skill is non-destructive. It must not partition, format, mount target filesystems, install bootloaders, create users, change passwords, or alter the target Gentoo system.

## 2. When to Use This Skill
Use this skill:

- Immediately after booting the official Gentoo live ISO.
- After cloning or entering the project directory.
- Before `make bootstrap-codex`.
- Before disk planning, stage3 work, chroot work, or Ansible work.
- After any reboot into the live ISO, because live-session state is temporary.

## 3. Required Context
- Project directory path.
- Confirmation that the ISO is the official Gentoo live ISO.
- Expected architecture: amd64.
- Expected boot mode: UEFI.
- Network access requirements for Codex, Gentoo mirrors, GURU, npm, or binary downloads.
- Whether the project directory is writable.
- Whether any target filesystems are already mounted.

## 4. Preflight Checks
Prefer `make preflight` for the combined check. Preflight should verify:

- Internet connectivity.
- DNS resolution.
- Correct system time.
- UEFI availability via `/sys/firmware/efi`.
- Available disks via `lsblk`.
- Available memory.
- CPU architecture.
- Root privileges.
- Write access to the project directory.
- Availability of `curl`, `wget`, `git`, `bash`, and `make`.

Preflight must be read-only. If a missing dependency is found in the live environment, install it only through a make target or documented script. Do not use undocumented ad-hoc commands.

## 5. Network Setup Checks
Use `make check-network` when available.

Verify:

- At least one network interface has carrier or a configured connection.
- The live ISO has an IP address.
- A default route exists.
- Outbound HTTPS works.
- Required hosts for Gentoo mirrors, Codex bootstrap method, GURU, npm, or binary release download are reachable.

Do not assume network works just because an interface is present.

## 6. DNS Checks
DNS checks should verify:

- Hostname resolution works for public domains.
- Gentoo mirror hostnames resolve.
- Codex install source hostnames resolve for the selected method.
- Resolver configuration is present and readable.

Failure to resolve names blocks Codex bootstrap and stage3/package downloads.

## 7. Time Synchronization Checks
Use `make check-time` when available.

Verify:

- Current date and time are plausible.
- Timezone mismatch does not imply an incorrect clock.
- TLS certificate validation is likely to succeed.
- NTP or the live ISO time-sync mechanism is active when available.

Wrong time must be fixed before downloading Codex, stage3 files, Portage metadata, or package artifacts.

## 8. UEFI Detection
Use `make check-uefi` when available.

Verify:

- `/sys/firmware/efi` exists.
- EFI variables are accessible when required.
- The system was not booted in legacy BIOS mode.

If UEFI is missing, stop and instruct the operator to reboot the official live ISO using the machine's UEFI boot entry. The v1 install assumes UEFI.

## 9. Disk Discovery
Use `make detect-disks` for read-only disk discovery.

Disk discovery should show:

- Disk path.
- Stable `/dev/disk/by-id/...` path when available.
- Model.
- Serial when available.
- Size.
- Transport.
- Current partition table.
- Existing filesystems.
- Current mount state.

Disk discovery must not select a target disk and must not modify disks. Disk names are operator-provided later during planning.

## 10. Memory and CPU Checks
Verify:

- CPU architecture is amd64.
- CPU count is visible for later build planning.
- Available memory is enough for live ISO operation, Codex bootstrap, and package operations.
- Swap availability is reported if present.

Low memory should trigger a warning before Codex bootstrap or package-heavy steps.

## 11. Package Manager Readiness
Verify whether the live environment can install or run temporary tools:

- `make` is available.
- `bash` is available.
- `git` is available for project work.
- `curl` and/or `wget` are available for downloads.
- The selected Codex install method has its dependencies available or installable through documented targets.
- Portage readiness is checked only for live-environment needs, not for modifying the target root.

Any missing dependency in the live environment should be installed through a make target or documented script, not through undocumented ad-hoc commands.

## 12. Expected Make Targets
This skill should reference these targets:

- `make preflight`
- `make detect-disks`
- `make check-network`
- `make check-uefi`
- `make check-time`
- `make bootstrap-codex`

Target expectations:

- `make preflight`: run all read-only readiness checks.
- `make detect-disks`: show disk inventory without selecting or modifying a disk.
- `make check-network`: verify link, IP, routing, DNS, and HTTPS.
- `make check-uefi`: verify UEFI boot mode.
- `make check-time`: verify clock and time-sync status.
- `make bootstrap-codex`: run only after preflight passes.

## 13. Failure Modes
- The system booted from a custom ISO instead of the official Gentoo live ISO.
- The live ISO was booted in legacy BIOS mode.
- CPU architecture is not amd64.
- Network interface lacks IP configuration.
- Default route is missing.
- DNS resolution fails.
- System time is wrong and TLS downloads fail.
- Required commands such as `curl`, `wget`, `git`, `bash`, or `make` are missing.
- Project directory is not writable.
- Memory is too low for Codex bootstrap or package operations.
- Existing mounts make target paths ambiguous.

## 14. Recovery Advice
- Reboot using the official Gentoo live ISO if the environment is wrong.
- Reboot using the UEFI boot entry if `/sys/firmware/efi` is missing.
- Fix network through documented make targets or documented scripts.
- Fix time before any TLS download or signature verification.
- Install missing live-environment dependencies through make targets or documented scripts only.
- Move the project checkout to a writable path if needed.
- Stop and inspect mounts before any later target mount work.
- Re-run `make preflight` after each recovery action.

## 15. Output Artifacts
This skill should produce or request:

- Preflight summary.
- Network check output.
- DNS check result.
- Time check result.
- UEFI check result.
- Disk inventory output from `make detect-disks`.
- CPU and memory summary.
- Missing dependency list.
- Go/no-go decision for `make bootstrap-codex`.
- Notes suitable for OpenSpec validation evidence.
