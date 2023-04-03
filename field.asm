INCLUDE "img/tiles_background.asm"
INCLUDE "inc/math.asm"
INCLUDE "img/tiles_food.asm"
INCLUDE "img/tiles_title.asm"
INCLUDE "inc/sprites.asm"
INCLUDE "inc/rand.asm"
INCLUDE "inc/debug.asm"
INCLUDE "inc/save.asm"

SECTION "Field Module Variables", WRAM0
FIELD_MODULE_SNAKE_SLOT_COUNT EQU 18*14
FIELD_MODULE_SNAKE_TICK_TIME EQU 16
FIELD_MODULE_FOOD_PER_TICK_INCREASE EQU 15
FIELD_MODULE_FASTEST_TICK_RATE EQU 7

FIELD_MODULE_DIRECTION_DOWN EQU %0001
FIELD_MODULE_DIRECTION_UP EQU %0010
FIELD_MODULE_DIRECTION_RIGHT EQU %0100
FIELD_MODULE_DIRECTION_LEFT EQU %1000

FIELD_MODULE_SPRITE_DATA_OFFSET EQU 32
FIELD_MODULE_FONT_DATA_OFFSET EQU 40

FIELD_MODULE_HEART_SPAWN_COUNT EQU 10
FIELD_MODULE_HEART_DURATION_SECONDS EQU 9

fieldModuleTickTime: DS 1
fieldModuleFoodUntilTickTimeIncrease: DS 1

fieldModuleHeartSpawnCountdown: DS 1
fieldModuleFoodIsHeart: DS 1

fieldModuleSnakeLength: DS 1
fieldModuleSnakeSlots: DS FIELD_MODULE_SNAKE_SLOT_COUNT * 2
fieldModuleSnakeSlotHead: DS 1
fieldModuleSnakeSlotTail: DS 1
fieldModuleSnakeTickTime: DS 1
fieldModuleSnakeNextDirection: DS 1
fieldModuleSnakePreviousDirection: DS 1
fieldModuleOccupiedFlags: DS FIELD_MODULE_SNAKE_SLOT_COUNT

fieldModuleShouldWriteSnakeHead: DS 1
fieldModuleShouldWriteSnakeHeadX: DS 1
fieldModuleShouldWriteSnakeHeadY: DS 1

fieldModuleShouldWriteSnakeTail: DS 1
fieldModuleShouldWriteSnakeTailX: DS 1
fieldModuleShouldWriteSnakeTailY: DS 1
fieldModuleShouldWriteSnakeTailValue: DS 1

fieldModuleHeadCoordinateBufferX: DS 1
fieldModuleHeadCoordinateBufferY: DS 1
fieldModuleNextDirectionBuffer: DS 1

fieldModuleHeartAgeSeconds: DS 1
fieldModuleHeartAgeTicks: DS 1

fieldModuleFoodX: DS 1
fieldModuleFoodY: DS 1
fieldModuleDidHideFood: DS 1
fieldModuleFoodBufferX: DS 1
fieldModuleFoodBufferY: DS 1
fieldModuleFoodTile: DS 1
fieldModuleShouldWriteFoodOAM: DS 1

fieldModuleReleasedPause: DS 1

fieldModuleScore: DS 2
fieldModuleShouldRenderScore: DS 1

SECTION "Field Module", ROM0
fieldModuleScoreText:
  db "SCORE",0
fieldModuleHighScoreText:
  db "RECORD",0
fieldModuleDigitCharacters:
  db "0123456789",0

fieldMap:
  DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DB $03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$05
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$07
  DB $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DB $08,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0A

fieldIndexToXYTable:
INDEX = 0
  REPT 18 * 14
  DB INDEX % 18
  DB INDEX / 18
INDEX = INDEX + 1
  ENDR

; =====
; =====
fieldMain:
  di
  call busyWaitForVBlank

  ld a, 0
  ldh [gb_lcd_ctrl], a ; Disable LCD
  
  ; Say that we haven't released pause button yet
  ld a, 0
  ld [fieldModuleReleasedPause], a
  
  ; Set score to 0
  ld a, 0
  ld [fieldModuleScore], a
  ld [fieldModuleScore + 1], a
  ld [fieldModuleShouldRenderScore], a
  
  loadPalette PALETTE_BDLW, gb_palette_bg
  loadPalette PALETTE_BDLW, gb_palette_obj1
  call fieldLoadBackground
  
  call zeroSpriteOAMMemory
  
  call fieldLoadSpriteData
  
  ; Set food heart state
  ld a, 0
  ld [fieldModuleDidHideFood], a
  
  ld a, FIELD_MODULE_HEART_SPAWN_COUNT + 1
  ld [fieldModuleHeartSpawnCountdown], a
  
  ; Set occupied flags to 0
  ld de, fieldModuleOccupiedFlags
  ld h, 0
  ld bc, FIELD_MODULE_SNAKE_SLOT_COUNT
  call memset
  
  call fieldInitSnake
  
  ld b, 0
  ld c, FIELD_MODULE_SPRITE_DATA_OFFSET
  call setSpriteTile
  
  ld c, 0
  ld b, 0
  call setSpriteFlags
  
  ld a, 0
  ld [fieldModuleFoodX], a
  ld [fieldModuleFoodY], a
  call fieldPlaceFood

  ld c, FIELD_MODULE_FONT_DATA_OFFSET
  call initializeFont
  
  ld hl, fieldModuleHighScoreText
  ld bc, (32 * 0) + 0
  call printString
  
  ld hl, fieldModuleScoreText
  ld bc, (32 * 0) + 15
  call printString
  
  ld a, [fieldModuleDigitCharacters]
  ld e, a
  ld bc, (32 * 1) + 0
  call printCharacter
  
  ld a, [fieldModuleDigitCharacters]
  ld e, a
  ld bc, (32 * 1) + 19
  call printCharacter
  
  ; renderBCD(sram_record, coordinate)
  call enableSRAM
  ld hl, sram_record
  ld bc, (32 * 1) + 0
  call renderBCD
  call disableSRAM

  ; Turn LCD back on
  ld a, GB_LCD_CTRL_BG_ON | GB_LCD_CTRL_TILESET2 | GB_LCD_CTRL_ON | GB_LCD_CTRL_OBJ_ON
  ldh [gb_lcd_ctrl], a

  ; Enable v-blank interrupt
  ld a, GB_INTERRUPT_VBLANK
  ldh [gb_interrupt_enable], a

  ei
