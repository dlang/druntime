# This makefile is designed to be run by gnu make.
# The default make program on FreeBSD 8.1 is not gnu make; to install gnu make:
#    pkg_add -r gmake
# and then run as gmake rather than make.

QUIET:=@

OS:=
uname_S:=$(shell uname -s)
ifeq (Darwin,$(uname_S))
	OS:=osx
endif
ifeq (Linux,$(uname_S))
	OS:=linux
endif
ifeq (FreeBSD,$(uname_S))
	OS:=freebsd
endif
ifeq (OpenBSD,$(uname_S))
	OS:=openbsd
endif
ifeq (Solaris,$(uname_S))
	OS:=solaris
endif
ifeq (SunOS,$(uname_S))
	OS:=solaris
endif
ifeq (,$(OS))
	$(error Unrecognized or unsupported OS for uname: $(uname_S))
endif

DMD?=dmd

DOCDIR=doc
IMPDIR=import

MODEL=32
override PIC:=$(if $(PIC),-fPIC,)

ifeq (osx,$(OS))
	DOTDLL:=.dylib
	DOTLIB:=.a
else
	DOTDLL:=.so
	DOTLIB:=.a
endif

DFLAGS=-m$(MODEL) -O -release -inline -w -Isrc -Iimport -property $(PIC)
UDFLAGS=-m$(MODEL) -O -release -w -Isrc -Iimport -property $(PIC)
DDOCFLAGS=-m$(MODEL) -c -w -o- -Isrc -Iimport

CFLAGS=-m$(MODEL) -O $(PIC)

ifeq (osx,$(OS))
    ASMFLAGS =
else
    ASMFLAGS = -Wa,--noexecstack
endif

OBJDIR:=obj/$(MODEL)
OBJ_LIB_DIR:=$(OBJDIR)/lib
OBJ_DLL_DIR:=$(OBJDIR)/dll
DRUNTIME_BASE:=druntime-$(OS)$(MODEL)

TARGET:=druntime_lib
UNITTEST:=unittest_lib
# default to dll targets on some platforms
ifeq (linux,$(OS))
	ifeq (64,$(MODEL))
#		TARGET:=druntime_dll
		UNITTEST:=unittest_dll
	endif
endif

DOCFMT=-version=CoreDdoc

include mak/COPY
COPY:=$(subst \,/,$(COPY))

include mak/DOCS
DOCS:=$(subst \,/,$(DOCS))

include mak/IMPORTS
IMPORTS:=$(subst \,/,$(IMPORTS))

include mak/MANIFEST
MANIFEST:=$(subst \,/,$(MANIFEST))

include mak/SRCS
SRCS:=$(subst \,/,$(SRCS))

# NOTE: trace.d and cover.d are not necessary for a successful build
#       as both are used for debugging features (profiling and coverage)
# NOTE: a pre-compiled minit.obj has been provided in dmd for Win32	 and
#       minit.asm is not used by dmd for Linux

OBJS:=errno_c.o threadasm.o complex.o
OBJS_LIB:=$(addprefix $(OBJ_LIB_DIR)/,$(OBJS))
OBJS_DLL:=$(addprefix $(OBJ_DLL_DIR)/,$(OBJS))

######################## All of'em ##############################

target : import copy druntime doc

######################## Doc .html file generation ##############################

doc: $(DOCS)

$(DOCDIR)/object.html : src/object_.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $<

$(DOCDIR)/core_%.html : src/core/%.di
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $<

$(DOCDIR)/core_%.html : src/core/%.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $<

$(DOCDIR)/core_sync_%.html : src/core/sync/%.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $<

######################## Header .di file generation ##############################

import: $(IMPORTS)

$(IMPDIR)/core/sync/%.di : src/core/sync/%.d
	@mkdir -p `dirname $@`
	$(DMD) -m$(MODEL) -c -o- -Isrc -Iimport -Hf$@ $<

######################## Header .di file copy ##############################

copy: $(COPY)

$(IMPDIR)/%.di : src/%.di
	@mkdir -p `dirname $@`
	cp $< $@

$(IMPDIR)/%.d : src/%.d
	@mkdir -p `dirname $@`
	cp $< $@

################### C/ASM Targets ############################

$(OBJDIR)/%/complex.o : src/rt/complex.c
	@mkdir -p `dirname $@`
	$(CC) -c $(CFLAGS) $< -o$@

$(OBJDIR)/%/errno_c.o : src/core/stdc/errno.c
	@mkdir -p `dirname $@`
	$(CC) -c $(CFLAGS) $< -o$@

