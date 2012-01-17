/**
 * The thread module provides support for thread creation and management.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly, Walter Bright
 * Source:    $(DRUNTIMESRC core/internal/_thread/thread.d)
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 * Source: $(LINK http://www.dsource.org/projects/druntime/browser/trunk/src/core/thread.d)
 */
module core.internal.thread; // definition of

// this should be true for most architectures
version = StackGrowsDown;

import core.time; // for Duration

version(Posix)
{
    import core.sys.posix.sys.types;
    alias pthread_key_t TLSKey;
    alias pthread_t     ThreadAddr;
    static import core.sys.posix.unistd;
    alias core.sys.posix.unistd.getpid getpid;
}
else version (Windows)
{
    static import core.sys.windows.windows;
    alias core.sys.windows.windows.GetCurrentProcessId getpid;
    alias uint TLSKey;
    alias uint ThreadAddr;
}


///////////////////////////////////////////////////////////////////////////////
// Thread and Fiber Exceptions
///////////////////////////////////////////////////////////////////////////////


/**
 * Base class for thread exceptions.
 */
class ThreadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

/**
 * Base class for fiber exceptions.
 */
class FiberException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}


private
{
    import core.sync.mutex;

    //
    // from core.memory
    //
    extern (C) void  gc_enable();
    extern (C) void  gc_disable();
    extern (C) void* gc_malloc(size_t sz, uint ba = 0);

    //
    // from core.stdc.string
    //
    extern (C) void* memcpy(void*, const void*, size_t);

    //
    // exposed by compiler runtime
    //
    extern (C) void* rt_stackBottom();
    extern (C) void* rt_stackTop();
    extern (C) void  rt_moduleTlsCtor();
    extern (C) void  rt_moduleTlsDtor();
    extern (C) void  rt_processGCMarks(void[]);


    void* getStackBottom()
    {
        return rt_stackBottom();
    }


    void* getStackTop()
    {
        return rt_stackTop();
    }
}

///////////////////////////////////////////////////////////////////////////////
// Thread Entry Point and Signal Handlers
///////////////////////////////////////////////////////////////////////////////


