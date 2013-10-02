import core.runtime;

extern(C) alias RunDepTests = int function(const char*);

void main(string[] args)
{
    auto root = args[0][0..$-"load_loaddep".length];
    auto libloaddep = root ~ "libloaddep.so";
    auto lib = .loadLib(libloaddep);
    auto runDepTests = lib.loadFunc!(RunDepTests, "runDepTests")();
    assert(runDepTests((root ~ "lib.so\0").ptr));
    assert(lib.unloadLib());
}
