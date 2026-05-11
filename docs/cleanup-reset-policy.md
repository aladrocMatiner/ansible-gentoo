# Cleanup And Reset Policy

Cleanup is Makefile-mediated and scoped. It deletes only generated project artifacts after explicit confirmation.

The VM cleanup path remains `make vm-clean`; it stops and undefines only the configured project-owned libvirt domain, including active transient domains left by installed-disk first-boot validation, then removes generated VM artifacts plus the selected case state pointer under `var/state/libvirt/<case-domain>/current-install.json`. The cleanup targets in this document handle non-VM-specific installer state, run logs, audit bundles, and stage3 cache files.

`STAGE3_CACHE_DIR` is a live-target path in the normal SSH-driven installer flow. Stage3 cache cleanup therefore runs through Ansible against the live ISO target.

Cache boundaries follow `docs/download-cache-and-mirror-policy.md`.

## Targets

Preview cleanup candidates without deleting:

```sh
make cleanup-plan CLEAN_SCOPE=state
make cleanup-plan CLEAN_SCOPE=logs
make cleanup-plan CLEAN_SCOPE=audit
make cleanup-plan CLEAN_SCOPE=stage3-cache
make cleanup-plan CLEAN_SCOPE=test-run
```

Delete after confirmation:

```sh
make clean-state I_UNDERSTAND_CLEANUP_DELETE=DELETE
make clean-logs I_UNDERSTAND_CLEANUP_DELETE=DELETE
make clean-audit I_UNDERSTAND_CLEANUP_DELETE=DELETE
make clean-stage3-cache I_UNDERSTAND_CLEANUP_DELETE=DELETE
make reset-test-run I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

For logs or audit from a specific run:

```sh
make clean-logs CLEAN_RUN_ID=<run-id> I_UNDERSTAND_CLEANUP_DELETE=DELETE
make clean-audit CLEAN_RUN_ID=<run-id> I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

If `CLEAN_RUN_ID` is unset, cleanup uses the run id in `var/state/current-install.json`.

## Scopes

- `state`: deletes only the configured `INSTALL_STATE_FILE`, normally `var/state/current-install.json`.
- `logs`: deletes non-audit files and phase directories under `logs/install-runs/<run-id>/`.
- `audit`: deletes only `logs/install-runs/<run-id>/audit-bundle/`.
- `stage3-cache`: deletes target-local `STAGE3_CACHE_DIR` over Ansible only when it is under `/tmp/gentoo-ai-installer/`.
- `test-run`: deletes the configured state file and non-audit logs for the selected run.

`make vm-clean` is separate from these scopes. It stops only the selected project VM domain if it is active, deletes only the selected VM case artifacts and that case's current state pointer, and does not delete historical `logs/install-runs/` evidence or audit bundles.

Audit bundles are preserved by default. They are deleted only by `make clean-audit` or another explicit `audit` scope.

## Safety Rules

Cleanup refuses:

- paths outside approved roots,
- parent traversal,
- symlinked cleanup paths or symlinked ancestors,
- host block devices,
- arbitrary user-provided paths,
- broad recursive deletion from the project root.

Every delete target requires:

```text
I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

`make cleanup-plan` is read-only and should be run before any cleanup target.

## Failure Modes

- Missing confirmation: rerun with `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- Missing run id: pass `CLEAN_RUN_ID=<run-id>` or regenerate install state.
- Unsafe `STAGE3_CACHE_DIR`: use the default target-local `/tmp/gentoo-ai-installer/stage3`.
- Symlinked artifact path: remove the symlink manually only after inspecting it; cleanup will not follow it.

## Recovery

If cleanup was too broad, use the preserved audit bundle when available. If audit was intentionally deleted, rerun the relevant install or validation phase to regenerate evidence before sharing results.