version( Windows )
{
    private
    {
        import core.stdc.stdint : uintptr_t; // for _beginthreadex decl below
        import core.stdc.stdlib;             // for malloc
        import core.sys.windows.windows;
        import core.sys.windows.threadaux;   // for OpenThreadHandle

        const DWORD TLS_OUT_OF_INDEXES  = 0xFFFFFFFF;

        extern (Windows) alias uint function(void*) btex_fptr;
        extern (C) uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*);

        version( DigitalMars )
        {
            // NOTE: The memory between the addresses of _tlsstart and _tlsend
            //       is the storage for thread-local data in D 2.0.  Both of
            //       these are defined in dm\src\win32\tlsseg.asm by DMC.
            extern (C)
            {
                extern int _tlsstart;
                extern int _tlsend;
            }
        }
        else
        {
            __gshared int   _tlsstart;
            alias _tlsstart _tlsend;
        }


        //
        // Entry point for Windows threads
        //
        extern (Windows) uint thread_entryPoint( void* arg )
        {
            ThreadImpl obj = cast(ThreadImpl) arg;
            assert( obj );

            assert( obj.m_curr is &obj.m_main );
            obj.m_main.bstack = getStackBottom();
            obj.m_main.tstack = obj.m_main.bstack;

            void* pstart = cast(void*) &_tlsstart;
            void* pend   = cast(void*) &_tlsend;
            obj.m_tls = pstart[0 .. pend - pstart];

            ThreadImpl.setThis( obj );
            //ThreadImpl.add( obj );
            scope( exit )
            {
                ThreadImpl.remove( obj );
            }
            ThreadImpl.add( &obj.m_main );

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and ThreadImpl.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Windows but it should be followed for the
            //       sake of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            void append( Throwable t )
            {
                if( obj.m_unhandled is null )
                    obj.m_unhandled = t;
                else
                {
                    Throwable last = obj.m_unhandled;
                    while( last.next !is null )
                        last = last.next;
                    last.next = t;
                }
            }

            version( D_InlineAsm_X86 )
            {
                asm { fninit; }
            }

            try
            {
                rt_moduleTlsCtor();
                try
                {
                    obj.run();
                }
                catch( Throwable t )
                {
                    append( t );
                }
                rt_moduleTlsDtor();
            }
            catch( Throwable t )
            {
                append( t );
            }
            return 0;
        }


        HANDLE GetCurrentThreadHandle()
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
else version( Posix )
{
    private
    {
        import core.stdc.errno;
        import core.sys.posix.semaphore;
        import core.sys.posix.stdlib; // for malloc, valloc, free
        import core.sys.posix.pthread;
        import core.sys.posix.signal;
        import core.sys.posix.time;

        version( OSX )
        {
            import core.sys.osx.mach.thread_act;
            extern (C) mach_port_t pthread_mach_thread_np(pthread_t);
        }

        version( GNU )
        {
            import gcc.builtins;
        }

        version( DigitalMars )
        {
            version( linux )
            {
                extern (C)
                {
                    extern int _tlsstart;
                    extern int _tlsend;
                }
            }
            else version( OSX )
            {
                extern (C)
                {
                    extern __gshared
                    {
                        void* _tls_beg;
                        void* _tls_end;
                    }
                }
            }
            else version( FreeBSD )
            {
                extern (C)
                {
                    extern void* _tlsstart;
                    extern void* _tlsend;
                }
            }
            else
            {
                __gshared int   _tlsstart;
                alias _tlsstart _tlsend;
            }
        }
        else
        {
            __gshared int   _tlsstart;
            alias _tlsstart _tlsend;
        }


        //
        // Entry point for POSIX threads
        //
        extern (C) void* thread_entryPoint( void* arg )
        {
            ThreadImpl obj = cast(ThreadImpl) arg;
            assert( obj );

            assert( obj.m_curr is &obj.m_main );
            // NOTE: For some reason this does not always work for threads.
            //obj.m_main.bstack = getStackBottom();
            version( D_InlineAsm_X86 )
            {
                static void* getBasePtr()
                {
                    asm
                    {
                        naked;
                        mov EAX, EBP;
                        ret;
                    }
                }

                obj.m_main.bstack = getBasePtr();
            }
            else version( D_InlineAsm_X86_64 )
            {
                static void* getBasePtr()
                {
                    asm
                    {
                        naked;
                        mov RAX, RBP;
                        ret;
                    }
                }

                obj.m_main.bstack = getBasePtr();
            }
            else version( StackGrowsDown )
                obj.m_main.bstack = &obj + 1;
            else
                obj.m_main.bstack = &obj;
            obj.m_main.tstack = obj.m_main.bstack;

            version( OSX )
            {
                // NOTE: OSX does not support TLS, so we do it ourselves.  The TLS
                //       data output by the compiler is bracketed by _tls_beg and
                //       _tls_end, so make a copy of it for each thread.
                const sz = cast(void*) &_tls_end - cast(void*) &_tls_beg;
                auto p = malloc( sz );
                assert( p );
                obj.m_tls = p[0 .. sz];
                memcpy( p, &_tls_beg, sz );
                scope (exit) { free( p ); obj.m_tls = null; }
            }
            else
            {
                auto pstart = cast(void*) &_tlsstart;
                auto pend   = cast(void*) &_tlsend;
                obj.m_tls = pstart[0 .. pend - pstart];
            }

            obj.m_isRunning = true;
            ThreadImpl.setThis( obj );
            //ThreadImpl.add( obj );
            scope( exit )
            {
                // NOTE: isRunning should be set to false after the thread is
                //       removed or a double-removal could occur between this
                //       function and thread_suspendAll.
                ThreadImpl.remove( obj );
                obj.m_isRunning = false;
            }
            ThreadImpl.add( &obj.m_main );

            static extern (C) void thread_cleanupHandler( void* arg )
            {
                ThreadImpl obj = cast(ThreadImpl) arg;
                assert( obj );

                // NOTE: If the thread terminated abnormally, just set it as
                //       not running and let thread_suspendAll remove it from
                //       the thread list.  This is safer and is consistent
                //       with the Windows thread code.
                obj.m_isRunning = false;
            }

            // NOTE: Using void to skip the initialization here relies on
            //       knowledge of how pthread_cleanup is implemented.  It may
            //       not be appropriate for all platforms.  However, it does
            //       avoid the need to link the pthread module.  If any
            //       implementation actually requires default initialization
            //       then pthread_cleanup should be restructured to maintain
            //       the current lack of a link dependency.
            static if( __traits( compiles, pthread_cleanup ) )
            {
                pthread_cleanup cleanup = void;
                cleanup.push( &thread_cleanupHandler, cast(void*) obj );
            }
            else static if( __traits( compiles, pthread_cleanup_push ) )
            {
                pthread_cleanup_push( &thread_cleanupHandler, cast(void*) obj );
            }
            else
            {
                static assert( false, "Platform not supported." );
            }

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and ThreadImpl.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Windows but it should be followed for the
            //       sake of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            void append( Throwable t )
            {
                if( obj.m_unhandled is null )
                    obj.m_unhandled = t;
                else
                {
                    Throwable last = obj.m_unhandled;
                    while( last.next !is null )
                        last = last.next;
                    last.next = t;
                }
            }

            try
            {
                rt_moduleTlsCtor();
                try
                {
                    obj.run();
                }
                catch( Throwable t )
                {
                    append( t );
                }
                rt_moduleTlsDtor();
            }
            catch( Throwable t )
            {
                append( t );
            }

            // NOTE: Normal cleanup is handled by scope(exit).

            static if( __traits( compiles, pthread_cleanup ) )
            {
                cleanup.pop( 0 );
            }
            else static if( __traits( compiles, pthread_cleanup_push ) )
            {
                pthread_cleanup_pop( 0 );
            }

            return null;
        }


        //
        // Used to track the number of suspended threads
        //
        __gshared sem_t suspendCount;


        extern (C) void thread_suspendHandler( int sig )
        in
        {
            assert( sig == SIGUSR1 );
        }
        body
        {
            version( D_InlineAsm_X86 )
            {
                asm
                {
                    pushad;
                }
            }
            else version ( D_InlineAsm_X86_64 )
            {
                asm
                {
                    // Not sure what goes here, pushad is invalid in 64 bit code
                    push RAX ;
                    push RBX ;
                    push RCX ;
                    push RDX ;
                    push RSI ;
                    push RDI ;
                    push RBP ;
                    push R8  ;
                    push R9  ;
                    push R10 ;
                    push R11 ;
                    push R12 ;
                    push R13 ;
                    push R14 ;
                    push R15 ;
                    push RAX ;   // 16 byte align the stack
                }
            }
            else version( GNU )
            {
                __builtin_unwind_init();
            }
            else
            {
                static assert( false, "Architecture not supported." );
            }

            // NOTE: Since registers are being pushed and popped from the
            //       stack, any other stack data used by this function should
            //       be gone before the stack cleanup code is called below.
            {
                ThreadImpl obj = ThreadImpl.getThis();

                // NOTE: The thread reference returned by getThis is set within
                //       the thread startup code, so it is possible that this
                //       handler may be called before the reference is set.  In
                //       this case it is safe to simply suspend and not worry
                //       about the stack pointers as the thread will not have
                //       any references to GC-managed data.
                if( obj && !obj.m_lock )
                {
                    obj.m_curr.tstack = getStackTop();
                }

                sigset_t    sigres = void;
                int         status;

                status = sigfillset( &sigres );
                assert( status == 0 );

                status = sigdelset( &sigres, SIGUSR2 );
                assert( status == 0 );

                status = sem_post( &suspendCount );
                assert( status == 0 );

                sigsuspend( &sigres );

                if( obj && !obj.m_lock )
                {
                    obj.m_curr.tstack = obj.m_curr.bstack;
                }
            }

            version( D_InlineAsm_X86 )
            {
                asm
                {
                    popad;
                }
            }
            else version ( D_InlineAsm_X86_64 )
            {
                asm
                {
                    // Not sure what goes here, popad is invalid in 64 bit code
                    pop RAX ;   // 16 byte align the stack
                    pop R15 ;
                    pop R14 ;
                    pop R13 ;
                    pop R12 ;
                    pop R11 ;
                    pop R10 ;
                    pop R9  ;
                    pop R8  ;
                    pop RBP ;
                    pop RDI ;
                    pop RSI ;
                    pop RDX ;
                    pop RCX ;
                    pop RBX ;
                    pop RAX ;
                }
            }
            else version( GNU )
            {
                // registers will be popped automatically
            }
            else
            {
                static assert( false, "Architecture not supported." );
            }
        }


        extern (C) void thread_resumeHandler( int sig )
        in
        {
            assert( sig == SIGUSR2 );
        }
        body
        {

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


///////////////////////////////////////////////////////////////////////////////
// ThreadImpl
///////////////////////////////////////////////////////////////////////////////


final class ThreadImpl
{
    static ThreadImpl create(Object obj, void function() fn, size_t sz)
    {
        auto p = create(obj);
        p.m_fn = fn;
        p.m_sz = sz;
        p.m_call = Call.FN;
        return p;
    }

    static ThreadImpl create(Object obj, void delegate() dg, size_t sz)
    {
        auto p = create(obj);
        p.m_dg = dg;
        p.m_sz = sz;
        p.m_call = Call.DG;
        return p;
    }

    void finalize()
    {
        if( m_addr == m_addr.init )
        {
            return;
        }

        version( Windows )
        {
            m_addr = m_addr.init;
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version( Posix )
        {
            pthread_detach( m_addr );
            m_addr = m_addr.init;
        }
        version( OSX )
        {
            m_tmach = m_tmach.init;
        }
    }

    void start()
    {
        assert( !next && !prev );

        auto wasThreaded  = multiThreadedFlag;
        multiThreadedFlag = true;
        scope( failure )
        {
            if( !wasThreaded )
                multiThreadedFlag = false;
        }

        version( Windows ) {} else
        version( Posix )
        {
            pthread_attr_t  attr;

            if( pthread_attr_init( &attr ) )
                throw new ThreadException( "Error initializing thread attributes" );
            if( m_sz && pthread_attr_setstacksize( &attr, m_sz ) )
                throw new ThreadException( "Error initializing thread stack size" );
            if( pthread_attr_setdetachstate( &attr, PTHREAD_CREATE_JOINABLE ) )
                throw new ThreadException( "Error setting thread joinable" );
        }

        // NOTE: The starting thread must be added to the global thread list
        //       here rather than within thread_entryPoint to prevent a race
        //       with the main thread, which could finish and terminat the
        //       app without ever knowing that it should have waited for this
        //       starting thread.  In effect, not doing the add here risks
        //       having thread being treated like a daemon thread.
        synchronized( slock )
        {
            version( Windows )
            {
                assert(m_sz <= uint.max, "m_sz must be less than or equal to uint.max");
                m_hndl = cast(HANDLE) _beginthreadex( null, cast(uint) m_sz, &thread_entryPoint, cast(void*) this, 0, &m_addr );
                if( cast(size_t) m_hndl == 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            else version( Posix )
            {
                // NOTE: This is also set to true by thread_entryPoint, but set it
                //       here as well so the calling thread will see the isRunning
                //       state immediately.
                m_isRunning = true;
                scope( failure ) m_isRunning = false;

                if( pthread_create( &m_addr, &attr, &thread_entryPoint, cast(void*) this ) != 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            version( OSX )
            {
                m_tmach = pthread_mach_thread_np( m_addr );
                if( m_tmach == m_tmach.init )
                    throw new ThreadException( "Error creating thread" );
            }
            // NOTE: DllMain(THREAD_ATTACH) may be called before this call
            //       exits, and this in turn calls ThreadImpl.findByAddr, which
            //       would expect this thread to be in the global list if it
            //       is a D-created thread.  However, since ThreadImpl.findByAddr
            //       acquires ThreadImpl.slock before searching the list, it is
            //       safe to add this thread after _beginthreadex instead
            //       of before.  This also saves us from having to use a
            //       scope statement to remove the thread on error.
            add(this);
        }
    }

    Throwable join(bool rethrow)
    {

        version( Windows )
        {
            if( WaitForSingleObject( m_hndl, INFINITE ) != WAIT_OBJECT_0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: m_addr must be cleared before m_hndl is closed to avoid
            //       a race condition with isRunning.  The operation is labeled
            //       volatile to prevent compiler reordering.
            volatile m_addr = m_addr.init;
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version( Posix )
        {
            if( pthread_join( m_addr, null ) != 0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: pthread_join acts as a substitute for pthread_detach,
            //       which is normally called by the dtor.  Setting m_addr
            //       to zero ensures that pthread_detach will not be called
            //       on object destruction.
            volatile m_addr = m_addr.init;
        }
        if( m_unhandled )
        {
            if( rethrow )
                throw m_unhandled;
            return m_unhandled;
        }
        return null;
    }

    @property string name()
    {
        synchronized(m_owner)
        {
            return m_name;
        }
    }

    @property void name(string val)
    {
        synchronized(m_owner)
        {
            m_name = val;
        }
    }

    @property bool isDaemon()
    {
        synchronized(m_owner)
        {
            return m_isDaemon;
        }
    }

    @property void isDaemon(bool val)
    {
        synchronized(m_owner)
        {
            m_isDaemon = val;
        }
    }

    @property bool isRunning()
    {
        if( m_addr == m_addr.init )
        {
            return false;
        }

        version( Windows )
        {
            uint ecode = 0;
            GetExitCodeThread( m_hndl, &ecode );
            return ecode == STILL_ACTIVE;
        }
        else version( Posix )
        {
            // NOTE: It should be safe to access this value without
            //       memory barriers because word-tearing and such
            //       really isn't an issue for boolean values.
            return m_isRunning;
        }
    }

    /**
     * The minimum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the minimum valid priority for the scheduling policy of
     * the process.
     */
    __gshared const int PRIORITY_MIN;

    static @property int minPriority()
    {
        return PRIORITY_MIN;
    }

    /**
     * The maximum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the minimum valid priority for the scheduling policy of
     * the process.
     */
    __gshared const int PRIORITY_MAX;

    static @property int maxPriority()
    {
        return PRIORITY_MAX;
    }

    @property int priority()
    {
        version( Windows )
        {
            return GetThreadPriority( m_hndl );
        }
        else version( Posix )
        {
            int         policy;
            sched_param param;

            if( pthread_getschedparam( m_addr, &policy, &param ) )
                throw new ThreadException( "Unable to get thread priority" );
            return param.sched_priority;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Static Initalizer
    ///////////////////////////////////////////////////////////////////////////


    /**
     * This initializer is used to set thread constants.  All functional
     * initialization occurs within thread_init().
     */
    shared static this()
    {
        version( Windows )
        {
            PRIORITY_MIN = -15;
            PRIORITY_MAX =  15;
        }
        else version( Posix )
        {
            int         policy;
            sched_param param;
            pthread_t   self = pthread_self();

            int status = pthread_getschedparam( self, &policy, &param );
            assert( status == 0 );

            PRIORITY_MIN = sched_get_priority_min( policy );
            assert( PRIORITY_MIN != -1 );

            PRIORITY_MAX = sched_get_priority_max( policy );
            assert( PRIORITY_MAX != -1 );
        }
    }

    @property void priority(int val)
    {
        version( Windows )
        {
            if( !SetThreadPriority( m_hndl, val ) )
                throw new ThreadException( "Unable to set thread priority" );
        }
        else version( Posix )
        {
            // NOTE: pthread_setschedprio is not implemented on linux, so use
            //       the more complicated get/set sequence below.
            //if( pthread_setschedprio( m_addr, val ) )
            //    throw new ThreadException( "Unable to set thread priority" );

            int         policy;
            sched_param param;

            if( pthread_getschedparam( m_addr, &policy, &param ) )
                throw new ThreadException( "Unable to set thread priority" );
            param.sched_priority = val;
            if( pthread_setschedparam( m_addr, policy, &param ) )
                throw new ThreadException( "Unable to set thread priority" );
        }
    }

    static void sleep(Duration val)
    {
        version( Windows )
        {
            auto maxSleepMillis = dur!("msecs")( uint.max - 1 );

            // NOTE: In instances where all other threads in the process have a
            //       lower priority than the current thread, the current thread
            //       will not yield with a sleep time of zero.  However, unlike
            //       yield(), the user is not asking for a yield to occur but
            //       only for execution to suspend for the requested interval.
            //       Therefore, expected performance may not be met if a yield
            //       is forced upon the user.
            while( val > maxSleepMillis )
            {
                Sleep( cast(uint)
                       maxSleepMillis.total!("msecs")() );
                val -= maxSleepMillis;
            }
            Sleep( cast(uint) val.total!("msecs")() );
        }
        else version( Posix )
        {
            timespec tin  = void;
            timespec tout = void;

            if( val.total!("seconds")() > tin.tv_sec.max )
            {
                tin.tv_sec  = tin.tv_sec.max;
                tin.tv_nsec = cast(typeof(tin.tv_nsec)) val.fracSec.nsecs;
            }
            else
            {
                tin.tv_sec  = cast(typeof(tin.tv_sec)) val.total!("seconds")();
                tin.tv_nsec = cast(typeof(tin.tv_nsec)) val.fracSec.nsecs;
            }
            while( true )
            {
                if( !nanosleep( &tin, &tout ) )
                    return;
                if( getErrno() != EINTR )
                    throw new ThreadException( "Unable to sleep for the specified duration" );
                tin = tout;
            }
        }
    }

    static void yield()
    {
        version( Windows )
        {
            // NOTE: Sleep(1) is necessary because Sleep(0) does not give
            //       lower priority threads any timeslice, so looping on
            //       Sleep(0) could be resource-intensive in some cases.
            Sleep( 1 );
        }
        else version( Posix )
        {
            sched_yield();
        }
    }

    static Object getOwner()
    {
        return getThis().m_owner;
    }

    static ThreadImpl getThis()
    {
        // NOTE: This function may not be called until thread_init has
        //       completed.  See thread_suspendAll for more information
        //       on why this might occur.
        version( Windows )
        {
            auto t = cast(ThreadImpl) TlsGetValue( sm_this );

            // NOTE: If this thread was attached via thread_attachByAddr then
            //       this TLS lookup won't initially be set, so when the TLS
            //       lookup fails, try an exhaustive search.
            if( t is null )
            {
                t = ThreadImpl.findByAddr( GetCurrentThreadId() );
                setThis( t );
            }
            return t;
        }
        else version( Posix )
        {
            auto t = cast(ThreadImpl) pthread_getspecific( sm_this );

            // NOTE: See the comment near ThreadImpl.findByAddr() for why the
            //       secondary ThreadImpl.findByAddr lookup can't be done on
            //       Posix.  However, because thread_attachByAddr() is for
            //       Windows only, the secondary lookup is pointless anyway.
            return t;
        }
    }

    static Object[] getAll()
    {
        synchronized( slock )
        {
            Object[] buf = new Object[]( sm_tlen );

            size_t pos;
            for( ThreadImpl t = sm_tbeg; t; t = t.next )
                buf[pos++] = t.getOwner();
            return buf;
        }
    }

    static int opApply(scope int delegate( ref ThreadImpl ) dg )
    {
        synchronized( slock )
        {
            for( ThreadImpl t = sm_tbeg; t; t = t.next )
            {
                if ( auto ret = dg( t ) )
                    return ret;
            }
        }
        return 0;
    }

private:
    Object m_owner; // back reference to owning object, needed for getOwner
                 // and synchronization

    //
    // Initializes a thread object which has no associated executable function.
    // This is used for the main thread initialized in thread_init().
    //
    static ThreadImpl create(Object owner)
    in
    {
        assert(owner !is null); // used as mutex
    }
    body
    {
        auto p = new ThreadImpl;

        p.m_owner  = owner;
        p.m_call = Call.NO;
        p.m_curr = &p.m_main;

        version( OSX )
        {
            // NOTE: OSX does not support TLS, so we do it ourselves.  The TLS
            //       data output by the compiler is bracketed by _tls_beg and
            //       _tls_end, so make a copy of it for each thread.
            const sz = cast(void*) &_tls_end - cast(void*) &_tls_beg;
            auto ptls = malloc( sz );
            assert( ptls );
            p.m_tls = ptls[0 .. sz];
            memcpy( ptls, &_tls_beg, sz );
            // The free must happen at program end, if anywhere.
        }
        else
        {
            auto pstart = cast(void*) &_tlsstart;
            auto pend   = cast(void*) &_tlsend;
            p.m_tls = pstart[0 .. pend - pstart];
        }
        return p;
    }

    //
    // Thread entry point.  Invokes the function or delegate passed on
    // construction (if any).
    //
    void run()
    {
        switch( m_call )
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

    //
    // The type of routine passed on thread construction.
    //
    enum Call
    {
        NO,
        FN,
        DG
    }


    //
    // Local storage
    //
    __gshared TLSKey      sm_this;

    //
    // Main process thread
    //
    __gshared ThreadImpl sm_main;

    //
    // Standard thread data
    //
    version( Windows )
    {
        HANDLE          m_hndl;
    }
    else version( OSX )
    {
        mach_port_t     m_tmach;
    }
    ThreadAddr          m_addr;
    Call                m_call;
    string              m_name;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }
    size_t              m_sz;
    version( Posix )
    {
        bool            m_isRunning;
    }
    bool                m_isDaemon;
    Throwable           m_unhandled;

private:
    ///////////////////////////////////////////////////////////////////////////
    // Storage of Active Thread
    ///////////////////////////////////////////////////////////////////////////


    //
    // Sets a thread-local reference to the current thread object.
    //
    static void setThis( ThreadImpl t )
    {
        version( Windows )
        {
            TlsSetValue( sm_this, cast(void*) t );
        }
        else version( Posix )
        {
            pthread_setspecific( sm_this, cast(void*) t );
        }
    }

private:
    ///////////////////////////////////////////////////////////////////////////
    // Thread Context and GC Scanning Support
    ///////////////////////////////////////////////////////////////////////////


    final void pushContext( Context* c )
    in
    {
        assert( !c.within );
    }
    body
    {
        c.within = m_curr;
        m_curr = c;
    }


    final void popContext()
    in
    {
        assert( m_curr && m_curr.within );
    }
    body
    {
        Context* c = m_curr;
        m_curr = c.within;
        c.within = null;
    }


    final Context* topContext()
    in
    {
        assert( m_curr );
    }
    body
    {
        return m_curr;
    }


    static struct Context
    {
        void*           bstack,
                        tstack;
        Context*        within;
        Context*        next,
                        prev;
    }


    Context             m_main;
    Context*            m_curr;
    bool                m_lock;
    void[]              m_tls;  // spans implicit thread local storage

    version( Windows )
    {
      version( X86 )
      {
        uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
      }
      else version( X86_64 )
      {
        ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                               // r8,r9,r10,r11,r12,r13,r14,r15
      }
      else
      {
        static assert(false, "Architecture not supported." );
      }
    }
    else version( OSX )
    {
      version( X86 )
      {
        uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
      }
      else version( X86_64 )
      {
        ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                               // r8,r9,r10,r11,r12,r13,r14,r15
      }
      else
      {
        static assert(false, "Architecture not supported." );
      }
    }

private:
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
    // All use of the global lists should synchronize on this lock.
    //
    @property static Mutex slock()
    {
        __gshared Mutex m = null;

        if( m !is null )
            return m;
        else
        {
            auto ci = Mutex.classinfo;
            auto p  = malloc( ci.init.length );
            (cast(byte*) p)[0 .. ci.init.length] = ci.init[];
            m = cast(Mutex) p;
            m.__ctor();
            return m;
        }
    }


    __gshared Context*    sm_cbeg;
    __gshared size_t      sm_clen;

    __gshared ThreadImpl  sm_tbeg;
    __gshared size_t      sm_tlen;

    //
    // Used for ordering threads in the global thread list.
    //
    ThreadImpl            prev;
    ThreadImpl            next;


    ///////////////////////////////////////////////////////////////////////////
    // Global Context List Operations
    ///////////////////////////////////////////////////////////////////////////


    //
    // Add a context to the global context list.
    //
    static void add( Context* c )
    in
    {
        assert( c );
        assert( !c.next && !c.prev );
    }
    body
    {
        // NOTE: This loop is necessary to avoid a race between newly created
        //       threads and the GC.  If a collection starts between the time
        //       ThreadImpl.start is called and the new thread calls ThreadImpl.add,
        //       the thread will have its stack scanned without first having
        //       been properly suspended.  Testing has shown this to sometimes
        //       cause a deadlock.

        while( true )
        {
            synchronized( slock )
            {
                if( !suspendDepth )
                {
                    if( sm_cbeg )
                    {
                        c.next = sm_cbeg;
                        sm_cbeg.prev = c;
                    }
                    sm_cbeg = c;
                    ++sm_clen;
                   return;
                }
            }
            yield();
        }
    }


    //
    // Remove a context from the global context list.
    //
    static void remove( Context* c )
    in
    {
        assert( c );
        assert( c.next || c.prev );
    }
    body
    {
        synchronized( slock )
        {
            if( c.prev )
                c.prev.next = c.next;
            if( c.next )
                c.next.prev = c.prev;
            if( sm_cbeg == c )
                sm_cbeg = c.next;
            --sm_clen;
        }
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
    static void add( ThreadImpl t )
    in
    {
        assert( t );
        assert( !t.next && !t.prev );
        assert( t.isRunning );
    }
    body
    {
        // NOTE: This loop is necessary to avoid a race between newly created
        //       threads and the GC.  If a collection starts between the time
        //       ThreadImpl.start is called and the new thread calls ThreadImpl.add,
        //       the thread could manipulate global state while the collection
        //       is running, and by being added to the thread list it could be
        //       resumed by the GC when it was never suspended, which would
        //       result in an exception thrown by the GC code.
        //
        //       An alternative would be to have ThreadImpl.start call ThreadImpl.add
        //       for the new thread, but this may introduce its own problems,
        //       since the thread object isn't entirely ready to be operated
        //       on by the GC.  This could be fixed by tracking thread startup
        //       status, but it's far easier to simply have ThreadImpl.add wait
        //       for any running collection to stop before altering the thread
        //       list.
        //
        //       After further testing, having add wait for a collect to end
        //       proved to have its own problems (explained in ThreadImpl.start),
        //       so add(Thread) is now being done in ThreadImpl.start.  This
        //       reintroduced the deadlock issue mentioned in bugzilla 4890,
        //       which appears to have been solved by doing this same wait
        //       procedure in add(Context).  These comments will remain in
        //       case other issues surface that require the startup state
        //       tracking described above.

        while( true )
        {
            synchronized( slock )
            {
                if( !suspendDepth )
                {
                    if( sm_tbeg )
                    {
                        t.next = sm_tbeg;
                        sm_tbeg.prev = t;
                    }
                    sm_tbeg = t;
                    ++sm_tlen;
                    return;
                }
            }
            yield();
        }
    }


    //
    // Remove a thread from the global thread list.
    //
    static void remove( ThreadImpl t )
    in
    {
        assert( t );
        assert( t.next || t.prev );
    }
    body
    {
        synchronized( slock )
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

            if( t.prev )
                t.prev.next = t.next;
            if( t.next )
                t.next.prev = t.prev;
            if( sm_tbeg == t )
                sm_tbeg = t.next;
            --sm_tlen;
        }
        // NOTE: Don't null out t.next or t.prev because opApply currently
        //       follows t.next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this
        //       function, however, a thread should never be re-added to the
        //       list anyway and having next and prev be non-null is a good way
        //       to ensure that.
    }


    /**
     * Registers the calling thread for use with the D Runtime.  If this routine
     * is called for a thread which is already registered, the result is undefined.
     */
    static ThreadImpl attachThis(Object owner)
    {
        gc_disable(); scope(exit) gc_enable();

        ThreadImpl          thisThread  = ThreadImpl.create(owner);
        ThreadImpl.Context* thisContext = &thisThread.m_main;
        assert( thisContext == thisThread.m_curr );

        version( Windows )
        {
            thisThread.m_addr  = GetCurrentThreadId();
            thisThread.m_hndl  = GetCurrentThreadHandle();
            thisContext.bstack = getStackBottom();
            thisContext.tstack = thisContext.bstack;
        }
        else version( Posix )
             {
                 thisThread.m_addr  = pthread_self();
                 thisContext.bstack = getStackBottom();
                 thisContext.tstack = thisContext.bstack;

                 thisThread.m_isRunning = true;
             }
        thisThread.m_isDaemon = true;
        ThreadImpl.setThis( thisThread );

        version( OSX )
        {
            thisThread.m_tmach = pthread_mach_thread_np( thisThread.m_addr );
            assert( thisThread.m_tmach != thisThread.m_tmach.init );
        }

        version( OSX )
        {
            // NOTE: OSX does not support TLS, so we do it ourselves.  The TLS
            //       data output by the compiler is bracketed by _tls_beg and
            //       _tls_end, so make a copy of it for each thread.
            const sz = cast(void*) &_tls_end - cast(void*) &_tls_beg;
            auto p = gc_malloc(sz);
            thisThread.m_tls = p[0 .. sz];
            memcpy( p, &_tls_beg, sz );
            // used gc_malloc so no need to free
        }
        else
        {
            auto pstart = cast(void*) &_tlsstart;
            auto pend   = cast(void*) &_tlsend;
            thisThread.m_tls = pstart[0 .. pend - pstart];
        }

        ThreadImpl.add( thisThread );
        ThreadImpl.add( thisContext );
        if( ThreadImpl.sm_main !is null )
            multiThreadedFlag = true;
        return thisThread;
    }

    /**
     * Search the list of all threads for a thread with the given thread identifier.
     *
     * Params:
     *  addr = The thread identifier to search for.
     * Returns:
     *  The thread object associated with the thread identifier, null if not found.
     */
    static ThreadImpl findByAddr( ThreadAddr addr )
    {
        synchronized( ThreadImpl.slock )
        {
            for( ThreadImpl t = ThreadImpl.sm_tbeg; t; t = t.next )
            {
                if( t.m_addr == addr )
                    return t;
            }
        }
        return null;
    }


    version( Windows )
    {
        // NOTE: These calls are not safe on Posix systems that use signals to
        //       perform garbage collection.  The suspendHandler uses getThis()
        //       to get the thread handle so getThis() must be a simple call.
        //       Mutexes can't safely be acquired inside signal handlers, and
        //       even if they could, the mutex needed (ThreadImpl.slock) is held by
        //       thread_suspendAll().  So in short, these routines will remain
        //       Windows-specific.  If they are truly needed elsewhere, the
        //       suspendHandler will need a way to call a version of getThis()
        //       that only does the TLS lookup without the fancy fallback stuff.

        /// ditto
        static ThreadImpl attachByAddr( Object owner, ThreadAddr addr )
        {
            return attachByAddrB( owner, addr, getThreadStackBottom( addr ) );
        }

        /// ditto
        static ThreadImpl attachByAddrB( Object owner, ThreadAddr addr, void* bstack )
        {
            gc_disable(); scope(exit) gc_enable();

            ThreadImpl          thisThread  = ThreadImpl.create(owner);
            ThreadImpl.Context* thisContext = &thisThread.m_main;
            assert( thisContext == thisThread.m_curr );

            version( Windows )
            {
                thisThread.m_addr  = addr;
                thisContext.bstack = bstack;
                thisContext.tstack = thisContext.bstack;

                if( addr == GetCurrentThreadId() )
                {
                    thisThread.m_hndl = GetCurrentThreadHandle();
                }
                else
                {
                    thisThread.m_hndl = OpenThreadHandle( addr );
                }
            }
            else version( Posix )
                 {
                     thisThread.m_addr  = addr;
                     thisContext.bstack = bstack;
                     thisContext.tstack = thisContext.bstack;

                     thisThread.m_isRunning = true;
                 }
            thisThread.m_isDaemon = true;

            version( OSX )
            {
                thisThread.m_tmach = pthread_mach_thread_np( thisThread.m_addr );
                assert( thisThread.m_tmach != thisThread.m_tmach.init );
            }

            version( OSX )
            {
                // NOTE: OSX does not support TLS, so we do it ourselves.  The TLS
                //       data output by the compiler is bracketed by _tls_beg and
                //       _tls_end, so make a copy of it for each thread.
                const sz = cast(void*) &_tls_end - cast(void*) &_tls_beg;
                auto p = gc_malloc(sz);
                assert( p );
                obj.m_tls = p[0 .. sz];
                memcpy( p, &_tls_beg, sz );
                // used gc_malloc so no need to free

                if( t.m_addr == pthread_self() )
                    ThreadImpl.setThis( thisThread );
            }
            else version( Windows )
            {
                if( addr == GetCurrentThreadId() )
                {
                    auto pstart = cast(void*) &_tlsstart;
                    auto pend   = cast(void*) &_tlsend;
                    thisThread.m_tls = pstart[0 .. pend - pstart];
                    ThreadImpl.setThis( thisThread );
                }
                else
                {
                    // TODO: This seems wrong.  If we're binding threads from
                    //       a DLL, will they always have space reserved for
                    //       the TLS chunk we expect?  I don't know Windows
                    //       well enough to say.
                    auto pstart = cast(void*) &_tlsstart;
                    auto pend   = cast(void*) &_tlsend;
                    auto pos    = GetTlsDataAddress( thisThread.m_hndl );
                    if( pos ) // on x64, threads without TLS happen to exist
                        thisThread.m_tls = pos[0 .. pend - pstart];
                    else
                        thisThread.m_tls = [];
                }
            }
            else
            {
                static assert( false, "Platform not supported." );
            }

            ThreadImpl.add( thisThread );
            ThreadImpl.add( thisContext );
            if( ThreadImpl.sm_main !is null )
                multiThreadedFlag = true;
            return thisThread;
        }
    }
}

/**
 * Initializes the thread module.  This function must be called by the
 * garbage collector on startup and before any other thread routines
 * are called.
 */
void init()
{
    // NOTE: If thread_init itself performs any allocations then the thread
    //       routines reserved for garbage collector use may be called while
    //       thread_init is being processed.  However, since no memory should
    //       exist to be scanned at this point, it is sufficient for these
    //       functions to detect the condition and return immediately.

    version( Windows )
    {
        ThreadImpl.sm_this = TlsAlloc();
        assert( ThreadImpl.sm_this != TLS_OUT_OF_INDEXES );
    }
    else version( OSX )
    {
        int status;

        status = pthread_key_create( &ThreadImpl.sm_this, null );
        assert( status == 0 );
    }
    else version( Posix )
    {
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
        static if( __traits( compiles, SA_RESTART ) )
            sigusr1.sa_flags = SA_RESTART;
        else
            sigusr1.sa_flags   = 0;
        sigusr1.sa_handler = &thread_suspendHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr1.sa_mask );
        assert( status == 0 );

        // NOTE: Since SIGUSR2 should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        sigusr2.sa_flags   = 0;
        sigusr2.sa_handler = &thread_resumeHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr2.sa_mask );
        assert( status == 0 );

        status = sigaction( SIGUSR1, &sigusr1, null );
        assert( status == 0 );

        status = sigaction( SIGUSR2, &sigusr2, null );
        assert( status == 0 );

        status = sem_init( &suspendCount, 0, 0 );
        assert( status == 0 );

        status = pthread_key_create( &ThreadImpl.sm_this, null );
        assert( status == 0 );
    }
}

/**
 *
 */
extern (C) bool thread_isMainThread()
{
    return ThreadImpl.getThis() is ThreadImpl.sm_main;
}

/// This should be handled automatically by thread_attach.
version (Windows)
deprecated extern (C) void thread_setNeedLock( bool need ) nothrow
{
    if( need )
        multiThreadedFlag = true;
}

/**
 * Deregisters the calling thread from use with the runtime.  If this routine
 * is called for a thread which is already registered, the result is undefined.
 */
extern (C) void thread_detachThis()
{
    ThreadImpl.remove(ThreadImpl.getThis());
}

/// ditto
extern (C) void thread_detachByAddr( ThreadAddr addr )
{
    if( auto t = ThreadImpl.findByAddr( addr ) )
        ThreadImpl.remove( t );
}

/**
 * Joins all non-daemon threads that are currently running.  This is done by
 * performing successive scans through the thread list until a scan consists
 * of only daemon threads.
 */
extern (C) void thread_joinAll()
{
    while( true )
    {
        ThreadImpl nonDaemon = null;

        synchronized ( ThreadImpl.slock )
        {
            for( ThreadImpl t = ThreadImpl.sm_tbeg; t; t = t.next )
            {
                if( !t.isRunning )
                {
                    ThreadImpl.remove( t );
                    continue;
                }
                if( !t.isDaemon )
                {
                    nonDaemon = t;
                    break;
                }
            }
        }
        if( nonDaemon is null )
            break;
        nonDaemon.join(true);
    }
}

/**
 * Performs intermediate shutdown of the thread module.
 */
shared static ~this()
{
    // NOTE: The functionality related to garbage collection must be minimally
    //       operable after this dtor completes.  Therefore, only minimal
    //       cleanup may occur.

    for( auto t = ThreadImpl.sm_tbeg; t; t = t.next )
    {
        if( !t.isRunning )
            ThreadImpl.remove( t );
    }
}

// Used for needLock below.
private __gshared bool multiThreadedFlag = false;

/**
 * This function is used to determine whether the the process is
 * multi-threaded.  Optimizations may only be performed on this
 * value if the programmer can guarantee that no path from the
 * enclosed code will start a thread.
 *
 * Returns:
 *  True if ThreadImpl.start() has been called in this process.
 */
extern (C) bool thread_needLock() nothrow
{
    return multiThreadedFlag;
}


// Used for suspendAll/resumeAll below.
private __gshared uint suspendDepth = 0;

/**
 * Suspend all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function may be called multiple times, and must
 * be followed by a matching number of calls to thread_resumeAll before
 * processing is resumed.
 *
 * Throws:
 *  ThreadException if the suspend operation fails for a running thread.
 */
extern (C) void thread_suspendAll()
{
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
     *  ThreadException if the suspend operation fails for a running thread.
     */
    void suspend( ThreadImpl t )
    {
        version( Windows )
        {
            if( t.m_addr != GetCurrentThreadId() && SuspendThread( t.m_hndl ) == 0xFFFFFFFF )
            {
                if( !t.isRunning )
                {
                    ThreadImpl.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to suspend thread" );
            }

            CONTEXT context = void;
            context.ContextFlags = CONTEXT_INTEGER | CONTEXT_CONTROL;

            if( !GetThreadContext( t.m_hndl, &context ) )
                throw new ThreadException( "Unable to load thread context" );

            version( X86 )
            {
                if( !t.m_lock )
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
            else
            {
                static assert(false, "Architecture not supported." );
            }
        }
        else version( OSX )
        {
            if( t.m_addr != pthread_self() && thread_suspend( t.m_tmach ) != KERN_SUCCESS )
            {
                if( !t.isRunning )
                {
                    ThreadImpl.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to suspend thread" );
            }

            version( X86 )
            {
                x86_thread_state32_t    state = void;
                mach_msg_type_number_t  count = x86_THREAD_STATE32_COUNT;

                if( thread_get_state( t.m_tmach, x86_THREAD_STATE32, &state, &count ) != KERN_SUCCESS )
                    throw new ThreadException( "Unable to load thread state" );
                if( !t.m_lock )
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
            else version( X86_64 )
            {
                x86_thread_state64_t    state = void;
                mach_msg_type_number_t  count = x86_THREAD_STATE64_COUNT;

                if( thread_get_state( t.m_tmach, x86_THREAD_STATE64, &state, &count ) != KERN_SUCCESS )
                    throw new ThreadException( "Unable to load thread state" );
                if( !t.m_lock )
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
            else
            {
                static assert(false, "Architecture not supported." );
            }
        }
        else version( Posix )
        {
            if( t.m_addr != pthread_self() )
            {
                if( pthread_kill( t.m_addr, SIGUSR1 ) != 0 )
                {
                    if( !t.isRunning )
                    {
                        ThreadImpl.remove( t );
                        return;
                    }
                    throw new ThreadException( "Unable to suspend thread" );
                }
                // NOTE: It's really not ideal to wait for each thread to
                //       signal individually -- rather, it would be better to
                //       suspend them all and wait once at the end.  However,
                //       semaphores don't really work this way, and the obvious
                //       alternative (looping on an atomic suspend count)
                //       requires either the atomic module (which only works on
                //       x86) or other specialized functionality.  It would
                //       also be possible to simply loop on sem_wait at the
                //       end, but I'm not convinced that this would be much
                //       faster than the current approach.
                sem_wait( &suspendCount );
            }
            else if( !t.m_lock )
            {
                t.m_curr.tstack = getStackTop();
            }
        }
    }


    // NOTE: We've got an odd chicken & egg problem here, because while the GC
    //       is required to call thread_init before calling any other thread
    //       routines, thread_init may allocate memory which could in turn
    //       trigger a collection.  Thus, thread_suspendAll, thread_scanAll,
    //       and thread_resumeAll must be callable before thread_init
    //       completes, with the assumption that no other GC memory has yet
    //       been allocated by the system, and thus there is no risk of losing
    //       data if the global thread list is empty.  The check of
    //       ThreadImpl.sm_tbeg below is done to ensure thread_init has completed,
    //       and therefore that calling ThreadImpl.getThis will not result in an
    //       error.  For the short time when ThreadImpl.sm_tbeg is null, there is
    //       no reason not to simply call the multithreaded code below, with
    //       the expectation that the foreach loop will never be entered.
    if( !multiThreadedFlag && ThreadImpl.sm_tbeg )
    {
        if( ++suspendDepth == 1 )
            suspend( ThreadImpl.getThis() );
        return;
    }

    ThreadImpl.slock.lock();
    {
        if( ++suspendDepth > 1 )
            return;

        // NOTE: I'd really prefer not to check isRunning within this loop but
        //       not doing so could be problematic if threads are termianted
        //       abnormally and a new thread is created with the same thread
        //       address before the next GC run.  This situation might cause
        //       the same thread to be suspended twice, which would likely
        //       cause the second suspend to fail, the garbage collection to
        //       abort, and Bad Things to occur.
        for( auto t = ThreadImpl.sm_tbeg; t; t = t.next )
        {
            if( t.isRunning )
                suspend( t );
            else
                ThreadImpl.remove( t );
        }

        version( Posix )
        {
            // wait on semaphore -- see note in suspend for
            // why this is currently not implemented
        }
    }
}


/**
 * Resume all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function must be called once for each preceding
 * call to thread_suspendAll before the threads are actually resumed.
 *
 * In:
 *  This routine must be preceded by a call to thread_suspendAll.
 *
 * Throws:
 *  ThreadException if the resume operation fails for a running thread.
 */
extern (C) void thread_resumeAll()
in
{
    assert( suspendDepth > 0 );
}
body
{
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
     *  ThreadException if the resume fails for a running thread.
     */
    void resume( ThreadImpl t )
    {
        version( Windows )
        {
            if( t.m_addr != GetCurrentThreadId() && ResumeThread( t.m_hndl ) == 0xFFFFFFFF )
            {
                if( !t.isRunning )
                {
                    ThreadImpl.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to resume thread" );
            }

            if( !t.m_lock )
                t.m_curr.tstack = t.m_curr.bstack;
            t.m_reg[0 .. $] = 0;
        }
        else version( OSX )
        {
            if( t.m_addr != pthread_self() && thread_resume( t.m_tmach ) != KERN_SUCCESS )
            {
                if( !t.isRunning )
                {
                    ThreadImpl.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to resume thread" );
            }

            if( !t.m_lock )
                t.m_curr.tstack = t.m_curr.bstack;
            t.m_reg[0 .. $] = 0;
        }
        else version( Posix )
        {
            if( t.m_addr != pthread_self() )
            {
                if( pthread_kill( t.m_addr, SIGUSR2 ) != 0 )
                {
                    if( !t.isRunning )
                    {
                        ThreadImpl.remove( t );
                        return;
                    }
                    throw new ThreadException( "Unable to resume thread" );
                }
            }
            else if( !t.m_lock )
            {
                t.m_curr.tstack = t.m_curr.bstack;
            }
        }
    }


    // NOTE: See thread_suspendAll for the logic behind this.
    if( !multiThreadedFlag && ThreadImpl.sm_tbeg )
    {
        if( --suspendDepth == 0 )
            resume( ThreadImpl.getThis() );
        return;
    }

    scope(exit) ThreadImpl.slock.unlock();
    {
        if( --suspendDepth > 0 )
            return;

        for( auto t = ThreadImpl.sm_tbeg; t; t = t.next )
        {
            resume( t );
        }
    }
}

private alias void delegate( void*, void* ) scanAllThreadsFn;

/**
 * The main entry point for garbage collection.  The supplied delegate
 * will be passed ranges representing both stack and register values.
 *
 * Params:
 *  scan        = The scanner function.  It should scan from p1 through p2 - 1.
 *  curStackTop = An optional pointer to the top of the calling thread's stack.
 *
 * In:
 *  This routine must be preceded by a call to thread_suspendAll.
 */
extern (C) void thread_scanAll( scanAllThreadsFn scan, void* curStackTop = null )
in
{
    assert( suspendDepth > 0 );
}
body
{
    ThreadImpl   thisThread  = null;
    void*        oldStackTop = null;

    if( curStackTop && ThreadImpl.sm_tbeg )
    {
        thisThread  = ThreadImpl.getThis();
        if( !thisThread.m_lock )
        {
            oldStackTop = thisThread.m_curr.tstack;
            thisThread.m_curr.tstack = curStackTop;
        }
    }

    scope( exit )
    {
        if( curStackTop && ThreadImpl.sm_tbeg )
        {
            if( !thisThread.m_lock )
            {
                thisThread.m_curr.tstack = oldStackTop;
            }
        }
    }

    // NOTE: Synchronizing on ThreadImpl.slock is not needed because this
    //       function may only be called after all other threads have
    //       been suspended from within the same lock.
    for( auto c = ThreadImpl.sm_cbeg; c; c = c.next )
    {
        version( StackGrowsDown )
        {
            // NOTE: We can't index past the bottom of the stack
            //       so don't do the "+1" for StackGrowsDown.
            if( c.tstack && c.tstack < c.bstack )
                scan( c.tstack, c.bstack );
        }
        else
        {
            if( c.bstack && c.bstack < c.tstack )
                scan( c.bstack, c.tstack + 1 );
        }
    }

    for( auto t = ThreadImpl.sm_tbeg; t; t = t.next )
    {
        scan( t.m_tls.ptr, t.m_tls.ptr + t.m_tls.length );

        version( Windows )
        {
            scan( t.m_reg.ptr, t.m_reg.ptr + t.m_reg.length );
        }
    }
}


/**
 * This routine allows the runtime to process any special per-thread handling
 * for the GC.  This is needed for taking into account any memory that is
 * referenced by non-scanned pointers but is about to be freed.  That currently
 * means the array append cache.
 *
 * In:
 *  This routine must be called just prior to resuming all threads.
 */
extern(C) void thread_processGCMarks()
{
    foreach(t; ThreadImpl)
    {
        rt_processGCMarks(t.m_tls);
    }
}


/**
 *
 */
extern(C) void[] thread_getTLSBlock()
{
    version(OSX)
    {
        // TLS lives in the thread object.
        auto t = ThreadImpl.getThis();
        return t.m_tls;
    }
    else version(FreeBSD)
    {
        return (cast(void*)&_tlsstart)[0..(&_tlsend)-(&_tlsstart)];
    }
    else
    {

        return (cast(void*)&_tlsstart)[0..(&_tlsend)-(&_tlsstart)];
    }
}


/**
 *
 */
extern (C) void* thread_stackBottom()
{
    if( auto t = ThreadImpl.getThis() )
        return t.topContext().bstack;
    return rt_stackBottom();
}




///////////////////////////////////////////////////////////////////////////////
// Fiber Platform Detection and Memory Allocation
///////////////////////////////////////////////////////////////////////////////


private
{
    version( D_InlineAsm_X86 )
    {
        version( Windows )
            version = AsmX86_Windows;
        else version( Posix )
            version = AsmX86_Posix;

        version( OSX )
            version = AlignFiberStackTo16Byte;
    }
    else version( D_InlineAsm_X86_64 )
    {
        version( Windows )
        {
            version = AsmX86_64_Windows;
            version = AlignFiberStackTo16Byte;
        }
        else version( Posix )
        {
            version = AsmX86_64_Posix;
            version = AlignFiberStackTo16Byte;
        }
    }
    else version( PPC )
    {
        version( Posix )
            version = AsmPPC_Posix;
    }


    version( Posix )
    {
        import core.sys.posix.unistd;   // for sysconf
        import core.sys.posix.sys.mman; // for mmap

        version( AsmX86_Windows )    {} else
        version( AsmX86_Posix )      {} else
        version( AsmX86_64_Windows ) {} else
        version( AsmX86_64_Posix )   {} else
        version( AsmPPC_Posix )      {} else
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

    __gshared const size_t PAGESIZE;
}


shared static this()
{
    static if( __traits( compiles, GetSystemInfo ) )
    {
        SYSTEM_INFO info;
        GetSystemInfo( &info );

        PAGESIZE = info.dwPageSize;
        assert( PAGESIZE < int.max );
    }
    else static if( __traits( compiles, sysconf ) &&
                    __traits( compiles, _SC_PAGESIZE ) )
    {
        PAGESIZE = cast(size_t) sysconf( _SC_PAGESIZE );
        assert( PAGESIZE < int.max );
    }
    else
    {
        version( PPC )
            PAGESIZE = 8192;
        else
            PAGESIZE = 4096;
    }
}


///////////////////////////////////////////////////////////////////////////////
// Fiber Entry Point and Context Switch
///////////////////////////////////////////////////////////////////////////////


private
{
    extern (C) void fiber_entryPoint()
    {
        FiberImpl obj = FiberImpl.getThis();
        assert( obj !is null );

        assert( ThreadImpl.getThis().m_curr is obj.m_ctxt );
        volatile ThreadImpl.getThis().m_lock = false;
        obj.m_ctxt.tstack = obj.m_ctxt.bstack;
        obj.m_state = FiberImpl.State.EXEC;

        try
        {
            obj.run();
        }
        catch( Throwable t )
        {
            obj.m_unhandled = t;
        }

        static if( __traits( compiles, ucontext_t ) )
          obj.m_ucur = &obj.m_utxt;

        obj.m_state = FiberImpl.State.TERM;
        obj.switchOut();
    }


  // NOTE: If AsmPPC_Posix is defined then the context switch routine will
  //       be defined externally until inline PPC ASM is supported.
  version( AsmPPC_Posix )
    extern (C) void fiber_switchContext( void** oldp, void* newp );
  else
    extern (C) void fiber_switchContext( void** oldp, void* newp )
    {
        // NOTE: The data pushed and popped in this routine must match the
        //       default stack created by Fiber.initStack or the initial
        //       switch into a new context will fail.

        version( AsmX86_Windows )
        {
            asm
            {
                naked;

                // save current stack state
                push EBP;
                mov  EBP, ESP;
                push EDI;
                push ESI;
                push EBX;
                push dword ptr FS:[0];
                push dword ptr FS:[4];
                push dword ptr FS:[8];
                push EAX;

                // store oldp again with more accurate address
                mov EAX, dword ptr 8[EBP];
                mov [EAX], ESP;
                // load newp to begin context switch
                mov ESP, dword ptr 12[EBP];

                // load saved state from new stack
                pop EAX;
                pop dword ptr FS:[8];
                pop dword ptr FS:[4];
                pop dword ptr FS:[0];
                pop EBX;
                pop ESI;
                pop EDI;
                pop EBP;

                // 'return' to complete switch
                ret;
            }
        }
        else version( AsmX86_64_Windows )
        {
            asm
            {
                naked;

                // save current stack state
                push RBP;
                mov  RBP, RSP;
                push RBX;
                push R12;
                push R13;
                push R14;
                push R15;
                push qword ptr GS:[0];
                push qword ptr GS:[8];
                push qword ptr GS:[16];

                // store oldp
                mov [RDI], RSP;
                // load newp to begin context switch
                mov RSP, RSI;

                // load saved state from new stack
                pop qword ptr GS:[16];
                pop qword ptr GS:[8];
                pop qword ptr GS:[0];
                pop R15;
                pop R14;
                pop R13;
                pop R12;
                pop RBX;
                pop RBP;

                // 'return' to complete switch
                pop RCX;
                jmp RCX;
            }
        }
        else version( AsmX86_Posix )
        {
            asm
            {
                naked;

                // save current stack state
                push EBP;
                mov  EBP, ESP;
                push EDI;
                push ESI;
                push EBX;
                push EAX;

                // store oldp again with more accurate address
                mov EAX, dword ptr 8[EBP];
                mov [EAX], ESP;
                // load newp to begin context switch
                mov ESP, dword ptr 12[EBP];

                // load saved state from new stack
                pop EAX;
                pop EBX;
                pop ESI;
                pop EDI;
                pop EBP;

                // 'return' to complete switch
                pop ECX;
                jmp ECX;
            }
        }
        else version( AsmX86_64_Posix )
        {
            asm
            {
                naked;

                // save current stack state
                push RBP;
                mov  RBP, RSP;
                push RBX;
                push R12;
                push R13;
                push R14;
                push R15;

                // store oldp
                mov [RDI], RSP;
                // load newp to begin context switch
                mov RSP, RSI;

                // load saved state from new stack
                pop R15;
                pop R14;
                pop R13;
                pop R12;
                pop RBX;
                pop RBP;

                // 'return' to complete switch
                pop RCX;
                jmp RCX;
            }
        }
        else static if( __traits( compiles, ucontext_t ) )
        {
            Fiber   cfib = Fiber.getThis();
            void*   ucur = cfib.m_ucur;

            *oldp = &ucur;
            swapcontext( **(cast(ucontext_t***) oldp),
                          *(cast(ucontext_t**)  newp) );
        }
    }
}


///////////////////////////////////////////////////////////////////////////////
// Fiber
///////////////////////////////////////////////////////////////////////////////


/**
 * This class provides a cooperative concurrency mechanism integrated with the
 * threading and garbage collection functionality.  Calling a fiber may be
 * considered a blocking operation that returns when the fiber yields (via
 * Fiber.yield()).  Execution occurs within the context of the calling thread
 * so synchronization is not necessary to guarantee memory visibility so long
 * as the same thread calls the fiber each time.  Please note that there is no
 * requirement that a fiber be bound to one specific thread.  Rather, fibers
 * may be freely passed between threads so long as they are not currently
 * executing.  Like threads, a new fiber thread may be created using either
 * derivation or composition, as in the following example.
 *
 * Example:
 * ----------------------------------------------------------------------
 *
 * class DerivedFiber : Fiber
 * {
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private :
 *     void run()
 *     {
 *         printf( "Derived fiber running.\n" );
 *     }
 * }
 *
 * void fiberFunc()
 * {
 *     printf( "Composed fiber running.\n" );
 *     Fiber.yield();
 *     printf( "Composed fiber running.\n" );
 * }
 *
 * // create instances of each type
 * Fiber derived = new DerivedFiber();
 * Fiber composed = new Fiber( &fiberFunc );
 *
 * // call both fibers once
 * derived.call();
 * composed.call();
 * printf( "Execution returned to calling context.\n" );
 * composed.call();
 *
 * // since each fiber has run to completion, each should have state TERM
 * assert( derived.state == Fiber.State.TERM );
 * assert( composed.state == Fiber.State.TERM );
 *
 * ----------------------------------------------------------------------
 *
 * Authors: Based on a design by Mikola Lysenko.
 */
final class FiberImpl
{
    static FiberImpl create(Object owner, void function() fn, size_t sz)
    in
    {
        assert( fn );
    }
    body
    {
        if (sz == cast(size_t)-1)
            sz = PAGESIZE*4;

        auto p = new FiberImpl;

        p.m_owner   = owner;
        p.m_fn    = fn;
        p.m_call  = Call.FN;
        p.m_state = State.HOLD;
        p.allocStack(sz);
        p.initStack();
        return p;
    }


    static FiberImpl create(Object owner, void delegate() dg, size_t sz)
    in
    {
        assert( dg );
    }
    body
    {
        if (sz == cast(size_t)-1)
            sz = PAGESIZE*4;

        auto p = new FiberImpl;

        p.m_owner   = owner;
        p.m_dg    = dg;
        p.m_call  = Call.DG;
        p.m_state = State.HOLD;
        p.allocStack( sz );
        p.initStack();
        return p;
    }

    void finalize()
    {
        freeStack();
    }

    enum State
    {
        HOLD,
        EXEC,
        TERM,
    }

    Object call(bool rethrow)
    in
    {
        assert( m_state == State.HOLD );
    }
    body
    {
        FiberImpl    cur = getThis();

        static if( __traits( compiles, ucontext_t ) )
          m_ucur = cur ? &cur.m_utxt : &Fiber.sm_utxt;

        setThis( this );
        this.switchIn();
        setThis( cur );

        static if( __traits( compiles, ucontext_t ) )
          m_ucur = null;

        // NOTE: If the fiber has terminated then the stack pointers must be
        //       reset.  This ensures that the stack for this fiber is not
        //       scanned if the fiber has terminated.  This is necessary to
        //       prevent any references lingering on the stack from delaying
        //       the collection of otherwise dead objects.  The most notable
        //       being the current object, which is referenced at the top of
        //       fiber_entryPoint.
        if( m_state == State.TERM )
        {
            m_ctxt.tstack = m_ctxt.bstack;
        }
        if( m_unhandled )
        {
            Throwable t = m_unhandled;
            m_unhandled = null;
            if( rethrow )
                throw t;
            return t;
        }
        return null;
    }

    void reset()
    in
    {
        assert( m_state == State.TERM );
        assert( m_ctxt.tstack == m_ctxt.bstack );
    }
    body
    {
        m_state = State.HOLD;
        initStack();
        m_unhandled = null;
    }

    @property State state() const
    {
        return m_state;
    }

    static void yield()
    {
        FiberImpl    cur = getThis();
        assert( cur, "Fiber.yield() called with no active fiber" );
        assert( cur.m_state == State.EXEC );

        static if( __traits( compiles, ucontext_t ) )
          cur.m_ucur = &cur.m_utxt;

        cur.m_state = State.HOLD;
        cur.switchOut();
        cur.m_state = State.EXEC;
    }

    static void yieldAndThrow(Throwable t)
    in
    {
        assert(t);
    }
    body
    {
        FiberImpl   cur = getThis();
        assert(cur, "Fiber.yield() called with no active fiber");
        assert(cur.m_state == State.EXEC);

        static if(__traits(compiles, ucontext_t))
            cur.m_ucur = &cur.m_utxt;

        cur.m_unhandled = t;
        cur.m_state     = State.HOLD;
        cur.switchOut();
        cur.m_state     = State.EXEC;
    }

    static Object getOwner()
    {
        return getThis().m_owner;
    }

    static FiberImpl getThis()
    {
        return sm_this;
    }

private:

    version( Posix )
    {
        static if(__traits(compiles, ucontext_t))
        {
            // check that getcontext doesn't fail
            static this()
            {
                int status = getcontext(&sm_utxt);
                assert(status == 0);
            }
        }
    }

    void run()
    {
        switch( m_call )
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

    //
    // The type of routine passed on fiber construction.
    //
    enum Call
    {
        NO,
        FN,
        DG
    }

    //
    // Standard fiber data
    //
    Call                m_call;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }
    bool                m_isRunning;
    Throwable           m_unhandled;
    State               m_state;
    Object              m_owner;


    ///////////////////////////////////////////////////////////////////////////
    // Stack Management
    ///////////////////////////////////////////////////////////////////////////


    //
    // Allocate a new stack for this fiber.
    //
    final void allocStack( size_t sz )
    in
    {
        assert( !m_pmem && !m_ctxt );
    }
    body
    {
        // adjust alloc size to a multiple of PAGESIZE
        sz += PAGESIZE - 1;
        sz -= sz % PAGESIZE;

        // NOTE: This instance of ThreadImpl.Context is dynamic so Fiber objects
        //       can be collected by the GC so long as no user level references
        //       to the object exist.  If m_ctxt were not dynamic then its
        //       presence in the global context list would be enough to keep
        //       this object alive indefinitely.  An alternative to allocating
        //       room for this struct explicitly would be to mash it into the
        //       base of the stack being allocated below.  However, doing so
        //       requires too much special logic to be worthwhile.
        m_ctxt = new ThreadImpl.Context;

        static if( __traits( compiles, VirtualAlloc ) )
        {
            // reserve memory for stack
            m_pmem = VirtualAlloc( null,
                                   sz + PAGESIZE,
                                   MEM_RESERVE,
                                   PAGE_NOACCESS );
            if( !m_pmem )
            {
                throw new FiberException( "Unable to reserve memory for stack" );
            }

            version( StackGrowsDown )
            {
                void* stack = m_pmem + PAGESIZE;
                void* guard = m_pmem;
                void* pbase = stack + sz;
            }
            else
            {
                void* stack = m_pmem;
                void* guard = m_pmem + sz;
                void* pbase = stack;
            }

            // allocate reserved stack segment
            stack = VirtualAlloc( stack,
                                  sz,
                                  MEM_COMMIT,
                                  PAGE_READWRITE );
            if( !stack )
            {
                throw new FiberException( "Unable to allocate memory for stack" );
            }

            // allocate reserved guard page
            guard = VirtualAlloc( guard,
                                  PAGESIZE,
                                  MEM_COMMIT,
                                  PAGE_READWRITE | PAGE_GUARD );
            if( !guard )
            {
                throw new FiberException( "Unable to create guard page for stack" );
            }

            m_ctxt.bstack = pbase;
            m_ctxt.tstack = pbase;
            m_size = sz;
        }
        else
        {   static if( __traits( compiles, mmap ) )
            {
                m_pmem = mmap( null,
                               sz,
                               PROT_READ | PROT_WRITE,
                               MAP_PRIVATE | MAP_ANON,
                               -1,
                               0 );
                if( m_pmem == MAP_FAILED )
                    m_pmem = null;
            }
            else static if( __traits( compiles, valloc ) )
            {
                m_pmem = valloc( sz );
            }
            else static if( __traits( compiles, malloc ) )
            {
                m_pmem = malloc( sz );
            }
            else
            {
                m_pmem = null;
            }

            if( !m_pmem )
            {
                throw new FiberException( "Unable to allocate memory for stack" );
            }

            version( StackGrowsDown )
            {
                m_ctxt.bstack = m_pmem + sz;
                m_ctxt.tstack = m_pmem + sz;
            }
            else
            {
                m_ctxt.bstack = m_pmem;
                m_ctxt.tstack = m_pmem;
            }
            m_size = sz;
        }

        ThreadImpl.add( m_ctxt );
    }


    //
    // Free this fiber's stack.
    //
    final void freeStack()
    in
    {
        assert( m_pmem && m_ctxt );
    }
    body
    {
        // NOTE: m_ctxt is guaranteed to be alive because it is held in the
        //       global context list.
        ThreadImpl.remove( m_ctxt );

        static if( __traits( compiles, VirtualAlloc ) )
        {
            VirtualFree( m_pmem, 0, MEM_RELEASE );
        }
        else static if( __traits( compiles, mmap ) )
        {
            munmap( m_pmem, m_size );
        }
        else static if( __traits( compiles, valloc ) )
        {
            free( m_pmem );
        }
        else static if( __traits( compiles, malloc ) )
        {
            free( m_pmem );
        }
        m_pmem = null;
        m_ctxt = null;
    }

    //
    // Initialize the allocated stack.
    //
    final void initStack()
    in
    {
        assert( m_ctxt.tstack && m_ctxt.tstack == m_ctxt.bstack );
        assert( cast(size_t) m_ctxt.bstack % (void*).sizeof == 0 );
    }
    body
    {
        void* pstack = m_ctxt.tstack;
        scope( exit )  m_ctxt.tstack = pstack;

        void push( size_t val )
        {
            version( StackGrowsDown )
            {
                pstack -= size_t.sizeof;
                *(cast(size_t*) pstack) = val;
            }
            else
            {
                pstack += size_t.sizeof;
                *(cast(size_t*) pstack) = val;
            }
        }

        // NOTE: On OS X the stack must be 16-byte aligned according
        // to the IA-32 call spec. For x86_64 the stack also needs to
        // be aligned to 16-byte according to SysV AMD64 ABI.
        version( AlignFiberStackTo16Byte )
        {
            version( StackGrowsDown )
            {
                pstack = cast(void*)(cast(size_t)(pstack) - (cast(size_t)(pstack) & 0x0F));
            }
            else
            {
                pstack = cast(void*)(cast(size_t)(pstack) + (cast(size_t)(pstack) & 0x0F));
            }
        }

        version( AsmX86_Windows )
        {
            push( cast(size_t) &fiber_entryPoint );                 // EIP
            push( cast(size_t) m_ctxt.bstack );                     // EBP
            push( 0x00000000 );                                     // EDI
            push( 0x00000000 );                                     // ESI
            push( 0x00000000 );                                     // EBX
            push( 0xFFFFFFFF );                                     // FS:[0]
            version( StackGrowsDown )
            {
                push( cast(size_t) m_ctxt.bstack );                 // FS:[4]
                push( cast(size_t) m_ctxt.bstack - m_size );        // FS:[8]
            }
            else
            {
                push( cast(size_t) m_ctxt.bstack );                 // FS:[4]
                push( cast(size_t) m_ctxt.bstack + m_size );        // FS:[8]
            }
            push( 0x00000000 );                                     // EAX
        }
        else version( AsmX86_64_Windows )
        {
            push( 0x00000000_00000000 );                            // Return address of fiber_entryPoint call
            push( cast(size_t) &fiber_entryPoint );                 // RIP
            push( 0x00000000_00000000 );                            // RBP
            push( 0x00000000_00000000 );                            // RBX
            push( 0x00000000_00000000 );                            // R12
            push( 0x00000000_00000000 );                            // R13
            push( 0x00000000_00000000 );                            // R14
            push( 0x00000000_00000000 );                            // R15
            push( 0xFFFFFFFF_FFFFFFFF );                            // GS:[0]
            version( StackGrowsDown )
            {
                push( cast(size_t) m_ctxt.bstack );                 // GS:[8]
                push( cast(size_t) m_ctxt.bstack - m_size );        // GS:[16]
            }
            else
            {
                push( cast(size_t) m_ctxt.bstack );                 // GS:[8]
                push( cast(size_t) m_ctxt.bstack + m_size );        // GS:[16]
            }
        }
        else version( AsmX86_Posix )
        {
            push( 0x00000000 );                                     // Return address of fiber_entryPoint call
            push( cast(size_t) &fiber_entryPoint );                 // EIP
            push( cast(size_t) m_ctxt.bstack );                     // EBP
            push( 0x00000000 );                                     // EDI
            push( 0x00000000 );                                     // ESI
            push( 0x00000000 );                                     // EBX
            push( 0x00000000 );                                     // EAX
        }
        else version( AsmX86_64_Posix )
        {
            push( 0x00000000_00000000 );                            // Return address of fiber_entryPoint call
            push( cast(size_t) &fiber_entryPoint );                 // RIP
            push( cast(size_t) m_ctxt.bstack );                     // RBP
            push( 0x00000000_00000000 );                            // RBX
            push( 0x00000000_00000000 );                            // R12
            push( 0x00000000_00000000 );                            // R13
            push( 0x00000000_00000000 );                            // R14
            push( 0x00000000_00000000 );                            // R15
        }
        else version( AsmPPC_Posix )
        {
            version( StackGrowsDown )
            {
                pstack -= int.sizeof * 5;
            }
            else
            {
                pstack += int.sizeof * 5;
            }

            push( cast(size_t) &fiber_entryPoint );     // link register
            push( 0x00000000 );                         // control register
            push( 0x00000000 );                         // old stack pointer

            // GPR values
            version( StackGrowsDown )
            {
                pstack -= int.sizeof * 20;
            }
            else
            {
                pstack += int.sizeof * 20;
            }

            assert( (cast(size_t) pstack & 0x0f) == 0 );
        }
        else static if( __traits( compiles, ucontext_t ) )
        {
            getcontext( &m_utxt );
            m_utxt.uc_stack.ss_sp   = m_pmem;
            m_utxt.uc_stack.ss_size = m_size;
            makecontext( &m_utxt, &fiber_entryPoint, 0 );
            // NOTE: If ucontext is being used then the top of the stack will
            //       be a pointer to the ucontext_t struct for that fiber.
            push( cast(size_t) &m_utxt );
        }
    }


    ThreadImpl.Context* m_ctxt;
    size_t          m_size;
    void*           m_pmem;

    static if( __traits( compiles, ucontext_t ) )
    {
        // NOTE: The static ucontext instance is used to represent the context
        //       of the executing thread.
        static ucontext_t       sm_utxt = void;
        ucontext_t              m_utxt  = void;
        ucontext_t*             m_ucur  = null;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Storage of Active Fiber
    ///////////////////////////////////////////////////////////////////////////


    //
    // Sets a thread-local reference to the current fiber object.
    //
    static void setThis( FiberImpl f )
    {
        sm_this = f;
    }

    static FiberImpl sm_this;

    ///////////////////////////////////////////////////////////////////////////
    // Context Switching
    ///////////////////////////////////////////////////////////////////////////


    //
    // Switches into the stack held by this fiber.
    //
    final void switchIn()
    {
        ThreadImpl   tobj = ThreadImpl.getThis();
        void**       oldp = &tobj.m_curr.tstack;
        void*        newp = m_ctxt.tstack;

        // NOTE: The order of operations here is very important.  The current
        //       stack top must be stored before m_lock is set, and pushContext
        //       must not be called until after m_lock is set.  This process
        //       is intended to prevent a race condition with the suspend
        //       mechanism used for garbage collection.  If it is not followed,
        //       a badly timed collection could cause the GC to scan from the
        //       bottom of one stack to the top of another, or to miss scanning
        //       a stack that still contains valid data.  The old stack pointer
        //       oldp will be set again before the context switch to guarantee
        //       that it points to exactly the correct stack location so the
        //       successive pop operations will succeed.
        *oldp = getStackTop();
        volatile tobj.m_lock = true;
        tobj.pushContext( m_ctxt );

        fiber_switchContext( oldp, newp );

        // NOTE: As above, these operations must be performed in a strict order
        //       to prevent Bad Things from happening.
        tobj.popContext();
        volatile tobj.m_lock = false;
        tobj.m_curr.tstack = tobj.m_curr.bstack;
    }


    //
    // Switches out of the current stack and into the enclosing stack.
    //
    final void switchOut()
    {
        ThreadImpl   tobj = ThreadImpl.getThis();
        void**       oldp = &m_ctxt.tstack;
        void*        newp = tobj.m_curr.within.tstack;

        // NOTE: The order of operations here is very important.  The current
        //       stack top must be stored before m_lock is set, and pushContext
        //       must not be called until after m_lock is set.  This process
        //       is intended to prevent a race condition with the suspend
        //       mechanism used for garbage collection.  If it is not followed,
        //       a badly timed collection could cause the GC to scan from the
        //       bottom of one stack to the top of another, or to miss scanning
        //       a stack that still contains valid data.  The old stack pointer
        //       oldp will be set again before the context switch to guarantee
        //       that it points to exactly the correct stack location so the
        //       successive pop operations will succeed.
        *oldp = getStackTop();
        volatile tobj.m_lock = true;

        fiber_switchContext( oldp, newp );

        // NOTE: As above, these operations must be performed in a strict order
        //       to prevent Bad Things from happening.
        // NOTE: If use of this fiber is multiplexed across threads, the thread
        //       executing here may be different from the one above, so get the
        //       current thread handle before unlocking, etc.
        tobj = ThreadImpl.getThis();
        volatile tobj.m_lock = false;
        tobj.m_curr.tstack = tobj.m_curr.bstack;
    }
}


///////////////////////////////////////////////////////////////////////////////
// Compiler interface for TLS on OSX
///////////////////////////////////////////////////////////////////////////////


version( OSX )
{
    // NOTE: The Mach-O object file format does not allow for thread local
    //       storage declarations. So instead we roll our own by putting tls
    //       into the sections bracketed by _tls_beg and _tls_end.
    //
    //       This function is called by the code emitted by the compiler.  It
    //       is expected to translate an address into the TLS static data to
    //       the corresponding address in the TLS dynamic per-thread data.
    extern (D) void* ___tls_get_addr( void* p )
    {
        // NOTE: p is an address in the TLS static data emitted by the
        //       compiler.  If it isn't, something is disastrously wrong.
        assert( p >= cast(void*) &_tls_beg && p < cast(void*) &_tls_end );
        auto obj = ThreadImpl.getThis();
        return obj.m_tls.ptr + (p - cast(void*) &_tls_beg);
    }
}
