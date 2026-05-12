# Design: implement-libvirt-install-test-matrix

## Matrix Entries

Required planned matrix:

| Entry | Platform | Profile | Filesystem | Stage3 flavor |
| --- | --- | --- | --- | --- |
| `amd64-openrc-ext4` | `amd64` | `openrc` | `ext4` | `standard` |
| `amd64-openrc-btrfs` | `amd64` | `openrc` | `btrfs` | `standard` |
| `amd64-systemd-ext4` | `amd64` | `systemd` | `ext4` | `standard` |
| `amd64-systemd-btrfs` | `amd64` | `systemd` | `btrfs` | `standard` |
| `amd64-openrc-ext4-hardened` | `amd64` | `openrc` | `ext4` | `hardened` |
| `amd64-openrc-btrfs-hardened` | `amd64` | `openrc` | `btrfs` | `hardened` |
| `amd64-systemd-ext4-hardened` | `amd64` | `systemd` | `ext4` | `hardened` |
| `amd64-systemd-btrfs-hardened` | `amd64` | `systemd` | `btrfs` | `hardened` |
| `amd64-openrc-ext4-musl` | `amd64` | `openrc` | `ext4` | `musl` |
| `amd64-openrc-btrfs-musl` | `amd64` | `openrc` | `btrfs` | `musl` |
| `amd64-systemd-ext4-musl` | `amd64` | `systemd` | `ext4` | `musl` |
| `amd64-systemd-btrfs-musl` | `amd64` | `systemd` | `btrfs` | `musl` |

## Test Phases

Matrix validation should progress in phases:

1. read-only preflight, disk detection, install plan, partition plan, mount plan, filesystem plan,
2. destructive install in disposable libvirt disks once apply roles exist,
3. first-boot validation once bootloader and final checks exist.

## Safety

- Use only project-local qcow2 disks under the approved libvirt artifact directory.
- Never use host block devices.
- Require explicit destructive confirmations for full-install matrix runs.
- Use separate disks or restored snapshots per matrix entry.
- Keep VM domains and artifacts named so cleanup cannot affect unrelated VMs.

## Makefile Integration

Implemented targets:

- `make vm-test-matrix`
- `make vm-test-matrix-plan`

`make vm-test-matrix-plan` enumerates all supported amd64 profile/filesystem/stage3 flavor entries, validates entry configuration, writes evidence under `logs/libvirt-matrix/<timestamp>/`, and does not create disks or domains. `make vm-test-matrix` is an alias for the same read-only planner.

`VM_TEST_IMAGE_NAME=<image-name>` is optional. When set, the planner inserts it between `VM_NAME` and the `amd64` platform segment in planned domain and disk names. The value must be a conservative label, not a path, ISO filename, token, or secret.

Optional read-only target plan validation is available with:

```sh
make vm-test-matrix-plan VM_TEST_MATRIX_RUN_TARGET_PLANS=yes
```

This mode requires a booted, SSH-enabled live ISO target and runs implemented read-only plan wrappers only.

Planned later target:

- `make vm-test-matrix-clean`

Only implemented targets should be advertised as runnable in README quickstarts.
