INCLUDE "inc/hardware.asm"

SECTION "Restart $00", ROM0[$00]
  jp $100

SECTION "Restart $08", ROM0[$08]
  jp $100

SECTION "Restart $10", ROM0[$10]
  jp $100

SECTION "Restart $18", ROM0[$18]
  jp $100

SECTION "Restart $20", ROM0[$20]
  jp $100

SECTION "Restart $28", ROM0[$28]
  jp $100

SECTION "Restart $30", ROM0[$30]
  jp $100

SECTION "Restart $38", ROM0[$38]
  jp $100

SECTION "V-Blank Interrupt", ROM0[$40]
  jp vblank

SECTION "Status Interrupt", ROM0[$48]
  reti

SECTION "Timer Interrupt", ROM0[$50]
  reti

SECTION "Serial Data Interrupt", ROM0[$58]
  reti

SECTION "Joypad Interrupt", ROM0[$60]
  reti

SECTION "Header Padding", ROM0[$68]
  DS $98

SECTION "Entrypoint", ROM0[$100]
  nop
  jp main

SECTION "Nintendo Logo", ROM0[$104]
  NINTENDO_LOGO ; Defined in hardware.inc

SECTION "Title", ROM0[$134]
  ; Title must be 11 upper-case characters. Pad with $00.
  DB "SNAKE",0,0,0,0,0,0
  
SECTION "Product Code", ROM0[$13F]
  ; Leave blank.
  DB 0,0,0,0

SECTION "Game Boy Color Mode", ROM0[$143]
  DB BOOT_GBC_UNSUPPORTED

SECTION "Licensee Code", ROM0[$144]
  DB "DH"

SECTION "Super Game Boy Mode", ROM0[$146]
  DB BOOT_SGB_UNSUPPORTED

SECTION "Cartridge Type", ROM0[$147]
  DB BOOT_CART_MBC5_RAM_BATTERY

SECTION "ROM Size", ROM0[$148]
  DB BOOT_ROM_32K

SECTION "RAM Size", ROM0[$149]
  DB BOOT_RAM_2K

SECTION "Destination Code", ROM0[$14A]
  DB BOOT_DEST_INTERNATIONAL

SECTION "Old Licensee Code", ROM0[$14B]
  DB $33

SECTION "ROM Version", ROM0[$14C]
  DB $01

SECTION "Header Checksum", ROM0[$14D]
  DB $00

SECTION "Global Checksum", ROM0[$14E]
  DW $0000
