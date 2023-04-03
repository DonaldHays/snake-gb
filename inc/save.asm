IF !DEF(SAVE_INC)
SAVE_INC = 1

sram_root EQU $A000

sram_magic EQU (sram_root)
sram_magic_size EQU $0004

sram_record EQU (sram_magic + sram_magic_size)
sram_record_size EQU $0002

sram_disable EQU $00
sram_enable EQU $0A

sram_enable_reg EQU $0000
sram_bank_number_reg EQU $4000

SECTION "Save", ROM0
magicData:
  db "save"

saveInit:
  call enableSRAM
  ld hl, magicData
  ld de, sram_magic
  ld bc, sram_magic_size
  call memcmp
  jr z, .endErase
  
.erase:
  call eraseSRAM
.endErase:
  call disableSRAM
  
  ret

eraseSRAM:
  call enableSRAM
  
  ld hl, magicData
  ld de, sram_magic
  ld bc, sram_magic_size
  call memcpy
  
  ld a, 0
  ld [sram_record], a
  ld [sram_record + 1], a
  
  call disableSRAM
  ret

enableSRAM:
  ld a, sram_enable
  ld [sram_enable_reg], a
  
  ld a, 0
  ld [sram_bank_number_reg], a
  
  ret

disableSRAM:
  ld a, sram_disable
  ld [sram_enable_reg], a
  ret
  
ENDC
