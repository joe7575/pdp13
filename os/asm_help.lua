pdp13.AsmHelp = [[## VM16 Instruction Set ##
0000           nop
0802           sys  #2
1200, 0100     jump $100
1600, 0100     call $100
1800           ret
1C00           halt
2001           move A, B
2008           move A, [X]
2009           move A, [Y]
2010, 0123     move A, #$123  ; const
2011, 0123     move A, $123   ; mem
2020           move B, A
2028           move B, [X]    ; mem
2029           move B, [Y]    ; mem
2030, 0123     move B, #$123  ; const
2031, 0123     move B, $123   ; mem
2090, 0123     move X, #$123  ; const
2091, 0123     move X, $123   ; mem
20B0, 0123     move Y, #$123  ; const
20B1, 0123     move Y, $123   ; mem
2401           xchg A, B
2800           inc  A
2820           inc  B
2880           inc  X
28A0           inc  Y
2C00           dec  A
2C20           dec  B
2C80           dec  X
2CA0           dec  Y
3001           add  A, B
3010, 0002     add  A, #2
3011, 0100     add  A, $100  ; mem
3020           add  B, A
3030, 0002     add  B, #2
3031, 0100     add  B, $100  ; mem
3401           sub  A, B
3410, 0003     sub  A, #3
3411, 0100     sub  A, $100  ; mem
3420           sub  B, A
3430, 0003     sub  B, #3
3431, 0100     sub  B, $100  ; mem
3801           mul  A, B
3810, 0004     mul  A, #4
3C01           div  A, B
3C10, 0005     div  A, #5
4001           and  A, B
4010, 0006     and  A, #6
4011, 0100     and  A, $100  ; mem
4401           or   A, B
4410, 0007     or   A, #7
4411, 0100     or   A, $100  ; mem
4801           xor  A, B
4810, 0008     xor  A, #8
4811, 0100     xor  A, $100  ; mem
4C00           not  A
5012, 0002     bnze A, +2
5010, 0100     bnze A, $100  ; mem
5412, FFFE     bze  A, -2
5410, 0100     bze  A, $100  ; mem
5812, FFFC     bpos A, -4
5810, 0100     bpos A, $100  ; mem
5C12, FFFC     bneg A, -4
5C10, 0100     bneg A, $100  ; mem
6010, 0002     in   A, #2
6600, 0003     out  #3, A
]]

pdp13.AsmHelp = pdp13.AsmHelp:gsub(",", "\\,")
pdp13.AsmHelp = pdp13.AsmHelp:gsub("\n", ",")
pdp13.AsmHelp = pdp13.AsmHelp:gsub("%[", "\\%[")
pdp13.AsmHelp = pdp13.AsmHelp:gsub("%]", "\\%]")
