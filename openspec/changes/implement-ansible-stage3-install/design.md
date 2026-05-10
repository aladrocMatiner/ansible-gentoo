# Design: implement-ansible-stage3-install

## Selection
Use official Gentoo release metadata where practical. `stage3_variant` must match `PROFILE`.

Expected mapping:

- `PROFILE=openrc` maps to the official amd64 OpenRC stage3.
- `PROFILE=systemd` maps to the official amd64 systemd stage3.

Do not infer the stage3 variant from filenames alone when official metadata can be parsed.

## Verification
Download checksums and signatures when available. Fail closed on checksum mismatch.

## Extraction
Use tar options appropriate for Gentoo stage3 extraction, preserving numeric ownership and attributes. Extract only into verified `/mnt/gentoo`.

The target root must already be mounted according to the approved mount plan. Extraction into `/`, an unmounted `/mnt/gentoo`, or an unexpected existing root must fail.

## Evidence
Record source URL, filenames, checksums, signature status, timestamp, target root, and extraction result.
