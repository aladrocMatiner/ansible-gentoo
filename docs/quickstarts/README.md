# Libvirt Case Quickstarts

These quickstarts run one disposable local libvirt validation case at a time. The v1 platform is `amd64`, and VM targets derive the domain, disk, XML, NVRAM, log, and local install-state paths from `PROFILE` and `FILESYSTEM`.

| Case | Quickstart |
| --- | --- |
| `amd64-openrc-ext4` | [openrc-ext4.md](openrc-ext4.md) |
| `amd64-openrc-btrfs` | [openrc-btrfs.md](openrc-btrfs.md) |
| `amd64-systemd-ext4` | [systemd-ext4.md](systemd-ext4.md) |
| `amd64-systemd-btrfs` | [systemd-btrfs.md](systemd-btrfs.md) |

Run `make vm-list-cases` to print all generated case domains and artifact paths before creating anything.

The default case is `PROFILE=openrc FILESYSTEM=ext4`, which maps to `gentoo-test-amd64-openrc-ext4`.

To label a manually tested image or test line, pass a conservative non-secret label:

```sh
make vm-list-cases VM_TEST_IMAGE_NAME=handbook
```

The label is inserted before `amd64`, for example `gentoo-test-handbook-amd64-openrc-ext4`. `VM_TEST_IMAGE_NAME` is not an ISO path; use `VM_ISO` for the official Gentoo live ISO path.

The VM guest disk examples use `/dev/vda` because the target is the disposable qcow2 disk inside libvirt. Real hardware workflows must use the explicit disk reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.
