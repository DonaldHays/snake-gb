IF !DEF(STRINGS_INC)
STRINGS_INC = 1

include "img/tiles_font.asm"
include "inc/memory.asm"
include "inc/shift.asm"

SECTION "Strings Variables", WRAM0
loadedFontMapRAMIndex: DS 1

SECTION "Strings", ROM0

; func initializeFont(b=offset)
initializeFont:
  ; Store offset in loadedFontMapRAMIndex
  ld a, c
  ld [loadedFontMapRAMIndex], a
  
  ; Set `b` to 0 so `bc` = offset
  ld b, 0
  
  ; Multiply `bc` by 16 to get Tile RAM offset
  sla16 bc, 4
  
  ; de = gb_ram_tile + tile RAM offset
  ld hl, gb_ram_tile
  add hl, bc
  ld d, h
  ld e, l
  
  ; Load tiles into VRAM
  ld hl, fontTiles
  ld bc, FONT_TILES_COUNT*16
  call memcpy
  ret

; func printCharacter(e=character, bc=tile index)
; destroys a, d, e, hl
printCharacter:
  ; Set `d` to 0 so `de` = character
  ld d, 0
  
  ; Subtract 33 from `e` because our font begins with `!` at 0
  ld a, e
  sub 33
  ld e, a
  
  ; a (tile number) = loadedFontMapRAMIndex + `e` (character index)
  ld a, [loadedFontMapRAMIndex]
  add a, e
  
  ; `hl` = Map RAM address + tile index
  ld hl, gb_ram_map
  add hl, bc
  
  ; Put tile number in MAP RAM address
  ld [hl], a
  
  ret

; func printString(hl=string address, bc=tile origin)
printString:
  ; `e` = character from string
  ld a, [hl+]
  ld e, a
  
  ; break if `e` == 0 (end of string)
  ld a, 0
  cp e
  ret z
  
  ; save hl, call printCharacter, restore hl
  push hl
  call printCharacter
  pop hl
  
  ; Increment tile origin and loop
  inc bc
  jr printString

ENDC
