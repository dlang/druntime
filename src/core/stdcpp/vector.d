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

    // ctor/dtor
    this(size_type count);
    this(size_type count, ref const(value_type) val);
    this(size_type count, ref const(value_type) val, ref const(allocator_type) al = defaultAlloc);
    this(ref const(vector) x);
    this(iterator first, iterator last);
    this(iterator first, iterator last, ref const(allocator_type) al = defaultAlloc);
    this(const_iterator first, const_iterator last);
    this(const_iterator first, const_iterator last, ref const(allocator_type) al = defaultAlloc);
    extern(D) this(T[] arr)                                                     { this(arr.ptr, arr.ptr + arr.length); }
    extern(D) this(T[] arr, ref const(allocator_type) al = defaultAlloc)        { this(arr.ptr, arr.ptr + arr.length); }
    extern(D) this(const(T)[] arr)                                              { this(arr.ptr, arr.ptr + arr.length); }
    extern(D) this(const(T)[] arr, ref const(allocator_type) al = defaultAlloc) { this(arr.ptr, arr.ptr + arr.length); }
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
    size_type size() const nothrow @trusted @nogc;
    size_type max_size() const nothrow @trusted @nogc;
    size_type capacity() const nothrow @trusted @nogc;

    bool empty() const nothrow @trusted @nogc;

    void clear() nothrow;
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0) @trusted @nogc;
    void shrink_to_fit();

    // Element access
    T* data() nothrow @trusted @nogc;
    const(T)* data() const nothrow @trusted @nogc;

    ref T opIndex(size_type i) @trusted @nogc;
    ref const(T) opIndex(size_type i) const @trusted @nogc;
    ref T at(size_type i) @trusted @nogc;
    ref const(T) at(size_type i) const @trusted @nogc;

    ref T back() @trusted @nogc;
    ref const(T) back() const @trusted @nogc;
    ref T front() @trusted @nogc;
    ref const(T) front() const @trusted @nogc;

    // Modifiers
    void push_back(ref const(T) _);
    extern(D) void push_back(const(T) el) { push_back(el); } // forwards to ref version

    void pop_back();

    // D helpers
    alias as_array this;
    extern(D)        T[] as_array() nothrow @safe @nogc                                             { return this[]; }
    extern(D) const(T)[] as_array() const nothrow @safe @nogc                                       { return this[]; }

    extern(D)        T[] opSlice() nothrow @safe @nogc                                              { return data()[0 .. size()]; }
    extern(D) const(T)[] opSlice() const nothrow @safe @nogc                                        { return data()[0 .. size()]; }
    extern(D)        T[] opSlice(size_type start, size_type end) @safe                              { assert(start <= end && end <= size(), "Index out of bounds"); return data()[start .. end]; }
    extern(D) const(T)[] opSlice(size_type start, size_type end) const @safe                        { assert(start <= end && end <= size(), "Index out of bounds"); return data()[start .. end]; }
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                            { static assert(pos == 0, "std::vector is one-dimensional"); return size(); }

    // support all the assignment variants
    extern(D) void opSliceAssign(T value)                                                           { opSlice()[] = value; }
    extern(D) void opSliceAssign(T value, size_type i, size_type j)                                 { opSlice(i, j)[] = value; }
    extern(D) void opSliceUnary(string op)()                         if (op == "++" || op == "--")  { mixin(op ~ "opSlice()[];"); }
    extern(D) void opSliceUnary(string op)(size_type i, size_type j) if (op == "++" || op == "--")  { mixin(op ~ "opSlice(i, j)[];"); }
    extern(D) void opSliceOpAssign(string op)(T value)                                              { mixin("opSlice()[] " ~ op ~ "= value;"); }
    extern(D) void opSliceOpAssign(string op)(T value, size_type i, size_type j)                    { mixin("opSlice(i, j)[] " ~ op ~ "= value;"); }

private:
    void[24] _ = void; // to match sizeof(std::vector) and pad the object correctly.
    __gshared static immutable allocator!T defaultAlloc;
}
