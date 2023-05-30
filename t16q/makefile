SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
QUARTUS := quartus
Q_SRC := $(SELF_DIR)src
Q_SRCS := $(shell find $(Q_SRC)) $(SELF_DIR)tiny16.qpf $(SELF_DIR)tiny16.qsf
Q_ROMINIT := $(Q_SRC)/rom-init.mif
Q_SOF := $(SELF_DIR)output_files/tiny16.sof
Q_CDF := output_files/tiny16.cdf
Q_PROGRAM_NAME := hello_world_printf

$(Q_ROMINIT): $(FASMG_BIN)/$(Q_PROGRAM_NAME).mif
	@echo [MIF] rom-init.mif is $<
	@cp $< $@

$(Q_SOF): $(Q_SRCS) $(Q_ROMINIT)
	@echo [QUARTUS_SH] compile $@
	@cd $(SELF_DIR) && \
	$(QUARTUS)_sh --flow compile tiny16

t16q.run: $(Q_SOF)
	@echo [QUARTUS_PPGM] upload $<
	@cd $(SELF_DIR) && \
	$(QUARTUS)_pgm $(Q_CDF)

.PHONY: run.t16q
