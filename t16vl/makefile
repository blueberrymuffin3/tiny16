SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
IVERILOG := iverilog
VL_SRC := $(SELF_DIR)src
VL_SRCS := $(wildcard $(VL_SRC)/*.sv)
VL_BIN := $(SELF_DIR)out.vvd

v_all: $(VL_BIN)

$(VL_BIN): $(VL_SRCS)
	@echo [IVERILOG] $@
	@$(IVERILOG) -g2012 -o $@ $^

v_format:
	verible-verilog-format --inplace $(VL_SRCS)

.PHONY: v_format
