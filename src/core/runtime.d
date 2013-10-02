/**
 * The runtime module exposes information specific to the D runtime code.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/_runtime.d)
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.runtime;

version (Windows) import core.stdc.wchar_ : wchar_t;


/// C interface for Runtime.loadLibrary
extern (C) void* rt_loadLibrary(const char* name);
/// ditto
version (Windows) extern (C) void* rt_loadLibraryW(const wchar_t* name);
/// C interface for Runtime.unloadLibrary
extern (C) int rt_unloadLibrary(void* ptr);

private
{
    alias bool function() ModuleUnitTester;
    alias bool function(Object) CollectHandler;
    alias Throwable.TraceInfo function( void* ptr ) TraceHandler;

    extern (C) void rt_setCollectHandler( CollectHandler h );
    extern (C) CollectHandler rt_getCollectHandler();

    extern (C) void rt_setTraceHandler( TraceHandler h );
    extern (C) TraceHandler rt_getTraceHandler();

    alias void delegate( Throwable ) ExceptionHandler;
    extern (C) bool rt_init( ExceptionHandler dg = null );
    extern (C) bool rt_term( ExceptionHandler dg = null );

    extern (C) void* thread_stackBottom();

    extern (C) string[] rt_args();
    extern (C) CArgs rt_cArgs();

    // backtrace
    version( linux )
        import core.sys.linux.execinfo;
    else version( OSX )
        import core.sys.osx.execinfo;
    else version( FreeBSD )
        import core.sys.freebsd.execinfo;
    else version( Windows )
        import core.sys.windows.stacktrace;

    // For runModuleUnitTests error reporting.
    version( Windows )
    {
        import core.sys.windows.windows;
    }
    else version( Posix )
    {
        import core.sys.posix.unistd;
    }
}


static this()
{
    // NOTE: Some module ctors will run before this handler is set, so it's
    //       still possible the app could exit without a stack trace.  If
    //       this becomes an issue, the handler could be set in C main
    //       before the module ctors are run.
    Runtime.traceHandler = &defaultTraceHandler;
}


///////////////////////////////////////////////////////////////////////////////
// Runtime
///////////////////////////////////////////////////////////////////////////////

/**
 * Stores the unprocessed arguments supplied when the
 * process was started.
 */
struct CArgs
{
    int argc; /// The argument count.
    char** argv; /// The arguments as a C array of strings.
}

/**
 * This struct encapsulates all functionality related to the underlying runtime
 * module for the calling context.
 */
struct Runtime
{
    /**
     * Initializes the runtime.  This call is to be used in instances where the
     * standard program initialization process is not executed.  This is most
     * often in shared libraries or in libraries linked to a C program.
     *
     * Params:
     *  dg = A delegate which will receive any exception thrown during the
     *       initialization process or null if such exceptions should be
     *       discarded.
     *
     * Returns:
     *  true if initialization succeeds and false if initialization fails.
     */
    static bool initialize( ExceptionHandler dg = null )
    {
        return rt_init( dg );
    }


    /**
     * Terminates the runtime. This call is to be used in instances
     * where the standard program termination process will not be not
     * executed. This is most often in shared libraries or in
     * libraries linked to a C program. All non-daemon threads must be
     * joined or detached prior to calling this function. See also
     * $(CXREF thread, thread_joinAll) and $(CXREF thread, thread_detachThis).
     *
     * Params:
     *  dg = A delegate which will receive any exception thrown during the
     *       termination process or null if such exceptions should be
     *       discarded.
     *
     * Returns:
     *  true if termination succeeds and false if termination fails.
     */
    static bool terminate( ExceptionHandler dg = null )
    {
        return rt_term( dg );
    }


    /**
     * Returns the arguments supplied when the process was started.
     *
     * Returns:
     *  The arguments supplied when this process was started.
     */
    static @property string[] args()
    {
        return rt_args();
    }

