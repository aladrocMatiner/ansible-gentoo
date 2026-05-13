## Why

libvirt testing depends on host capabilities. The project needs a clear host requirements contract so host setup failures are not confused with installer failures.

## What Changes

- Define supported host requirements for VM/libvirt workflows.
- Document required tools, permissions, firmware, networking, storage, and CPU virtualization.
- Add read-only host checks before VM workflows.
- Keep host setup separate from Gentoo target installation.

## Capabilities

### New Capabilities
- `supported-host-requirements`: Defines host prerequisites for libvirt and project development/test workflows.

### Modified Capabilities

## Impact

- VM docs, Makefile checks, config validation, release readiness.
