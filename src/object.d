/**
 * Forms the symbols available to all D programs. Includes Object, which is
 * the root of the class object hierarchy.  This module is implicitly
 * imported.
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, Sean Kelly
 */

module object;

// NOTE: For some reason, this declaration method doesn't work
//       in this particular file (and this file only).  It must
//       be a DMD thing.
//alias typeof(int.sizeof)                    size_t;
//alias typeof(cast(void*)0 - cast(void*)0)   ptrdiff_t;

version (D_LP64)
{
    alias size_t = ulong;
    alias ptrdiff_t = long;
}
else
{
    alias size_t = uint;
    alias ptrdiff_t = int;
}

alias sizediff_t = ptrdiff_t; //For backwards compatibility only.

alias hash_t = size_t; //For backwards compatibility only.
alias equals_t = bool; //For backwards compatibility only.

alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

version (D_ObjectiveC) public import core.attribute : selector;

// Size used to store the TypeInfo at the end of an allocation for structs that
// have a destructor
private size_t structTypeInfoSize(T)() pure nothrow @nogc
{
    // can't use because it's in rt.lifetime
    //if (!callStructDtorsDuringGC)
        //return 0;

    static if (is(T == struct) && is(typeof({ T t; t.__xdtor; })))
        return size_t.sizeof;
    return 0;
}

/*
 * Allocate an uninitialized non-array item.
 * This is an optimization to avoid things needed for arrays like the __arrayPad(size).
 */
private T* ___d_newitemU(T)()
{
    import core.memory;
    import core.internal.traits : Unqual;

    auto ti = typeid(Unqual!T);
    auto flags = !(ti.flags & 1) ? GC.BlkAttr.NO_SCAN : 0;
    enum tiSize = structTypeInfoSize!T();
    enum size = T.sizeof + tiSize;

    static if (is(T == struct))
    {
        if (tiSize)
            flags |= GC.BlkAttr.STRUCTFINAL | GC.BlkAttr.FINALIZE;
    }
    auto blkInf = GC.qalloc(size, flags, ti);
    auto p = blkInf.base;

    static if (is(T == struct))
    {
        if (tiSize)
            *cast(TypeInfo*)(p + blkInf.size - tiSize) = cast() ti;
    }
    return cast(T*) p;
}

// Same as above, for item with non-zero initializer.
T* ___d_newitemT(T)()
{
    import core.stdc.string;
    import core.internal.traits : Unqual;
    auto p = (() @trusted => ___d_newitemU!T())();
    static if (__traits(isZeroInit, T))
    {
        () @trusted { memset(cast(Unqual!T *) p, 0, T.sizeof); }();
    }
    else
    {
        auto init = T.init;
        () @trusted { memcpy(cast(Unqual!T *) p, &init, T.sizeof); }();
    }
    return p;
}

int __cmp(T)(scope const T[] lhs, scope const T[] rhs) @trusted
    if (__traits(isScalar, T))
{
    // Compute U as the implementation type for T
    static if (is(T == ubyte) || is(T == void) || is(T == bool))
        alias U = char;
    else static if (is(T == wchar))
        alias U = ushort;
    else static if (is(T == dchar))
        alias U = uint;
    else static if (is(T == ifloat))
        alias U = float;
    else static if (is(T == idouble))
        alias U = double;
    else static if (is(T == ireal))
        alias U = real;
    else
        alias U = T;

    static if (is(U == char))
    {
        import core.internal.string : dstrcmp;
        return dstrcmp(cast(char[]) lhs, cast(char[]) rhs);
    }
    else static if (!is(U == T))
    {
        // Reuse another implementation
        return __cmp(cast(U[]) lhs, cast(U[]) rhs);
    }
    else
    {
        version (BigEndian)
        static if (__traits(isUnsigned, T) ? !is(T == __vector) : is(T : P*, P))
        {
            if (!__ctfe)
            {
                import core.stdc.string : memcmp;
                int c = memcmp(lhs.ptr, rhs.ptr, (lhs.length <= rhs.length ? lhs.length : rhs.length) * T.sizeof);
                if (c)
                    return c;
                static if (size_t.sizeof <= uint.sizeof && T.sizeof >= 2)
                    return cast(int) lhs.length - cast(int) rhs.length;
                else
                    return int(lhs.length > rhs.length) - int(lhs.length < rhs.length);
            }
        }

        immutable len = lhs.length <= rhs.length ? lhs.length : rhs.length;
        foreach (const u; 0 .. len)
        {
            static if (__traits(isFloating, T))
            {
                immutable a = lhs.ptr[u], b = rhs.ptr[u];
                static if (is(T == cfloat) || is(T == cdouble)
                    || is(T == creal))
                {
                    // Use rt.cmath2._Ccmp instead ?
                    auto r = (a.re > b.re) - (a.re < b.re);
                    if (!r) r = (a.im > b.im) - (a.im < b.im);
                }
                else
                {
                    const r = (a > b) - (a < b);
                }
                if (r) return r;
            }
            else if (lhs.ptr[u] != rhs.ptr[u])
                return lhs.ptr[u] < rhs.ptr[u] ? -1 : 1;
        }
        return lhs.length < rhs.length ? -1 : (lhs.length > rhs.length);
    }
}

// Compare class and interface objects for ordering.
private int __cmp(Obj)(Obj lhs, Obj rhs)
if (is(Obj : Object))
{
    if (lhs is rhs)
        return 0;
    // Regard null references as always being "less than"
    if (!lhs)
        return -1;
    if (!rhs)
        return 1;
    return lhs.opCmp(rhs);
}

// This function is called by the compiler when dealing with array
// comparisons in the semantic analysis phase of CmpExp. The ordering
// comparison is lowered to a call to this template.
int __cmp(T1, T2)(T1[] s1, T2[] s2)
if (!__traits(isScalar, T1) && !__traits(isScalar, T2))
{
    import core.internal.traits : Unqual;
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static if (is(U1 == void) && is(U2 == void))
        static @trusted ref inout(ubyte) at(inout(void)[] r, size_t i) { return (cast(inout(ubyte)*) r.ptr)[i]; }
    else
        static @trusted ref R at(R)(R[] r, size_t i) { return r.ptr[i]; }

    // All unsigned byte-wide types = > dstrcmp
    immutable len = s1.length <= s2.length ? s1.length : s2.length;

    foreach (const u; 0 .. len)
    {
        static if (__traits(compiles, __cmp(at(s1, u), at(s2, u))))
        {
            auto c = __cmp(at(s1, u), at(s2, u));
            if (c != 0)
                return c;
        }
        else static if (__traits(compiles, at(s1, u).opCmp(at(s2, u))))
        {
            auto c = at(s1, u).opCmp(at(s2, u));
            if (c != 0)
                return c;
        }
        else static if (__traits(compiles, at(s1, u) < at(s2, u)))
        {
            if (at(s1, u) != at(s2, u))
                return at(s1, u) < at(s2, u) ? -1 : 1;
        }
        else
        {
            // TODO: fix this legacy bad behavior, see
            // https://issues.dlang.org/show_bug.cgi?id=17244
            static assert(is(U1 == U2), "Internal error.");
            import core.stdc.string : memcmp;
            auto c = (() @trusted => memcmp(&at(s1, u), &at(s2, u), U1.sizeof))();
            if (c != 0)
                return c;
        }
    }
    return s1.length < s2.length ? -1 : (s1.length > s2.length);
}

// integral types
@safe unittest
{
    void compareMinMax(T)()
    {
        T[2] a = [T.max, T.max];
        T[2] b = [T.min, T.min];

        assert(__cmp(a, b) > 0);
        assert(__cmp(b, a) < 0);
    }

    compareMinMax!int;
    compareMinMax!uint;
    compareMinMax!long;
    compareMinMax!ulong;
    compareMinMax!short;
    compareMinMax!ushort;
    compareMinMax!byte;
    compareMinMax!dchar;
    compareMinMax!wchar;
}

// char types (dstrcmp)
@safe unittest
{
    void compareMinMax(T)()
    {
        T[2] a = [T.max, T.max];
        T[2] b = [T.min, T.min];

        assert(__cmp(a, b) > 0);
        assert(__cmp(b, a) < 0);
    }

    compareMinMax!ubyte;
    compareMinMax!bool;
    compareMinMax!char;
    compareMinMax!(const char);

    string s1 = "aaaa";
    string s2 = "bbbb";
    assert(__cmp(s2, s1) > 0);
    assert(__cmp(s1, s2) < 0);
}

// fp types
@safe unittest
{
    void compareMinMax(T)()
    {
        T[2] a = [T.max, T.max];
        T[2] b = [T.min_normal, T.min_normal];
        T[2] c = [T.max, T.min_normal];
        T[1] d = [T.max];

        assert(__cmp(a, b) > 0);
        assert(__cmp(b, a) < 0);
        assert(__cmp(a, c) > 0);
        assert(__cmp(a, d) > 0);
        assert(__cmp(d, c) < 0);
        assert(__cmp(c, c) == 0);
    }

    compareMinMax!real;
    compareMinMax!float;
    compareMinMax!double;
    compareMinMax!ireal;
    compareMinMax!ifloat;
    compareMinMax!idouble;
    compareMinMax!creal;
    //compareMinMax!cfloat;
    compareMinMax!cdouble;

    // qualifiers
    compareMinMax!(const real);
    compareMinMax!(immutable real);
}

// void[]
@safe unittest
{
    void[] a;
    const(void)[] b;

    (() @trusted
    {
        a = cast(void[]) "bb";
        b = cast(const(void)[]) "aa";
    })();

    assert(__cmp(a, b) > 0);
    assert(__cmp(b, a) < 0);
}

// arrays of arrays with mixed modifiers
@safe unittest
{
    // https://issues.dlang.org/show_bug.cgi?id=17876
    bool less1(immutable size_t[][] a, size_t[][] b) { return a < b; }
    bool less2(const void[][] a, void[][] b) { return a < b; }
    bool less3(inout size_t[][] a, size_t[][] b) { return a < b; }

    immutable size_t[][] a = [[1, 2], [3, 4]];
    size_t[][] b = [[1, 2], [3, 5]];
    assert(less1(a, b));
    assert(less3(a, b));

    auto va = [cast(immutable void[])a[0], a[1]];
    auto vb = [cast(void[])b[0], b[1]];
    assert(less2(va, vb));
}

// objects
@safe unittest
{
    class C
    {
        int i;
        this(int i) { this.i = i; }

        override int opCmp(Object c) const @safe
        {
            return i - (cast(C)c).i;
        }
    }

    auto c1 = new C(1);
    auto c2 = new C(2);
    assert(__cmp(c1, null) > 0);
    assert(__cmp(null, c1) < 0);
    assert(__cmp(c1, c1) == 0);
    assert(__cmp(c1, c2) < 0);
    assert(__cmp(c2, c1) > 0);

    assert(__cmp([c1, c1][], [c2, c2][]) < 0);
    assert(__cmp([c2, c2], [c1, c1]) > 0);
}

// structs
@safe unittest
{
    struct C
    {
        ubyte i;
        this(ubyte i) { this.i = i; }
    }

    auto c1 = C(1);
    auto c2 = C(2);

    assert(__cmp([c1, c1][], [c2, c2][]) < 0);
    assert(__cmp([c2, c2], [c1, c1]) > 0);
    assert(__cmp([c2, c2], [c2, c1]) > 0);
}

// `lhs == rhs` lowers to `__equals(lhs, rhs)` for dynamic arrays
bool __equals(T1, T2)(T1[] lhs, T2[] rhs)
{
    import core.internal.traits : Unqual;
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static @trusted ref R at(R)(R[] r, size_t i) { return r.ptr[i]; }
    static @trusted R trustedCast(R, S)(S[] r) { return cast(R) r; }

    if (lhs.length != rhs.length)
        return false;

    if (lhs.length == 0 && rhs.length == 0)
        return true;

    static if (is(U1 == void) && is(U2 == void))
    {
        return __equals(trustedCast!(ubyte[])(lhs), trustedCast!(ubyte[])(rhs));
    }
    else static if (is(U1 == void))
    {
        return __equals(trustedCast!(ubyte[])(lhs), rhs);
    }
    else static if (is(U2 == void))
    {
        return __equals(lhs, trustedCast!(ubyte[])(rhs));
    }
    else static if (!is(U1 == U2))
    {
        // This should replace src/object.d _ArrayEq which
        // compares arrays of different types such as long & int,
        // char & wchar.
        // Compiler lowers to __ArrayEq in dmd/src/opover.d
        foreach (const u; 0 .. lhs.length)
        {
            if (at(lhs, u) != at(rhs, u))
                return false;
        }
        return true;
    }
    else static if (__traits(isIntegral, U1))
    {

        if (!__ctfe)
        {
            import core.stdc.string : memcmp;
            return () @trusted { return memcmp(cast(void*)lhs.ptr, cast(void*)rhs.ptr, lhs.length * U1.sizeof) == 0; }();
        }
        else
        {
            foreach (const u; 0 .. lhs.length)
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            return true;
        }
    }
    else
    {
        foreach (const u; 0 .. lhs.length)
        {
            static if (__traits(compiles, __equals(at(lhs, u), at(rhs, u))))
            {
                if (!__equals(at(lhs, u), at(rhs, u)))
                    return false;
            }
            else static if (__traits(isFloating, U1))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (is(U1 : Object) && is(U2 : Object))
            {
                if (!(cast(Object)at(lhs, u) is cast(Object)at(rhs, u)
                    || at(lhs, u) && (cast(Object)at(lhs, u)).opEquals(cast(Object)at(rhs, u))))
                    return false;
            }
            else static if (__traits(hasMember, U1, "opEquals"))
            {
                if (!at(lhs, u).opEquals(at(rhs, u)))
                    return false;
            }
            else static if (is(U1 == delegate))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (is(U1 == U11*, U11))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (__traits(isAssociativeArray, U1))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else
            {
                if (at(lhs, u).tupleof != at(rhs, u).tupleof)
                    return false;
            }
        }

        return true;
    }
}

@safe unittest
{
    assert(__equals([], []));
    assert(!__equals([1, 2], [1, 2, 3]));
}

@safe unittest
{
    struct A
    {
        int a;
    }

    auto arr1 = [A(0), A(2)];
    auto arr2 = [A(0), A(1)];
    auto arr3 = [A(0), A(1)];

    assert(arr1 != arr2);
    assert(arr2 == arr3);
}

