IF !DEF(RAND_INC)
RAND_INC SET 1

INCLUDE "inc/math.asm"

SECTION "Random Variables", BSS
randomState DS 1

SECTION "Random", HOME
; Seeds the random number generator based on the current value of the timer divider
seedRandom:
  ld a, [gb_timer_divider]
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
