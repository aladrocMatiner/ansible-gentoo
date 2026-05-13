# Design: extend-libvirt-matrix-stage3-flavors

## Stage3 Flavor Model

Use three independent selectors:

| Selector | Values | Meaning |
| --- | --- | --- |
| `PROFILE` | `openrc`, `systemd` | Init system and service manager |
| `FILESYSTEM` | `ext4`, `btrfs` | Target root filesystem layout |
| `STAGE3_FLAVOR` | `standard`, `hardened`, `musl` | Gentoo stage3/profile family |

`PROFILE` must not be overloaded with hardened or musl. `STAGE3_FLAVOR` is orthogonal to filesystem and must be passed through Makefile targets, scripts, Ansible extra vars, reports, and matrix evidence.

## Supported Matrix

The supported libvirt matrix is:

| Case key | Profile | Filesystem | Stage3 flavor |
| --- | --- | --- | --- |
| `amd64-openrc-ext4` | `openrc` | `ext4` | `standard` |
| `amd64-openrc-btrfs` | `openrc` | `btrfs` | `standard` |
| `amd64-systemd-ext4` | `systemd` | `ext4` | `standard` |
| `amd64-systemd-btrfs` | `systemd` | `btrfs` | `standard` |
| `amd64-openrc-ext4-hardened` | `openrc` | `ext4` | `hardened` |
| `amd64-openrc-btrfs-hardened` | `openrc` | `btrfs` | `hardened` |
| `amd64-systemd-ext4-hardened` | `systemd` | `ext4` | `hardened` |
| `amd64-systemd-btrfs-hardened` | `systemd` | `btrfs` | `hardened` |
| `amd64-openrc-ext4-musl` | `openrc` | `ext4` | `musl` |
| `amd64-openrc-btrfs-musl` | `openrc` | `btrfs` | `musl` |
| `amd64-systemd-ext4-musl` | `systemd` | `ext4` | `musl` |
| `amd64-systemd-btrfs-musl` | `systemd` | `btrfs` | `musl` |

## Naming Rules

Standard cases preserve the current name shape:

```text
gentoo-test-amd64-openrc-ext4
gentoo-test-amd64-systemd-btrfs
```

Non-standard cases append the stage3 flavor:

```text
gentoo-test-amd64-openrc-ext4-hardened
gentoo-test-amd64-systemd-btrfs-musl
```

When `VM_TEST_IMAGE_NAME=<label>` is used, it remains between the base VM name and platform:

```text
gentoo-test-<label>-amd64-openrc-btrfs-musl
```

## Stage3 Selection

The stage3 role must derive official Gentoo autobuild index names from `PROFILE` and `STAGE3_FLAVOR`:

| `PROFILE` | `STAGE3_FLAVOR` | Latest file |
| --- | --- | --- |
| `openrc` | `standard` | `latest-stage3-amd64-openrc.txt` |
| `systemd` | `standard` | `latest-stage3-amd64-systemd.txt` |
| `openrc` | `hardened` | `latest-stage3-amd64-hardened-openrc.txt` |
| `systemd` | `hardened` | `latest-stage3-amd64-hardened-systemd.txt` |
| `openrc` | `musl` | `latest-stage3-amd64-musl-openrc.txt` |
| `systemd` | `musl` | `latest-stage3-amd64-musl-systemd.txt` |

The downloaded tarball must start with the matching base name. Checksum and signature policy remains unchanged.

## Portage Profile Selection

Portage profile selection must match both init system and flavor:

| `PROFILE` | `STAGE3_FLAVOR` | Portage profile |
| --- | --- | --- |
| `openrc` | `standard` | `default/linux/amd64/23.0` |
| `systemd` | `standard` | `default/linux/amd64/23.0/systemd` |
| `openrc` | `hardened` | `default/linux/amd64/23.0/hardened` |
| `systemd` | `hardened` | `default/linux/amd64/23.0/hardened/systemd` |
| `openrc` | `musl` | `default/linux/amd64/23.0/musl` |
| `systemd` | `musl` | `default/linux/amd64/23.0/musl/systemd` |

The Portage role should derive this mapping in one shared place rather than duplicating it between OpenRC and systemd flows.

## Makefile Integration

Add:

```make
STAGE3_FLAVOR ?= standard
export STAGE3_FLAVOR
```

Makefile help must document:

- `PROFILE=openrc|systemd`
- `FILESYSTEM=ext4|btrfs`
- `STAGE3_FLAVOR=standard|hardened|musl`
- the 12-case matrix

No operator-facing command should require raw `ansible-playbook` invocation.

## Safety Gates

Stage3 flavor does not change destructive behavior. The same shared safety gates apply to all 12 cases:

- no default `INSTALL_DISK`,
- explicit wipe confirmation for destructive tasks,
- shared disk identity reporting,
- shared destructive confirmation validation,
- no host block devices in libvirt workflows,
- `/dev/vda` only as the explicit guest VM disk inside disposable libvirt guests.
- Matrix/list targets must derive unique user-mode SSH host ports per case and reject a shared manual `VM_SSH_HOST_PORT` override.

## Documentation Requirements

Update documentation in the same implementation change:

- README or overview docs with the new selector.
- `docs/libvirt-install-test-matrix.md` with the 12 cases.
- `docs/quickstarts/` with hardened and musl case quick starts or an index table pointing to exact commands.
- `docs/ansible-stage3-install.md` and `docs/ansible-portage-baseline.md`.
- `docs/install-configuration.md`.
- relevant skills and agents.

## Review Checklist

- Does every script that passes `PROFILE`/`FILESYSTEM` also pass `STAGE3_FLAVOR` where stage3/profile behavior is relevant?
- Are standard names backward compatible?
- Are all non-standard names explicit?
- Are the SSH ports unique?
- Do matrix/list targets reject manual shared SSH port overrides that would make user-mode networking collide?
- Does the stage3 role use official Gentoo latest files?
- Does the Portage role select matching profiles?
- Do Ansible roles keep shared logic common?
- Do docs avoid claiming full E2E success until the cases are actually run?
