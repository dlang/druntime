/**
 * Opaque declarations of rt.thread interface implementations.
 *
 * Copyright: Copyright Martin Nowak 2011.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly, Walter Bright
 * Source:    $(DRUNTIMESRC core/internal/thread.di)
 */

/*          Copyright Sean Martin Nowak 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 * Source: $(LINK http://www.dsource.org/projects/druntime/browser/trunk/src/core/thread.d)
 */
module core.internal.thread;
import core.time; // for Duration

// declaration only
class ThreadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__);
    // no fields, no virtual methods
}

// declaration only
class FiberException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__);
    // no fields, no virtual methods
}

// initialize thread module
void init();

/*
 * Opaque interface to thread implementation. Always use a ThreadImpl by reference.
 */
final class ThreadImpl
{
    static ThreadImpl create(Object owner, void function() fn, size_t sz);
    static ThreadImpl create(Object owner, void delegate() dg, size_t sz);
    void finalize();

    void start();
    Throwable join(bool rethrow);
    @property string name();
    @property void name(string val);
    @property bool isDaemon();
    @property void isDaemon(bool val);
    @property bool isRunning();
    static @property int minPriority();
    static @property int maxPriority();
    @property int priority();
    @property void priority(int val);

    static void sleep(Duration val);
    static void yield();
    static Object getOwner();
    static Object[] getAll();
    static int opApply(scope int delegate( ref ThreadImpl ) dg);

    version(Posix)
    {
        import core.sys.posix.sys.types;
        alias pthread_key_t TLSKey;
        alias pthread_t     ThreadAddr;
    }
    else version (Windows)
    {
        alias uint TLSKey;
        alias uint ThreadAddr;
    }

    static ThreadImpl attachThis(Object owner);
    version( Windows )
    {
        static ThreadImpl attachByAddr(Object owner, ThreadAddr addr);
        static ThreadImpl attachByAddr(Object owner, ThreadAddr addr, void *bstack);
    }
    static ThreadImpl findByAddr(ThreadAddr addr);
}


/*
 * Opaque interface to fiber implementation. Always use a FiberImpl by reference.
 */
final class FiberImpl
{
    static FiberImpl create(Object owner, void function() fn, size_t sz);
    static FiberImpl create(Object owner, void delegate() dg, size_t sz);
    void finalize();

    enum State { HOLD, EXEC, TERM }

    Object call(bool rethrow);
    void reset();
    @property State state() const;
    static void yield();
    static void yieldAndThrow(Throwable t);
    static Object getOwner();
}