@safe unittest
{
    struct A
    {
        int a;
        int b;

        bool opEquals(const A other)
        {
            return this.a == other.b && this.b == other.a;
        }
    }

    auto arr1 = [A(1, 0), A(0, 1)];
    auto arr2 = [A(1, 0), A(0, 1)];
    auto arr3 = [A(0, 1), A(1, 0)];

    assert(arr1 != arr2);
    assert(arr2 == arr3);
}

// https://issues.dlang.org/show_bug.cgi?id=18252
@safe unittest
{
    string[int][] a1, a2;
    assert(__equals(a1, a2));
    assert(a1 == a2);
    a1 ~= [0: "zero"];
    a2 ~= [0: "zero"];
    assert(__equals(a1, a2));
    assert(a1 == a2);
    a2[0][1] = "one";
    assert(!__equals(a1, a2));
    assert(a1 != a2);
}

/**
Destroys the given object and optionally resets to initial state. It's used to
_destroy an object, calling its destructor or finalizer so it no longer
references any other objects. It does $(I not) initiate a GC cycle or free
any GC memory.
If `initialize` is supplied `false`, the object is considered invalid after
destruction, and should not be referenced.
*/
void destroy(bool initialize = true, T)(ref T obj) if (is(T == struct))
{
    _destructRecurse(obj);

    static if (initialize)
    {
        // We need to re-initialize `obj`.  Previously, an immutable static
        // and memcpy were used to hold an initializer. With improved unions, this is no longer
        // needed.
        union UntypedInit
        {
            T dummy;
        }
        static struct UntypedStorage
        {
            align(T.alignof) void[T.sizeof] dummy;
        }

        () @trusted {
            *cast(UntypedStorage*) &obj = cast(UntypedStorage) UntypedInit.init;
        } ();
    }
}

@safe unittest
{
    struct A { string s = "A";  }
    A a = {s: "B"};
    assert(a.s == "B");
    a.destroy;
    assert(a.s == "A");
}

private void _destructRecurse(S)(ref S s)
    if (is(S == struct))
{
    static if (__traits(hasMember, S, "__xdtor") &&
            // Bugzilla 14746: Check that it's the exact member of S.
            __traits(isSame, S, __traits(parent, s.__xdtor)))
        s.__xdtor();
}

nothrow @safe @nogc unittest
{
    {
        struct A { string s = "A";  }
        A a;
        a.s = "asd";
        destroy!false(a);
        assert(a.s == "asd");
        destroy(a);
        assert(a.s == "A");
    }
    {
        static int destroyed = 0;
        struct C
        {
            string s = "C";
            ~this() nothrow @safe @nogc
            {
                destroyed ++;
            }
        }

        struct B
        {
            C c;
            string s = "B";
            ~this() nothrow @safe @nogc
            {
                destroyed ++;
            }
        }
        B a;
        a.s = "asd";
        a.c.s = "jkl";
        destroy!false(a);
        assert(destroyed == 2);
        assert(a.s == "asd");
        assert(a.c.s == "jkl" );
        destroy(a);
        assert(destroyed == 4);
        assert(a.s == "B");
        assert(a.c.s == "C" );
    }
}

/// ditto
void destroy(bool initialize = true, T)(T obj) if (is(T == class))
{
    static if (__traits(getLinkage, T) == "C++")
    {
        obj.__xdtor();

        static if (initialize)
        {
            enum classSize = __traits(classInstanceSize, T);
            (cast(void*)obj)[0 .. classSize] = typeid(T).initializer[];
        }
    }
    else
        rt_finalize(cast(void*)obj);
}

/// ditto
void destroy(bool initialize = true, T)(T obj) if (is(T == interface))
{
    static assert(__traits(getLinkage, T) == "D", "Invalid call to destroy() on extern(" ~ __traits(getLinkage, T) ~ ") interface");

    destroy!initialize(cast(Object)obj);
}

/// Reference type demonstration
@system unittest
{
    class C
    {
        struct Agg
        {
            static int dtorCount;

            int x = 10;
            ~this() { dtorCount++; }
        }

        static int dtorCount;

        string s = "S";
        Agg a;
        ~this() { dtorCount++; }
    }

    C c = new C();
    assert(c.dtorCount == 0);   // destructor not yet called
    assert(c.s == "S");         // initial state `c.s` is `"S"`
    assert(c.a.dtorCount == 0); // destructor not yet called
    assert(c.a.x == 10);        // initial state `c.a.x` is `10`
    c.s = "T";
    c.a.x = 30;
    assert(c.s == "T");         // `c.s` is `"T"`
    destroy(c);
    assert(c.dtorCount == 1);   // `c`'s destructor was called
    assert(c.s == "S");         // `c.s` is back to its inital state, `"S"`
    assert(c.a.dtorCount == 1); // `c.a`'s destructor was called
    assert(c.a.x == 10);        // `c.a.x` is back to its inital state, `10`

    // check C++ classes work too!
    extern (C++) class CPP
    {
        struct Agg
        {
            __gshared int dtorCount;

            int x = 10;
            ~this() { dtorCount++; }
        }

        __gshared int dtorCount;

        string s = "S";
        Agg a;
        ~this() { dtorCount++; }
    }

    CPP cpp = new CPP();
    assert(cpp.dtorCount == 0);   // destructor not yet called
    assert(cpp.s == "S");         // initial state `cpp.s` is `"S"`
    assert(cpp.a.dtorCount == 0); // destructor not yet called
    assert(cpp.a.x == 10);        // initial state `cpp.a.x` is `10`
    cpp.s = "T";
    cpp.a.x = 30;
    assert(cpp.s == "T");         // `cpp.s` is `"T"`
    destroy!false(cpp);           // destroy without initialization
    assert(cpp.dtorCount == 1);   // `cpp`'s destructor was called
    assert(cpp.s == "T");         // `cpp.s` is not initialized
    assert(cpp.a.dtorCount == 1); // `cpp.a`'s destructor was called
    assert(cpp.a.x == 30);        // `cpp.a.x` is not initialized
    destroy(cpp);
    assert(cpp.dtorCount == 2);   // `cpp`'s destructor was called again
    assert(cpp.s == "S");         // `cpp.s` is back to its inital state, `"S"`
    assert(cpp.a.dtorCount == 2); // `cpp.a`'s destructor was called again
    assert(cpp.a.x == 10);        // `cpp.a.x` is back to its inital state, `10`
}

/// Value type demonstration
@safe unittest
{
    int i;
    assert(i == 0);           // `i`'s initial state is `0`
    i = 1;
    assert(i == 1);           // `i` changed to `1`
    destroy!false(i);
    assert(i == 1);           // `i` was not initialized
    destroy(i);
    assert(i == 0);           // `i` is back to its initial state `0`
}

@system unittest
{
    // class with an `alias this`
    class A
    {
        static int dtorCount;
        ~this()
        {
            dtorCount++;
        }
    }

    class B
    {
        A a;
        alias a this;
        this()
        {
            a = new A;
        }
        static int dtorCount;
        ~this()
        {
            dtorCount++;
        }
    }
    auto b = new B;
    assert(A.dtorCount == 0);
    assert(B.dtorCount == 0);
    destroy(b);
    assert(A.dtorCount == 0);
    assert(B.dtorCount == 1);
}

@system unittest
{
    interface I { }
    {
        class A: I { string s = "A"; this() {} }
        auto a = new A, b = new A;
        a.s = b.s = "asd";
        destroy(a);
        assert(a.s == "A");

        I i = b;
        destroy(i);
        assert(b.s == "A");
    }
    {
        static bool destroyed = false;
        class B: I
        {
            string s = "B";
            this() {}
            ~this()
            {
                destroyed = true;
            }
        }
        auto a = new B, b = new B;
        a.s = b.s = "asd";
        destroy(a);
        assert(destroyed);
        assert(a.s == "B");

        destroyed = false;
        I i = b;
        destroy(i);
        assert(destroyed);
        assert(b.s == "B");
    }
    // this test is invalid now that the default ctor is not run after clearing
    version (none)
    {
        class C
        {
            string s;
            this()
            {
                s = "C";
            }
        }
        auto a = new C;
        a.s = "asd";
        destroy(a);
        assert(a.s == "C");
    }
}

nothrow @safe @nogc unittest
{
    {
        struct A { string s = "A";  }
        A a;
        a.s = "asd";
        destroy!false(a);
        assert(a.s == "asd");
        destroy(a);
        assert(a.s == "A");
    }
    {
        static int destroyed = 0;
        struct C
        {
            string s = "C";
            ~this() nothrow @safe @nogc
            {
                destroyed ++;
            }
        }

        struct B
        {
            C c;
            string s = "B";
            ~this() nothrow @safe @nogc
            {
                destroyed ++;
            }
        }
        B a;
        a.s = "asd";
        a.c.s = "jkl";
        destroy!false(a);
        assert(destroyed == 2);
        assert(a.s == "asd");
        assert(a.c.s == "jkl" );
        destroy(a);
        assert(destroyed == 4);
        assert(a.s == "B");
        assert(a.c.s == "C" );
    }
}

/// ditto
void destroy(bool initialize = true, T : U[n], U, size_t n)(ref T obj) if (!is(T == struct))
{
    foreach_reverse (ref e; obj[])
        destroy!initialize(e);
}

@safe unittest
{
    int[2] a;
    a[0] = 1;
    a[1] = 2;
    destroy!false(a);
    assert(a == [ 1, 2 ]);
    destroy(a);
    assert(a == [ 0, 0 ]);
}

@safe unittest
{
    static struct vec2f {
        float[2] values;
        alias values this;
    }

    vec2f v;
    destroy!(true, vec2f)(v);
}

@system unittest
{
    // Bugzilla 15009
    static string op;
    static struct S
    {
        int x;
        this(int x) { op ~= "C" ~ cast(char)('0'+x); this.x = x; }
        this(this)  { op ~= "P" ~ cast(char)('0'+x); }
        ~this()     { op ~= "D" ~ cast(char)('0'+x); }
    }

    {
        S[2] a1 = [S(1), S(2)];
        op = "";
    }
    assert(op == "D2D1");   // built-in scope destruction
    {
        S[2] a1 = [S(1), S(2)];
        op = "";
        destroy(a1);
        assert(op == "D2D1");   // consistent with built-in behavior
    }

    {
        S[2][2] a2 = [[S(1), S(2)], [S(3), S(4)]];
        op = "";
    }
    assert(op == "D4D3D2D1");
    {
        S[2][2] a2 = [[S(1), S(2)], [S(3), S(4)]];
        op = "";
        destroy(a2);
        assert(op == "D4D3D2D1", op);
    }
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj)
    if (!is(T == struct) && !is(T == interface) && !is(T == class) && !_isStaticArray!T)
{
    static if (initialize)
        obj = T.init;
}

template _isStaticArray(T : U[N], U, size_t N)
{
    enum bool _isStaticArray = true;
}

template _isStaticArray(T)
{
    enum bool _isStaticArray = false;
}

@safe unittest
{
    {
        int a = 42;
        destroy!false(a);
        assert(a == 42);
        destroy(a);
        assert(a == 0);
    }
    {
        float a = 42;
        destroy!false(a);
        assert(a == 42);
        destroy(a);
        assert(a != a); // isnan
    }
}


private
{
    extern (C) Object _d_newclass(const TypeInfo_Class ci);
    extern (C) void rt_finalize(void *data, bool det=true);
}

public @trusted @nogc nothrow pure extern (C) void _d_delThrowable(scope Throwable);

/**
 * All D class objects inherit from Object.
 */
class Object
{
    /**
     * Convert Object to a human readable string.
     */
    string toString()
    {
        return typeid(this).name;
    }

    /**
     * Compute hash function for Object.
     */
    size_t toHash() @trusted nothrow
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        size_t addr = cast(size_t) cast(void*) this;
        // The bottom log2((void*).alignof) bits of the address will always
        // be 0. Moreover it is likely that each Object is allocated with a
        // separate call to malloc. The alignment of malloc differs from
        // platform to platform, but rather than having special cases for
        // each platform it is safe to use a shift of 4. To minimize
        // collisions in the low bits it is more important for the shift to
        // not be too small than for the shift to not be too big.
        return addr ^ (addr >>> 4);
    }

    /**
     * Compare with another Object obj.
     * Returns:
     *  $(TABLE
     *  $(TR $(TD this &lt; obj) $(TD &lt; 0))
     *  $(TR $(TD this == obj) $(TD 0))
     *  $(TR $(TD this &gt; obj) $(TD &gt; 0))
     *  )
     */
    int opCmp(Object o)
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        //return cast(int)cast(void*)this - cast(int)cast(void*)o;

        throw new Exception("need opCmp for class " ~ typeid(this).name);
        //return this !is o;
    }

    /**
     * Test whether $(D this) is equal to $(D o).
     * The default implementation only compares by identity (using the $(D is) operator).
     * Generally, overrides for $(D opEquals) should attempt to compare objects by their contents.
     */
    bool opEquals(Object o)
    {
        return this is o;
    }

    interface Monitor
    {
        void lock();
        void unlock();
    }

    /**
     * Create instance of class specified by the fully qualified name
     * classname.
     * The class must either have no constructors or have
     * a default constructor.
     * Returns:
     *   null if failed
     * Example:
     * ---
     * module foo.bar;
     *
     * class C
     * {
     *     this() { x = 10; }
     *     int x;
     * }
     *
     * void main()
     * {
     *     auto c = cast(C)Object.factory("foo.bar.C");
     *     assert(c !is null && c.x == 10);
     * }
     * ---
     */
    static Object factory(string classname)
    {
        auto ci = TypeInfo_Class.find(classname);
        if (ci)
        {
            return ci.create();
        }
        return null;
    }
}

bool opEquals(Object lhs, Object rhs)
{
    // If aliased to the same object or both null => equal
    if (lhs is rhs) return true;

    // If either is null => non-equal
    if (lhs is null || rhs is null) return false;

    // If same exact type => one call to method opEquals
    if (typeid(lhs) is typeid(rhs) ||
        !__ctfe && typeid(lhs).opEquals(typeid(rhs)))
            /* CTFE doesn't like typeid much. 'is' works, but opEquals doesn't
            (issue 7147). But CTFE also guarantees that equal TypeInfos are
            always identical. So, no opEquals needed during CTFE. */
    {
        return lhs.opEquals(rhs);
    }

    // General case => symmetric calls to method opEquals
    return lhs.opEquals(rhs) && rhs.opEquals(lhs);
}

