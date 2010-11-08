/**
 * This module contains allocation functions for the garbage collector.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, David Friedman, Sean Kelly, Leandro Lucarella
 */

module gc.os;


// Fork
////////////////////////////////////////////////////////////////////////

// Public interface/Documentation

/**
 * Possible results for the wait_pid() function.
 */
enum WRes
{
    DONE, /// The process has finished successfully
    RUNNING, /// The process is still running
    ERROR /// There was an error waiting for the process
}

version (D_Ddoc) {

/**
 * Indicates if an implementation support fork().
 *
 * The value shown here is just demostrative, the real value is defined based
 * on the OS it's being compiled in.
 */
const HAVE_FORK = true;

/**
 * Wait for a process with PID pid to finish.
 *
 * If block is false, this function will not block, and return WRes.RUNNING if
 * the process is still running. Otherwise it will return always WRes.DONE
 * (unless there is an error, in which case WRes.ERROR is returned).
 */
WRes wait_pid(pid_t pid, bool block = true);

public import core.sys.posix.unistd: pid_t, fork;

}

// Implementations
else version (Posix) {
    enum { HAVE_FORK = true }
    public import core.sys.posix.unistd: pid_t, fork;
    import core.sys.posix.sys.wait: waitpid, WNOHANG;
    public WRes wait_pid(pid_t pid, bool block = true) {
        int status = void;
        pid_t waited_pid = waitpid(pid, &status, block ? 0 : WNOHANG);
        if (waited_pid == 0)
            return WRes.RUNNING;
        assert (waited_pid == pid);
        assert (status == 0);
        if (waited_pid != pid || status != 0)
            return WRes.ERROR;
        return WRes.DONE;
    }
}

else {
    enum { HAVE_FORK = false }
    alias int pid_t;
    pid_t fork() { assert (false); return -1; }
    WRes wait_pid(pid_t, bool = true) { assert (false); return false; }
}


// Allocation
////////////////////////////////////////////////////////////////////////

version (Win32)
    import core.sys.windows.UserGdi;
else version (Posix)
    import core.sys.posix.sys.mman;
else
    import core.stdc.stdlib;


// Public interface/Documentation

/**
 * Visibility of the mapped memory.
 */
enum Vis
{
    PRIV, /// Private to this process
    SHARED, /// Shared across fork()ed processes (only when HAVE_SHARED)
}

version (D_Ddoc) {

/**
 * Indicates if an implementation support mapping shared memory.
 *
 * The value shown here is just demostrative, the real value is defined based
 * on the OS it's being compiled in.
 */
const HAVE_SHARED = false;

/**
 * Map memory.
 */
void* alloc(size_t nbytes, Vis vis = Vis.PRIV);

/**
 * Unmap memory allocated with alloc().
 * Returns:
 *      true  success
 *      false failure
 */
bool dealloc(void* base, size_t nbytes, Vis vis = Vis.PRIV);

}

// Implementations
else static if (is(typeof(VirtualAlloc))) {
    enum { HAVE_SHARED = false }

    void* alloc(size_t nbytes, Vis vis = Vis.PRIV)
    {
        assert (vis == Vis.PRIV);
        return VirtualAlloc(null, nbytes, MEM_RESERVE | MEM_COMMIT,
                PAGE_READWRITE);
    }

    bool dealloc(void* base, size_t nbytes, Vis vis = Vis.PRIV)
    {
        assert (vis == Vis.PRIV);
        return VirtualFree(base, 0, MEM_RELEASE) != 0;
    }

}

else static if (is(typeof(mmap)) && is(typeof(MAP_ANON))) {
    enum { HAVE_SHARED = true }

    void* alloc(size_t nbytes, Vis vis = Vis.PRIV)
    {
        auto flags = MAP_ANON;
        if (vis == Vis.SHARED)
            flags |= MAP_SHARED;
        else // PRIV
            flags |= MAP_PRIVATE;
        void* p = mmap(null, nbytes, PROT_READ | PROT_WRITE, flags, -1, 0);
        return (p == MAP_FAILED) ? null : p;
    }

    bool dealloc(void* base, size_t nbytes, Vis vis = Vis.PRIV)
    {
        // vis is not necessary to unmap
        return munmap(base, nbytes) == 0;
    }
}

else static if (is(typeof(malloc))) {
    enum { HAVE_SHARED = false }

    // NOTE: This assumes malloc granularity is at least (void*).sizeof.  If
    //       (req_size + PAGESIZE) is allocated, and the pointer is rounded up
    //       to PAGESIZE alignment, there will be space for a void* at the end
    //       after PAGESIZE bytes used by the GC.

    import gc.gc: PAGESIZE;

    const size_t PAGE_MASK = PAGESIZE - 1;

    void* alloc(size_t nbytes, Vis vis = Vis.PRIV)
    {
        assert (vis == Vis.PRIV);
        byte* p, q;
        p = cast(byte* ) malloc(nbytes + PAGESIZE);
        q = p + ((PAGESIZE - ((cast(size_t) p & PAGE_MASK))) & PAGE_MASK);
        *cast(void**)(q + nbytes) = p;
        return q;
    }

    bool dealloc(void* base, size_t nbytes, Vis vis = Vis.PRIV)
    {
        assert (vis == Vis.PRIV);
        free(*cast(void**)(cast(byte*) base + nbytes));
        return true;
    }
}

else static assert(false, "No supported allocation methods available.");


// vim: set et sw=4 sts=4 :
