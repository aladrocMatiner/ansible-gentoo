# Design: support-unsigned-latest-stage3-index

## Current Behavior
The stage3 role runs `gpg --verify` against the downloaded `latest-stage3-*` index unconditionally. This works for clearsigned standard indexes but fails for official hardened indexes that are currently plain text.

## New Behavior
The role must inspect the downloaded latest index before verification:

- If the first line is `-----BEGIN PGP SIGNED MESSAGE-----`, run `gpg --verify` on the latest index and fail on verification failure.
- If the first line is not OpenPGP signed-message armor, mark the latest index as unsigned and continue only to the mandatory verification steps for signed DIGESTS, tarball detached signature, and SHA512 checksum.

## Trust Model
The latest index is selection metadata, not the final extraction trust anchor. The final trust chain is:

1. Stage3 filename must match the selected architecture, init system, and flavor.
2. Signed `.DIGESTS` metadata must verify with Gentoo release keys.
3. Tarball detached `.asc` signature must verify with Gentoo release keys.
4. SHA512 checksum extracted from signed DIGESTS must match the downloaded tarball.

If any mandatory trust anchor fails, extraction must stop.

## Evidence
`verification.json` must include:

- `latest_metadata_signed`
- `latest_metadata_signature_checked`
- `latest_metadata_signature_verified`
- existing DIGESTS, tarball, optional SHA256, and checksum status

## Documentation
Documentation must state that some official latest indexes may be unsigned and that this does not relax mandatory tarball/DIGESTS/checksum verification.

## Test Strategy
- Run syntax checks for shell and Ansible YAML where practical.
- Run `make ansible-check`.
- Run OpenSpec validation.
- Re-run at least one hardened stage3 or E2E workflow after the fix.
