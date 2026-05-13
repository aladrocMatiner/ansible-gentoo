# Tasks: support-unsigned-latest-stage3-index

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate support-unsigned-latest-stage3-index --strict`.

## Implementation
- [x] Detect whether the latest stage3 index is OpenPGP clearsigned.
- [x] Verify the latest index only when it is signed.
- [x] Keep signed DIGESTS verification mandatory.
- [x] Keep tarball detached signature verification mandatory.
- [x] Keep SHA512 checksum verification mandatory.
- [x] Record latest-index signature status in stage3 evidence.

## Documentation
- [x] Update stage3 signature policy documentation.
- [x] Update stage3 install documentation.

## Validation
- [x] Run `make ansible-check`.
- [x] Run `openspec validate --all --strict`.
- [x] Re-run a hardened validation path.
