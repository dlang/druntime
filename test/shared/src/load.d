import core.runtime, core.stdc.stdio, core.thread, core.sys.linux.dlfcn;

Library openLib(string s)
{
    auto h = .loadLib(s);

    import lib; // .di

    libThrowException = h.findFunc!throwException();
    libCollectException = h.findFunc!collectException();

    libAlloc = h.findFunc!alloc();
    libAccess = h.findFunc!access();
    libFree = h.findFunc!free();

    libTlsAlloc = h.findFunc!tls_alloc();
    libTlsAccess = h.findFunc!tls_access();
    libTlsFree = h.findFunc!tls_free();

    libSharedStaticCtor = h.findVar!shared_static_ctor();
    libSharedStaticDtor = h.findVar!shared_static_dtor();
    libStaticCtor = h.findVar!static_ctor();
    libStaticDtor = h.findVar!static_dtor();

    return h;
}

void closeLib(Library lib)
{
    .unloadLib(lib);
}

__gshared
{
    void function() libThrowException;
    Exception function(void delegate()) libCollectException;

    void function() libAlloc;
    void function() libTlsAlloc;
    void function() libAccess;
    void function() libTlsAccess;
    void function() libFree;
    void function() libTlsFree;

    shared uint* libSharedStaticCtor;
    shared uint* libSharedStaticDtor;
    shared uint* libStaticCtor;
    shared uint* libStaticDtor;
}

void testEH()
{
    bool passed;
    try
        libThrowException();
    catch (Exception e)
        passed = true;
    assert(passed); passed = false;

    assert(libCollectException({throw new Exception(null);}) !is null);
    assert(libCollectException({libThrowException();}) !is null);
}

void testGC()
{
    import core.memory;
    libAlloc();
    libTlsAlloc();
    libAccess();
    libTlsAccess();
    GC.collect();
    libTlsAccess();
    libAccess();
    libTlsFree();
    libFree();
}

void testInit()
{

    assert(*libStaticCtor == 1);
    assert(*libStaticDtor == 0);
    static void run()
    {
        assert(*libSharedStaticCtor == 1);
        assert(*libSharedStaticDtor == 0);
        assert(*libStaticCtor == 2);
        assert(*libStaticDtor == 0);
    }
    auto thr = new Thread(&run);
    thr.start();
    thr.join();
    assert(*libSharedStaticCtor == 1);
    assert(*libSharedStaticDtor == 0);
    assert(*libStaticCtor == 2);
    assert(*libStaticDtor == 1);
}

const(ModuleInfo)* findModuleInfo(string name)
{
    foreach (m; ModuleInfo)
        if (m.name == name) return m;
    return null;
}

void runTests(string libName)
{
    assert(findModuleInfo("lib") is null);
    auto handle = openLib(libName);
    assert(findModuleInfo("lib") !is null);

    testEH();
    testGC();
    testInit();

    closeLib(handle);
    assert(findModuleInfo("lib") is null);
}

void main(string[] args)
{
    auto name = args[0];
    assert(name[$-5 .. $] == "/load");
    name = name[0 .. $-4] ~ "lib.so";

    runTests(name);

    // lib is no longer resident
    name ~= '\0';
    assert(.dlopen(name.ptr, RTLD_LAZY | RTLD_NOLOAD) is null);
    name = name[0 .. $-1];

    auto thr = new Thread({runTests(name);});
    thr.start();
    thr.join();
}
