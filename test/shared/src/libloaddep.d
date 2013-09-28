import core.runtime, core.stdc.string, core.sys.posix.dlfcn;

extern(C) alias RunTests = int function();

extern(C) int runDepTests(const char* name)
{
    auto lib = .loadLibrary(name[0 .. strlen(name)]);
    if (lib is null) return false;
    auto runTests = lib.loadFunc!(RunTests, "runTests")();
    assert(runTests !is null);
    if (!runTests()) return false;
    return lib.unloadLibrary();
}
