
/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 * Source: $(LINK http://www.dsource.org/projects/druntime/browser/trunk/src/core/thread.d)
 */
module core.thread;


public import core.time; // for Duration


// this should be true for most architectures
version = StackGrowsDown;

version(Posix)
{
    import core.sys.posix.unistd;
    alias core.sys.posix.unistd.getpid getpid;
}
else version (Windows)
{
    import core.sys.windows.windows;
    alias core.sys.windows.windows.GetCurrentProcessId getpid;
}


///////////////////////////////////////////////////////////////////////////////
// Thread and Fiber Exceptions
///////////////////////////////////////////////////////////////////////////////


class ThreadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__);
}


class FiberException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__);
}


///////////////////////////////////////////////////////////////////////////////
// Thread
///////////////////////////////////////////////////////////////////////////////


class Thread
{
    ///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////


    this( void function() fn, size_t sz = 0 );


    this( void delegate() dg, size_t sz = 0 );


    ~this();


    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////


    final void start();


    final Throwable join( bool rethrow = true );


    ///////////////////////////////////////////////////////////////////////////
    // General Properties
    ///////////////////////////////////////////////////////////////////////////


    final @property string name();


    final @property void name( string val );


    final @property bool isDaemon();


    final @property void isDaemon( bool val );


    final @property bool isRunning();


    ///////////////////////////////////////////////////////////////////////////
    // Thread Priority Actions
    ///////////////////////////////////////////////////////////////////////////


    __gshared const int PRIORITY_MIN;


    __gshared const int PRIORITY_MAX;


    final @property int priority();


    final @property void priority( int val );


    ///////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ///////////////////////////////////////////////////////////////////////////


    static void sleep( Duration val );


    deprecated("Please use the overload of sleep which takes a Duration.")
    static void sleep( long period );


    static void yield();


    ///////////////////////////////////////////////////////////////////////////
    // Thread Accessors
    ///////////////////////////////////////////////////////////////////////////


    static Thread getThis();


    static Thread[] getAll();


    static int opApply( scope int delegate( ref Thread ) dg );


    ///////////////////////////////////////////////////////////////////////////
    // Static Initalizer
    ///////////////////////////////////////////////////////////////////////////


    // This initializer is used to set thread constants.  All functional
    // initialization occurs within thread_init().
    shared static this();


    ///////////////////////////////////////////////////////////////////////////
    // Stuff That Should Go Away
    ///////////////////////////////////////////////////////////////////////////


private:
    //
    // Standard types
    //
    version( Windows )
    {
        alias uint TLSKey;
        alias uint ThreadAddr;
    }
    else version( Posix )
    {
        import core.sys.posix.pthread;
        alias pthread_key_t TLSKey;
        alias pthread_t     ThreadAddr;
    }

    // These must be kept in sync with core/thread.d
    version (D_LP64)
    {
        version (Windows)      enum ThreadSize = 312;
        else version (OSX)     enum ThreadSize = 320;
        else version (Solaris) enum ThreadSize = 176;
        else version (Posix)   enum ThreadSize = 184;
        else static assert(0, "Platform not supported.");
    }
    else
    {
        static assert((void*).sizeof == 4); // 32-bit

        version (Windows)      enum ThreadSize = 128;
        else version (OSX)     enum ThreadSize = 128;
        else version (Posix)   enum ThreadSize =  92;
        else static assert(0, "Platform not supported.");
    }

    void data[ThreadSize - __traits(classInstanceSize, Object)] = void;
}


///////////////////////////////////////////////////////////////////////////////
// GC Support Routines
///////////////////////////////////////////////////////////////////////////////


extern (C) void thread_init();


extern (C) bool thread_isMainThread();


extern (C) Thread thread_attachThis();


version( Windows )
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

    extern (C) Thread thread_attachByAddr( Thread.ThreadAddr addr );

    extern (C) Thread thread_attachByAddrB( Thread.ThreadAddr addr, void* bstack );
}


extern (C) void thread_detachThis();


extern (C) void thread_detachByAddr( Thread.ThreadAddr addr );


static Thread thread_findByAddr( Thread.ThreadAddr addr );


extern (C) void thread_setThis(Thread t);


extern (C) void thread_joinAll();


// Performs intermediate shutdown of the thread module.
shared static ~this();