/************************
* Returns true if lhs and rhs are equal.
*/
bool opEquals(const Object lhs, const Object rhs)
{
    // A hack for the moment.
    return opEquals(cast()lhs, cast()rhs);
}

/// If aliased to the same object or both null => equal
@system unittest
{
    class F { int flag; this(int flag) { this.flag = flag; } }

    F f;
    assert(f == f); // both null
    f = new F(1);
    assert(f == f); // both aliased to the same object
}

/// If either is null => non-equal
@system unittest
{
    class F { int flag; this(int flag) { this.flag = flag; } }
    F f;
    assert(!(new F(0) == f));
    assert(!(f == new F(0)));
}

/// If same exact type => one call to method opEquals
@system unittest
{
    class F
    {
        int flag;

        this(int flag)
        {
            this.flag = flag;
        }

        override bool opEquals(const Object o)
        {
            return flag == (cast(F) o).flag;
        }
    }

    F f;
    assert(new F(0) == new F(0));
    assert(!(new F(0) == new F(1)));
}

/// General case => symmetric calls to method opEquals
@system unittest
{
    int fEquals, gEquals;

    class Base
    {
        int flag;
        this(int flag)
        {
            this.flag = flag;
        }
    }

    class F : Base
    {
        this(int flag) { super(flag); }

        override bool opEquals(const Object o)
        {
            fEquals++;
            return flag == (cast(Base) o).flag;
        }
    }

    class G : Base
    {
        this(int flag) { super(flag); }

        override bool opEquals(const Object o)
        {
            gEquals++;
            return flag == (cast(Base) o).flag;
        }
    }

    assert(new F(1) == new G(1));
    assert(fEquals == 1);
    assert(gEquals == 1);
}

private extern(C) void _d_setSameMutex(shared Object ownee, shared Object owner) nothrow;

void setSameMutex(shared Object ownee, shared Object owner)
{
    _d_setSameMutex(ownee, owner);
}

/**
 * Information about an interface.
 * When an object is accessed via an interface, an Interface* appears as the
 * first entry in its vtbl.
 */
struct Interface
{
    TypeInfo_Class   classinfo;  /// .classinfo for this interface (not for containing class)
    void*[]     vtbl;
    size_t      offset;     /// offset to Interface 'this' from Object 'this'
}

/**
 * Array of pairs giving the offset and type information for each
 * member in an aggregate.
 */
struct OffsetTypeInfo
{
    size_t   offset;    /// Offset of member from start of object
    TypeInfo ti;        /// TypeInfo for this member
}

/**
 * Runtime type information about a type.
 * Can be retrieved for any type using a
 * $(GLINK2 expression,TypeidExpression, TypeidExpression).
 */
class TypeInfo
{
    override string toString() const pure @safe nothrow
    {
        return typeid(this).name;
    }

    override size_t toHash() @trusted const nothrow
    {
        return hashOf(this.toString());
    }

    override int opCmp(Object o)
    {
        import core.internal.string : dstrcmp;

        if (this is o)
            return 0;
        TypeInfo ti = cast(TypeInfo)o;
        if (ti is null)
            return 1;
        return dstrcmp(this.toString(), ti.toString());
    }

    override bool opEquals(Object o)
    {
        /* TypeInfo instances are singletons, but duplicates can exist
         * across DLL's. Therefore, comparing for a name match is
         * sufficient.
         */
        if (this is o)
            return true;
        auto ti = cast(const TypeInfo)o;
        return ti && this.toString() == ti.toString();
    }

    /**
     * Computes a hash of the instance of a type.
     * Params:
     *    p = pointer to start of instance of the type
     * Returns:
     *    the hash
     * Bugs:
     *    fix https://issues.dlang.org/show_bug.cgi?id=12516 e.g. by changing this to a truly safe interface.
     */
    size_t getHash(scope const void* p) @trusted nothrow const
    {
        return hashOf(p);
    }

    /// Compares two instances for equality.
    bool equals(in void* p1, in void* p2) const { return p1 == p2; }

    /// Compares two instances for &lt;, ==, or &gt;.
    int compare(in void* p1, in void* p2) const { return _xopCmp(p1, p2); }

    /// Returns size of the type.
    @property size_t tsize() nothrow pure const @safe @nogc { return 0; }

    /// Swaps two instances of the type.
    void swap(void* p1, void* p2) const
    {
        immutable size_t n = tsize;
        for (size_t i = 0; i < n; i++)
        {
            byte t = (cast(byte *)p1)[i];
            (cast(byte*)p1)[i] = (cast(byte*)p2)[i];
            (cast(byte*)p2)[i] = t;
        }
    }

    /** Get TypeInfo for 'next' type, as defined by what kind of type this is,
    null if none. */
    @property inout(TypeInfo) next() nothrow pure inout @nogc { return null; }

    /**
     * Return default initializer.  If the type should be initialized to all
     * zeros, an array with a null ptr and a length equal to the type size will
     * be returned. For static arrays, this returns the default initializer for
     * a single element of the array, use `tsize` to get the correct size.
     */
    abstract const(void)[] initializer() nothrow pure const @safe @nogc;

    /** Get flags for type: 1 means GC should scan for pointers,
    2 means arg of this type is passed in XMM register */
    @property uint flags() nothrow pure const @safe @nogc { return 0; }

    /// Get type information on the contents of the type; null if not available
    const(OffsetTypeInfo)[] offTi() const { return null; }
    /// Run the destructor on the object and all its sub-objects
    void destroy(void* p) const {}
    /// Run the postblit on the object and all its sub-objects
    void postblit(void* p) const {}


    /// Return alignment of type
    @property size_t talign() nothrow pure const @safe @nogc { return tsize; }

    /** Return internal info on arguments fitting into 8byte.
     * See X86-64 ABI 3.2.3
     */
    version (X86_64) int argTypes(out TypeInfo arg1, out TypeInfo arg2) @safe nothrow
    {
        arg1 = this;
        return 0;
    }

    /** Return info used by the garbage collector to do precise collection.
     */
    @property immutable(void)* rtInfo() nothrow pure const @safe @nogc { return rtinfoHasPointers; } // better safe than sorry
}

class TypeInfo_Enum : TypeInfo
{
    override string toString() const { return name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Enum)o;
        return c && this.name == c.name &&
                    this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { return base.getHash(p); }
    override bool equals(in void* p1, in void* p2) const { return base.equals(p1, p2); }
    override int compare(in void* p1, in void* p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void* p1, void* p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return base.flags; }

    override const(void)[] initializer() const
    {
        return m_init.length ? m_init : base.initializer();
    }

    override @property size_t talign() nothrow pure const { return base.talign; }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    override @property immutable(void)* rtInfo() const { return base.rtInfo; }

    TypeInfo base;
    string   name;
    void[]   m_init;
}

@safe unittest // issue 12233
{
    static assert(is(typeof(TypeInfo.init) == TypeInfo));
    assert(TypeInfo.init is null);
}


// Please make sure to keep this in sync with TypeInfo_P (src/rt/typeinfo/ti_ptr.d)
class TypeInfo_Pointer : TypeInfo
{
    override string toString() const { return m_next.toString() ~ "*"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Pointer)o;
        return c && this.m_next == c.m_next;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        size_t addr = cast(size_t) *cast(const void**)p;
        return addr ^ (addr >> 4);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        return *cast(void**)p1 == *cast(void**)p2;
    }

    override int compare(in void* p1, in void* p2) const
    {
        if (*cast(void**)p1 < *cast(void**)p2)
            return -1;
        else if (*cast(void**)p1 > *cast(void**)p2)
            return 1;
        else
            return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return (void*).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (void*).sizeof];
    }

    override void swap(void* p1, void* p2) const
    {
        void* tmp = *cast(void**)p1;
        *cast(void**)p1 = *cast(void**)p2;
        *cast(void**)p2 = tmp;
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return m_next; }
    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    override string toString() const { return value.toString() ~ "[]"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Array)o;
        return c && this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        void[] a = *cast(void[]*)p;
        return getArrayHash(value, a.ptr, a.length);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        if (a1.length != a2.length)
            return false;
        size_t sz = value.tsize;
        for (size_t i = 0; i < a1.length; i++)
        {
            if (!value.equals(a1.ptr + i * sz, a2.ptr + i * sz))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const
    {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        size_t sz = value.tsize;
        size_t len = a1.length;

        if (a2.length < len)
            len = a2.length;
        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(a1.ptr + u * sz, a2.ptr + u * sz);
            if (result)
                return result;
        }
        return cast(int)a1.length - cast(int)a2.length;
    }

    override @property size_t tsize() nothrow pure const
    {
        return (void[]).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (void[]).sizeof];
    }

    override void swap(void* p1, void* p2) const
    {
        void[] tmp = *cast(void[]*)p1;
        *cast(void[]*)p1 = *cast(void[]*)p2;
        *cast(void[]*)p2 = tmp;
    }

    TypeInfo value;

    override @property inout(TypeInfo) next() nothrow pure inout
    {
        return value;
    }

    override @property uint flags() nothrow pure const { return 1; }

    override @property size_t talign() nothrow pure const
    {
        return (void[]).alignof;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(size_t);
        arg2 = typeid(void*);
        return 0;
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return RTInfo!(void[]); }
}

class TypeInfo_StaticArray : TypeInfo
{
    override string toString() const
    {
        import core.internal.string : unsignedToTempString;

        char[20] tmpBuff = void;
        return value.toString() ~ "[" ~ unsignedToTempString(len, tmpBuff, 10) ~ "]";
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_StaticArray)o;
        return c && this.len == c.len &&
                    this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        return getArrayHash(value, p, len);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            if (!value.equals(p1 + u * sz, p2 + u * sz))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(p1 + u * sz, p2 + u * sz);
            if (result)
                return result;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return len * value.tsize;
    }

    override void swap(void* p1, void* p2) const
    {
        import core.memory;
        import core.stdc.string : memcpy;

        void* tmp;
        size_t sz = value.tsize;
        ubyte[16] buffer;
        void* pbuffer;

        if (sz < buffer.sizeof)
            tmp = buffer.ptr;
        else
            tmp = pbuffer = (new void[sz]).ptr;

        for (size_t u = 0; u < len; u += sz)
        {
            size_t o = u * sz;
            memcpy(tmp, p1 + o, sz);
            memcpy(p1 + o, p2 + o, sz);
            memcpy(p2 + o, tmp, sz);
        }
        if (pbuffer)
            GC.free(pbuffer);
    }

    override const(void)[] initializer() nothrow pure const
    {
        return value.initializer();
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return value; }
    override @property uint flags() nothrow pure const { return value.flags; }

    override void destroy(void* p) const
    {
        immutable sz = value.tsize;
        p += sz * len;
        foreach (i; 0 .. len)
        {
            p -= sz;
            value.destroy(p);
        }
    }

    override void postblit(void* p) const
    {
        immutable sz = value.tsize;
        foreach (i; 0 .. len)
        {
            value.postblit(p);
            p += sz;
        }
    }

    TypeInfo value;
    size_t   len;

    override @property size_t talign() nothrow pure const
    {
        return value.talign;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        return 0;
    }

    // just return the rtInfo of the element, we have no generic type T to run RTInfo!T on
    override @property immutable(void)* rtInfo() nothrow pure const @safe { return value.rtInfo(); }
}

class TypeInfo_AssociativeArray : TypeInfo
{
    override string toString() const
    {
        return value.toString() ~ "[" ~ key.toString() ~ "]";
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_AssociativeArray)o;
        return c && this.key == c.key &&
                    this.value == c.value;
    }

    override bool equals(in void* p1, in void* p2) @trusted const
    {
        return !!_aaEqual(this, *cast(const void**) p1, *cast(const void**) p2);
    }

    override hash_t getHash(scope const void* p) nothrow @trusted const
    {
        return _aaGetHash(cast(void*)p, this);
    }

    // BUG: need to add the rest of the functions

    override @property size_t tsize() nothrow pure const
    {
        return (char[int]).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (char[int]).sizeof];
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return value; }
    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo value;
    TypeInfo key;

    override @property size_t talign() nothrow pure const
    {
        return (char[int]).alignof;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        return 0;
    }
}

class TypeInfo_Vector : TypeInfo
{
    override string toString() const { return "__vector(" ~ base.toString() ~ ")"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Vector)o;
        return c && this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { return base.getHash(p); }
    override bool equals(in void* p1, in void* p2) const { return base.equals(p1, p2); }
    override int compare(in void* p1, in void* p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void* p1, void* p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return base.flags; }

    override const(void)[] initializer() nothrow pure const
    {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { return 16; }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
}

class TypeInfo_Function : TypeInfo
{
    override string toString() const
    {
        import core.demangle : demangleType;

        alias SafeDemangleFunctionType = char[] function (const(char)[] buf, char[] dst = null) @safe nothrow pure;
        SafeDemangleFunctionType demangle = ( () @trusted => cast(SafeDemangleFunctionType)(&demangleType) ) ();

        return (() @trusted => cast(string)(demangle(deco))) ();
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Function)o;
        return c && this.deco == c.deco;
    }

    // BUG: need to add the rest of the functions

    override @property size_t tsize() nothrow pure const
    {
        return 0;       // no size for functions
    }

    override const(void)[] initializer() const @safe
    {
        return null;
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return rtinfoNoPointers; }

    TypeInfo next;

    /**
    * Mangled function type string
    */
    string deco;
}

@safe unittest
{
    abstract class C
    {
       void func();
       void func(int a);
       int func(int a, int b);
    }

    alias functionTypes = typeof(__traits(getVirtualFunctions, C, "func"));
    assert(typeid(functionTypes[0]).toString() == "void function()");
    assert(typeid(functionTypes[1]).toString() == "void function(int)");
    assert(typeid(functionTypes[2]).toString() == "int function(int, int)");
}

class TypeInfo_Delegate : TypeInfo
{
    override string toString() const
    {
        return cast(string)(next.toString() ~ " delegate()");
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Delegate)o;
        return c && this.deco == c.deco;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        return hashOf(*cast(void delegate()*)p);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        auto dg1 = *cast(void delegate()*)p1;
        auto dg2 = *cast(void delegate()*)p2;
        return dg1 == dg2;
    }

    override int compare(in void* p1, in void* p2) const
    {
        auto dg1 = *cast(void delegate()*)p1;
        auto dg2 = *cast(void delegate()*)p2;

        if (dg1 < dg2)
            return -1;
        else if (dg1 > dg2)
            return 1;
        else
            return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        alias dg = int delegate();
        return dg.sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (int delegate()).sizeof];
    }

    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo next;
    string deco;

    override @property size_t talign() nothrow pure const
    {
        alias dg = int delegate();
        return dg.alignof;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        arg2 = typeid(void*);
        return 0;
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return RTInfo!(int delegate()); }
}

