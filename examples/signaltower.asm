; SmartLine Signal Tower/TA4 Signal Tower demo v1.0
; Grinder on port #0
; Signal Tower on port #1


   out  #0, #5 ; send 'state' to grinder
   in   A, #0  ; read response

   ; if off then send off
   skne A, #10
   out  #1, #00 ; force 2 byte instr.
   ; if running then send green
   skne A, #5
   out  #1, #2
   ; if standby then send amber
   skne A, #7
   out  #1, #3
   ; if blocked then send red
   skne A, #6
   out  #1, #4

   jump #0  ; start again
