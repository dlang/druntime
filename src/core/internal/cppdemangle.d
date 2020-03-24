/**
* This module provides routines to demangle C++ symbols
*
* For Posix platform the demangling is done by function `__cxa_demangle` presents in Itanium C++ ABI.
* If the function is not found or something fails, the original mangled C++ name will be returned.
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
* If it is not a C++ mangled name or cppdemangle is not supported by your platform, the original mangled C++ name will be returned.
* The optional destination buffer and return will be contains the same string if the demangle is successful.
*
 * Params:
 *  buf = The string to demangle.
 *  dst = The destination buffer, if the size of the destination buffer is <= the size of cppdemangle output the return string would be incomplete.
 *  withPrefix = If true, add the prefix "[C++] " before the C++ demangled name, make sure the target buffer is at least large to contain the prefix.
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled C++ name.
 */
version (iOS)
{
    // Not supported (dlopen is not supported)
    // Fix me
}
else version (Posix)
{
    alias _cppdemangle = posixCppdemangle;
    version = SupportCppDemangle;
    version = PosixCppDemangle;
}

char[] cppdemangle(const(char)[] buf, char[] dst, bool withPrefix = false) @safe @nogc nothrow
{
    enum prefix = "[C++] ";
    auto dstStart = withPrefix ? prefix.length : 0;
    assert(dst !is null && dst.length > dstStart, "The destination buffer is null or too small for perform demangle");

    version (SupportCppDemangle)
    {
        auto demangle = _cppdemangle(buf, dst[dstStart..$]);
    }
    else
    {
        char[] demangle = null;
    }

    if (demangle is null) return copyResult(buf, dst);
    if (withPrefix) dst[0..dstStart] = prefix;
    return dst[0..(demangle.length + dstStart)];
}

version (PosixCppDemangle)
{
    private char[] posixCppdemangle(const(char)[] buf, char[] dst) @trusted @nogc nothrow
    {
        import core.memory : pureCalloc, pureFree;
        import core.stdc.string : strlen;

        int status;
        auto mangledNamePtr = cast(char*) pureCalloc(buf.length + 1, char.sizeof);
        auto mangledName = mangledNamePtr[0..buf.length];
        scope(exit) pureFree(mangledNamePtr);
        mangledName[0..buf.length] = buf[];

        auto demangle = CXADemangleAPI.instance().__cxa_demangle;
        if (demangle is null) return null;

        auto resultPtr = demangle(mangledName.ptr, null, null, &status);
        auto result = resultPtr[0..strlen(resultPtr)];
        scope(exit) pureFree(resultPtr);

        if (status != 0) return null;
        return copyResult(result, dst);
    }
}

private char[] copyResult(const(char)[] input, char[] dst) @safe @nogc nothrow
{
    auto len = input.length <= dst.length ? input.length : dst.length;
    dst[] = '\0';
    dst[0..len] = input[0..len];
    dst[len..$] = '\0';
    return dst[0..len];
}

version (PosixCppDemangle)
{
    private static struct CXADemangleAPI
    {
        static struct API
        {
            @nogc nothrow  extern(C):
            private __gshared extern(C) char* function(const char* mangled_name, char* dst_buffer, size_t* length, int* status) __cxa_demangle;
        }

        private __gshared API _api;
        private __gshared void* _handle;

        static ref API instance() @nogc nothrow
        {
            if (_api.__cxa_demangle is null) _handle = loadAPI();
            return _api;
        }

        static void* loadAPI() @nogc nothrow
        {
            static extern(C) void cleanup()
            {
                if (_handle is null) return;
                import core.sys.posix.dlfcn : dlclose;
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
            if (handle is null) return null;

            auto p = dlsym(handle, "__cxa_demangle");
            if (p !is null) return setSym(handle, p);

            dlclose(handle);

            version (OSX)
                enum names = ["libc++abi.dylib", "libstdc++.dylib"];
            else version (Posix)
            {
                enum names = ["libstdc++.so", "libc++abi.so",
                "libc++abi.so.1"];
            }
            else version (MinGW)
                enum names = ["libstdc++.dll", "libstdc++-6.dll"];

            foreach (name; names)
            {
                handle = dlopen(name.ptr, RTLD_LAZY);
                if (handle !is null) break;
            }

            if (handle is null) return null;
            p = dlsym(handle, "__cxa_demangle");

            if (p is null) dlclose(handle);

            return setSym(handle, p);
        }
    }
}