/**
 * Runtime type information about a class.
 * Can be retrieved from an object instance by using the
 * $(DDSUBLINK spec/property,classinfo, .classinfo) property.
 */
class TypeInfo_Class : TypeInfo
{
    override string toString() const { return info.name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Class)o;
        return c && this.info.name == c.info.name;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        auto o = *cast(Object*)p;
        return o ? o.toHash() : 0;
    }

    override bool equals(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override int compare(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 !is o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const
    {
        return Object.sizeof;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return 1; }

    override @property const(OffsetTypeInfo)[] offTi() nothrow pure const
    {
        return m_offTi;
    }

    @property auto info() @safe nothrow pure const { return this; }
    @property auto typeinfo() @safe nothrow pure const { return this; }

    byte[]      m_init;         /** class static initializer
                                 * (init.length gives size in bytes of class)
                                 */
    string      name;           /// class name
    void*[]     vtbl;           /// virtual function pointer table
    Interface[] interfaces;     /// interfaces this class implements
    TypeInfo_Class   base;           /// base class
    void*       destructor;
    void function(Object) classInvariant;
    enum ClassFlags : uint
    {
        isCOMclass = 0x1,
        noPointers = 0x2,
        hasOffTi = 0x4,
        hasCtor = 0x8,
        hasGetMembers = 0x10,
        hasTypeInfo = 0x20,
        isAbstract = 0x40,
        isCPPclass = 0x80,
        hasDtor = 0x100,
    }
    ClassFlags m_flags;
    void*       deallocator;
    OffsetTypeInfo[] m_offTi;
    void function(Object) defaultConstructor;   // default Constructor

    immutable(void)* m_RTInfo;        // data for precise GC
    override @property immutable(void)* rtInfo() const { return m_RTInfo; }

    /**
     * Search all modules for TypeInfo_Class corresponding to classname.
     * Returns: null if not found
     */
    static const(TypeInfo_Class) find(in char[] classname)
    {
        foreach (m; ModuleInfo)
        {
            if (m)
            {
                //writefln("module %s, %d", m.name, m.localClasses.length);
                foreach (c; m.localClasses)
                {
                    if (c is null)
                        continue;
                    //writefln("\tclass %s", c.name);
                    if (c.name == classname)
                        return c;
                }
            }
        }
        return null;
    }

    /**
     * Create instance of Object represented by 'this'.
     */
    Object create() const
    {
        if (m_flags & 8 && !defaultConstructor)
            return null;
        if (m_flags & 64) // abstract
            return null;
        Object o = _d_newclass(this);
        if (m_flags & 8 && defaultConstructor)
        {
            defaultConstructor(o);
        }
        return o;
    }
}

alias ClassInfo = TypeInfo_Class;

@safe unittest
{
    // Bugzilla 14401
    static class X
    {
        int a;
    }

    assert(typeid(X).initializer is typeid(X).m_init);
    assert(typeid(X).initializer.length == typeid(const(X)).initializer.length);
    assert(typeid(X).initializer.length == typeid(shared(X)).initializer.length);
    assert(typeid(X).initializer.length == typeid(immutable(X)).initializer.length);
}

class TypeInfo_Interface : TypeInfo
{
    override string toString() const { return info.name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Interface)o;
        return c && this.info.name == typeid(c).name;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        if (!*cast(void**)p)
        {
            return 0;
        }
        Interface* pi = **cast(Interface ***)*cast(void**)p;
        Object o = cast(Object)(*cast(void**)p - pi.offset);
        assert(o);
        return o.toHash();
    }

    override bool equals(in void* p1, in void* p2) const
    {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);

        return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }

    override int compare(in void* p1, in void* p2) const
    {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 != o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const
    {
        return Object.sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. Object.sizeof];
    }

    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo_Class info;
}

class TypeInfo_Struct : TypeInfo
{
    override string toString() const { return name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto s = cast(const TypeInfo_Struct)o;
        return s && this.name == s.name &&
                    this.initializer().length == s.initializer().length;
    }

    override size_t getHash(scope const void* p) @trusted pure nothrow const
    {
        assert(p);
        if (xtoHash)
        {
            return (*xtoHash)(p);
        }
        else
        {
            return hashOf(p[0 .. initializer().length]);
        }
    }

    override bool equals(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        if (!p1 || !p2)
            return false;
        else if (xopEquals)
            return (*xopEquals)(p1, p2);
        else if (p1 == p2)
            return true;
        else
            // BUG: relies on the GC not moving objects
            return memcmp(p1, p2, initializer().length) == 0;
    }

    override int compare(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        // Regard null references as always being "less than"
        if (p1 != p2)
        {
            if (p1)
            {
                if (!p2)
                    return true;
                else if (xopCmp)
                    return (*xopCmp)(p2, p1);
                else
                    // BUG: relies on the GC not moving objects
                    return memcmp(p1, p2, initializer().length);
            }
            else
                return -1;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return initializer().length;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return m_flags; }

    override @property size_t talign() nothrow pure const { return m_align; }

    final override void destroy(void* p) const
    {
        if (xdtor)
        {
            if (m_flags & StructFlags.isDynamicType)
                (*xdtorti)(p, this);
            else
                (*xdtor)(p);
        }
    }

    override void postblit(void* p) const
    {
        if (xpostblit)
            (*xpostblit)(p);
    }

    string name;
    void[] m_init;      // initializer; m_init.ptr == null if 0 initialize

    @safe pure nothrow
    {
        size_t   function(in void*)           xtoHash;
        bool     function(in void*, in void*) xopEquals;
        int      function(in void*, in void*) xopCmp;
        string   function(in void*)           xtoString;

        enum StructFlags : uint
        {
            hasPointers = 0x1,
            isDynamicType = 0x2, // built at runtime, needs type info in xdtor
        }
        StructFlags m_flags;
    }
    union
    {
        void function(void*)                xdtor;
        void function(void*, const TypeInfo_Struct ti) xdtorti;
    }
    void function(void*)                    xpostblit;

    uint m_align;

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return m_RTInfo; }

    version (X86_64)
    {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = m_arg1;
            arg2 = m_arg2;
            return 0;
        }
        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }
    immutable(void)* m_RTInfo;                // data for precise GC
}

@system unittest
{
    struct S
    {
        bool opEquals(ref const S rhs) const
        {
            return false;
        }
    }
    S s;
    assert(!typeid(S).equals(&s, &s));
}

class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[] elements;

    override string toString() const
    {
        string s = "(";
        foreach (i, element; elements)
        {
            if (i)
                s ~= ',';
            s ~= element.toString();
        }
        s ~= ")";
        return s;
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;

        auto t = cast(const TypeInfo_Tuple)o;
        if (t && elements.length == t.elements.length)
        {
            for (size_t i = 0; i < elements.length; i++)
            {
                if (elements[i] != t.elements[i])
                    return false;
            }
            return true;
        }
        return false;
    }

    override size_t getHash(scope const void* p) const
    {
        assert(0);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        assert(0);
    }

    override int compare(in void* p1, in void* p2) const
    {
        assert(0);
    }

    override @property size_t tsize() nothrow pure const
    {
        assert(0);
    }

    override const(void)[] initializer() const @trusted
    {
        assert(0);
    }

    override void swap(void* p1, void* p2) const
    {
        assert(0);
    }

    override void destroy(void* p) const
    {
        assert(0);
    }

    override void postblit(void* p) const
    {
        assert(0);
    }

    override @property size_t talign() nothrow pure const
    {
        assert(0);
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        assert(0);
    }
}

class TypeInfo_Const : TypeInfo
{
    override string toString() const
    {
        return cast(string) ("const(" ~ base.toString() ~ ")");
    }

    //override bool opEquals(Object o) { return base.opEquals(o); }
    override bool opEquals(Object o)
    {
        if (this is o)
            return true;

        if (typeid(this) != typeid(o))
            return false;

        auto t = cast(TypeInfo_Const)o;
        return base.opEquals(t.base);
    }

    override size_t getHash(scope const void *p) const { return base.getHash(p); }
    override bool equals(in void *p1, in void *p2) const { return base.equals(p1, p2); }
    override int compare(in void *p1, in void *p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void *p1, void *p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return base.flags; }

    override const(void)[] initializer() nothrow pure const
    {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { return base.talign; }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
}

class TypeInfo_Invariant : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("immutable(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Shared : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("shared(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Inout : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("inout(" ~ base.toString() ~ ")");
    }
}

// Contents of Moduleinfo._flags
enum
{
    MIctorstart  = 0x1,   // we've started constructing it
    MIctordone   = 0x2,   // finished construction
    MIstandalone = 0x4,   // module ctor does not depend on other module
                        // ctors being done first
    MItlsctor    = 8,
    MItlsdtor    = 0x10,
    MIctor       = 0x20,
    MIdtor       = 0x40,
    MIxgetMembers = 0x80,
    MIictor      = 0x100,
    MIunitTest   = 0x200,
    MIimportedModules = 0x400,
    MIlocalClasses = 0x800,
    MIname       = 0x1000,
}

/*****************************************
 * An instance of ModuleInfo is generated into the object file for each compiled module.
 *
 * It provides access to various aspects of the module.
 * It is not generated for betterC.
 */
struct ModuleInfo
{
    uint _flags; // MIxxxx
    uint _index; // index into _moduleinfo_array[]

    version (all)
    {
        deprecated("ModuleInfo cannot be copy-assigned because it is a variable-sized struct.")
        void opAssign(in ModuleInfo m) { _flags = m._flags; _index = m._index; }
    }
    else
    {
        @disable this();
    }

const:
    private void* addrOf(int flag) nothrow pure @nogc
    in
    {
        assert(flag >= MItlsctor && flag <= MIname);
        assert(!(flag & (flag - 1)) && !(flag & ~(flag - 1) << 1));
    }
    do
    {
        import core.stdc.string : strlen;

        void* p = cast(void*)&this + ModuleInfo.sizeof;

        if (flags & MItlsctor)
        {
            if (flag == MItlsctor) return p;
            p += typeof(tlsctor).sizeof;
        }
        if (flags & MItlsdtor)
        {
            if (flag == MItlsdtor) return p;
            p += typeof(tlsdtor).sizeof;
        }
        if (flags & MIctor)
        {
            if (flag == MIctor) return p;
            p += typeof(ctor).sizeof;
        }
        if (flags & MIdtor)
        {
            if (flag == MIdtor) return p;
            p += typeof(dtor).sizeof;
        }
        if (flags & MIxgetMembers)
        {
            if (flag == MIxgetMembers) return p;
            p += typeof(xgetMembers).sizeof;
        }
        if (flags & MIictor)
        {
            if (flag == MIictor) return p;
            p += typeof(ictor).sizeof;
        }
        if (flags & MIunitTest)
        {
            if (flag == MIunitTest) return p;
            p += typeof(unitTest).sizeof;
        }
        if (flags & MIimportedModules)
        {
            if (flag == MIimportedModules) return p;
            p += size_t.sizeof + *cast(size_t*)p * typeof(importedModules[0]).sizeof;
        }
        if (flags & MIlocalClasses)
        {
            if (flag == MIlocalClasses) return p;
            p += size_t.sizeof + *cast(size_t*)p * typeof(localClasses[0]).sizeof;
        }
        if (true || flags & MIname) // always available for now
        {
            if (flag == MIname) return p;
            p += strlen(cast(immutable char*)p);
        }
        assert(0);
    }

    @property uint index() nothrow pure @nogc { return _index; }

    @property uint flags() nothrow pure @nogc { return _flags; }

    /************************
     * Returns:
     *  module constructor for thread locals, `null` if there isn't one
     */
    @property void function() tlsctor() nothrow pure @nogc
    {
        return flags & MItlsctor ? *cast(typeof(return)*)addrOf(MItlsctor) : null;
    }

    /************************
     * Returns:
     *  module destructor for thread locals, `null` if there isn't one
     */
    @property void function() tlsdtor() nothrow pure @nogc
    {
        return flags & MItlsdtor ? *cast(typeof(return)*)addrOf(MItlsdtor) : null;
    }

    /*****************************
     * Returns:
     *  address of a module's `const(MemberInfo)[] getMembers(string)` function, `null` if there isn't one
     */
    @property void* xgetMembers() nothrow pure @nogc
    {
        return flags & MIxgetMembers ? *cast(typeof(return)*)addrOf(MIxgetMembers) : null;
    }

    /************************
     * Returns:
     *  module constructor, `null` if there isn't one
     */
    @property void function() ctor() nothrow pure @nogc
    {
        return flags & MIctor ? *cast(typeof(return)*)addrOf(MIctor) : null;
    }

    /************************
     * Returns:
     *  module destructor, `null` if there isn't one
     */
    @property void function() dtor() nothrow pure @nogc
    {
        return flags & MIdtor ? *cast(typeof(return)*)addrOf(MIdtor) : null;
    }

    /************************
     * Returns:
     *  module order independent constructor, `null` if there isn't one
     */
    @property void function() ictor() nothrow pure @nogc
    {
        return flags & MIictor ? *cast(typeof(return)*)addrOf(MIictor) : null;
    }

    /*************
     * Returns:
     *  address of function that runs the module's unittests, `null` if there isn't one
     */
    @property void function() unitTest() nothrow pure @nogc
    {
        return flags & MIunitTest ? *cast(typeof(return)*)addrOf(MIunitTest) : null;
    }

    /****************
     * Returns:
     *  array of pointers to the ModuleInfo's of modules imported by this one
     */
    @property immutable(ModuleInfo*)[] importedModules() nothrow pure @nogc
    {
        if (flags & MIimportedModules)
        {
            auto p = cast(size_t*)addrOf(MIimportedModules);
            return (cast(immutable(ModuleInfo*)*)(p + 1))[0 .. *p];
        }
        return null;
    }

    /****************
     * Returns:
     *  array of TypeInfo_Class references for classes defined in this module
     */
    @property TypeInfo_Class[] localClasses() nothrow pure @nogc
    {
        if (flags & MIlocalClasses)
        {
            auto p = cast(size_t*)addrOf(MIlocalClasses);
            return (cast(TypeInfo_Class*)(p + 1))[0 .. *p];
        }
        return null;
    }

