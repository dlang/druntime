/**
 * This module contains utilities for TypeInfo implementation.
 *
 * Copyright: Copyright Kenji Hara 2014-.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Kenji Hara
 */
module rt.util.typeinfo;
static import core.internal.hash;

template Floating(T)
if (is(T == float) || is(T == double) || is(T == real))
{
  pure nothrow @safe:

    bool equals(T f1, T f2)
    {
        return f1 == f2;
    }

    int compare(T d1, T d2)
    {
        if (d1 != d1 || d2 != d2) // if either are NaN
        {
            if (d1 != d1)
            {
                if (d2 != d2)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (d1 == d2) ? 0 : ((d1 < d2) ? -1 : 1);
    }

    public alias hashOf = core.internal.hash.hashOf;
}
template Floating(T)
if (is(T == cfloat) || is(T == cdouble) || is(T == creal))
{
  pure nothrow @safe:

    bool equals(T f1, T f2)
    {
        return f1 == f2;
    }

    int compare(T f1, T f2)
    {
        int result;

        if (f1.re < f2.re)
            result = -1;
        else if (f1.re > f2.re)
            result = 1;
        else if (f1.im < f2.im)
            result = -1;
        else if (f1.im > f2.im)
            result = 1;
        else
            result = 0;
        return result;
    }

    public alias hashOf = core.internal.hash.hashOf;
}

template Array(T)
if (is(T ==  float) || is(T ==  double) || is(T ==  real) ||
    is(T == cfloat) || is(T == cdouble) || is(T == creal))
{
  pure nothrow @safe:

    bool equals(T[] s1, T[] s2)
    {
        size_t len = s1.length;
        if (len != s2.length)
            return false;
        for (size_t u = 0; u < len; u++)
        {
            if (!Floating!T.equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }

    int compare(T[] s1, T[] s2)
    {
        size_t len = s1.length;
        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            if (int c = Floating!T.compare(s1[u], s2[u]))
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    public alias hashOf = core.internal.hash.hashOf;
}

version (CoreUnittest)
{
    alias TypeTuple(T...) = T;
}
unittest
{
    // Bugzilla 13052

    static struct SX(F) { F f; }
    TypeInfo ti;

    // real types
    foreach (F; TypeTuple!(float, double, real))
    (){ // workaround #2396
        alias S = SX!F;
        F f1 = +0.0,
          f2 = -0.0;

        assert(f1  == f2);
        assert(f1 !is f2);
        ti = typeid(F);
        assert(ti.getHash(&f1) == ti.getHash(&f2));

        F[] a1 = [f1, f1, f1];
        F[] a2 = [f2, f2, f2];
        assert(a1  == a2);
        assert(a1 !is a2);
        ti = typeid(F[]);
        assert(ti.getHash(&a1) == ti.getHash(&a2));

        F[][] aa1 = [a1, a1, a1];
        F[][] aa2 = [a2, a2, a2];
        assert(aa1  == aa2);
        assert(aa1 !is aa2);
        ti = typeid(F[][]);
        assert(ti.getHash(&aa1) == ti.getHash(&aa2));

        S s1 = {f1},
          s2 = {f2};
        assert(s1  == s2);
        assert(s1 !is s2);
        ti = typeid(S);
        assert(ti.getHash(&s1) == ti.getHash(&s2));

        S[] da1 = [S(f1), S(f1), S(f1)],
            da2 = [S(f2), S(f2), S(f2)];
        assert(da1  == da2);
        assert(da1 !is da2);
        ti = typeid(S[]);
        assert(ti.getHash(&da1) == ti.getHash(&da2));

        S[3] sa1 = {f1},
             sa2 = {f2};
        assert(sa1  == sa2);
        assert(sa1[] !is sa2[]);
        ti = typeid(S[3]);
        assert(ti.getHash(&sa1) == ti.getHash(&sa2));
    }();

    // imaginary types
    foreach (F; TypeTuple!(ifloat, idouble, ireal))
    (){ // workaround #2396
        alias S = SX!F;
        F f1 = +0.0i,
          f2 = -0.0i;

        assert(f1  == f2);
        assert(f1 !is f2);
        ti = typeid(F);
        assert(ti.getHash(&f1) == ti.getHash(&f2));

        F[] a1 = [f1, f1, f1];
        F[] a2 = [f2, f2, f2];
        assert(a1  == a2);
        assert(a1 !is a2);
        ti = typeid(F[]);
        assert(ti.getHash(&a1) == ti.getHash(&a2));

        F[][] aa1 = [a1, a1, a1];
        F[][] aa2 = [a2, a2, a2];
        assert(aa1  == aa2);
        assert(aa1 !is aa2);
        ti = typeid(F[][]);
        assert(ti.getHash(&aa1) == ti.getHash(&aa2));

        S s1 = {f1},
          s2 = {f2};
        assert(s1  == s2);
        assert(s1 !is s2);
        ti = typeid(S);
        assert(ti.getHash(&s1) == ti.getHash(&s2));

        S[] da1 = [S(f1), S(f1), S(f1)],
            da2 = [S(f2), S(f2), S(f2)];
        assert(da1  == da2);
        assert(da1 !is da2);
        ti = typeid(S[]);
        assert(ti.getHash(&da1) == ti.getHash(&da2));

        S[3] sa1 = {f1},
             sa2 = {f2};
        assert(sa1  == sa2);
        assert(sa1[] !is sa2[]);
        ti = typeid(S[3]);
        assert(ti.getHash(&sa1) == ti.getHash(&sa2));
    }();

    // complex types
    foreach (F; TypeTuple!(cfloat, cdouble, creal))
    (){ // workaround #2396
        alias S = SX!F;
        F[4] f = [+0.0 + 0.0i,
                  +0.0 - 0.0i,
                  -0.0 + 0.0i,
                  -0.0 - 0.0i];

        foreach (i, f1; f) foreach (j, f2; f) if (i != j)
        {
            assert(f1 == 0 + 0i);

            assert(f1 == f2);
            assert(f1 !is f2);
            ti = typeid(F);
            assert(ti.getHash(&f1) == ti.getHash(&f2));

            F[] a1 = [f1, f1, f1];
            F[] a2 = [f2, f2, f2];
            assert(a1  == a2);
            assert(a1 !is a2);
            ti = typeid(F[]);
            assert(ti.getHash(&a1) == ti.getHash(&a2));

            F[][] aa1 = [a1, a1, a1];
            F[][] aa2 = [a2, a2, a2];
            assert(aa1  == aa2);
            assert(aa1 !is aa2);
            ti = typeid(F[][]);
            assert(ti.getHash(&aa1) == ti.getHash(&aa2));

            S s1 = {f1},
              s2 = {f2};
            assert(s1  == s2);
            assert(s1 !is s2);
            ti = typeid(S);
            assert(ti.getHash(&s1) == ti.getHash(&s2));

            S[] da1 = [S(f1), S(f1), S(f1)],
                da2 = [S(f2), S(f2), S(f2)];
            assert(da1  == da2);
            assert(da1 !is da2);
            ti = typeid(S[]);
            assert(ti.getHash(&da1) == ti.getHash(&da2));

            S[3] sa1 = {f1},
                 sa2 = {f2};
            assert(sa1  == sa2);
            assert(sa1[] !is sa2[]);
            ti = typeid(S[3]);
            assert(ti.getHash(&sa1) == ti.getHash(&sa2));
        }
    }();
}

private class TypeInfoGeneric(T) : TypeInfo
{
    static if (is(T == ifloat)) private alias Real = float;
    else static if (is(T == idouble)) private alias Real = double;
    else static if (is(T == ireal)) private alias Real = real;
    else private alias Real = T;

    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { return T.stringof; }

    override size_t getHash(scope const void* p)
    {
        static if (__traits(isFloating, T))
            return Floating!Real.hashOf(*cast(Real*)p);
        else
            return hashOf(*cast(const T *)p);
    }

    override bool equals(in void* p1, in void* p2)
    {
        static if (__traits(isFloating, T))
            return Floating!Real.equals(*cast(Real*)p1, *cast(Real*)p2);
        else
            return *cast(T *)p1 == *cast(T *)p2;
    }

    override int compare(in void* p1, in void* p2)
    {
        static if (__traits(isFloating, T))
        {
            return Floating!Real.compare(*cast(Real*)p1, *cast(Real*)p2);
        }
        else static if (T.sizeof < int.sizeof)
        {
            return *cast(T *)p1 - *cast(T *)p2;
        }
        else
        {
            if (*cast(T *)p1 < *cast(T *)p2)
                return -1;
            if (*cast(T *)p1 > *cast(T *)p2)
                return 1;
            return 0;
        }
    }

    override @property size_t tsize() nothrow pure
    {
        return T.sizeof;
    }

    override @property size_t talign() nothrow pure
    {
        return T.alignof;
    }

    override const(void)[] initializer() @trusted
    {
        static if (__traits(isZeroInit, T))
        {
            return (cast(void *)null)[0 .. T.sizeof];
        }
        else
        {
            static immutable T[1] c;
            return c;
        }
    }

    override void swap(void *p1, void *p2)
    {
        auto t = *cast(T *) p1;
        *cast(T *)p1 = *cast(T *)p2;
        *cast(T *)p2 = t;
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe
    {
        return RTInfo!T;
    }

    static if (__traits(isFloating, T))
        static if (is(immutable Real == immutable real) && T.mant_dig != 64) // exclude 80-bit X87
            // passed in SIMD register
            override @property uint flags() const { return 2; }
}

unittest
{
    assert(typeid(int).toString == "int");
    double a = 42, b = 43;
    assert(typeid(double).equals(&a, &a));
    assert(!typeid(double).equals(&a, &b));
    assert(typeid(double).compare(&a, &a) == 0);
    assert(typeid(double).compare(&a, &b) == -1);
    assert(typeid(double).compare(&b, &a) == 1);

    short c = 42, d = 43;
    assert(typeid(short).equals(&c, &c));
    assert(!typeid(short).equals(&c, &b));
    assert(typeid(short).compare(&c, &c) == 0);
    assert(typeid(short).compare(&c, &d) == -1);
    assert(typeid(short).compare(&d, &c) == 1);

    assert(typeid(int).initializer.ptr is null);
    assert(typeid(int).initializer.length == int.sizeof);

    typeid(short).swap(&d, &c);
    assert(c == 43 && d == 42);
}

private class TypeInfoArrayGeneric(T) : TypeInfo_Array
{
    static if (is(T == ifloat)) private alias Real = float;
    else static if (is(T == idouble)) private alias Real = double;
    else static if (is(T == ireal)) private alias Real = real;
    else private alias Real = T;

    override bool opEquals(Object o) { return TypeInfo.opEquals(o); }

    override string toString() const { return (T[]).stringof; }

    override size_t getHash(scope const void* p) @trusted const
    {
        static if (__traits(isFloating, T))
            return Array!Real.hashOf(*cast(Real[]*)p);
        else
        {
            return hashOf(*cast(const T[]*) p);
        }
    }

    override bool equals(in void* p1, in void* p2) const
    {
        static if (__traits(isFloating, T))
        {
            return Array!Real.equals(*cast(Real[]*)p1, *cast(Real[]*)p2);
        }
        else
        {
            import core.stdc.string;
            auto s1 = *cast(T[]*)p1;
            auto s2 = *cast(T[]*)p2;
            return s1.length == s2.length &&
                memcmp(s1.ptr, s2.ptr, s1.length) == 0;
        }
    }

    override int compare(in void* p1, in void* p2) const
    {
        static if (__traits(isFloating, T))
        {
            return Array!Real.compare(*cast(Real[]*)p1, *cast(Real[]*)p2);
        }
        else
        {
            auto s1 = *cast(T[]*)p1;
            auto s2 = *cast(T[]*)p2;
            auto len = s1.length;

            if (s2.length < len)
                len = s2.length;
            for (size_t u = 0; u < len; u++)
            {
                if (int result = (s1[u] > s2[u]) - (s1[u] < s2[u]))
                    return result;
            }
            return (s1.length > s2.length) - (s1.length < s2.length);
        }
    }

    override @property inout(TypeInfo) next() inout
    {
        return cast(inout) typeid(T);
    }
}

unittest
{
    assert(typeid(int[]) == typeid(int[]));
    assert(typeid(int[]) != typeid(uint[]));
    assert(typeid(int[]).toString == "int[]");

    double[] a = [ 1, 2, 3 ], b = [ 2, 3 ];

    assert(typeid(double[]).equals(&a, &a));
    assert(!typeid(double[]).equals(&a, &b));

    assert(typeid(double[]).compare(&a, &a) == 0);
    assert(typeid(double[]).compare(&a, &b) == -1);
    assert(typeid(double[]).compare(&b, &a) == 1);
}

////////////////////////////////////////////////////////////////////////////////
// Predefined TypeInfos
////////////////////////////////////////////////////////////////////////////////

// void
class TypeInfo_v : TypeInfoGeneric!ubyte
{
    const: nothrow: pure: @trusted:

    override string toString() const pure nothrow @safe { return "void"; }

    override size_t getHash(scope const void* p)
    {
        assert(0);
    }

    override @property uint flags() nothrow pure
    {
        return 1;
    }

    unittest
    {
        assert(typeid(void).toString == "void");
        assert(typeid(void).flags == 1);
    }
}

// All integrals.
class TypeInfo_b : TypeInfoGeneric!bool {}
class TypeInfo_g : TypeInfoGeneric!byte {}
class TypeInfo_h : TypeInfoGeneric!ubyte {}
class TypeInfo_a : TypeInfoGeneric!char {}
class TypeInfo_u : TypeInfoGeneric!wchar {}
class TypeInfo_w : TypeInfoGeneric!dchar {}
class TypeInfo_s : TypeInfoGeneric!short {}
class TypeInfo_t : TypeInfoGeneric!ushort {}
class TypeInfo_i : TypeInfoGeneric!int {}
class TypeInfo_k : TypeInfoGeneric!uint {}
class TypeInfo_l : TypeInfoGeneric!long {}
class TypeInfo_m : TypeInfoGeneric!ulong {}
static if (is(cent)) class TypeInfo_zi : TypeInfoGeneric!cent {}
static if (is(ucent)) class TypeInfo_zk : TypeInfoGeneric!ucent {}

// All simple floating-point types.
class TypeInfo_f : TypeInfoGeneric!float {}
class TypeInfo_o : TypeInfoGeneric!ifloat {}
class TypeInfo_d : TypeInfoGeneric!double {}
class TypeInfo_p : TypeInfoGeneric!idouble {}
class TypeInfo_e : TypeInfoGeneric!real {}
class TypeInfo_j : TypeInfoGeneric!ireal {}

// All complex floating-point types.

// cfloat
class TypeInfo_q : TypeInfoGeneric!cfloat
{
    const: nothrow: pure: @trusted:
    static if (__traits(hasMember, TypeInfo, "argTypes"))
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = typeid(double);
            return 0;
        }
}

// cdouble
class TypeInfo_r : TypeInfoGeneric!cdouble
{
    const: nothrow: pure: @trusted:
    static if (__traits(hasMember, TypeInfo, "argTypes"))
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = typeid(double);
            arg2 = typeid(double);
            return 0;
        }
}

// creal
class TypeInfo_c : TypeInfoGeneric!creal
{
    const: nothrow: pure: @trusted:
    static if (__traits(hasMember, TypeInfo, "argTypes"))
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = typeid(real);
            arg2 = typeid(real);
            return 0;
        }
}

// All pointer types are represented by `TypeInfo_P`.
// Please keep in sync with `TypeInfo_Pointer`.
class TypeInfo_P : TypeInfoGeneric!(void*)
{
    const: nothrow: pure: @trusted:

    override size_t getHash(scope const void* p)
    {
        size_t addr = cast(size_t) *cast(const void**)p;
        return addr ^ (addr >> 4);
    }

    override @property uint flags() nothrow pure const { return 1; }
}

unittest
{
    with (new TypeInfo_P)
    {
        int x;
        int* p = &x;
        assert(getHash(&p) != 0);
        assert(flags == 1);
    }
}

// Arrays of all integrals.
class TypeInfo_Ab : TypeInfoArrayGeneric!bool {}
class TypeInfo_Ag : TypeInfoArrayGeneric!byte {}
class TypeInfo_Ah : TypeInfoArrayGeneric!ubyte {}
class TypeInfo_Aa : TypeInfoArrayGeneric!char {}
class TypeInfo_Axa : TypeInfoArrayGeneric!(const char) {}
class TypeInfo_Aya : TypeInfoArrayGeneric!(immutable char)
{
    // Must override this, otherwise "string" is returned.
    override string toString() const { return "immutable(char)[]"; }
}
class TypeInfo_As : TypeInfoArrayGeneric!short {}
class TypeInfo_At : TypeInfoArrayGeneric!ushort {}
class TypeInfo_Au : TypeInfoArrayGeneric!wchar {}
class TypeInfo_Ai : TypeInfoArrayGeneric!int {}
class TypeInfo_Ak : TypeInfoArrayGeneric!uint {}
class TypeInfo_Aw : TypeInfoArrayGeneric!dchar {}
class TypeInfo_Al : TypeInfoArrayGeneric!long {}
class TypeInfo_Am : TypeInfoArrayGeneric!ulong {}

extern (C) void[] _adSort(void[] a, TypeInfo ti);

unittest
{
    assert(typeid(string).toString() == "immutable(char)[]");
    int[][] a = [[5,3,8,7], [2,5,3,8,7]];
    _adSort(*cast(void[]*)&a, typeid(a[0]));
    assert(a == [[2,5,3,8,7], [5,3,8,7]]);

    a = [[5,3,8,7], [5,3,8]];
    _adSort(*cast(void[]*)&a, typeid(a[0]));
    assert(a == [[5,3,8], [5,3,8,7]]);
}

unittest
{
    // Issue 13073: original code uses int subtraction which is susceptible to
    // integer overflow, causing the following case to fail.
    int[] a = [int.max, int.max];
    int[] b = [int.min, int.min];
    assert(a > b);
    assert(b < a);
}

unittest
{
    // Original test case from issue 13073
    uint x = 0x22_DF_FF_FF;
    uint y = 0xA2_DF_FF_FF;
    assert(!(x < y && y < x));
    uint[] a = [x];
    uint[] b = [y];
    assert(!(a < b && b < a)); // Original failing case
    uint[1] a1 = [x];
    uint[1] b1 = [y];
    assert(!(a1 < b1 && b1 < a1)); // Original failing case
}

// Arrays of all floating point types.
class TypeInfo_Af : TypeInfoArrayGeneric!float {}
class TypeInfo_Ao : TypeInfoArrayGeneric!ifloat {}
class TypeInfo_Ad : TypeInfoArrayGeneric!double {}
class TypeInfo_Ap : TypeInfoArrayGeneric!idouble {}
class TypeInfo_Ae : TypeInfoArrayGeneric!real {}
class TypeInfo_Aj : TypeInfoArrayGeneric!ireal {}
class TypeInfo_Aq : TypeInfoArrayGeneric!cfloat {}
class TypeInfo_Ar : TypeInfoArrayGeneric!cdouble {}
class TypeInfo_Ac : TypeInfoArrayGeneric!creal {}

// void[] is a bit different, behaves like ubyte[] for comparison purposes.
class TypeInfo_Av : TypeInfo_Ah
{
    override string toString() const { return "void[]"; }

    override @property inout(TypeInfo) next() inout
    {
        return cast(inout) typeid(void);
    }

    unittest
    {
        assert(typeid(void[]).toString == "void[]");
        assert(typeid(void[]).next == typeid(void));
    }
}

// all delegates
class TypeInfo_D : TypeInfoGeneric!(void delegate(int))
{
    const: nothrow: pure: @trusted:
    override @property uint flags() nothrow pure
    {
        return 1;
    }

    unittest
    {
        assert(typeid(void delegate(int)).flags == 1);
    }
}

// typeof(null)
class TypeInfo_n : TypeInfo
{
    override string toString() const @safe { return "typeof(null)"; }

    override size_t getHash(scope const void* p) const
    {
        return 0;
    }

    override bool equals(in void* p1, in void* p2) const @trusted
    {
        return true;
    }

    override int compare(in void* p1, in void* p2) const @trusted
    {
        return 0;
    }

    override @property size_t tsize() const
    {
        return typeof(null).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        __gshared immutable void[typeof(null).sizeof] init;
        return init;
    }

    override void swap(void *p1, void *p2) const @trusted
    {
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return rtinfoNoPointers; }

    unittest
    {
        with (typeid(typeof(null)))
        {
            assert(toString == "typeof(null)");
            assert(getHash(null) == 0);
            assert(equals(null, null));
            assert(compare(null, null) == 0);
            assert(tsize == typeof(null).sizeof);
            assert(initializer == new ubyte[(void*).sizeof]);
            assert(rtInfo == rtinfoNoPointers);
        }
    }
}

// Test typeinfo for classes.
unittest
{
    static class Bacon
    {
        int sizzle = 1;
        override int opCmp(Object rhs) const
        {
            if (auto rhsb = cast(Bacon) rhs)
                return (sizzle > rhsb.sizzle) - (sizzle < rhsb.sizzle);
            return 0;
        }
    }
    Object obj = new Bacon;
    Bacon obj2 = new Bacon;
    obj2.sizzle = 2;
    auto dummy = new Object;
    with (typeid(obj))
    {
        assert(toString[$ - 6 .. $] == ".Bacon");
        assert(getHash(&obj) != 0);
        assert(equals(&obj, &obj));
        assert(!equals(&obj, &obj2));
        assert(compare(&obj, &dummy) == 0);
        assert(compare(&obj, &obj) == 0);
        assert(compare(&obj, &obj2) == -1);
        assert(compare(&obj2, &obj) == 1);
        assert(tsize == Object.sizeof);
        assert(rtInfo == RTInfo!Bacon);
        assert(tsize == Object.sizeof);
        assert(initializer.ptr !is null);
        assert(initializer.length == __traits(classInstanceSize, Bacon));
        assert(flags == 1);
    }
}
