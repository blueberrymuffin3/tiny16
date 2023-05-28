SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
FASMG := fasmg -v 1
MIFPY := $(SELF_DIR)/mif.py

FASMG_SRC := $(SELF_DIR)src
FASMG_SRC_LIB := $(FASMG_SRC)/lib
FASMG_SRCS := $(wildcard $(FASMG_SRC)/*.t16s)
FASMG_SRC_LIBS := $(wildcard $(FASMG_SRC)/lib/*)
FASMG_BIN := $(SELF_DIR)bin
FASMG_OBJS := $(patsubst $(FASMG_SRC)/%.t16s,$(FASMG_BIN)/%.t16,$(FASMG_SRCS))
FASMG_MIFS := $(patsubst $(FASMG_SRC)/%.t16s,$(FASMG_BIN)/%.mif,$(FASMG_SRCS))

fasmg_all: $(FASMG_OBJS)
fasmg_all_mif: $(FASMG_MIFS)

fasmg_clean:
	rm -Rfv $(FASMG_BIN)

$(FASMG_BIN):
	@mkdir -p $@

$(FASMG_BIN)/%.t16 $(FASMG_BIN)/%.dbg: $(FASMG_SRC)/%.t16s $(FASMG_SRC_LIBS) | $(FASMG_BIN)
	@echo [FASMG] $@
	@$(FASMG) $< $@

$(FASMG_BIN)/%.mif: $(FASMG_BIN)/%.t16
	@echo [MIF] $@
	@python $(MIFPY) <$^ >$@

.PHONY: fasmg_all fasmg_clean phony_explicit
phony_explicit:

.SUFFIXES:
