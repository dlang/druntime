include ../common.mak

TESTS:=bug20368

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix ,$(TESTS)))

$(ROOT)/%: $(SRC)/%.d
	$(QUIET)$(DMD) -of$@ $<

clean:
	rm -rf $(ROOT)
