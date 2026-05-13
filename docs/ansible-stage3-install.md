# Ansible Stage3 Install

`make stage3-install` downloads, verifies, and extracts an official Gentoo amd64 stage3 into the mounted target root. `PROFILE` selects OpenRC or systemd, and `STAGE3_FLAVOR` selects `standard`, `hardened`, or `musl`.

It does not partition, format, mount target filesystems, chroot, configure Portage, install packages, create users, enable services, install a kernel, or install a bootloader.

Download cache and mirror behavior follows `docs/download-cache-and-mirror-policy.md`; signature and checksum behavior follows `docs/stage3-signature-policy.md`.

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
make stage3-install PROFILE=openrc FILESYSTEM=btrfs STAGE3_FLAVOR=standard
```

For a network live ISO target:

```sh
make stage3-install ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=systemd FILESYSTEM=ext4 STAGE3_FLAVOR=hardened
```

Supported stage3 selectors:

| `PROFILE` | `STAGE3_FLAVOR` | Official latest metadata |
| --- | --- | --- |
| `openrc` | `standard` | `latest-stage3-amd64-openrc.txt` |
| `systemd` | `standard` | `latest-stage3-amd64-systemd.txt` |
| `openrc` | `hardened` | `latest-stage3-amd64-hardened-openrc.txt` |
| `systemd` | `hardened` | `latest-stage3-amd64-hardened-systemd.txt` |
| `openrc` | `musl` | `latest-stage3-amd64-musl-openrc.txt` |
| `systemd` | `musl` | `latest-stage3-amd64-musl-systemd.txt` |

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `PROFILE` | `openrc` | Selects OpenRC or systemd stage3 metadata. |
| `FILESYSTEM` | `ext4` | Passed for configuration consistency; stage3 extraction does not format or mount. |
| `STAGE3_FLAVOR` | `standard` | Selects standard, hardened, or musl official stage3 metadata. |
| `STAGE3_MIRROR` | `https://distfiles.gentoo.org/releases/amd64/autobuilds` | Base URL for official Gentoo stage3 metadata. |
| `STAGE3_CACHE_DIR` | `/tmp/gentoo-ai-installer/stage3` | Live-ISO-local cache for stage3 downloads and verification files. Must not be under `/mnt/gentoo`. |

Mirror overrides must still use HTTPS and must still pass checksum and signature verification.

## Verification

The workflow follows `docs/stage3-signature-policy.md`:

- downloads the official latest metadata for the selected variant,
- selects the tarball matching `PROFILE` and `STAGE3_FLAVOR`,
- downloads the selected tarball, `.DIGESTS`, `.asc`, and optional `.sha256` metadata when present,
- imports `/usr/share/openpgp-keys/gentoo-release.asc` into an isolated GnuPG home under the live ISO cache,
- verifies the latest metadata when that index is OpenPGP clearsigned,
- records the latest metadata as unsigned when Gentoo publishes it as plain text,
- verifies the signed `.DIGESTS` metadata,
- verifies the tarball detached signature,
- verifies optional signed `.sha256` metadata when present,
- verifies the tarball SHA512 checksum from signed `.DIGESTS`,
- fails before extraction if any mandatory verification step fails.

The latest metadata selects the tarball name. It is not the final extraction trust anchor when Gentoo publishes that index as plain text. Extraction still requires signed `.DIGESTS`, a verified tarball `.asc`, and a matching SHA512 checksum.

Cached tarballs are reverified before extraction. Cache presence is never treated as proof of trust.

Stage3 network fetches use bounded retries and a longer per-request timeout so transient live ISO NAT or mirror stalls do not fail the install immediately. Retry success does not relax checksum or signature verification.

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

- selected profile, stage3 variant, and stage3 flavor,
- mirror and metadata URLs,
- selected tarball filename,
- target mount evidence,
- checksum result,
- latest-index signed/unsigned status,
- mandatory signature results,
- extraction result.

## Failure Modes

- live ISO target is unreachable over SSH,
- `/mnt/gentoo` is not mounted,
- target root already contains stage3-like paths,
- `wget`, `gpg`, `sha512sum`, or `tar` is missing,
- Gentoo release key bundle is missing,
- selected metadata does not match `PROFILE` and `STAGE3_FLAVOR`,
- download fails,
- signature verification fails,
- checksum verification fails,
- expected directories are missing after extraction.

## Recovery

Stop on failure. Do not extract manually over a partially verified or failed artifact.

If verification fails, remove only the known bad files under `STAGE3_CACHE_DIR` or use a later documented cleanup target, then rerun `make stage3-install`.

If extraction fails after writing files into `/mnt/gentoo`, preserve logs and inspect the target root before retrying. Do not overwrite an existing Gentoo root without a later approved reuse/reset policy.
