/**
* D binding to C++ <tuple>.
*
* Copyright: Copyright (c) 2019 D Language Foundation
* License: Distributed under the
*      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
*    (See accompanying file LICENSE)
* Authors:   Suleyman Sahmi
* Source:    $(DRUNTIMESRC core/stdcpp/tuple.d)
*/

module core.stdcpp.tuple;

import core.stdcpp.xutility : StdNamespace;
import core.internal.traits : AliasSeq, allSatisfy, isType, staticMap;
import core.lifetime : move, forward;

///
extern(C++, (StdNamespace))
extern(C++, class)
struct tuple(_Types...)
if (allSatisfy!(isType, _Types))
{
extern(D):
    alias Types = _Types;

    /// Forward construction from another tuple.
    this(T : tuple!Types2, Types2...)(auto ref T rhs)
    if (Types2.length == Types.length)
    {
        static if (__traits(isRef, rhs))
            expand = rhs.expand;
        else static foreach (i; 0 .. expand.length)
            expand[i] = move(rhs.expand[i]);
    }

    /// Forward construction from arguments.
    this(Args...)(auto ref Args args)
    if (Args.length == Types.length)
    {
        expand = AliasSeq!(forward!args);
    }

    /// Move assign from an rvalue tuple.
    ref tuple opAssign()(auto ref tuple rhs)
    if (!__traits(isRef, rhs))
    {
        this.swap(rhs);
        return this;
    }

    /// Copy assign from an lvalue tuple.
    ref tuple opAssign()(ref tuple rhs)
    {
        expand = rhs.expand;
        return this;
    }

    /// Forward assignment to tuple fields from another tuple.
    ref tuple opAssign(T : tuple!Types2, Types2...)(auto ref T rhs)
    if (Types2.length == Types.length)
    {
        static if (__traits(isRef, rhs))
            expand = rhs.expand;
        else static foreach (i; 0 .. expand.length)
            expand[i] = move(rhs.expand[i]);
        return this;
    }

    /// Forward assignment to tuple fields from arguments.
    ref tuple opAssign(Args...)(auto ref Args args)
    if (Args.length == Types.length)
    {
        expand = AliasSeq!(forward!(args));
        return this;
    }

    /// Swap tuple fields.
    void swap()(ref tuple rhs)
    {
        import core.internal.lifetime : swap;

        static foreach (i; 0 .. expand.length)
            swap(expand[i], rhs.expand[i]);
    }

    /// Expand tuple fields into an AliasSeq.
    Types expand;

    /// Enables tuple unpacking.
    alias expand this;

    ///
    unittest
    {
        int a; string b;
        AliasSeq!(a, b) = make_tuple(1, "2");
        assert(a == 1 && b == "2");
    }

    ///
    bool opEquals(T : tuple!Types2, Types2...)(auto ref T rhs)
    if (Types2.length == Types.length)
    {
        return expand == rhs.expand;
    }

    ///
    bool opEquals(Args...)(auto ref Args args)
    if (Args.length == Types.length)
    {
        return expand == args;
    }

    ///
    int opCmp(T : tuple!Types2, Types2...)(auto ref T rhs)
    if (Types2.length == Types.length)
    {
        static if (!Types.length) return 0;
        else
        {
            alias lhs = this;

            static foreach (i; 0 .. Types.length)
            {
                if (lhs.expand[i] < rhs.expand[i])
                    return -1;
                if (rhs.expand[i] < lhs.expand[i])
                    return 1;
            }
            return 0;
        }
    }

    ///
    int opCmp(Args...)(auto ref Args rhs)
    if (Args.length == Types.length)
    {
        static if (!Types.length) return 0;
        else
        {
            alias lhs = AliasSeq!(this.expand);

            static foreach (i; 0 .. Types.length)
            {
                if (lhs[i] < rhs[i])
                    return -1;
                if (rhs[i] < lhs[i])
                    return 1;
            }
            return 0;
        }
    }

    /// Concatenate and create a new tuple.
    auto opBinary(string op : "~", T : tuple!Types2, Types2...)(auto ref T rhs)
    {
        static if (Types2.length == 0)
            return this;
        else
        {
            static if (__traits(isRef, rhs))
                return tuple!(Types, Types2)(expand, rhs.expand);
            else
                return tuple!(Types, Types2)(expand, moveExpand!(rhs));
        }
    }

    /// Ditto
    auto opBinary(string op : "~", Args)(auto ref Args args)
    {
        static if (Args.length == 0)
            return this;
        else
            return tuple!(Types, Args)(expand, forward!args);
    }
}