.loop:
  call fieldUpdate
  
.vblankLoop:
  halt
  nop
  nop
  ld a, [vblankFlag]
  or a
  jr z, .vblankLoop
  ld a, 0
  ld [vblankFlag], a
  
  call fieldRender
  jr .loop


; =====
; =====
fieldUpdate:
  call fieldAttemptPause
  call fieldUpdateIntendedDirection
  
  ; Age heart
.ageHeart:
  ; if fieldModuleFoodIsHeart == false, break
  ld a, [fieldModuleFoodIsHeart]
  cp a, 1
  jr nz, .endAgeHeart
  
.heartFlicker:
  ; if [fieldModuleHeartAgeSeconds] != 1, break
  ld a, [fieldModuleHeartAgeSeconds]
  cp a, 3
  jr nc, .endHeartFlicker
  
  ld a, [fieldModuleHeartAgeTicks]
  srl a
  srl a
  srl a
  and a, $01
  ld b, a
  ld a, FIELD_MODULE_SPRITE_DATA_OFFSET
  add a, b
  ld [fieldModuleFoodTile], a
  ld a, 1
  ld [fieldModuleShouldWriteFoodOAM], a
.endHeartFlicker:
  
  ; [fieldModuleHeartAgeTicks]--
  ld a, [fieldModuleHeartAgeTicks]
  dec a
  ld [fieldModuleHeartAgeTicks], a
  
  ; if [fieldModuleHeartAgeTicks] != 0, break
  cp a, 0
  jr nz, .endAgeHeart
  
  ; [fieldModuleHeartAgeTicks] = 60
  ld a, 60
  ld [fieldModuleHeartAgeTicks], a
  
  ; [fieldModuleHeartAgeSeconds]--
  ld a, [fieldModuleHeartAgeSeconds]
  dec a
  ld [fieldModuleHeartAgeSeconds], a
  
  ; if [fieldModuleHeartAgeSeconds] != 0, break
  cp a, 0
  jr nz, .endAgeHeart
  
  ; fieldModuleFoodIsHeart = false, write tile
  ld a, 0
  ld [fieldModuleFoodIsHeart], a
  
  ld a, FIELD_MODULE_SPRITE_DATA_OFFSET
  ld [fieldModuleFoodTile], a
  
  ld a, 1
  ld [fieldModuleShouldWriteFoodOAM], a
  
.endAgeHeart:
  
  ; Decrement Timer
  ld a, [fieldModuleSnakeTickTime]
  dec a
  ld [fieldModuleSnakeTickTime], a
  
  ; Return if timer != 0
  cp 0
  ret nz
  
  ; Set timer
  ld a, [fieldModuleTickTime]
  ld [fieldModuleSnakeTickTime], a
  
  ; Will we hit a wall?
  call fieldCheckBorderDeath
  
  ; Load up desired coordinate
  call fieldLoadDesiredCoordinate
  
  ld a, d
  ld [fieldModuleHeadCoordinateBufferX], a
  ld a, e
  ld [fieldModuleHeadCoordinateBufferY], a
  ld a, [fieldModuleSnakeNextDirection]
  ld [fieldModuleNextDirectionBuffer], a
  
.spawnFood:
  ; Will we hit food?
  ld a, [fieldModuleFoodX]
  cp a, d
  jp nz, .endSpawnFood
  
  ld a, [fieldModuleFoodY]
  cp a, e
  jp nz, .endSpawnFood
  
  ; We're eating! Increment score!
  call fieldIncrementScore
  
  call fieldHideFood
  
.checkTooLong:
  ld a, [fieldModuleSnakeLength]
  cp a, FIELD_MODULE_SNAKE_SLOT_COUNT - 1
  jr nz, .endCheckTooLong
  
  ; Scribble the head coordinate
  ld a, 1
  ld [fieldModuleShouldWriteSnakeHead], a
  ld a, [fieldModuleHeadCoordinateBufferX]
  ld [fieldModuleShouldWriteSnakeHeadX], a
  ld a, [fieldModuleHeadCoordinateBufferY]
  ld [fieldModuleShouldWriteSnakeHeadY], a
  
  call gameOver
  
.endCheckTooLong:
  
  ld a, [fieldModuleFoodIsHeart]
  cp a, 1
  jr nz, .endEatHeart
