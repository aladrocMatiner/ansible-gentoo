# Logging and Error Taxonomy

Project commands should report stable error codes so failures can be reviewed without parsing fragile prose. Logs and reports must not include secret values.

## Initial Error Codes

| Code | Meaning |
| --- | --- |
| `CONFIG_INVALID` | Operator configuration is malformed or unsupported. |
| `HOST_REQUIREMENT_MISSING` | Required controller-side tooling is missing. |
| `LIVE_ISO_NOT_READY` | The target live ISO is reachable but missing required live-environment state. |
| `NETWORK_UNAVAILABLE` | Network, DNS, route, or SSH readiness failed. |
| `DISK_UNSAFE` | Disk input is missing, ambiguous, mounted, or unsafe. |
| `DESTRUCTIVE_CONFIRMATION_MISSING` | A destructive workflow lacks the required explicit confirmation. |
| `VERIFY_FAILED` | Checksum, signature, UUID, or generated-file verification failed. |
| `SECRET_LEAK_RISK` | A value appears to contain a secret or a forbidden secret channel is in use. |
| `MOUNT_UNSAFE` | A mount target is missing, already mounted unexpectedly, or outside the approved path. |
| `CHROOT_NOT_READY` | Target root pseudo-filesystems, DNS, or chroot prerequisites are incomplete. |
| `PORTAGE_FAILED` | Portage sync, profile, package, or configuration operation failed. |
| `BOOTLOADER_UNSAFE` | UEFI, EFI mount, GRUB, or boot entry safety checks failed. |
| `FINAL_CHECK_FAILED` | Reboot-readiness validation failed. |
| `VM_VALIDATION_FAILED` | Local libvirt harness validation failed. |
| `UNSUPPORTED_CONFIGURATION` | The requested behavior is outside the approved project scope. |

## Message Rules

Errors should include:

- the code,
- the failing target, script, role, or task,
- safe context such as variable names, selected profile, filesystem, or target path,
- the next recovery action.

Errors must not include:

- plaintext passwords,
- API keys,
- login tokens,
- private SSH keys,
- private local credentials.

## Log Paths

Future installer logs should live under project-local `logs/`, grouped by run id when the install-state workflow is implemented:

```text
logs/install-runs/<run-id>/
```

Current read-only checks may print their report to stdout and must remain safe to run before a run id exists.
