# Libvirt Case Quickstarts

These quickstarts run one disposable local libvirt validation case at a time. The v1 platform is `amd64`, and VM targets derive the domain, disk, XML, NVRAM, log, and local install-state paths from `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR`.

| Case | Quickstart |
| --- | --- |
| `amd64-openrc-ext4` | [openrc-ext4.md](openrc-ext4.md) |
| `amd64-openrc-btrfs` | [openrc-btrfs.md](openrc-btrfs.md) |
| `amd64-systemd-ext4` | [systemd-ext4.md](systemd-ext4.md) |
| `amd64-systemd-btrfs` | [systemd-btrfs.md](systemd-btrfs.md) |
| `amd64-openrc-ext4-hardened` | [openrc-ext4-hardened.md](openrc-ext4-hardened.md) |
| `amd64-openrc-btrfs-hardened` | [openrc-btrfs-hardened.md](openrc-btrfs-hardened.md) |
| `amd64-systemd-ext4-hardened` | [systemd-ext4-hardened.md](systemd-ext4-hardened.md) |
| `amd64-systemd-btrfs-hardened` | [systemd-btrfs-hardened.md](systemd-btrfs-hardened.md) |
| `amd64-openrc-ext4-musl` | [openrc-ext4-musl.md](openrc-ext4-musl.md) |
| `amd64-openrc-btrfs-musl` | [openrc-btrfs-musl.md](openrc-btrfs-musl.md) |
| `amd64-systemd-ext4-musl` | [systemd-ext4-musl.md](systemd-ext4-musl.md) |
| `amd64-systemd-btrfs-musl` | [systemd-btrfs-musl.md](systemd-btrfs-musl.md) |

Run `make vm-list-cases` to print all generated case domains and artifact paths before creating anything.

The default case is `PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard`, which maps to `gentoo-test-amd64-openrc-ext4`. Standard cases omit the `standard` suffix; hardened and musl cases append the flavor.

To label a manually tested image or test line, pass a conservative non-secret label:

```sh
make vm-list-cases VM_TEST_IMAGE_NAME=handbook
```

The label is inserted before `amd64`, for example `gentoo-test-handbook-amd64-openrc-ext4`. `VM_TEST_IMAGE_NAME` is not an ISO path; use `VM_ISO` for the official Gentoo live ISO path.

The VM guest disk examples use `/dev/vda` because the target is the disposable qcow2 disk inside libvirt. Real hardware workflows must use the explicit disk reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.
