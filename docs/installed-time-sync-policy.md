# Installed Time Synchronization Policy

The live ISO preflight checks the temporary installer clock before downloads and signature checks. The installed Gentoo target also needs its own time synchronization policy after reboot.

## Policy

For v1:

- `PROFILE=openrc` uses `net-misc/chrony` and enables `chronyd` through OpenRC.
- `PROFILE=systemd` uses `systemd-timesyncd.service` through systemd.
- Time-sync package and service names are variant data; shared Ansible roles must not duplicate OpenRC and systemd task bodies except for genuinely init-specific service enablement.

## Makefile Workflows

Time-sync setup is part of:

```sh
make install-system-packages PROFILE=openrc
make install-system-packages PROFILE=systemd
```

Time-sync validation is part of:

```sh
make final-checks ADMIN_USER=<admin-user>
make vm-validate-first-boot ADMIN_USER=<admin-user>
make install-report
```

## OpenRC

OpenRC installations must:

- install `net-misc/chrony`,
- enable `chronyd` with OpenRC logic,
- validate service status without calling `systemctl`.

## systemd

systemd installations must:

- use `systemd-timesyncd.service`,
- enable it with systemd logic,
- rely on journald/systemd conventions where appropriate,
- validate service status without calling `rc-update` or `rc-service`.

## Validation

Final checks must report whether the expected time-sync service is enabled or available for the selected profile. First-boot validation should report runtime synchronization status where practical.

The install report must summarize available time-sync evidence and report missing evidence as `unavailable` instead of inventing state.

## Failure Modes

- OpenRC service missing: rerun `make install-system-packages PROFILE=openrc` and verify `net-misc/chrony` installed successfully.
- systemd service missing: verify the selected stage3/profile is systemd and rerun `make install-system-packages PROFILE=systemd`.
- Wrong service manager command used: reject the change; OpenRC must use OpenRC tooling and systemd must use systemd tooling.
- First-boot time sync unavailable: check networking and the selected time-sync service after boot.

## Recovery

Use Makefile targets to repair package/service state. Do not manually enable a different time-sync implementation unless an OpenSpec change adds that policy.
