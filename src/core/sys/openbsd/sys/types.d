/**
  * D header file for OpenBSD
  */
module core.sys.openbsd.sys.types;

version (OpenBSD):
extern (C):
pure:
nothrow:

// _MAX_PAGE_SHIFT is a system var that is used to
// calculate the MINSIGSTKSZ and SIGSTKSZ variables
// in sys/posix/signal.d. This value differs between
// system platforms based on the OpenBSD source code.

// MIPS64 has a value of 14
// SPARC64 and Alpha platforms have a value of 13
// everything else has a value of 12
// Values found here:
// https://github.com/openbsd/src/search?q=_MAX_PAGE_SHIFT&unscoped_q=_MAX_PAGE_SHIFT 
version (SPARC64)
{
    enum PAGE_SHIFT = 13;
}
else version (Alpha)
{
    enum PAGE_SHIFT = 13;
}
else version (MIPS64)
{
    enum PAGE_SHIFT = 14;
}
else
{
    enum PAGE_SHIFT = 12;
}

enum _MAX_PAGE_SHIFT = PAGE_SHIFT;
enum PAGE_SIZE       = (1 << PAGE_SHIFT);

// ALIGNBYTES & STACKALIGNBYTES definitions by platform
// located in <machine/_types.h> OpenBSD src.
version (Alpha)
{
    enum _ALIGNBYTES        = 7;
    alias _STACKALIGNBYTES  = _ALIGNBYTES;
}
else version (X86_64)
{
    enum _ALIGNBYTES        = (long.sizeof - 1);
    enum _STACKALIGNBYTES   = 15;
}
else version (ARM)
{
    enum _ALIGNBYTES        = (double.sizeof - 1);
    enum _STACKALIGNBYTES   = 7;
}
else version (AArch64)
{
    enum _ALIGNBYTES        = (long.sizeof - 1);
    enum _STACKALIGNBYTES   = 15;
}
else version (HPPA)
{
    enum _ALIGNBYTES        = 7;
    alias _STACKALIGNBYTES  = _ALIGNBYTES;
}
else version (X86)
{
    enum _ALIGNBYTES        = (int.sizeof - 1);
    enum _STACKALIGNBYTES   = 15;
}
else version (MIPS64)
{
    enum _ALIGNBYTES        = 7;
    enum _STACKALIGNBYTES   = 15;
}
else version (PPC)
{
    enum _ALIGNBYTES        = (double.sizeof - 1);
    enum _STACKALIGNBYTES   = 15;
}
else version (SH)
{
    enum _ALIGNBYTES        = (int.sizeof - 1);
    alias _STACKALIGNBYTES  = _ALIGNBYTES;
}
else version (SPARC64)
{
    enum _ALIGNBYTES        = 0xf;
    alias _STACKALIGNBYTES  = _ALIGNBYTES;
}
else
{
    // Not sure what to use for default since these values are
    // not available across all OpenBSD supported platforms.
}

