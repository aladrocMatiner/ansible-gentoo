# Release Readiness

`make release-check` is the first usable milestone gate. It checks repository hygiene, documentation coverage, safety guardrails, OpenSpec validation, and implemented Ansible syntax without running installer tasks.

## Run

```sh
make release-check
```

The target writes:

```text
logs/release-readiness/latest.json
```

The report is local and ignored by git.

## Checks

The release check runs:

- `make help`,
- `git diff --check`,
- `scripts/secret-check.sh`,
- `scripts/ansible-check.sh`,
- `openspec validate --all --strict`,
- required documentation file checks,
- tracked artifact checks for ISO, qcow2, firmware, logs, state, and secret paths,
- OpenSpec active-change status reporting.

It does not:

- run destructive install targets,
- boot a VM,
- connect to a live ISO,
- publish release artifacts,
- archive OpenSpec changes automatically.

## Guardrail Status

The report records whether the following guardrails are documented and implemented through Makefile targets:

- audit bundle,
- secret input policy,
- Handbook traceability,
- libvirt matrix planning and disposable E2E matrix validation,
- first-boot validation,
- install report,
- real hardware readiness,
- cleanup/reset,
- supported host requirements,
- manual escape hatch.

## Artifact Policy

The repository must not track:

- `gentoo.iso` or ISO files,
- qcow2 disks,
- OVMF/NVRAM `.fd` files,
- logs,
- state files,
- local secret files,
- `.env` files other than `.env.example`.

Local generated files belong under ignored directories such as `logs/`, `var/state/`, `var/libvirt/`, `var/qemu/`, or `/tmp/gentoo-ai-installer/`.

## OpenSpec Archive Policy

Completed OpenSpec changes may remain active until the operator intentionally archives them with the approved OpenSpec archive workflow. Release readiness reports active complete changes so they can be archived deliberately rather than hidden by automation.

## Failure Modes

- Missing required doc: add or update the file before release.
- Secret check failure: remove the secret from tracked or unignored files and rotate it if it was real.
- Tracked artifact failure: untrack the artifact and keep it under an ignored local path.
- OpenSpec validation failure: fix the failing change/spec before release.
- Ansible check failure: fix syntax or lint errors before release.

## Recovery

Fix the reported issue, then rerun:

```sh
make release-check
```

Do not publish or tag a release while the result is `FAIL`.
