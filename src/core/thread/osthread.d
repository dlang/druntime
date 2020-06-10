/**
 * The osthread module provides low-level, OS-dependent code
 * for thread creation and management.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/osthread.d)
 */

module core.thread.osthread;

public import core.thread.threadbase; //FIXME: remove public
import core.thread.context;
import core.atomic;
import core.memory : GC;
import core.time;
import core.exception : onOutOfMemoryError;


///////////////////////////////////////////////////////////////////////////////
// Platform Detection and Memory Allocation
///////////////////////////////////////////////////////////////////////////////

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (D_InlineAsm_X86)
{
    version (Windows)
        version = AsmX86_Windows;
    else version (Posix)
        version = AsmX86_Posix;
}
else version (D_InlineAsm_X86_64)
{
    version (Windows)
    {
        version = AsmX86_64_Windows;
    }
    else version (Posix)
    {
        version = AsmX86_64_Posix;
    }
}

version (Posix)
{
    import core.sys.posix.unistd;

    version (AsmX86_Windows)    {} else
    version (AsmX86_Posix)      {} else
    version (AsmX86_64_Windows) {} else
    version (AsmX86_64_Posix)   {} else
    version (AsmExternal)       {} else
    {
        // NOTE: The ucontext implementation requires architecture specific
        //       data definitions to operate so testing for it must be done
        //       by checking for the existence of ucontext_t rather than by
        //       a version identifier.  Please note that this is considered
        //       an obsolescent feature according to the POSIX spec, so a
        //       custom solution is still preferred.
        import core.sys.posix.ucontext;
    }
}

version (Windows)
{
    import core.stdc.stdint : uintptr_t; // for _beginthreadex decl below
    import core.stdc.stdlib;             // for malloc, atexit
    import core.sys.windows.basetsd /+: HANDLE+/;
    import core.sys.windows.threadaux /+: getThreadStackBottom, impersonate_thread, OpenThreadHandle+/;
    import core.sys.windows.winbase /+: CloseHandle, CREATE_SUSPENDED, DuplicateHandle, GetCurrentThread,
        GetCurrentThreadId, GetCurrentProcess, GetExitCodeThread, GetSystemInfo, GetThreadContext,
        GetThreadPriority, INFINITE, ResumeThread, SetThreadPriority, Sleep,  STILL_ACTIVE,
        SuspendThread, SwitchToThread, SYSTEM_INFO, THREAD_PRIORITY_IDLE, THREAD_PRIORITY_NORMAL,
        THREAD_PRIORITY_TIME_CRITICAL, WAIT_OBJECT_0, WaitForSingleObject+/;
    import core.sys.windows.windef /+: TRUE+/;
    import core.sys.windows.winnt /+: CONTEXT, CONTEXT_CONTROL, CONTEXT_INTEGER+/;

    private extern (Windows) alias btex_fptr = uint function(void*);
    package /* FIXME:private */ extern (C) uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*) nothrow @nogc;
}
else version (Posix)
{
    import core.stdc.errno;
    import core.sys.posix.semaphore;
    import core.sys.posix.stdlib; // for malloc, valloc, free, atexit
    import core.sys.posix.pthread;
    import core.sys.posix.signal;
    import core.sys.posix.time;

    version (Darwin)
    {
        import core.sys.darwin.mach.thread_act;
        import core.sys.darwin.pthread : pthread_mach_thread_np;
    }
}

package(core.thread)
{
    static immutable size_t PAGESIZE;
    version (Posix) static immutable size_t PTHREAD_STACK_MIN;
}

shared static this()
{
    version (Windows)
    {
        SYSTEM_INFO info;
        GetSystemInfo(&info);

        PAGESIZE = info.dwPageSize;
        assert(PAGESIZE < int.max);
    }
    else version (Posix)
    {
        PAGESIZE = cast(size_t)sysconf(_SC_PAGESIZE);
        PTHREAD_STACK_MIN = cast(size_t)sysconf(_SC_THREAD_STACK_MIN);
    }
    else
    {
        static assert(0, "unimplemented");
    }
}

version (Solaris)
{
    import core.sys.solaris.sys.priocntl;
    import core.sys.solaris.sys.types;
    import core.sys.posix.sys.wait : idtype_t;
}

//FIXME: temporary moved from threadbase.d
/**
 * Performs intermediate shutdown of the thread module.
 */
shared static ~this()
{
    // NOTE: The functionality related to garbage collection must be minimally
    //       operable after this dtor completes.  Therefore, only minimal
    //       cleanup may occur.
    auto t = ThreadBase.sm_tbeg;
    while (t)
    {
        auto tn = t.next;
        if (!t.isRunning)
            ThreadBase.remove(t);
        t = tn;
    }
}


/**
 * This class encapsulates all threading functionality for the D
 * programming language.  As thread manipulation is a required facility
 * for garbage collection, all user threads should derive from this
 * class, and instances of this class should never be explicitly deleted.
 * A new thread may be created using either derivation or composition, as
 * in the following example.
 */
class Thread : ThreadBase
{
    //
    // Standard thread data
    //
    version (Posix)
    {
        private shared bool     m_isRunning;
    }
    version (Darwin)
    {
        private mach_port_t     m_tmach;
    }

    version (Solaris)
    {
        private __gshared bool m_isRTClass;
    }

