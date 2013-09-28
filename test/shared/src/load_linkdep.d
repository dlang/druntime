import core.runtime;

extern(C) alias RunDepTests = int function();

void main(string[] args)
{
    auto name = args[0];
    assert(name[$-13 .. $] == "/load_linkdep");
    name = name[0 .. $-12] ~ "liblinkdep.so";

    auto lib = .loadLibrary(name);
    assert(lib);
    auto runDepTests = lib.loadFunc!(RunDepTests, "runDepTests")();
    assert(runDepTests());
    assert(lib.unloadLibrary());
}
