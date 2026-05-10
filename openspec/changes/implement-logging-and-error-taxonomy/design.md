# Design: implement-logging-and-error-taxonomy

## Error Categories

Initial categories:

- `CONFIG_INVALID`
- `HOST_REQUIREMENT_MISSING`
- `LIVE_ISO_NOT_READY`
- `NETWORK_UNAVAILABLE`
- `DISK_UNSAFE`
- `CONFIRMATION_MISSING`
- `VERIFY_FAILED`
- `SECRET_LEAK_RISK`
- `MOUNT_UNSAFE`
- `CHROOT_NOT_READY`
- `PORTAGE_FAILED`
- `BOOTLOADER_UNSAFE`
- `FINAL_CHECK_FAILED`
- `VM_VALIDATION_FAILED`
- `UNSUPPORTED_SCOPE`

## Logging Paths

Logs should live under project-local `logs/`, preferably grouped by run id:

```text
logs/install-runs/<run-id>/
```

## Message Requirements

Errors should include:

- code,
- short summary,
- failing target/role/task,
- relevant safe context,
- next recommended recovery action.

## Secret Safety

Logs must not print secret values. If an error involves a secret, log the variable name and redacted status only.
