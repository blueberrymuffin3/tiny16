all: fasmg_all v_all
include fasmg/makefile
include t16q/makefile

T16EMU := cargo run --manifest-path t16emu/Cargo.toml
T16VL := ./$(VL_BIN)

run.t16emu.%: $(FASMG_BIN)/%.t16 phony_explicit
	@echo [LAUNCH] $@
	@$(T16EMU) $<

phony_explicit:
.PHONY: all phony_explicit