    /********************
     * Returns:
     *  name of module, `null` if no name
     */
    @property string name() nothrow pure @nogc
    {
        if (true || flags & MIname) // always available for now
        {
            import core.stdc.string : strlen;

            auto p = cast(immutable char*)addrOf(MIname);
            return p[0 .. strlen(p)];
        }
        // return null;
    }

    static int opApply(scope int delegate(ModuleInfo*) dg)
    {
        import core.internal.traits : externDFunc;
        alias moduleinfos_apply = externDFunc!("rt.minfo.moduleinfos_apply",
                                              int function(scope int delegate(immutable(ModuleInfo*))));
        // Bugzilla 13084 - enforcing immutable ModuleInfo would break client code
        return moduleinfos_apply(
            (immutable(ModuleInfo*)m) => dg(cast(ModuleInfo*)m));
    }
}

@system unittest
{
    ModuleInfo* m1;
    foreach (m; ModuleInfo)
    {
        m1 = m;
    }
}

///////////////////////////////////////////////////////////////////////////////
// Throwable
///////////////////////////////////////////////////////////////////////////////


/**
 * The base class of all thrown objects.
 *
 * All thrown objects must inherit from Throwable. Class $(D Exception), which
 * derives from this class, represents the category of thrown objects that are
 * safe to catch and handle. In principle, one should not catch Throwable
 * objects that are not derived from $(D Exception), as they represent
 * unrecoverable runtime errors. Certain runtime guarantees may fail to hold
 * when these errors are thrown, making it unsafe to continue execution after
 * catching them.
 */
class Throwable : Object
{
    interface TraceInfo
    {
        int opApply(scope int delegate(ref const(char[]))) const;
        int opApply(scope int delegate(ref size_t, ref const(char[]))) const;
        string toString() const;
    }

    string      msg;    /// A message describing the error.

    /**
     * The _file name of the D source code corresponding with
     * where the error was thrown from.
     */
    string      file;
    /**
     * The _line number of the D source code corresponding with
     * where the error was thrown from.
     */
    size_t      line;

    /**
     * The stack trace of where the error happened. This is an opaque object
     * that can either be converted to $(D string), or iterated over with $(D
     * foreach) to extract the items in the stack trace (as strings).
     */
    TraceInfo   info;

    /**
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    private Throwable   nextInChain;

    private uint _refcount;     // 0 : allocated by GC
                                // 1 : allocated by _d_newThrowable()
                                // 2.. : reference count + 1

    /**
     * Returns:
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    @property inout(Throwable) next() @safe inout return scope pure nothrow @nogc { return nextInChain; }

    /**
     * Replace next in chain with `tail`.
     * Use `chainTogether` instead if at all possible.
     */
    @property void next(Throwable tail) @safe scope pure nothrow @nogc
    {
        if (tail && tail._refcount)
            ++tail._refcount;           // increment the replacement *first*

        auto n = nextInChain;
        nextInChain = null;             // sever the tail before deleting it

        if (n && n._refcount)
            _d_delThrowable(n);         // now delete the old tail

        nextInChain = tail;             // and set the new tail
    }

    /**
     * Returns:
     *  mutable reference to the reference count, which is
     *  0 - allocated by the GC, 1 - allocated by _d_newThrowable(),
     *  and >=2 which is the reference count + 1
     */
    @system @nogc final pure nothrow ref uint refcount() return scope { return _refcount; }

    /**
     * Loop over the chain of Throwables.
     */
    int opApply(scope int delegate(Throwable) dg)
    {
        int result = 0;
        for (Throwable t = this; t; t = t.nextInChain)
        {
            result = dg(t);
            if (result)
                break;
        }
        return result;
    }

    /**
     * Append `e2` to chain of exceptions that starts with `e1`.
     * Params:
     *  e1 = start of chain (can be null)
     *  e2 = second part of chain (can be null)
     * Returns:
     *  Throwable that is at the start of the chain; null if both `e1` and `e2` are null
     */
    static @__future @system @nogc pure nothrow Throwable chainTogether(return scope Throwable e1, return scope Throwable e2)
    {
        if (e2 && e2.refcount())
            ++e2.refcount();
        if (!e1)
            return e2;
        if (!e2)
            return e1;
        for (auto e = e1; 1; e = e.nextInChain)
        {
            if (!e.nextInChain)
            {
                e.nextInChain = e2;
                break;
            }
        }
        return e1;
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain = null)
    {
        this.msg = msg;
        this.nextInChain = nextInChain;
        //this.info = _d_traceContext();
    }

    @nogc @safe pure nothrow this(string msg, string file, size_t line, Throwable nextInChain = null)
    {
        this(msg, nextInChain);
        this.file = file;
        this.line = line;
        //this.info = _d_traceContext();
    }

    @trusted nothrow ~this()
    {
        if (nextInChain && nextInChain._refcount)
            _d_delThrowable(nextInChain);
    }

    /**
     * Overrides $(D Object.toString) and returns the error message.
     * Internally this forwards to the $(D toString) overload that
     * takes a $(D_PARAM sink) delegate.
     */
    override string toString()
    {
        string s;
        toString((buf) { s ~= buf; });
        return s;
    }

    /**
     * The Throwable hierarchy uses a toString overload that takes a
     * $(D_PARAM _sink) delegate to avoid GC allocations, which cannot be
     * performed in certain error situations.  Override this $(D
     * toString) method to customize the error message.
     */
    void toString(scope void delegate(in char[]) sink) const
    {
        import core.internal.string : unsignedToTempString;

        char[20] tmpBuff = void;

        sink(typeid(this).name);
        sink("@"); sink(file);
        sink("("); sink(unsignedToTempString(line, tmpBuff, 10)); sink(")");

        if (msg.length)
        {
            sink(": "); sink(msg);
        }
        if (info)
        {
            try
            {
                sink("\n----------------");
                foreach (t; info)
                {
                    sink("\n"); sink(t);
                }
            }
            catch (Throwable)
            {
                // ignore more errors
            }
        }
    }

    /**
     * Get the message describing the error.
     * Base behavior is to return the `Throwable.msg` field.
     * Override to return some other error message.
     *
     * Returns:
     *  Error message
     */
    @__future const(char)[] message() const
    {
        return this.msg;
    }
}


/**
 * The base class of all errors that are safe to catch and handle.
 *
 * In principle, only thrown objects derived from this class are safe to catch
 * inside a $(D catch) block. Thrown objects not derived from Exception
 * represent runtime errors that should not be caught, as certain runtime
 * guarantees may not hold, making it unsafe to continue program execution.
 */
class Exception : Throwable
{

