# PDP-13 [pdp13]

A 16-bit minicomputer simulation for Minetest, inspired by DEC, IBM, and
other Vintage Computers from the 60s and 70s.

![screenshot](https://github.com/joe7575/pdp13/blob/main/screenshot.png)

A computer simulation that will take you back to the beginnings of programming:

- Machine code
- Telewriter
- Punch tapes
- Terminals
- Hard disks
- Tape drives
- Monitor program with assembler / disassembler (in-game)
- RAM and ROM chips to expand the computer
- Communication possibilities between computers
- Output possibilities like color lamp and 7-segment node
- Compatible to TechAge and TechPack (tubelib) to be able control machines
- J/OS operating system to be able to boot from drives
- commands like: ls, cat, mkdir, rm, cd, cp, disk, format, ...
- Macro assembler application
- Many ASM stdlib and example files

On client side Minetest 5.4 is recommended (font=mono)

This mod is based on [vm16](https://github.com/joe7575/vm16),
a virtual CPU implemented as Lua library with an outstanding performance.



### Manuals

Manuals are on [GitHub](https://github.com/joe7575/pdp13/wiki)
The main manual is available in German and English.
The English translation was made by Flitzpiepe



### License

Copyright (C) 2019-2022 Joe (iauit@gmx.de)
Code: Licensed under the GNU AGPL version 3 or later. See LICENSE.txt  
Textures: CC BY-SA 3.0  
Sound: `271163__alienxxx__beep-008.wav` from freesound.org,  
licensed under the Attribution License.  



### Dependencies

Required: default, vm16, techage or tubelib



### History

- 2019-12-03  v0.01  * First draft
- 2020-12-05  v0.02  * Restructure completely and adapt to new vm16
- 2020-12-15  v0.03  * Add memory rack, monitor program, ICs and much more
- 2020-12-18  v0.04  * Add UDP like communication mechanism
- 2020-12-20  v0.05  * Add OS ROM chip and exam2
- 2020-12-28  v0.06  * Add terminal, tape drive, hard dirk, and more
- 2021-01-03  v0.07  * Add terminal history buffer, update manual, fix bugs
- 2021-01-07  v0.08  * Add macro asm, OS install process, and many more
- 2021-01-13  v0.09  * Add new macro asm, add dir level for drive 'h'
- 2021-08-28  v0.10  * Change exe/asm search paths, add new commands to J/OS v0.2
- 2021-08-31  v0.11  * Prepared for TechPack
- 2021-09-05  v0.12  * Rework the exams
- 2022-05-07  v0.13  * Adapt to vm16 v3.5

