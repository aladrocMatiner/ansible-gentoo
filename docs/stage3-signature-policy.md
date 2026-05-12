# Stage3 Signature Policy

This policy defines the verification rules that `implement-ansible-stage3-install` must enforce before extracting any Gentoo stage3 tarball into `/mnt/gentoo`.

It is based on the Gentoo AMD64 Handbook stage-file verification flow and official Gentoo release metadata. It does not itself download or extract stage3 artifacts.

## Official Sources

Use official Gentoo release metadata under:

```text
https://distfiles.gentoo.org/releases/amd64/autobuilds/
```

Supported basic console stage3 selectors:

| `PROFILE` | `STAGE3_FLAVOR` | Directory | Latest file |
| --- | --- | --- | --- |
| `openrc` | `standard` | `current-stage3-amd64-openrc/` | `latest-stage3-amd64-openrc.txt` |
| `systemd` | `standard` | `current-stage3-amd64-systemd/` | `latest-stage3-amd64-systemd.txt` |
| `openrc` | `hardened` | `current-stage3-amd64-hardened-openrc/` | `latest-stage3-amd64-hardened-openrc.txt` |
| `systemd` | `hardened` | `current-stage3-amd64-hardened-systemd/` | `latest-stage3-amd64-hardened-systemd.txt` |
| `openrc` | `musl` | `current-stage3-amd64-musl-openrc/` | `latest-stage3-amd64-musl-openrc.txt` |
| `systemd` | `musl` | `current-stage3-amd64-musl-systemd/` | `latest-stage3-amd64-musl-systemd.txt` |

The stage3 implementation must select one of those directories from `PROFILE` and `STAGE3_FLAVOR`. It must not silently substitute desktop, LLVM, SELinux, no-multilib, split-usr, non-amd64, or unrelated variants.

## Required Metadata Files

For the selected variant, the workflow must use official metadata where available:

- the `latest-stage3-*` file matching `PROFILE` and `STAGE3_FLAVOR`
- selected `stage3-amd64-<variant>-<timestamp>.tar.xz`
- selected tarball `.DIGESTS` or `.DIGESTS.asc`
- selected tarball `.asc`
- selected tarball `.sha256` when available
- `.CONTENTS.gz` may be downloaded for evidence, but it is not a substitute for checksum or signature verification

The selected tarball filename, metadata filenames, source URLs, sizes, and timestamps must be recorded in non-secret logs.

## Required Tools

The live ISO target or the controller-side download workflow must have equivalent tools for:

- HTTPS download: `wget` or `curl`
- SHA512 or SHA256 checksum verification: `sha512sum`, `sha256sum`, or `openssl`
- OpenPGP signature verification: `gpg`
- archive extraction in the later stage3 install change: `tar`

If checksum tooling is missing, the stage3 workflow must fail before extraction.

If signature tooling or trusted Gentoo release keys are missing, the workflow must fail closed unless a later OpenSpec change defines an explicit override with documented risk, confirmation, and audit output.

## Checksum Policy

Checksum verification is mandatory.

The workflow must:

1. Download the selected stage3 tarball.
2. Download official checksum metadata for the same tarball.
3. Verify the tarball checksum before extraction.
4. Fail immediately if the computed checksum does not match official metadata.
5. Record the checksum algorithm, expected value source, computed result, and pass/fail status.

The implementation should prefer SHA512 from official `.DIGESTS` metadata where practical. A signed `.sha256` file may also be used when available, but it does not remove the requirement to verify official metadata consistently.

## Signature Policy

Signature verification is required where official signature metadata and tooling are available.

The workflow must verify signatures for official metadata before extraction. Valid inputs may include:

- tarball `.asc`
- `.DIGESTS.asc`
- signed `.sha256`

Signature failure must stop the workflow.

The workflow must not treat an unsigned checksum file as fully trusted unless a later OpenSpec change defines and approves an explicit fail-closed exception. Any exception must be visible in the audit output and must not be enabled by default.

## Variant Policy

The selected stage3 must match all of these values:

- architecture: `amd64`
- `PROFILE=openrc` maps to `stage3_variant=openrc`
- `PROFILE=systemd` maps to `stage3_variant=systemd`
- `STAGE3_FLAVOR` is `standard`, `hardened`, or `musl`
- selected metadata path matches the selected profile and flavor
- selected tarball filename matches the selected profile and flavor

Filename checks are not sufficient by themselves when official metadata can be parsed. Metadata selection and variant variables must agree.

## Evidence

The later stage3 implementation must write non-secret evidence under:

```text
logs/install-runs/<run-id>/stage3/
```

Evidence must include:

- selected profile, stage3 variant, and stage3 flavor,
- source mirror or URL,
- selected metadata file names,
- selected tarball file name,
- download timestamps,
- checksum algorithm and result,
- signature verification result,
- trusted key source or missing-key failure,
- extraction allowed: true/false,
- failure reason when verification blocks extraction.

Do not log API keys, private SSH keys, tokens, passwords, cookies, or private mirror credentials.

## Failure Modes

- selected variant does not match `PROFILE` and `STAGE3_FLAVOR`
- metadata path does not match selected profile and flavor
- metadata download fails
- tarball download fails
- checksum metadata is missing
- checksum mismatch
- `gpg` is missing and no approved fail-closed exception exists
- trusted Gentoo release keys are unavailable
- signature verification fails
- system time prevents TLS or signature validation
- cached artifact exists but fails reverification

## Recovery

If verification fails:

1. Stop before extraction.
2. Keep non-secret evidence logs.
3. Delete only the known bad downloaded file through a documented cleanup path.
4. Re-run download and verification from official metadata.
5. Do not continue with extraction until checksum verification passes and signature policy is satisfied.