.eatHeart:
  ; Good job eating a heart, have more points!
  call fieldIncrementScore
  call fieldIncrementScore
  call fieldIncrementScore
  call fieldIncrementScore
  call fieldIncrementScore
  
  ; Scribble the head coordinate
  ld a, 1
  ld [fieldModuleShouldWriteSnakeHead], a
  ld a, [fieldModuleHeadCoordinateBufferX]
  ld [fieldModuleShouldWriteSnakeHeadX], a
  ld a, [fieldModuleHeadCoordinateBufferY]
  ld [fieldModuleShouldWriteSnakeHeadY], a
  
  ; Pop 5 tail segments
  ld c, 5
  call popTail
.endEatHeart:
  
.increaseTimer:
  ; check if we've eaten enough food to decrease timer duration
  ld a, [fieldModuleFoodUntilTickTimeIncrease]
  sub a, 1
  ld [fieldModuleFoodUntilTickTimeIncrease], a
  cp 0
  jr nz, .endIncreaseTimer
  
  ; reset food counter
  ld a, FIELD_MODULE_FOOD_PER_TICK_INCREASE
  ld [fieldModuleFoodUntilTickTimeIncrease], a
  
  ; if fieldModuleTickTime == FIELD_MODULE_FASTEST_TICK_RATE, don't increase any more
  ld a, [fieldModuleTickTime]
  cp a, FIELD_MODULE_FASTEST_TICK_RATE
  jr z, .endIncreaseTimer
  
  ; make next time tick faster
  sub a, 1
  ; debug "Set tick rate to %a%"
  ld [fieldModuleTickTime], a
.endIncreaseTimer:
  
.restoreFoodPosition:
  ld a, [fieldModuleDidHideFood]
  cp a, 1
  jr nz, .endRestoreFoodPosition
  
  ld a, 0
  ld [fieldModuleDidHideFood], a
  ld a, [fieldModuleFoodBufferX]
  ld [fieldModuleFoodX], a
  ld a, [fieldModuleFoodBufferY]
  ld [fieldModuleFoodY], a
.endRestoreFoodPosition:
  call fieldPlaceFood
  jr .endPopTail
.endSpawnFood:
  
.popTail:
  ; Pop tail coordinate
  call fieldLoadSnakeTailCoordinate
  push de ; Store old tail
  call fieldPopTailCoordinate
  
  ; Flag to write block to map
  pop de ; Retrieve old tail
  ld a, 1
  ld [fieldModuleShouldWriteSnakeTail], a
  ld a, d
  ld [fieldModuleShouldWriteSnakeTailX], a
  ld a, e
  ld [fieldModuleShouldWriteSnakeTailY], a
  
  call tileAt
  ld a, b
  ld [fieldModuleShouldWriteSnakeTailValue], a
.endPopTail:

.pushHead
  ; Is desired coordinate illegal
  ld a, [fieldModuleHeadCoordinateBufferX]
  ld d, a
  ld a, [fieldModuleHeadCoordinateBufferY]
  ld e, a
  
  call fieldGetOccupiedFlag
  cp 1
  call z, gameOver
  
  ; Push desired coordinate
  ld a, [fieldModuleHeadCoordinateBufferX]
  ld d, a
  ld a, [fieldModuleHeadCoordinateBufferY]
  ld e, a
  
  call fieldPushHeadCoordinate
  
  ; Update previous direction
  ld a, [fieldModuleNextDirectionBuffer]
  ld [fieldModuleSnakePreviousDirection], a
  
  ; Load coordinates new head, flag to write block to map
  call fieldLoadSnakeHeadCoordinate
  ld a, 1
  ld [fieldModuleShouldWriteSnakeHead], a
  ld a, d
  ld [fieldModuleShouldWriteSnakeHeadX], a
  ld a, e
  ld [fieldModuleShouldWriteSnakeHeadY], a
.endPushHead

  ret

; =====
; func fieldIncrementScore()
; =====
fieldIncrementScore:
  ld a, [fieldModuleScore]
  add a, 1
  daa
  ld [fieldModuleScore], a
  ld b, a
  
  ld a, [fieldModuleScore + 1]
  adc a, 0
  daa
  ld [fieldModuleScore + 1], a
  ; debug "score %a%%b%"
  
  ld a, 1
  ld [fieldModuleShouldRenderScore], a
  
  call fieldSaveRecord
  
  ret

; =====
; fieldPause
; =====
fieldAttemptPause:
  ; If we're not holding start right now, set fieldModuleReleasedPause to 1 and exit
  call readJoypad
  ld b, a
  bit GB_JOY_BIT_START, a
  jr nz, .continueAttempt
  
  ld a, 1
  ld [fieldModuleReleasedPause], a
  ret
  
.continueAttempt:
  ; if [fieldModuleReleasedPause] == false, return
  ld a, [fieldModuleReleasedPause]
  cp a, 0
  ret z
  
  ; Set fieldModuleReleasedPause = false
  ld a, 0
  ld [fieldModuleReleasedPause], a
  
.vblankLoop:
  halt
  nop
  nop
  ld a, [vblankFlag]
  or a
  jr z, .vblankLoop
  ld a, 0
  ld [vblankFlag], a
  
  ; If not pressing start, jump to .didReleasePause
  call readJoypad
  ld b, a
  bit GB_JOY_BIT_START, a
  jr z, .didReleasePause
  
  ; We're pressing start, return if we've previously released pause
  ld a, [fieldModuleReleasedPause]
  cp a, 1
  jr z, .exitPause
  
  ; We're pressing start, but we haven't previously released pause, so loop
  jr .vblankLoop
  
.exitPause:
  ld a, 0
  ld [fieldModuleReleasedPause], a
  ret
  
.didReleasePause:
  ; Record that we've released pause, then loop
  ld a, 1
  ld [fieldModuleReleasedPause], a
  
  jr .vblankLoop

