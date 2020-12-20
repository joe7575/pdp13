        nop
        sys  #2
        jump $100
        call $100
        ret
        halt
        move A, B
        move A, [X]
        move A, [Y]
        move A, #$123
        move A, $123
        move B, A
        move B, [X]
        move B, [Y]
        move B, #$123
        move B, $123
        move X, #$123
        move X, $123
        move Y, #$123
        move Y, $123
        xchg A, B
        inc  A
        inc  B
        inc  X
        inc  Y
        dec  A
        dec  B
        dec  X
        dec  Y
        add  A, B
        add  A, #2
        add  A, $100
        add  B, A
        add  B, #2
        add  B, $100
        sub  A, B
        sub  A, #3
        sub  A, $100
        sub  B, A
        sub  B, #3
        sub  B, $100
        mul  A, B
        mul  A, #4
        div  A, B
        div  A, #5
        and  A, B
        and  A, #6
        and  A, $100
        or   A, B
        or   A, #7
        or   A, $100
        xor  A, B
        xor  A, #8
        xor  A, $100
        not  A
        bnze A, +2
        bnze A, $100
        bze  A, -2
        bze  A, $100
        bpos A, -4
        bpos A, $100
        bneg A, -4
        bneg A, $100
        in   A, #2
        out  #3, A