    /**
     * Returns the unprocessed C arguments supplied when the process was
     * started. Use this when you need to supply argc and argv to C libraries.
     *
     * Returns:
     *  A $(LREF CArgs) struct with the arguments supplied when this process was started.
     */
    static @property CArgs cArgs()
    {
        return rt_cArgs();
    }

    /// deprecated, same as $(LREF .loadLib) but returns a raw handle.
    deprecated("Please use core.runtime.loadLib instead.")
    static void* loadLibrary()(in char[] name)
    {
        return loadLib(name).handle;
    }

    /// deprecated, same as $(LREF .unloadLib) but take a raw handle.
    deprecated("Please use core.runtime.unloadLib instead.")
    static void unloadLibrary()(void* handle)
    {
        auto lib = Library(handle);
        unloadLib(lib);
    }

    /**
     * Overrides the default trace mechanism with s user-supplied version.  A
     * trace represents the context from which an exception was thrown, and the
     * trace handler will be called when this occurs.  The pointer supplied to
     * this routine indicates the base address from which tracing should occur.
     * If the supplied pointer is null then the trace routine should determine
     * an appropriate calling context from which to begin the trace.
     *
     * Params:
     *  h = The new trace handler.  Set to null to use the default handler.
     */
    static @property void traceHandler( TraceHandler h )
    {
        rt_setTraceHandler( h );
    }

    /**
     * Gets the current trace handler.
     *
     * Returns:
     *  The current trace handler or null if none has been set.
     */
    static @property TraceHandler traceHandler()
    {
        return rt_getTraceHandler();
    }

    /**
     * Overrides the default collect hander with a user-supplied version.  This
     * routine will be called for each resource object that is finalized in a
     * non-deterministic manner--typically during a garbage collection cycle.
     * If the supplied routine returns true then the object's dtor will called
     * as normal, but if the routine returns false than the dtor will not be
     * called.  The default behavior is for all object dtors to be called.
     *
     * Params:
     *  h = The new collect handler.  Set to null to use the default handler.
     */
    static @property void collectHandler( CollectHandler h )
    {
        rt_setCollectHandler( h );
    }


    /**
     * Gets the current collect handler.
     *
     * Returns:
     *  The current collect handler or null if none has been set.
     */
    static @property CollectHandler collectHandler()
    {
        return rt_getCollectHandler();
    }


    /**
     * Overrides the default module unit tester with a user-supplied version.
     * This routine will be called once on program initialization.  The return
     * value of this routine indicates to the runtime whether the tests ran
     * without error.
     *
     * Params:
     *  h = The new unit tester.  Set to null to use the default unit tester.
     */
    static @property void moduleUnitTester( ModuleUnitTester h )
    {
        sm_moduleUnitTester = h;
    }


    /**
     * Gets the current module unit tester.
     *
     * Returns:
     *  The current module unit tester handler or null if none has been set.
     */
    static @property ModuleUnitTester moduleUnitTester()
    {
        return sm_moduleUnitTester;
    }


private:
    // NOTE: This field will only ever be set in a static ctor and should
    //       never occur within any but the main thread, so it is safe to
    //       make it __gshared.
    __gshared ModuleUnitTester sm_moduleUnitTester = null;
}

version (CoreDdoc)
{
    version = UseDecls;
    version = UseUnittest;
}
else version (Windows)
{
    version = UseUnittest;
}
else version (Shared) // compiling a shared druntime
{
    version = UseUnittest;
}
else
{
    version = UseDecls;
}

// Workaround Bug 3956. Optlink strips leading underscores
// of exported symbols. Except for the first one :(.
version (Win32) export __gshared uint _dummy; // So that's the first one hopefully.

/**
 * The Library struct is a loaded library. It contains functionality
 * to load symbols and perform runtime introspection of the library.
 */
