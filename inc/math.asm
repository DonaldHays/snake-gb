IF !DEF(MATH_INC)
MATH_INC SET 1

SECTION "Math", HOME

; func mul8(d, e) -> h 
; Multiplies d by e, storing in h
mul8:
  ld h, 0
  ld l, e
.loop:
  ; if l == 0, return
  ld a, l
  or a ; when (a == 0), ((a || a) == 0)
  ret z
  
  ; if l.bit0 == 0, skipMath
  bit 0, l
  jr z, .skipMath
  
  ; h = h + d
  ld a, h
  add d
  ld h, a
  
.skipMath:

  ; l = l >> 1, d = d << 1
  srl l
  sla d
  
  jr .loop
  
ENDC
