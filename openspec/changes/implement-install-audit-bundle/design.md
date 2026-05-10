# Design: implement-install-audit-bundle

## Bundle Location

Audit bundles must be written under project-local logs, for example:

```text
logs/install-runs/<run-id>/audit/
```

The implementation may archive the directory, but raw logs must remain inspectable.

## Bundle Contents

Include:

- run id and timestamps,
- selected `PROFILE`, `FILESYSTEM`, `BOOT_MODE`, and non-secret variables,
- `lsblk` or equivalent disk inventory,
- partition table summary,
- filesystem UUID summary,
- mount table summary,
- stage3 filename, checksums, signature status, and timestamps,
- generated fstab,
- Portage profile and repository sync status,
- installed kernel artifacts,
- service enablement status,
- user/access summary without secrets,
- bootloader and EFI evidence,
- final checks report,
- Ansible logs and task summaries.

## Secret Redaction

The bundle must not include:

- passwords,
- password hashes unless explicitly approved as safe to store,
- API keys,
- login tokens,
- private SSH keys,
- unredacted secret variable values.

## Makefile Integration

Planned targets may include:

- `make install-audit`
- `make final-checks`

The final target names must be documented at implementation time.