version (CoreDdoc) struct Library
{
    /// disabled default constructor
    @disable this();

    /**
     * Constructs a Library from a native platform handle.
     *
     * Params:
     *   handle = The native platform handle.
     */
    this(void* handle);

    /**
     * Tries to locate a function with type FT and fully qualified
     * name fqn in this library.  For extern(C) functions fqn is the
     * plain function name.
     *
     * Params:
     *   T = The function pointer type.
     *   fqn = The fully qualified name of the function.
     *
     * Returns:
     *   A pointer to the function on success or null.
     */
    T findFunc(T:FT*, FT)(string fqn) if(is(FT == function));

    /// ditto
    T findFunc(T:FT*, string fqn, FT)() if(is(FT == function));

    /**
     * Tries to locate a function in this library using the type and
     * fully qualified name of a .di file declaration.
     *
     * Params:
     *   func = An alias to the function declaration.
     *
     * Returns:
     *   A pointer to the function on success or null.
     */
    typeof(func)* findFunc(alias func)() if (is(typeof(func) == function));

    /**
     * Tries to locate a variable with type T and fully qualified name
     * fqn in this library.  For extern(C) variables fqn is the
     * plain variable name.
     *
     * Params:
     *   T = The variable type.
     *   fqn = The fully qualified name of the variable.
     *
     * Returns:
     *   A pointer to the variable on success or null.
     */
    T* findVar(T)(string fqn);

    /// ditto
    T* findVar(T, string fqn)();

    /**
     * Tries to locate a variable in this library using the type and
     * fully qualified name of a .di file declaration.
     *
     * Params:
     *   var = An alias to the variable declaration.
     *
     * Returns:
     *   A pointer to the variable on success or null.
     */
    typeof(var)* findVar(alias var)() if (!is(typeof(var) == function) && hasLinkage!var);

    /// Returns the native platform handle.
    @property void* handle();

private:
    template hasLinkage(alias var) {}

    void* _handle;
}

// example unittest needs to follow documentation (Bug 11133)
///
version (UseUnittest) unittest
{
    version (Windows)
    {
        auto lib = Library(GetModuleHandleA(null));
    }
    else
    {
        auto lib = loadLib(null); // the executable
        scope (exit) lib.unloadLib();
    }
    auto load1 = lib.findFunc!(size_t function(string))("core.runtime.TestStruct.func");
    auto load2 = lib.findFunc!(size_t function(string), "core.runtime.TestStruct.func")();
    auto load3 = lib.findFunc!(TestStruct.func)();
    assert(load1 is load2);
    assert(load2 is load3);
    assert(load3 is &TestStruct.func);

    auto var1 = lib.findVar!(size_t)("core.runtime.TestStruct.var");
    auto var2 = lib.findVar!(size_t, "core.runtime.TestStruct.var")();
    auto var3 = lib.findVar!(TestStruct.var)();
    assert(var1 is var2);
    assert(var2 is var3);
    assert(var3 is &TestStruct.var);

    // can only load variables with linkage
    static struct Export
    {
    export:
        __gshared uint num1 = 1;
        static shared uint num2 = 2;
        static const uint num3 = 3;

        shared uint num4 = 4; // stack variables have no linkage
        enum num5 = 5;        // manifest constants have no linkage
        static uint num6 = 6; // TLS variables have no linkage
    }
    assert(*lib.findVar!(Export.num1)() == 1);
    assert(*lib.findVar!(Export.num2)() == 2);
    assert(*lib.findVar!(Export.num3)() == 3);

    static assert(!__traits(compiles, lib.findVar!num4()));
    static assert(!__traits(compiles, lib.findVar!num5()));
    static assert(!__traits(compiles, lib.findVar!num6()));
}

version (UseUnittest)
{
    struct TestStruct
    {
    export:
        static size_t func(string s) { return s.length; }
        __gshared size_t var;
    }

    unittest
    {
        static bool throws(void delegate() dg)
        {
            try
                dg();
            catch (Throwable)
                return true;
            return false;
        }
        static assert(!__traits(compiles, {Library lib;}));
        assert(throws({loadLib("nonexistent");}));

        debug assert(throws({auto lib = Library(null);}));
        version (Posix)
        {
            auto lib = loadLib(null);
            lib.unloadLib();
            debug assert(throws({lib.findFunc!(TestStruct.func)();}));
        }
    }
}

