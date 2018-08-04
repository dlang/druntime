/**
 * D header file for interaction with C++ std::vector.
 *
 * Copyright: Copyright Guillaume Chatelet 2014 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/vector.d)
 */

module core.stdcpp.vector;

///////////////////////////////////////////////////////////////////////////////
// std::vector declaration.
//
// Current caveats :
// - mangling issues still exist
// - won't work with custom allocators
// - missing noexcept
// - iterators are implemented as pointers
// - no reverse_iterator nor rbegin/rend
// - nothrow @trusted @nogc for most functions depend on knowledge
//   of T's construction/destruction/assignment semantics
///////////////////////////////////////////////////////////////////////////////

import core.stdcpp.allocator;

alias vector = std.vector;

extern(C++, std):

extern(C++, class) struct vector(T, Alloc = allocator!T)
{
    alias value_type = T;
    alias allocator_type = Alloc;
    alias reference = ref T;
    alias const_reference = ref const(T);
    alias pointer = T*;
    alias const_pointer = const(T)*;
    alias iterator = pointer;
    alias const_iterator = const_pointer;
    // alias reverse_iterator
    // alias const_reverse_iterator
    alias difference_type = ptrdiff_t;
    alias size_type = size_t;

    alias as_array this;

    // ctor/dtor
    this(size_type count);
    this(size_type count, ref const(value_type) val);
    this(size_type count, ref const(value_type) val, ref const(allocator_type) al = defaultAlloc);
    this(ref const(vector) x);
    this(iterator first, iterator last);
    this(iterator first, iterator last, ref const(allocator_type) al = defaultAlloc);
    this(const_iterator first, const_iterator last);
    this(const_iterator first, const_iterator last, ref const(allocator_type) al = defaultAlloc);
//    extern(D) this(T[] arr)                                                     { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(T[] arr, ref const(allocator_type) al = defaultAlloc)        { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(const(T)[] arr)                                              { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(const(T)[] arr, ref const(allocator_type) al = defaultAlloc) { this(arr.ptr, arr.ptr + arr.length); }
    ~this();

    ref vector opAssign(ref const(vector) s);

    // Iterators
    iterator begin() @trusted @nogc;
    const_iterator begin() const @trusted @nogc;
    const_iterator cbegin() const @trusted @nogc;
    iterator end() @trusted @nogc;
    const_iterator end() const @trusted @nogc;
    const_iterator cend() const @trusted @nogc;

    // no reverse iterator for now.

    // Capacity
    size_type max_size() const nothrow @trusted @nogc;

    void clear() nothrow;
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0) @trusted @nogc;
    void shrink_to_fit();

    // Element access
    ref T back() @trusted @nogc;
    ref const(T) back() const @trusted @nogc;
    ref T front() @trusted @nogc;
    ref const(T) front() const @trusted @nogc;

    // Modifiers
    void push_back(ref const(T) _);
    extern(D) void push_back(const(T) el) { push_back(el); } // forwards to ref version

    void pop_back();

    // D helpers
    extern(D)        T[] as_array() nothrow @safe @nogc                                             { return this[]; }
    extern(D) const(T)[] as_array() const nothrow @safe @nogc                                       { return this[]; }

    extern(D)        T[] opSlice() nothrow @trusted @nogc                                           { return data()[0 .. size()]; }
    extern(D) const(T)[] opSlice() const nothrow @trusted @nogc                                     { return data()[0 .. size()]; }
    extern(D)        T[] opSlice(size_type start, size_type end) @trusted                           { assert(start <= end && end <= size(), "Index out of bounds"); return data()[start .. end]; }
    extern(D) const(T)[] opSlice(size_type start, size_type end) const @trusted                     { assert(start <= end && end <= size(), "Index out of bounds"); return data()[start .. end]; }
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                            { static assert(pos == 0, "std::vector is one-dimensional"); return size(); }

    // support all the assignment variants
    extern(D) void opSliceAssign(T value)                                                           { opSlice()[] = value; }
    extern(D) void opSliceAssign(T value, size_type i, size_type j)                                 { opSlice(i, j)[] = value; }
    extern(D) void opSliceUnary(string op)()                         if (op == "++" || op == "--")  { mixin(op ~ "opSlice()[];"); }
    extern(D) void opSliceUnary(string op)(size_type i, size_type j) if (op == "++" || op == "--")  { mixin(op ~ "opSlice(i, j)[];"); }
    extern(D) void opSliceOpAssign(string op)(T value)                                              { mixin("opSlice()[] " ~ op ~ "= value;"); }
    extern(D) void opSliceOpAssign(string op)(T value, size_type i, size_type j)                    { mixin("opSlice(i, j)[] " ~ op ~ "= value;"); }

private:
    extern (D) __gshared static immutable allocator!T defaultAlloc;

    version(CRuntime_Microsoft)
    {
        import core.stdcpp.utility : _Container_base, _Compressed_pair, _Xlength_error, _Xout_of_range;

        void _Xlen() const @trusted @nogc                                   { _Xlength_error("vector!T too long"); }
        void _Xran() const @trusted @nogc                                   { _Xout_of_range("invalid vector!T subscript"); }

        extern (C++, class) struct _Vector_val
        {
            _Container_base base;
            alias base this;

            pointer _Myfirst;   // pointer to beginning of array
            pointer _Mylast;    // pointer to current end of sequence
            pointer _Myend;     // pointer to end of array
        }

        _Compressed_pair!(void, _Vector_val) _Mypair;

    public:
        // perf will be greatly improved by inlining the primitive access functions
        extern(D) size_type size() const nothrow @safe @nogc                { return _Mypair._Myval2._Mylast - _Mypair._Myval2._Myfirst; }
        extern(D) size_type capacity() const nothrow @safe @nogc            { return _Mypair._Myval2._Myend - _Mypair._Myval2._Myfirst; }
        extern(D) bool empty() const nothrow @safe @nogc                    { return _Mypair._Myval2._Myfirst == _Mypair._Myval2._Mylast; }

        extern(D) T* data() nothrow @safe @nogc                             { return _Mypair._Myval2._Myfirst; }
        extern(D) const(T)* data() const nothrow @safe @nogc                { return _Mypair._Myval2._Myfirst; }

        extern(D) ref T opIndex(size_type i) @trusted @nogc                 { if (size() <= i) _Xran(); return _Mypair._Myval2._Myfirst[i]; }
        extern(D) ref const(T) opIndex(size_type i) const @trusted @nogc    { if (size() <= i) _Xran(); return _Mypair._Myval2._Myfirst[i]; }
        extern(D) ref T at(size_type i) @trusted @nogc                      { if (size() <= i) _Xran(); return _Mypair._Myval2._Myfirst[i]; }
        extern(D) ref const(T) at(size_type i) const @trusted @nogc         { if (size() <= i) _Xran(); return _Mypair._Myval2._Myfirst[i]; }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}
