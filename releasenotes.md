# Release Notes for pdp13 /JOS

## v0.10.00 (2021-08-28)

### Additions
- disk command added (sys #$63)
- format command added (sys #$64)

### Changes
- search paths for ASM files and executables has changed
- the tape size is doubled
- Changed J/OS version to 0.2
- TTL for HDDs in chests added (files will be deleted after 40 days)


## v0.09.00 (2021-01-13)

- Add Lua macro assembler (will replace Python vm16asm tool)
- Divide filesystem in front- and backend
- Add one level of directories to drive 'h'

### Removals

### Changes
- Move sys cmnd `get current drive` from `$74` to `$5E`

### Fixes


