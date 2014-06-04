/**
 * Contains the implementation for object monitors.
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 */

/*          Copyright Digital Mars 2000 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.monitor_;

//debug=PRINTF;

nothrow:

private
{
    debug(PRINTF) import core.stdc.stdio;
    import core.stdc.stdlib;
    import core.atomic;

    version( linux )
    {
        version = USE_PTHREADS;
    }
    else version( FreeBSD )
    {
        version = USE_PTHREADS;
    }
    else version( OSX )
    {
        version = USE_PTHREADS;
    }
    else version( Solaris )
    {
        version = USE_PTHREADS;
    }
    else version( Android )
    {
        version = USE_PTHREADS;
    }

    // This is what the monitor reference in Object points to
    alias Object.Monitor        IMonitor;
    alias void delegate(Object) DEvent;

    version( Windows )
    {
        version (Win32)
            pragma(lib, "snn.lib");
        import core.sys.windows.windows;

        struct Monitor
        {
            IMonitor impl; // for user-level monitors
            DEvent[] devt; // for internal monitors
            size_t   refs; // reference count
            CRITICAL_SECTION mon;
        }
    }
    else version( USE_PTHREADS )
    {
        import core.sys.posix.pthread;

        struct Monitor
        {
            IMonitor impl; // for user-level monitors
            DEvent[] devt; // for internal monitors
            size_t   refs; // reference count
            pthread_mutex_t mon;
        }
    }
    else
    {
        static assert(0, "Unsupported platform");
    }

    __gshared Monitor*[Object] monitors;

    shared static SpinRWLock monitorsLock;

    extern(C) Monitor* getMonitor(Object h) nothrow
    {
        assert(h);
        size_t offset = typeid(h).monitorOffset;
        if (offset  == size_t.max)
        {
            // The monitor is stored in external hash table
            monitorsLock.lockRead();
            scope(exit) monitorsLock.unlockRead();
            try
            {
                return monitors.get(h, null);
            }
            catch(Exception ex)
            {
                return null;
            }
        }
        return *cast(Monitor**)(cast(byte*)h + offset);
    }

    extern(C) void setMonitor(Object h, Monitor* m) nothrow
    {
        assert(h);
        size_t offset = typeid(h).monitorOffset;
        if (offset == size_t.max)
        {
            // The monitor is stored in external hash table
            monitorsLock.lockWrite();
            scope(exit) monitorsLock.unlockWrite();
            if (m is null)
            {
                monitors.remove(h);
            }
            else
            {
                monitors[h] = m;
            }
            return;
        }

        *cast(Monitor**)(cast(byte*)h + offset) = m;
    }

    static __gshared int inited;
}

shared struct SpinRWLock
{
    void lockRead() nothrow
    {
        while (!tryLockRead()) { }
    }

    bool tryLockRead() nothrow
    {
        ptrdiff_t thisVal;
        ptrdiff_t newVal;
        do
        {
            thisVal = count;
            if (thisVal == -1) return false;
            newVal = count + 1;
        } while(!cas(&count, thisVal, newVal));
        return true;
    }

    void unlockRead() nothrow
    {
        ptrdiff_t thisVal;
        ptrdiff_t newVal;
        do
        {
            thisVal = count;
            assert(thisVal > 0);
            newVal = count - 1;
        } while(!cas(&count, thisVal, newVal));
    }

    bool tryLockWrite() nothrow
    {
        do
        {
            if (count > 0) return false;
        } while(!cas(&count, cast(ptrdiff_t)0, cast(ptrdiff_t)-1));
        return true;
    }

    void lockWrite() nothrow
    {
        while (!cas(&count, cast(ptrdiff_t)0, cast(ptrdiff_t)-1)) { }
    }

    void unlockWrite() nothrow
    {
        assert(count == -1);
        while (!cas(&count, cast(ptrdiff_t)-1, cast(ptrdiff_t)0)) { }
    }

    void promote() nothrow
    {
        while (!cas(&count, cast(ptrdiff_t)1, cast(ptrdiff_t)-1)) { }
    }

    void demote() nothrow
    {
        assert(count == -1);
        while (!cas(&count, cast(ptrdiff_t)-1, cast(ptrdiff_t)1)) { }
    }

    private ptrdiff_t count = 0;
}


/* =============================== Win32 ============================ */

