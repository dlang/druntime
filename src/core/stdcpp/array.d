/**
 * D header file for interaction with C++ std::array.
 *
 * Copyright: Manu Evans 2014 - 2018.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/array.d)
 */

module core.stdcpp.array;

///////////////////////////////////////////////////////////////////////////////
// std::array declaration.
//
// - no iterators
///////////////////////////////////////////////////////////////////////////////

import stdcpp.allocator;

alias array = std.array;

extern(C++, std):

extern(C++, class) struct array(T, size_t N)
{
    alias size_type = size_t;
    alias difference_type = ptrdiff_t;
    alias value_type = T;
    alias reference = ref T;
    alias const_reference = ref const(T);
    alias pointer = T*;
    alias const_pointer = const(T)*;
//    alias iterator = pointer;
//    alias const_iterator = const_pointer;
//    alias reverse_iterator
//    alias const_reverse_iterator

    // Iterators
//    iterator begin() @trusted @nogc;
//    const_iterator begin() const @trusted @nogc;
//    const_iterator cbegin() const @trusted @nogc;
//    iterator end() @trusted @nogc;
//    const_iterator end() const @trusted @nogc;
//    const_iterator cend() const @trusted @nogc;

    // no reverse iterator for now.

	alias as_array this;

    extern(D) size_type size() const nothrow @safe @nogc                                            { return N; }
    extern(D) size_type max_size() const nothrow @safe @nogc                                        { return N; }
    extern(D) bool empty() const nothrow @safe @nogc                                                { return N > 0; }

    // Element access
    extern(D) reference front() @safe @nogc                                                         { return as_array()[0]; }
    extern(D) const_reference front() const @safe @nogc                                             { return as_array()[0]; }
    extern(D) reference back() @safe @nogc                                                          { return as_array()[N == 0 ? 0 : N-1]; }
    extern(D) const_reference back() const @safe @nogc                                              { return as_array()[N == 0 ? 0 : N-1]; }

    extern(D) void fill(ref const(T) value) @safe @nogc                                             { foreach (ref T v; as_array()) v = value; }

    // D helpers
    extern(D)        T[] opSlice() nothrow @safe @nogc                                              { return as_array(); }
    extern(D) const(T)[] opSlice() const nothrow @safe @nogc                                        { return as_array(); }
    extern(D)        T[] opSlice(size_type start, size_type end) @safe                              { assert(start <= end && end <= N, "Index out of bounds"); return as_array()[start .. end]; }
    extern(D) const(T)[] opSlice(size_type start, size_type end) const @safe                        { assert(start <= end && end <= N, "Index out of bounds"); return as_array()[start .. end]; }
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                            { static assert(pos == 0, "std::vector is one-dimensional"); return N; }

    // support all the assignment variants
    extern(D) void opSliceAssign(T value)                                                           { opSlice()[] = value; }
    extern(D) void opSliceAssign(T value, size_type i, size_type j)                                 { opSlice(i, j)[] = value; }
    extern(D) void opSliceUnary(string op)()                         if (op == "++" || op == "--")  { mixin(op ~ "opSlice()[];"); }
    extern(D) void opSliceUnary(string op)(size_type i, size_type j) if (op == "++" || op == "--")  { mixin(op ~ "opSlice(i, j)[];"); }
    extern(D) void opSliceOpAssign(string op)(T value)                                              { mixin("opSlice()[] " ~ op ~ "= value;"); }
    extern(D) void opSliceOpAssign(string op)(T value, size_type i, size_type j)                    { mixin("opSlice(i, j)[] " ~ op ~ "= value;"); }

private:
    version(CRuntime_Microsoft)
    {
        import core.stdcpp.utility : _Xout_of_range;

        T[N ? N : 1] _Elems;

        void _Xran() const @trusted @nogc { _Xout_of_range("invalid array<T, N> subscript"); }

    public:
        // perf will be greatly improved by inlining the primitive access functions
        extern(D) T* data() nothrow @safe @nogc                                 { return &_Elems[0]; }
        extern(D) const(T)* data() const nothrow @safe @nogc                    { return &_Elems[0]; }

        extern(D) ref T opIndex(size_type i) nothrow @safe @nogc                { return _Elems[0 .. N][i]; }
        extern(D) ref const(T) opIndex(size_type i) const nothrow @safe @nogc   { return _Elems[0 .. N][i]; }
        extern(D) ref T at(size_type i) nothrow @trusted @nogc                  { static if (N > 0) { if (N <= i) _Xran(); return _Elems.ptr[i]; } else { _Xran(); } }
        extern(D) ref const(T) at(size_type i) const nothrow @trusted @nogc     { static if (N > 0) { if (N <= i) _Xran(); return _Elems.ptr[i]; } else { _Xran(); } }

        extern(D)        T[] as_array() nothrow @safe @nogc                     { return _Elems[0 .. N]; }
        extern(D) const(T)[] as_array() const nothrow @safe @nogc               { return _Elems[0 .. N]; }
    }
    else version(CRuntime_Glibc)
    {
        static if (N > 0)
        {
            T[N] _M_elems;
        }
        else
        {
            struct _Placeholder {}
            _Placeholder _M_placeholder;
        }

    public:
        import core.exception : RangeError;

        // perf will be greatly improved by inlining the primitive access functions
        extern(D) T* data() nothrow @safe @nogc                             { static if (N > 0) { return &_M_elems[0]; } else { return null; } }
        extern(D) const(T)* data() const nothrow @safe @nogc                { static if (N > 0) { return &_M_elems[0]; } else { return null; } }

        extern(D) ref T opIndex(size_type i) nothrow @nogc                  { static if (N > 0) { return _M_elems[i]; } else { return (cast(T[])null)[i]; } }
        extern(D) ref const(T) opIndex(size_type i) const nothrow @nogc     { static if (N > 0) { return _M_elems[i]; } else { return (cast(T[])null)[i]; } }
        extern(D) ref T at(size_type i) @trusted                            { if (i >= N) throw new RangeError("Index out of range"); return _M_elems.ptr[i]; }
        extern(D) ref const(T) at(size_type i) const @trusted               { if (i >= N) throw new RangeError("Index out of range"); return _M_elems.ptr[i]; }

        alias as_array this;
        extern(D)        T[] as_array() nothrow @safe @nogc                 { static if (N > 0) { return _M_elems[]; } else { return null; } }
        extern(D) const(T)[] as_array() const nothrow @safe @nogc           { static if (N > 0) { return _M_elems[]; } else { return null; } }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}
