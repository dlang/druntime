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
    iterator begin();
    const_iterator begin() const;
    const_iterator cbegin() const;
    iterator end();
    const_iterator end() const;
    const_iterator cend() const;

    // no reverse iterator for now.

    // Capacity
    size_type size() const;
    size_type max_size() const;
    size_type capacity() const;

    bool empty() const;

    void clear();
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0);
    void shrink_to_fit();

    // Element access
    T* data() nothrow;
    const(T)* data() const nothrow;

    ref T opIndex(size_type i);
    ref const(T) opIndex(size_type i) const;
    ref T at(size_type i);
    ref const(T) at(size_type i) const;

    ref T back();
    ref const(T) back() const;
    ref T front();
    ref const(T) front() const;

    // Modifiers
    void push_back(ref const(T) _);
    extern(D) void push_back(const(T) el) { push_back(el); } // forwards to ref version

    void pop_back();

    // D helpers
    alias as_array this;
    extern(D)        T[] as_array()         { return data()[0 .. size()]; }
    extern(D) const(T)[] as_array() const   { return data()[0 .. size()]; }

private:
    void[24] _ = void; // to match sizeof(std::vector) and pad the object correctly.
    __gshared static immutable allocator!T defaultAlloc;
}
