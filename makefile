rom_title = snake
rom_file = bin/$(rom_title).gb
imgs = $(wildcard img/src/*.png)
dats = $(patsubst img/src/%.png,img/tiles_%.asm,$(imgs))

ensure_directory_exists = @mkdir -p $(@D)

# ------------------------------------------------------------------------------
# Primary Targets
# ------------------------------------------------------------------------------
game: $(rom_file)

clean:
	rm -rf obj
	rm -rf bin
	rm img/*.asm

# ------------------------------------------------------------------------------
# Dependency Targets
# ------------------------------------------------------------------------------

$(rom_file): $(dats) obj/main.o
	$(ensure_directory_exists)
	rgblink -m bin/$(rom_title).map -n bin/$(rom_title).sym -o $@ obj/main.o
	rgbfix -p 0xFF -v $@

img/tiles_%.asm: img/src/%.png img/src/%.json
	node builder/gfx $< $@

obj/main.o: main.asm
	$(ensure_directory_exists)
	rgbasm -h -E -M $(@:.o=.d) -o $@ $<

include $(wildcard obj/*.d)
