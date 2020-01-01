; Lamp v1.0
;
; read inport on port 2 and output on 3

        .code

LAMP:   in      A, #$10         ; read button
        out     #$18, A         ; write to lamp
        jump    +LAMP           ; repeat
        