    //
    // Standard types
    //
    version (Windows)
    {
        alias TLSKey = uint;
    }
    else version (Posix)
    {
        alias TLSKey = pthread_key_t;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a thread object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  fn must not be null.
     */
    this( void function() fn, size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(fn, sz);
    }


    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  dg must not be null.
     */
    this( void delegate() dg, size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(dg, sz);
    }

    package /*FIXME: private!*/ this( size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(sz);
    }

    /**
     * Cleans up any remaining resources used by this object.
     */
    ~this() nothrow @nogc
    {
        if (super.destructBeforeDtor())
            return;

        version (Windows)
        {
            m_addr = m_addr.init;
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version (Posix)
        {
            pthread_detach( m_addr );
            m_addr = m_addr.init;
        }
        version (Darwin)
        {
            m_tmach = m_tmach.init;
        }
    }

    /**
     * Provides a reference to the calling thread.
     *
     * Returns:
     *  The thread object representing the calling thread.  The result of
     *  deleting this object is undefined.  If the current thread is not
     *  attached to the runtime, a null reference is returned.
     */
    static Thread getThis() @safe nothrow @nogc
    {
        return ThreadBase.getThis().toThread;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Thread Context and GC Scanning Support
    ///////////////////////////////////////////////////////////////////////////


    version (Windows)
    {
        version (X86)
        {
            uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
        }
        else version (X86_64)
        {
            ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                                   // r8,r9,r10,r11,r12,r13,r14,r15
        }
        else
        {
            static assert(false, "Architecture not supported." );
        }
    }
    else version (Darwin)
    {
        version (X86)
        {
            uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
        }
        else version (X86_64)
        {
            ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                                   // r8,r9,r10,r11,r12,r13,r14,r15
        }
        else version (AArch64)
        {
            ulong[33]       m_reg; // x0-x31, pc
        }
        else version (ARM)
        {
            uint[16]        m_reg; // r0-r15
        }
        else
        {
            static assert(false, "Architecture not supported." );
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////


    /**
     * Starts the thread and invokes the function or delegate passed upon
     * construction.
     *
     * In:
     *  This routine may only be called once per thread instance.
     *
     * Throws:
     *  ThreadException if the thread fails to start.
     */
    final Thread start() nothrow
    in
    {
        assert( !next && !prev );
    }
    do
    {
        auto wasThreaded  = multiThreadedFlag;
        multiThreadedFlag = true;
        scope( failure )
        {
            if ( !wasThreaded )
                multiThreadedFlag = false;
        }

        version (Windows) {} else
        version (Posix)
        {
            size_t stksz = adjustStackSize( m_sz );

            pthread_attr_t  attr;

            if ( pthread_attr_init( &attr ) )
                onThreadError( "Error initializing thread attributes" );
            if ( stksz && pthread_attr_setstacksize( &attr, stksz ) )
                onThreadError( "Error initializing thread stack size" );
        }

        version (Windows)
        {
            // NOTE: If a thread is just executing DllMain()
            //       while another thread is started here, it holds an OS internal
            //       lock that serializes DllMain with CreateThread. As the code
            //       might request a synchronization on slock (e.g. in thread_findByAddr()),
            //       we cannot hold that lock while creating the thread without
            //       creating a deadlock
            //
            // Solution: Create the thread in suspended state and then
            //       add and resume it with slock acquired
            assert(m_sz <= uint.max, "m_sz must be less than or equal to uint.max");
            m_hndl = cast(HANDLE) _beginthreadex( null, cast(uint) m_sz, &thread_entryPoint, cast(void*) this, CREATE_SUSPENDED, &m_addr );
            if ( cast(size_t) m_hndl == 0 )
                onThreadError( "Error creating thread" );
        }

        slock.lock_nothrow();
        scope(exit) slock.unlock_nothrow();
        {
            ++nAboutToStart;
            pAboutToStart = cast(ThreadBase*)realloc(pAboutToStart, Thread.sizeof * nAboutToStart);
            pAboutToStart[nAboutToStart - 1] = cast(Thread) this; //FIXME: remove cast
            version (Windows)
            {
                if ( ResumeThread( m_hndl ) == -1 )
                    onThreadError( "Error resuming thread" );
            }
            else version (Posix)
            {
                // NOTE: This is also set to true by thread_entryPoint, but set it
                //       here as well so the calling thread will see the isRunning
                //       state immediately.
                atomicStore!(MemoryOrder.raw)(m_isRunning, true);
                scope( failure ) atomicStore!(MemoryOrder.raw)(m_isRunning, false);

                version (Shared)
                {
                    auto libs = externDFunc!("rt.sections_elf_shared.pinLoadedLibraries",
                                             void* function() @nogc nothrow)();

                    auto ps = cast(void**).malloc(2 * size_t.sizeof);
                    if (ps is null) onOutOfMemoryError();
                    ps[0] = cast(void*)this;
                    ps[1] = cast(void*)libs;
                    if ( pthread_create( &m_addr, &attr, &thread_entryPoint, ps ) != 0 )
                    {
                        externDFunc!("rt.sections_elf_shared.unpinLoadedLibraries",
                                     void function(void*) @nogc nothrow)(libs);
                        .free(ps);
                        onThreadError( "Error creating thread" );
                    }
                }
                else
                {
                    if ( pthread_create( &m_addr, &attr, &thread_entryPoint, cast(void*) this ) != 0 )
                        onThreadError( "Error creating thread" );
                }
                if ( pthread_attr_destroy( &attr ) != 0 )
                    onThreadError( "Error destroying thread attributes" );
            }
            version (Darwin)
            {
                m_tmach = pthread_mach_thread_np( m_addr );
                if ( m_tmach == m_tmach.init )
                    onThreadError( "Error creating thread" );
            }

            return cast(Thread) this; //FIXME cast
        }
    }

    /**
     * Waits for this thread to complete.  If the thread terminated as the
     * result of an unhandled exception, this exception will be rethrown.
     *
     * Params:
     *  rethrow = Rethrow any unhandled exception which may have caused this
     *            thread to terminate.
     *
     * Throws:
     *  ThreadException if the operation fails.
     *  Any exception not handled by the joined thread.
     *
     * Returns:
     *  Any exception not handled by this thread if rethrow = false, null
     *  otherwise.
     */
    override final Throwable join( bool rethrow = true )
    {
        version (Windows)
        {
            if ( WaitForSingleObject( m_hndl, INFINITE ) != WAIT_OBJECT_0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: m_addr must be cleared before m_hndl is closed to avoid
            //       a race condition with isRunning. The operation is done
            //       with atomicStore to prevent compiler reordering.
            atomicStore!(MemoryOrder.raw)(*cast(shared)&m_addr, m_addr.init);
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version (Posix)
        {
            if ( pthread_join( m_addr, null ) != 0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: pthread_join acts as a substitute for pthread_detach,
            //       which is normally called by the dtor.  Setting m_addr
            //       to zero ensures that pthread_detach will not be called
            //       on object destruction.
            m_addr = m_addr.init;
        }
        if ( m_unhandled )
        {
            if ( rethrow )
                throw m_unhandled;
            return m_unhandled;
        }
        return null;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Thread Priority Actions
    ///////////////////////////////////////////////////////////////////////////

    version (Windows)
    {
        @property static int PRIORITY_MIN() @nogc nothrow pure @safe
        {
            return THREAD_PRIORITY_IDLE;
        }

        @property static const(int) PRIORITY_MAX() @nogc nothrow pure @safe
        {
            return THREAD_PRIORITY_TIME_CRITICAL;
        }

        @property static int PRIORITY_DEFAULT() @nogc nothrow pure @safe
        {
            return THREAD_PRIORITY_NORMAL;
        }
    }
    else
    {
        private struct Priority
        {
            int PRIORITY_MIN = int.min;
            int PRIORITY_DEFAULT = int.min;
            int PRIORITY_MAX = int.min;
        }

        /*
        Lazily loads one of the members stored in a hidden global variable of
        type `Priority`. Upon the first access of either member, the entire
        `Priority` structure is initialized. Multiple initializations from
        different threads calling this function are tolerated.

        `which` must be one of `PRIORITY_MIN`, `PRIORITY_DEFAULT`,
        `PRIORITY_MAX`.
        */
        private static shared Priority cache;
        private static int loadGlobal(string which)()
        {
            auto local = atomicLoad(mixin("cache." ~ which));
            if (local != local.min) return local;
            // There will be benign races
            cache = loadPriorities;
            return atomicLoad(mixin("cache." ~ which));
        }

        /*
        Loads all priorities and returns them as a `Priority` structure. This
        function is thread-neutral.
        */
        private static Priority loadPriorities() @nogc nothrow @trusted
        {
            Priority result;
            version (Solaris)
            {
                pcparms_t pcParms;
                pcinfo_t pcInfo;

                pcParms.pc_cid = PC_CLNULL;
                if (priocntl(idtype_t.P_PID, P_MYID, PC_GETPARMS, &pcParms) == -1)
                    assert( 0, "Unable to get scheduling class" );

                pcInfo.pc_cid = pcParms.pc_cid;
                // PC_GETCLINFO ignores the first two args, use dummy values
                if (priocntl(idtype_t.P_PID, 0, PC_GETCLINFO, &pcInfo) == -1)
                    assert( 0, "Unable to get scheduling class info" );

                pri_t* clparms = cast(pri_t*)&pcParms.pc_clparms;
                pri_t* clinfo = cast(pri_t*)&pcInfo.pc_clinfo;

                result.PRIORITY_MAX = clparms[0];

                if (pcInfo.pc_clname == "RT")
                {
                    m_isRTClass = true;

                    // For RT class, just assume it can't be changed
                    result.PRIORITY_MIN = clparms[0];
                    result.PRIORITY_DEFAULT = clparms[0];
                }
                else
                {
                    m_isRTClass = false;

                    // For all other scheduling classes, there are
                    // two key values -- uprilim and maxupri.
                    // maxupri is the maximum possible priority defined
                    // for the scheduling class, and valid priorities
                    // range are in [-maxupri, maxupri].
                    //
                    // However, uprilim is an upper limit that the
                    // current thread can set for the current scheduling
                    // class, which can be less than maxupri.  As such,
                    // use this value for priorityMax since this is
                    // the effective maximum.

                    // maxupri
                    result.PRIORITY_MIN = -clinfo[0];
                    // by definition
                    result.PRIORITY_DEFAULT = 0;
                }
            }
            else version (Posix)
            {
                int         policy;
                sched_param param;
                pthread_getschedparam( pthread_self(), &policy, &param ) == 0
                    || assert(0, "Internal error in pthread_getschedparam");

                result.PRIORITY_MIN = sched_get_priority_min( policy );
                result.PRIORITY_MIN != -1
                    || assert(0, "Internal error in sched_get_priority_min");
                result.PRIORITY_DEFAULT = param.sched_priority;
                result.PRIORITY_MAX = sched_get_priority_max( policy );
                result.PRIORITY_MAX != -1 ||
                    assert(0, "Internal error in sched_get_priority_max");
            }
            else
            {
                static assert(0, "Your code here.");
            }
            return result;
        }

        /**
         * The minimum scheduling priority that may be set for a thread.  On
         * systems where multiple scheduling policies are defined, this value
         * represents the minimum valid priority for the scheduling policy of
         * the process.
         */
        @property static int PRIORITY_MIN() @nogc nothrow pure @trusted
        {
            return (cast(int function() @nogc nothrow pure @safe)
                &loadGlobal!"PRIORITY_MIN")();
        }

        /**
         * The maximum scheduling priority that may be set for a thread.  On
         * systems where multiple scheduling policies are defined, this value
         * represents the maximum valid priority for the scheduling policy of
         * the process.
         */
        @property static const(int) PRIORITY_MAX() @nogc nothrow pure @trusted
        {
            return (cast(int function() @nogc nothrow pure @safe)
                &loadGlobal!"PRIORITY_MAX")();
        }

        /**
         * The default scheduling priority that is set for a thread.  On
         * systems where multiple scheduling policies are defined, this value
         * represents the default priority for the scheduling policy of
         * the process.
         */
        @property static int PRIORITY_DEFAULT() @nogc nothrow pure @trusted
        {
            return (cast(int function() @nogc nothrow pure @safe)
                &loadGlobal!"PRIORITY_DEFAULT")();
        }
    }

    version (NetBSD)
    {
        //NetBSD does not support priority for default policy
        // and it is not possible change policy without root access
        int fakePriority = int.max;
    }

    /**
     * Gets the scheduling priority for the associated thread.
     *
     * Note: Getting the priority of a thread that already terminated
     * might return the default priority.
     *
     * Returns:
     *  The scheduling priority of this thread.
     */
    final @property int priority()
    {
        version (Windows)
        {
            return GetThreadPriority( m_hndl );
        }
        else version (NetBSD)
        {
           return fakePriority==int.max? PRIORITY_DEFAULT : fakePriority;
        }
        else version (Posix)
        {
            int         policy;
            sched_param param;

            if (auto err = pthread_getschedparam(m_addr, &policy, &param))
            {
                // ignore error if thread is not running => Bugzilla 8960
                if (!atomicLoad(m_isRunning)) return PRIORITY_DEFAULT;
                throw new ThreadException("Unable to get thread priority");
            }
            return param.sched_priority;
        }
    }


    /**
     * Sets the scheduling priority for the associated thread.
     *
     * Note: Setting the priority of a thread that already terminated
     * might have no effect.
     *
     * Params:
     *  val = The new scheduling priority of this thread.
     */
    final @property void priority( int val )
    in
    {
        assert(val >= PRIORITY_MIN);
        assert(val <= PRIORITY_MAX);
    }
    do
    {
        version (Windows)
        {
            if ( !SetThreadPriority( m_hndl, val ) )
                throw new ThreadException( "Unable to set thread priority" );
        }
        else version (Solaris)
        {
            // the pthread_setschedprio(3c) and pthread_setschedparam functions
            // are broken for the default (TS / time sharing) scheduling class.
            // instead, we use priocntl(2) which gives us the desired behavior.

            // We hardcode the min and max priorities to the current value
            // so this is a no-op for RT threads.
            if (m_isRTClass)
                return;

            pcparms_t   pcparm;

            pcparm.pc_cid = PC_CLNULL;
            if (priocntl(idtype_t.P_LWPID, P_MYID, PC_GETPARMS, &pcparm) == -1)
                throw new ThreadException( "Unable to get scheduling class" );

            pri_t* clparms = cast(pri_t*)&pcparm.pc_clparms;

            // clparms is filled in by the PC_GETPARMS call, only necessary
            // to adjust the element that contains the thread priority
            clparms[1] = cast(pri_t) val;

            if (priocntl(idtype_t.P_LWPID, P_MYID, PC_SETPARMS, &pcparm) == -1)
                throw new ThreadException( "Unable to set scheduling class" );
        }
        else version (NetBSD)
        {
           fakePriority = val;
        }
        else version (Posix)
        {
            static if (__traits(compiles, pthread_setschedprio))
            {
                if (auto err = pthread_setschedprio(m_addr, val))
                {
                    // ignore error if thread is not running => Bugzilla 8960
                    if (!atomicLoad(m_isRunning)) return;
                    throw new ThreadException("Unable to set thread priority");
                }
            }
            else
            {
                // NOTE: pthread_setschedprio is not implemented on Darwin, FreeBSD, OpenBSD,
                //       or DragonFlyBSD, so use the more complicated get/set sequence below.
                int         policy;
                sched_param param;

                if (auto err = pthread_getschedparam(m_addr, &policy, &param))
                {
                    // ignore error if thread is not running => Bugzilla 8960
                    if (!atomicLoad(m_isRunning)) return;
                    throw new ThreadException("Unable to set thread priority");
                }
                param.sched_priority = val;
                if (auto err = pthread_setschedparam(m_addr, policy, &param))
                {
                    // ignore error if thread is not running => Bugzilla 8960
                    if (!atomicLoad(m_isRunning)) return;
                    throw new ThreadException("Unable to set thread priority");
                }
            }
        }
    }


    unittest
    {
        auto thr = Thread.getThis();
        immutable prio = thr.priority;
        scope (exit) thr.priority = prio;

        assert(prio == PRIORITY_DEFAULT);
        assert(prio >= PRIORITY_MIN && prio <= PRIORITY_MAX);
        thr.priority = PRIORITY_MIN;
        assert(thr.priority == PRIORITY_MIN);
        thr.priority = PRIORITY_MAX;
        assert(thr.priority == PRIORITY_MAX);
    }

    unittest // Bugzilla 8960
    {
        import core.sync.semaphore;

        auto thr = new Thread({});
        thr.start();
        Thread.sleep(1.msecs);       // wait a little so the thread likely has finished
        thr.priority = PRIORITY_MAX; // setting priority doesn't cause error
        auto prio = thr.priority;    // getting priority doesn't cause error
        assert(prio >= PRIORITY_MIN && prio <= PRIORITY_MAX);
    }

    /**
     * Tests whether this thread is running.
     *
     * Returns:
     *  true if the thread is running, false if not.
     */
    override final @property bool isRunning() nothrow @nogc
    {
        if (!super.isRunning())
            return false;

        version (Windows)
        {
            uint ecode = 0;
            GetExitCodeThread( m_hndl, &ecode );
            return ecode == STILL_ACTIVE;
        }
        else version (Posix)
        {
            return atomicLoad(m_isRunning);
        }
    }
}

package /*FIXME:private*/ Thread toThread(ThreadBase t) @safe nothrow @nogc pure
{
    return cast(Thread) t;
}


private extern (C) ThreadBase attachThread(Thread thisThread) @nogc
{
    StackContext* thisContext = &thisThread.m_main;
    assert( thisContext == thisThread.m_curr );

    version (Windows)
    {
        thisThread.m_addr  = GetCurrentThreadId();
        thisThread.m_hndl  = GetCurrentThreadHandle();
        thisContext.bstack = getStackBottom();
        thisContext.tstack = thisContext.bstack;
    }
    else version (Posix)
    {
        thisThread.m_addr  = pthread_self();
        thisContext.bstack = getStackBottom();
        thisContext.tstack = thisContext.bstack;

        atomicStore!(MemoryOrder.raw)(thisThread.m_isRunning, true);
    }
    thisThread.m_isDaemon = true;
    thisThread.tlsGCdataInit();
    Thread.setThis( thisThread );

    version (Darwin)
    {
        thisThread.m_tmach = pthread_mach_thread_np( thisThread.m_addr );
        assert( thisThread.m_tmach != thisThread.m_tmach.init );
    }

    Thread.add( thisThread, false );
    Thread.add( thisContext );
    if ( Thread.sm_main !is null )
        multiThreadedFlag = true;
    return thisThread;
}


version (Windows)
{
    // NOTE: These calls are not safe on Posix systems that use signals to
    //       perform garbage collection.  The suspendHandler uses getThis()
    //       to get the thread handle so getThis() must be a simple call.
    //       Mutexes can't safely be acquired inside signal handlers, and
    //       even if they could, the mutex needed (Thread.slock) is held by
    //       thread_suspendAll().  So in short, these routines will remain
    //       Windows-specific.  If they are truly needed elsewhere, the
    //       suspendHandler will need a way to call a version of getThis()
    //       that only does the TLS lookup without the fancy fallback stuff.

    /// ditto
    extern (C) Thread thread_attachByAddr( ThreadID addr )
    {
        return thread_attachByAddrB( addr, getThreadStackBottom( addr ) );
    }


    /// ditto
    extern (C) Thread thread_attachByAddrB( ThreadID addr, void* bstack )
    {
        GC.disable(); scope(exit) GC.enable();

        if (auto t = thread_findByAddr(addr).toThread)
            return t;

        Thread        thisThread  = new Thread();
        StackContext* thisContext = &thisThread.m_main;
        assert( thisContext == thisThread.m_curr );

        thisThread.m_addr  = addr;
        thisContext.bstack = bstack;
        thisContext.tstack = thisContext.bstack;

        thisThread.m_isDaemon = true;

        if ( addr == GetCurrentThreadId() )
        {
            thisThread.m_hndl = GetCurrentThreadHandle();
            thisThread.tlsGCdataInit();
            Thread.setThis( thisThread );
        }
        else
        {
            thisThread.m_hndl = OpenThreadHandle( addr );
            impersonate_thread(addr,
            {
                thisThread.tlsGCdataInit();
                Thread.setThis( thisThread );
            });
        }

        Thread.add( thisThread, false );
        Thread.add( thisContext );
        if ( Thread.sm_main !is null )
            multiThreadedFlag = true;
        return thisThread;
    }
}


// Calls the given delegate, passing the current thread's stack pointer to it.
package void callWithStackShell(scope void delegate(void* sp) nothrow fn) nothrow
in (fn)
{
    // The purpose of the 'shell' is to ensure all the registers get
    // put on the stack so they'll be scanned. We only need to push
    // the callee-save registers.
    void *sp = void;
    version (GNU)
    {
        __builtin_unwind_init();
        sp = &sp;
    }
    else version (AsmX86_Posix)
    {
        size_t[3] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 4], EBX;
            mov [regs + 1 * 4], ESI;
            mov [regs + 2 * 4], EDI;

            mov sp[EBP], ESP;
        }
    }
    else version (AsmX86_Windows)
    {
        size_t[3] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 4], EBX;
            mov [regs + 1 * 4], ESI;
            mov [regs + 2 * 4], EDI;

            mov sp[EBP], ESP;
        }
    }
    else version (AsmX86_64_Posix)
    {
        size_t[5] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 8], RBX;
            mov [regs + 1 * 8], R12;
            mov [regs + 2 * 8], R13;
            mov [regs + 3 * 8], R14;
            mov [regs + 4 * 8], R15;

            mov sp[RBP], RSP;
        }
    }
    else version (AsmX86_64_Windows)
    {
        size_t[7] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 8], RBX;
            mov [regs + 1 * 8], RSI;
            mov [regs + 2 * 8], RDI;
            mov [regs + 3 * 8], R12;
            mov [regs + 4 * 8], R13;
            mov [regs + 5 * 8], R14;
            mov [regs + 6 * 8], R15;

            mov sp[RBP], RSP;
        }
    }
    else
    {
        static assert(false, "Architecture not supported.");
    }

    fn(sp);
}

version (GNU)
{
    import gcc.builtins;
    version (GNU_StackGrowsDown)
        public version = StackGrowsDown;
}
else
{
    // this should be true for most architectures
    public version = StackGrowsDown;
}


extern (C) @nogc nothrow
{
    version (CRuntime_Glibc)  version = PThread_Getattr_NP;
    version (CRuntime_Bionic) version = PThread_Getattr_NP;
    version (CRuntime_Musl)   version = PThread_Getattr_NP;
    version (CRuntime_UClibc) version = PThread_Getattr_NP;

    version (FreeBSD)         version = PThread_Attr_Get_NP;
    version (NetBSD)          version = PThread_Attr_Get_NP;
    version (DragonFlyBSD)    version = PThread_Attr_Get_NP;

    version (PThread_Getattr_NP)  int pthread_getattr_np(pthread_t thread, pthread_attr_t* attr);
    version (PThread_Attr_Get_NP) int pthread_attr_get_np(pthread_t thread, pthread_attr_t* attr);
    version (Solaris) int thr_stksegment(stack_t* stk);
    version (OpenBSD) int pthread_stackseg_np(pthread_t thread, stack_t* sinfo);
}


package(core.thread) void* getStackTop() nothrow @nogc
{
    version (D_InlineAsm_X86)
        asm pure nothrow @nogc { naked; mov EAX, ESP; ret; }
    else version (D_InlineAsm_X86_64)
        asm pure nothrow @nogc { naked; mov RAX, RSP; ret; }
    else version (GNU)
        return __builtin_frame_address(0);
    else
        static assert(false, "Architecture not supported.");
}


package(core.thread) void* getStackBottom() nothrow @nogc
{
    version (Windows)
    {
        version (D_InlineAsm_X86)
            asm pure nothrow @nogc { naked; mov EAX, FS:4; ret; }
        else version (D_InlineAsm_X86_64)
            asm pure nothrow @nogc
            {    naked;
                 mov RAX, 8;
                 mov RAX, GS:[RAX];
                 ret;
            }
        else
            static assert(false, "Architecture not supported.");
    }
    else version (Darwin)
    {
        import core.sys.darwin.pthread;
        return pthread_get_stackaddr_np(pthread_self());
    }
    else version (PThread_Getattr_NP)
    {
        pthread_attr_t attr;
        void* addr; size_t size;

        pthread_attr_init(&attr);
        pthread_getattr_np(pthread_self(), &attr);
        pthread_attr_getstack(&attr, &addr, &size);
        pthread_attr_destroy(&attr);
        version (StackGrowsDown)
            addr += size;
        return addr;
    }
    else version (PThread_Attr_Get_NP)
    {
        pthread_attr_t attr;
        void* addr; size_t size;

        pthread_attr_init(&attr);
        pthread_attr_get_np(pthread_self(), &attr);
        pthread_attr_getstack(&attr, &addr, &size);
        pthread_attr_destroy(&attr);
        version (StackGrowsDown)
            addr += size;
        return addr;
    }
    else version (OpenBSD)
    {
        stack_t stk;

        pthread_stackseg_np(pthread_self(), &stk);
        return stk.ss_sp;
    }
    else version (Solaris)
    {
        stack_t stk;

        thr_stksegment(&stk);
        return stk.ss_sp;
    }
    else
        static assert(false, "Platform not supported.");
}

/**
 * Suspend the specified thread and load stack and register information for
 * use by thread_scanAll.  If the supplied thread is the calling thread,
 * stack and register information will be loaded but the thread will not
 * be suspended.  If the suspend operation fails and the thread is not
 * running then it will be removed from the global thread list, otherwise
 * an exception will be thrown.
 *
 * Params:
 *  t = The thread to suspend.
 *
 * Throws:
 *  ThreadError if the suspend operation fails for a running thread.
 * Returns:
 *  Whether the thread is now suspended (true) or terminated (false).
 */
private extern (C) bool suspend( Thread t ) nothrow
{
    Duration waittime = dur!"usecs"(10);
 Lagain:
    if (!t.isRunning)
    {
        Thread.remove(t);
        return false;
    }
    else if (t.m_isInCriticalRegion)
    {
        Thread.criticalRegionLock.unlock_nothrow();
        Thread.sleep(waittime);
        if (waittime < dur!"msecs"(10)) waittime *= 2;
        Thread.criticalRegionLock.lock_nothrow();
        goto Lagain;
    }

    version (Windows)
    {
        if ( t.m_addr != GetCurrentThreadId() && SuspendThread( t.m_hndl ) == 0xFFFFFFFF )
        {
            if ( !t.isRunning )
            {
                Thread.remove( t );
                return false;
            }
            onThreadError( "Unable to suspend thread" );
        }

        CONTEXT context = void;
        context.ContextFlags = CONTEXT_INTEGER | CONTEXT_CONTROL;

        if ( !GetThreadContext( t.m_hndl, &context ) )
            onThreadError( "Unable to load thread context" );
        version (X86)
        {
            if ( !t.m_lock )
                t.m_curr.tstack = cast(void*) context.Esp;
            // eax,ebx,ecx,edx,edi,esi,ebp,esp
            t.m_reg[0] = context.Eax;
            t.m_reg[1] = context.Ebx;
            t.m_reg[2] = context.Ecx;
            t.m_reg[3] = context.Edx;
            t.m_reg[4] = context.Edi;
            t.m_reg[5] = context.Esi;
            t.m_reg[6] = context.Ebp;
            t.m_reg[7] = context.Esp;
        }
        else version (X86_64)
        {
            if ( !t.m_lock )
                t.m_curr.tstack = cast(void*) context.Rsp;
            // rax,rbx,rcx,rdx,rdi,rsi,rbp,rsp
            t.m_reg[0] = context.Rax;
            t.m_reg[1] = context.Rbx;
            t.m_reg[2] = context.Rcx;
            t.m_reg[3] = context.Rdx;
            t.m_reg[4] = context.Rdi;
            t.m_reg[5] = context.Rsi;
            t.m_reg[6] = context.Rbp;
            t.m_reg[7] = context.Rsp;
            // r8,r9,r10,r11,r12,r13,r14,r15
            t.m_reg[8]  = context.R8;
            t.m_reg[9]  = context.R9;
            t.m_reg[10] = context.R10;
            t.m_reg[11] = context.R11;
            t.m_reg[12] = context.R12;
            t.m_reg[13] = context.R13;
            t.m_reg[14] = context.R14;
            t.m_reg[15] = context.R15;
        }
        else
        {
            static assert(false, "Architecture not supported." );
        }
    }
    else version (Darwin)
    {
        if ( t.m_addr != pthread_self() && thread_suspend( t.m_tmach ) != KERN_SUCCESS )
        {
            if ( !t.isRunning )
            {
                Thread.remove( t );
                return false;
            }
            onThreadError( "Unable to suspend thread" );
        }

        version (X86)
        {
            x86_thread_state32_t    state = void;
            mach_msg_type_number_t  count = x86_THREAD_STATE32_COUNT;

            if ( thread_get_state( t.m_tmach, x86_THREAD_STATE32, &state, &count ) != KERN_SUCCESS )
                onThreadError( "Unable to load thread state" );
            if ( !t.m_lock )
                t.m_curr.tstack = cast(void*) state.esp;
            // eax,ebx,ecx,edx,edi,esi,ebp,esp
            t.m_reg[0] = state.eax;
            t.m_reg[1] = state.ebx;
            t.m_reg[2] = state.ecx;
            t.m_reg[3] = state.edx;
            t.m_reg[4] = state.edi;
            t.m_reg[5] = state.esi;
            t.m_reg[6] = state.ebp;
            t.m_reg[7] = state.esp;
        }
        else version (X86_64)
        {
            x86_thread_state64_t    state = void;
            mach_msg_type_number_t  count = x86_THREAD_STATE64_COUNT;

            if ( thread_get_state( t.m_tmach, x86_THREAD_STATE64, &state, &count ) != KERN_SUCCESS )
                onThreadError( "Unable to load thread state" );
            if ( !t.m_lock )
                t.m_curr.tstack = cast(void*) state.rsp;
            // rax,rbx,rcx,rdx,rdi,rsi,rbp,rsp
            t.m_reg[0] = state.rax;
            t.m_reg[1] = state.rbx;
            t.m_reg[2] = state.rcx;
            t.m_reg[3] = state.rdx;
            t.m_reg[4] = state.rdi;
            t.m_reg[5] = state.rsi;
            t.m_reg[6] = state.rbp;
            t.m_reg[7] = state.rsp;
            // r8,r9,r10,r11,r12,r13,r14,r15
            t.m_reg[8]  = state.r8;
            t.m_reg[9]  = state.r9;
            t.m_reg[10] = state.r10;
            t.m_reg[11] = state.r11;
            t.m_reg[12] = state.r12;
            t.m_reg[13] = state.r13;
            t.m_reg[14] = state.r14;
            t.m_reg[15] = state.r15;
        }
        else version (AArch64)
        {
            arm_thread_state64_t state = void;
            mach_msg_type_number_t count = ARM_THREAD_STATE64_COUNT;

            if (thread_get_state(t.m_tmach, ARM_THREAD_STATE64, &state, &count) != KERN_SUCCESS)
                onThreadError("Unable to load thread state");
            // TODO: ThreadException here recurses forever!  Does it
            //still using onThreadError?
            //printf("state count %d (expect %d)\n", count ,ARM_THREAD_STATE64_COUNT);
            if (!t.m_lock)
                t.m_curr.tstack = cast(void*) state.sp;

            t.m_reg[0..29] = state.x;  // x0-x28
            t.m_reg[29] = state.fp;    // x29
            t.m_reg[30] = state.lr;    // x30
            t.m_reg[31] = state.sp;    // x31
            t.m_reg[32] = state.pc;
        }
        else version (ARM)
        {
            arm_thread_state32_t state = void;
            mach_msg_type_number_t count = ARM_THREAD_STATE32_COUNT;

            // Thought this would be ARM_THREAD_STATE32, but that fails.
            // Mystery
            if (thread_get_state(t.m_tmach, ARM_THREAD_STATE, &state, &count) != KERN_SUCCESS)
                onThreadError("Unable to load thread state");
            // TODO: in past, ThreadException here recurses forever!  Does it
            //still using onThreadError?
            //printf("state count %d (expect %d)\n", count ,ARM_THREAD_STATE32_COUNT);
            if (!t.m_lock)
                t.m_curr.tstack = cast(void*) state.sp;

            t.m_reg[0..13] = state.r;  // r0 - r13
            t.m_reg[13] = state.sp;
            t.m_reg[14] = state.lr;
            t.m_reg[15] = state.pc;
        }
        else
        {
            static assert(false, "Architecture not supported." );
        }
    }
    else version (Posix)
    {
        if ( t.m_addr != pthread_self() )
        {
            if ( pthread_kill( t.m_addr, suspendSignalNumber ) != 0 )
            {
                if ( !t.isRunning )
                {
                    Thread.remove( t );
                    return false;
                }
                onThreadError( "Unable to suspend thread" );
            }
        }
        else if ( !t.m_lock )
        {
            t.m_curr.tstack = getStackTop();
        }
    }
    return true;
}

/**
 * Resume the specified thread and unload stack and register information.
 * If the supplied thread is the calling thread, stack and register
 * information will be unloaded but the thread will not be resumed.  If
 * the resume operation fails and the thread is not running then it will
 * be removed from the global thread list, otherwise an exception will be
 * thrown.
 *
 * Params:
 *  t = The thread to resume.
 *
 * Throws:
 *  ThreadError if the resume fails for a running thread.
 */
private extern (C) void resume( Thread t ) nothrow
{
    version (Windows)
    {
        if ( t.m_addr != GetCurrentThreadId() && ResumeThread( t.m_hndl ) == 0xFFFFFFFF )
        {
            if ( !t.isRunning )
            {
                Thread.remove( t );
                return;
            }
            onThreadError( "Unable to resume thread" );
        }

        if ( !t.m_lock )
            t.m_curr.tstack = t.m_curr.bstack;
        t.m_reg[0 .. $] = 0;
    }
    else version (Darwin)
    {
        if ( t.m_addr != pthread_self() && thread_resume( t.m_tmach ) != KERN_SUCCESS )
        {
            if ( !t.isRunning )
            {
                Thread.remove( t );
                return;
            }
            onThreadError( "Unable to resume thread" );
        }

        if ( !t.m_lock )
            t.m_curr.tstack = t.m_curr.bstack;
        t.m_reg[0 .. $] = 0;
    }
    else version (Posix)
    {
        if ( t.m_addr != pthread_self() )
        {
            if ( pthread_kill( t.m_addr, resumeSignalNumber ) != 0 )
            {
                if ( !t.isRunning )
                {
                    Thread.remove( t );
                    return;
                }
                onThreadError( "Unable to resume thread" );
            }
        }
        else if ( !t.m_lock )
        {
            t.m_curr.tstack = t.m_curr.bstack;
        }
    }
}


/**
 * Initializes the thread module.  This function must be called by the
 * garbage collector on startup and before any other thread routines
 * are called.
 */
extern (C) void thread_init() @nogc
{
    // NOTE: If thread_init itself performs any allocations then the thread
    //       routines reserved for garbage collector use may be called while
    //       thread_init is being processed.  However, since no memory should
    //       exist to be scanned at this point, it is sufficient for these
    //       functions to detect the condition and return immediately.

    initLowlevelThreads();
    Thread.initLocks();

    // The Android VM runtime intercepts SIGUSR1 and apparently doesn't allow
    // its signal handler to run, so swap the two signals on Android, since
    // thread_resumeHandler does nothing.
    version (Android) thread_setGCSignals(SIGUSR2, SIGUSR1);

    version (Darwin)
    {
        // thread id different in forked child process
        static extern(C) void initChildAfterFork()
        {
            auto thisThread = Thread.getThis();
            thisThread.m_addr = pthread_self();
            assert( thisThread.m_addr != thisThread.m_addr.init );
            thisThread.m_tmach = pthread_mach_thread_np( thisThread.m_addr );
            assert( thisThread.m_tmach != thisThread.m_tmach.init );
       }
        pthread_atfork(null, null, &initChildAfterFork);
    }
    else version (Posix)
    {
        if ( suspendSignalNumber == 0 )
        {
            suspendSignalNumber = SIGUSR1;
        }

        if ( resumeSignalNumber == 0 )
        {
            resumeSignalNumber = SIGUSR2;
        }

        int         status;
        sigaction_t sigusr1 = void;
        sigaction_t sigusr2 = void;

        // This is a quick way to zero-initialize the structs without using
        // memset or creating a link dependency on their static initializer.
        (cast(byte*) &sigusr1)[0 .. sigaction_t.sizeof] = 0;
        (cast(byte*) &sigusr2)[0 .. sigaction_t.sizeof] = 0;

        // NOTE: SA_RESTART indicates that system calls should restart if they
        //       are interrupted by a signal, but this is not available on all
        //       Posix systems, even those that support multithreading.
        static if ( __traits( compiles, SA_RESTART ) )
            sigusr1.sa_flags = SA_RESTART;
        else
            sigusr1.sa_flags   = 0;
        sigusr1.sa_handler = &thread_suspendHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr1.sa_mask );
        assert( status == 0 );

        // NOTE: Since resumeSignalNumber should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        sigusr2.sa_flags   = 0;
        sigusr2.sa_handler = &thread_resumeHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr2.sa_mask );
        assert( status == 0 );

