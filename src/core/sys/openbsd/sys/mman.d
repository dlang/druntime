/**
 * D header file for OpenBSD
 *
 * https://cvsweb.openbsd.org/src/sys/sys/mman.h
 */
module core.sys.openbsd.sys.mman;

version (OpenBSD):
extern (C):
nothrow:

public import core.sys.posix.sys.mman;
import core.sys.openbsd.sys.cdefs;
import core.sys.posix.sys.types;

static if (__BSD_VISIBLE)
{
    enum MAP_INHERIT_SHARE = 0;     // share with child
    enum MAP_INHERIT_COPY =  1;     // copy into child
    enum MAP_INHERIT_NONE =  2;     // absent from child
    enum MAP_INHERIT_ZERO =  3;     // zero in child

    alias MAP_COPY = MAP_PRIVATE;   // "copy" region at mmap time

    enum MAP_FILE = 0;              // map from file (default)
    enum MAP_HASSEMAPHORE = 0;      // region may contain semaphores
    enum MAP_INHERIT = 0;           // region retained after exec
    enum MAP_NORESERVE = 0;         // Sun: don't reserve needed swap area
    enum MAP_RENAME = 0;            // Sun: rename private pages to file
    enum MAP_TRYFIXED = 0;          // attempt hint address, even within heap

    alias MADV_NORMAL = POSIX_MADV_NORMAL;
    alias MADV_RANDOM = POSIX_MADV_RANDOM;
    alias MADV_SEQUENTIAL = POSIX_MADV_SEQUENTIAL;
    alias MADV_WILLNEED = POSIX_MADV_WILLNEED;
    alias MADV_DONTNEED = POSIX_MADV_DONTNEED;

    enum MADV_SPACAVAIL = 5;    // insure that resources are reserved
    enum MADV_FREE      = 6;    // pages are empty, free them

    int madvise(void *, size_t, int);
    int mincore(const(void) *, size_t, char *);
    int minherit(void *, size_t, int);
}

