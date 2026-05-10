# Ansible Stage3 Install

`make stage3-install` downloads, verifies, and extracts an official Gentoo amd64 stage3 into the mounted target root.

It does not partition, format, mount target filesystems, chroot, configure Portage, install packages, create users, enable services, install a kernel, or install a bootloader.

## Required State

Run the previous apply targets first against the same live ISO target:

```sh
make partition PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
make format PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Inside the local libvirt VM, `/dev/vda` is the disposable guest disk. For a real network target, use the disk reported by `make detect-disks` and pass `ANSIBLE_LIVE_HOST=...`.

## Command

For the local libvirt VM:

```sh
make stage3-install PROFILE=openrc FILESYSTEM=btrfs
```

For a network live ISO target:

```sh
make stage3-install ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=systemd FILESYSTEM=ext4
```

Supported profiles:

- `PROFILE=openrc`: official amd64 OpenRC stage3
- `PROFILE=systemd`: official amd64 systemd stage3

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `PROFILE` | `openrc` | Selects OpenRC or systemd stage3 metadata. |
| `FILESYSTEM` | `ext4` | Passed for configuration consistency; stage3 extraction does not format or mount. |
| `STAGE3_MIRROR` | `https://distfiles.gentoo.org/releases/amd64/autobuilds` | Base URL for official Gentoo stage3 metadata. |
| `STAGE3_CACHE_DIR` | `/tmp/gentoo-ai-installer/stage3` | Live-ISO-local cache for stage3 downloads and verification files. Must not be under `/mnt/gentoo`. |

Mirror overrides must still use HTTPS and must still pass checksum and signature verification.

## Verification

The workflow follows `docs/stage3-signature-policy.md`:

- downloads the official latest metadata for the selected variant,
- selects `stage3-amd64-openrc-*.tar.xz` or `stage3-amd64-systemd-*.tar.xz`,
- downloads the selected tarball, `.DIGESTS`, `.asc`, and optional `.sha256` metadata when present,
- imports `/usr/share/openpgp-keys/gentoo-release.asc` into an isolated GnuPG home under the live ISO cache,
- verifies the signed latest metadata,
- verifies the signed `.DIGESTS` metadata,
- verifies the tarball detached signature,
- verifies optional signed `.sha256` metadata when present,
- verifies the tarball SHA512 checksum from signed `.DIGESTS`,
- fails before extraction if any verification step fails.

Cached tarballs are reverified before extraction. Cache presence is never treated as proof of trust.

## Extraction

The target root must be mounted at `/mnt/gentoo`. The workflow refuses extraction if `/mnt/gentoo` is not a mountpoint, if the target root is `/`, or if stage3-like paths such as `etc`, `usr`, `bin`, `lib`, `sbin`, `opt`, or `root` already exist.

Extraction uses tar with xattrs and numeric ownership preserved:

```text
tar -xJpf <verified-stage3> --xattrs-include=*.* --numeric-owner -C /mnt/gentoo
```

## Output

The role writes non-secret evidence under:

```text
logs/install-runs/<run-id>/stage3/
```

Evidence includes:

- selected profile and stage3 variant,
- mirror and metadata URLs,
- selected tarball filename,
- target mount evidence,
- checksum result,
- signature results,
- extraction result.

## Failure Modes

- live ISO target is unreachable over SSH,
- `/mnt/gentoo` is not mounted,
- target root already contains stage3-like paths,
- `wget`, `gpg`, `sha512sum`, or `tar` is missing,
- Gentoo release key bundle is missing,
- selected metadata does not match `PROFILE`,
- download fails,
- signature verification fails,
- checksum verification fails,
- expected directories are missing after extraction.

## Recovery

Stop on failure. Do not extract manually over a partially verified or failed artifact.

If verification fails, remove only the known bad files under `STAGE3_CACHE_DIR` or use a later documented cleanup target, then rerun `make stage3-install`.

If extraction fails after writing files into `/mnt/gentoo`, preserve logs and inspect the target root before retrying. Do not overwrite an existing Gentoo root without a later approved reuse/reset policy.