extern (C) void thread_suspendAll();


extern (C) void thread_resumeAll();


enum ScanType
{
    stack,
    tls,
}

alias void delegate(void*, void*) ScanAllThreadsFn;
alias void delegate(ScanType, void*, void*) ScanAllThreadsTypeFn;


extern (C) void thread_scanAllType( scope ScanAllThreadsTypeFn scan );


extern (C) void thread_scanAll( scope ScanAllThreadsFn scan );


extern (C) void thread_enterCriticalRegion();


extern (C) void thread_exitCriticalRegion();


extern (C) bool thread_inCriticalRegion();


enum IsMarked : int
{
         no,
        yes,
    unknown,
}

alias IsMarked delegate( void* addr ) IsMarkedDg;


extern(C) void thread_processGCMarks( scope IsMarkedDg isMarked );


extern (C) void* thread_stackTop();


extern (C) void* thread_stackBottom();


///////////////////////////////////////////////////////////////////////////////
// Thread Group
///////////////////////////////////////////////////////////////////////////////


class ThreadGroup
{
    final Thread create( void function() fn );


    final Thread create( void delegate() dg );


    final void add( Thread t );


    final void remove( Thread t );


    final int opApply( scope int delegate( ref Thread ) dg );


    final void joinAll( bool rethrow = true );


private:

    // These must be kept in sync with core/thread.d
    version (D_LP64)
    {
        enum ThreadGroupSize = 24;
    }
    else
    {
        static assert((void*).sizeof == 4); // 32-bit
        enum ThreadGroupSize = 12;
    }

    void data[ThreadGroupSize - __traits(classInstanceSize, Object)] = void;
}


///////////////////////////////////////////////////////////////////////////////
// Fiber Platform Detection and Memory Allocation
///////////////////////////////////////////////////////////////////////////////

private extern __gshared const size_t PAGESIZE;

shared static this();


///////////////////////////////////////////////////////////////////////////////
// Fiber
///////////////////////////////////////////////////////////////////////////////


class Fiber
{
    ///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////


    this( void function() fn, size_t sz = PAGESIZE*4 );


    this( void delegate() dg, size_t sz = PAGESIZE*4 );


    ~this();


    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////


    final Object call( bool rethrow = true );


    final void reset();


    final void reset( void function() fn );


    final void reset( void delegate() dg );

    ///////////////////////////////////////////////////////////////////////////
    // General Properties
    ///////////////////////////////////////////////////////////////////////////


    enum State
    {
        HOLD,
        EXEC,
        TERM,
    }


    final @property State state() const;


    ///////////////////////////////////////////////////////////////////////////
    // Actions on Calling Fiber
    ///////////////////////////////////////////////////////////////////////////


    static void yield();


    static void yieldAndThrow( Throwable t );


    ///////////////////////////////////////////////////////////////////////////
    // Fiber Accessors
    ///////////////////////////////////////////////////////////////////////////


    static Fiber getThis();


    ///////////////////////////////////////////////////////////////////////////
    // Static Initialization
    ///////////////////////////////////////////////////////////////////////////


    version( Posix )
    {
        static this();
    }

private:

    // These must be kept in sync with core/thread.d
    version (D_LP64)
    {
        version (Windows)      enum FiberSize = 88;
        else version (OSX)     enum FiberSize = 88;
        else version (Posix)   enum FiberSize = 88;
        else static assert(0, "Platform not supported.");
    }
    else
    {
        static assert((void*).sizeof == 4); // 32-bit

        version (Windows)      enum FiberSize = 44;
        else version (OSX)     enum FiberSize = 44;
        else version (Posix)   enum FiberSize = 44;
        else static assert(0, "Platform not supported.");
    }

    void data[FiberSize - __traits(classInstanceSize, Object)] = void;
}

version( OSX )
{
    // NOTE: The Mach-O object file format does not allow for thread local
    //       storage declarations. So instead we roll our own by putting tls
    //       into the sections bracketed by _tls_beg and _tls_end.
    //
    //       This function is called by the code emitted by the compiler.  It
    //       is expected to translate an address into the TLS static data to
    //       the corresponding address in the TLS dynamic per-thread data.
    extern (D) void* ___tls_get_addr( void* p );
}