; =====
; fieldHideFood
; =====
fieldHideFood:
  ld a, [fieldModuleFoodX]
  ld [fieldModuleFoodBufferX], a
  ld a, [fieldModuleFoodY]
  ld [fieldModuleFoodBufferY], a
  
  ld a, 1
  ld [fieldModuleDidHideFood], a
  
  ld a, 20
  ld [fieldModuleFoodX], a
  ld [fieldModuleFoodY], a
  
  ld a, 1
  ld [fieldModuleShouldWriteFoodOAM], a
  ret

; =====
; fieldPlaceFood
; =====
fieldPlaceFood:
  ; a = random in [0, 255]
  call random

  ; first, fix a to be < FIELD_MODULE_SNAKE_SLOT_COUNT
  ; this logic will very slightly bias b towards the first few indexes  
.checkBigRandomFix:
  cp a, FIELD_MODULE_SNAKE_SLOT_COUNT
  jr z, .doBigRandomFix ; if a == FIELD_MODULE_SNAKE_SLOT_COUNT, do the fix
  jr c, .endBigRandomFix ; if (a - FIELD_MODULE_SNAKE_SLOT_COUNT) has carry (therefore is less than), don't fix
  ; else nc (meaning a > FIELD_MODULE_SNAKE_SLOT_COUNT), in which case doBigRandomFix
  
.doBigRandomFix:
  ; debug "fixing %a% for being too big"
  sub a, FIELD_MODULE_SNAKE_SLOT_COUNT
  
.endBigRandomFix:

  ; b = fixed a
  ld b, a
  
  ; Now, we grab the first sane index
.indexLoop:
.bOverflowFix:
  ; wrap if b overflows
  ld a, b
  cp a, FIELD_MODULE_SNAKE_SLOT_COUNT
  jr nz, .endBOverflowFix
  
  ld b, 0
.endBOverflowFix:

.snakePositionFix:
  ; Don't let food spawn where there's a snake
  
  ; a = occupied flag for current b
  push bc
  ld c, b
  call fieldGetXYForPlayableIndex
  call fieldGetOccupiedFlag
  pop bc
  
  ; if a == 0, don't fix for snake position
  cp a, 0
  jr z, .endSnakePositionFix
  
  ; increment b, start index loop over
  inc b
  jr .indexLoop
.endSnakePositionFix:

.currentPositionFix:
  ; Don't let food spawn at its current position
  
  ; de = x, y for current
  push bc
  ld c, b
  call fieldGetXYForPlayableIndex
  pop bc
  
  ld a, [fieldModuleFoodX]
  cp d
  jr nz, .endCurrentPositionFix
  
  ld a, [fieldModuleFoodY]
  cp e
  jr nz, .endCurrentPositionFix
  
  ; increment b, start index loop over
  inc b
  jr .indexLoop
.endCurrentPositionFix:
.endIndexLoop:
  
  ; b contains our index, let's find field coordinate
  ld c, b
  call fieldGetXYForPlayableIndex
  
  ; store field coordinates
  ld a, d
  ld [fieldModuleFoodX], a
  
  ld a, e
  ld [fieldModuleFoodY], a
  
  ; Figure out food type
  ld b, FIELD_MODULE_SPRITE_DATA_OFFSET
  
  ld a, 0
  ld [fieldModuleFoodIsHeart], a
  ld a, [fieldModuleHeartSpawnCountdown]
  dec a
  ld [fieldModuleHeartSpawnCountdown], a
  cp a, 0
  jr nz, .endSpawnHeart
  
.spawnHeart:
  ld a, 1
  ld [fieldModuleFoodIsHeart], a
  
  ld a, FIELD_MODULE_HEART_SPAWN_COUNT
  ld [fieldModuleHeartSpawnCountdown], a
  
  ld a, FIELD_MODULE_HEART_DURATION_SECONDS
  ld [fieldModuleHeartAgeSeconds], a
  ld a, 60
  ld [fieldModuleHeartAgeTicks], a
  
  ld b, FIELD_MODULE_SPRITE_DATA_OFFSET + 1
.endSpawnHeart:
  
  ld a, b
  ld [fieldModuleFoodTile], a
  
  ld a, 1
  ld [fieldModuleShouldWriteFoodOAM], a
  
  ret

; =====
; =====
fieldCheckBorderDeath:
  ; Load head coordinate into d, e
  call fieldLoadSnakeHeadCoordinate
  
  ; Load desired direction into a
  ld a, [fieldModuleSnakeNextDirection]
.ifUp
  cp a, FIELD_MODULE_DIRECTION_UP
  jr nz, .ifRight
  
  ld a, e
  cp a, 0
  call z, gameOver
  ret
.ifRight
  cp a, FIELD_MODULE_DIRECTION_RIGHT
  jr nz, .ifDown
  
  ld a, d
  cp a, 17
  call z, gameOver
  ret
.ifDown
  cp a, FIELD_MODULE_DIRECTION_DOWN
  jr nz, .elseLeft
  
  ld a, e
  cp a, 13
  call z, gameOver
  ret
.elseLeft
  ld a, d
  cp a, 0
  call z, gameOver
  ret

; =====
; func fieldLoadDesiredCoordinate() -> (d: x, e: y)
; Returns the (x, y) coordinate pair that the head of the snake wants to go to.
; =====
fieldLoadDesiredCoordinate:
  ; Load head coordinate into d, e
  call fieldLoadSnakeHeadCoordinate
  
  ; Load desired direction into a
  ld a, [fieldModuleSnakeNextDirection]
