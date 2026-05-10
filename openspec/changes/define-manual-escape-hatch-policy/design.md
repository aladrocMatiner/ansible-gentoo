# Design: define-manual-escape-hatch-policy

## Allowed Use

Manual intervention may be used when:

- a live ISO network condition cannot be automated safely,
- a package mirror or transient service fails,
- an operator needs to inspect target state,
- an approved recovery step requires manual verification.

Manual intervention must not be used to bypass destructive safety gates.

## Recording Manual Changes

The operator should record:

- what was changed,
- why automation could not continue,
- commands or steps run, without secrets,
- current disk/mount/target state after intervention,
- whether the next step should resume or restart.

## Resume Rules

After manual intervention:

- run config validation,
- run relevant read-only plans/checks,
- compare install-state checkpoint with current state,
- update audit evidence,
- require destructive confirmations again when next step is destructive.

## Makefile Integration

Planned target:

```sh
make record-manual-step
```

If implemented, it must write project-local non-secret notes and must not execute arbitrary operator commands.
