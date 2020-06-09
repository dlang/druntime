/**
 * The threadbase module provides OS-independent code
 * for thread storage and management.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/threadbase.d)
 */

module core.thread.threadbase;

import core.thread.context;
import core.thread.osthread; //FIXME: remove it
import core.sync.mutex;
import core.sys.posix.stdlib : realloc;

// Handling unaligned mutexes are not supported on all platforms, so we must
// ensure that the address of all shared data are appropriately aligned.
import core.internal.traits : classInstanceAlignment;

private enum mutexAlign = classInstanceAlignment!Mutex;
private enum mutexClassInstanceSize = __traits(classInstanceSize, Mutex);

package abstract class ThreadBase
{
    static ThreadBase       sm_this; /// Local storage
    __gshared ThreadBase    sm_main; /// Main process thread

    //
    // Standard thread data
    //
    Callable        m_call; /// The thread function.
    size_t          m_sz;   /// The stack size for this thread.
    StackContext    m_main;
    StackContext*   m_curr;
    ThreadID        m_addr;
    bool            m_isDaemon;

    //
    // Storage of Active Thread
    //

    bool m_lock;
    void*               m_tlsgcdata;

    //
    // Sets a thread-local reference to the current thread object.
    //
    static void setThis( ThreadBase t ) nothrow @nogc
    {
        sm_this = t;
    }

    ///////////////////////////////////////////////////////////////////////////
    // GC Scanning Support
    ///////////////////////////////////////////////////////////////////////////


    // NOTE: The GC scanning process works like so:
    //
    //          1. Suspend all threads.
    //          2. Scan the stacks of all suspended threads for roots.
    //          3. Resume all threads.
    //
    //       Step 1 and 3 require a list of all threads in the system, while
    //       step 2 requires a list of all thread stacks (each represented by
    //       a Context struct).  Traditionally, there was one stack per thread
    //       and the Context structs were not necessary.  However, Fibers have
    //       changed things so that each thread has its own 'main' stack plus
    //       an arbitrary number of nested stacks (normally referenced via
    //       m_curr).  Also, there may be 'free-floating' stacks in the system,
    //       which are Fibers that are not currently executing on any specific
    //       thread but are still being processed and still contain valid
    //       roots.
    //
    //       To support all of this, the Context struct has been created to
    //       represent a stack range, and a global list of Context structs has
    //       been added to enable scanning of these stack ranges.  The lifetime
    //       (and presence in the Context list) of a thread's 'main' stack will
    //       be equivalent to the thread's lifetime.  So the Ccontext will be
    //       added to the list on thread entry, and removed from the list on
    //       thread exit (which is essentially the same as the presence of a
    //       Thread object in its own global list).  The lifetime of a Fiber's
    //       context, however, will be tied to the lifetime of the Fiber object
    //       itself, and Fibers are expected to add/remove their Context struct
    //       on construction/deletion.


    //
    // All use of the global thread lists/array should synchronize on this lock.
    //
    // Careful as the GC acquires this lock after the GC lock to suspend all
    // threads any GC usage with slock held can result in a deadlock through
    // lock order inversion.
    @property static Mutex slock() nothrow @nogc
    {
        return cast(Mutex)_slock.ptr;
    }

    @property static Mutex criticalRegionLock() nothrow @nogc
    {
        return cast(Mutex)_criticalRegionLock.ptr;
    }

    __gshared align(mutexAlign) void[mutexClassInstanceSize] _slock;
    __gshared align(mutexAlign) void[mutexClassInstanceSize] _criticalRegionLock;

    static void initLocks() @nogc
    {
        _slock[] = typeid(Mutex).initializer[];
        (cast(Mutex)_slock.ptr).__ctor();

        _criticalRegionLock[] = typeid(Mutex).initializer[];
        (cast(Mutex)_criticalRegionLock.ptr).__ctor();
    }

    static void termLocks() @nogc
    {
        (cast(Mutex)_slock.ptr).__dtor();
        (cast(Mutex)_criticalRegionLock.ptr).__dtor();
    }

    __gshared StackContext*  sm_cbeg;

    __gshared ThreadBase    sm_tbeg;
    __gshared size_t    sm_tlen;

    // can't use core.internal.util.array in public code
    __gshared Thread* pAboutToStart;
    __gshared size_t nAboutToStart;

    //
    // Used for ordering threads in the global thread list.
    //
    ThreadBase          prev;
    ThreadBase          next;


    ///////////////////////////////////////////////////////////////////////////
    // Global Context List Operations
    ///////////////////////////////////////////////////////////////////////////


    //
    // Add a context to the global context list.
    //
    static void add( StackContext* c ) nothrow @nogc
    in
    {
        assert( c );
        assert( !c.next && !c.prev );
    }
    do
    {
        slock.lock_nothrow();
        scope(exit) slock.unlock_nothrow();
        assert(!suspendDepth); // must be 0 b/c it's only set with slock held

        if (sm_cbeg)
        {
            c.next = sm_cbeg;
            sm_cbeg.prev = c;
        }
        sm_cbeg = c;
    }


    //
    // Remove a context from the global context list.
    //
    // This assumes slock being acquired. This isn't done here to
    // avoid double locking when called from remove(Thread)
    static void remove( StackContext* c ) nothrow @nogc
    in
    {
        assert( c );
        assert( c.next || c.prev );
    }
    do
    {
        if ( c.prev )
            c.prev.next = c.next;
        if ( c.next )
            c.next.prev = c.prev;
        if ( sm_cbeg == c )
            sm_cbeg = c.next;
        // NOTE: Don't null out c.next or c.prev because opApply currently
        //       follows c.next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this
        //       function, however, a context should never be re-added to the
        //       list anyway and having next and prev be non-null is a good way
        //       to ensure that.
    }


    ///////////////////////////////////////////////////////////////////////////
    // Global Thread List Operations
    ///////////////////////////////////////////////////////////////////////////


    //
    // Add a thread to the global thread list.
    //
    static void add( Thread t, bool rmAboutToStart = true ) nothrow @nogc
    in
    {
        assert( t );
        assert( !t.next && !t.prev );
    }
    do
    {
        slock.lock_nothrow();
        scope(exit) slock.unlock_nothrow();
        assert(t.isRunning); // check this with slock to ensure pthread_create already returned
        assert(!suspendDepth); // must be 0 b/c it's only set with slock held

        if (rmAboutToStart)
        {
            size_t idx = -1;
            foreach (i, thr; pAboutToStart[0 .. nAboutToStart])
            {
                if (thr is t)
                {
                    idx = i;
                    break;
                }
            }
            assert(idx != -1);
            import core.stdc.string : memmove;
            memmove(pAboutToStart + idx, pAboutToStart + idx + 1, threadClassSize * (nAboutToStart - idx - 1));
            pAboutToStart =
                cast(Thread*)realloc(pAboutToStart, threadClassSize * --nAboutToStart);
        }

        if (sm_tbeg)
        {
            t.next = sm_tbeg;
            sm_tbeg.prev = t;
        }
        sm_tbeg = t;
        ++sm_tlen;
    }

    //
    // Remove a thread from the global thread list.
    //
    static void remove( ThreadBase t ) nothrow @nogc
    in( t )
    {
        // Thread was already removed earlier, might happen b/c of thread_detachInstance
        if (!t.next && !t.prev && (sm_tbeg !is t))
            return;

        slock.lock_nothrow();
        {
            // NOTE: When a thread is removed from the global thread list its
            //       main context is invalid and should be removed as well.
            //       It is possible that t.m_curr could reference more
            //       than just the main context if the thread exited abnormally
            //       (if it was terminated), but we must assume that the user
            //       retains a reference to them and that they may be re-used
            //       elsewhere.  Therefore, it is the responsibility of any
            //       object that creates contexts to clean them up properly
            //       when it is done with them.
            remove( &t.m_main );

            if ( t.prev )
                t.prev.next = t.next;
            if ( t.next )
                t.next.prev = t.prev;
            if ( sm_tbeg is t )
                sm_tbeg = t.next;
            t.prev = t.next = null;
            --sm_tlen;
        }
        // NOTE: Don't null out t.next or t.prev because opApply currently
        //       follows t.next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this
        //       function, however, a thread should never be re-added to the
        //       list anyway and having next and prev be non-null is a good way
        //       to ensure that.
        slock.unlock_nothrow();
    }


    ///////////////////////////////////////////////////////////////////////////
    // General Properties
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Sets the daemon status for this thread.  While the runtime will wait for
     * all normal threads to complete before tearing down the process, daemon
     * threads are effectively ignored and thus will not prevent the process
     * from terminating.  In effect, daemon threads will be terminated
     * automatically by the OS when the process exits.
     *
     * Params:
     *  val = The new daemon status for this thread.
     */
    final @property void isDaemon( bool val ) @safe @nogc
    {
        synchronized( this )
        {
            m_isDaemon = val;
        }
    }

    /**
     * Gets the daemon status for this thread.  While the runtime will wait for
     * all normal threads to complete before tearing down the process, daemon
     * threads are effectively ignored and thus will not prevent the process
     * from terminating.  In effect, daemon threads will be terminated
     * automatically by the OS when the process exits.
     *
     * Returns:
     *  true if this is a daemon thread.
     */
    final @property bool isDaemon() @safe @nogc
    {
        synchronized( this )
        {
            return m_isDaemon;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////

    package this(size_t sz = 0) @safe pure nothrow @nogc
    {
        m_sz = sz;
        m_curr = &m_main;
    }

    this( void function() fn, size_t sz = 0 ) @safe pure nothrow @nogc
    in( fn )
    {
        this(sz);
        m_call = fn;
    }

    this( void delegate() dg, size_t sz = 0 ) @safe pure nothrow @nogc
    in( dg )
    {
        this(sz);
        m_call = dg;
    }

    void tlsGCdataInit() nothrow @nogc
    {
        m_tlsgcdata = rt_tlsgc_init();
    }

    void dataStorageInit() nothrow
    {
        assert( m_curr is &m_main );

        m_main.bstack = getStackBottom();
        m_main.tstack = m_main.bstack;
        tlsGCdataInit();
    }

    void dataStorageDestroy() nothrow @nogc
    {
        rt_tlsgc_destroy( m_tlsgcdata );
        m_tlsgcdata = null;
    }

    void dataStorageDestroyIfAvail() nothrow @nogc
    {
        if (m_tlsgcdata)
            dataStorageDestroy();
    }

    bool isRunning() nothrow @nogc;


    ///////////////////////////////////////////////////////////////////////////
    // Thread Accessors
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Provides a reference to the calling thread.
     *
     * Returns:
     *  The thread object representing the calling thread.  The result of
     *  deleting this object is undefined.  If the current thread is not
     *  attached to the runtime, a null reference is returned.
     */
    static ThreadBase getThis() @safe nothrow @nogc
    {
        // NOTE: This function may not be called until thread_init has
        //       completed.  See thread_suspendAll for more information
        //       on why this might occur.
        return sm_this;
    }


    /**
     * Provides a list of all threads currently being tracked by the system.
     * Note that threads in the returned array might no longer run (see
     * $(D Thread.)$(LREF isRunning)).
     *
     * Returns:
     *  An array containing references to all threads currently being
     *  tracked by the system.  The result of deleting any contained
     *  objects is undefined.
     */
    static ThreadBase[] getAll()
    {
        static void resize(ref ThreadBase[] buf, size_t nlen)
        {
            buf.length = nlen;
        }
        return getAllImpl!resize();
    }

    package static ThreadBase[] getAllImpl(alias resize)()
    {
        import core.atomic;

        ThreadBase[] buf;
        while (true)
        {
            immutable len = atomicLoad!(MemoryOrder.raw)(*cast(shared)&sm_tlen);
            resize(buf, len);
            assert(buf.length == len);
            synchronized (slock)
            {
                if (len == sm_tlen)
                {
                    size_t pos;
                    for (ThreadBase t = sm_tbeg; t; t = t.next)
                        buf[pos++] = t;
                    return buf;
                }
            }
        }
    }
}

extern (C) size_t threadClassSize() pure @nogc nothrow;

// Used for suspendAll/resumeAll below.
package __gshared uint suspendDepth = 0;

private
{
    // interface to rt.tlsgc
    import core.internal.traits : externDFunc;

    alias rt_tlsgc_init = externDFunc!("rt.tlsgc.init", void* function() nothrow @nogc);
    alias rt_tlsgc_destroy = externDFunc!("rt.tlsgc.destroy", void function(void*) nothrow @nogc);

    alias ScanDg = void delegate(void* pstart, void* pend) nothrow;
    alias rt_tlsgc_scan =
        externDFunc!("rt.tlsgc.scan", void function(void*, scope ScanDg) nothrow);

    alias rt_tlsgc_processGCMarks =
        externDFunc!("rt.tlsgc.processGCMarks", void function(void*, scope IsMarkedDg) nothrow);
}


/**
 * Search the list of all threads for a thread with the given thread identifier.
 *
 * Params:
 *  addr = The thread identifier to search for.
 * Returns:
 *  The thread object associated with the thread identifier, null if not found.
 */
static ThreadBase thread_findByAddr( ThreadID addr )
{
    Thread.slock.lock_nothrow();
    scope(exit) ThreadBase.slock.unlock_nothrow();

    // also return just spawned thread so that
    // DLL_THREAD_ATTACH knows it's a D thread
    foreach (t; ThreadBase.pAboutToStart[0 .. ThreadBase.nAboutToStart])
        if (t.m_addr == addr)
            return t;

    foreach (t; Thread)
        if (t.m_addr == addr)
            return t;

    return null;
}


/**
 * Sets the current thread to a specific reference. Only to be used
 * when dealing with externally-created threads (in e.g. C code).
 * The primary use of this function is when Thread.getThis() must
 * return a sensible value in, for example, TLS destructors. In
 * other words, don't touch this unless you know what you're doing.
 *
 * Params:
 *  t = A reference to the current thread. May be null.
 */
extern (C) void thread_setThis(ThreadBase t) nothrow @nogc
{
    ThreadBase.setThis(t);
}