.ifUp
  cp a, FIELD_MODULE_DIRECTION_UP
  jr nz, .ifRight
  
  dec e
  ret
.ifRight
  cp a, FIELD_MODULE_DIRECTION_RIGHT
  jr nz, .ifDown
  
  inc d
  ret
.ifDown
  cp a, FIELD_MODULE_DIRECTION_DOWN
  jr nz, .elseLeft
  
  inc e
  ret
.elseLeft
  dec d
  ret


; =====
; =====
fieldUpdateIntendedDirection:
  call readJoypad
  ld b, a
.testUp:
  bit GB_JOY_BIT_UP, a
  jr z, .testLeft
  
  ld a, [fieldModuleSnakePreviousDirection]
  and (FIELD_MODULE_DIRECTION_DOWN | FIELD_MODULE_DIRECTION_UP)
  jr nz, .testLeft
  
  ld a, FIELD_MODULE_DIRECTION_UP
  ld [fieldModuleSnakeNextDirection], a
  ret
.testLeft:
  ld a, b
  
  bit GB_JOY_BIT_LEFT, a
  jr z, .testDown
  
  ld a, [fieldModuleSnakePreviousDirection]
  and (FIELD_MODULE_DIRECTION_RIGHT | FIELD_MODULE_DIRECTION_LEFT)
  jr nz, .testDown
  
  ld a, FIELD_MODULE_DIRECTION_LEFT
  ld [fieldModuleSnakeNextDirection], a
  ret
.testDown:
  ld a, b
  
  bit GB_JOY_BIT_DOWN, a
  jr z, .testRight
  
  ld a, [fieldModuleSnakePreviousDirection]
  and (FIELD_MODULE_DIRECTION_UP | FIELD_MODULE_DIRECTION_DOWN)
  jr nz, .testRight
  
  ld a, FIELD_MODULE_DIRECTION_DOWN
  ld [fieldModuleSnakeNextDirection], a
  ret
.testRight:
  ld a, b
  
  bit GB_JOY_BIT_RIGHT, a
  ret z
  
  ld a, [fieldModuleSnakePreviousDirection]
  and (FIELD_MODULE_DIRECTION_LEFT | FIELD_MODULE_DIRECTION_RIGHT)
  ret nz
  
  ld a, FIELD_MODULE_DIRECTION_RIGHT
  ld [fieldModuleSnakeNextDirection], a
  ret


; =====
; =====
fieldRender:
  ; Write Tail
.writeTailIf:
  ; if fieldModuleShouldWriteSnakeTail == 1
  ld a, [fieldModuleShouldWriteSnakeTail]
  cp a, 1
  jr nz, .writeTailEndIf
  
  ; fieldWriteBlock(fieldModuleShouldWriteSnakeTailValue, fieldModuleShouldWriteSnakeTailX, fieldModuleShouldWriteSnakeTailY)
  ld a, [fieldModuleShouldWriteSnakeTailX]
  ld d, a
  ld a, [fieldModuleShouldWriteSnakeTailY]
  ld e, a
  ld a, [fieldModuleShouldWriteSnakeTailValue]
  call fieldWriteBlock
  
  ; fieldModuleShouldWriteSnakeTail = 0
  ld a, 0
  ld [fieldModuleShouldWriteSnakeTail], a
.writeTailEndIf:

  ; Write Head
.writeHeadIf:
  ; if fieldModuleShouldWriteSnakeHead == 1
  ld a, [fieldModuleShouldWriteSnakeHead]
  cp a, 1
  jr nz, .writeHeadEndIf
  
  ; fieldWriteBlock(TILE_BK_SNAKE, fieldModuleShouldWriteSnakeHeadX, fieldModuleShouldWriteSnakeHeadY)
  ld a, [fieldModuleShouldWriteSnakeHeadX]
  ld d, a
  ld a, [fieldModuleShouldWriteSnakeHeadY]
  ld e, a
  ld a, TILE_BK_SNAKE
  call fieldWriteBlock
  
  ; fieldModuleShouldWriteSnakeHead = 0
  ld a, 0
  ld [fieldModuleShouldWriteSnakeHead], a
.writeHeadEndIf:
  
  ; Write Food OAM
.writeFoodIf:
  ; if fieldModuleShouldWriteFoodOAM == 1
  ld a, [fieldModuleShouldWriteFoodOAM]
  cp a, 1
  jr nz, .writeFoodEndIf
  
  ld a, [fieldModuleFoodX]
  ld d, a
  ld a, [fieldModuleFoodY]
  ld e, a
  
  ; d = (d + 2) * 8 (offset is 1 inside screen space + 1 for window space)
  inc d
  inc d
  sla d
  sla d
  sla d
  
  ; e = (e + 5) * 8 (offset is 3 inside screen space + 2 for window space)
  ld a, e
  add a, 5
  ld e, a
  sla e
  sla e
  sla e

  ld c, 0
  call setSpriteCoordinate
  
  ld a, [fieldModuleFoodTile]
  ld c, a
  ld b, 0
  call setSpriteTile
  
  ; fieldModuleShouldWriteFoodOAM = 0
  ld a, 0
  ld [fieldModuleShouldWriteFoodOAM], a
.writeFoodEndIf:
.writeScoreIf:
  ; if fieldModuleShouldRenderScore != 1, break
  ld a, [fieldModuleShouldRenderScore]
  cp a, 1
  jr nz, .writeScoreEndIf
  
  ; fieldModuleShouldRenderScore = 0
  ld a, 0
  ld [fieldModuleShouldRenderScore], a
  
  ; renderBCD(fieldModuleScore, coordinate)
  ld hl, fieldModuleScore
  ; a = number of printing digits in fieldModuleScore
  call getBCDLength
  
  ld bc, (32 * 1) + 20
