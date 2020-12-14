/**
 * D header file for C99.
 *
 * $(C_HEADER_DESCRIPTION pubs.opengroup.org/onlinepubs/009695399/basedefs/_time.h.html, _time.h)
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly,
 *            Alex Rønne Petersen
 * Source:    $(DRUNTIMESRC core/stdc/_time.d)
 * Standards: ISO/IEC 9899:1999 (E)
 */

module core.stdc.time;

version (Posix)
{
    public import core.sys.posix.stdc.time;
    import core.sys.posix.sys.types : CRuntime_Musl_Needs_Time64_Compat_Layer;
}
else version (Windows)
{
    public import core.sys.windows.stdc.time;
    // This enum is defined only for Posix, this file is the only one
    // needing it in `core.stdc`.
    private enum CRuntime_Musl_Needs_Time64_Compat_Layer = false;
}
else
    static assert(0, "unsupported system");

import core.stdc.config;

extern (C):
@trusted: // There are only a few functions here that use unsafe C strings.
nothrow:
@nogc:

static if (CRuntime_Musl_Needs_Time64_Compat_Layer)
{
    pure double  __difftime64(time_t time1, time_t time0); // MT-Safe
    @system time_t  __mktime64(scope tm* timeptr); // @system: MT-Safe env locale
    time_t  __time64(scope time_t* timer);
    @system char*   __ctime64(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf race:asctime env locale
    @system tm*     __gmtime64(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale
    @system tm*     __localtime64(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale

    ///
    alias time = __time64;
    ///
    alias difftime = __difftime64;
    ///
    alias mktime = __mktime64;
    ///
    alias gmtime = __gmtime64;
    ///
    alias localtime = __localtime64;
    ///
    alias ctime = __ctime64;
}
else
{
    ///
    pure double  difftime(time_t time1, time_t time0); // MT-Safe
    ///
    @system time_t  mktime(scope tm* timeptr); // @system: MT-Safe env locale
    ///
    time_t  time(scope time_t* timer);
    ///
    @system char*   ctime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf race:asctime env locale
    ///
    @system tm*     gmtime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale
    ///
    @system tm*     localtime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale
}

///
@system char*   asctime(const scope tm* timeptr); // @system: MT-Unsafe race:asctime locale
///
@system size_t  strftime(scope char* s, size_t maxsize, const scope char* format, const scope tm* timeptr); // @system: MT-Safe env locale
