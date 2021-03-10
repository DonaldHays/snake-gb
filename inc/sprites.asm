IF !DEF(SPRITES_INC)
SPRITES_INC SET 1

SECTION "Sprites", ROM0

; Sprite OAM exists at gb_ram_obj. There are 40 sprites. Each sprite has 4 bytes
; of data.
; Byte 0: y position
; Byte 1: x position
; Byte 2: tile index
; Byte 3: flag
;   - Bit 7: Priority (1: in front of window & background, 0: just background)
;   - Bit 6: Flip Y
;   - Bit 5: Flip X
;   - Bit 4: Palette Number

; =====
; Sets every byte in OAM memory to 0.
; =====
zeroSpriteOAMMemory:
  ld de, gb_ram_obj
  ld bc, 40 * 4
  ld h, 0
  call memset
  
  ret

; =====
; Sets sprite at c to x coordinate in d and y coordinate in e
; =====
setSpriteCoordinate:
  ; hl = address of sprite OAM for sprite at c
  call addressOfSpriteOAM
  
  ld a, e
  ld [hl+], a
  ld a, d
  ld [hl+], a
  
  ret

; =====
; Sets the flags of sprite at c to b
; =====
setSpriteFlags:
  call addressOfSpriteOAM
  
  inc hl
  inc hl
  inc hl
  
  ld [hl], b
  
  ret

; =====
; Sets sprite at b to tile index at c
; =====
setSpriteTile:
  ; hl = address of sprite OAM for sprite at b
  push bc
  ld c, b
  call addressOfSpriteOAM
  pop bc
  
  ; hl += 2 to set it to the tile index address
  inc hl
  inc hl
  
  ld [hl], c
  
  ret

; =====
; Sets hl to the address of the sprite OAM with index c
; =====
addressOfSpriteOAM:
  ld hl, gb_ram_obj
  
  ; b = 0
  ld b, 0
  
  ; c = c * 4
  sla c
  sla c
  
  ; hl += bc (in other words: gb_ram_obj + 4 * c)
  add hl, bc
  ret

ENDC
