HIDE=@
LIB_DIR:=lib
SRC_DIR:=src
TEST_DIR:=test
DMD:=dmd
TESTS:=deh gc init
TESTS:=$(addprefix $(TEST_DIR)/, $(TESTS))

LDFLAGS:=-L-L$(LIB_DIR) -L-rpath=$(LIB_DIR)

all: $(TESTS)

$(TEST_DIR)/%: LDFLAGS+=-L-l$*
$(TESTS): $(TEST_DIR)/%: $(SRC_DIR)/%.d $(LIB_DIR)/lib%.so Makefile
	$(HIDE)$(DMD) -unittest -I$(SRC_DIR) $(LDFLAGS) -of$@ $<
	$(HIDE)touch -t 197001230123 $@
	$(HIDE)echo Testing $@
	$(HIDE) $@
	$(HIDE)touch $@

$(LIB_DIR)/lib%.so: $(SRC_DIR)/lib%.d Makefile
	$(HIDE)$(DMD) -shared -fPIC  -I$(SRC_DIR) -of$@ $<

clean:
	rm -rf $(TEST_DIR) $(LIB_DIR)
