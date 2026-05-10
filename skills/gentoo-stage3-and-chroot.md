# Gentoo Stage3 and Chroot Skill

## 1. Purpose
This skill describes how `gentoo-ai-installer` should download, verify, extract, and prepare a Gentoo stage3 environment.

The v1 target is amd64 OpenRC, the root filesystem is mounted at `/mnt/gentoo`, the project starts from the official Gentoo live ISO, and the Makefile is the operator-facing control plane. This skill supports phase-1 manual workflows and future phase-2 Ansible automation.

This skill describes procedure and requirements. It does not implement scripts.

## 2. When to Use This Skill
Use this skill:

- After disk planning, partitioning, formatting, and mounting are complete.
- After `/mnt/gentoo` is expected to be the target root.
- Before configuring Portage.
- Before entering the chroot.
- When designing future Ansible roles for stage3 and chroot preparation.

Do not use this skill before the target root mount has been verified.

Before any future `mount-target` implementation is used, the operator should review `make mount-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` output to confirm the intended root, EFI, and Btrfs subvolume mount layout.

## 3. Required Context
- Official Gentoo live ISO preflight result.
- Target root path: `/mnt/gentoo`.
- Confirmation that `/mnt/gentoo` is mounted.
- Confirmation that `/mnt/gentoo` is the intended target root.
- Selected stage3: official Gentoo amd64 OpenRC stage3 tarball.
- Network, DNS, and time status.
- Download directory.
- Verification files such as checksums and signatures when available.
- Whether `/mnt/gentoo` is empty or already contains a Gentoo root.

## 4. Stage3 Selection
Stage3 assumptions:

- Architecture: amd64.
- Init system: OpenRC.
- Source: official Gentoo stage3 tarball.
- Systemd stage3 tarballs are out of scope for v1.
- Non-amd64 stage3 tarballs are out of scope for v1.

The selected filename should clearly indicate amd64 and OpenRC. The skill must fail if architecture does not match amd64 or if the selected tarball is not the OpenRC variant.

Manual validation examples may include checking filenames, release metadata, and tarball contents. Future automation must parse metadata where practical instead of relying only on filename string matching.

## 5. Download Procedure
Use:

```text
make download-stage3
```

The download procedure should:

- Use official Gentoo mirror or release metadata.
- Download the stage3 tarball.
- Download checksum files.
- Download signature files where available.
- Preserve downloaded file names.
- Preserve download timestamps.
- Avoid writing downloads into the target root unless that path is explicitly planned.
- Record the selected mirror or source URL.

Manual validation commands may inspect downloaded filenames, timestamps, and sizes. Future automation should produce structured output containing file path, source URL, size, and timestamp.

## 6. Verification Procedure
Use:

```text
make verify-stage3
```

Verification should:

- Verify checksums.
- Verify signatures where possible.
- Confirm the tarball is official Gentoo stage3.
- Confirm architecture is amd64.
- Confirm init system is OpenRC.
- Fail if checksum verification fails.
- Fail if signature verification fails when signature verification is required.
- Fail if metadata is missing and no operator-approved fallback exists.

Preserve logs of downloaded file names, checksums, verification status, and timestamps.

Manual validation commands may include checksum verification and signature verification tools available in the live ISO. Future automation must fail closed on verification mismatch.

## 7. Extraction Procedure
Use:

```text
make extract-stage3
```

Safety requirements:

- Do not extract stage3 unless `/mnt/gentoo` is mounted.
- Confirm `/mnt/gentoo` is the intended target root.
- Do not extract into `/`.
- Do not extract into an ambiguous path.
- Do not overwrite an existing Gentoo root unless explicitly confirmed.
- Stop if `/mnt/gentoo` contains unexpected files.
- Preserve extraction logs.

Extraction should:

- Use the verified amd64 OpenRC stage3 tarball.
- Preserve permissions, ownership, extended attributes, and numeric IDs as required by Gentoo installation practice.
- Extract into `/mnt/gentoo`.
- Record tarball path, target root, timestamp, and result.

Manual validation may inspect `/mnt/gentoo` after extraction for expected directories such as `etc`, `usr`, `var`, `bin`, and `root`. Future automation must check target-root assertions before extraction.

## 8. Mount Preparation for Chroot
Use:

```text
make prepare-chroot
```

Chroot mount preparation should:

- Confirm `/mnt/gentoo` is mounted.
- Confirm required target directories exist after stage3 extraction.
- Prepare required pseudo-filesystem mounts for chroot.
- Ensure bind mounts are scoped under `/mnt/gentoo`.
- Avoid mounting over unrelated live ISO paths.
- Show current mounts before and after preparation.

Future automation must be idempotent: if required mounts already exist and point to the expected sources, it should not duplicate them.

## 9. DNS Preparation
DNS preparation should:

- Confirm DNS works in the live ISO before chroot.
- Ensure resolver configuration is available inside `/mnt/gentoo` by a documented and reversible method.
- Avoid overwriting target resolver configuration without review.
- Record what DNS files or links were placed into the target.

Manual validation may test name resolution before and after chroot entry. Future automation should fail if DNS cannot be proven available for package operations.

## 10. Chroot Entry Expectations
Use:

```text
make enter-chroot
```

Chroot entry expectations:

- The operator enters chroot only after stage3 extraction, mount preparation, and DNS preparation pass.
- The target root must be `/mnt/gentoo`.
- Any command inside chroot that changes the target system is target-mutating and must be treated with appropriate risk.
- The chroot should use an environment suitable for Gentoo installation.
- Chroot entry should make it obvious that the shell is operating on the target root.

Future automation should minimize ad-hoc shell execution in chroot and prefer explicit Ansible tasks with guards, assertions, and logs.

## 11. Makefile Targets
Expected targets:

These targets define the expected control-plane contract for stage3 and chroot work. If a target is not present in the current `Makefile`, treat it as planned and do not document it as runnable in user-facing docs.

- `make download-stage3`
- `make verify-stage3`
- `make extract-stage3`
- `make prepare-chroot`
- `make enter-chroot`
- `make mount-plan`

Target expectations:

- `make download-stage3`: fetch official amd64 OpenRC stage3 and verification files.
- `make verify-stage3`: verify checksums, signatures where possible, architecture, and OpenRC variant.
- `make extract-stage3`: extract only verified stage3 into confirmed `/mnt/gentoo`.
- `make prepare-chroot`: prepare pseudo-filesystems and DNS for chroot.
- `make enter-chroot`: enter target chroot after readiness checks.
- `make mount-plan`: read-only prerequisite check that reports the intended target mount layout before any future `mount-target` action.

The operator should not be asked to run raw download, tar extraction, mount, DNS-copy, or chroot commands when Makefile targets exist.

## 12. Failure Modes
- `/mnt/gentoo` is not mounted.
- `/mnt/gentoo` is not the intended target root.
- `/mnt/gentoo` points to the live root or an unexpected filesystem.
- Wrong stage3 variant selected.
- Stage3 architecture is not amd64.
- Stage3 init system is not OpenRC.
- Download is incomplete.
- Checksum verification fails.
- Signature verification fails.
- System time breaks TLS or signature validation.
- Extraction target is non-empty or contains an existing Gentoo root.
- Required pseudo-filesystems are not mounted.
- DNS does not work inside chroot.
- Future automation cannot prove target-root identity.

## 13. Recovery Advice
- If `/mnt/gentoo` is not mounted, stop and return to disk/mount planning.
- If target-root identity is unclear, stop and inspect mounts before writing.
- If the wrong stage3 was selected, delete only the known bad downloaded file through documented cleanup and select the amd64 OpenRC tarball.
- If checksum or signature verification fails, discard the downloaded file and redownload from an official source.
- If extraction was attempted in the wrong path, stop immediately and collect evidence before making further changes.
- If `/mnt/gentoo` already contains a Gentoo root, require explicit operator confirmation before overwriting or reusing it.
- If chroot DNS fails, inspect resolver setup and pseudo-filesystem mounts before package operations.
- If a chroot command fails, preserve logs and inspect target state before retrying.

## 14. Output Artifacts
This skill should produce or request:

- Selected stage3 source URL or mirror.
- Downloaded stage3 filename.
- Checksum file name.
- Signature file name when available.
- Download timestamp.
- Verification log.
- Architecture and OpenRC validation result.
- Target root mount confirmation for `/mnt/gentoo`.
- Extraction log.
- Chroot mount preparation log.
- DNS preparation summary.
- Chroot readiness decision.

## Documentation maintenance
When stage3, extraction, mount preparation, DNS, or chroot behavior changes, documentation must change in the same implementation step.

- If stage3 selection changes, update this skill and manual install documentation to state the supported architecture, init system, source, checksum, and signature expectations.
- If verification behavior changes, update failure modes and recovery guidance so checksum or signature failures still fail closed.
- If extraction target, mount points, pseudo-filesystem mounts, resolver handling, or chroot entry expectations change, update this skill, `agents/gentoo-install-agent.md`, and relevant `docs/` workflows.
- If Makefile targets such as `make download-stage3`, `make verify-stage3`, `make extract-stage3`, `make prepare-chroot`, or `make enter-chroot` change, update this skill and `skills/makefile-control-plane.md`.
- If automation later implements these steps, ensure the active OpenSpec `tasks.md` includes documentation updates for target-root checks, overwrite behavior, logs, and recovery.
- Before finishing, confirm failure modes and recovery advice still match the implemented stage3 and chroot flow.