///
unittest
{
    tuple!(int, string) t = make_tuple(1, "a");
    assert(t.get!0 ==1 && t.get!1 == "a");

    t = make_tuple(2, "b");
    assert(t.get!0 == 2 );
    assert(t.get!1 == "b");

    t = AliasSeq!(3, "c");
    assert(t == make_tuple(3, "c"));

    // unpacking
    int a;
    string s;
    AliasSeq!(a, s) = t;
    assert(a == 3 && s == "c");

    bool b;
    tie(b, ignore, s) = make_tuple(true, 45, "hello");
    assert(b == true && s == "hello");

    // comparison operators
    assert(make_tuple(1, "a") == make_tuple(1, "a"));
    assert(make_tuple(1, "a") != make_tuple(2, "b"));
    assert(make_tuple(1, 4.0, "12") <= make_tuple(2.0, 4, "2"));
    assert(make_tuple(1, 2) < make_tuple(2, 1));
    assert(make_tuple(1, "a") == AliasSeq!(1, "a"));
    assert(make_tuple(1, "b") > AliasSeq!(1, "a"));

    // concatenation
    auto tc = make_tuple(1, "a") ~ make_tuple(2.0, '3');
    assert(tc == make_tuple(1, "a", 2.0, '3'));
    assert(tc == tuple_cat(make_tuple(1), make_tuple("a", 2.0), make_tuple('3')));
}

unittest
{
    // empty tuple
    tuple!() t = make_tuple();
    tuple!() t2 = t;
    t = t2;
    assert(t == t2);
}

///
auto make_tuple(Types...)(auto ref Types args)
{
    return tuple!Types(forward!args);
}

///
auto ref get(size_t i, T : tuple!Types, Types...)(auto ref T tup)
{
    static assert(i < Types.length, "index `" ~ toString!i ~ "` must be lower than the number of fields `" ~ toString!(Types.length) ~ "`");
    static if (__traits(isRef, tup))
        return tup.expand[i];
    else
        return move(tup.expand[i]);
}

///
auto tie(Types...)(ref Types args)
{
    alias RefTuple = tuple!(staticMap!(Ref, Types));
    return RefTuple(args);
}

///
static immutable Ignore ignore;

///
auto tuple_cat(Tuples...)(auto ref Tuples args)
if (allSatisfy!(isTuple, Tuples))
{
    alias GetTypes(T) = AliasSeq!(T.Types);
    alias CTypes = staticMap!(GetTypes, Tuples);
    // can't use AliasSeq!(args[0].expand, args[1].expand, ...).
    return mixin({
        char[] code;
        code ~= "tuple!CTypes(";
        static foreach (i; 0 .. args.length)
        {
            if (i != 0) code ~= ", ";
            code ~= "args[" ~ i.stringof ~ "].expand";
        }
        code ~= ")";
        return code;
        }());
}

///
template forward_as_tuple(Args...)
{
    static template ForwardTypes(args...)
    {
        static if (args.length == 0)
            alias ForwardTypes = AliasSeq!();
        else
        {
            alias arg = args[0];

            static if (__traits(isRef, arg))
                alias T = Ref!(typeof(arg));
            else
                alias T = RvalueRef!(typeof(arg));

            alias ForwardTypes = AliasSeq!(T, ForwardTypes!(args[1 .. $]));
        }
    }

    auto forward_as_tuple(auto ref Args args)
    {
        return tuple!(ForwardTypes!args)(args);
    }
}

///
unittest
{
    int i = 1;
    auto t = forward_as_tuple(i, 3);
    //FIXME: It isn't working with auto ref. Apparently alias this doesn't decide the outcome of auto ref.
    //static void sink()(ref int l, auto ref int r) if (!__traits(isRef, r)) {}
    static void sink()(ref int l, int r) {}
    sink(t.expand);
}

///
struct tuple_size(T : tuple!Types, Types...)
{
    enum value = Types.length;
}

///
enum tuple_size_v(T) = tuple_size!T.value;

///
struct tuple_element(size_t n, T : tuple!Types, Types...)
{
    alias type = Types[n];
}

///
alias tuple_element_t(size_t n, T) = tuple_element!(n, T).type;


private:

//
enum isTuple(T) = is(T == tuple!Types, Types...);

//
struct Ignore
{
    auto ref opAssign(T)(auto ref const T) inout { return this; }
}

//
enum toString(long i) = i.stringof[0 .. $ - 1];

//
template moveExpand(alias tup, size_t i = 0)
{
    static if (i >= tup.Types.length)
        alias moveExpand = AliasSeq!();
    else
    {
        @property auto mv() { return move(tup.expand[i]); }
        alias moveExpand = AliasSeq!(mv, moveExpand!(tup, i + 1));
    }
}

//
struct Ref(T)
{
    this(inout ref T arg) inout { field = &arg; }
    auto opAssign(Args...)(auto ref Args args) if (Args.length) { *field = forward!args; }

    ref inout(T) _get() inout { return *field; }
    alias _get this;

    private T* field;
}

//
struct RvalueRef(T)
{
    this(inout ref T arg) inout { field = &arg; }
    auto opAssign(Args...)(auto ref Args args) if (Args.length) { *field = forward!args; }

    inout(T) _get() inout { return move(*field); }
    alias _get this;

    private T* field;
}
