# Design: implement-ansible-partition-apply

## Tooling
Use one reviewed partitioning tool, preferably `sgdisk` or `parted`, through guarded Ansible tasks. The chosen tool must be documented.

## Sequence
1. Run read-only disk detection.
2. Run install and partition plan roles.
3. Run shared destructive safety gates.
4. Wipe only partition table metadata required by the selected partitioning tool.
5. Create GPT partition table.
6. Create ESP and root partitions.
7. Ask the kernel to reread partition table where needed.
8. Re-run read-only disk detection.

## Outputs
The role must print before/after disk layout and preserve logs under `logs/` when logging is implemented.

## Safety
Only `common/partitioning` may run partitioning commands. Init-specific roles must not partition disks.
