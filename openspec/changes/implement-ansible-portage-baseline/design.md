# Design: implement-ansible-portage-baseline

## Handbook Alignment
Follow the Gentoo AMD64 Handbook base system and Portage configuration flow. The project should automate conservative defaults first and avoid turning the first install into a tuning exercise.

## make.conf
Use conservative `COMMON_FLAGS`, documented `MAKEOPTS`, and minimal global USE flags.

Do not add aggressive CPU-specific optimization in v1. Any `ACCEPT_LICENSE`, `USE`, or mirror policy must be explicit in variables and documentation.

## Profile
OpenRC and systemd profile names are variant data. Shared tasks select the profile from variables.

## Repos
Sync official Gentoo repository. Do not enable GURU in the installed system by default.

Codex may be installed temporarily in the live ISO through npm, GURU, or binary release workflows, but Codex does not need to be installed into the final Gentoo system in v1.
