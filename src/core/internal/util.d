module core.internal.util;

/// Thread local singleton pattern
auto Singleton(T, A...)(A a)
{
    static if (is(T == class))
        static T ret;
    else static if (is(T == struct))
        static T* ret;
    else
        static assert(0);
    if (!ret)
    {
        ret = new T(a);
    }
    return ret;
}
