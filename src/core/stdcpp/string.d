﻿/**
 * D header file for interaction with C++ std::string.
 *
 * Copyright: Copyright Guillaume Chatelet 2014 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/string.d)
 */

module core.stdcpp.string;

///////////////////////////////////////////////////////////////////////////////
// std::string declaration.
//
// Current caveats :
// - mangling issues still exist
// - won't work with custom allocators
// - iterators are implemented as pointers
// - no reverse_iterator nor rbegin/rend
// - missing functions : replace, swap
///////////////////////////////////////////////////////////////////////////////

import core.stdcpp.allocator;
import core.stdc.stddef;

extern(C++, std):

/**
 * Character traits classes specify character properties and provide specific
 * semantics for certain operations on characters and sequences of characters.
 */
struct char_traits(CharT) {}

/**
 * The basic_string is the generalization of class string for any character
 * type.
 */
extern(C++, class) struct basic_string(T, Traits = char_traits!T, Alloc = allocator!T)
{
    enum size_type npos = size_type.max;

    alias value_type = T;
    alias traits_type = Traits;
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
    this(const(T)* ptr, size_type count);
    this(const(T)* ptr, size_type count, ref const(allocator_type) al = defaultAlloc);
    this(const(T)* ptr);
    this(const(T)* ptr, ref const(allocator_type) al = defaultAlloc);
    extern(D) this(const(T)[] dstr)                                                 { this(dstr.ptr, dstr.length); }
    extern(D) this(const(T)[] dstr, ref const(allocator_type) al = defaultAlloc)    { this(dstr.ptr, dstr.length); }
    ~this() nothrow;

    ref basic_string opAssign(ref const(basic_string) s);

    // Iterators
    iterator begin() nothrow @trusted @nogc;
    const_iterator begin() const nothrow @trusted @nogc;
    const_iterator cbegin() const nothrow @trusted @nogc;

    iterator end() nothrow @trusted @nogc;
    const_iterator end() const nothrow @trusted @nogc;
    const_iterator cend() const nothrow @trusted @nogc;

    // no reverse iterator for now.

    // Capacity
    size_type size() const nothrow @trusted @nogc;
    size_type length() const nothrow @trusted @nogc;
    size_type max_size() const nothrow @trusted @nogc;
    size_type capacity() const nothrow @trusted @nogc;

    bool empty() const nothrow @trusted @nogc;

    void clear() nothrow;
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0) @trusted @nogc;
    void shrink_to_fit();

    // Element access
    ref T opIndex(size_type i) @trusted @nogc;
    ref const(T) opIndex(size_type i) const @trusted @nogc;
    ref T at(size_type i) @trusted @nogc;
    ref const(T) at(size_type i) const @trusted @nogc;

    ref T back() @trusted @nogc;
    ref const(T) back() const @trusted @nogc;
    ref T front() @trusted @nogc;
    ref const(T) front() const @trusted @nogc;

    const(T)* c_str() const nothrow @trusted @nogc;
    T* data() nothrow @trusted @nogc;
    const(T)* data() const nothrow @trusted @nogc;

    // Modifiers
    ref basic_string opOpAssign(string op : "+")(ref const(basic_string) s);
    ref basic_string opOpAssign(string op : "+")(const(T)* s);
    ref basic_string opOpAssign(string op : "+")(T s);
    extern(D) ref basic_string opOpAssign(string op : "~")(ref const(basic_string) s)   { this += s; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(const(T)* s)                 { this += s; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(const(T)[] s)                { auto t = basic_string(s.ptr, s.length); this += t; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(T s)                         { this += s; return this; }

    ref basic_string append(size_type n, T c);
    ref basic_string append(const(T)* s);
    ref basic_string append(const(T)* s, size_type n);
    ref basic_string append(ref const(basic_string) str);
    ref basic_string append(ref const(basic_string) str, size_type subpos, size_type sublen);
    extern(D) ref basic_string append(const(T)[] s)                                     { append(s.ptr, s.length); return this; }

    void push_back(T c);

    ref basic_string assign(size_type n, T c);
    ref basic_string assign(const(T)* s);
    ref basic_string assign(const(T)* s, size_type n);
    ref basic_string assign(ref const(basic_string) str);
    ref basic_string assign(ref const(basic_string) str, size_type subpos, size_type sublen);
    extern(D) ref basic_string assign(const(T)[] s)                                     { assign(s.ptr, s.length); return this; }

    ref basic_string insert(size_type pos, ref const(basic_string) str);
    ref basic_string insert(size_type pos, ref const(basic_string) str, size_type subpos, size_type sublen);
    ref basic_string insert(size_type pos, const(T)* s);
    ref basic_string insert(size_type pos, const(T)* s, size_type n);
    ref basic_string insert(size_type pos, size_type n, T c);
    extern(D) ref basic_string insert(size_type pos, const(T)[] s)                      { insert(pos, s.ptr, s.length); return this; }

    ref basic_string erase(size_type pos = 0, size_type len = npos);

    // replace
    // swap
    void pop_back();

    // String operations
    size_type copy(T* s, size_type len, size_type pos = 0) const;

    size_type find(ref const(basic_string) str, size_type pos = 0) const nothrow;
    size_type find(const(T)* s, size_type pos = 0) const;
    size_type find(const(T)* s, size_type pos, size_type n) const;
    size_type find(T c, size_type pos = 0) const nothrow;

    size_type rfind(ref const(basic_string) str, size_type pos = npos) const nothrow;
    size_type rfind(const(T)* s, size_type pos = npos) const;
    size_type rfind(const(T)* s, size_type pos, size_type n) const;
    size_type rfind(T c, size_type pos = npos) const nothrow;

    size_type find_first_of(ref const(basic_string) str, size_type pos = 0) const nothrow;
    size_type find_first_of(const(T)* s, size_type pos = 0) const;
    size_type find_first_of(const(T)* s, size_type pos, size_type n) const;
    size_type find_first_of(T c, size_type pos = 0) const nothrow;

    size_type find_last_of(ref const(basic_string) str, size_type pos = npos) const nothrow;
    size_type find_last_of(const(T)* s, size_type pos = npos) const;
    size_type find_last_of(const(T)* s, size_type pos, size_type n) const;
    size_type find_last_of(T c, size_type pos = npos) const nothrow;

    size_type find_first_not_of(ref const(basic_string) str, size_type pos = 0) const nothrow;
    size_type find_first_not_of(const(T)* s, size_type pos = 0) const;
    size_type find_first_not_of(const(T)* s, size_type pos, size_type n) const;
    size_type find_first_not_of(T c, size_type pos = 0) const nothrow;

    size_type find_last_not_of(ref const(basic_string) str, size_type pos = npos) const nothrow;
    size_type find_last_not_of(const(T)* s, size_type pos = npos) const;
    size_type find_last_not_of(const(T)* s, size_type pos, size_type n) const;
    size_type find_last_not_of(T c, size_type pos = npos) const nothrow;

    basic_string substr(size_type pos = 0, size_type len = npos) const;

    int compare(ref const(basic_string) str) const nothrow;
    int compare(size_type pos, size_type len, ref const(basic_string) str) const;
    int compare(size_type pos, size_type len, ref const(basic_string) str, size_type subpos, size_type sublen) const;
    int compare(const(T)* s) const;
    int compare(size_type pos, size_type len, const(T)* s) const;
    int compare(size_type pos, size_type len, const(T)* s, size_type n) const;

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
    void[8] _ = void; // to match sizeof(std::string) and pad the object correctly.
    __gshared static immutable allocator!T defaultAlloc;
}

alias basic_string!char std_string;
//alias basic_string!wchar std_u16string; // TODO: can't mangle these yet either...
//alias basic_string!dchar std_u32string;
//alias basic_string!wchar_t std_wstring; // TODO: we can't mangle wchar_t properly (yet?)
