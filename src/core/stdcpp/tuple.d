/**
 * D header file for interaction with C++ std::tuple.
 *
 * Copyright: Copyright Manu Evans 2018.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/tuple.d)
 */

module core.stdcpp.tuple;

alias std_tuple = std.tuple;

extern(C++, std):

private template allTypes(T...)
{
    static if (T.length == 0)
        enum allTypes = true;
    else
        enum allTypes = is(T[0]) && allTypes!(T[1 .. $]);
}

extern(C++, class) struct tuple(Types...) if (allTypes!Types)
{
    enum length = Types.length;

    ref auto get(size_t i)() nothrow @safe @nogc { return tupleof[i]; }

    auto opSlice() { return this.tupleof; }
    alias opSlice this;

private:
    template ToNum(size_t i)
    {
        static if (i < 10)
            enum ToNum = [ '0' + i ];
        else
            enum ToNum = ToNum!(i / 10) ~ [ '0' + (i % 10) ];
    }
    static foreach (i, T; Types)
        mixin("T v" ~ ToNum!i ~ ";");
}

struct tuple_element(size_t i, T : tuple!Types, Types...)
{
    alias type = Types[i];
}
alias tuple_element_t(size_t i, T : tuple!Types, Types...) = tuple_element!(i, tuple!Types).type;

auto ref tuple_element_t!(i, T) get(size_t i, T : tuple!Types, Types...)(auto ref T tup)
{
    return tup.tupleof[i];
}