    /**
     * Creates a new instance of Exception. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}

///
@safe unittest
{
    bool gotCaught;
    try
    {
        throw new Exception("msg");
    }
    catch (Exception e)
    {
        gotCaught = true;
        assert(e.msg == "msg");
    }
    assert(gotCaught);
}

@system unittest
{
    {
        auto e = new Exception("msg");
        assert(e.file == __FILE__);
        assert(e.line == __LINE__ - 2);
        assert(e.nextInChain is null);
        assert(e.msg == "msg");
    }

    {
        auto e = new Exception("msg", new Exception("It's an Exception!"), "hello", 42);
        assert(e.file == "hello");
        assert(e.line == 42);
        assert(e.nextInChain !is null);
        assert(e.msg == "msg");
    }

    {
        auto e = new Exception("msg", "hello", 42, new Exception("It's an Exception!"));
        assert(e.file == "hello");
        assert(e.line == 42);
        assert(e.nextInChain !is null);
        assert(e.msg == "msg");
    }

    {
        auto e = new Exception("message");
        assert(e.message == "message");
    }
}


/**
 * The base class of all unrecoverable runtime errors.
 *
 * This represents the category of $(D Throwable) objects that are $(B not)
 * safe to catch and handle. In principle, one should not catch Error
 * objects, as they represent unrecoverable runtime errors.
 * Certain runtime guarantees may fail to hold when these errors are
 * thrown, making it unsafe to continue execution after catching them.
 */
class Error : Throwable
{
    /**
     * Creates a new instance of Error. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Error; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg, Throwable nextInChain = null)
    {
        super(msg, nextInChain);
        bypassedException = null;
    }

    @nogc @safe pure nothrow this(string msg, string file, size_t line, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
        bypassedException = null;
    }

    /** The first $(D Exception) which was bypassed when this Error was thrown,
    or $(D null) if no $(D Exception)s were pending. */
    Throwable   bypassedException;
}

///
@system unittest
{
    bool gotCaught;
    try
    {
        throw new Error("msg");
    }
    catch (Error e)
    {
        gotCaught = true;
        assert(e.msg == "msg");
    }
    assert(gotCaught);
}

@safe unittest
{
    {
        auto e = new Error("msg");
        assert(e.file is null);
        assert(e.line == 0);
        assert(e.nextInChain is null);
        assert(e.msg == "msg");
        assert(e.bypassedException is null);
    }

    {
        auto e = new Error("msg", new Exception("It's an Exception!"));
        assert(e.file is null);
        assert(e.line == 0);
        assert(e.nextInChain !is null);
        assert(e.msg == "msg");
        assert(e.bypassedException is null);
    }

    {
        auto e = new Error("msg", "hello", 42, new Exception("It's an Exception!"));
        assert(e.file == "hello");
        assert(e.line == 42);
        assert(e.nextInChain !is null);
        assert(e.msg == "msg");
        assert(e.bypassedException is null);
    }
}

/* Used in Exception Handling LSDA tables to 'wrap' C++ type info
 * so it can be distinguished from D TypeInfo
 */
class __cpp_type_info_ptr
{
    void* ptr;          // opaque pointer to C++ RTTI type info
}

extern (C)
{
    // from druntime/src/rt/aaA.d

    // size_t _aaLen(in void* p) pure nothrow @nogc;
    private void* _aaGetY(void** paa, const TypeInfo_AssociativeArray ti, in size_t valuesize, in void* pkey) pure nothrow;
    private void* _aaGetX(void** paa, const TypeInfo_AssociativeArray ti, in size_t valuesize, in void* pkey, out bool found) pure nothrow;
    // inout(void)* _aaGetRvalueX(inout void* p, in TypeInfo keyti, in size_t valuesize, in void* pkey);
    inout(void)[] _aaValues(inout void* p, in size_t keysize, in size_t valuesize, const TypeInfo tiValArray) pure nothrow;
    inout(void)[] _aaKeys(inout void* p, in size_t keysize, const TypeInfo tiKeyArray) pure nothrow;
    void* _aaRehash(void** pp, in TypeInfo keyti) pure nothrow;
    void _aaClear(void* p) pure nothrow;

    // alias _dg_t = extern(D) int delegate(void*);
    // int _aaApply(void* aa, size_t keysize, _dg_t dg);

    // alias _dg2_t = extern(D) int delegate(void*, void*);
    // int _aaApply2(void* aa, size_t keysize, _dg2_t dg);

    private struct AARange { void* impl; size_t idx; }
    AARange _aaRange(void* aa) pure nothrow @nogc @safe;
    bool _aaRangeEmpty(AARange r) pure nothrow @nogc @safe;
    void* _aaRangeFrontKey(AARange r) pure nothrow @nogc @safe;
    void* _aaRangeFrontValue(AARange r) pure nothrow @nogc @safe;
    void _aaRangePopFront(ref AARange r) pure nothrow @nogc @safe;

    int _aaEqual(in TypeInfo tiRaw, in void* e1, in void* e2);
    hash_t _aaGetHash(in void* aa, in TypeInfo tiRaw) nothrow;

    /*
        _d_assocarrayliteralTX marked as pure, because aaLiteral can be called from pure code.
        This is a typesystem hole, however this is existing hole.
        Early compiler didn't check purity of toHash or postblit functions, if key is a UDT thus
        copiler allowed to create AA literal with keys, which have impure unsafe toHash methods.
    */
    void* _d_assocarrayliteralTX(const TypeInfo_AssociativeArray ti, void[] keys, void[] values) pure;
}

void* aaLiteral(Key, Value)(Key[] keys, Value[] values) @trusted pure
{
    return _d_assocarrayliteralTX(typeid(Value[Key]), *cast(void[]*)&keys, *cast(void[]*)&values);
}

alias AssociativeArray(Key, Value) = Value[Key];

/***********************************
 * Removes all remaining keys and values from an associative array.
 * Params:
 *      aa =     The associative array.
 */
void clear(T : Value[Key], Value, Key)(T aa)
{
    _aaClear(*cast(void **) &aa);
}

/* ditto */
void clear(T : Value[Key], Value, Key)(T* aa)
{
    _aaClear(*cast(void **) aa);
}

///
@system unittest
{
    auto aa = ["k1": 2];
    aa.clear;
    assert("k1" !in aa);
}

/***********************************
 * Reorganizes the associative array in place so that lookups are more
 * efficient.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      The rehashed associative array.
 */
T rehash(T : Value[Key], Value, Key)(T aa)
{
    _aaRehash(cast(void**)&aa, typeid(Value[Key]));
    return aa;
}

/* ditto */
T rehash(T : Value[Key], Value, Key)(T* aa)
{
    _aaRehash(cast(void**)aa, typeid(Value[Key]));
    return *aa;
}

/* ditto */
T rehash(T : shared Value[Key], Value, Key)(T aa)
{
    _aaRehash(cast(void**)&aa, typeid(Value[Key]));
    return aa;
}

/* ditto */
T rehash(T : shared Value[Key], Value, Key)(T* aa)
{
    _aaRehash(cast(void**)aa, typeid(Value[Key]));
    return *aa;
}

/***********************************
 * Create a new associative array of the same size and copy the contents of the
 * associative array into it.
 * Params:
 *      aa =     The associative array.
 */
V[K] dup(T : V[K], K, V)(T aa)
{
    //pragma(msg, "K = ", K, ", V = ", V);

    // Bug10720 - check whether V is copyable
    static assert(is(typeof({ V v = aa[K.init]; })),
        "cannot call " ~ T.stringof ~ ".dup because " ~ V.stringof ~ " is not copyable");

    V[K] result;

    //foreach (k, ref v; aa)
    //    result[k] = v;  // Bug13701 - won't work if V is not mutable

    ref V duplicateElem(ref K k, ref const V v) @trusted pure nothrow
    {
        import core.stdc.string : memcpy;

        void* pv = _aaGetY(cast(void**)&result, typeid(V[K]), V.sizeof, &k);
        memcpy(pv, &v, V.sizeof);
        return *cast(V*)pv;
    }

    if (auto postblit = _getPostblit!V())
    {
        foreach (k, ref v; aa)
            postblit(duplicateElem(k, v));
    }
    else
    {
        foreach (k, ref v; aa)
            duplicateElem(k, v);
    }

    return result;
}

/* ditto */
V[K] dup(T : V[K], K, V)(T* aa)
{
    return (*aa).dup;
}

///
@safe unittest
{
    auto aa = ["k1": 2];
    auto a2 = aa.dup;
    aa["k2"] = 3;
    assert("k2" !in a2);
}

// this should never be made public.
private AARange _aaToRange(T: V[K], K, V)(ref T aa) pure nothrow @nogc @safe
{
    // ensure we are dealing with a genuine AA.
    static if (is(const(V[K]) == const(T)))
        alias realAA = aa;
    else
        const(V[K]) realAA = aa;
    return _aaRange(() @trusted { return cast(void*)realAA; } ());
}

/***********************************
 * Returns a forward range over the keys of the associative array.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      A forward range.
 */
auto byKey(T : V[K], K, V)(T aa) pure nothrow @nogc @safe
{
    import core.internal.traits : substInout;

    static struct Result
    {
        AARange r;

    pure nothrow @nogc:
        @property bool empty()  @safe { return _aaRangeEmpty(r); }
        @property ref front()
        {
            auto p = (() @trusted => cast(substInout!K*) _aaRangeFrontKey(r)) ();
            return *p;
        }
        void popFront() @safe { _aaRangePopFront(r); }
        @property Result save() { return this; }
    }

    return Result(_aaToRange(aa));
}

/* ditto */
auto byKey(T : V[K], K, V)(T* aa) pure nothrow @nogc
{
    return (*aa).byKey();
}

///
@safe unittest
{
    auto dict = [1: 0, 2: 0];
    int sum;
    foreach (v; dict.byKey)
        sum += v;

    assert(sum == 3);
}

/***********************************
 * Returns a forward range over the values of the associative array.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      A forward range.
 */
auto byValue(T : V[K], K, V)(T aa) pure nothrow @nogc @safe
{
    import core.internal.traits : substInout;

    static struct Result
    {
        AARange r;

    pure nothrow @nogc:
        @property bool empty() @safe { return _aaRangeEmpty(r); }
        @property ref front()
        {
            auto p = (() @trusted => cast(substInout!V*) _aaRangeFrontValue(r)) ();
            return *p;
        }
        void popFront() @safe { _aaRangePopFront(r); }
        @property Result save() { return this; }
    }

    return Result(_aaToRange(aa));
}

/* ditto */
auto byValue(T : V[K], K, V)(T* aa) pure nothrow @nogc
{
    return (*aa).byValue();
}

///
@safe unittest
{
    auto dict = ["k1": 1, "k2": 2];
    int sum;
    foreach (v; dict.byValue)
        sum += v;

    assert(sum == 3);
}

/***********************************
 * Returns a forward range over the key value pairs of the associative array.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      A forward range.
 */
auto byKeyValue(T : V[K], K, V)(T aa) pure nothrow @nogc @safe
{
    import core.internal.traits : substInout;

    static struct Result
    {
        AARange r;

    pure nothrow @nogc:
        @property bool empty() @safe { return _aaRangeEmpty(r); }
        @property auto front()
        {
            static struct Pair
            {
                // We save the pointers here so that the Pair we return
                // won't mutate when Result.popFront is called afterwards.
                private void* keyp;
                private void* valp;

                @property ref key() inout
                {
                    auto p = (() @trusted => cast(substInout!K*) keyp) ();
                    return *p;
                }
                @property ref value() inout
                {
                    auto p = (() @trusted => cast(substInout!V*) valp) ();
                    return *p;
                }
            }
            return Pair(_aaRangeFrontKey(r),
                        _aaRangeFrontValue(r));
        }
        void popFront() @safe { return _aaRangePopFront(r); }
        @property Result save() { return this; }
    }

    return Result(_aaToRange(aa));
}

/* ditto */
auto byKeyValue(T : V[K], K, V)(T* aa) pure nothrow @nogc
{
    return (*aa).byKeyValue();
}

///
@safe unittest
{
    auto dict = ["k1": 1, "k2": 2];
    int sum;
    foreach (e; dict.byKeyValue)
        sum += e.value;

    assert(sum == 3);
}

/***********************************
 * Returns a dynamic array, the elements of which are the keys in the
 * associative array.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      A dynamic array.
 */
Key[] keys(T : Value[Key], Value, Key)(T aa) @property
{
    auto a = cast(void[])_aaKeys(cast(inout(void)*)aa, Key.sizeof, typeid(Key[]));
    auto res = *cast(Key[]*)&a;
    _doPostblit(res);
    return res;
}

/* ditto */
Key[] keys(T : Value[Key], Value, Key)(T *aa) @property
{
    return (*aa).keys;
}

///
@system unittest
{
    auto aa = [1: "v1", 2: "v2"];
    int sum;
    foreach (k; aa.keys)
        sum += k;

    assert(sum == 3);
}

/***********************************
 * Returns a dynamic array, the elements of which are the values in the
 * associative array.
 * Params:
 *      aa =     The associative array.
 * Returns:
 *      A dynamic array.
 */
Value[] values(T : Value[Key], Value, Key)(T aa) @property
{
    auto a = cast(void[])_aaValues(cast(inout(void)*)aa, Key.sizeof, Value.sizeof, typeid(Value[]));
    auto res = *cast(Value[]*)&a;
    _doPostblit(res);
    return res;
}

/* ditto */
Value[] values(T : Value[Key], Value, Key)(T *aa) @property
{
    return (*aa).values;
}

///
@system unittest
{
    auto aa = ["k1": 1, "k2": 2];
    int sum;
    foreach (e; aa.values)
        sum += e;

    assert(sum == 3);
}

/***********************************
 * Looks up key; if it exists returns corresponding value else evaluates and
 * returns defaultValue.
 * Params:
 *      aa =     The associative array.
 *      key =    The key.
 *      defaultValue = The default value.
 * Returns:
 *      The value.
 */
inout(V) get(K, V)(inout(V[K]) aa, K key, lazy inout(V) defaultValue)
{
    auto p = key in aa;
    return p ? *p : defaultValue;
}

/* ditto */
inout(V) get(K, V)(inout(V[K])* aa, K key, lazy inout(V) defaultValue)
{
    return (*aa).get(key, defaultValue);
}

@safe unittest
{
    auto aa = ["k1": 1];
    assert(aa.get("k1", 0) == 1);
    assert(aa.get("k2", 0) == 0);
}

/***********************************
 * Looks up key; if it exists returns corresponding value else evaluates
 * value, adds it to the associative array and returns it.
 * Params:
 *      aa =     The associative array.
 *      key =    The key.
 *      value =  The required value.
 * Returns:
 *      The value.
 */
ref V require(K, V)(ref V[K] aa, K key, lazy V value = V.init)
{
    bool found;
    // if key is @safe-ly copyable, `require` can infer @safe
    static if (isSafeCopyable!K)
    {
        auto p = () @trusted
        {
            return cast(V*) _aaGetX(cast(void**) &aa, typeid(V[K]), V.sizeof, &key, found);
        } ();
    }
    else
    {
        auto p = cast(V*) _aaGetX(cast(void**) &aa, typeid(V[K]), V.sizeof, &key, found);
    }
    return found ? *p : (*p = value);
}

///
@safe unittest
{
    auto aa = ["k1": 1];
    assert(aa.require("k1", 0) == 1);
    assert(aa.require("k2", 0) == 0);
    assert(aa["k2"] == 0);
}

// Constraints for aa update. Delegates, Functions or Functors (classes that
// provide opCall) are allowed. See unittest for an example.
private
{
    template isCreateOperation(C, V)
    {
        static if (is(C : V delegate()) || is(C : V function()))
            enum bool isCreateOperation = true;
        else static if (isCreateOperation!(typeof(&C.opCall), V))
            enum bool isCreateOperation = true;
        else
            enum bool isCreateOperation = false;
    }

    template isUpdateOperation(U, V)
    {
        static if (is(U : V delegate(ref V)) || is(U : V function(ref V)))
            enum bool isUpdateOperation = true;
        else static if (isUpdateOperation!(typeof(&U.opCall), V))
            enum bool isUpdateOperation = true;
        else
            enum bool isUpdateOperation = false;
    }
}

// Tests whether T can be @safe-ly copied. Use a union to exclude destructor from the test.
private enum bool isSafeCopyable(T) = is(typeof(() @safe { union U { T x; } T *x; auto u = U(*x); }));

/***********************************
 * Looks up key; if it exists applies the update delegate else evaluates the
 * create delegate and adds it to the associative array
 * Params:
 *      aa =     The associative array.
 *      key =    The key.
 *      create = The delegate to apply on create.
 *      update = The delegate to apply on update.
 */
void update(K, V, C, U)(ref V[K] aa, K key, scope C create, scope U update)
if (isCreateOperation!(C, V) && isUpdateOperation!(U, V))
{
    bool found;
    // if key is @safe-ly copyable, `update` may infer @safe
    static if (isSafeCopyable!K)
    {
        auto p = () @trusted
        {
            return cast(V*) _aaGetX(cast(void**) &aa, typeid(V[K]), V.sizeof, &key, found);
        } ();
    }
    else
    {
        auto p = cast(V*) _aaGetX(cast(void**) &aa, typeid(V[K]), V.sizeof, &key, found);
    }
    if (!found)
        *p = create();
    else
        *p = update(*p);
}

///
@system unittest
{
    auto aa = ["k1": 1];

    aa.update("k1", {
        return -1; // create (won't be executed
    }, (ref int v) {
        return v + 1; // update
    });
    assert(aa["k1"] == 2);

    aa.update("k2", {
        return 0; // create
    }, (ref int v) {
        return -1; // update (won't be executed)
    });
    assert(aa["k2"] == 0);
}

@safe unittest
{
    static struct S
    {
        int x;
    @nogc nothrow pure:
        this(this) @system {}

    @safe const:
        // stubs
        bool opEquals(S rhs) { assert(0); }
        size_t toHash() { assert(0); }
    }

    int[string] aai;
    static assert(is(typeof(() @safe { aai.require("a", 1234); })));
    static assert(is(typeof(() @safe { aai.update("a", { return 1234; }, (ref int x) { x++; return x; }); })));

    S[string] aas;
    static assert(is(typeof(() { aas.require("a", S(1234)); })));
    static assert(is(typeof(() { aas.update("a", { return S(1234); }, (ref S s) { s.x++; return s; }); })));
    static assert(!is(typeof(() @safe { aas.update("a", { return S(1234); }, (ref S s) { s.x++; return s; }); })));

    int[S] aais;
    static assert(is(typeof(() { aais.require(S(1234), 1234); })));
    static assert(is(typeof(() { aais.update(S(1234), { return 1234; }, (ref int x) { x++; return x; }); })));
    static assert(!is(typeof(() @safe { aais.require(S(1234), 1234); })));
    static assert(!is(typeof(() @safe { aais.update(S(1234), { return 1234; }, (ref int x) { x++; return x; }); })));
}

private void _destructRecurse(E, size_t n)(ref E[n] arr)
{
    import core.internal.traits : hasElaborateDestructor;

    static if (hasElaborateDestructor!E)
    {
        foreach_reverse (ref elem; arr)
            _destructRecurse(elem);
    }
}

// Public and explicitly undocumented
void _postblitRecurse(S)(ref S s)
    if (is(S == struct))
{
    static if (__traits(hasMember, S, "__xpostblit") &&
               // Bugzilla 14746: Check that it's the exact member of S.
               __traits(isSame, S, __traits(parent, s.__xpostblit)))
        s.__xpostblit();
}

// Ditto
void _postblitRecurse(E, size_t n)(ref E[n] arr)
{
    import core.internal.traits : hasElaborateCopyConstructor;

    static if (hasElaborateCopyConstructor!E)
    {
        size_t i;
        scope(failure)
        {
            for (; i != 0; --i)
            {
                _destructRecurse(arr[i - 1]); // What to do if this throws?
            }
        }

        for (i = 0; i < arr.length; ++i)
            _postblitRecurse(arr[i]);
    }
}

// Test destruction/postblit order
@safe nothrow pure unittest
{
    string[] order;

    struct InnerTop
    {
        ~this() @safe nothrow pure
        {
            order ~= "destroy inner top";
        }

        this(this) @safe nothrow pure
        {
            order ~= "copy inner top";
        }
    }

    struct InnerMiddle {}

    version (none) // https://issues.dlang.org/show_bug.cgi?id=14242
    struct InnerElement
    {
        static char counter = '1';

        ~this() @safe nothrow pure
        {
            order ~= "destroy inner element #" ~ counter++;
        }

        this(this) @safe nothrow pure
        {
            order ~= "copy inner element #" ~ counter++;
        }
    }

    struct InnerBottom
    {
        ~this() @safe nothrow pure
        {
            order ~= "destroy inner bottom";
        }

        this(this) @safe nothrow pure
        {
            order ~= "copy inner bottom";
        }
    }

    struct S
    {
        char[] s;
        InnerTop top;
        InnerMiddle middle;
        version (none) InnerElement[3] array; // https://issues.dlang.org/show_bug.cgi?id=14242
        int a;
        InnerBottom bottom;
        ~this() @safe nothrow pure { order ~= "destroy outer"; }
        this(this) @safe nothrow pure { order ~= "copy outer"; }
    }

    string[] destructRecurseOrder;
    {
        S s;
        _destructRecurse(s);
        destructRecurseOrder = order;
        order = null;
    }

    assert(order.length);
    assert(destructRecurseOrder == order);
    order = null;

    S s;
    _postblitRecurse(s);
    assert(order.length);
    auto postblitRecurseOrder = order;
    order = null;
    S s2 = s;
    assert(order.length);
    assert(postblitRecurseOrder == order);
}

// Test static struct
nothrow @safe @nogc unittest
{
    static int i = 0;
    static struct S { ~this() nothrow @safe @nogc { i = 42; } }
    S s;
    _destructRecurse(s);
    assert(i == 42);
}

@safe unittest
{
    // Bugzilla 14746
    static struct HasDtor
    {
        ~this() { assert(0); }
    }
    static struct Owner
    {
        HasDtor* ptr;
        alias ptr this;
    }

    Owner o;
    assert(o.ptr is null);
    destroy(o);     // must not reach in HasDtor.__dtor()
}

@safe unittest
{
    // Bugzilla 14746
    static struct HasPostblit
    {
        this(this) { assert(0); }
    }
    static struct Owner
    {
        HasPostblit* ptr;
        alias ptr this;
    }

    Owner o;
    assert(o.ptr is null);
    _postblitRecurse(o);     // must not reach in HasPostblit.__postblit()
}

// Test handling of fixed-length arrays
// Separate from first test because of https://issues.dlang.org/show_bug.cgi?id=14242
@safe unittest
{
    string[] order;

    struct S
    {
        char id;

        this(this)
        {
            order ~= "copy #" ~ id;
        }

        ~this()
        {
            order ~= "destroy #" ~ id;
        }
    }

    string[] destructRecurseOrder;
    {
        S[3] arr = [S('1'), S('2'), S('3')];
        _destructRecurse(arr);
        destructRecurseOrder = order;
        order = null;
    }
    assert(order.length);
    assert(destructRecurseOrder == order);
    order = null;

    S[3] arr = [S('1'), S('2'), S('3')];
    _postblitRecurse(arr);
    assert(order.length);
    auto postblitRecurseOrder = order;
    order = null;

    auto arrCopy = arr;
    assert(order.length);
    assert(postblitRecurseOrder == order);
}

// Test handling of failed postblit
// Not nothrow or @safe because of https://issues.dlang.org/show_bug.cgi?id=14242
/+ nothrow @safe +/ unittest
{
    static class FailedPostblitException : Exception { this() nothrow @safe { super(null); } }
    static string[] order;
    static struct Inner
    {
        char id;

        @safe:
        this(this)
        {
            order ~= "copy inner #" ~ id;
            if (id == '2')
                throw new FailedPostblitException();
        }

        ~this() nothrow
        {
            order ~= "destroy inner #" ~ id;
        }
    }

    static struct Outer
    {
        Inner inner1, inner2, inner3;

        nothrow @safe:
        this(char first, char second, char third)
        {
            inner1 = Inner(first);
            inner2 = Inner(second);
            inner3 = Inner(third);
        }

        this(this)
        {
            order ~= "copy outer";
        }

        ~this()
        {
            order ~= "destroy outer";
        }
    }

    auto outer = Outer('1', '2', '3');

    try _postblitRecurse(outer);
    catch (FailedPostblitException) {}
    catch (Exception) assert(false);

    auto postblitRecurseOrder = order;
    order = null;

    try auto copy = outer;
    catch (FailedPostblitException) {}
    catch (Exception) assert(false);

    assert(postblitRecurseOrder == order);
    order = null;

    Outer[3] arr = [Outer('1', '1', '1'), Outer('1', '2', '3'), Outer('3', '3', '3')];

    try _postblitRecurse(arr);
    catch (FailedPostblitException) {}
    catch (Exception) assert(false);

    postblitRecurseOrder = order;
    order = null;

    try auto arrCopy = arr;
    catch (FailedPostblitException) {}
    catch (Exception) assert(false);

    assert(postblitRecurseOrder == order);
}

private
{
    extern (C) void _d_arrayshrinkfit(const TypeInfo ti, void[] arr) nothrow;
    extern (C) size_t _d_arraysetcapacity(const TypeInfo ti, size_t newcapacity, void[]* arrptr) pure nothrow;
}

/**
 * (Property) Gets the current _capacity of a slice. The _capacity is the size
 * that the slice can grow to before the underlying array must be
 * reallocated or extended.
 *
 * If an append must reallocate a slice with no possibility of extension, then
 * `0` is returned. This happens when the slice references a static array, or
 * if another slice references elements past the end of the current slice.
 *
 * Note: The _capacity of a slice may be impacted by operations on other slices.
 */
@property size_t capacity(T)(T[] arr) pure nothrow @trusted
{
    return _d_arraysetcapacity(typeid(T[]), 0, cast(void[]*)&arr);
}

///
@safe unittest
{
    //Static array slice: no capacity
    int[4] sarray = [1, 2, 3, 4];
    int[]  slice  = sarray[];
    assert(sarray.capacity == 0);
    //Appending to slice will reallocate to a new array
    slice ~= 5;
    assert(slice.capacity >= 5);

    //Dynamic array slices
    int[] a = [1, 2, 3, 4];
    int[] b = a[1 .. $];
    int[] c = a[1 .. $ - 1];
    debug(SENTINEL) {} else // non-zero capacity very much depends on the array and GC implementation
    {
        assert(a.capacity != 0);
        assert(a.capacity == b.capacity + 1); //both a and b share the same tail
    }
    assert(c.capacity == 0);              //an append to c must relocate c.
}

/**
 * Reserves capacity for a slice. The capacity is the size
 * that the slice can grow to before the underlying array must be
 * reallocated or extended.
 *
 * Returns: The new capacity of the array (which may be larger than
 * the requested capacity).
 */
size_t reserve(T)(ref T[] arr, size_t newcapacity) pure nothrow @trusted
{
    return _d_arraysetcapacity(typeid(T[]), newcapacity, cast(void[]*)&arr);
}

///
@safe unittest
{
    //Static array slice: no capacity. Reserve relocates.
    int[4] sarray = [1, 2, 3, 4];
    int[]  slice  = sarray[];
    auto u = slice.reserve(8);
    assert(u >= 8);
    assert(&sarray[0] !is &slice[0]);
    assert(slice.capacity == u);

    //Dynamic array slices
    int[] a = [1, 2, 3, 4];
    a.reserve(8); //prepare a for appending 4 more items
    auto p = &a[0];
    u = a.capacity;
    a ~= [5, 6, 7, 8];
    assert(p == &a[0]);      //a should not have been reallocated
    assert(u == a.capacity); //a should not have been extended
}

// Issue 6646: should be possible to use array.reserve from SafeD.
@safe unittest
{
    int[] a;
    a.reserve(10);
}

/**
 * Assume that it is safe to append to this array. Appends made to this array
 * after calling this function may append in place, even if the array was a
 * slice of a larger array to begin with.
 *
 * Use this only when it is certain there are no elements in use beyond the
 * array in the memory block.  If there are, those elements will be
 * overwritten by appending to this array.
 *
 * Warning: Calling this function, and then using references to data located after the
 * given array results in undefined behavior.
 *
 * Returns:
 *   The input is returned.
 */
auto ref inout(T[]) assumeSafeAppend(T)(auto ref inout(T[]) arr) nothrow @system
{
    _d_arrayshrinkfit(typeid(T[]), *(cast(void[]*)&arr));
    return arr;
}

///
@system unittest
{
    int[] a = [1, 2, 3, 4];

    // Without assumeSafeAppend. Appending relocates.
    int[] b = a [0 .. 3];
    b ~= 5;
    assert(a.ptr != b.ptr);

    debug(SENTINEL) {} else
    {
        // With assumeSafeAppend. Appending overwrites.
        int[] c = a [0 .. 3];
        c.assumeSafeAppend() ~= 5;
        assert(a.ptr == c.ptr);
    }
}

@system unittest
{
    int[] arr;
    auto newcap = arr.reserve(2000);
    assert(newcap >= 2000);
    assert(newcap == arr.capacity);
    auto ptr = arr.ptr;
    foreach (i; 0..2000)
        arr ~= i;
    assert(ptr == arr.ptr);
    arr = arr[0..1];
    arr.assumeSafeAppend();
    arr ~= 5;
    assert(ptr == arr.ptr);
}

@system unittest
{
    int[] arr = [1, 2, 3];
    void foo(ref int[] i)
    {
        i ~= 5;
    }
    arr = arr[0 .. 2];
    foo(assumeSafeAppend(arr)); //pass by ref
    assert(arr[]==[1, 2, 5]);
    arr = arr[0 .. 1].assumeSafeAppend(); //pass by value
}

// https://issues.dlang.org/show_bug.cgi?id=10574
@system unittest
{
    int[] a;
    immutable(int[]) b;
    auto a2 = &assumeSafeAppend(a);
    auto b2 = &assumeSafeAppend(b);
    auto a3 = assumeSafeAppend(a[]);
    auto b3 = assumeSafeAppend(b[]);
    assert(is(typeof(*a2) == int[]));
    assert(is(typeof(*b2) == immutable(int[])));
    assert(is(typeof(a3) == int[]));
    assert(is(typeof(b3) == immutable(int[])));
}

version (none)
{
    // enforce() copied from Phobos std.contracts for destroy(), left out until
    // we decide whether to use it.


    T _enforce(T, string file = __FILE__, int line = __LINE__)
        (T value, lazy const(char)[] msg = null)
    {
        if (!value) bailOut(file, line, msg);
        return value;
    }

    T _enforce(T, string file = __FILE__, int line = __LINE__)
        (T value, scope void delegate() dg)
    {
        if (!value) dg();
        return value;
    }

    T _enforce(T)(T value, lazy Exception ex)
    {
        if (!value) throw ex();
        return value;
    }

    private void _bailOut(string file, int line, in char[] msg)
    {
        char[21] buf = void;
        throw new Exception(cast(string)(file ~ "(" ~ ulongToString(buf[], line) ~ "): " ~ (msg ? msg : "Enforcement failed")));
    }
}

version (D_Ddoc)
{
    // This lets DDoc produce better documentation.

    /**
    Calculates the hash value of `arg` with an optional `seed` initial value.
    The result might not be equal to `typeid(T).getHash(&arg)`.

    Params:
        arg = argument to calculate the hash value of
        seed = optional `seed` value (may be used for hash chaining)

    Return: calculated hash value of `arg`
    */
    size_t hashOf(T)(auto ref T arg, size_t seed)
    {
        static import core.internal.hash;
        return core.internal.hash.hashOf(arg, seed);
    }
    /// ditto
    size_t hashOf(T)(auto ref T arg)
    {
        static import core.internal.hash;
        return core.internal.hash.hashOf(arg);
    }

    @safe unittest
    {
        auto h1 = "my.string".hashOf;
        assert(h1 == "my.string".hashOf);
    }
}
else
{
    public import core.internal.hash : hashOf;
}

///
@system unittest
{
    class MyObject
    {
        size_t myMegaHash() const @safe pure nothrow
        {
            return 42;
        }
    }
    struct Test
    {
        int a;
        string b;
        MyObject c;
        size_t toHash() const pure nothrow
        {
            size_t hash = a.hashOf();
            hash = b.hashOf(hash);
            size_t h1 = c.myMegaHash();
            hash = h1.hashOf(hash); //Mix two hash values
            return hash;
        }
    }
}

bool _xopEquals(in void*, in void*)
{
    throw new Error("TypeInfo.equals is not implemented");
}

bool _xopCmp(in void*, in void*)
{
    throw new Error("TypeInfo.compare is not implemented");
}

void __ctfeWrite(scope const(char)[] s) @nogc @safe pure nothrow {}

/******************************************
 * Create RTInfo for type T
 */

template RTInfoImpl(size_t[] pointers)
{
    immutable size_t[pointers.length] data = pointers[];
    immutable RTInfoImpl = data.ptr;
}

template RTInfo(T)
{
    enum RTInfo = RTInfoImpl!(__traits(getPointerBitmap, T));
}

/**
* shortcuts for the precise GC, also generated by the compiler
* used instead of the actual pointer bitmap
*/
enum immutable(void)* rtinfoNoPointers  = null;
enum immutable(void)* rtinfoHasPointers = cast(void*)1;

// Compiler hook into the runtime implementation of array (vector) operations.
template _arrayOp(Args...)
{
    import core.internal.arrayop;
    alias _arrayOp = arrayOp!Args;
}

/*
 * Support for switch statements switching on strings.
 * Params:
 *      caseLabels = sorted array of strings generated by compiler. Note the
                   strings are sorted by length first, and then lexicographically.
 *      condition = string to look up in table
 * Returns:
 *      index of match in caseLabels, a negative integer if not found
*/
int __switch(T, caseLabels...)(/*in*/ const scope T[] condition) pure nothrow @safe @nogc
{
    // This closes recursion for other cases.
    static if (caseLabels.length == 0)
    {
        return int.min;
    }
    else static if (caseLabels.length == 1)
    {
        return __cmp(condition, caseLabels[0]) == 0 ? 0 : int.min;
    }
    // To be adjusted after measurements
    // Compile-time inlined binary search.
    else static if (caseLabels.length < 7)
    {
        int r = void;
        enum mid = cast(int)caseLabels.length / 2;
        if (condition.length == caseLabels[mid].length)
        {
            r = __cmp(condition, caseLabels[mid]);
            if (r == 0) return mid;
        }
        else
        {
            // Equivalent to (but faster than) condition.length > caseLabels[$ / 2].length ? 1 : -1
            r = ((condition.length > caseLabels[mid].length) << 1) - 1;
        }

        if (r < 0)
        {
            // Search the left side
            return __switch!(T, caseLabels[0 .. mid])(condition);
        }
        else
        {
            // Search the right side
            return __switch!(T, caseLabels[mid + 1 .. $])(condition) + mid + 1;
        }
    }
    else
    {
        // Need immutable array to be accessible in pure code, but case labels are
        // currently coerced to the switch condition type (e.g. const(char)[]).
        static immutable T[][caseLabels.length] cases = {
            auto res = new immutable(T)[][](caseLabels.length);
            foreach (i, s; caseLabels)
                res[i] = s.idup;
            return res;
        }();

        // Run-time binary search in a static array of labels.
        return __switchSearch!T(cases[], condition);
    }
}

// binary search in sorted string cases, also see `__switch`.
private int __switchSearch(T)(/*in*/ const scope T[][] cases, /*in*/ const scope T[] condition) pure nothrow @safe @nogc
{
    size_t low = 0;
    size_t high = cases.length;

    do
    {
        auto mid = (low + high) / 2;
        int r = void;
        if (condition.length == cases[mid].length)
        {
            r = __cmp(condition, cases[mid]);
            if (r == 0) return cast(int) mid;
        }
        else
        {
            // Generates better code than "expr ? 1 : -1" on dmd and gdc, same with ldc
            r = ((condition.length > cases[mid].length) << 1) - 1;
        }

        if (r > 0) low = mid + 1;
        else high = mid;
    }
    while (low < high);

    // Not found
    return -1;
}

@system unittest
{
    static void testSwitch(T)()
    {
        switch (cast(T[]) "c")
        {
             case "coo":
             default:
                 break;
        }

        static int bug5381(immutable(T)[] s)
        {
            switch (s)
            {
                case "unittest":        return 1;
                case "D_Version2":      return 2;
                case "nonenone":        return 3;
                case "none":            return 4;
                case "all":             return 5;
                default:                return 6;
            }
        }

        int rc = bug5381("unittest");
        assert(rc == 1);

        rc = bug5381("D_Version2");
        assert(rc == 2);

        rc = bug5381("nonenone");
        assert(rc == 3);

        rc = bug5381("none");
        assert(rc == 4);

        rc = bug5381("all");
        assert(rc == 5);

        rc = bug5381("nonerandom");
        assert(rc == 6);

        static int binarySearch(immutable(T)[] s)
        {
            switch (s)
            {
                static foreach (i; 0 .. 16)
                case i.stringof: return i;
                default: return -1;
            }
        }
        static foreach (i; 0 .. 16)
            assert(binarySearch(i.stringof) == i);
        assert(binarySearch("") == -1);
        assert(binarySearch("sth.") == -1);
        assert(binarySearch(null) == -1);

        static int bug16739(immutable(T)[] s)
        {
            switch (s)
            {
                case "\u0100": return 1;
                case "a": return 2;
                default: return 3;
            }
        }
        assert(bug16739("\u0100") == 1);
        assert(bug16739("a") == 2);
        assert(bug16739("foo") == 3);
    }
    testSwitch!char;
    testSwitch!wchar;
    testSwitch!dchar;
}

// Compiler lowers final switch default case to this (which is a runtime error)
// Old implementation is in core/exception.d
void __switch_error()(string file = __FILE__, size_t line = __LINE__)
{
    import core.exception : __switch_errorT;
    __switch_errorT(file, line);
}

// Helper functions

private inout(TypeInfo) getElement(inout TypeInfo value) @trusted pure nothrow
{
    TypeInfo element = cast() value;
    for (;;)
    {
        if (auto qualified = cast(TypeInfo_Const) element)
            element = qualified.base;
        else if (auto redefined = cast(TypeInfo_Enum) element)
            element = redefined.base;
        else if (auto staticArray = cast(TypeInfo_StaticArray) element)
            element = staticArray.value;
        else if (auto vector = cast(TypeInfo_Vector) element)
            element = vector.base;
        else
            break;
    }
    return cast(inout) element;
}

private size_t getArrayHash(in TypeInfo element, in void* ptr, in size_t count) @trusted nothrow
{
    if (!count)
        return 0;

    const size_t elementSize = element.tsize;
    if (!elementSize)
        return 0;

    static bool hasCustomToHash(in TypeInfo value) @trusted pure nothrow
    {
        const element = getElement(value);

        if (const struct_ = cast(const TypeInfo_Struct) element)
            return !!struct_.xtoHash;

        return cast(const TypeInfo_Array) element
            || cast(const TypeInfo_AssociativeArray) element
            || cast(const ClassInfo) element
            || cast(const TypeInfo_Interface) element;
    }

    import core.internal.traits : externDFunc;
    if (!hasCustomToHash(element))
        return hashOf(ptr[0 .. elementSize * count]);

    size_t hash = 0;
    foreach (size_t i; 0 .. count)
        hash = hashOf(element.getHash(ptr + i * elementSize), hash);
    return hash;
}

/// Provide the .dup array property.
@property auto dup(T)(T[] a)
    if (!is(const(T) : T))
{
    import core.internal.traits : Unconst;
    static assert(is(T : Unconst!T), "Cannot implicitly convert type "~T.stringof~
                  " to "~Unconst!T.stringof~" in dup.");

    // wrap unsafe _dup in @trusted to preserve @safe postblit
    static if (__traits(compiles, (T b) @safe { T a = b; }))
        return _trustedDup!(T, Unconst!T)(a);
    else
        return _dup!(T, Unconst!T)(a);
}

///
@safe unittest
{
    auto arr = [1, 2];
    auto arr2 = arr.dup;
    arr[0] = 0;
    assert(arr == [0, 2]);
    assert(arr2 == [1, 2]);
}

/// ditto
// const overload to support implicit conversion to immutable (unique result, see DIP29)
@property T[] dup(T)(const(T)[] a)
    if (is(const(T) : T))
{
    // wrap unsafe _dup in @trusted to preserve @safe postblit
    static if (__traits(compiles, (T b) @safe { T a = b; }))
        return _trustedDup!(const(T), T)(a);
    else
        return _dup!(const(T), T)(a);
}


/// Provide the .idup array property.
@property immutable(T)[] idup(T)(T[] a)
{
    static assert(is(T : immutable(T)), "Cannot implicitly convert type "~T.stringof~
                  " to immutable in idup.");

    // wrap unsafe _dup in @trusted to preserve @safe postblit
    static if (__traits(compiles, (T b) @safe { T a = b; }))
        return _trustedDup!(T, immutable(T))(a);
    else
        return _dup!(T, immutable(T))(a);
}

/// ditto
@property immutable(T)[] idup(T:void)(const(T)[] a)
{
    return a.dup;
}

///
@safe unittest
{
    char[] arr = ['a', 'b', 'c'];
    string s = arr.idup;
    arr[0] = '.';
    assert(s == "abc");
}

private U[] _trustedDup(T, U)(T[] a) @trusted
{
    return _dup!(T, U)(a);
}

private U[] _dup(T, U)(T[] a) // pure nothrow depends on postblit
{
    if (__ctfe)
    {
        static if (is(T : void))
            assert(0, "Cannot dup a void[] array at compile time.");
        else
        {
            U[] res;
            foreach (ref e; a)
                res ~= e;
            return res;
        }
    }

    import core.stdc.string : memcpy;

    void[] arr = _d_newarrayU(typeid(T[]), a.length);
    memcpy(arr.ptr, cast(const(void)*)a.ptr, T.sizeof * a.length);
    auto res = *cast(U[]*)&arr;

    static if (!is(T : void))
        _doPostblit(res);
    return res;
}

private extern (C) void[] _d_newarrayU(const TypeInfo ti, size_t length) pure nothrow;


/**************
 * Get the postblit for type T.
 * Returns:
 *      null if no postblit is necessary
 *      function pointer for struct postblits
 *      delegate for class postblits
 */
private auto _getPostblit(T)() @trusted pure nothrow @nogc
{
    // infer static postblit type, run postblit if any
    static if (is(T == struct))
    {
        import core.internal.traits : Unqual;
        // use typeid(Unqual!T) here to skip TypeInfo_Const/Shared/...
        alias _PostBlitType = typeof(function (ref T t){ T a = t; });
        return cast(_PostBlitType)typeid(Unqual!T).xpostblit;
    }
    else if ((&typeid(T).postblit).funcptr !is &TypeInfo.postblit)
    {
        alias _PostBlitType = typeof(delegate (ref T t){ T a = t; });
        return cast(_PostBlitType)&typeid(T).postblit;
    }
    else
        return null;
}

private void _doPostblit(T)(T[] arr)
{
    // infer static postblit type, run postblit if any
    if (auto postblit = _getPostblit!T())
    {
        foreach (ref elem; arr)
            postblit(elem);
    }
}

@safe unittest
{
    static struct S1 { int* p; }
    static struct S2 { @disable this(); }
    static struct S3 { @disable this(this); }

    int dg1() pure nothrow @safe
    {
        {
           char[] m;
           string i;
           m = m.dup;
           i = i.idup;
           m = i.dup;
           i = m.idup;
        }
        {
           S1[] m;
           immutable(S1)[] i;
           m = m.dup;
           i = i.idup;
           static assert(!is(typeof(m.idup)));
           static assert(!is(typeof(i.dup)));
        }
        {
            S3[] m;
            immutable(S3)[] i;
            static assert(!is(typeof(m.dup)));
            static assert(!is(typeof(i.idup)));
        }
        {
            shared(S1)[] m;
            m = m.dup;
            static assert(!is(typeof(m.idup)));
        }
        {
            int[] a = (inout(int)) { inout(const(int))[] a; return a.dup; }(0);
        }
        return 1;
    }

    int dg2() pure nothrow @safe
    {
        {
           S2[] m = [S2.init, S2.init];
           immutable(S2)[] i = [S2.init, S2.init];
           m = m.dup;
           m = i.dup;
           i = m.idup;
           i = i.idup;
        }
        return 2;
    }

    enum a = dg1();
    enum b = dg2();
    assert(dg1() == a);
    assert(dg2() == b);
}

@system unittest
{
    static struct Sunpure { this(this) @safe nothrow {} }
    static struct Sthrow { this(this) @safe pure {} }
    static struct Sunsafe { this(this) @system pure nothrow {} }

    static assert( __traits(compiles, ()         { [].dup!Sunpure; }));
    static assert(!__traits(compiles, () pure    { [].dup!Sunpure; }));
    static assert( __traits(compiles, ()         { [].dup!Sthrow; }));
    static assert(!__traits(compiles, () nothrow { [].dup!Sthrow; }));
    static assert( __traits(compiles, ()         { [].dup!Sunsafe; }));
    static assert(!__traits(compiles, () @safe   { [].dup!Sunsafe; }));

    static assert( __traits(compiles, ()         { [].idup!Sunpure; }));
    static assert(!__traits(compiles, () pure    { [].idup!Sunpure; }));
    static assert( __traits(compiles, ()         { [].idup!Sthrow; }));
    static assert(!__traits(compiles, () nothrow { [].idup!Sthrow; }));
    static assert( __traits(compiles, ()         { [].idup!Sunsafe; }));
    static assert(!__traits(compiles, () @safe   { [].idup!Sunsafe; }));
}

@safe unittest
{
    static int*[] pureFoo() pure { return null; }
    { char[] s; immutable x = s.dup; }
    { immutable x = (cast(int*[])null).dup; }
    { immutable x = pureFoo(); }
    { immutable x = pureFoo().dup; }
}

@safe unittest
{
    auto a = [1, 2, 3];
    auto b = a.dup;
    debug(SENTINEL) {} else
        assert(b.capacity >= 3);
}

@system unittest
{
    // Bugzilla 12580
    void[] m = [0];
    shared(void)[] s = [cast(shared)1];
    immutable(void)[] i = [cast(immutable)2];

    s = s.dup;
    static assert(is(typeof(s.dup) == shared(void)[]));

    m = i.dup;
    i = m.dup;
    i = i.idup;
    i = m.idup;
    i = s.idup;
    i = s.dup;
    static assert(!__traits(compiles, m = s.dup));
}

@safe unittest
{
    // Bugzilla 13809
    static struct S
    {
        this(this) {}
        ~this() {}
    }

    S[] arr;
    auto a = arr.dup;
}

@system unittest
{
    // Bugzilla 16504
    static struct S
    {
        __gshared int* gp;
        int* p;
        // postblit and hence .dup could escape
        this(this) { gp = p; }
    }

    int p;
    scope S[1] arr = [S(&p)];
    auto a = arr.dup; // dup does escape
}

// compiler frontend lowers dynamic array comparison to this
bool __ArrayEq(T1, T2)(T1[] a, T2[] b)
{
    if (a.length != b.length)
        return false;
    foreach (size_t i; 0 .. a.length)
    {
        if (a[i] != b[i])
            return false;
    }
    return true;
}

// compiler frontend lowers struct array postblitting to this
void __ArrayPostblit(T)(T[] a)
{
    foreach (ref T e; a)
        e.__xpostblit();
}

// compiler frontend lowers dynamic array deconstruction to this
void __ArrayDtor(T)(T[] a)
{
    foreach_reverse (ref T e; a)
        e.__xdtor();
}

/**
Used by `__ArrayCast` to emit a descriptive error message.

It is a template so it can be used by `__ArrayCast` in -betterC
builds.  It is separate from `__ArrayCast` to minimize code
bloat.

Params:
    fromType = name of the type being cast from
    fromSize = total size in bytes of the array being cast from
    toType   = name of the type being cast o
    toSize   = total size in bytes of the array being cast to
 */
private void onArrayCastError()(string fromType, size_t fromSize, string toType, size_t toSize) @trusted
{
    import core.internal.string : unsignedToTempString;
    import core.stdc.stdlib : alloca;

    const(char)[][8] msgComponents =
    [
        "Cannot cast `"
        , fromType
        , "` to `"
        , toType
        , "`; an array of size "
        , unsignedToTempString(fromSize)
        , " does not align on an array of size "
        , unsignedToTempString(toSize)
    ];

    // convert discontiguous `msgComponents` to contiguous string on the stack
    size_t length = 0;
    foreach (m ; msgComponents)
        length += m.length;

    auto msg = (cast(char*)alloca(length))[0 .. length];

    size_t index = 0;
    foreach (m ; msgComponents)
        foreach (c; m)
            msg[index++] = c;

    // first argument must evaluate to `false` at compile-time to maintain memory safety in release builds
    assert(false, msg);
}

/**
The compiler lowers expressions of `cast(TTo[])TFrom[]` to
this implementation.

Params:
    from = the array to reinterpret-cast

Returns:
    `from` reinterpreted as `TTo[]`
 */
TTo[] __ArrayCast(TFrom, TTo)(TFrom[] from) @nogc pure @trusted
{
    const fromSize = from.length * TFrom.sizeof;
    const toLength = fromSize / TTo.sizeof;

    if ((fromSize % TTo.sizeof) != 0)
    {
        onArrayCastError(TFrom.stringof, fromSize, TTo.stringof, toLength * TTo.sizeof);
    }

    struct Array
    {
        size_t length;
        void* ptr;
    }
    auto a = cast(Array*)&from;
    a.length = toLength; // jam new length
    return *cast(TTo[]*)a;
}

@safe @nogc pure nothrow unittest
{
    byte[int.sizeof * 3] b = cast(byte) 0xab;
    int[] i;
    short[] s;

    i = __ArrayCast!(byte, int)(b);
    assert(i.length == 3);
    foreach (v; i)
        assert(v == cast(int) 0xabab_abab);

    s = __ArrayCast!(byte, short)(b);
    assert(s.length == 6);
    foreach (v; s)
        assert(v == cast(short) 0xabab);

    s = __ArrayCast!(int, short)(i);
    assert(s.length == 6);
    foreach (v; s)
        assert(v == cast(short) 0xabab);
}

// Allows customized assert error messages
string _d_assert_fail(string comp, A, B)(A a, B b)
{
    import core.internal.dassert : invertCompToken, miniFormat;
    auto valA = miniFormat(a);
    auto valB = miniFormat(b);
    enum token = invertCompToken(comp);
    return valA ~ " " ~ token ~ " " ~ valB;
}