version (CoreDdoc) // see above unittest (Bug 11133)
{
}
else version (Windows)
{
    struct Library
    {
        import core.sys.windows.windows : GetProcAddress;
        version (Win32)
        {
            // Bug 3956 - optlink strips underscores
            mixin LibraryImpl!(function(h, n) =>
                GetProcAddress(h, n[0] == '_' && n[1] == 'D' ? n+1 : n));
        }
        else
        {
            mixin LibraryImpl!GetProcAddress;
        }
    }
}
else version (Posix)
{
    struct Library
    {
        import core.sys.posix.dlfcn : dlsym;
        mixin LibraryImpl!dlsym;
    }
}
else
{
    static assert(0, "unimplemented");
}


version (UseDecls)
{
    /**
     * Locates a dynamic library with the supplied library name and
     * dynamically loads it into the caller's address space. On error
     * the function will throw an Exception.
     *
     * Params:
     *  name = The name of the dynamic library to load.
     *
     * Returns:
     *  The loaded Library.
     */
    Library loadLib(in char[] name);

    /**
     * Unloads the dynamic library lib. This will set the internal
     * handle to null. On error the function will throw an Exception.
     *
     * Params:
     *  lib = The library to unload.
     */
    void unloadLib(ref Library lib);
}
else version (Windows)
{
    Library loadLib(in char[] name)
    {
        import core.stdc.stdlib : free, malloc;
        import core.sys.windows.windows;

        if (name.length == 0) return Library(null);
        // Load a DLL at runtime
        enum CP_UTF8 = 65001;
        auto len = MultiByteToWideChar(
            CP_UTF8, 0, name.ptr, cast(int)name.length, null, 0);
        if (len == 0)
            return Library(null);

        auto buf = cast(wchar_t*)malloc((len+1) * wchar_t.sizeof);
        if (buf is null) return Library(null);
        scope (exit) free(buf);

        len = MultiByteToWideChar(
            CP_UTF8, 0, name.ptr, cast(int)name.length, buf, len);
        if (len == 0)
            return Library(null);

        buf[len] = '\0';

        auto res = rt_loadLibraryW(buf);
        if (res is null)
            loadError("Failed to load Library '"~name.idup~"'.");
        return Library(res);
    }

    void unloadLib(ref Library lib)
    {
        scope (exit) lib._handle = null;
        if (!rt_unloadLibrary(lib.handle))
            loadError("Failed to unload Library");
    }

    private void loadError(string msg)
    {
        if (auto err = GetLastError())
        {
            import core.stdc.stdio : snprintf;
            char[10] buf=void;
            immutable len = snprintf(buf.ptr, buf.length, "%u", err);
            len > 0 && cast(size_t)len < buf.length || assert(0);
            msg ~= " (Error Code: "~buf[0 .. len]~")";
        }
        throw new Exception(msg);
    }
}
else version (Shared)
{
    Library loadLib(in char[] name)
    {
        import core.stdc.stdlib : free, malloc;

        /* Need a 0-terminated C string for the dll name
         */
        immutable len = name.length;
        auto buf = cast(char*)malloc(len + 1);
        if (!buf) return Library(null);
        scope (exit) free(buf);

        buf[0 .. len] = name[];
        buf[len] = 0;

        auto res = rt_loadLibrary(buf);
        if (res is null)
            loadError("Failed to load Library '"~name.idup~"'.");
        return Library(res);
    }

    void unloadLib(ref Library lib)
    {
        scope (exit) lib._handle = null;
        if (!rt_unloadLibrary(lib.handle))
            loadError("Failed to unload Library.");
    }

    private void loadError(string msg)
    {
        import core.stdc.string : strlen;
        import core.sys.posix.dlfcn : dlerror;

        if (auto err = dlerror())
            msg ~= " ("~err[0 .. strlen(err)]~")";
        throw new Exception(msg);
    }
}


