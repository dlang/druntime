/**
 * D header file for GNU/Hurd
 *
 * $(LINK2 http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h, glibc bits/elfclass.h)
 */
module core.sys.hurd.elfclass;

version (Hurd):
extern (C):
nothrow:
@system:

import core.stdc.stdint : uint32_t;
import core.sys.hurd.config : __WORDSIZE;

alias __ELF_NATIVE_CLASS = __WORDSIZE;
alias Elf_Symndx = uint32_t;
