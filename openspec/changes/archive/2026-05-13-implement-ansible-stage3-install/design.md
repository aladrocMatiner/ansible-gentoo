# Design: implement-ansible-stage3-install

## Selection
Use official Gentoo release metadata where practical. `stage3_variant` must match `PROFILE`, and `stage3_flavor` must select the matching standard, hardened, or musl official metadata.

Expected mapping:

- `PROFILE=openrc` maps to the official amd64 OpenRC stage3.
- `PROFILE=systemd` maps to the official amd64 systemd stage3.

Do not infer the stage3 variant from filenames alone when official metadata can be parsed.

## Verification
Download checksums and signatures when available. Fail closed on checksum mismatch.

Stage3 metadata, tarball, signature, and checksum downloads should use bounded retries with explicit request timeouts. Retry behavior handles transient network or mirror failures only; it must not bypass signature or checksum verification, and partial files must not be treated as trusted cache entries.

## Extraction
Use tar options appropriate for Gentoo stage3 extraction, preserving numeric ownership and attributes. Extract only into verified `/mnt/gentoo`.

The target root must already be mounted according to the approved mount plan. Extraction into `/`, an unmounted `/mnt/gentoo`, or an unexpected existing root must fail.

## Evidence
Record source URL, filenames, checksums, signature status, timestamp, target root, and extraction result.