// implementation using GetProcAddress or dlsym
private mixin template LibraryImpl(alias dlsym)
{
    import core.demangle : mangle, mangleFunc;

    @disable this();

    this(void* handle)
    {
        _handle = handle;
    }

    T findFunc(T:FT*, FT)(string fqn) if(is(FT == function))
    {
        char[256] buf = void;
        auto mangling = mangleFunc!(T)(fqn, buf);
        return cast(T)dlsym(handle, toStringz(mangling, buf.length));
    }

    T findFunc(T:FT*, string fqn, FT)() if(is(FT == function))
    {
        static const mangling = mangleFunc!(T)(fqn) ~ '\0';
        return cast(T)dlsym(handle, mangling.ptr);
    }

    typeof(func)* findFunc(alias func)() if (is(typeof(func) == function))
    {
        static const mangling = func.mangleof ~ '\0';
        return cast(typeof(func)*)dlsym(handle, mangling.ptr);
    }

    T* findVar(T)(string fqn)
    {
        char[256] buf = void;
        auto mangling = mangle!(T)(fqn, buf);
        return cast(T*)dlsym(handle, toStringz(mangling, buf.length));
    }

    T* findVar(T, string fqn)()
    {
        static const mangling = mangle!(T)(fqn) ~ '\0';
        return cast(T*)dlsym(handle, mangling.ptr);
    }

    typeof(var)* findVar(alias var)() if (!is(typeof(var) == function) && hasLinkage!var)
    {
        static const mangling = var.mangleof ~ '\0';
        return cast(typeof(var)*)dlsym(handle, mangling.ptr);
    }

    @property void* handle()
    {
        return _handle;
    }

    invariant()
    {
        assert(_handle !is null);
    }

private:
    template hasLinkage(alias var)
    {
        // TLS: cannot take address of thread-local variable var at compile time
        // enum: constant var is not an lvalue
        // local: non-constant expression &var
        // use is(typeof) to avoid linking in var
        enum hasLinkage = is(typeof({static const varref = &var;}));
        static assert(hasLinkage); // for better diagnostic message
    }

    char* toStringz(char[] buf, size_t knownSize)
    {
        immutable nulpos = buf.length;
        if (nulpos >= knownSize) ++buf.length;
        buf.ptr[nulpos] = 0;
        return buf.ptr;
    }

    void* _handle;
}

///////////////////////////////////////////////////////////////////////////////
// Overridable Callbacks
///////////////////////////////////////////////////////////////////////////////


/**
 * This routine is called by the runtime to run module unit tests on startup.
 * The user-supplied unit tester will be called if one has been supplied,
 * otherwise all unit tests will be run in sequence.
 *
 * Returns:
 *  true if execution should continue after testing is complete and false if
 *  not.  Default behavior is to return true.
 */
extern (C) bool runModuleUnitTests()
{
    static if( __traits( compiles, backtrace ) )
    {
        import core.sys.posix.signal; // segv handler

        static extern (C) void unittestSegvHandler( int signum, siginfo_t* info, void* ptr )
        {
            static enum MAXFRAMES = 128;
            void*[MAXFRAMES]  callstack;
            int               numframes;

            numframes = backtrace( callstack.ptr, MAXFRAMES );
            backtrace_symbols_fd( callstack.ptr, numframes, 2 );
        }

        sigaction_t action = void;
        sigaction_t oldseg = void;
        sigaction_t oldbus = void;

        (cast(byte*) &action)[0 .. action.sizeof] = 0;
        sigfillset( &action.sa_mask ); // block other signals
        action.sa_flags = SA_SIGINFO | SA_RESETHAND;
        action.sa_sigaction = &unittestSegvHandler;
        sigaction( SIGSEGV, &action, &oldseg );
        sigaction( SIGBUS, &action, &oldbus );
        scope( exit )
        {
            sigaction( SIGSEGV, &oldseg, null );
            sigaction( SIGBUS, &oldbus, null );
        }
    }

    static struct Console
    {
        Console opCall( in char[] val )
        {
            version( Windows )
            {
                DWORD count = void;
                assert(val.length <= uint.max, "val must be less than or equal to uint.max");
                WriteFile( GetStdHandle( 0xfffffff5 ), val.ptr, cast(uint)val.length, &count, null );
            }
            else version( Posix )
            {
                write( 2, val.ptr, val.length );
            }
            return this;
        }
    }

    static __gshared Console console;

    if( Runtime.sm_moduleUnitTester is null )
    {
        size_t failed = 0;
        foreach( m; ModuleInfo )
        {
            if( m )
            {
                auto fp = m.unitTest;

                if( fp )
                {
                    try
                    {
                        fp();
                    }
                    catch( Throwable e )
                    {
                        console( e.toString() )( "\n" );
                        failed++;
                    }
                }
            }
        }
        return failed == 0;
    }
    return Runtime.sm_moduleUnitTester();
}


