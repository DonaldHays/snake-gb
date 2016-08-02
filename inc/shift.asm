;*
;* 16-bit Shift & Rotate Macros
;*
;*   Started 9-May-97
;*
;* Initials: JF = Jeff Frohwein, CS = Carsten Sorensen
;*
;* V1.0 - 17-Jul-97 : Original Release - JF
;* V1.1 - 19-Jul-97 : Changed format & added more macros - CS,JF
;* V1.2 - 27-Jul-97 : Modified for new subroutine prefixes - JF
;*
;* Library Macros:
;*
;* sla16 RP,N -
;*   Shift RP (BC,DE, or HL) N times to the left.
;*   Format: C <- 15<-0 <- 0
;*
;* srl16 RP,N -
;*   Shift RP (BC,DE, or HL) N times to the right.
;*   Format: 0 -> 15->0 -> C
;*
;* rl16 RP,N -
;*   Rotate RP (BC,DE, or HL) N times to the left.
;*   Format: +-- C <- 15<-0 <--+
;*           +-----------------+
;*
;* rr16 RP,N -
;*   Rotate RP (BC,DE, or HL) N times to the right.
;*   Format: +--> 15->0 -> C --+
;*           +-----------------+
;*

; If all of these are already defined, don't do it again.

        IF      !DEF(SHIFT_INC)
SHIFT_INC  SET  1

rev_Check_shift_inc: MACRO
;NOTE: REVISION NUMBER CHANGES MUST BE ADDED
;TO SECOND PARAMETER IN FOLLOWING LINE.
        IF      \1 > 1.2      ; <--- PUT REVISION NUMBER HERE
        WARN    "Version \1 or later of 'hardware.inc' is required."
        ENDC
        ENDM

; Shift: C <- 15<-0 <- 0

sla16:  MACRO
__rp    EQUS    STRLWR("\1")
__r1    EQUS    STRSUB("\1",1,1)
__r2    EQUS    STRSUB("\1",2,1)
        IF      (STRCMP("{__rp}","bc")==0) || (STRCMP("{__rp}","de")==0) || (STRCMP("{__rp}","hl")==0)
         REPT    \2
         sla     __r2
         rl      __r1
         ENDR
        ELSE
         FAIL   "Register must be BC, DE or HL"
        ENDC
        PURGE   __rp,__r1,__r2
        ENDM

; Shift: 0 -> 15->0 -> C

srl16:  MACRO
__rp    EQUS    STRLWR("\1")
__r1    EQUS    STRSUB("\1",1,1)
__r2    EQUS    STRSUB("\1",2,1)
        IF      (STRCMP("{__rp}","bc")==0) || (STRCMP("{__rp}","de")==0) || (STRCMP("{__rp}","hl")==0)
         REPT    \2
         srl     __r1
         rr      __r2
         ENDR
        ELSE
         FAIL   "Register must be BC, DE or HL"
        ENDC
        PURGE   __rp,__r1,__r2
        ENDM

; Rotate: +-- C <- 15<-0 <--+
;         +-----------------+

rl16:   MACRO
__rp    EQUS    STRLWR("\1")
__r1    EQUS    STRSUB("\1",1,1)
__r2    EQUS    STRSUB("\1",2,1)
        IF      (STRCMP("{__rp}","bc")==0) || (STRCMP("{__rp}","de")==0) || (STRCMP("{__rp}","hl")==0)
         REPT    \2
         rl      __r2
         rl      __r1
         ENDR
        ELSE
         FAIL   "Register must be BC, DE or HL"
        ENDC
        PURGE   __rp,__r1,__r2
        ENDM

; Rotate: +--> 15->0 -> C --+
;         +-----------------+

rr16:   MACRO
__rp    EQUS    STRLWR("\1")
__r1    EQUS    STRSUB("\1",1,1)
__r2    EQUS    STRSUB("\1",2,1)
        IF      (STRCMP("{__rp}","bc")==0) || (STRCMP("{__rp}","de")==0) || (STRCMP("{__rp}","hl")==0)
         REPT    \2
         rr      __r1
         rr      __r2
         ENDR
        ELSE
         FAIL   "Register must be BC, DE or HL"
        ENDC
        PURGE   __rp,__r1,__r2
        ENDM

        ENDC    ;SHIFT_INC

