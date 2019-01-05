# Makefile to build D runtime library druntime.lib for Win32

MODEL=32

DMD_DIR=..\dmd
BUILD=release
OS=windows
DMD=$(DMD_DIR)\generated\$(OS)\$(BUILD)\$(MODEL)\dmd

CC=dmc
MAKE=make

DOCDIR=doc
IMPDIR=import

DFLAGS=-m$(MODEL) -conf= -O -release -dip1000 -inline -w -Isrc -Iimport
UDFLAGS=-m$(MODEL) -conf= -O -release -dip1000 -w -Isrc -Iimport
DDOCFLAGS=-conf= -c -w -o- -Isrc -Iimport -version=CoreDdoc

CFLAGS=

DRUNTIME_BASE=druntime
DRUNTIME=lib\$(DRUNTIME_BASE).lib
GCSTUB=lib\gcstub.obj

DOCFMT=

target : import copydir copy $(DRUNTIME) $(GCSTUB)

$(mak\COPY)
$(mak\DOCS)
$(mak\IMPORTS)
$(mak\SRCS)

# NOTE: trace.d and cover.d are not necessary for a successful build
#       as both are used for debugging features (profiling and coverage)
# NOTE: a pre-compiled minit.obj has been provided in dmd for Win32 and
#       minit.asm is not used by dmd for Linux

OBJS= errno_c_$(MODEL).obj src\rt\minit.obj
OBJS_TO_DELETE= errno_c_$(MODEL).obj

######################## Header file generation ##############################

import:
	$(MAKE) -f mak/WINDOWS import DMD="$(DMD)" IMPDIR="$(IMPDIR)"

copydir:
	$(MAKE) -f mak/WINDOWS copydir IMPDIR="$(IMPDIR)"

copy:
	$(MAKE) -f mak/WINDOWS copy DMD="$(DMD)" IMPDIR="$(IMPDIR)"

######################## Doc .html file generation ##############################

doc: $(DOCS)

$(DOCDIR)\object.html : src\object.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_atomic.html : src\core\atomic.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_attribute.html : src\core\attribute.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_bitop.html : src\core\bitop.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_checkedint.html : src\core\checkedint.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_cpuid.html : src\core\cpuid.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_demangle.html : src\core\demangle.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_exception.html : src\core\exception.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_math.html : src\core\math.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_memory.html : src\core\memory.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_runtime.html : src\core\runtime.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_simd.html : src\core\simd.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_thread.html : src\core\thread.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_time.html : src\core\time.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_vararg.html : src\core\vararg.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_assert_.html : src\core\stdc\assert_.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_complex.html : src\core\stdc\complex.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_ctype.html : src\core\stdc\ctype.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_errno.html : src\core\stdc\errno.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_fenv.html : src\core\stdc\fenv.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_float_.html : src\core\stdc\float_.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_inttypes.html : src\core\stdc\inttypes.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_limits.html : src\core\stdc\limits.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_locale.html : src\core\stdc\locale.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_math.html : src\core\stdc\math.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_signal.html : src\core\stdc\signal.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_stdarg.html : src\core\stdc\stdarg.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_stddef.html : src\core\stdc\stddef.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_stdint.html : src\core\stdc\stdint.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_stdio.html : src\core\stdc\stdio.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_stdlib.html : src\core\stdc\stdlib.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_string.html : src\core\stdc\string.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_tgmath.html : src\core\stdc\tgmath.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_time.html : src\core\stdc\time.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_wchar_.html : src\core\stdc\wchar_.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_stdc_wctype.html : src\core\stdc\wctype.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_barrier.html : src\core\sync\barrier.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_condition.html : src\core\sync\condition.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_config.html : src\core\sync\config.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_exception.html : src\core\sync\exception.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_mutex.html : src\core\sync\mutex.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_rwmutex.html : src\core\sync\rwmutex.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

$(DOCDIR)\core_sync_semaphore.html : src\core\sync\semaphore.d
	$(DMD) $(DDOCFLAGS) -Df$@ $(DOCFMT) $**

changelog.html: changelog.dd
	$(DMD) -Dfchangelog.html changelog.dd

################### Win32 Import Libraries ###################

IMPLIBS= \
	lib\win32\glu32.lib \
	lib\win32\odbc32.lib \
	lib\win32\opengl32.lib \
	lib\win32\rpcrt4.lib \
	lib\win32\shell32.lib \
	lib\win32\version.lib \
	lib\win32\wininet.lib \
	lib\win32\winspool.lib

implibsdir :
	if not exist lib\win32 mkdir lib\win32

implibs : implibsdir $(IMPLIBS)

lib\win32\glu32.lib : def\glu32.def
	implib $@ $**

lib\win32\odbc32.lib : def\odbc32.def
	implib $@ $**

lib\win32\opengl32.lib : def\opengl32.def
	implib $@ $**

lib\win32\rpcrt4.lib : def\rpcrt4.def
	implib $@ $**

lib\win32\shell32.lib : def\shell32.def
	implib $@ $**

lib\win32\version.lib : def\version.def
	implib $@ $**

lib\win32\wininet.lib : def\wininet.def
	implib $@ $**

lib\win32\winspool.lib : def\winspool.def
	implib $@ $**

################### C\ASM Targets ############################

errno_c_$(MODEL).obj : src\core\stdc\errno.c
	$(CC) -c -o$@ $(CFLAGS) src\core\stdc\errno.c

# only rebuild explicitly
rebuild_minit_obj : src\rt\minit.asm
	$(CC) -c $(CFLAGS) src\rt\minit.asm

################### gcstub generation #########################

$(GCSTUB) : src\gcstub\gc.d win$(MODEL).mak
	$(DMD) -c -of$(GCSTUB) src\gcstub\gc.d $(DFLAGS)

################### Library generation #########################

$(DRUNTIME): $(OBJS) $(SRCS) win$(MODEL).mak
	*$(DMD) -lib -of$(DRUNTIME) -Xfdruntime.json $(DFLAGS) $(SRCS) $(OBJS)

unittest : $(SRCS) $(DRUNTIME)
	*$(DMD) $(UDFLAGS) -L/co -unittest -ofunittest.exe -main $(SRCS) $(DRUNTIME) -debuglib=$(DRUNTIME) -defaultlib=$(DRUNTIME)
	unittest

zip: druntime.zip

druntime.zip:
	del druntime.zip
	git ls-tree --name-only -r HEAD >MANIFEST.tmp
	zip32 -T -ur druntime @MANIFEST.tmp
	del MANIFEST.tmp

install: druntime.zip
	unzip -o druntime.zip -d \dmd2\src\druntime

clean:
	del $(DRUNTIME) $(OBJS_TO_DELETE) $(GCSTUB)
	rmdir /S /Q $(DOCDIR) $(IMPDIR)

auto-tester-build: target

# Disable unittests for Druntime.
auto-tester-test:
