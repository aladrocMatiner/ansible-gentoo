# Manual Escape Hatch Policy

Manual intervention is allowed only as a controlled recovery path when automation cannot safely continue. It must be recorded before resuming so audit evidence and install state remain honest.

## When Manual Intervention Is Allowed

Manual intervention may be used when:

- live ISO networking needs operator inspection,
- a mirror or transient service fails,
- the operator must inspect target state,
- an approved recovery step requires manual verification.

Manual intervention must not bypass destructive safety gates, disk confirmations, bootloader confirmations, secret policy, or OpenSpec review.

## Record A Manual Step

Use the Makefile target:

```sh
make record-manual-step \
  MANUAL_STEP_SUMMARY="Adjusted live ISO network route" \
  MANUAL_STEP_REASON="DHCP route was missing after boot"
```

Optional:

```sh
make record-manual-step \
  MANUAL_STEP_SUMMARY="Reviewed pending Portage config files" \
  MANUAL_STEP_REASON="final-checks reported protected config updates" \
  MANUAL_STEP_NEXT_ACTION="Run make final-checks again before reboot"
```

The target:

- requires an existing install state with `run_id`,
- writes non-secret JSON under `logs/install-runs/<run-id>/manual-steps/`,
- appends a non-secret event to `logs/install-runs/<run-id>/events.jsonl`,
- marks the install state as requiring revalidation,
- mirrors the state update to `logs/install-runs/<run-id>/state.json`,
- does not execute any operator-provided command.

The Makefile exports `MANUAL_STEP_SUMMARY`, `MANUAL_STEP_REASON`, and `MANUAL_STEP_NEXT_ACTION` to the helper script. The script does not receive the note text as command-line arguments from the Makefile target.

## What To Record

Record:

- what changed,
- why automation could not continue,
- what should be revalidated next,
- relevant non-secret observations.

Do not record:

- passwords,
- password hashes,
- private SSH keys,
- API keys,
- tokens,
- private mirror credentials,
- full command transcripts containing secrets.

## Resume Rules

After a manual step:

1. Run `make install-state`.
2. Run `make install-resume-plan`.
3. Fix any reported mismatch or missing evidence.
4. Run `make install-resume` to execute exactly one planner-approved phase.
5. Re-enter destructive confirmations if the next phase is destructive.

State records never satisfy destructive confirmations.
Successful `make install-resume-plan` clears the manual revalidation flag after target facts match the saved checkpoint and no mismatches are reported. `make install-resume` then stops after one phase and requires a fresh `make install-resume-plan` before continuing.

## Audit

`make install-audit` includes recorded manual-step JSON files after secret scanning. Audit bundles do not include secret inputs or arbitrary operator transcripts.

## Failure Modes

- Missing install state: run a Makefile-mediated plan or install phase before recording a manual step.
- Empty summary or reason: rerun with `MANUAL_STEP_SUMMARY` and `MANUAL_STEP_REASON`.
- Secret-like value detected: remove the secret from the note, rotate the exposed secret if necessary, and rerun.
- Resume validation fails: stop and inspect the reported state difference before continuing.
