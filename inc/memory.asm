IF !DEF(MEMORY_INC)
MEMORY_INC SET 1

SECTION "Memory", ROM0

; func memcpy(de=destinationAddress, hl=sourceAddress, bc=length)
; Copies `bc` bytes from `hl` to `de`
memcpy:
  ld a, b     ; Return if bc == 0
  or c
  ret z
  ld a, [hl+] ; Load a source byte into a, incrementing hl
  ld [de], a  ; Put into destination
  inc de      ; Increment destination
  dec bc      ; Reduce counter
  jr memcpy

; func memset(de=destinationAddress, h=value, bc=length)
; Writes `h` `bc` times starting from `de`
memset:
  ld a, b     ; Return if bc == 0
  or c
  ret z
  ld a, h     ; Load byte into a
  ld [de], a  ; Put into destination
  inc de      ; Increment destination
  dec bc      ; Reduce counter
  jr memset

; func memcmp(de=first address, hl=second address, bc=length) -> a = 0 if equal
; Compares `bc` bytes between `de` and `hl`.
; `a` will be equal if `de` and `hl` point to `bc` bytes of identical data, or non-zero otherwise
memcmp:
  ; return if bc == 0
  ld a, b
  or c
  ret z
  
  ; a = [de] - [hl]
  ld a, [de]
  sub a, [hl]
  ; if a != 0, return
  ret nz
  
  ; de++, hl++, bc--, loop
  inc de
  inc hl
  dec bc
  jr memcmp

; ld16 r1, r2
; Copies `r2` into `r1`
; - requires: `r1` and `r2` must both be one of "bc", "de", or "hl"
ld16: MACRO
__a EQUS STRLWR("\1")
__b EQUS STRLWR("\2")
__a1 EQUS STRSUB("\1", 1, 1)
__a2 EQUS STRSUB("\1", 2, 1)
__b1 EQUS STRSUB("\2", 1, 1)
__b2 EQUS STRSUB("\2", 2, 1)
  IF ((STRCMP("{__a}","bc")==0) || (STRCMP("{__a}","de")==0) || (STRCMP("{__a}","hl")==0)) && ((STRCMP("{__b}","bc")==0) || (STRCMP("{__b}","de")==0) || (STRCMP("{__b}","hl")==0))
    ld __a1, __b1
    ld __a2, __b2
  ELSE
    FAIL "Registers must be BC, DE, or HL"
  ENDC
  PURGE __a, __b, __a1, __a2, __b1, __b2
ENDM

ENDC