/**
  * D header file for OpenBSD
  */
module core.sys.openbsd.sys.types;

version (OpenBSD):

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
        enum _MAX_PAGE_SHIFT = 13;
    }
    else version (Alpha)
    {
        enum _MAX_PAGE_SHIFT = 13;
    }
    else version (MIPS64)
    {
        enum _MAX_PAGE_SHIFT = 14;
    }
    else
    {
        enum _MAX_PAGE_SHIFT = 12;
    }

