import core.runtime, core.stdc.string, core.sys.posix.dlfcn;

extern(C) alias RunTests = int function();

extern(C) int runDepTests(const char* name)
{
    try
    {
        auto lib = .loadLib(name[0 .. strlen(name)]);
        scope (exit) lib.unloadLib();
        auto runTests = lib.loadFunc!(RunTests, "runTests")();
        if (runTests !is null && runTests())
            return true;
    }
    catch (Exception)
    {
    }
    return false;
}