.decrementTileIndexLoop:
  ; if a == 0, break
  cp a, 0
  jr z, .endDecrementTileIndexLoop
  
  ; decrease bc and a, then loop
  dec bc
  dec a
  jr .decrementTileIndexLoop
.endDecrementTileIndexLoop:

  call renderBCD
.writeScoreEndIf:
  
  ret

; =====
; func getBCDLength(hl = number address) -> a = number of digits
; =====
getBCDLength:
  ; Check upper pair first
  inc hl
  
.upperMostSignificant:
  ; if upper 4 of upper pair == 0, check lower 4 of upper pair
  ld a, [hl]
  and a, $F0
  jr z, .upperLeastSignificant
  
  ; Not zero, so it's 4
  dec hl
  ld a, 4
  ret
  
.upperLeastSignificant:
  ; if lower 4 of upper pair == 0, check upper 4 of lower pair
  ld a, [hl]
  and a, $0F
  jr z, .lowerMostSignificant
  
  ; Not zero, so it's 3
  dec hl
  ld a, 3
  ret
  
.lowerMostSignificant:
  ; reduce hl to the lower pair
  dec hl
  
  ; if upper 4 of lower pair == 0, check lower 4 of lower pair
  ld a, [hl]
  and a, $F0
  jr z, .lowerLeastSignificant
  
  ; Not zero, so it's 2
  ld a, 2
  ret
  
.lowerLeastSignificant:
  ; It's 1
  ld a, 1
  ret

; =====
; func renderBCD(hl = number address, bc = tileIndex)
; =====
renderBCD:
  ; d indicates whether or not we're writing characters yet
  ld d, 0
  
  ; Start at most significant part of number
  inc hl
  call renderBCDPair
  
  ; Now render less significant part of number
  dec hl
  call renderBCDPair
  
  ret

; =====
; func renderBCD(hl = number address, bc = tileIndex, d = writeAllDigits)
; destroys e
; increments bc
; sets d to 1 if a digit was written
; =====
renderBCDPair:
  ; if d == 1, writeMostSignificant
  ld a, d
  cp a, 1
  jr z, .writeMostSignificant
  
  ; if ([hl] & $F0) == 0, leastSignificantDigit
  ld a, [hl]
  and a, $F0
  jr z, .leastSignificantDigit

.writeMostSignificant:
  ; a = upper 4 bits of [hl]
  ld a, [hl]
  swap a
  and a, $0F
  
  ; Render BCD digit, preserving hl
  push hl
  call renderBCDDigit
  pop hl
  
  ; Increment tile index
  inc bc
  
.leastSignificantDigit:
  ; if d == 1, writeLeastSignificant
  ld a, d
  cp a, 1
  jr z, .writeLeastSignificant
  
  ; if ([hl] & $0F) == 0, ret
  ld a, [hl]
  and a, $0f
  ret z
  
.writeLeastSignificant:
  ; a = lower 4 bits of [hl]
  ld a, [hl]
  and a, $0F
  
  ; Render BCD digit, preserving hl
  push hl
  call renderBCDDigit
  pop hl
  
  ; Increment tile index
  inc bc
  
  ret

; =====
; func renderBCD(a = digit, bc = tileIndex)
; Destroys a, hl, e
; Sets d to 1
; =====
renderBCDDigit:
  ; hl = address of our "0123456789" ASCII table
  ld hl, fieldModuleDigitCharacters
  
  ; de = a (the digit)
  ld e, a
  ld d, 0
  
  ; hl = address of ASCII table + digit
  add hl, de
  
  ; e = ASCII character
  ld e, [hl]
  
  call printCharacter
  
  ld d, 1
  
  ret

; =====
; func tileAt(d = x, e = y)
; Sets b to the original map value represented at d, e
; =====
tileAt:
  ld hl, fieldMap
  ld bc, 20
  
  ; e += 3
  ld a, e
  add a, 3
  ld e, a
  
  ; d += 1
  ld a, d
  add a, 1
  ld d, a
  
.startYLoop:
  ; if e == 0, break
  ld a, e
  cp a, 0
  jr z, .endYLoop
  
  ; dec e, add 20 to hl
  dec e
  add hl, bc
  
  ; loop
  jr .startYLoop
.endYLoop:
  ld e, d
  ld d, 0
  add hl, de
  
  ld b, [hl]

  ret

; =====
; func fieldPushHeadCoordinate(d = x, e = y)
; Increases the index of fieldModuleSnakeSlotHead (wrapping if necessary), and
; writes (d, e) to the appropriate index of fieldModuleSnakeSlots.
; =====
fieldPushHeadCoordinate:
  ; Increase length
  ld a, [fieldModuleSnakeLength]
  inc a
  ld [fieldModuleSnakeLength], a
  
  ; Set occupied flag
  push de
  ld a, 1
  call fieldSetOccupiedFlag
  pop de

  ; *fieldModuleSnakeSlotHead += 1
  ld hl, fieldModuleSnakeSlotHead
  inc [hl]
  
  ; Wrap if necessary
.beginWrap:
  ld a, [hl]
  cp a, FIELD_MODULE_SNAKE_SLOT_COUNT
  jr nz, .endWrap
  ld [hl], 0
