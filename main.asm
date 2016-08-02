INCLUDE "header.asm"
INCLUDE "title.asm"
INCLUDE "field.asm"
INCLUDE "inc/save.asm"

SECTION "Global Flags", BSS
vblankFlag DS 1

SECTION "Main", HOME[$150]
main:
  ld sp, $FFFE        ; Set stack pointer to high RAM
  call saveInit
  jp titleMain

vblank:
  push af
  ld a, 1
  ld [vblankFlag], a
  pop af
  reti
