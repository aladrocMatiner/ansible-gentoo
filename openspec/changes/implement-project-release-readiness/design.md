# Design: implement-project-release-readiness

## Checklist
Validate docs, OpenSpec state, Makefile help, safety warnings, ignored artifacts, secret checks, Ansible checks, and VM test evidence.

Implemented target:

```sh
make release-check
```

The target writes `logs/release-readiness/latest.json` and does not run installer tasks, boot VMs, publish artifacts, or archive OpenSpec changes automatically.

## Release Notes
Summarize supported profiles, filesystems, VM requirements, live ISO assumptions, and known limitations.

## Archives
Archive completed OpenSpec changes only after implementation and validation are complete. The release readiness report lists active complete changes so the operator can archive them deliberately through the approved OpenSpec workflow.
