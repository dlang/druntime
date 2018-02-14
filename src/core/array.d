module core.array;

/++
    Returns a static array constructed from `a`
+/
CommonType!T[T.length] StaticArray(T...)(T a)
{
    return [a];
}

unittest
{
    {
        auto a = StaticArray(1, 2, 3);
        assert(is(typeof(a) == int[3]));
        assert(a == [1, 2, 3]);
    }
    {
        auto a = StaticArray(1, 2.0);
        assert(is(typeof(a) == double[2]));
        assert(a == [1, 2.0]);
    }
    assert(!__traits(compiles, StaticArray(1, "")));
    assert(is(typeof(StaticArray()) == void[0]));
}

package:
// copied from std.traits ; TODO: move to core.internal.adapted?
template CommonType(T...)
{
    static if (!T.length)
    {
        alias CommonType = void;
    }
    else static if (T.length == 1)
    {
        static if (is(typeof(T[0])))
        {
            alias CommonType = typeof(T[0]);
        }
        else
        {
            alias CommonType = T[0];
        }
    }
    else static if (is(typeof(true ? T[0].init : T[1].init) U))
    {
        alias CommonType = CommonType!(U, T[2 .. $]);
    }
    else
        alias CommonType = void;
}
