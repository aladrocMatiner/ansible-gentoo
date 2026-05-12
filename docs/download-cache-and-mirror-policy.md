# Download Cache And Mirror Policy

Stage3 downloads, Gentoo metadata, Portage syncs, and cleanup must use documented paths and verified inputs. Cache reuse must never bypass checksum or signature verification.

## Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `STAGE3_MIRROR` | `https://distfiles.gentoo.org/releases/amd64/autobuilds` | Official Gentoo stage3 autobuild metadata base URL. |
| `STAGE3_CACHE_DIR` | `/tmp/gentoo-ai-installer/stage3` | Live-ISO-local cache for stage3 metadata, tarballs, signatures, and verification work files. |
| `PORTAGE_GENTOO_MIRRORS` | `https://distfiles.gentoo.org` | HTTPS Gentoo distfiles mirror written to target `GENTOO_MIRRORS`. |

`STAGE3_CACHE_DIR` is a path on the live ISO target, not a host path in the normal SSH-driven installer flow. It must be absolute, must not be under `TARGET_MOUNT`, and must not point at arbitrary host disks.

## Mirror Policy

- Prefer official Gentoo metadata and mirrors.
- Mirror overrides must use documented Makefile variables.
- Mirror URLs must use HTTPS in v1.
- Overrides must not skip checksum or signature verification.
- The installed system must not blindly inherit controller-local private mirror credentials.

## Cache Reuse

The cache may reduce repeated downloads, but it does not prove trust. A cached stage3 tarball is reusable only after:

- metadata is fetched or present from the approved source,
- SHA512 checksum verification passes,
- signature verification follows `docs/stage3-signature-policy.md`,
- selected stage3 variant matches `PROFILE`.

Partial files must not be promoted to verified artifact names. Interrupted downloads must be retried or cleaned through documented cleanup targets.

Stage3 download tasks should use bounded retries and explicit request timeouts for metadata, tarballs, signatures, and checksum files. A retry only handles transient transport failure; every downloaded or cached artifact must still pass the normal signature and checksum checks before extraction.

## Cleanup

Stage3 cache cleanup is exposed through:

```sh
make cleanup-plan CLEAN_SCOPE=stage3-cache
make clean-stage3-cache I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

Cleanup may delete only approved target-local cache paths under `/tmp/gentoo-ai-installer/`. It must not delete arbitrary paths and must not remove audit bundles unless an explicit audit cleanup scope is used.

## Evidence

Stage3 evidence must record:

- selected mirror or metadata URL,
- selected stage3 variant,
- downloaded filenames,
- checksum status,
- signature status,
- timestamps,
- whether cached files were reused after reverification.

Audit bundles should include verification evidence but not the downloaded tarball itself.

## Failure Modes

- Mirror URL rejected: use an HTTPS Gentoo-compatible mirror URL.
- Cached file fails verification: delete only the failed cache files under `STAGE3_CACHE_DIR` or run `make clean-stage3-cache` with confirmation.
- `STAGE3_CACHE_DIR` unsafe: use the default `/tmp/gentoo-ai-installer/stage3`.
- Portage sync fails: verify live ISO network, DNS, time, and mirror reachability, then rerun the Makefile target.

## Recovery

Do not manually extract unverified tarballs. Fix mirror/cache inputs, rerun `make stage3-install`, and let the stage3 role reverify artifacts before extraction.
