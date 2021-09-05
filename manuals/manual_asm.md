# Macro Assembler Manual



## Introduction

The Assembler `asm`  is used to translate `.asm` files  into `.h16` files, which can be directly executed on the PDP-13. This assembler is available in-game on the PDP-13, but a similar program can be installed on your PC (Linux, macOS, and Windows). See https://github.com/joe7575/vm16asm). 

Example "7segment.asm":

```assembly
; 7 segment demo v1.0
; PDP13 7-Segment on port #0

    move A, #$80    ; 'value' command
    move B, #00     ; value in B

loop:
    add  B, #01
    and  B, #$0F    ; values from 0 to 15
    out  #00, A
    nop
    nop
    jump loop
```

`.h16` file "7segment.h16":

```
:20000010000000D
:80000002010008020300000303000014030000F
:6000800660000000000000012000004
:00000FF
```

The `.h16` file includes also address information so that the code can be located to the predefined VM16 memory address.

If installed properly, you can directly type:

```
asm <asm-file>
```

For example:

```
asm test.asm
```

The Assembler will generate a `.lst` file in addition. This file can be used to verify that the translation went as expected.



## Assembler Syntax

The assembler differentiates between upper and lower case, all instructions have to be in lower case, CPU register (A - Y) always in upper case. Each instruction has to be placed in a separate line. Leading blanks are accepted.

```assembly
    move  A B
    add   A, #10
    jump #$1000
```

The assembler allows blank and/or a comma separators between the first and the second operator.

The `#` sign in `move A, #10` signals an absolute value (immediate addressing). This value is loaded into the register. In contrast to `move A, 0`, where the value from memory address `0` is loaded into the register.

The `$` sign signals a hexadecimal value. `$400` is equal to `1024`.

`#` and `$` signs also can be combined, like in `jump #$1000`



## Comments

Comments are used for addition documentation, or to disable some lines of code. Every character behind the `;` sign is a comment and is ignored by the assembler:

```assembly
; this is a comment
    move    A, 0    ; this is also a comment
```

Due to Minetest limitations, only the ASCII character set shall be used



## Labels

Labels allow to implement a jump/call/branch to a dedicated position without knowing the correct memory address. 
In the example above the instruction `out  #8, A` will be executed after the instruction `jump loop`.  

For labels  the characters 'A' - 'Z', 'a' - 'z',  '_' and '0' - '9' are allowed ('0' - '9' not as first character) following by the ':' sign.

Labels can be used in two different ways:

- `jump  loop` is translated into an instruction with an absolute memory address
- `jump +loop` is translated into an instruction with a relative address (+/- some addresses), so that the code can be relocated to a different memory address

To be able to distinguish between local and external labels, the `.asm` file name is used as prefix for labels. Lets say, you want to call a function from your file `example.asm`:

- `call foo` will jump to a file local label
- `call example.foo` will also jump to a file local label
- `call strcpy.foo` will jump to a label in the file `strcpy.asm`

If you want to call the external function `strcpy`, the following alternatives are valid:

- `call strcpy` is the short form
- `call strcpy.start` is the normal form 

Both variants will point to the beginning of the code segment or the the explicit label `start` in `strcpy.asm`

See also chapter "Include Instruction".



## Assembler Directives

Assembler directives are used to distinguish between code, data, and text segments, or to specify a memory address for following code blocks.

Here a (not useful) example:

```assembly
        .org $100
        .code
start:  move    A, #text1
        sys     #0
        halt
        
        .data
var1:	100
var2:   $2123

        .org $200
        .text
text1:  "Hello World\0"
```

- `.org` defines the memory start address for the locater. In the example above, the code will start at address 100 (hex).
- `.code` marks the start of a code block and is optional at the beginning of a program (code is default).
- `.data` marks the start of a data/variables block.  Variables have a name and a start value. Variables have always the size of one word.
- `.text` marks the start of a text block with "..." strings. `\0` is equal to the value zero and has always be used to terminate the string.
- `.ctext` marks the start of a compressed text block (two characters in one word). This is not used in the example above but allows a better packaging of constant strings. It depends on your output device, if  compressed strings are supported.

The assembler output for the example above looks like:

```
VM16 ASSEMBLER v1.3.0 (c) 2019-2021 by Joe
 - read t/demo2.asm...
 - generate code...
 - write demo2.h16...
 - write demo2.lst...
Code start address: $0100
Last used address:  $020B
Code size [words]:  $0012
```



## Symbols

To make you program better readable, the assembler supports constant or symbol definitions.

```assembly
INP_BUFF = $40      ; 64 chars
OUT_BUFF = $80      ; 64 chars

START:  move    X, #INP_BUFF
        move    Y, #OUT_BUFF
```

For symbols  the characters 'A' - 'Z', 'a' - 'z',  '_' and '0' - '9' are allowed ('0' - '9' not as first character).

Of course, symbols must be defined before they can be used.



## Include Instruction

To bind several `.asm` files to one larger project, the assembler allows to import other files with the `$include` instruction:

```assembly
$include "itoa.asm"
```

This allows to use code or call functions from other files by means of globally valid labels (see chap. Labels).

The imported code will be directly inserted at the position of the `$include` line.  Therefore, put all your `$include` lines at the and of your `.asm` file.



## Macros

Using macros is a way of ensuring modular programming in assembly language.

- A macro is a sequence of instructions, assigned by a name and could be used anywhere in the program.
- Macros are defined with `$macro` and `$endmacro` directives.

The Syntax for macro definition:

```
$macro macro_name  num_of_params
   <instructions>
$endmacro
```

`num_of_params` specifies the number parameters, `macro_name` specifies the name of the macro.

The macro is invoked by using the macro name, along with the necessary parameters. 

When you need to use some sequence of instructions many  times in a program, you can put those instructions in a macro and use it instead of writing the instructions all the time.

Here an extract from `install.asm` (J/OS installation program):

```assembly
$macro read_tape 2          ; <------- start of the marco definition block
    move  A, #%1            ; <------- use of param 1
    sys   #$14
    call  input
    move  A, #$500
    sys   #5
    move  B, #%2            ; <------- use of param 2
    bze   A, error
    move  B, #15
    call  sleep
$endmacro                   ; <------- end of the marco definition block

start:
    sys   #$10
    move  A, #HELLO
    sys   #$14
    move  A, #NEWLINE
    sys   #$14

    read_tape TAPE1 1       ; <------- use the macro
    read_tape TAPE2 2       ; <------- use the macro
    read_tape TAPE3 3       ; <------- use the macro

    move  A, #READY
    sys   #$14

    halt
```

