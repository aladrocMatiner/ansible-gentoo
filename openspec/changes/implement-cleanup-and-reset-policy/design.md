# Design: implement-cleanup-and-reset-policy

## Cleanup Scopes

Potential scopes:

- VM domains and qcow2 artifacts under approved project paths,
- copied OVMF vars files,
- logs,
- install state,
- audit bundles,
- downloaded stage3 files,
- temporary live-session secret files.

## Rules

- Cleanup must be Makefile-mediated.
- Destructive cleanup must require explicit confirmation, such as typing `DELETE`.
- Cleanup must operate only under approved project-local paths.
- Cleanup must not follow symlinked artifact directories.
- Cleanup must not delete arbitrary user-provided paths.
- Cleanup must not delete host block devices.
- Audit bundles should be preserved by default.

## Makefile Integration

Planned targets may include:

- `make clean-vm`
- `make clean-state`
- `make clean-logs`
- `make clean-audit`
- `make reset-test-run`

Actual targets must document scope precisely.
