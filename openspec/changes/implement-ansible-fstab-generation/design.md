# Design: implement-ansible-fstab-generation

## Data Source
Use `blkid`/Ansible facts after filesystems exist to collect UUIDs.

## ext4
Generate root `/` and `/boot/efi` entries.

## Btrfs
Generate root `subvol=@` and entries for planned subvolumes.

## Validation
Validate all referenced UUIDs exist before writing.

## Handbook Order
The role may run after filesystem creation and target mounting once UUIDs are available. If it runs before kernel or package installation, final checks must still validate fstab after all relevant target state exists. This is an automation ordering choice, not a deviation in final system contents.
