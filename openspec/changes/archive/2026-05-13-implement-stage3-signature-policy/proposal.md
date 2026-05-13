## Why

Stage3 extraction establishes the target root filesystem. The installer must verify downloaded stage3 artifacts consistently before extraction.

## What Changes

- Define mandatory checksum verification for official Gentoo stage3 downloads.
- Define signature verification expectations using official Gentoo metadata and trusted keys where practical.
- Fail closed when checksum verification fails.
- Require explicit documented override or failure when signature verification cannot be performed.
- Record downloaded filenames, timestamps, checksum status, and signature status in logs/audit output.

## Capabilities

### New Capabilities
- `stage3-signature-policy`: Defines checksum and signature verification requirements for stage3 artifacts.

### Modified Capabilities

## Impact

- Future stage3 Ansible role and Makefile targets.
- Audit bundle and Handbook traceability output.
- Documentation under stage3/chroot skills and docs.
