INCLUDE "inc/hardware.asm"
INCLUDE "inc/memory.asm"
INCLUDE "inc/strings.asm"
INCLUDE "inc/utilities.asm"
INCLUDE "inc/palettes.asm"
INCLUDE "inc/save.asm"

SECTION "Title Module Variables", WRAM0
titleModuleState: DS 1
titleModuleFadeTimer: DS 1
titleModuleFadeState: DS 1
titleModuleFadePalettes: DS 4

TITLE_MODULE_STATE_FADING_IN EQU 1
TITLE_MODULE_STATE_AWAITING_INPUT EQU 2
TITLE_MODULE_STATE_FADING_OUT EQU 3
TITLE_MODULE_STATE_DONE EQU 4

FADE_TIMER_DURATION EQU 5

SECTION "Title Module", ROM0
pressStartText:
  db "PRESS  START",0
urlText:
  db "DONALDHAYS.COM",0

titleMain:
  call seedRandom
  
  di
  call busyWaitForVBlank
  
  ld a, 0
  ldh [gb_lcd_ctrl], a ; Disable LCD
  
  call loadGray
  
  ld c, 1
  call initializeFont
  
  call titleLoadTiles
  
  call clearMap
  
  call titleDrawLogo
  
  ld hl, pressStartText
  ld bc, (32 * 12) + 4
  call printString
  
  ld hl, urlText
  ld bc, (32 * 16) + 3
  call printString
  
  call initializeFadeIn
  
  ; Turn LCD back on
  ld a, GB_LCD_CTRL_BG_ON | GB_LCD_CTRL_TILESET2 | GB_LCD_CTRL_ON
  ldh [gb_lcd_ctrl], a
  
  ; Enable v-blank interrupt
  ld a, GB_INTERRUPT_VBLANK
  ldh [gb_interrupt_enable], a
  
  ei

.loop:
  call titleUpdate
  ; Increment random value for randomness
  call random

  halt
  nop

  ld a, [titleModuleState]
  cp TITLE_MODULE_STATE_FADING_IN
  call z, fadeCycle
  cp TITLE_MODULE_STATE_FADING_OUT
  call z, fadeCycle
  
  ld a, [titleModuleState]
  cp TITLE_MODULE_STATE_DONE
  jp nz, .loop
  
  jp fieldMain

; func titleUpdate()
; Ticks the title module
titleUpdate:
  ld a, [titleModuleState]
  cp TITLE_MODULE_STATE_AWAITING_INPUT
  ret nz
  
  call readJoypad
  ld b, a
.eraseSRAM:
  cp a, (GB_JOY_DOWN | GB_JOY_SELECT | GB_JOY_B)
  jr nz, .endEraseSRAM
  
  call eraseSRAM
  jp main
  
.endEraseSRAM:
  
  ; Check for start
  ld a, b
  and a, (GB_JOY_START | GB_JOY_A)
  ret z
  
  call initializeFadeOut
  ret

titleLoadTiles:
  ld bc, TITLE_TILES_COUNT * 16
  ld hl, titleTiles
  ld de, gb_ram_tile + ($40 * 16)
  call memcpy
  ret
  
titleDrawLogo:
  ; yeah these are some pretty horribly hardcoded magic numbers, I just want to
  ; get this title logo quickly thrown together XD
  ld b, 7           ; logo height in tiles
  ld c, 14          ; logo width in tiles
  ld a, $40         ; starting vram tile index
  ld de, 32 - 14    ; offset after each row
  ld hl, $9843      ; start address
.outerTitleLoop
.titleLoop
  ld [hli], a
  inc a
  dec c
  jr nz, .titleLoop
  
  ld c, 14
  add hl, de
  dec b
  jr nz, .outerTitleLoop
  
  ret
  
; func initializeFadeIn()
; Sets up state for a fade in
initializeFadeIn:
  loadPalette PALETTE_WWWW, gb_palette_bg

  ld a, FADE_TIMER_DURATION
  ld [titleModuleFadeTimer], a

  ld a, 0
  ld [titleModuleFadeState], a

  ld a, TITLE_MODULE_STATE_FADING_IN
  ld [titleModuleState], a
  
  ld a, PALETTE_WWWW
  ld [titleModuleFadePalettes], a
  ld a, PALETTE_LWWW
  ld [titleModuleFadePalettes + 1], a
  ld a, PALETTE_DLWW
  ld [titleModuleFadePalettes + 2], a
  ld a, PALETTE_BDLW
  ld [titleModuleFadePalettes + 3], a
  
  ret

; func initializeFadeOut()
; Sets up state for a fade out
initializeFadeOut:
  ld a, FADE_TIMER_DURATION
  ld [titleModuleFadeTimer], a
  
  ld a, 0
  ld [titleModuleFadeState], a
  
  ld a, TITLE_MODULE_STATE_FADING_OUT
  ld [titleModuleState], a
  
  ld a, PALETTE_BDLW
  ld [titleModuleFadePalettes], a
  ld a, PALETTE_DLWW
  ld [titleModuleFadePalettes + 1], a
  ld a, PALETTE_LWWW
  ld [titleModuleFadePalettes + 2], a
  ld a, PALETTE_WWWW
  ld [titleModuleFadePalettes + 3], a
  
  ret

; func fadeCycle()
; Adjusts a fade
fadeCycle:
  ; Decrement Timer
  ld a, [titleModuleFadeTimer]
  dec a
  ld [titleModuleFadeTimer], a
  
  ; Return if timer != 0
  cp 0
  ret nz
  
  ; Timer reached zero, reset to duration
  ld a, FADE_TIMER_DURATION
  ld [titleModuleFadeTimer], a
  
  ; Increment State
  ld a, [titleModuleFadeState]
  inc a
  ld [titleModuleFadeState], a
  
fadeSwitch1:
  cp 1
  jr nz, fadeSwitch2
  loadPalette [titleModuleFadePalettes + 1], gb_palette_bg
  ret
fadeSwitch2:
  cp 2
  jr nz, fadeSwitch3
  loadPalette [titleModuleFadePalettes + 2], gb_palette_bg
  ret
fadeSwitch3:
  loadPalette [titleModuleFadePalettes + 3], gb_palette_bg
  ld a, [titleModuleState]
  cp TITLE_MODULE_STATE_FADING_IN
  jr nz, fadeSwitchIfFadingOut
fadeSwitchIfFadingIn:
  ld a, TITLE_MODULE_STATE_AWAITING_INPUT
  ld [titleModuleState], a
  ret
fadeSwitchIfFadingOut:
  ld a, TITLE_MODULE_STATE_DONE
  ld [titleModuleState], a
  ret