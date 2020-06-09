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
    private extern (C) uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*) nothrow @nogc;
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
