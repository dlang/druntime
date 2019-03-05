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
if (is(T == float) || is(T == double) || is(T == real) ||
    is(T == ifloat) || is(T == idouble) || is(T == ireal))
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

enum isFloatingTypeInfoT(T) = is(T ==  float) || is(T ==  double) || is(T ==  real) ||
                              is(T == cfloat) || is(T == cdouble) || is(T == creal) ||
                              is(T == ifloat) || is(T == idouble) || is(T == ireal);

template Array(T)
if (isFloatingTypeInfoT!T)
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

enum isIntegralTypeInfoT(T) = is(T == int) || is(T == uint) || is(T == dchar) ||
        is(T == long) || is(T == ulong) ||
        is(T == short) || is(T == ushort) || is(T == wchar) ||
        is(T == byte) || is(T == ubyte) || is(T == void) || is(T == bool) ||
        is(T == char) || is(T == immutable(char)) || is(T == const(char));

template Array(T)
if (isIntegralTypeInfoT!T)
{
    bool equals(T[] s1, T[] s2)
    {
        import core.stdc.string;
        alias U = equalsBaseType!T;

        auto len = s1.length;
        return len == s2.length &&
               memcmp(cast(U*) s1, cast(U*) s2, len * U.sizeof) == 0;
    }

    int compare(T[] ss1, T[] ss2)
    {
        alias U = compareBaseType!T;
        U[] s1 = cast(U[]) ss1;
        U[] s2 = cast(U[]) ss2;

        static if (is(U == char))
        {
            import core.internal.string;
            return dstrcmp(s1, s2);
        }
        else
        {
            size_t len1 = s1.length;
            size_t len2 = s2.length;
            size_t minLen = len1 < len2 ? len1 : len2;

            for (size_t u = 0; u < minLen; u++)
            {
                if (s1[u] < s2[u])
                    return -1;
                else if (s1[u] > s2[u])
                    return 1;
            }
            if (len1 < len2)
                return -1;
            else if (len1 > len2)
                return 1;
            return 0;
        }
    }

    public alias hashOf = core.internal.hash.hashOf;
}

mixin template TypeInfo_A_T(T)
if (isFloatingTypeInfoT!T || isIntegralTypeInfoT!T)
{
    override bool opEquals(Object o) { return TypeInfo.opEquals(o); }

    override string toString() const { return (T[]).stringof; }

    override size_t getHash(scope const void* p) @trusted const
    {
        static if (isFloatingTypeInfoT!T)
        {
            return Array!T.hashOf(*cast(T[]*)p);
        }
        else
        {
            alias U = hashBaseType!T;
            static if (is(U == char))
                U[] s = *cast(U[]*)p;
            else
                const s = *cast(const U[]*)p;
            return hashOf(s);
        }
    }

    override bool equals(in void* p1, in void* p2) const
    {
        return Array!T.equals(*cast(T[]*)p1, *cast(T[]*)p2);
    }

    override int compare(in void* p1, in void* p2) const
    {
        return Array!T.compare(*cast(T[]*)p1, *cast(T[]*)p2);
    }

    override @property inout(TypeInfo) next() inout
    {
        return cast(inout)typeid(T);
    }
}

template hashBaseType(T)
{
    static if (is(T == int) || is(T == uint) || is(T == dchar))
        alias hashBaseType = uint;
    else static if (is(T == long) || is(T == ulong))
        alias hashBaseType = ulong;
    else static if (is(T == short) || is(T == ushort) || is(T == wchar))
        alias hashBaseType = ushort;
    else static if(is(T == byte) || is(T == ubyte) || is(T == void) || is(T == bool))
        alias hashBaseType = void;
    else static if (is(T == char) || is(T == immutable(char)) || is(T == const(char)))
        alias hashBaseType = char;
    else
        alias hashBaseType = T;
}

template equalsBaseType(T)
{
    static if (is(T == int) || is(T == uint) || is(T == dchar))
        alias equalsBaseType = int;
    else static if (is(T == long) || is(T == ulong))
        alias equalsBaseType = long;
    else static if (is(T == short) || is(T == ushort) || is(T == wchar))
        alias equalsBaseType = short;
    else static if(is(T == byte) || is(T == ubyte) || is(T == void) || is(T == bool) ||
                   is(T == char) || is(T == immutable(char)) || is(T == const(char)))
        alias equalsBaseType = byte;
    else
        alias equalsBaseType = T;
}

template compareBaseType(T)
{
    static if (is(T == ubyte) || is(T == void) || is(T == bool) ||
               is(T == char) || is(T == immutable(char)) || is(T == const(char)))
        alias compareBaseType = char;
    else static if (is(T == ushort) || is(T == wchar))
        alias compareBaseType = ushort;
    else static if (is(T == uint) || is(T == dchar))
        alias compareBaseType = uint;
    else // byte || short || int || long || ulong
        alias compareBaseType = T;
}

version (unittest)
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
