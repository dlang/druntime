import core.runtime, core.time : MonoTime;
import core.stdc.stdio;

ModuleInfo* getModuleInfo(string name)
{
    foreach (m; ModuleInfo)
        if (m.name == name) return m;
    assert(0, "module '"~name~"' not found");
}

bool tester()
{
    assert(Runtime.args.length == 2);
    auto name = Runtime.args[1];
    immutable pkg = ".package";
    immutable pkgLen = pkg.length;

    if(name.length > pkgLen && name[$ - pkgLen .. $] == pkg)
        name = name[0 .. $ - pkgLen];

    if (auto fp = getModuleInfo(name).unitTest)
    {
        try
        {
            immutable t0 = MonoTime.currTime;
            fp();
            immutable t1 = MonoTime.currTime;
            printf("%.3fs PASS %.*s\n", (t1 - t0).total!"msecs" / 1000.0,
                cast(int)name.length, name.ptr);
        }
        catch (Throwable e)
        {
            auto msg = e.toString();
            printf("****** FAIL %.*s\n%.*s\n", cast(int)name.length, name.ptr,
                cast(int)msg.length, msg.ptr);
            return false;
        }
    }

    testCustomRTInfo();

    return true;
}

shared static this()
{
    Runtime.moduleUnitTester = &tester;
}

void main()
{
}

void testCustomRTInfo()
{
    static string[] registeredClasses;
    static struct CustomRTInfo(T)
    {
        static assert(is(T == A) || is(T == B));
        static this()
        {
            registeredClasses ~= T.stringof;
        }
    }

    @rtInfo!CustomRTInfo static class A { }
    static class B : A { }

    // @rtInfo test
    assert(registeredClasses.length == 2);
    assert(registeredClasses[0] == "A" || registeredClasses[1] == "A");
    assert(registeredClasses[0] == "B" || registeredClasses[1] == "B");
}

