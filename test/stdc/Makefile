include ../common.mak

TESTS:=test19416

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix ,$(TESTS)))

$(ROOT)/%: $(SRC)/%.d
	$(QUIET)$(DMD) -betterC -of$@ $<

clean:
	rm -rf $(ROOT)
