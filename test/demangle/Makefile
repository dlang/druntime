include ../common.mak

TESTS:=test_demangle

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix .done,$(TESTS)))

$(ROOT)/%: $(SRC)/%.d
	$(QUIET)$(DMD) $(DFLAGS) -of$@ $<

$(ROOT)/test_demangle.done: $(ROOT)/test_demangle
	@echo Testing demangling
	$(QUIET)$(ROOT)/test_demangle
	@touch $@

clean:
	rm -rf $(ROOT)
