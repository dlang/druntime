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

    alias as_array this;

    extern(D) size_type size() const nothrow @safe @nogc                    { return N; }
    extern(D) size_type max_size() const nothrow @safe @nogc                { return N; }
    extern(D) bool empty() const nothrow @safe @nogc                        { return N == 0; }

    // Element access
    extern(D) reference front() @safe @nogc                                 { static if (N > 0) { return as_array()[0]; } else { return as_array()[][0]; } }
    extern(D) const_reference front() const @safe @nogc                     { static if (N > 0) { return as_array()[0]; } else { return as_array()[][0]; } }
    extern(D) reference back() @safe @nogc                                  { static if (N > 0) { return as_array()[N-1]; } else { return as_array()[][0]; } }
    extern(D) const_reference back() const @safe @nogc                      { static if (N > 0) { return as_array()[N-1]; } else { return as_array()[][0]; } }

    extern(D) void fill(ref const(T) value) @safe @nogc                     { foreach (ref T v; as_array()) v = value; }

    // D helpers
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc    { static assert(pos == 0, "std::vector is one-dimensional"); return N; }

    version(CRuntime_Microsoft)
    {
        // perf will be greatly improved by inlining the primitive access functions
        extern(D)        T* data() nothrow @safe @nogc                      { return &_Elems[0]; }
        extern(D) const(T)* data() const nothrow @safe @nogc                { return &_Elems[0]; }

        extern(D)        ref T at(size_type i) nothrow @trusted @nogc       { static if (N > 0) { if (N <= i) _Xran(); return _Elems.ptr[i]; } else { _Xran(); return _Elems[0]; } }
        extern(D) ref const(T) at(size_type i) const nothrow @trusted @nogc { static if (N > 0) { if (N <= i) _Xran(); return _Elems.ptr[i]; } else { _Xran(); return _Elems[0]; } }

        extern(D) ref inout(T)[N] as_array() const inout @safe @nogc        { return _Elems[0 .. N]; }

	private:
        import core.stdcpp.utility : _Xout_of_range;

        T[N ? N : 1] _Elems;

        void _Xran() const @safe @nogc { _Xout_of_range("invalid array<T, N> subscript"); }
    }
    else version(CRuntime_Glibc)
    {
        import core.exception : RangeError;

        // perf will be greatly improved by inlining the primitive access functions
        extern(D)        T* data() nothrow @safe @nogc                      { static if (N > 0) { return &_M_elems[0]; } else { return null; } }
        extern(D) const(T)* data() const nothrow @safe @nogc                { static if (N > 0) { return &_M_elems[0]; } else { return null; } }

        extern(D)        ref T at(size_type i) @trusted                     { if (i >= N) throw new RangeError("Index out of range"); return _M_elems.ptr[i]; }
        extern(D) ref const(T) at(size_type i) const @trusted               { if (i >= N) throw new RangeError("Index out of range"); return _M_elems.ptr[i]; }

        extern(D) ref inout(T)[N] as_array() inout nothrow @safe @nogc      { return _M_elems[0 .. N]; }

	private:
        static if (N > 0)
        {
            T[N] _M_elems;
        }
        else
        {
            struct _Placeholder {}
            _Placeholder _M_placeholder;
        }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}
