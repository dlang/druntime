/**
 * Every thread / fiber needs stack context data structure.
 * thread.context decouples this info into the StackContext struct.
 * Also, Thread / Fiber have some common functionality which is provided
 * as a super class for both in StackContextExecutor.
 * Finally, GlobalStackContext contains commonly used global data.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/osthread.d)
 */

module core.thread.context;

struct StackContext
{
    // bottom, top of stack
    void* bstack, tstack;

    /// Slot for the EH implementation to keep some state for each stack
    /// (will be necessary for exception chaining, etc.). Opaque as far as
    /// we are concerned here.
    void* ehContext;

    StackContext* within, next, prev;
}

/**
A class that represents a thread of execution that manages a stack.
This serves primarily as a superclass for Thread and Fiber.
*/
class StackContextExecutor
{
    //
    // The type of routine passed on thread/fiber construction.
    //
    enum Call
    {
        NO,
        FN,
        DG
    }

    // Common standard data for Thread / Fiber.
    Call                m_call = Call.NO;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }

    StackContext*   m_ctxt;
    size_t          m_size;
    Throwable       m_unhandled;

    // Thread / Fiber entry point.  Invokes the function or delegate passed on
    // construction (if any).
    final void run()
    {
        switch ( m_call )
        {
        case Call.FN:
            m_fn();
            break;
        case Call.DG:
            m_dg();
            break;
        default:
            break;
        }
    }

    final void pushContext( StackContext* c ) nothrow @nogc
    in
    {
        assert( !c.within );
    }
    do
    {
        m_ctxt.ehContext = swapContext(c.ehContext);
        c.within = m_ctxt;
        m_ctxt = c;
    }

    final void popContext() nothrow @nogc
    in
    {
        assert( m_ctxt && m_ctxt.within );
    }
    do
    {
        StackContext* c = m_ctxt;
        m_ctxt = c.within;
        c.ehContext = swapContext(m_ctxt.ehContext);
        c.within = null;
    }

    final StackContext* topContext() nothrow @nogc
    in
    {
        assert( m_ctxt );
    }
    do
    {
        return m_ctxt;
    }
}

struct GlobalStackContext
{
    ///////////////////////////////////////////////////////////////////////////
    // GC Scanning Support
    ///////////////////////////////////////////////////////////////////////////

    import core.sync.mutex : Mutex;


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
    //       To support all of this, the StackContext struct has been created to
    //       represent a stack range, and a global list of StackContext structs has
    //       been added to enable scanning of these stack ranges.  The lifetime
    //       (and presence in the StackContext list) of a thread's 'main' stack will
    //       be equivalent to the thread's lifetime.  So the StackContext will be
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
        return cast(Mutex)_locks[0].ptr;
    }

    @property static Mutex criticalRegionLock() nothrow @nogc
    {
        return cast(Mutex)_locks[1].ptr;
    }

    __gshared align(Mutex.alignof) void[__traits(classInstanceSize, Mutex)][2] _locks;

    static void initLocks() @nogc
    {
        foreach (ref lock; _locks)
        {
            lock[] = typeid(Mutex).initializer[];
            (cast(Mutex)lock.ptr).__ctor();
        }
    }

    static void termLocks() @nogc
    {
        foreach (ref lock; _locks)
            (cast(Mutex)lock.ptr).__dtor();
    }



    __gshared StackContext*  sm_cbeg;

    import core.thread : Thread;

    __gshared Thread sm_tbeg;
    __gshared size_t sm_tlen;

    // can't use core.internal.util.array in public code
    __gshared Thread* pAboutToStart;
    __gshared size_t  nAboutToStart;


    __gshared uint suspendDepth = 0;

    ///////////////////////////////////////////////////////////////////////////
    // Global Context List Operations
    ///////////////////////////////////////////////////////////////////////////


    //
    // Add a context to the global context list.
    //
    static void add(StackContext* c) nothrow @nogc
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
    static void remove(StackContext* c) nothrow @nogc
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
    static void add(Thread t, bool rmAboutToStart = true) nothrow @nogc
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
            import core.stdc.stdlib : realloc;
            memmove(pAboutToStart + idx,
                    pAboutToStart + idx + 1, Thread.sizeof * (nAboutToStart - idx - 1));

            pAboutToStart =
                cast(Thread*)realloc(pAboutToStart, Thread.sizeof * --nAboutToStart);
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
    static void remove(Thread t) nothrow @nogc
    in
    {
        assert( t );
    }
    do
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
}

private
{
    /**
     * Hook for whatever EH implementation is used to save/restore some data
     * per stack.
     *
     * Params:
     *     newContext = The return value of the prior call to this function
     *         where the stack was last swapped out, or null when a fiber stack
     *         is switched in for the first time.
     */
    extern(C) void* _d_eh_swapContext(void* newContext) nothrow @nogc;

    version (DigitalMars)
    {
        version (Windows)
            alias swapContext = _d_eh_swapContext;
        else
        {
            extern(C) void* _d_eh_swapContextDwarf(void* newContext) nothrow @nogc;

            void* swapContext(void* newContext) nothrow @nogc
            {
                /* Detect at runtime which scheme is being used.
                 * Eventually, determine it statically.
                 */
                static int which = 0;
                final switch (which)
                {
                    case 0:
                    {
                        assert(newContext == null);
                        auto p = _d_eh_swapContext(newContext);
                        auto pdwarf = _d_eh_swapContextDwarf(newContext);
                        if (p)
                        {
                            which = 1;
                            return p;
                        }
                        else if (pdwarf)
                        {
                            which = 2;
                            return pdwarf;
                        }
                        return null;
                    }
                    case 1:
                        return _d_eh_swapContext(newContext);
                    case 2:
                        return _d_eh_swapContextDwarf(newContext);
                }
            }
        }
    }
    else
        alias swapContext = _d_eh_swapContext;
}
