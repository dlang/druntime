void main()
{
    try
    {
        f1();
    }
    catch (Exception e)
    {
        import core.stdc.stdio;
        auto str = e.toString();
        printf("%.*s\n", cast(int)str.length, str.ptr);
    }

    try
    {
        S1.f1();
    }
    catch (Exception e)
    {
        import core.stdc.stdio;
        auto str = e.toString();
        printf("%.*s\n", cast(int)str.length, str.ptr);
    }

    try
    {
        ubyte nothing;
        C1!ubyte.f1(nothing, &nothing, nothing);
    }
    catch (Exception e)
    {
        import core.stdc.stdio;
        auto str = e.toString();
        printf("%.*s\n", cast(int)str.length, str.ptr);
    }
}

extern(C++) void f1()
{
    throw new Exception("exception");
}

extern(C++) struct S1
{
    static void f1()
    {
        throw new Exception("exception");
    }
}

extern(C++)
{
    class C1(T)
    {
        static T f1(T arg1, T* arg2, ref T arg3)
        {
            throw new Exception("exception");
        }
    }
}
