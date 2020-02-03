/**
 * Handle page protection errors using D errors (exceptions). $(D NullPointerError) is
 * thrown when dereferencing null pointers. A system-dependent error is thrown in other
 * cases.
 *
 * Note: Only x86 and x86_64 are supported for now.
 *
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE_1_0.txt)
 * Authors:   Amaury SECHET, FeepingCreature, Vladimir Panteleev
 * Source: $(DRUNTIMESRC src/etc/linux/memory.d)
 */

module etc.linux.memoryerror;

version (CRuntime_Glibc)
{
    version (X86)
        version = MemoryErrorSupported;
    version (X86_64)
        version = MemoryErrorSupported;
}

version (MemoryErrorSupported):
@system:

import core.sys.posix.pthread;
import core.sys.posix.signal;
import core.sys.posix.ucontext;

import core.thread;

extern (C) int pthread_getattr_np(pthread_t thread, pthread_attr_t* attr) @nogc nothrow;

// Register and unregister memory error handler.

bool registerMemoryErrorHandler()
{
    sigaction_t action;
    action.sa_sigaction = &handleSignal;
    action.sa_flags = SA_SIGINFO;

    auto oldptr = &old_sigaction;

    return !sigaction(SIGSEGV, &action, oldptr);
}

bool deregisterMemoryErrorHandler()
{
    auto oldptr = &old_sigaction;

    return !sigaction(SIGSEGV, oldptr, null);
}

/**
 * Thrown on POSIX systems when a SIGSEGV signal is received.
 */
class InvalidPointerError : Error
{
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super("", file, line, next);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super("", file, line, next);
    }
}

/**
 * Thrown on stack overflow.
 */
class StackOverflow : InvalidPointerError
{
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(file, line, next);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(file, line, next);
    }
}

/**
 * Thrown on null pointer dereferences.
 */
class NullPointerError : InvalidPointerError
{
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(file, line, next);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(file, line, next);
    }
}

unittest
{
    int* getNull() { return null; }

    assert(registerMemoryErrorHandler());

    bool b;

    try
    {
        *getNull() = 42;
    }
    catch (NullPointerError)
    {
        b = true;
    }

    assert(b);

    b = false;

    try
    {
        *getNull() = 42;
    }
    catch (InvalidPointerError)
    {
        b = true;
    }

    assert(b);

    assert(deregisterMemoryErrorHandler());
}

unittest
{
    import core.sys.posix.pthread;

    assert(registerMemoryErrorHandler());

    pthread_attr_t attr;
    void* stackaddr;
    size_t size;

    assert(pthread_attr_init(&attr) == 0);
    assert(pthread_getattr_np(pthread_self(), &attr) == 0);
    assert(pthread_attr_getstack(&attr, &stackaddr, &size) == 0);
    assert(pthread_attr_destroy(&attr) == 0);

    bool b = false;

    try
    {
        b = *cast(bool*)(stackaddr - (bool*).sizeof);
    }
    catch (StackOverflow)
    {
        b = true;
    }

    assert(b);

    assert(deregisterMemoryErrorHandler());
}

// Signal handler space.

private:

__gshared sigaction_t old_sigaction;

alias typeof(ucontext_t.init.uc_mcontext.gregs[0]) RegType;

