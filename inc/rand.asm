IF !DEF(RAND_INC)
RAND_INC = 1

INCLUDE "inc/math.asm"

SECTION "Random Variables", WRAM0
randomState: DS 1

SECTION "Random", ROM0
; Seeds the random number generator based on the current value of the timer divider
seedRandom:
  ldh a, [gb_timer_divider]
  ld [randomState], a
  ret

; Returns a random number in A
random:
  ; a = *randomState * 169
  ld a, [randomState]
  ld d, a
  ld e, 169
  call mul8
  ld a, h
  
  ; a = a + 151
  add a, 151
  
  ; *randomState = a
  ld [randomState], a
  
  ret

ENDC
