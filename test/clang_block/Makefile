include ../common.mak

TESTS:=clang_block

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix .done,$(TESTS)))

$(ROOT)/%.done: $(ROOT)/%
	@echo Testing $*
	$(QUIET)$(TIMELIMIT)$(ROOT)/$* $(RUN_ARGS)
	@touch $@

$(ROOT)/%_c: $(SRC)/%.c
	@mkdir -p $(@D)
	$(QUIET)$(CC) $(CFLAGS) -o $@.o -c $<

$(ROOT)/%: $(SRC)/%.d $(ROOT)/%_c
	$(QUIET)$(DMD) $(DFLAGS) -main -unittest -of$@ $@_c.o $<

clean:
	rm -rf $(GENERATED)