.endWrap:
  
  ; write x, y to fieldModuleSnakeSlots[fieldModuleSnakeSlotHead]
  
  ; bc = *fieldModuleSnakeSlotHead
  ld b, 0
  ld c, [hl]
  
  ; bc *= 2
  sla16 bc, 1
  
  ; Load address of x to hl
  ; hl = fieldModuleSnakeSlots + bc
  ld hl, fieldModuleSnakeSlots
  add hl, bc
  
  ; Write x and y
  ld [hl], d
  inc hl
  ld [hl], e
  
  ret


; =====
; func fieldPopTailCoordinate()
; Increases the index of fieldModuleSnakeSlotTail, wrapping if necessary.
; =====
fieldPopTailCoordinate:
  ; Decrease length
  ld a, [fieldModuleSnakeLength]
  dec a
  ld [fieldModuleSnakeLength], a
  
  ; Write occupied flag
  push de
  ld a, 0
  call fieldSetOccupiedFlag
  pop de

  ; *fieldModuleSnakeSlotTail += 1
  ld hl, fieldModuleSnakeSlotTail
  inc [hl]
  
  ; Wrap if necessary
.beginWrap:
  ld a, [hl]
  cp a, FIELD_MODULE_SNAKE_SLOT_COUNT
  jr nz, .endWrap
  ld [hl], 0
.endWrap:
  ret
  
  
; =====
; func fieldLoadSnakeHeadCoordinate() -> (d: x, e: y)
; Returns the (x, y) coordinate pair that the head of the snake occupies.
; =====
fieldLoadSnakeHeadCoordinate:
  ld hl, fieldModuleSnakeSlotHead
  ld a, [hl]
  ld l, a
  call fieldLoadSnakeCoordinate
  ret


; =====
; =====
fieldLoadSnakeTailCoordinate:
  ld hl, fieldModuleSnakeSlotTail
  ld a, [hl]
  ld l, a
  call fieldLoadSnakeCoordinate
  ret


; =====
; func fieldLoadSnakeCoordinate(l = index) -> (d: x, e: y)
; Returns the (x, y) coordinate pair at `index` in `fieldModuleSnakeSlots`
; dirties: h, l, a
; =====
fieldLoadSnakeCoordinate:
  ; Prepare `hl`, then double it to make offset from fieldModuleSnakeSlots of x
  ld a, 0
  ld h, a
  sla16 hl, 1
  
  ; hl = address of x
  ld de, fieldModuleSnakeSlots
  add hl, de
  
  ; d = x, e = y
  ld d, [hl]
  inc hl
  ld e, [hl]
  ret


; =====
; =====
fieldInitSnake:
  ; Set initial movement direction
  ld a, FIELD_MODULE_DIRECTION_UP
  ld [fieldModuleSnakeNextDirection], a
  
  ld a, FIELD_MODULE_DIRECTION_UP
  ld [fieldModuleSnakePreviousDirection], a
  
  ; Set initial write values
  ld a, 0
  ld [fieldModuleShouldWriteSnakeHead], a
  ld [fieldModuleShouldWriteSnakeTail], a
  
  ; Prepare initial 3 slots
  ld a, 3
  ld [fieldModuleSnakeLength], a
  
  ld a, 0
  ld [fieldModuleSnakeSlotTail], a
  
  ld a, 2
  ld [fieldModuleSnakeSlotHead], a
  
  ; Write values into slots
  ld hl, fieldModuleSnakeSlots
  ld [hl], 9
  inc hl
  ld [hl], 9
  inc hl
  ld [hl], 9
  inc hl
  ld [hl], 8
  inc hl
  ld [hl], 9
  inc hl
  ld [hl], 7
  inc hl
  
  ; Write values into map
  ld a, TILE_BK_SNAKE
  ld d, 9
  ld e, 9
  call fieldWriteBlock
  
  ld a, TILE_BK_SNAKE
  ld d, 9
  ld e, 8
  call fieldWriteBlock
  
  ld a, TILE_BK_SNAKE
  ld d, 9
  ld e, 7
  call fieldWriteBlock
  
  ; Write values into flags
  ld a, 1
  ld d, 9
  ld e, 9
  call fieldSetOccupiedFlag
  
  ld a, 1
  ld d, 9
  ld e, 8
  call fieldSetOccupiedFlag
  
  ld a, 1
  ld d, 9
  ld e, 7
  call fieldSetOccupiedFlag
  
  ; Set timer
  ld a, FIELD_MODULE_SNAKE_TICK_TIME
  ld [fieldModuleTickTime], a
  ld [fieldModuleSnakeTickTime], a
  ld a, FIELD_MODULE_FOOD_PER_TICK_INCREASE
  ld [fieldModuleFoodUntilTickTimeIncrease], a
  
  ret

; =====
; func fieldGetXYForPlayableIndex(c = index) -> (d = x, e = y)
; =====
fieldGetXYForPlayableIndex:
  ; bc = c * 2
  ld a, 0
  sla c
  adc a, 0
  ld b, a
  
  ld hl, fieldIndexToXYTable
  add hl, bc
  
  ld d, [hl]
  inc hl
  ld e, [hl]
  
  ret

; =====
; func fieldGetOccupiedFlagAddress(d = x, e = y) -> (hl = address of occupied flag)
; =====
fieldGetOccupiedFlagAddress:
  ; bc = d
  ld b, 0
  ld c, d
  
  ; h = e * 18
  ld d, 18
  call mul8
  
  ; hl = bc + h
  ld l, h
  ld h, 0
  add hl, bc
  
  ; hl = fieldModuleOccupiedFlags + offset we just computed
  ld de, fieldModuleOccupiedFlags
  add hl, de
  
  ret