        status = sigaction( suspendSignalNumber, &sigusr1, null );
        assert( status == 0 );

        status = sigaction( resumeSignalNumber, &sigusr2, null );
        assert( status == 0 );

        status = sem_init( &suspendCount, 0, 0 );
        assert( status == 0 );
    }
    if (typeid(Thread).initializer.ptr)
        _mainThreadStore[] = typeid(Thread).initializer[];
    Thread.sm_main = attachThread((cast(Thread)_mainThreadStore.ptr).__ctor());
}

package __gshared align(Thread.alignof) void[__traits(classInstanceSize, Thread)] _mainThreadStore;


///////////////////////////////////////////////////////////////////////////////
// Thread Entry Point and Signal Handlers
///////////////////////////////////////////////////////////////////////////////


version (Windows)
{
    //~ private //FIXME
    version (all)
    {
        //
        // Entry point for Windows threads
        //
        extern (Windows) uint thread_entryPoint( void* arg ) nothrow
        {
            Thread  obj = cast(Thread) arg;
            assert( obj );

            obj.dataStorageInit();

            Thread.setThis(obj);
            Thread.add(obj);
            scope (exit)
            {
                Thread.remove(obj);
                obj.dataStorageDestroy();
            }
            Thread.add(&obj.m_main);

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and Thread.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Windows but it should be followed for the
            //       sake of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            void append( Throwable t )
            {
                obj.m_unhandled = Throwable.chainTogether(obj.m_unhandled, t);
            }

            version (D_InlineAsm_X86)
            {
                asm nothrow @nogc { fninit; }
            }

            try
            {
                rt_moduleTlsCtor();
                try
                {
                    obj.run();
                }
                catch ( Throwable t )
                {
                    append( t );
                }
                rt_moduleTlsDtor();
            }
            catch ( Throwable t )
            {
                append( t );
            }
            return 0;
        }


        HANDLE GetCurrentThreadHandle() nothrow @nogc
        {
            const uint DUPLICATE_SAME_ACCESS = 0x00000002;

            HANDLE curr = GetCurrentThread(),
                   proc = GetCurrentProcess(),
                   hndl;

            DuplicateHandle( proc, curr, proc, &hndl, 0, TRUE, DUPLICATE_SAME_ACCESS );
            return hndl;
        }
    }
}
else version (Posix)
{
    //~ private //FIXME
    version (all)
    {
        import core.stdc.errno;
        import core.sys.posix.semaphore;
        import core.sys.posix.stdlib; // for malloc, valloc, free, atexit
        import core.sys.posix.pthread;
        import core.sys.posix.signal;
        import core.sys.posix.time;

        version (Darwin)
        {
            import core.sys.darwin.mach.thread_act;
            import core.sys.darwin.pthread : pthread_mach_thread_np;
        }

        //
        // Entry point for POSIX threads
        //
        extern (C) void* thread_entryPoint( void* arg ) nothrow
        {
            version (Shared)
            {
                Thread obj = cast(Thread)(cast(void**)arg)[0];
                auto loadedLibraries = (cast(void**)arg)[1];
                .free(arg);
            }
            else
            {
                Thread obj = cast(Thread)arg;
            }
            assert( obj );

            // loadedLibraries need to be inherited from parent thread
            // before initilizing GC for TLS (rt_tlsgc_init)
            version (Shared)
            {
                externDFunc!("rt.sections_elf_shared.inheritLoadedLibraries",
                             void function(void*) @nogc nothrow)(loadedLibraries);
            }

            obj.dataStorageInit();

            atomicStore!(MemoryOrder.raw)(obj.m_isRunning, true);
            Thread.setThis(obj); // allocates lazy TLS (see Issue 11981)
            Thread.add(obj);     // can only receive signals from here on
            scope (exit)
            {
                Thread.remove(obj);
                atomicStore!(MemoryOrder.raw)(obj.m_isRunning, false);
                obj.dataStorageDestroy();
            }
            Thread.add(&obj.m_main);

            static extern (C) void thread_cleanupHandler( void* arg ) nothrow @nogc
            {
                Thread  obj = cast(Thread) arg;
                assert( obj );

                // NOTE: If the thread terminated abnormally, just set it as
                //       not running and let thread_suspendAll remove it from
                //       the thread list.  This is safer and is consistent
                //       with the Windows thread code.
                atomicStore!(MemoryOrder.raw)(obj.m_isRunning,false);
            }

            // NOTE: Using void to skip the initialization here relies on
            //       knowledge of how pthread_cleanup is implemented.  It may
            //       not be appropriate for all platforms.  However, it does
            //       avoid the need to link the pthread module.  If any
            //       implementation actually requires default initialization
            //       then pthread_cleanup should be restructured to maintain
            //       the current lack of a link dependency.
            static if ( __traits( compiles, pthread_cleanup ) )
            {
                pthread_cleanup cleanup = void;
                cleanup.push( &thread_cleanupHandler, cast(void*) obj );
            }
            else static if ( __traits( compiles, pthread_cleanup_push ) )
            {
                pthread_cleanup_push( &thread_cleanupHandler, cast(void*) obj );
            }
            else
            {
                static assert( false, "Platform not supported." );
            }

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and Thread.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Windows but it should be followed for the
            //       sake of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            void append( Throwable t )
            {
                obj.m_unhandled = Throwable.chainTogether(obj.m_unhandled, t);
            }
            try
            {
                rt_moduleTlsCtor();
                try
                {
                    obj.run();
                }
                catch ( Throwable t )
                {
                    append( t );
                }
                rt_moduleTlsDtor();
                version (Shared)
                {
                    externDFunc!("rt.sections_elf_shared.cleanupLoadedLibraries",
                                 void function() @nogc nothrow)();
                }
            }
            catch ( Throwable t )
            {
                append( t );
            }

            // NOTE: Normal cleanup is handled by scope(exit).

            static if ( __traits( compiles, pthread_cleanup ) )
            {
                cleanup.pop( 0 );
            }
            else static if ( __traits( compiles, pthread_cleanup_push ) )
            {
                pthread_cleanup_pop( 0 );
            }

            return null;
        }


        //
        // Used to track the number of suspended threads
        //
        __gshared sem_t suspendCount;


        extern (C) void thread_suspendHandler( int sig ) nothrow
        in
        {
            assert( sig == suspendSignalNumber );
        }
        do
        {
            void op(void* sp) nothrow
            {
                // NOTE: Since registers are being pushed and popped from the
                //       stack, any other stack data used by this function should
                //       be gone before the stack cleanup code is called below.
                Thread obj = Thread.getThis();
                assert(obj !is null);

                if ( !obj.m_lock )
                {
                    obj.m_curr.tstack = getStackTop();
                }

                sigset_t    sigres = void;
                int         status;

                status = sigfillset( &sigres );
                assert( status == 0 );

                status = sigdelset( &sigres, resumeSignalNumber );
                assert( status == 0 );

                version (FreeBSD) obj.m_suspendagain = false;
                status = sem_post( &suspendCount );
                assert( status == 0 );

                sigsuspend( &sigres );

                if ( !obj.m_lock )
                {
                    obj.m_curr.tstack = obj.m_curr.bstack;
                }
            }

            // avoid deadlocks on FreeBSD, see Issue 13416
            version (FreeBSD)
            {
                auto obj = Thread.getThis();
                if (THR_IN_CRITICAL(obj.m_addr))
                {
                    obj.m_suspendagain = true;
                    if (sem_post(&suspendCount)) assert(0);
                    return;
                }
            }

            callWithStackShell(&op);
        }


        extern (C) void thread_resumeHandler( int sig ) nothrow
        in
        {
            assert( sig == resumeSignalNumber );
        }
        do
        {

        }

        // HACK libthr internal (thr_private.h) macro, used to
        // avoid deadlocks in signal handler, see Issue 13416
        version (FreeBSD) bool THR_IN_CRITICAL(pthread_t p) nothrow @nogc
        {
            import core.sys.posix.config : c_long;
            import core.sys.posix.sys.types : lwpid_t;

            // If the begin of pthread would be changed in libthr (unlikely)
            // we'll run into undefined behavior, compare with thr_private.h.
            static struct pthread
            {
                c_long tid;
                static struct umutex { lwpid_t owner; uint flags; uint[2] ceilings; uint[4] spare; }
                umutex lock;
                uint cycle;
                int locklevel;
                int critical_count;
                // ...
            }
            auto priv = cast(pthread*)p;
            return priv.locklevel > 0 || priv.critical_count > 0;
        }
    }
}
else
{
    // NOTE: This is the only place threading versions are checked.  If a new
    //       version is added, the module code will need to be searched for
    //       places where version-specific code may be required.  This can be
    //       easily accomlished by searching for 'Windows' or 'Posix'.
    static assert( false, "Unknown threading implementation." );
}

    //
    // exposed by compiler runtime
    //
    extern (C) void  rt_moduleTlsCtor();
    extern (C) void  rt_moduleTlsDtor();
