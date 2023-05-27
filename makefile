all: fasmg_all v_all
include fasmg/makefile
include t16vl/makefile

T16EMU := cargo run --manifest-path t16emu/Cargo.toml
T16VL := ./$(VL_BIN)

run.t16emu.%: $(FASMG_BIN)/%.t16 phony_explicit
	@echo [LAUNCH] $@
	@$(T16EMU) $<

run.t16vl.%: $(FASMG_BIN)/%.hex $(T16VL) phony_explicit
	@echo [LAUNCH] $@
	@$(T16VL) +rom=$<

phony_explicit:
.PHONY: all phony_explicit
