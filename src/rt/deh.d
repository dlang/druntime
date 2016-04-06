/**
 * Implementation of exception handling support routines.
 *
 * Copyright: Copyright Digital Mars 1999 - 2013.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright
 * Source: $(DRUNTIMESRC src/rt/deh.d)
 */

module rt.deh;

extern (C)
{
    Throwable.TraceInfo _d_traceContext(void* ptr = null);
    void _d_createTrace(Object o, void* context)
    {
        auto t = cast(Throwable) o;

        if (t !is null && t.info is null &&
            cast(byte*) t !is typeid(t).initializer.ptr)
        {
            t.info = _d_traceContext(context);
        }
    }

    /// Uncaught exception handler.
    /// Should only ever be executed if rt_trapExceptions was 0 when
    /// the runtime was initialized.
    /// Not supported on Win32 as stack unwinding and uncaught
    /// exceptions are handled by the OS there.
    /// If this function returns, a platform-specific action occurs
    /// (e.g. abort() is called, a HLT instruction is executed, or the
    /// exception is passed to the operating system).
    __gshared void function(Object o) _d_uncaughtException =
        &_d_uncaughtExceptionDefaultHandler;

    /// Default uncaught exception handler.
    /// It should be possible to breakpoint this function to stop the
    /// debugger on uncaught exceptions before the stack has been unwound
    /// (except on Win32 - see above).
    void _d_uncaughtExceptionDefaultHandler(Object o)
    {
    }
}

version (Win32)
    public import rt.deh_win32;
else version (Win64)
    public import rt.deh_win64_posix;
else version (Posix)
    public import rt.deh_win64_posix;
else
    static assert (0, "Unsupported architecture");

