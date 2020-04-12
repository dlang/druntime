/**
* This module provides functions to demangle C++ symbols
*
* For POSIX platforms the function `__cxa_demangle` present in Itanium C++ ABI does the demangling, therefore this module
* depends on the C++ standard library which must be linked dynamically or available for research through the dynamic loader.
*
* For Windows platform the function `UnDecorateSymbolName` present in the Debug Help Library does the demangling,
* which should be available for all versions of Windows supported by D.
*
* Copyright: Copyright © 2020, The D Language Foundation
* License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
* Authors: Ernesto Castellotti
* Source: $(DRUNTIMESRC core/internal/_cppdemangle.d)
* See_Also:
*      https://itanium-cxx-abi.github.io/cxx-abi/abi.html#demangler
*      https://gcc.gnu.org/onlinedocs/libstdc++/libstdc++-html-USERS-4.3/a01696.html
*      https://libcxxabi.llvm.org/spec.html
*      https://docs.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-undecoratesymbolname
*/
module core.internal.cppdemangle;

/**
* Demangles C++ mangled names.
*
* The output buffer and return will be contains the demangled name of C++ symbol if the demangling is successful.
*
* This function will fail and the mangled name in input will be returned if:
* 1. The symbol to be processed does not follow the Itanium ABI for POSIX or Visual C++ for Windows, or more simply it is not a C++ name
* 2. The platform is not compatible or the library needed to perform the demangling was not found or linked with the executable
* 3. The size of the output buffer is not sufficient to contain the demangled name with its prefix
*
* This function will fail and null will be returned if:
* 1. The output buffer is null
* 2. The function has failed (see list above) and output buffer is unable to contain the mangled name in input
*
 * Params:
 *  mangledName = The string to demangle.
 *  outputBuffer = The destination buffer, if the size of the destination buffer is <= the size of cppdemangle output the return string would be incomplete.
 *  prefix = Specifies the prefix to be added to the beginning of the string containing the demangled name
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled C++ name.
 */
char[] cppdemangle(const(char)[] mangledName, char[] outputBuffer, string prefix = "") @trusted
{
    CPPDemangle.initialize();
    return CPPDemangle.instance.cppdemangle(mangledName, outputBuffer, prefix);
}

