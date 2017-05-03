import core.runtime;

void main(string[] args)
{
    profilegc_setlogfilename(args[1]);

    struct S { ~this() { } }
    class C { }
    interface I { }

    {
        auto a = new C();
        auto b = new int;
        auto c = new int[3];
        auto d = new int[][](3,4);
        auto e = new float;
        auto f = new float[3];
        auto g = new float[][](3,4);
    }

    {
        int[] a; delete a;
        S[] as; delete as;
        C c; delete c;
        I i; delete i;
        C* pc = &c; delete *pc;
        I* pi = &i; delete *pi;
        int* pint; delete pint;
        S* ps; delete ps;
    }

    {
        int[] a = [1, 2, 3];
        string[int] aa = [1:"one", 2:"two", 3:"three"];
    }

    {
        int[] a, b, c;
        c = a ~ b;
        c = a ~ b ~ c;
    }

    {
        dchar dc = 'a';
        char[] ac; ac ~= dc;
        wchar[] aw; aw ~= dc;
        char[] ac2; ac2 ~= ac;
        int[] ai; ai ~= 3;
    }

    {
        int[] ai; ai.length = 10;
        float[] af; af.length = 10;
    }

    {
        auto foo ( )
        {
            int v = 42;
            return { return v; };
        }

        auto x = foo()();
    }

    {
        import core.thread;

        Thread[] arr;

        void bar ( )
        {
            auto x = new int[10];
        }

        for (int i = 0; i < 10; ++i)
            arr ~= new Thread(&bar, 1024).start();

        foreach (t; arr)
            t.join();
    }
}
