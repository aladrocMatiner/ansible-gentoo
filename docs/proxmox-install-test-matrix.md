# Proxmox Install Test Matrix

The Proxmox matrix validates the reusable SSH-driven Ansible installer on disposable Proxmox VMs. It does not define a separate installer path and does not build a custom ISO.

The workflow boots the official Gentoo live ISO from a Proxmox ISO volume, configures temporary live ISO SSH through the Proxmox serial console, runs the existing Ansible installer over SSH, and shuts down the VM after a passing install.

## Current Lab Defaults

These defaults match the current Proxmox validation environment:

| Variable | Default |
| --- | --- |
| `PROXMOX_HOST` | `100.64.60.211` |
| `PROXMOX_NODE` | `pve-node10` |
| `PROXMOX_STORAGE` | `ceph_low_prio` |
| `PROXMOX_BRIDGE` | `vmbr0` |
| `PROXMOX_VLAN` | `1070` |
| `PROXMOX_ISO` | `local:iso/install-amd64-minimal-20260510T170106Z.iso` |
| `PROXMOX_VMID_BASE` | `73000` |
| `PROXMOX_IP_BASE` | `10.64.70.99` |
| `PROXMOX_GATEWAY` | `10.64.70.1` |
| `PROXMOX_DISK_SIZE` | `80G` |
| `PROXMOX_RAM` | `16384` |
| `PROXMOX_CPUS` | `4` |
| `PROXMOX_MATRIX_PARALLEL` | `4` |
| `ENABLE_QEMU_GUEST_AGENT` | `yes` for Proxmox E2E wrapper defaults |

The IP range starts at `10.64.70.99` so the 12 cases occupy `10.64.70.99-110`, within the requested `10.64.70.90-110` range.

## Matrix Cases

Run:

```sh
make proxmox-list-cases
```

The implemented matrix is:

| VMID | IP | Case | VM name |
| --- | --- | --- | --- |
| `73000` | `10.64.70.99` | `amd64-openrc-ext4` | `gentoo-test-amd64-openrc-ext4` |
| `73001` | `10.64.70.100` | `amd64-openrc-btrfs` | `gentoo-test-amd64-openrc-btrfs` |
| `73002` | `10.64.70.101` | `amd64-systemd-ext4` | `gentoo-test-amd64-systemd-ext4` |
| `73003` | `10.64.70.102` | `amd64-systemd-btrfs` | `gentoo-test-amd64-systemd-btrfs` |
| `73004` | `10.64.70.103` | `amd64-openrc-ext4-hardened` | `gentoo-test-amd64-openrc-ext4-hardened` |
| `73005` | `10.64.70.104` | `amd64-openrc-btrfs-hardened` | `gentoo-test-amd64-openrc-btrfs-hardened` |
| `73006` | `10.64.70.105` | `amd64-systemd-ext4-hardened` | `gentoo-test-amd64-systemd-ext4-hardened` |
| `73007` | `10.64.70.106` | `amd64-systemd-btrfs-hardened` | `gentoo-test-amd64-systemd-btrfs-hardened` |
| `73008` | `10.64.70.107` | `amd64-openrc-ext4-musl` | `gentoo-test-amd64-openrc-ext4-musl` |
| `73009` | `10.64.70.108` | `amd64-openrc-btrfs-musl` | `gentoo-test-amd64-openrc-btrfs-musl` |
| `73010` | `10.64.70.109` | `amd64-systemd-ext4-musl` | `gentoo-test-amd64-systemd-ext4-musl` |
| `73011` | `10.64.70.110` | `amd64-systemd-btrfs-musl` | `gentoo-test-amd64-systemd-btrfs-musl` |

`VM_TEST_IMAGE_NAME=<label>` may insert a conservative label after `gentoo-test`. It is only a generated VM/artifact label, not an ISO path or package selector.

## Create VMs

Check the Proxmox environment:

```sh
make proxmox-check
```

Create all matrix VMs:

```sh
make proxmox-vm-create-all
```

Create one case:

```sh
make proxmox-vm-create PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
```

The script refuses unrelated existing VMIDs unless they carry the project ownership marker and expected generated VM name.

## Run The Matrix

Run the full matrix only on disposable Proxmox VMs:

```sh
ADMIN_USER=testadmin \
ENABLE_SSH=yes \
ADMIN_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
ADMIN_SUDO_NOPASSWD=yes \
ENABLE_QEMU_GUEST_AGENT=yes \
INSTALL_DISK=/dev/sda \
I_UNDERSTAND_THIS_WIPES_DISK=yes \
I_UNDERSTAND_BOOTLOADER_CHANGES=yes \
I_UNDERSTAND_CLEANUP_DELETE=DELETE \
PROXMOX_MATRIX_PARALLEL=4 \
make proxmox-e2e-matrix
```

The current Proxmox SCSI setup exposes the VM disk as `/dev/sda` inside the live ISO. `INSTALL_DISK` remains explicit and must be verified for other Proxmox hardware models.

Proxmox E2E validation installs and enables `app-emulation/qemu-guest-agent` by default through `ENABLE_QEMU_GUEST_AGENT=yes`. For OpenRC this enables `qemu-guest-agent`; for systemd it enables `qemu-guest-agent.service`. VM creation also enables the Proxmox guest-agent channel on each project-owned VM so the installed service can report state back to Proxmox after first boot.

## Evidence

Single-case results are written under:

```text
logs/proxmox-e2e/<timestamp>-<case>/result.json
logs/proxmox-e2e/<timestamp>-<case>/install.log
```

Matrix summary is written under:

```text
logs/proxmox-e2e-matrix/<timestamp>/matrix-e2e.json
```

Each install also writes normal installer evidence under `logs/install-runs/` and state under `var/state/proxmox/<vm-name>/`.

## Safety

- Proxmox targets operate only through `make`.
- Proxmox VMs are disposable validation targets.
- E2E install requires explicit `INSTALL_DISK`, wipe confirmation, and bootloader confirmation.
- Cleanup requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- Cleanup and shutdown require the expected project ownership marker.
- The reusable Ansible roles must not depend on Proxmox VMIDs, Proxmox storage, VLAN, or generated IPs.
