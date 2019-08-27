/**
This module contains implentations for duplicating dynamic arrays.

Copyright: Copyright Digital Mars 2000 - 2019.
License: Distributed under the
     $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
   (See accompanying file LICENSE)
Source: $(DRUNTIMESRC core/internal/_array/_duplication.d)
*/
module core.internal.array.duplication;

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

private extern (C) void[] _d_newarrayU(const TypeInfo ti, size_t length) pure nothrow;

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
        doPostblit(res);
    return res;
}

// compiler frontend lowers struct array postblitting to this
void __ArrayPostblit(T)(T[] a)
{
    foreach (ref T e; a)
        e.__xpostblit();
}

/**
Excutes the postblit for each element in `arr`
Params:
    arr = The array containing the elements to run postblit for
*/
void doPostblit(T)(T[] arr)
{
    // infer static postblit type, run postblit if any
    if (auto postblit = getPostblit!T())
    {
        foreach (ref elem; arr)
            postblit(elem);
    }
}

/**************
Get the postblit for type T.
Returns:
    null if no postblit is necessary
    function pointer for struct postblits
    delegate for class postblits
*/
auto getPostblit(T)() @trusted pure nothrow @nogc
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
