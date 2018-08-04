/**
 * D header file for interaction with C++ std::utility.
 *
 * Copyright: Copyright Manu Evans 2018.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/utility.d)
 */

module core.stdcpp.utility;

extern(C++, std):

/**
 * std.pair is a struct template that provides a way to store two heterogeneous objects as a single unit.
 * A pair is a specific case of a std.tuple with two elements.
 */
struct pair(T1, T2)
{
    alias first_type = T1;
    alias second_type = T2;

    first_type first;
    second_type second;
}

version(CRuntime_Microsoft)
{
    version (_ITERATOR_DEBUG_LEVEL_0)
        enum _ITERATOR_DEBUG_LEVEL = 0;
    else version (_ITERATOR_DEBUG_LEVEL_1)
        enum _ITERATOR_DEBUG_LEVEL = 1;
    else version (_ITERATOR_DEBUG_LEVEL_2)
        enum _ITERATOR_DEBUG_LEVEL = 2;
    else
        enum _ITERATOR_DEBUG_LEVEL = 0; // default? dunno...

    static if (_ITERATOR_DEBUG_LEVEL == 0)
    {
        struct _Container_base0 {}
        alias _Container_base = _Container_base0;
    }
    else
    {
        struct _Container_proxy
        {
            const(_Container_base12)* _Mycont;
            _Iterator_base12* _Myfirstiter;
        }
        struct _Container_base12 { _Container_proxy* _Myproxy; }
        alias _Container_base = _Container_base12;
    }

    extern (C++, class) struct _Compressed_pair(_Ty1, _Ty2, bool Ty1Empty = is(_Ty1 == void))
    {
        static if (!Ty1Empty)
            _Ty1 _Myval1;
        _Ty2 _Myval2;
    }

    void _Xbad_alloc() nothrow @trusted @nogc;
    void _Xinvalid_argument(const(char)* message) nothrow @trusted @nogc;
    void _Xlength_error(const(char)* message) nothrow @trusted @nogc;
    void _Xout_of_range(const(char)* message) nothrow @trusted @nogc;
    void _Xoverflow_error(const(char)* message) nothrow @trusted @nogc;
    void _Xruntime_error(const(char)* message) nothrow @trusted @nogc;
}
