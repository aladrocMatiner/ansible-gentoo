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
| `CONFIRMATION_MISSING` | A non-disk operation that still requires explicit confirmation is missing that confirmation. |
| `VERIFY_FAILED` | Checksum, signature, UUID, or generated-file verification failed. |
| `SECRET_LEAK_RISK` | A value appears to contain a secret or a forbidden secret channel is in use. |
| `MOUNT_UNSAFE` | A mount target is missing, already mounted unexpectedly, or outside the approved path. |
| `STAGE3_UNSAFE` | Stage3 target, cache, mirror, variant, or existing target-root state is unsafe. |
| `STAGE3_VARIANT_MISMATCH` | Selected stage3 metadata does not match the requested profile or init variant. |
| `STAGE3_SIGNATURE_UNAVAILABLE` | Required signature tooling or trusted Gentoo release keys are missing and no approved override exists. |
| `STAGE3_TOOL_MISSING` | Required stage3 download, verification, or extraction tooling is missing. |
| `STAGE3_EXTRACT_FAILED` | Stage3 extraction completed unsuccessfully or expected base paths are missing. |
| `CHROOT_NOT_READY` | Target root pseudo-filesystems, DNS, or chroot prerequisites are incomplete. |
| `PORTAGE_FAILED` | Portage sync, profile, package, or configuration operation failed. |
| `BOOTLOADER_UNSAFE` | UEFI, EFI mount, GRUB, or boot entry safety checks failed. |
| `FINAL_CHECK_FAILED` | Reboot-readiness validation failed. |
| `INSTALL_STATE_INVALID` | Install state is missing, malformed, incomplete, outside the approved path, or unsafe to consume. |
| `INSTALL_STATE_SECRET_RISK` | Install state contains secret-like keys or values and must not be used. |
| `RESUME_CHECKPOINT_INVALID` | Resume validation was requested but the recorded checkpoint is absent or incomplete. |
| `RESUME_CHECKPOINT_MISMATCH` | Current target disk, partition, filesystem, UUID, mount, profile, or filesystem facts differ from the checkpoint. |
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

## Implementation Conventions

Bash wrappers that source `scripts/vm-libvirt-common.sh` should use:

- `require_command`, which reports `HOST_REQUIREMENT_MISSING`,
- `assert_install_disk_input`, which reports `DISK_UNSAFE`,
- `require_ansible_live_target`, which reports `NETWORK_UNAVAILABLE` for failed target discovery,
- `die_code <CODE> <message>` when adding new wrapper-level validation.

Ansible assertions should start `fail_msg` with the stable code, for example:

```yaml
fail_msg: "DISK_UNSAFE: INSTALL_DISK is required."
```

Python helpers should print errors as:

```text
<script>: <CODE>: <safe summary>
```

New codes must be added to this document when introduced.