package struct CPPDemangle
{
    private __gshared CPPDemangle _instance;
    private __gshared bool isInitialized;

    version (Posix)
    {
        @nogc nothrow extern(C)
        {
            private extern(C) char* function(const char* mangledName, char* outputBuffer, size_t* length, int* status) __cxa_demangle;
        }

        version (OSX)
            private static immutable names = ["libc++abi.dylib", "libstdc++.dylib"];
        else
        {
            private static immutable names = ["libstdc++.so", "libstdc++.so.6", "libstdc++.so.5",
                "libc++abi.so", "libc++abi.so.1"];
        }

        private __gshared void* _handle;

        shared static ~this() {
            import core.sys.posix.dlfcn : dlclose;

            if (isInitialized)
            {
                dlclose(_handle);
                _handle = null;
                isInitialized = false;
            }
        }
    }

    version (Windows)
    {
        import core.sys.windows.dbghelp : UnDecorateSymbolNameFunc;

        @nogc nothrow extern(System)
        {
            private UnDecorateSymbolNameFunc UnDecorateSymbolName;
        }
    }

    char[] cppdemangle(const(char)[] mangledName, char[] outputBuffer, string prefix = "") @safe
    {
        auto prefixEmpty = prefix.length <= 0;
        auto demangleOffset = prefixEmpty ? 0 : prefix.length + 1; // Add prefix + space

        if (outputBuffer is null)
        {
            return null;
        }

        if (outputBuffer.length < demangleOffset)
        {
            return copyResult(mangledName, outputBuffer);
        }

        auto demangle = _cppdemangle(mangledName, outputBuffer[demangleOffset..$]);

        if (demangle is null)
        {
            return copyResult(mangledName, outputBuffer);
        }

        if (!prefixEmpty)
        {
            outputBuffer[0..demangleOffset - 1] = prefix;
            outputBuffer[demangleOffset - 1] = ' ';
        }

        return outputBuffer[0..(demangle.length + demangleOffset)];
    }

    static CPPDemangleStatus initialize()
    {
        if (isInitialized)
        {
            return CPPDemangleStatus.INITIALIZED;
        }

        version (iOS)
        {
            // Not supported (dlopen doesn't work)
            // Fix me
            return CPPDemangleStatus.LOAD_ERROR;
        }
        else version (Posix)
        {
            import core.sys.posix.dlfcn : dlsym, dlopen, dlclose, RTLD_LAZY;

            auto handle = dlopen(null, RTLD_LAZY);
            assert(handle !is null);
            auto p = dlsym(handle, "__cxa_demangle");

            if (p !is null)
            {
                _handle = handle;
                _instance.__cxa_demangle = cast(typeof(CPPDemangle.__cxa_demangle)) p;
                isInitialized = true;
                return CPPDemangleStatus.INITIALIZED;
            }

            dlclose(handle);

            foreach (name; names)
            {
                handle = dlopen(name.ptr, RTLD_LAZY);

                if (handle !is null)
                {
                    break;
                }
            }

            if (handle is null)
            {
                return CPPDemangleStatus.LOAD_ERROR;
            }

            p = dlsym(handle, "__cxa_demangle");

            if (p !is null)
            {
                _handle = handle;
                _instance.__cxa_demangle = cast(typeof(CPPDemangle.__cxa_demangle)) p;
                isInitialized = true;
                return CPPDemangleStatus.INITIALIZED;
            }
            else
            {
                return CPPDemangleStatus.SYMBOL_ERROR;
            }
        }
        else version (Windows)
        {
            import core.sys.windows.dbghelp : DbgHelp;

            auto dbgHelp = DbgHelp.get();

            if (dbgHelp is null)
            {
                return CPPDemangleStatus.LOAD_ERROR;
            }

            auto func = dbgHelp.UnDecorateSymbolName;

            if (dbgHelp.UnDecorateSymbolName !is null)
            {
                _instance.UnDecorateSymbolName = dbgHelp.UnDecorateSymbolName;
                isInitialized = true;
                return CPPDemangleStatus.INITIALIZED;
            }
            else
            {
                return CPPDemangleStatus.SYMBOL_ERROR;
            }
        }
        else
        {
            // Platform not supported
            return CPPDemangleStatus.LOAD_ERROR;
        }
    }

    static CPPDemangle instance() @nogc nothrow
    {
        return _instance;
    }

    private char[] _cppdemangle(const(char)[] mangledName, char[] outputBuffer) @trusted
    {
        import core.memory : pureCalloc, pureFree;
        import core.stdc.string : strlen;

        if (!isInitialized)
        {
            return null;
        }

        auto mangledNamePtr = cast(char*) pureCalloc(mangledName.length + 1, char.sizeof);

        scope(exit)
        {
            if (mangledNamePtr !is null)
            {
                pureFree(mangledNamePtr);
            }
        }

        mangledNamePtr[0..mangledName.length] = mangledName[];

        version (Posix)
        {
            int status;
            auto demangledName = _instance.__cxa_demangle(mangledNamePtr, null, null, &status);
            // NOTE: Due to the implementation of __cxa_demangle, the result of the function
            // will be a pointer to arrays of characters of unknown size before the call to
            // the function.
            // It is in no way possible to pass the output buffer of this function and perform
            // the demangling if its size is sufficient directly by calling __cxa_demangle,
            // because if the size was insufficient __cxa_demangle would try to increase
            // it through realloc.
            // Tto use this function safely, it is therefore necessary to allow the necessary
            // memory to be allocated (just pass null) and then copy (if the size is sufficient)
             // the result into the output buffer.

            if (status != 0 && demangledName is null)
            {
                return null;
            }

            scope(exit)
            {
                if (demangledName !is null)
                {
                    pureFree(demangledName);
                }
            }

            return copyResult(demangledName[0..strlen(demangledName)], outputBuffer);
        }

        version (Windows)
        {
            import core.sys.windows.windef : DWORD;

            auto maxStringLen = (outputBuffer.length > DWORD.max) ? DWORD.max : cast(DWORD) outputBuffer.length;
            // NOTE: UnDecorateSymbolName expects to receive a length in DWORD (uint) instead
            // outputBuffer.length would be ulong.
            // To make a safe cast I make sure not to exceed DWORD.max

            auto bufferLen = _instance.UnDecorateSymbolName(mangledNamePtr, outputBuffer.ptr, maxStringLen, 0);

            if (bufferLen <= 0)
            {
                return null;
            }

            return outputBuffer[0..bufferLen];
        }
    }
}

package enum CPPDemangleStatus
{
    INITIALIZED = 1,
    LOAD_ERROR = -1,
    SYMBOL_ERROR = -2
}

package char[] copyResult(const(char)[] input, char[] output) @safe @nogc nothrow
{
    if (input.length > output.length)
    {
        return null;
    }

    output[0..input.length] = input[0..input.length];
    return output[0..input.length];
}
