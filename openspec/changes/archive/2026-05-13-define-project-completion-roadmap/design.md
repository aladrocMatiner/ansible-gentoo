# Design: define-project-completion-roadmap

## Roadmap Order
0. Ansible quality standards and gates.
1. Local live ISO Ansible control plane.
2. Live ISO network bootstrap hardening.
3. Supported host requirements.
4. Install configuration schema.
5. Config validation report.
6. Logging and error taxonomy.
7. Target system baseline.
8. Installed time sync policy.
9. Installed SSH policy.
10. Boot kernel command line policy.
11. Download cache and mirror policy.
12. Portage world update policy.
13. Install state and resume checkpoints.
14. Install audit bundle.
15. Secret input policy.
16. Handbook traceability report.
17. Destructive command preview.
18. Shared destructive safety gates.
19. Partition apply.
20. Btrfs subvolume and snapshot policy.
21. Filesystem apply.
22. Mount target.
23. Stage3 signature policy.
24. Stage3 install.
25. Chroot preparation.
26. Portage baseline.
27. Locale, timezone, and hostname.
28. fstab generation.
29. Kernel install.
30. System packages and services.
31. Users and access.
32. GRUB bootloader.
33. Final checks and reboot readiness.
34. Basic console install orchestration.
35. Libvirt install test matrix.
36. First boot validation.
37. Libvirt end-to-end validation.
38. Manual escape hatch policy.
39. Install report summary.
40. Real hardware readiness policy.
41. Cleanup and reset policy.
42. Project release readiness.

## Risk Boundaries
- Read-only: planning, checks, reports, state inspection, audit generation, traceability, matrix planning, validation.
- Semi-dangerous: mounting target filesystems, extracting stage3, chroot preparation.
- High-risk: users, passwords, services, bootloader state.
- Destructive: partitioning, formatting, wiping filesystems.

## Reuse Rules
Every Ansible implementation change must first identify shared behavior. OpenRC/systemd differences must stay in variant variables or init-specific roles.

## Ansible Quality Rules
Every Ansible implementation change must pass or explicitly account for the project quality gate: FQCN modules, named tasks, module-first design, guarded command-like tasks, idempotency review, check-mode behavior, diff safety, secret redaction, host-key scope, syntax checks, and ansible-lint when available.

## Documentation Rules
Each implementation change must update `docs/`, relevant `skills/`, `Makefile` help, and OpenSpec tasks.
