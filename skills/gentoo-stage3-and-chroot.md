# Gentoo Stage3 and Chroot Skill

## 1. Purpose
This skill describes how `gentoo-ai-installer` should download, verify, extract, and prepare a Gentoo stage3 environment.

The target architecture is amd64, the root filesystem is mounted at `/mnt/gentoo`, the project starts from the official Gentoo live ISO, and the Makefile is the operator-facing control plane. Manual phase-1 defaults to OpenRC; phase-2 Ansible supports basic console OpenRC and systemd variants through shared logic.

This skill describes procedure and requirements. It does not implement scripts.

## 2. When to Use This Skill
Use this skill:

- After disk planning, partitioning, formatting, and mounting are complete.
- After `/mnt/gentoo` is expected to be the target root.
- Before configuring Portage.
- Before entering the chroot.
- When designing future Ansible roles for stage3 and chroot preparation.

Do not use this skill before the target root mount has been verified.

Before `make mount-target` is used, the operator should review `make mount-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` output to confirm the intended root, EFI, and Btrfs subvolume mount layout.

Before any future `format` implementation is used, the operator should review `make filesystem-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` output to confirm the intended EFI/root filesystem creation plan and Btrfs subvolume plan.

## 3. Required Context
- Official Gentoo live ISO preflight result.
- Target root path: `/mnt/gentoo`.
- Confirmation that `/mnt/gentoo` is mounted.
- Confirmation that `/mnt/gentoo` is the intended target root.
- Selected stage3: official Gentoo amd64 stage3 tarball matching `PROFILE` and `stage3_variant`.
- Network, DNS, and time status.
- Download directory.
- Download cache and mirror policy in `docs/download-cache-and-mirror-policy.md`.
- Verification files such as checksums and signatures when available.
- Whether `/mnt/gentoo` is empty or already contains a Gentoo root.

## 4. Stage3 Selection
Stage3 assumptions:

- Architecture: amd64.
- Init system: OpenRC for the manual phase-1 path, OpenRC or systemd for the reusable Ansible path.
- Source: official Gentoo stage3 tarball and official Gentoo release metadata.
- `PROFILE=openrc` maps to the official `current-stage3-amd64-openrc/` metadata path.
- `PROFILE=systemd` maps to the official `current-stage3-amd64-systemd/` metadata path.
- Non-amd64 stage3 tarballs are out of scope for v1.

The selected filename and metadata path should clearly indicate amd64 and the selected init variant. The skill must fail if architecture does not match amd64 or if the selected tarball does not match `PROFILE` and `stage3_variant`.

Manual validation examples may include checking filenames, release metadata, and tarball contents. Future automation must parse official metadata where practical instead of relying only on filename string matching.

## 5. Download Procedure
Use:

```text
make stage3-install
make download-stage3
```

The download procedure should:

- Use official Gentoo mirror or release metadata.
- Download the stage3 tarball.
- Download the matching `latest-stage3-amd64-<variant>.txt` metadata.
- Download checksum files such as `.DIGESTS`, `.DIGESTS.asc`, or `.sha256` where available.
- Download signature files such as tarball `.asc`, `.DIGESTS.asc`, or signed `.sha256` where available.
- Preserve downloaded file names.
- Preserve download timestamps.
- Avoid writing downloads into the target root unless that path is explicitly planned.
- Record the selected mirror or source URL.

Manual validation commands may inspect downloaded filenames, timestamps, and sizes. Future automation should produce structured output containing file path, source URL, size, and timestamp.

## 6. Verification Procedure
Use:

```text
make stage3-install
make verify-stage3
```

Verification should:

- Verify checksums.
- Verify signatures where official metadata and tooling are available.
- Confirm the tarball is official Gentoo stage3.
- Confirm architecture is amd64.
- Confirm init system matches `PROFILE` and `stage3_variant`.
- Fail if checksum verification fails.
- Fail if signature verification fails when signature verification is required.
- Fail closed if signature tooling or trusted keys are missing and no later OpenSpec change defines an explicit approved override.
- Fail if metadata is missing and no approved fail-closed fallback exists.

