module core.array;

/++
    Returns a static array constructed from `a`. The type of elements can be
    specified implicitly (`int[2] a = staticArray(1,2);`) or explicitly
    (`float[2] a = staticArray!float(1,2)`).

    The result is an rvalue, therefore uses like staticArray(1, 2, 3).find(x) may be inefficient.
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

    {
        auto a = staticArray!float(1, 2);
        assert(is(typeof(a) == float[2]));
        assert(a == [1, 2]);
    }

    assert(is(typeof(staticArray([1])) == int[][1]));

    // NOTE: correctly issues a deprecation
    //int[] a2 = staticArray(1,2);
}

/++
    Returns a static array constructed from `arr`. The type of elements can be
    specified implicitly (`int[2] a = [1,2].asStatic;`) or explicitly
    (`float[2] a = [1,2].asStatic!float`).

    The result is an rvalue, therefore uses like [1, 2, 3].asStatic.find(x) may be inefficient.
+/
pragma(inline, true) T[n] asStatic(T, size_t n)(auto ref T[n] arr) @nogc
{
    return arr;
}

U[n] asStatic(U, T, size_t n)(auto ref T[n] arr) @nogc if (!is(U == T) && is(T : U))
{
    U[n] ret = void;
    static foreach (i; 0 .. n)
        cast(Unqual!U)(ret[i]) = arr[i];
    return ret;
}

/// ditto
auto asStatic(U = typeof(arr[0]), alias arr)() @nogc
{
    enum n = arr.length;
    U[n] ret = void;
    static foreach (i; 0 .. n)
        cast(Unqual!U)(ret[i]) = arr[i];
    return ret;
}

/// ditto
auto asStatic(alias arr)() @nogc
{
    enum n = arr.length;
    alias U = typeof(arr[0]);
    U[n] ret = void;
    static foreach (i; 0 .. n)
        cast(Unqual!U)(ret[i]) = arr[i];
    return ret;
}

unittest
{
    {
        auto a = [1, 2, 3].asStatic;
        assert(is(typeof(a) == int[3]));
        assert(a == [1, 2, 3]);
    }

    @nogc void checkNogc()
    {
        auto a = [1, 2, 3].asStatic;
        assert(a == [1, 2, 3]);
    }

    {
        auto a = [1, 2, 3].asStatic!double;
    }

    {
        auto a = [1, 2, 3].asStatic!int;
    }
    {
        auto a1 = [1, 2, 3].asStatic!(const(int));
        const(int)[3] a2 = [1, 2, 3].asStatic;
        auto a3 = [1, 2, 3].asStatic!(const(double));
    }

    {
        import std.range;

        enum a = asStatic!(double, 2.iota);
        assert(is(typeof(a) == double[2]));
        assert(a == [0, 1]);
    }
    {
        import std.range;

        enum a = asStatic!(2.iota);
        assert(is(typeof(a) == int[2]));
        assert(a == [0, 1]);
    }

    // NOTE: correctly issues a deprecation
    //int[] a2 = [1,2].asStatic;
}

package:
// TODO: move to core.internal.adapted?
// copied from std.traits.CommonType
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

// Copied from std.traits.Unqual
template Unqual(T)
{
    version (none) // Error: recursive alias declaration @@@BUG1308@@@
    {
        static if (is(T U == const U))
            alias Unqual = Unqual!U;
        else static if (is(T U == immutable U))
            alias Unqual = Unqual!U;
        else static if (is(T U == inout U))
            alias Unqual = Unqual!U;
        else static if (is(T U == shared U))
            alias Unqual = Unqual!U;
        else
            alias Unqual = T;
    }
    else // workaround
    {
        static if (is(T U == immutable U))
            alias Unqual = U;
        else static if (is(T U == shared inout const U))
            alias Unqual = U;
        else static if (is(T U == shared inout U))
            alias Unqual = U;
        else static if (is(T U == shared const U))
            alias Unqual = U;
        else static if (is(T U == shared U))
            alias Unqual = U;
        else static if (is(T U == inout const U))
            alias Unqual = U;
        else static if (is(T U == inout U))
            alias Unqual = U;
        else static if (is(T U == const U))
            alias Unqual = U;
        else
            alias Unqual = T;
    }
}
