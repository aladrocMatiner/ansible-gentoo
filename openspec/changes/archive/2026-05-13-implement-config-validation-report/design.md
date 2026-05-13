# Design: implement-config-validation-report

## Report Scope

The report must validate:

- canonical variables and allowed values,
- missing required variables for the requested mode,
- no-default `INSTALL_DISK` behavior,
- destructive confirmation only when needed,
- `PROFILE`, `stage3_variant`, and `stage3_flavor` consistency,
- `FILESYSTEM` and Btrfs policy consistency,
- UEFI-only boot mode,
- target mount paths under `/mnt/gentoo`,
- secret input policy violations,
- host/libvirt requirements when VM mode is selected.

## Makefile Integration

Planned target:

```sh
make config-check PROFILE=openrc FILESYSTEM=ext4
```

The target must be read-only and safe to run before the ISO is booted when host-only checks are requested.

## Output

Output should include:

- PASS/FAIL status,
- normalized variable values,
- missing variables,
- unsupported values,
- warnings,
- next recommended Makefile target.

## Error Taxonomy

Failures should use codes from the logging/error taxonomy, such as `CONFIG_INVALID`, `DISK_UNSAFE`, `SECRET_LEAK_RISK`, or `HOST_REQUIREMENT_MISSING`.
