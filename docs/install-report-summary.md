# Install Report Summary

`make install-report` generates a concise, secret-safe Markdown summary for the current install run.

The report is for operator review after planning, install phases, final checks, or audit generation. It does not run Ansible against the target and does not modify the live ISO or installed system.

## Run

```sh
make install-report
```

The target reads:

```text
var/state/current-install.json
logs/install-runs/<run-id>/
```

It writes and prints:

```text
logs/install-runs/<run-id>/install-report.md
```

`var/state/` and `logs/` are ignored by git.

## Contents

The report includes available non-secret data for:

- run id, last completed phase, and completed phase list
- profile, filesystem, boot mode, target mount, EFI mount, and install disk
- hostname, timezone, locale, and keymap
- root and EFI UUIDs, fstab entries, and Btrfs root command-line policy
- kernel artifacts, module directories, GRUB status, and boot command line
- NetworkManager, time sync, optional SSH status, admin user, groups, and sudo policy
- Portage profile, flags, repo sync status, world update status, and pending config updates
- final-check status, first-boot status when available, audit bundle path, and next action guidance

Missing evidence is reported as `unavailable`; the report must not invent hostname, UUID, user, or validation facts.

## Secret Safety

The generator rejects state or evidence containing secret-like fields or values. It must not print:

- plaintext passwords
- password hashes
- API keys
- access or refresh tokens
- private SSH keys
- local credentials

Password-hash usage is reported only as boolean status, such as whether a hash was applied.

## Failure Modes

- No state file: run a Makefile-mediated plan or install phase first.
- Missing run directory: inspect `make install-state`; the state pointer may be stale.
- Secret-like evidence: stop and inspect the source role evidence before sharing logs.
- Missing audit bundle: run `make install-audit` if audit linkage is needed.

## Recovery

Check current state first:

```sh
make install-state
```

If state is stale, remove only the pointer:

```sh
make install-run-clean I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE
```

Then rerun the relevant plan, validation, or install phase and generate a fresh report.
