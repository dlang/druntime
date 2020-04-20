/**
* This module provides the demangling of C++ symbols for stacktrace
*
* Copyright: Copyright © 2020, The D Language Foundation
* License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
* Authors: Ernesto Castellotti
* Source: $(DRUNTIMESRC core/internal/_cppdemangle.d)
*/
module core.internal.cpptrace;

import core.internal.cppdemangle : CPPDemangle, CPPDemangleStatus;
import core.stdc.stdio : fprintf, stderr;
import core.stdc.stdlib : exit;

/**
* Demangles C++ mangled names passing the runtime options to cppdemangle.
*
* If it is not a C++ mangled name or cppdemangle is not supported by your platform, the original mangled C++ name will be returned.
* The optional destination buffer and return will be contains the same string if the demangle is successful.
* This function is used to demangle C++ symbols in the stacktrace.
*
 * Params:
 *  buf = The string to demangle.
 *  dst = The destination buffer, if the size of the destination buffer is <= the size of cppdemangle output the return string would be incomplete.
 *
 * Returns:
 *  The demangled name or the original string if the name is not a mangled C++ name.
 */
char[] demangleCppTrace(const(char)[] buf, char[] dst)
{
    import core.internal.cppdemangle : copyResult;

    if (!CPPTrace.config.enable)
    {
        return copyResult(buf, dst);
    }

    if (CPPTrace.config.noprefix)
    {
        CPPTrace.config.prefix = "";
    }

    return CPPTrace.instance.cppdemangle(buf, dst, CPPTrace.config.prefix);
}

private struct CPPTrace
{
    __gshared CPPDemangle instance;
    __gshared Config config;

    static this()
    {
        import core.internal.parseoptions : initConfigOptions;
        initConfigOptions(config, "cpptrace");

        version (Posix)
        {
            version (Shared)
            {
                // OK! CPPDemangling may be supported
            }
            else
            {
                if (config.enable)
                {
                    fprintf(stderr, "C++ demangling is only supported if phobos is dynamically linked. Recompile the program by passing -defaultlib=libphobos2.so to DMD\n");
                    exit(1);
                    assert(0);
                }
            }
        }

        if (config.enable)
        {
            auto result = CPPDemangle.initialize();

            final switch (result)
            {
                case CPPDemangleStatus.INITIALIZED:
                {
                    instance = CPPDemangle.instance();
                    return;
                }

                case CPPDemangleStatus.LOAD_ERROR:
                {
                    version (Posix)
                    {
                        fprintf(stderr, "The C++ library for the C++ demangle could not be loaded with dlopen. Please disable the option for C++ demangling.\n");
                    }
                    else version (Windows)
                    {
                        fprintf(stderr, "The Debug Help Library could not be loaded. Please disable the option for C++ demangling.\n");
                    }

                    exit(1);
                    assert(0);
                }

                case CPPDemangleStatus.SYMBOL_ERROR:
                {
                    version (Posix)
                    {
                        fprintf(stderr, "The __cxa_demangle symbol was not found in the C++ standard library (maybe it's not compatible). Please disable the option for C++ demangling.\n");
                    }
                    else version (Windows)
                    {
                        fprintf(stderr, "The UnDecorateSymbolName symbol was not found in the Debug Help Library (maybe it's not compatible). Please disable the option for C++ demangling.\n");
                    }

                    exit(1);
                    assert(0);
                }
            }
        }
    }
}

private struct Config
{
    bool enable;
    bool noprefix;
    string prefix = "[C++]";
}
