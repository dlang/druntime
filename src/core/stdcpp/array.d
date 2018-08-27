/**
 * D header file for interaction with C++ std::array.
 *
 * Copyright: Copyright (c) 2018 D Language Foundation
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/array.d)
 */

module core.stdcpp.array;

// hacks to support DMD on Win32
version (CppRuntime_Microsoft)
{
    version = CppRuntime_Windows; // use the MS runtime ABI for win32
}
else version (CppRuntime_DigitalMars)
{
    version = CppRuntime_Windows; // use the MS runtime ABI for win32
    pragma(msg, "std::array not supported by DMC");
}

extern(C++, "std"):

/**
 * D language counterpart to C++ std::array.
 *
 * C++ reference: $(LINK2 https://en.cppreference.com/w/cpp/container/array)
 */
extern(C++, class) struct array(T, size_t N)
{
extern(D):
pragma(inline, true):

    ///
    alias size_type = size_t;
    ///
    alias difference_type = ptrdiff_t;
    ///
    alias value_type = T;
    ///
    alias pointer = T*;
    ///
    alias const_pointer = const(T)*;

    ///
    alias as_array this;

    /// Variadic constructor
    this(T[N] args ...)                                             { this[] = args[]; }

    ///
    size_type size() const nothrow @safe @nogc                      { return N; }
    ///
    alias length = size;
    ///
    alias opDollar = length;
    ///
    size_type max_size() const nothrow @safe @nogc                  { return N; }
    ///
    bool empty() const nothrow @safe @nogc                          { return N == 0; }

    ///
    ref inout(T) front() inout nothrow @safe @nogc                  { static if (N > 0) { return this[0]; } else { return as_array()[][0]; /* HACK: force OOB */ } }
    ///
    ref inout(T) back() inout nothrow @safe @nogc                   { static if (N > 0) { return this[N-1]; } else { return as_array()[][0]; /* HACK: force OOB */ } }

    ///
    void fill()(auto ref const(T) value) @safe @nogc                { this[] = value; }

    version (CppRuntime_Windows)
    {
        ///
        inout(T)* data() inout nothrow @nogc                        { return &_Elems[0]; }
        ///
        ref inout(T)[N] as_array() const inout @safe @nogc          { return _Elems[0 .. N]; }

        version (CppRuntime_Microsoft)
        {
            import core.stdcpp.xutility : MSVCLinkDirectives, _Xout_of_range;
            void _Xran() const @nogc                                { _Xout_of_range("invalid array<T, N> subscript"); }
            mixin MSVCLinkDirectives!false;

            ///
            ref inout(T) at(size_type i) inout nothrow @trusted @nogc   { static if (N > 0) { if (N <= i) _Xran(); return _Elems.ptr[i]; } else { _Xran(); return _Elems[0]; } }
        }
        else
        {
            import core.exception : RangeError;

            ///
            ref inout(T) at(size_type i) inout @trusted             { if (i >= N) throw new RangeError("Index out of range"); return _Elems[i]; }
        }

    private:
        T[N ? N : 1] _Elems;
    }
    else version (CppRuntime_Gcc)
    {
        import core.exception : RangeError;

        ///
        inout(T)* data() inout nothrow @nogc                        { static if (N > 0) { return _M_elems.ptr; } else { return null; } }
        ///
        ref inout(T)[N] as_array() inout nothrow @trusted @nogc     { return data()[0 .. N]; }
        ///
        ref inout(T) at(size_type i) inout @trusted                 { if (i >= N) throw new RangeError("Index out of range"); return data()[i]; }

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
    else version (CppRuntime_Clang)
    {
        import core.exception : RangeError;

        ///
        inout(T)* data() inout nothrow @nogc                        { static if (N > 0) { return &__elems_[0]; } else { return cast(inout(T)*)__elems_.ptr; } }
        ///
        ref inout(T)[N] as_array() inout nothrow @trusted @nogc     { return data()[0 .. N]; }
        ///
        ref inout(T) at(size_type i) inout @trusted                 { if (i >= N) throw new RangeError("Index out of range"); return data()[i]; }

    private:
        static if (N > 0)
        {
            T[N] __elems_;
        }
        else
        {
            struct _ArrayInStructT { T[1] __data_; }
            align(_ArrayInStructT.alignof)
            byte[_ArrayInStructT.sizeof] __elems_ = void;
        }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}
