# PDP-13 [pdp13]

A 16-bit minicomputer simulation inspired by DEC, IBM, and other Vintage Computers from the 60s and 70s.

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
- Compatible to TechAge to be able control machines
- Installable macro assembler application `vm16asm` (on your PC) and in-game
- J/OS operating system to be able to boot from drive
- commands like: ls, cat, rm, rm, cd, cp, ...
- Many ASM stdlib and example files

On client side Minetest 5.4 is recommended (font=mono)

This mod is based on vm16, a virtual CPU implemented as Lua library with an outstanding performance.


To be able to use the external `vm16asm` assembler tool in-game,
add 'pdp13' to the list of trusted mods in minetest.conf:

```
secure.trusted_mods = vm16,pdp13
```



### See also:

- Virtual maschine [vm16](https://github.com/joe7575/vm16)
- Macro Assembler [vm16asm](https://github.com/joe7575/vm16asm)



### Manuals

Manuals are on [GitHub](https://github.com/joe7575/pdp13/wiki)
The main manual is currently only available in German, English will follow soon.



### License

Copyright (C) 2019-2021 Joe (iauit@gmx.de)
Code: Licensed under the GNU AGPL version 3 or later. See LICENSE.txt  
Textures: CC BY-SA 3.0  
Sound: 271163__alienxxx__beep-008.wav from freesound.org,  
licensed under the Attribution License.  



### Dependencies

Required: default,tubelib2,techage,vm16,vm16asm



### History

- 2019-12-03  v0.01  * First draft
- 2020-12-05  v0.02  * Restructure completely and adapt to new vm16
- 2020-12-15  v0.03  * Add memory rack, monitor program, ICs and much more
- 2020-12-18  v0.04  * Add UDP like communication mechanism
- 2020-12-20  v0.05  * Add OS ROM chip and exam2
- 2020-12-28  v0.06  * Add terminal, tape drive, hard dirk, and more
- 2021-01-03  v0.07  * Add terminal history buffer, update manual, fix bugs
- 2021-01-07  v0.08  * Add macro asm, OS install process, and many more

