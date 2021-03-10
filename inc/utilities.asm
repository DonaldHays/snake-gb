IF !DEF(UTILITIES_INC)
UTILITIES_INC SET 1

INCLUDE "img/tiles_gray.asm"

SECTION "Utilities", ROM0

busyWaitForVBlank:
  ldh a, [gb_scanline_current]  ; Load the current scanline
  cp 144                        ; 144 - 153 are within vblank
  jr nz, busyWaitForVBlank      ; Loop if != 144
  ret

; a = state of joypad
; - destroys b
readJoypad:
  ; Procedure from http://www.emulatronia.com/doctec/consolas/gameboy/gameboy.txt
  
  ; Read first part of joypad state
  ld a, GB_JOY_SELECT_FIRST_PART
  ld [gb_joy_ctrl], a
  
  ; Read several times to burn cycles waiting for register to update
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  cpl ; Invert so 1=on and 0=off
  and $0f ; Only want 4 least significant bits
  swap a  ; Swap nibbles
  ld b, a ; Store in b
  
  ; Read second part of joypad state
  ld a, GB_JOY_SELECT_SECOND_PART
  ld [gb_joy_ctrl], a
  
  ; Read several times to burn cycles waiting for register to update
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  ld a, [gb_joy_ctrl]
  cpl ; invert
  and $0f ; only 4 least significant bits
  or b ; Merge with b
  
  ret

clearMap:
  ld hl, gb_ram_map ; Load background map address into HL
  ld bc, 32*32      ; Load the number of tiles into BC
clearMapLoop:
  ld a, 0
  ld [hl+], a  ; Put 0 into [HL], then increment HL
  dec bc       ; Reduce counter
  ld a, b      ; Load B into A
  or c         ; Or A (which has B's value) with C. If A|C == 0, we're done
  jr nz, clearMapLoop
  ret

loadGray:
  ld de, gb_ram_tile
  ld hl, grayTiles
  ld bc, GRAY_TILES_COUNT*16
  call memcpy
  ret

ENDC