version( Windows )
{
    static __gshared CRITICAL_SECTION _monitor_critsec;

    extern (C) void _STI_monitor_staticctor()
    {
        debug(PRINTF) printf("+_STI_monitor_staticctor()\n");
        if (!inited)
        {
            InitializeCriticalSection(&_monitor_critsec);
            inited = 1;
        }
        debug(PRINTF) printf("-_STI_monitor_staticctor()\n");
    }

    extern (C) void _STD_monitor_staticdtor()
    {
        debug(PRINTF) printf("+_STI_monitor_staticdtor() - d\n");
        if (inited)
        {
            inited = 0;
            DeleteCriticalSection(&_monitor_critsec);
        }
        debug(PRINTF) printf("-_STI_monitor_staticdtor() - d\n");
    }

    extern (C) Monitor* _d_monitor_create(Object h)
    {
        /*
         * NOTE: Assume this is only called when h.__monitor is null prior to the
         * call.  However, please note that another thread may call this function
         * at the same time, so we can not assert this here.  Instead, try and
         * create a lock, and if one already exists then forget about it.
         */

        debug(PRINTF) printf("+_d_monitor_create(%p)\n", h);
        EnterCriticalSection(&_monitor_critsec);
        Monitor *cs = getMonitor(h);
        if (!cs)
        {
            cs = cast(Monitor *)calloc(Monitor.sizeof, 1);
            assert(cs);
            InitializeCriticalSection(&cs.mon);
            setMonitor(h, cs);
            cs.refs = 1;
        }
        LeaveCriticalSection(&_monitor_critsec);
        debug(PRINTF) printf("-_d_monitor_create(%p)\n", h);
        return cs;
    }

    extern (C) void _d_monitor_destroy(Object h)
    {
        debug(PRINTF) printf("+_d_monitor_destroy(%p)\n", h);
        Monitor* m = getMonitor(h);
        setMonitor(h, null);
        assert(m && !m.impl);
        DeleteCriticalSection(&m.mon);
        free(m);
        debug(PRINTF) printf("-_d_monitor_destroy(%p)\n", h);
    }

    extern (C) void _d_monitor_lock(Monitor* m)
    {
        debug(PRINTF) printf("+_d_monitor_acquire(%p)\n", m);
        assert(m && !m.impl);
        EnterCriticalSection(&m.mon);
        debug(PRINTF) printf("-_d_monitor_acquire(%p)\n", m);
    }

    extern (C) void _d_monitor_unlock(Monitor* m)
    {
        debug(PRINTF) printf("+_d_monitor_release(%p)\n", m);
        assert(m && !m.impl);
        LeaveCriticalSection(&m.mon);
        debug(PRINTF) printf("-_d_monitor_release(%p)\n", m);
    }
}

/* =============================== linux ============================ */

version( USE_PTHREADS )
{
    // Includes attribute fixes from David Friedman's GDC port
    static __gshared pthread_mutex_t _monitor_critsec;
    static __gshared pthread_mutexattr_t _monitors_attr;

    extern (C) void _STI_monitor_staticctor()
    {
        if (!inited)
        {
            pthread_mutexattr_init(&_monitors_attr);
            pthread_mutexattr_settype(&_monitors_attr, PTHREAD_MUTEX_RECURSIVE);
            pthread_mutex_init(&_monitor_critsec, &_monitors_attr);
            inited = 1;
        }
    }

    extern (C) void _STD_monitor_staticdtor()
    {
        if (inited)
        {
            inited = 0;
            pthread_mutex_destroy(&_monitor_critsec);
            pthread_mutexattr_destroy(&_monitors_attr);
        }
    }

    extern (C) Monitor* _d_monitor_create(Object h)
    {
        /*
         * NOTE: Assume this is only called when h.__monitor is null prior to the
         * call.  However, please note that another thread may call this function
         * at the same time, so we can not assert this here.  Instead, try and
         * create a lock, and if one already exists then forget about it.
         */

        debug(PRINTF) printf("+_d_monitor_create(%p)\n", h);
        pthread_mutex_lock(&_monitor_critsec);
        Monitor* cs = getMonitor(h);
        if (!cs)
        {
            cs = cast(Monitor *)calloc(Monitor.sizeof, 1);
            assert(cs);
            pthread_mutex_init(&cs.mon, &_monitors_attr);
            setMonitor(h, cs);
            cs.refs = 1;
            atomicOp!"|="((cast(shared)typeid(h)).m_flags, TypeInfo_Class.ClassFlags.hasAllocatedMonitors);
        }
        pthread_mutex_unlock(&_monitor_critsec);
        debug(PRINTF) printf("-_d_monitor_create(%p)\n", h);
        return cs;
    }

    extern (C) void _d_monitor_destroy(Object h)
    {
        debug(PRINTF) printf("+_d_monitor_destroy(%p)\n", h);
        Monitor* m = getMonitor(h);
        setMonitor(h, null);
        assert(m && !m.impl);
        pthread_mutex_destroy(&m.mon);
        free(m);
        debug(PRINTF) printf("-_d_monitor_destroy(%p)\n", h);
    }

    extern (C) void _d_monitor_lock(Monitor* m)
    {
        debug(PRINTF) printf("+_d_monitor_acquire(%p)\n", m);
        assert(m && !m.impl);
        pthread_mutex_lock(&m.mon);
        debug(PRINTF) printf("-_d_monitor_acquire(%p)\n", m);
    }

    extern (C) void _d_monitor_unlock(Monitor* m)
    {
        debug(PRINTF) printf("+_d_monitor_release(%p)\n", m);
        assert(m && !m.impl);
        pthread_mutex_unlock(&m.mon);
        debug(PRINTF) printf("-_d_monitor_release(%p)\n", m);
    }
}
