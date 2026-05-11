# Portage World Update Policy

The v1 installer configures a minimal reproducible Gentoo system. It must not turn the first install into an unbounded full system upgrade.

## Policy

For v1:

- The Gentoo repository sync runs through `make configure-portage`.
- Required baseline packages are installed explicitly by later package targets.
- A broad `emerge -avuDN @world` does not run by default.
- Pending protected config updates are reported, not merged unattended.
- Portage sync, world-update status, and config-update status are recorded as evidence.

## Rationale

Skipping a broad default `@world` update keeps the first installer:

- faster,
- more reproducible,
- closer to the selected stage3 baseline,
- less likely to fail because of unrelated package churn.

A later OpenSpec change may add an optional world-update target with explicit operator controls.

## Makefile Workflows

Portage baseline:

```sh
make configure-portage PROFILE=openrc
make configure-portage PROFILE=systemd
```

Package installation:

```sh
make install-system-packages PROFILE=openrc
make install-system-packages PROFILE=systemd
```

Validation and reporting:

```sh
make final-checks ADMIN_USER=<admin-user>
make install-report
```

## Config File Updates

Protected config updates such as `._cfg*` files must be detected and reported. v1 must not run unattended `etc-update`, `dispatch-conf`, or equivalent merge automation that could overwrite local configuration.

If pending config updates are reported, the operator must review them before considering the system release-ready.

## Evidence

Evidence should include:

- repository sync status,
- selected Portage profile,
- `make.conf` baseline,
- whether a world update was skipped or run,
- pending config-update list,
- package installation status.

## Failure Modes

- Repository sync fails: verify network, DNS, time, and mirror policy, then rerun `make configure-portage`.
- Package install fails due pending config updates: inspect the reported files before rerunning package or final-check targets.
- A change adds broad world update by default: reject it unless an approved OpenSpec change defines that behavior and operator controls.

## Recovery

Rerun Makefile-mediated Portage targets after fixing network, mirror, or config-update issues. Do not manually merge config updates in a way that leaves install evidence inconsistent.
