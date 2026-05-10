# Change: implement-ansible-partition-apply

## Summary
Implement the first destructive installer step: applying the approved GPT partition layout to an explicitly selected disk.

## Motivation
Read-only planning now defines the intended GPT layout. The installer needs a controlled `make partition` target that writes only the partition table and does not format or mount filesystems.

## Scope
- Add `make partition`.
- Add Ansible playbook and shared `common/partitioning` role.
- Reuse `common/disk_safety`.
- Use the destructive preview capability before accepting confirmation.
- Record install-state checkpoint evidence before and after partitioning.
- Apply GPT layout: 512 MiB EFI system partition, remaining disk root partition.
- Support ext4 and Btrfs root plans with the same partition layout.

## Non-goals
- Do not format filesystems.
- Do not mount.
- Do not install stage3.
- Do not install bootloader.

## Safety Requirements
- Require explicit `INSTALL_DISK`.
- Require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Show disk identity and current partition table before writing.
- Show the exact partition operation preview before accepting confirmation.
- Fail if selected disk or descendants are mounted.
- No default disk and no wildcard matching.

## Acceptance Criteria
- `make partition INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes` partitions only the explicit VM disk.
- Missing confirmation fails before disk writes.
- Missing `INSTALL_DISK` fails before disk writes.
- The role does not format or mount.
- Partition apply records non-secret state/audit evidence.
- `openspec validate implement-ansible-partition-apply --strict` passes.

## Affected Files
- `Makefile`
- `scripts/ansible-partition-apply.sh`
- `ansible/playbooks/partition-apply.yml`
- `ansible/roles/common/partitioning/`
- `docs/`
- `skills/`
