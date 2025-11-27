# Realtek 8852BU Wi-Fi Driver Troubleshooting

## Date
2025-11-25

## Issue
Adapter not probing after DKMS install.

## Steps Taken
- Edited USB ID table in driver source.
- Created firmware symlink: `rtl8852bu.bin → rtl8852bu_fw.bin`.
- Reloaded kernel module via `modprobe`.

## Outcome
Interface registered successfully in `dmesg`.

## Notes
Document reproducible workflow for future deployments.
