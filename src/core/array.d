module core.array;

/++
    Returns a static array constructed from `a`. The type of elements can be
    specified implicitly (`int[2] a = staticArray(1,2)`) or explicitly
    (`float[2] a = staticArray!float(1,2)`).
+/
pragma(inline, true) U[T.length] staticArray(U = CommonType!T, T...)(T a)
{
    return [a];
}

unittest
{
    {
        auto a = staticArray(1, 2, 3);
        assert(is(typeof(a) == int[3]));
        assert(a == [1, 2, 3]);
    }
    {
        auto a = staticArray(1, 2.0);
        assert(is(typeof(a) == double[2]));
        assert(a == [1, 2.0]);
    }
    assert(!__traits(compiles, staticArray(1, "")));
    assert(is(typeof(staticArray()) == void[0]));
    // NOTE: `int[] temp=staticArray(1,2)` correctly issues a deprecation

    {
        auto a = staticArray!float(1, 2);
        assert(is(typeof(a) == float[2]));
        assert(a == [1, 2]);
    }
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
