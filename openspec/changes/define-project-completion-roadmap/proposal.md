# Change: define-project-completion-roadmap

## Summary
Define the end-to-end roadmap for completing `gentoo-ai-installer` from the current read-only planning workflow to a reproducible Gentoo basic-console installation.

## Motivation
The project now has safe VM/libvirt testing and read-only Ansible planning through filesystem planning. The remaining work includes the remote/network Ansible control plane, cross-cutting guardrails, destructive disk operations, target mounting, stage3 installation, chroot preparation, Portage configuration, kernel, services, users, GRUB, final checks, orchestration, and VM validation. A roadmap keeps those changes small, ordered, and reviewable.

## Scope
- Document the full remaining implementation sequence.
- Define dependencies between OpenSpec changes.
- Include cross-cutting improvements: Ansible quality standards and gates, host requirements, install configuration schema, config validation, logging/error taxonomy, target baseline, installed time sync, installed SSH, boot kernel command line, download/cache mirror policy, Portage world update policy, install state, destructive preview, audit bundle, stage3 signature policy, Handbook traceability, Btrfs policy, test matrix, first-boot validation, secret policy, real hardware readiness, cleanup/reset, manual escape hatch, install report, and live ISO network bootstrap hardening.
- Separate read-only, semi-dangerous, high-risk, and destructive work.
- Preserve OpenRC/systemd reuse-first Ansible architecture.
- Preserve remote/network Ansible as the primary product path and libvirt as the local validation harness.
- Preserve ext4 and Btrfs support.
- Keep the Makefile as the operator-facing control plane.

## Non-goals
- Do not implement installer logic.
- Do not archive active changes.
- Do not collapse all remaining work into one large change.

## Acceptance Criteria
- A project completion roadmap exists.
- The roadmap lists remaining OpenSpec changes in dependency order.
- The roadmap places cross-cutting guardrails before the destructive workflows that depend on them.
- The roadmap places Ansible quality standards before broad role implementation.
- Destructive changes are clearly identified.
- Documentation tasks are included for all implementation changes.
- `openspec validate define-project-completion-roadmap --strict` passes.

## Affected Files
- `docs/project-completion-roadmap.md`
- `openspec/changes/*`
