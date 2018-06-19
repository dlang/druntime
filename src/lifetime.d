/**
 * Contains utilities for managing lifetimes.
 *
 * This module is not intended to be imported or used directly.  It is
 * publicly imported by object.d, and should be accessed through there.
 *
 * Copyright: The D Language Foundation 2000 - 2018.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, Sean Kelly
 */

module lifetime;

private extern (C) void rt_finalize(void *data, bool det=true);

/**
Destroys the given object and sets it back to its initial state. It's used to
_destroy an object, calling its destructor or finalizer so it no longer
references any other objects. It does $(I not) initiate a GC cycle or free
any GC memory.
*/
void destroy(T)(ref T obj) if (is(T == struct))
{
    // We need to re-initialize `obj`.  Previously, the code
    // `auto init = cast(ubyte[])typeid(T).initializer()` was used, but
    // `typeid` is a runtime call and requires the `TypeInfo` object which is
    // not usable when compiling with -betterC.  If we do `obj = T.init` then we
    // end up needlessly calling postblits and destructors.  So, we create a
    // static immutable lvalue that can be re-used with subsequent calls to `destroy`
    shared static immutable T init = T.init;

    _destructRecurse(obj);
    () @trusted {
        import core.stdc.string : memcpy;
        auto dest = (cast(ubyte*) &obj)[0 .. T.sizeof];
        auto src = (cast(ubyte*) &init)[0 .. T.sizeof];
        memcpy(dest.ptr, src.ptr, T.sizeof);
    } ();
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
        destroy(a);
        assert(destroyed == 2);
        assert(a.s == "B");
        assert(a.c.s == "C" );
    }
}


/// ditto
void destroy(T)(T obj) if (is(T == class))
{
    static if(__traits(getLinkage, T) == "C++")
    {
        obj.__xdtor();

        enum classSize = __traits(classInstanceSize, T);
        (cast(void*)obj)[0 .. classSize] = typeid(T).initializer[];
    }
    else
        rt_finalize(cast(void*)obj);
}

/// ditto
void destroy(T)(T obj) if (is(T == interface))
{
    destroy(cast(Object)obj);
}

/// Reference type demonstration
unittest
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
    destroy(cpp);
    assert(cpp.dtorCount == 1);   // `cpp`'s destructor was called
    assert(cpp.s == "S");         // `cpp.s` is back to its inital state, `"S"`
    assert(cpp.a.dtorCount == 1); // `cpp.a`'s destructor was called
    assert(cpp.a.x == 10);        // `cpp.a.x` is back to its inital state, `10`
}

/// Value type demonstration
unittest
{
    int i;
    assert(i == 0);           // `i`'s initial state is `0`
    i = 1;
    assert(i == 1);           // `i` changed to `1`
    destroy(i);
    assert(i == 0);           // `i` is back to its initial state `0`
}

unittest
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
    version(none)
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
        destroy(a);
        assert(destroyed == 2);
        assert(a.s == "B");
        assert(a.c.s == "C" );
    }
}

/// ditto
void destroy(T : U[n], U, size_t n)(ref T obj) if (!is(T == struct))
{
    foreach_reverse (ref e; obj[])
        destroy(e);
}

unittest
{
    int[2] a;
    a[0] = 1;
    a[1] = 2;
    destroy(a);
    assert(a == [ 0, 0 ]);
}

unittest
{
    static struct vec2f {
        float[2] values;
        alias values this;
    }

    vec2f v;
    destroy!vec2f(v);
}

unittest
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
void destroy(T)(ref T obj)
    if (!is(T == struct) && !is(T == interface) && !is(T == class) && !_isStaticArray!T)
{
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

unittest
{
    {
        int a = 42;
        destroy(a);
        assert(a == 0);
    }
    {
        float a = 42;
        destroy(a);
        assert(isnan(a));
    }
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

    version(none) // https://issues.dlang.org/show_bug.cgi?id=14242
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
        version(none) InnerElement[3] array; // https://issues.dlang.org/show_bug.cgi?id=14242
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

unittest
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

unittest
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
unittest
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
            if(id == '2')
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
    catch(FailedPostblitException) {}
    catch(Exception) assert(false);

    auto postblitRecurseOrder = order;
    order = null;

    try auto copy = outer;
    catch(FailedPostblitException) {}
    catch(Exception) assert(false);

    assert(postblitRecurseOrder == order);
    order = null;

    Outer[3] arr = [Outer('1', '1', '1'), Outer('1', '2', '3'), Outer('3', '3', '3')];

    try _postblitRecurse(arr);
    catch(FailedPostblitException) {}
    catch(Exception) assert(false);

    postblitRecurseOrder = order;
    order = null;

    try auto arrCopy = arr;
    catch(FailedPostblitException) {}
    catch(Exception) assert(false);

    assert(postblitRecurseOrder == order);
}
