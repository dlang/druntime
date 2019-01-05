# Makefile to build D runtime library druntime64.lib for Win64

MODEL=64

VCDIR=\Program Files (x86)\Microsoft Visual Studio 10.0\VC
SDKDIR=\Program Files (x86)\Microsoft SDKs\Windows\v7.0A

DMD_DIR=..\dmd
BUILD=release
OS=windows
DMD=$(DMD_DIR)\generated\$(OS)\$(BUILD)\$(MODEL)\dmd

CC="$(VCDIR)\bin\amd64\cl"
LD="$(VCDIR)\bin\amd64\link"
AR="$(VCDIR)\bin\amd64\lib"
CP=cp

DOCDIR=doc
IMPDIR=import

MAKE=make

DFLAGS=-m$(MODEL) -conf= -O -release -dip1000 -inline -w -Isrc -Iimport
UDFLAGS=-m$(MODEL) -conf= -O -release -dip1000 -w -Isrc -Iimport
DDOCFLAGS=-conf= -c -w -o- -Isrc -Iimport -version=CoreDdoc

#CFLAGS=/O2 /I"$(VCDIR)"\INCLUDE /I"$(SDKDIR)"\Include
CFLAGS=/Z7 /I"$(VCDIR)"\INCLUDE /I"$(SDKDIR)"\Include

DRUNTIME_BASE=druntime$(MODEL)
DRUNTIME=lib\$(DRUNTIME_BASE).lib
GCSTUB=lib\gcstub$(MODEL).obj

# do not preselect a C runtime (extracted from the line above to make the auto tester happy)
CFLAGS=$(CFLAGS) /Zl

DOCFMT=

target : import copydir copy $(DRUNTIME) $(GCSTUB)

$(mak\COPY)
$(mak\DOCS)
$(mak\IMPORTS)
$(mak\SRCS)

# NOTE: trace.d and cover.d are not necessary for a successful build
#       as both are used for debugging features (profiling and coverage)

OBJS= errno_c_$(MODEL).obj msvc_$(MODEL).obj msvc_math_$(MODEL).obj
OBJS_TO_DELETE= errno_c_$(MODEL).obj msvc_$(MODEL).obj msvc_math_$(MODEL).obj

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

################### C\ASM Targets ############################

errno_c_$(MODEL).obj : src\core\stdc\errno.c
	$(CC) -c -Fo$@ $(CFLAGS) src\core\stdc\errno.c

msvc_$(MODEL).obj : src\rt\msvc.c win64.mak
	$(CC) -c -Fo$@ $(CFLAGS) src\rt\msvc.c

msvc_math_$(MODEL).obj : src\rt\msvc_math.c win64.mak
	$(CC) -c -Fo$@ $(CFLAGS) src\rt\msvc_math.c

################### gcstub generation #########################

$(GCSTUB) : src\gcstub\gc.d win64.mak
	$(DMD) -c -of$(GCSTUB) src\gcstub\gc.d $(DFLAGS)


################### Library generation #########################

$(DRUNTIME): $(OBJS) $(SRCS) win64.mak
	*$(DMD) -lib -of$(DRUNTIME) -Xfdruntime.json $(DFLAGS) $(SRCS) $(OBJS)

# due to -conf= on the command line, LINKCMD and LIB need to be set in the environment
unittest : $(SRCS) $(DRUNTIME)
	*$(DMD) $(UDFLAGS) -version=druntime_unittest -unittest -ofunittest.exe -main $(SRCS) $(DRUNTIME) -debuglib=$(DRUNTIME) -defaultlib=$(DRUNTIME) user32.lib
	unittest

################### Win32 COFF support #########################

# default to 32-bit compiler relative to 64-bit compiler, link and lib are architecture agnostic
CC32=$(CC)\..\..\cl

druntime32mscoff:
	$(MAKE) -f win64.mak "DMD=$(DMD)" MODEL=32mscoff "CC=\$(CC32)"\"" "AR=\$(AR)"\"" "VCDIR=$(VCDIR)" "SDKDIR=$(SDKDIR)"

unittest32mscoff:
	$(MAKE) -f win64.mak "DMD=$(DMD)" MODEL=32mscoff "CC=\$(CC32)"\"" "AR=\$(AR)"\"" "VCDIR=$(VCDIR)" "SDKDIR=$(SDKDIR)" unittest

################### zip/install/clean ##########################

zip: druntime.zip

druntime.zip: import
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