version (X86_64)
{
    static RegType savedRDI, savedRSI;

    extern(C)
    void handleSignal(int signum, siginfo_t* info, void* contextPtr) nothrow
    {
        auto context = cast(ucontext_t*)contextPtr;

        // Save registers into global thread local, to allow recovery.
        savedRDI = context.uc_mcontext.gregs[REG_RDI];
        savedRSI = context.uc_mcontext.gregs[REG_RSI];

        // Hijack current context so we call our handler.
        auto rip = context.uc_mcontext.gregs[REG_RIP];
        auto addr = cast(RegType) info.si_addr;
        context.uc_mcontext.gregs[REG_RDI] = addr;
        context.uc_mcontext.gregs[REG_RSI] = rip;
        context.uc_mcontext.gregs[REG_RIP] = cast(RegType) ((rip != addr)?&sigsegvDataHandler:&sigsegvCodeHandler);
    }

    // All handler functions must be called with faulting address in RDI and original RIP in RSI.

    // This function is called when the segfault's cause is to call an invalid function pointer.
    void sigsegvCodeHandler()
    {
        asm
        {
            naked;

            // Handle the stack for an invalid function call (segfault at RIP).
            // With the return pointer, the stack is now alligned.
            push RBP;
            mov RBP, RSP;

            jmp sigsegvDataHandler;
        }
    }

    void sigsegvDataHandler()
    {
        asm
        {
            naked;

            push RSI;   // return address (original RIP).
            push RBP;   // old RBP
            mov RBP, RSP;

            pushfq;     // Save flags.
            push RAX;   // RAX, RCX, RDX, and R8 to R11 are trash registers and must be preserved as local variables.
            push RCX;
            push RDX;
            push R8;
            push R9;
            push R10;
            push R11;    // With 10 pushes, the stack is still aligned.

            // Parameter address is already set as RAX.
            call sigsegvUserspaceProcess;

            // Restore RDI and RSI values.
            call restoreRDI;
            push RAX;   // RDI is in RAX. It is pushed and will be poped back to RDI.

            call restoreRSI;
            mov RSI, RAX;

            pop RDI;

            // Restore trash registers value.
            pop R11;
            pop R10;
            pop R9;
            pop R8;
            pop RDX;
            pop RCX;
            pop RAX;
            popfq;      // Restore flags.

            // Return
            pop RBP;
            ret;
        }
    }

    // The return value is stored in EAX and EDX, so this function restore the correct value for theses registers.
    RegType restoreRDI()
    {
        return savedRDI;
    }

    RegType restoreRSI()
    {
        return savedRSI;
    }
}
else version (X86)
{
    static RegType savedEAX, savedEDX;

    extern(C)
    void handleSignal(int signum, siginfo_t* info, void* contextPtr) nothrow
    {
        auto context = cast(ucontext_t*)contextPtr;

        // Save registers into global thread local, to allow recovery.
        savedEAX = context.uc_mcontext.gregs[REG_EAX];
        savedEDX = context.uc_mcontext.gregs[REG_EDX];

        // Hijack current context so we call our handler.
        auto eip = context.uc_mcontext.gregs[REG_EIP];
        auto addr = cast(RegType) info.si_addr;
        context.uc_mcontext.gregs[REG_EAX] = addr;
        context.uc_mcontext.gregs[REG_EDX] = eip;
        context.uc_mcontext.gregs[REG_EIP] = cast(RegType) ((eip != addr)?&sigsegvDataHandler:&sigsegvCodeHandler);
    }

    // All handler functions must be called with faulting address in EAX and original EIP in EDX.

    // This function is called when the segfault's cause is to call an invalid function pointer.
    void sigsegvCodeHandler()
    {
        asm
        {
            naked;

            // Handle the stack for an invalid function call (segfault at EIP).
            // 4 bytes are used for function pointer; We need 12 byte to keep stack aligned.
            sub ESP, 12;
            mov 8[ESP], EBP;
            mov EBP, ESP;

            jmp sigsegvDataHandler;
        }
    }

    void sigsegvDataHandler()
    {
        asm
        {
            naked;

            // We jump directly here if we are in a valid function call case.
            push EDX;   // return address (original EIP).
            push EBP;   // old EBP
            mov EBP, ESP;

            pushfd;     // Save flags.
            push ECX;   // ECX is a trash register and must be preserved as local variable.
                        // 4 pushes have been done. The stack is aligned.

            // Parameter address is already set as EAX.
            call sigsegvUserspaceProcess;

            // Restore register values and return.
            call restoreRegisters;

            pop ECX;
            popfd;      // Restore flags.

            // Return
            pop EBP;
            ret;
        }
    }

    // The return value is stored in EAX and EDX, so this function restore the correct value for theses registers.
    RegType[2] restoreRegisters()
    {
        RegType[2] restore;
        restore[0] = savedEAX;
        restore[1] = savedEDX;

        return restore;
    }
}
else
{
    static assert(false, "Unsupported architecture.");
}

// This should be calculated by druntime.
// TODO: Add a core.memory function for this.
enum PAGE_SIZE = 4096;

// The first 64Kb are reserved for detecting null pointer dereferences.
enum MEMORY_RESERVED_FOR_NULL_DEREFERENCE = 4096 * 16;

// User space handler
void sigsegvUserspaceProcess(void* address)
{
    // SEGV_MAPERR, SEGV_ACCERR.
    //
    // The first page is protected to detect null dereferences.
    if ((cast(size_t) address) < MEMORY_RESERVED_FOR_NULL_DEREFERENCE)
    {
        throw new NullPointerError();
    }

    pthread_attr_t attr;
    pthread_attr_init(&attr);

    int rc = pthread_getattr_np(pthread_self(), &attr);
    if (rc != 0)
        throw new InvalidPointerError();
    void* stackaddr;
    size_t _size;
    rc = pthread_attr_getstack(&attr, &stackaddr, &_size);
    if (rc != 0)
        throw new InvalidPointerError();

    /**
     * On main thread, we cannot get guard size via pthread_attr_getguardsize.
     * So we rely on the kernel's own stack guard will work.
     */
    if (thread_isMainThread())
    {
        pthread_attr_destroy(&attr);

        /**
         * We assume,
         *   1. The size of the guard area == PAGE_SIZE.
         *   2. A user never defines own stack-guard implementation.
         *   3. stackaddr is aligned to a page. (which is guaranteed by pthread_attr_getstack)
         */
        if (stackaddr - PAGE_SIZE < address && address < stackaddr)
            throw new StackOverflow();
    }
    else
    {
        size_t guardsize;
        rc = pthread_attr_getguardsize(&attr, &guardsize);
        if (rc != 0 || guardsize == 0)
            throw new InvalidPointerError();

        pthread_attr_destroy(&attr);

        /**
         * GLibc < 2.27 has a bug that the thread implementation includes the guard
         * area within the stack size allocation, see `man pthread_attr_setguardsize`.
         */
        if (stackaddr - guardsize < address && address < stackaddr + guardsize)
            throw new StackOverflow();
    }
    throw new InvalidPointerError();
}
