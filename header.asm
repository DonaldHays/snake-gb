INCLUDE "inc/hardware.asm"

SECTION "Restart $00", HOME[$00]
  jp $100

SECTION "Restart $08", HOME[$08]
  jp $100

SECTION "Restart $10", HOME[$10]
  jp $100

SECTION "Restart $18", HOME[$18]
  jp $100

SECTION "Restart $20", HOME[$20]
  jp $100

SECTION "Restart $28", HOME[$28]
  jp $100

SECTION "Restart $30", HOME[$30]
  jp $100

SECTION "Restart $38", HOME[$38]
  jp $100

SECTION "V-Blank Interrupt", HOME[$40]
  jp vblank

SECTION "Status Interrupt", HOME[$48]
  reti

SECTION "Timer Interrupt", HOME[$50]
  reti

SECTION "Serial Data Interrupt", HOME[$58]
  reti

SECTION "Joypad Interrupt", HOME[$60]
  reti

SECTION "Header Padding", HOME[$68]
  DS $98

SECTION "Entrypoint", HOME[$100]
  nop
  jp main

SECTION "Nintendo Logo", HOME[$104]
  NINTENDO_LOGO ; Defined in hardware.inc

SECTION "Title", HOME[$134]
  ; Title must be 11 upper-case characters. Pad with $00.
  DB "SNAKE",0,0,0,0,0,0
  
SECTION "Product Code", HOME[$13F]
  ; Leave blank.
  DB 0,0,0,0

SECTION "Game Boy Color Mode", HOME[$143]
  DB BOOT_GBC_UNSUPPORTED

SECTION "Licensee Code", HOME[$144]
  DB "DH"

SECTION "Super Game Boy Mode", HOME[$146]
  DB BOOT_SGB_UNSUPPORTED

SECTION "Cartridge Type", HOME[$147]
  DB BOOT_CART_ROM_RAM_BATTERY

SECTION "ROM Size", HOME[$148]
  DB BOOT_ROM_32K

SECTION "RAM Size", HOME[$149]
  DB BOOT_RAM_2K

SECTION "Destination Code", HOME[$14A]
  DB BOOT_DEST_INTERNATIONAL

SECTION "Old Licensee Code", HOME[$14B]
  DB $33

SECTION "ROM Version", HOME[$14C]
  DB $01

SECTION "Header Checksum", HOME[$14D]
  DB $00

SECTION "Global Checksum", HOME[$14E]
  DW $0000
