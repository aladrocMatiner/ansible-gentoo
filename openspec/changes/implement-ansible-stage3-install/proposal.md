# Change: implement-ansible-stage3-install

## Summary
Implement official Gentoo stage3 download, verification, and extraction into the mounted target root.

## Motivation
After target filesystems are mounted, the installer must install the base Gentoo userspace from an official amd64 stage3 tarball matching the selected init system.

This change maps to the Gentoo AMD64 Handbook "The stage file" section. The implementation must keep the Handbook sequence of selecting an official stage3, verifying it, and extracting it into `/mnt/gentoo`.

## Scope
- Add `make stage3-install` or split Makefile targets for download, verify, and extract.
- Add shared `common/stage3` role.
- Select amd64 OpenRC or systemd stage3 from official Gentoo metadata.
- Select `stage3-amd64-openrc` for `PROFILE=openrc`.
- Select `stage3-amd64-systemd` for `PROFILE=systemd`.
- Follow `implement-stage3-signature-policy`: checksum verification is mandatory, signature verification must be performed where official metadata/tooling are available, and failures stop extraction.
- Follow the download cache and mirror policy for cache paths, mirror overrides, partial downloads, and cache reuse.
- Record verification evidence for install state and audit bundle.
- Extract into `/mnt/gentoo`.

## Non-goals
- Do not configure Portage beyond stage3 contents.
- Do not enter chroot.
- Do not install kernel or bootloader.

## Safety Requirements
- Require `/mnt/gentoo` mounted and verified as target root.
- Refuse extraction into `/`.
- Refuse overwriting an existing Gentoo root unless a later approved reuse policy exists.
- Preserve download and verification evidence.

## Acceptance Criteria
- OpenRC selects amd64 OpenRC stage3.
- systemd selects amd64 systemd stage3.
- Selected stage3 variant matches `PROFILE`, `stage3_variant`, and `stage3_flavor`.
- Verification failure stops extraction.
- Verification logs include filename, timestamp, checksum status, and signature status.
- Cached stage3 artifacts are reverified before extraction.
- Extraction creates expected base directories in `/mnt/gentoo`.
- `openspec validate implement-ansible-stage3-install --strict` passes.

## Affected Files
- `Makefile`
- `ansible/roles/common/stage3/`
- `ansible/init/openrc/`
- `ansible/init/systemd/`
- `docs/`
- `skills/`
