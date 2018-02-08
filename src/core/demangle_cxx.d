module core.demangle_cxx;

import core.internal : startsWith, Singleton;

// Where we expect to find `__cxa_demangle`
version (Posix)
    enum libCXXABIs = ["c++abi", "c++", "stdc++"];
else
    enum libCXXABIs = null;

/// returned by `demangleCXX`
enum DemangleCXXStatus
{
    invalidDemangleCXX,
    invalidLib,
    invalidPrefix,
    memoryFail,
    invalidMangling,
    invalidArg,
    success,
}

/// prefix triggering C++ demangling
enum prefixCXX = "_Z";

/++
demangle input mangled C++ symbol `buf`, returning demangling `status` and demangled input. `data` is reused accross calls for efficiency, and tries to `dlsym` `__cxa_demangle` lazily upon first use.
+/
char[] demangleCXX(out DemangleCXXStatus status, const(char)[] buf,
        DemangleCXX* data = __ctfe ? null : Singleton!DemangleCXX(0)) nothrow pure @trusted
{
    status = DemangleCXXStatus.invalidDemangleCXX;
    if (!data)
        return null;
    if (!buf.startsWith(prefixCXX))
    {
        status = DemangleCXXStatus.invalidPrefix;
        return null;
    }

    if (!data.fun_cxa_demangle)
    {
        status = DemangleCXXStatus.invalidLib;
        return null;
    }

    // make sure null terminated
    data.reserve(buf.length + 1);
    data.buffer[0 .. buf.length] = buf;
    data.buffer[buf.length] = '\0';

    size_t len = data.buffer2.length;
    int status2;
    auto ret = data.fun_cxa_demangle(data.buffer.ptr, data.buffer2.ptr, &len, &status2);
    data.buffer2 = ret[0 .. len];

    switch (status2)
    {
    case 0:
        status = DemangleCXXStatus.success;
        assert(len > 0 && ret[len - 1] == '\0');
        return ret[0 .. len - 1];
    case -1:
        status = DemangleCXXStatus.memoryFail;
        break;
    case -2:
        status = DemangleCXXStatus.invalidMangling;
        break;
    case -3:
        status = DemangleCXXStatus.invalidArg;
        break;
    default:
        assert(0);
    }
    return null;
}

unittest
{
    DemangleCXXStatus status;
    auto buf = "_ZN16ParseTimeVisitorI10ASTCodegenE5visitEP14DefaultInitExp";
    auto ret = demangleCXX(status, buf);
    assert(status == DemangleCXXStatus.success || status == DemangleCXXStatus.invalidLib);
    if (status == DemangleCXXStatus.success)
        assert(ret == "ParseTimeVisitor<ASTCodegen>::visit(DefaultInitExp*)");
    // TODO: should we check it works on some OS (eg OSX)? (auto-tester may have different locations for standard libraries)
}

private:
// from https://gcc.gnu.org/onlinedocs/libstdc++/libstdc++-html-USERS-4.3/a01696.html#76957f5810098d2ffb5c62f43eda1c6d :
/+
0: The demangling operation succeeded.
-1: A memory allocation failiure occurred.
-2: mangled_name is not a valid name under the C++ ABI mangling rules.
-3: One of the arguments is invalid.
+/
extern (C) pure nothrow char* __cxa_demangle(const char* mangled_name,
        char* output_buffer, size_t* length, int* status);

// internal data reused accross calls to demangleCXX
struct DemangleCXX
{
    typeof(__cxa_demangle)* fun_cxa_demangle;
    char[] buffer;
    // allocated via malloc (see __cxa_demangle)
    char[] buffer2;

    import core.internal.sharedlib : SharedLib, patternToLibrary;

    SharedLib lib;

    this(int unused) nothrow
    {
        // try to dlsym `__cxa_demangle`
        lib = SharedLib(0);
        foreach (a; libCXXABIs)
            if (lib.open(a.patternToLibrary()))
            {
                fun_cxa_demangle = lib.getFun!__cxa_demangle;
                break;
            }
    }

    ~this()
    {
        // CHECKME: is that safe to do? (cf caveats in https://github.com/dlang/druntime/pull/1836)
        import core.memory : pureFree;

        pureFree(buffer2.ptr);
    }

    void reserve(size_t length) pure nothrow
    {
        // NOTE: can't use not-pure assumeSafeAppend
        if (buffer.length < length)
        {
            buffer.length = length;
        }
    }
}