Preserve logs of downloaded file names, checksums, verification status, and timestamps.

Manual validation commands may include checksum verification and signature verification tools available in the live ISO. Future automation must fail closed on verification mismatch.

The detailed policy is documented in `docs/stage3-signature-policy.md`. The implemented `make stage3-install` target must follow that document before extraction.

## 7. Extraction Procedure
Use:

```text
make stage3-install
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

- Use the verified amd64 stage3 tarball matching `PROFILE` and `stage3_variant`.
- Preserve permissions, ownership, extended attributes, and numeric IDs as required by Gentoo installation practice.
- Extract into `/mnt/gentoo`.
- Record tarball path, target root, timestamp, and result.

Manual validation may inspect `/mnt/gentoo` after extraction for expected directories such as `etc`, `usr`, `var`, `bin`, and `root`. Future automation must check target-root assertions before extraction.

## 8. Mount Preparation for Chroot
Use:

```text
make prepare-chroot
```

The implemented `make prepare-chroot` target should:

- Confirm `/mnt/gentoo` is mounted.
- Confirm required target directories exist after stage3 extraction.
- Prepare `/mnt/gentoo/proc`, `/mnt/gentoo/sys`, `/mnt/gentoo/dev`, `/mnt/gentoo/dev/pts`, and `/mnt/gentoo/run` for chroot.
- Ensure bind mounts are scoped under `/mnt/gentoo`.
- Avoid mounting over unrelated live ISO paths.
- Show current mounts before and after preparation.

The target must be idempotent: if required mounts already exist and point to the expected sources, it must not duplicate them.

## 9. DNS Preparation
DNS preparation should:

- Confirm DNS works in the live ISO before chroot.
- Ensure resolver configuration is available inside `/mnt/gentoo` by a documented and reversible method.
- Avoid overwriting target resolver configuration without review.
- Record what DNS files or links were placed into the target.
- Validate target DNS with a read-only `chroot /mnt/gentoo getent hosts distfiles.gentoo.org` check before Portage or package operations.

Manual validation may test name resolution before and after chroot entry. The implemented automation must fail if DNS cannot be proven available for package operations.

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
- `make stage3-install`
- `make prepare-chroot`
- `make enter-chroot`
- `make mount-plan`
- `make filesystem-plan`

Target expectations:

- `make download-stage3`: fetch official amd64 stage3 and verification files matching `PROFILE`.
- `make verify-stage3`: verify checksums, signatures, architecture, and selected init variant according to `docs/stage3-signature-policy.md`.
- `make extract-stage3`: extract only verified stage3 into confirmed `/mnt/gentoo`.
- `make stage3-install`: implemented combined workflow that downloads, verifies, and extracts the selected official stage3 into verified `/mnt/gentoo`.
- `make prepare-chroot`: implemented combined workflow that prepares Handbook-aligned pseudo-filesystems and DNS for later chroot-based tasks without running Portage, package, kernel, user, service, or bootloader operations.
- `make enter-chroot`: enter target chroot after readiness checks.
- `make mount-plan`: read-only prerequisite check that reports the intended target mount layout before `make mount-target`.
- `make mount-target`: mount the approved root, Btrfs subvolumes when selected, and ESP before stage3 extraction.
- `make filesystem-plan`: read-only prerequisite check that reports the intended filesystem creation plan before any future `format` action.

The operator should not be asked to run raw download, tar extraction, mount, DNS-copy, or chroot commands when Makefile targets exist.

## 12. Failure Modes
- `/mnt/gentoo` is not mounted.
- `/mnt/gentoo` is not the intended target root.
- `/mnt/gentoo` points to the live root or an unexpected filesystem.
- Wrong stage3 variant selected.
- Stage3 architecture is not amd64.
- Stage3 init system does not match `PROFILE` and `stage3_variant`.
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
- If the wrong stage3 was selected, delete only the known bad downloaded file through documented cleanup and select the amd64 tarball matching `PROFILE`.
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
- Architecture and init-variant validation result.
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