; =====
; func fieldGetOccupiedFlag(d = x, e = y) -> (a = flag)
; =====
fieldGetOccupiedFlag:
  ; hl = occupied flag address
  call fieldGetOccupiedFlagAddress
  
  ; Write the value
  ld a, [hl]
  
  ret

; =====
; func fieldSetOccupiedFlag(a = value, d = x, e = y)
; =====
fieldSetOccupiedFlag:
  ; Store flag value
  push af
  
  ; hl = occupied flag address
  call fieldGetOccupiedFlagAddress
  
  ; Retrieve flag value
  pop af
  
  ; Write the value
  ld [hl], a
  
  ret

; =====
; func fieldWriteBlock(a = value, d = x, e = y)
; =====
fieldWriteBlock:
  ; Store block value
  push af
  
  ; Offset d and e to play area start points
  ld a, d
  add a, 1
  ld d, a
  
  ld a, e
  add a, 3
  ld e, a
  
  ; hl = x
  ld h, 0
  ld l, d
  
  ; Add 32 to hl e times.
  ld bc, 32
.loop:
  ; if e == 0 break
  ld a, e
  cp a, 0
  jr z, .loopEnd
  
  ; add 32 to hl
  add hl, bc
  
  ; e--; loop
  dec e
  jr .loop
.loopEnd:
  ; hl = gb_ram_map + offset we just computed
  ld de, gb_ram_map
  add hl, de
  
  ; Retrieve block value
  pop af
  
  ; write the tile
  ld [hl], a
  
  ret


; =====
; =====
fieldLoadSpriteData:
  ld de, (gb_ram_tile + FIELD_MODULE_SPRITE_DATA_OFFSET * 16)
  ld hl, foodTiles
  ld bc, FOOD_TILES_COUNT * 16
  call memcpy
  
  ret

; =====
; =====
fieldLoadBackground:
  ld de, gb_ram_tile
  ld hl, backgroundTiles
  ld bc, BACKGROUND_TILES_COUNT*16
  call memcpy
  
  ld de, gb_ram_map
  ld hl, fieldMap
  ld b, 0
  
.loop:
  ; Break loop if b == 18
  ld a, b
  cp a, 18
  ret z
  
  push bc
    ld bc, 20
    call memcpy
  
    ; de += 12
    push hl
      ld16 hl, de
      ld de, 12
      add hl, de
      ld16 de, hl
    pop hl
  pop bc
  
  inc b
  
  jr .loop

; =====
; func wait(c = number of ticks)
; waits `c` ticks, then returns
; =====
wait:
.loop:
  ld a, c
  cp a, 0
  ret z
  
  dec c
  push bc
  
.vblankLoop:
  halt
  nop
  nop
  ld a, [vblankFlag]
  or a
  jr z, .vblankLoop
  ld a, 0
  ld [vblankFlag], a
  
  call fieldRender
  
  pop bc
  
  jr .loop

; =====
; func popTail(c = number of segments)
; Removes `c` segments from the tail, seizing control of the main loop to do so
; in an animated fashion
; =====
popTail:
  ld b, 0
  
.loop:
  push bc
  call fieldUpdateIntendedDirection
  pop bc
  
  ld a, b
  cp a, 0
  jr z, .endDelay
.delay:
  dec b
  push bc
  jr .vblankLoop
.endDelay:
  ld b, 5
  
  ld a, c
  cp a, 0
  ret z
  
  dec c
  push bc

  ; Pop tail coordinate
  call fieldLoadSnakeTailCoordinate
  push de ; Store old tail
  call fieldPopTailCoordinate
  
  ; Flag to write block to map
  pop de ; Retrieve old tail
  ld a, 1
  ld [fieldModuleShouldWriteSnakeTail], a
  ld a, d
  ld [fieldModuleShouldWriteSnakeTailX], a
  ld a, e
  ld [fieldModuleShouldWriteSnakeTailY], a
  
  call tileAt
  ld a, b
  ld [fieldModuleShouldWriteSnakeTailValue], a
  
.vblankLoop:
  halt
  nop
  nop
  ld a, [vblankFlag]
  or a
  jr z, .vblankLoop
  ld a, 0
  ld [vblankFlag], a
  
  call fieldRender
  
  pop bc
  
  jr .loop
  
; =====
; func gameOver()
; ends the game
; =====
gameOver:
  call fieldSaveRecord
  ld c, 30
  call wait
  ld a, [fieldModuleSnakeLength]
  ld c, a
  call popTail
  ld c, 60
  call wait
  jp main
  
; =====
; func fieldSaveRecord()
; updates the saved record, if the new one is greater
; =====
fieldSaveRecord:
  call enableSRAM
  
  ; If record.msb < current.msb, save
  ld a, [fieldModuleScore + 1]
  ld d, a
  ld a, [sram_record + 1]
  cp a, d
  jr c, .save
  
  ; If record.msb != current.msb, that means it must be greater than, so don't save
  jr nz, .endSave
  
  ; current.msb equals record.msb
  ; if record.lsb < current.lsb, save
  ld a, [fieldModuleScore]
  ld d, a
  ld a, [sram_record]
  cp a, d
  jr c, .save
  
  ; record.lsb >= current.lsb, don't save
  jr .endSave
.save:
  ; Copy the score to SRAM
  ld hl, fieldModuleScore
  ld de, sram_record
  ld bc, 2
  call memcpy
.endSave:
  call disableSRAM
  ret
  