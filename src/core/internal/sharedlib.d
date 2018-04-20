module core.internal.sharedlib;

debug import core.stdc.stdio : printf;

// RAII wrapper for shared libraries
struct SharedLib
{
    import core.sys.posix.dlfcn;
    import core.internal.adapted.string : toStringz;

    void* handle;
    string libraryFile;
    static int flagDefault = RTLD_LOCAL | RTLD_LAZY;

    @disable this(this);

    this(int unused) nothrow
    {
    }

    ~this()
    {
        release();
    }

    // Return true of `dlopen` succeeded
    bool open(string libraryFile, int flag = flagDefault) nothrow
    {
        // TODO: consider version it out for windows
        release();
        this.libraryFile = libraryFile;
        auto temp = libraryFile.toStringz;
        handle = dlopen(libraryFile.toStringz, flag);
        if (handle)
            return true;
        debug (core_internal_sharedlib)
        {
            printf("dlopen `%.*s` failed in `%s`\n", cast(int) libraryFile.length,
                    libraryFile.ptr, __PRETTY_FUNCTION__.ptr);
        }
        return false;
    }

    // Return true of `dlopen` succeeded on at least one of `libraryFiles`
    bool open(string[] libraryFiles, int flag = flagDefault) nothrow
    {
        foreach (a; libraryFiles)
            if (open(a, flag))
                return true;
        return false;
    }

    // cleanup
    void release() nothrow
    {
        // if(handle) seems needed: https://stackoverflow.com/questions/11412943/is-it-safe-to-call-dlclosenull
        if (handle)
            dlclose(handle);

    }

    // try to dlsym provided `symbol` typed as `fun`
    auto getFun(alias fun, string symbol = __traits(identifier, fun))()
    {
        assert(handle);
        return cast(typeof(fun)*) dlsym(handle, symbol.ptr);
    }

    // ditto, and also call it with arguments `a`
    auto callFun(alias fun, string symbol = __traits(identifier, fun), T...)(string symbol, T a)
    {
        auto fun = getFun(symbol);
        assert(fun);
        return (*fun)(a);
    }
}

string sharedLibraryExt() nothrow
{
    version (OSX)
        return ".dylib";
    else version (linux)
        return ".so";
    else
        assert(0);
}

string patternToLibrary(string pattern) nothrow
{
    return "lib" ~ pattern ~ sharedLibraryExt;
}