$(OBJDIR)/%/threadasm.o : src/core/threadasm.S
	@mkdir -p $(OBJDIR)
	$(CC) $(ASMFLAGS) -c $(CFLAGS) $< -o$@

########################  ##############################

.PHONY: druntime druntime_dll druntime_lib
druntime: $(TARGET)

######################## Create a shared library ##############################

DRUNTIME_DLL:=lib/lib$(DRUNTIME_BASE)$(DOTDLL)

druntime_dll: PIC:=-fPIC
druntime_dll: $(DRUNTIME_DLL)

$(DRUNTIME_DLL): $(OBJS_DLL) $(SRCS)
	$(DMD) -shared -debuglib= -defaultlib= -of$@ -Xfdruntime.json $(DFLAGS) $(SRCS) $(OBJS_DLL)

################### Library generation #########################

DRUNTIME_LIB:=lib/lib$(DRUNTIME_BASE)$(DOTLIB)

druntime_lib: $(DRUNTIME_LIB)

$(DRUNTIME_LIB): $(OBJS_LIB) $(SRCS)
	$(DMD) -lib -of$@ -Xfdruntime.json $(DFLAGS) $(SRCS) $(OBJS_LIB)

################### Unit tests #########################

UT_MODULES:=$(patsubst src/%.d,%,$(SRCS))

.PHONY: unittest unittest_dll unittest_lib
unittest: $(UNITTEST)
	@echo done

ifeq ($(OS),freebsd)
DISABLED_TESTS =
else
DISABLED_TESTS =
endif

# macro that returns the module name given the src path
moduleName=$(subst rt.invariant,invariant,$(subst object_,object,$(subst /,.,$(1))))

################### Unit tests with a shared druntime #########################

UT_DLL_DIR:=$(OBJ_DLL_DIR)/unittest
UT_DRUNTIME:=$(UT_DLL_DIR)/lib$(DRUNTIME_BASE)-ut$(DOTDLL)

unittest_dll: PIC:=-fPIC
unittest_dll: $(UT_DLL_DIR)/test_runner $(addprefix $(UT_DLL_DIR)/,$(UT_MODULES))

$(UT_DRUNTIME): $(OBJS_DLL) $(SRCS)
	$(DMD) $(UDFLAGS) -shared -version=druntime_unittest -unittest -of$@ $(SRCS) $(OBJS_DLL) -debuglib= -defaultlib=

$(UT_DLL_DIR)/test_runner: $(UT_DRUNTIME) src/test_runner.d
	$(DMD) $(UDFLAGS) -of$@ src/test_runner.d -L-L$(UT_DLL_DIR) -L-rpath=$(UT_DLL_DIR) -L-l$(DRUNTIME_BASE)-ut -debuglib= -defaultlib=

$(UT_DLL_DIR)/% : $(UT_DLL_DIR)/test_runner
	@mkdir -p $(dir $@)
# make the file very old so it builds and runs again if it fails
	@touch -t 197001230123 $@
# run unittest in its own directory
	$(QUIET)$(RUN) $< $(call moduleName,$*)
# succeeded, render the file new again
	@touch $@

################### Unit tests with a static druntime #########################

UT_LIB_DIR:=$(OBJ_LIB_DIR)/unittest

unittest_lib: $(UT_LIB_DIR)/test_runner $(addprefix $(UT_LIB_DIR)/,$(UT_MODULES))

$(UT_LIB_DIR)/test_runner: $(OBJS_LIB) $(SRCS) src/test_runner.d
	$(DMD) $(UDFLAGS) -version=druntime_unittest -unittest -of$@ src/test_runner.d $(SRCS) $(OBJS_LIB) -debuglib= -defaultlib=

$(addprefix $(UT_LIB_DIR)/,$(DISABLED_TESTS)) :
	@echo $@ - disabled

$(UT_LIB_DIR)/% : $(UT_LIB_DIR)/test_runner
	@mkdir -p $(dir $@)
# make the file very old so it builds and runs again if it fails
	@touch -t 197001230123 $@
# run unittest in its own directory
	$(QUIET)$(RUN) $< $(call moduleName,$*)
# succeeded, render the file new again
	@touch $@

###################  #########################

detab:
	detab $(MANIFEST)
	tolf $(MANIFEST)

zip: druntime.zip

druntime.zip: $(MANIFEST) $(DOCS) $(IMPORTS)
	rm -rf $@
	zip $@ $^

install: druntime.zip
	unzip -o druntime.zip -d /dmd2/src/druntime

clean:
	rm -rf obj lib $(IMPDIR) $(DOCDIR) druntime.zip
