# Design: implement-destructive-command-preview

## Preview Scope

Preview output must be precise enough for an operator to answer: "What will change if I continue?"

For disk and filesystem actions, preview must include:

- selected disk path,
- model, serial when available, size,
- current partition table,
- current filesystems and mountpoints,
- planned partition or filesystem operations,
- target paths and UUID expectations when available,
- required confirmation variables.

For bootloader actions, preview must include:

- target disk,
- EFI mountpoint,
- current EFI boot entries before modification,
- planned GRUB install/configuration step names.

For users and passwords, preview must include:

- username,
- privilege escalation method,
- whether password hash or SSH keys are expected,
- a clear statement that secrets are not printed.

## Execution Model

Preview must be read-only. It may call existing read-only Ansible roles and state collectors, but must not call destructive commands or Ansible modules.

Destructive apply targets should run preview immediately before confirmation or embed the same preview data in the confirmation prompt.

## Makefile Integration

Planned targets may include:

- `make destructive-preview`
- `make partition-preview`
- `make format-preview`
- `make bootloader-preview`

Actual target names must be documented when implemented.

## Safety

Preview is not approval. A successful preview must not set `I_UNDERSTAND_THIS_WIPES_DISK=yes`, `confirm_wipe_disk=yes`, or any equivalent confirmation.
