module core.array;

import core.internal.traits : Unqual, CommonType;

debug import std.stdio;

// @nogc: https://issues.dlang.org/show_bug.cgi?id=18439
nothrow @safe pure:
/++
    Returns a static array constructed from `a`. The type of elements can be
    specified implicitly (`int[2] a = staticArray(1,2);`) or explicitly
    (`float[2] a = staticArray!float(1,2)`).

    The result is an rvalue, therefore uses like staticArray(1, 2, 3).find(x) may be inefficient.
+/
pragma(inline, true) U[T.length] staticArray(U = CommonType!T, T...)(T a) @nogc
{
    return [a];
}

// D20180214T185602: Workaround https://issues.dlang.org/show_bug.cgi?id=16779 (make alias to staticArray once fixed)
pragma(inline, true) U[T.length] staticArrayCast(U = CommonType!T, T...)(T a) @nogc
{
    enum n = T.length;
    U[n] ret = void;
    static foreach (i; 0 .. n)
        cast(Unqual!U)(ret[i]) = cast(U)(a[i]);
    return ret;
}

///
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
    {
        // see D20180214T185602
        // auto a = staticArray!byte(1, 2);
        auto a = staticArrayCast!byte(1, 2);
        assert(is(typeof(a) == byte[2]));
        assert(a == [1, 2]);
    }
    {
        auto a = staticArrayCast!byte(1, 129);
        assert(a == [1, -127]);
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

//U[n] asStatic(U, T, size_t n)(auto ref T[n] arr) @nogc if (!is(U == T) && is(T : U))
U[n] asStatic(U, T, size_t n)(auto ref T[n] arr) @nogc if (!is(U == T))
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

///
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
        // https://issues.dlang.org/show_bug.cgi?id=16779
        //auto a2 = [1, 2, 3].asStatic!byte;
        //auto a3 = [1, 2, 3].asStatic!ubyte;
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
