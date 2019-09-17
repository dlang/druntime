/**
* This module provides routines to demangle C++ symbols
*
* Demangling is done through the standard C++ `__cxa_demangle` function.
* The C++ standard library is lazily loaded via `dlsym`. If not found, those routines will return their arguments.
* This module currently only supports POSIX.
*
* Copyright: Copyright © 2019, The D Language Foundation
* License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
* Authors: Ernesto Castellotti
* Source: $(DRUNTIMESRC core/internal/_cppdemangle.d)
*/
module core.internal.cppdemangle;

/**
* Demangles C++ mangled names.
*
* If it is not a C++ mangled name, it returns its argument name.
*
 * Params:
 *  buf = The string to demangle.
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled C++
 *  name.
 * The returns is always allocated with malloc, use free to deallocate the memory.
 */
version (Posix)
{
    char[] cppdemangle(const(char)[] buf) @nogc @safe nothrow
    {
        char[] fakeDst = null;
        return cppdemangle(buf, fakeDst);
    }
}

extern(C++)  private class Test
{
    int var;
}

unittest
{
    version (Posix)  // Run tests only in Posix since is the only supported platform
    {
        import core.stdc.stdlib : free;
        auto demangledName = cppdemangle("_Znwm");
        assert(demangledName == "operator new(unsigned long)");
        free(demangledName.ptr);
        demangledName = cppdemangle(Test.var.mangleof);
        assert(demangledName == "Test::var");
        free(demangledName.ptr);
    }
}

/**
* Demangles C++ mangled names.
*
* If it is not a C++ mangled name, it returns its argument name.
* The optional destination buffer and return will be the same if the demangle is successful.
*
 * Params:
 *  buf = The string to demangle.
 * dst = An optional destination buffer, it does not need to be >= of the cppdemangle output (realloc will be used if necessary). A memory allocated with malloc must be provided.
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled C++
 *  name.
 * Do not deallocate with free the returns because it is not guaraneed to be allocated with malloc, it is necessary to de-allocate only the optional destination buffer.
 */
version (Posix)
{
    char[] cppdemangle(const(char)[] buf, ref char[] dst) @nogc @trusted nothrow
    {
        import core.stdc.stdlib : malloc, free;
        auto result = posixCppdemangle(buf, dst);

        if (result != buf)
            dst = result;
        else if (dst !is null)
            free(result.ptr);

        return result;
    }
}
else version (Windows)
{
  // Todo
}

unittest
{
    version (Posix)  // Run tests only in Posix since is the only supported platform
    {
        import core.stdc.stdlib : malloc, free;
        char[] buf = (cast(char*) malloc(10 * char.sizeof))[0..10];
        auto demangledName = cppdemangle("_Znwm", buf);
        assert(demangledName == "operator new(unsigned long)");
        free(buf.ptr);
        buf = (cast(char*) malloc(28 * char.sizeof))[0..28];
        demangledName = cppdemangle(Test.var.mangleof, buf);
        assert(demangledName == "Test::var");
        free(buf.ptr);
    }
}

private char[] posixCppdemangle(const(char)[] buf, char[] dst) @nogc nothrow
{
    import core.stdc.stdlib : malloc, free;
    import core.stdc.string : strlen;
    auto length = dst.length;
    int status;
    auto mangledName = (cast(char*) malloc((buf.length + 1) * char.sizeof))[0..buf.length + 1];
    mangledName[0..buf.length] = buf[];
    mangledName[buf.length] = 0;

    auto demangle =  CXADemangleAPI.instance().__cxa_demangle;

    if (demangle is null)
    {
        return mangledName[0..buf.length];
    }

    auto result = demangle(mangledName.ptr, dst.ptr, length, status);

    if (status != 0)
        return mangledName[0..buf.length];
    else
        free(mangledName.ptr);

    return result[0..strlen(result)];
}

private static struct CXADemangleAPI
{
    static struct API
    {
        @nogc nothrow  extern(C):
        private __gshared extern(C) char* function(const char* mangled_name, char* output_buffer, ref size_t  length, ref int status) __cxa_demangle;
    }

    private __gshared API _api;
    private __gshared void* _handle;

    static ref API instance() @nogc nothrow
    {
        if (_api.__cxa_demangle is null) _handle = loadAPI();
       return  _api;
    }

    static void* loadAPI() @nogc nothrow
    {
        static extern(C) void cleanup()
        {
            import core.sys.posix.dlfcn : dlclose;
            if (_handle is null) return;
            dlclose(_handle);
            _handle = null;
        }

        static void* setSym(void* handle, void* ptrSym)
        {
            import core.stdc.stdlib : atexit;
            atexit(&cleanup);
            _api.__cxa_demangle = cast(typeof(CXADemangleAPI.API.__cxa_demangle)) ptrSym;
            return handle;
        }

        import core.sys.posix.dlfcn : dlsym, dlopen, dlclose, RTLD_LAZY;
        auto handle = dlopen(null, RTLD_LAZY);
        assert(handle !is null);

        auto p = dlsym(handle, "__cxa_demangle");
        if (p !is null) return setSym(handle, p);
        dlclose(handle);

        version (OSX)
            static immutable names = ["libc++abi.dylib", "libstdc++.dylib"];
        else version (Posix)
        {
            static immutable names = ["libstdc++.so", "libc++abi.so",
            "libc++abi.so.1"];
        }

        foreach (name; names)
        {
            handle = dlopen(name.ptr, RTLD_LAZY);

            if (handle !is null)
            {
                p = dlsym(handle, "__cxa_demangle");
                if (p !is null) return setSym(handle, p);
                dlclose(handle);
            }
        }

        return null;
    }
}
