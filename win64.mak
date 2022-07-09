# Proxy Makefile for backwards compatibility after move to DMD

DMD_DIR=..\dmd
BUILD=release
MODEL=64
OS=windows
DMD=$(DMD_DIR)\generated\$(OS)\$(BUILD)\$(MODEL)\dmd
CC=cl
MAKE=make
HOST_DMD=dmd
DOCDIR=doc
IMPDIR=import
DFLAGS=-m$(MODEL) -conf= -O -release -preview=dip1000 -preview=fieldwise -preview=dtorfields -inline -w -Isrc -Iimport
UDFLAGS=-m$(MODEL) -conf= -O -release -preview=dip1000 -preview=fieldwise -w -version=_MSC_VER_$(_MSC_VER) -Isrc -Iimport
UTFLAGS=-version=CoreUnittest -unittest -checkaction=context
# DDOCFLAGS=-conf= -c -w -o- -Isrc -Iimport -version=CoreDdoc
CFLAGS=
DRUNTIME_BASE=druntime$(MODEL)
DRUNTIME=lib\$(DRUNTIME_BASE).lib
DOCFMT=

MAKE_WIN32=$(MAKE) -f win64.mak \
	"DMD_DIR=$(DMD_DIR)" \
	"BUILD=$(BUILD)" \
	"MODEL=$(MODEL)" \
	"OS=$(OS)" \
	"DMD=$(DMD)" \
	CC=$(CC) \
	"MAKE=$(MAKE)" \
	"HOST_DMD=$(HOST_DMD)" \
	"DOCDIR=$(DOCDIR)" \
	"IMPDIR=$(IMPDIR)" \
	"DFLAGS=$(DFLAGS)" \
	"UDFLAGS=$(UDFLAGS)" \
	"UTFLAGS=$(UTFLAGS)" \
	"CFLAGS=$(CFLAGS)" \
	"DRUNTIME_BASE=$(DRUNTIME_BASE)" \
	"DRUNTIME=$(DRUNTIME)" \
	"DOCFMT=$(DOCFMT)"

target:
	+cd $(DMD_DIR)/druntime && $(MAKE_WIN32) $@
	xcopy /s /e /h /i $(DMD_DIR)/druntime/lib lib

import:
	+cd $(DMD_DIR)/druntime && $(MAKE_WIN32) $@
	xcopy /s /e /h /i $(DMD_DIR)/druntime/import import

# copydir:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# copy:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# implibsdir:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# implibs:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# unittest:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# test_all:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

# zip:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

install:
	echo "Windows builds have been disabled"

# clean:
# 	cd $(DMD_DIR)/druntime
# 	$(MAKE_WIN32) $@

auto-tester-build:
	echo "Windows builds have been disabled on auto-tester"

auto-tester-test:
	echo "Windows builds have been disabled on auto-tester"
