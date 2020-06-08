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

// Handling unaligned mutexes are not supported on all platforms, so we must
// ensure that the address of all shared data are appropriately aligned.
import core.internal.traits : classInstanceAlignment;

private enum mutexAlign = classInstanceAlignment!Mutex;
private enum mutexClassInstanceSize = __traits(classInstanceSize, Mutex);

package abstract class ThreadBase
{
    //
    // Standard thread data
    //
    Callable m_call; /// The thread function.
    size_t m_sz; /// The stack size for this thread.
    StackContext m_main;
    StackContext* m_curr;

    //
    // Storage of Active Thread
    //

    bool m_lock;


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

    this(size_t sz = 0) @safe pure nothrow @nogc
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

    bool isRunning() nothrow @nogc;
}
