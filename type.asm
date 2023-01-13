; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

.op "PUSH","N","9$1 73 8$1 73"
.op "POP","N","60 72 A$1 F0 B$1"
.op "CALL","W","D4 H1 L1"
.op "RTN","","D5"
.op "MOV","NR","9$2 B$1 8$2 A$1"
.op "MOV","NW","F8 H2 B$1 F8 L2 A$1"

#include   bios.inc
#include   kernel.inc

           org     2000h
begin:     br      start
           eever
           db      'Written by Michael H. Riley',0

start:
           lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    good                ; jump if filename given
           sep     scall               ; otherwise display usage message
           dw      o_inmsg
           db      'Usage: type filename',10,13,0
           ldi     0ah
           sep     sret                ; and return to os
good:      ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    main                ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           ldi     0ch
           sep     sret                ; and return to os
main:      ldi     0                   ; clear out skip character
           phi     r9       
           ldi     23                  ; 23 lines before pausing
           plo     r9
mainlp:    ldi     0                   ; want to read 16 bytes
           phi     rc
           ldi     16
           plo     rc 
           ldi     high buffer         ; buffer to retrieve data
           phi     rf
           ldi     low buffer
           plo     rf
           sep     scall               ; read the header
           dw      o_read
           glo     rc                  ; check for zero bytes read
           lbz     done                ; jump if so
           ldi     high buffer         ; buffer to retrieve data
           phi     r8
           ldi     low buffer
           plo     r8
linelp:    lda     r8                  ; get next byte
           stxd                        ; save a copy
           sep     scall 
           dw      o_type
           irx                         ; recover character
           ghi     r9                  ; get skip character
           lbz     cont                ; continue on if no skip character
           sm                          ; check if this is skip character
           lbz     skipped             ; jump if skipped
cont:      ldx                         ; get character to check for eol
           smi     10                  ; check for lf (0ah)
           lbnz    chk_cr              ; if not lf check for cr  
           ldi     13                  ; skip next char if cr  (eol: lf,cr)    
           phi     r9              
           lbr     newline             ; process new line
chk_cr:    smi     3                   ; check for cr (0dh - 0ah = 3)
           lbnz    linelp2             ; jump if not cr
           ldi     10                  ; skip next char if lf (eol: cr,lf)
           phi     r9        
newline:   dec     r9                  ; decrement line count
           glo     r9                  ; see if full page
           lbnz    linelp2             ; jump if not
           call    o_inmsg             ; display more message
           db      10,'-MORE-',0
           call    o_readkey           ; check keys
           smi     3                   ; check for <CTRL><C>
           lbz     done                ; exit if <ESC> is pressed
           call    o_inmsg             ; display cr/lf
           db      10,13,0
           ldi     23                  ; reset line count
           plo     r9
skipped:   ldi     0
           phi     r9           
linelp2:   dec     rc                  ; decrement read count
           glo     rc                  ; see if done
           lbnz    linelp              ; loop back if not
           lbr     mainlp              ; and loop back til done

done:      sep     scall               ; close the file
           dw      o_close
           ldi     0
           sep     sret                ; return to os




errmsg:    db      'File not found',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

.suppress

buffer:    ds      20
cbuffer:   ds      80
dta:       ds      512

           end     begin
