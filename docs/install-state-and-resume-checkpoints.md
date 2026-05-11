# Install State and Resume Checkpoints

Install state records non-secret checkpoints for Makefile-mediated installer phases. It helps an operator inspect progress and validate whether a target still matches the last recorded state before continuing.

State never acts as destructive confirmation. Later destructive targets still require their normal Makefile variables, such as `I_UNDERSTAND_THIS_WIPES_DISK=yes` or `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

## Files

The current state pointer is:

```text
var/state/current-install.json
```

Each run also writes:

```text
logs/install-runs/<run-id>/state.json
logs/install-runs/<run-id>/events.jsonl
```

Both `var/state/` and `logs/` are ignored by git. State files must not contain passwords, API keys, tokens, private keys, password hashes, or local credentials.

## Make Targets

Show the current state summary:

```sh
make install-state
```

Validate the current live ISO target against the saved resume checkpoint:

```sh
make install-resume-plan
```

For a network target, pass the same SSH target variables used by other Ansible workflows:

```sh
make install-resume-plan ANSIBLE_LIVE_HOST=192.0.2.10
```

Delete only the current state pointer after confirmation:

```sh
make install-run-clean I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE
```

`install-run-clean` does not delete `logs/install-runs/`.

## What Is Recorded

The shared `common/install_state` role records:

- run id,
- last completed phase,
- completed phase list,
- profile,
- filesystem,
- boot mode,
- target root and EFI mount paths,
- selected install disk when known,
- per-phase evidence paths,
- the latest disk safety checkpoint when available.

The disk safety checkpoint includes selected disk identity, descendant partition state, filesystem types, UUIDs, and mountpoints.

## Resume Validation

`make install-resume-plan` is read-only for the live ISO target. It:

- reads `var/state/current-install.json`,
- rejects state files with secret-like fields or values,
- extracts the saved disk, profile, filesystem, and checkpoint,
- connects to the same kind of live ISO target over SSH,
- runs `common/disk_detection`,
- runs `common/disk_safety` with resume checkpoint comparison enabled,
- fails if current disk, partition, filesystem UUID, mount, profile, or filesystem facts differ from state.

The target allows mounted descendants during comparison because a partially completed install may have `/mnt/gentoo` mounted. Those mounts must match the checkpoint.

## Failure Modes

- No state file exists: run a Makefile-mediated plan or install phase first.
- State contains secret-like keys or values: stop and inspect how the state was generated.
- Resume checkpoint is missing: run a phase that includes `common/disk_safety`, such as `partition-plan`, `mount-plan`, `filesystem-plan`, `partition`, `format`, `mount-target`, `generate-fstab`, `install-bootloader`, or the full install flow.
- Disk identity differs: stop and run `make detect-disks` against the same target.
- UUID or mount state differs: inspect mounts and filesystem state before continuing.
- Profile or filesystem differs: resume with the recorded values or start a new clean run.

## Recovery

Use `make install-state` first. If the state is stale but logs are still useful, remove only the pointer:

```sh
make install-run-clean I_UNDERSTAND_DELETE_INSTALL_STATE=DELETE
```

Then rerun the appropriate read-only plan target against the current live ISO target to create a fresh state checkpoint. Do not manually edit state to bypass failed safety checks.

For broader cleanup, use `make cleanup-plan` first and follow `docs/cleanup-reset-policy.md`. Audit bundles are preserved by default by the cleanup policy.
