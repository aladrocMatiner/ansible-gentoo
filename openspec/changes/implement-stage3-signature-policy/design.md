# Design: implement-stage3-signature-policy

## Verification Policy

Stage3 verification must use official Gentoo release metadata. At minimum:

- download the selected official stage3 tarball,
- download corresponding digest/checksum metadata,
- verify checksum before extraction,
- verify signatures where official metadata and tooling are available,
- fail if checksum verification fails.

If signature verification cannot be completed because tooling or trusted keys are unavailable, implementation must either fail closed or require an explicit documented override approved by OpenSpec.

## Variant Matching

Verification must happen after the stage3 variant is selected and before extraction. The selected stage3 must match:

- amd64,
- `PROFILE=openrc` or `PROFILE=systemd`,
- expected `stage3_variant` and `stage3_flavor`.

## Evidence

Log:

- URLs or mirror paths,
- filenames,
- timestamps,
- checksum algorithm and result,
- signature verification result,
- override reason if an approved override exists.

Do not log secrets.
