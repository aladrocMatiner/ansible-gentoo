# Install Audit Bundle

The audit bundle is a local, secret-safe evidence bundle for the current install run. It helps review or debug an installation without manually collecting every role log.

## Target

Generate the bundle through the Makefile:

```sh
make install-audit
```

`make final-checks` and the full `make install`, `make install-openrc`, and `make install-systemd` flows also generate the audit bundle after successful final checks.

## Location

The bundle is written under the current run logs:

```text
logs/install-runs/<run-id>/audit-bundle/
```

It contains:

- `manifest.json`
- `summary.txt`
- `evidence/` with copied non-secret evidence files that exist for the run

The source run id comes from:

```text
var/state/current-install.json
```

Both `logs/` and `var/state/` are ignored by git.

## Evidence Included When Available

The generator copies known evidence files from the run directory:

- install state and event log,
- partition before/after evidence,
- filesystem before/after evidence,
- mount target before/after evidence,
- stage3 verification and extraction evidence,
- chroot preparation evidence,
- Portage baseline evidence,
- hostname/timezone/locale/keymap evidence,
- fstab evidence,
- kernel evidence,
- system package and service evidence,
- user/access evidence,
- bootloader evidence,
- final reboot readiness evidence.

Missing files are listed in `manifest.json`; missing optional evidence does not fail bundle generation.

## Secret Safety

Bundle generation scans state and source evidence before copying. It fails if it detects secret-like keys or values, including:

- password fields,
- API keys,
- access or refresh tokens,
- private key material,
- common token formats.

The bundle must not include plaintext passwords, password hashes, private SSH keys, Codex tokens, API keys, or local credentials.

## Failure Modes

- No state file exists: run a Makefile-mediated install phase first.
- State file has no run id: inspect `var/state/current-install.json`.
- Run directory is missing: the state pointer is stale; rerun a plan or install phase.
- Evidence contains secret-like text: stop and inspect the source evidence before sharing logs.
- Audit path is symlinked or outside `logs/install-runs/`: generation fails closed.

## Recovery

Run:

```sh
make install-state
```

Confirm the run id and last completed phase. If state is stale, remove only the pointer:

```sh
make install-run-clean I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE
```

Then rerun the appropriate plan or validation target to create fresh state before generating a new audit bundle.

After generating the bundle, run `make install-report` for a concise human-readable summary that links to the audit bundle when available.