///////////////////////////////////////////////////////////////////////////////
// Default Implementations
///////////////////////////////////////////////////////////////////////////////


/**
 *
 */
import core.stdc.stdio;
Throwable.TraceInfo defaultTraceHandler( void* ptr = null )
{
    //printf("runtime.defaultTraceHandler()\n");
    static if( __traits( compiles, backtrace ) )
    {
        import core.demangle;
        import core.stdc.stdlib : free;
        import core.stdc.string : strlen, memchr, memmove;

        class DefaultTraceInfo : Throwable.TraceInfo
        {
            this()
            {
                static enum MAXFRAMES = 128;
                void*[MAXFRAMES]  callstack;
                numframes = 0; //backtrace( callstack, MAXFRAMES );
                if (numframes < 2) // backtrace() failed, do it ourselves
                {
                    static void** getBasePtr()
                    {
                        version( D_InlineAsm_X86 )
                            asm { naked; mov EAX, EBP; ret; }
                        else
                        version( D_InlineAsm_X86_64 )
                            asm { naked; mov RAX, RBP; ret; }
                        else
                            return null;
                    }

                    auto  stackTop    = getBasePtr();
                    auto  stackBottom = cast(void**) thread_stackBottom();
                    void* dummy;

                    if( stackTop && &dummy < stackTop && stackTop < stackBottom )
                    {
                        auto stackPtr = stackTop;

                        for( numframes = 0; stackTop <= stackPtr &&
                                            stackPtr < stackBottom &&
                                            numframes < MAXFRAMES; )
                        {
                            callstack[numframes++] = *(stackPtr + 1);
                            stackPtr = cast(void**) *stackPtr;
                        }
                    }
                }
                framelist = backtrace_symbols( callstack.ptr, numframes );
            }

            ~this()
            {
                free( framelist );
            }

            override int opApply( scope int delegate(ref const(char[])) dg ) const
            {
                return opApply( (ref size_t, ref const(char[]) buf)
                                {
                                    return dg( buf );
                                } );
            }

            override int opApply( scope int delegate(ref size_t, ref const(char[])) dg ) const
            {
                version( Posix )
                {
                    // NOTE: The first 5 frames with the current implementation are
                    //       inside core.runtime and the object code, so eliminate
                    //       these for readability.  The alternative would be to
                    //       exclude the first N frames that are in a list of
                    //       mangled function names.
                    static enum FIRSTFRAME = 5;
                }
                else
                {
                    // NOTE: On Windows, the number of frames to exclude is based on
                    //       whether the exception is user or system-generated, so
                    //       it may be necessary to exclude a list of function names
                    //       instead.
                    static enum FIRSTFRAME = 0;
                }
                int ret = 0;

                for( int i = FIRSTFRAME; i < numframes; ++i )
                {
                    char[4096] fixbuf;
                    auto buf = framelist[i][0 .. strlen(framelist[i])];
                    auto pos = cast(size_t)(i - FIRSTFRAME);
                    buf = fixline( buf, fixbuf );
                    ret = dg( pos, buf );
                    if( ret )
                        break;
                }
                return ret;
            }

            override string toString() const
            {
                string buf;
                foreach( i, line; this )
                    buf ~= i ? "\n" ~ line : line;
                return buf;
            }

        private:
            int     numframes;
            char**  framelist;

        private:
            const(char)[] fixline( const(char)[] buf, ref char[4096] fixbuf ) const
            {
                size_t symBeg, symEnd;
                version( OSX )
                {
                    // format is:
                    //  1  module    0x00000000 D6module4funcAFZv + 0
                    for( size_t i = 0, n = 0; i < buf.length; i++ )
                    {
                        if( ' ' == buf[i] )
                        {
                            n++;
                            while( i < buf.length && ' ' == buf[i] )
                                i++;
                            if( 3 > n )
                                continue;
                            symBeg = i;
                            while( i < buf.length && ' ' != buf[i] )
                                i++;
                            symEnd = i;
                            break;
                        }
                    }
                }
                else version( linux )
                {
                    // format is:  module(_D6module4funcAFZv) [0x00000000]
                    // or:         module(_D6module4funcAFZv+0x78) [0x00000000]
                    auto bptr = cast(char*) memchr( buf.ptr, '(', buf.length );
                    auto eptr = cast(char*) memchr( buf.ptr, ')', buf.length );
                    auto pptr = cast(char*) memchr( buf.ptr, '+', buf.length );

                    if (pptr && pptr < eptr)
                        eptr = pptr;

                    if( bptr++ && eptr )
                    {
                        symBeg = bptr - buf.ptr;
                        symEnd = eptr - buf.ptr;
                    }
                }
                else version( FreeBSD )
                {
                    // format is: 0x00000000 <_D6module4funcAFZv+0x78> at module
                    auto bptr = cast(char*) memchr( buf.ptr, '<', buf.length );
                    auto eptr = cast(char*) memchr( buf.ptr, '+', buf.length );

                    if( bptr++ && eptr )
                    {
                        symBeg = bptr - buf.ptr;
                        symEnd = eptr - buf.ptr;
                    }
                }
                else
                {
                    // fallthrough
                }

                assert(symBeg < buf.length && symEnd < buf.length);
                assert(symBeg < symEnd);

                enum min = (size_t a, size_t b) => a <= b ? a : b;
                if (symBeg == symEnd || symBeg >= fixbuf.length)
                {
                    immutable len = min(buf.length, fixbuf.length);
                    fixbuf[0 .. len] = buf[0 .. len];
                    return fixbuf[0 .. len];
                }
                else
                {
                    fixbuf[0 .. symBeg] = buf[0 .. symBeg];

                    auto sym = demangle(buf[symBeg .. symEnd], fixbuf[symBeg .. $]);

                    if (sym.ptr !is fixbuf.ptr + symBeg)
                    {
                        // demangle reallocated the buffer, copy the symbol to fixbuf
                        immutable len = min(fixbuf.length - symBeg, sym.length);
                        memmove(fixbuf.ptr + symBeg, sym.ptr, len);
                        if (symBeg + len == fixbuf.length)
                            return fixbuf[];
                    }

                    immutable pos = symBeg + sym.length;
                    assert(pos < fixbuf.length);
                    immutable tail = buf.length - symEnd;
                    immutable len = min(fixbuf.length - pos, tail);
                    fixbuf[pos .. pos + len] = buf[symEnd .. symEnd + len];
                    return fixbuf[0 .. pos + len];
                }
            }
        }

        return new DefaultTraceInfo;
    }
    else static if( __traits( compiles, new StackTrace(0, null) ) )
    {
        version (Win64)
        {
            static enum FIRSTFRAME = 4;
        }
        else
        {
            static enum FIRSTFRAME = 0;
        }
        auto s = new StackTrace(FIRSTFRAME, cast(CONTEXT*)ptr);
        return s;
    }
    else
    {
        return null;
    }
}
