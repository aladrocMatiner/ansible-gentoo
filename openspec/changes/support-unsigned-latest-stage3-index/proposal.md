# Change: support-unsigned-latest-stage3-index

## Summary
Allow the stage3 installer to handle official Gentoo `latest-stage3-*` index files that are not OpenPGP clearsigned, while keeping mandatory signature and checksum verification on the selected stage3 tarball and signed DIGESTS metadata.

## Motivation
The E2E matrix found that standard stage3 `latest-*` indexes can be clearsigned, but hardened stage3 `latest-*` indexes may be plain text. The current role treats every latest index as a required OpenPGP signed message, so hardened installs fail before the tarball and checksum trust anchors can be verified.

## Problem Statement
The installer currently rejects official hardened stage3 indexes with:

```text
gpg: no valid OpenPGP data found.
```

That blocks supported hardened matrix cases even though the selected tarball `.asc` and `.DIGESTS` metadata are still available for verification.

## Scope
- Detect whether the downloaded `latest-stage3-*` index is OpenPGP clearsigned.
- Verify the latest index when it is signed.
- Treat an unsigned latest index as non-authoritative selection metadata.
- Keep `.DIGESTS` signature verification mandatory.
- Keep tarball detached signature verification mandatory.
- Keep SHA512 checksum verification mandatory.
- Record whether the latest index was signed and verified in evidence.
- Update stage3 signature documentation and OpenSpec requirements.

## Non-Goals
- Do not skip tarball signature verification.
- Do not skip signed DIGESTS verification.
- Do not add unsigned checksum exceptions.
- Do not automate new installer behavior beyond the stage3 verification fix.
- Do not change the supported matrix.

## Safety Considerations
The latest index is only used to select a tarball filename matching the requested `PROFILE` and `STAGE3_FLAVOR`. Extraction remains blocked unless the selected tarball verifies against signed Gentoo metadata and the SHA512 checksum passes.

## Acceptance Criteria
- Hardened latest indexes that are plain text do not fail solely because the latest index lacks OpenPGP armor.
- Clearsigned latest indexes are still verified and signature failure still stops the workflow.
- Signed DIGESTS verification remains mandatory.
- Tarball detached signature verification remains mandatory.
- SHA512 checksum verification remains mandatory.
- Stage3 evidence records whether the latest index was signed and whether verification was performed.
- `openspec validate support-unsigned-latest-stage3-index --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files
- `ansible/roles/common/stage3/tasks/main.yml`
- `docs/stage3-signature-policy.md`
- `docs/ansible-stage3-install.md`
- `openspec/changes/support-unsigned-latest-stage3-index/*`
