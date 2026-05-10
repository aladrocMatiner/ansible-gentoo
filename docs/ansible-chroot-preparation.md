# Ansible Chroot Preparation

`make prepare-chroot` prepares the extracted Gentoo target root for later chroot-based installation tasks.

It does not run Portage, install packages, configure kernel or bootloader, create users, enable services, or run arbitrary commands inside the chroot.

## Required State

Run the previous apply targets first:

```sh
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make stage3-install PROFILE=openrc FILESYSTEM=btrfs
```

For a network target, pass `ANSIBLE_LIVE_HOST=...` and use the same mounted target root.

## Command

```sh
make prepare-chroot PROFILE=openrc FILESYSTEM=btrfs
```

## Behavior

The workflow verifies that `/mnt/gentoo` is mounted and that stage3 marker directories exist. It then prepares the Handbook-aligned pseudo-filesystems under `/mnt/gentoo`:

- `/mnt/gentoo/proc` mounted as `proc`
- `/mnt/gentoo/sys` as recursive bind of `/sys`, then `--make-rslave`
- `/mnt/gentoo/dev` as recursive bind of `/dev`, then `--make-rslave`
- `/mnt/gentoo/dev/pts` via the `/dev` recursive bind
- `/mnt/gentoo/run` as bind of `/run`, then `--make-slave`

Existing correct mounts are validated and left unchanged.

## DNS

The workflow copies the live ISO resolver configuration into `/mnt/gentoo/etc/resolv.conf` with `no_log` enabled for the file content. If a target resolver file already exists, the role creates `/mnt/gentoo/etc/resolv.conf.gentoo-ai-installer.bak` once before managing the active resolver file.

DNS is validated with a read-only command inside the prepared target:

```text
chroot /mnt/gentoo getent hosts distfiles.gentoo.org
```

If DNS fails, the workflow stops before Portage or package operations.

## Safety

The role:

- refuses target roots other than `/mnt/gentoo`,
- refuses target root `/`,
- mounts only under `/mnt/gentoo`,
- validates existing pseudo-filesystem mounts before reusing them,
- prints before/after mount state,
- records non-secret evidence under `logs/install-runs/<run-id>/chroot/`.

## Idempotency

Re-running `make prepare-chroot` should report `changed=0` when all pseudo-filesystem mounts and resolver configuration already match the expected state.

## Recovery

If mount validation fails, stop and inspect `findmnt` output before continuing. Do not unmount broad paths manually unless you have confirmed they are under the intended disposable VM or target root.

If DNS validation fails, verify live ISO DNS first, then inspect `/mnt/gentoo/etc/resolv.conf` and rerun `make prepare-chroot`.
