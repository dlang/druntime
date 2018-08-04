/**
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
import core.stdc.stddef : wchar_t;

alias std_string = std.string;
//alias std_u16string = std.u16string;
//alias std_u32string = std.u32string;
//alias std_wstring = std.wstring;

extern(C++, std):

/**
 * Character traits classes specify character properties and provide specific
 * semantics for certain operations on characters and sequences of characters.
 */
extern(C++, struct) struct char_traits(CharT) {}

/**
 * The basic_string is the generalization of class string for any character
 * type.
 */
extern(C++, class) struct basic_string(T, Traits = char_traits!T, Alloc = allocator!T)
{
    enum size_type npos = size_type.max;

    alias size_type = size_t;
    alias difference_type = ptrdiff_t;
    alias value_type = T;
    alias traits_type = Traits;
    alias allocator_type = Alloc;
    alias reference = ref value_type;
    alias const_reference = ref const(value_type);
    alias pointer = value_type*;
    alias const_pointer = const(value_type)*;
    alias iterator = pointer;
    alias const_iterator = const_pointer;
    // alias reverse_iterator
    // alias const_reverse_iterator

    alias as_array this;

    // ctor/dtor
    this(const(T)* ptr, size_type count);
    this(const(T)* ptr, size_type count, ref const(allocator_type) al);
    this(const(T)* ptr);
    this(const(T)* ptr, ref const(allocator_type) al);
//    extern(D) this(const(T)[] dstr)                                                     { this(dstr.ptr, dstr.length); }
//    extern(D) this(const(T)[] dstr, ref const(allocator_type) al)                       { this(dstr.ptr, dstr.length, al); }
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
    size_type length() const nothrow @trusted @nogc                                     { return size(); }
    size_type max_size() const nothrow @trusted @nogc;

    bool empty() const nothrow @trusted @nogc                                           { return size() == 0; }

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

    extern(D) const(T)* c_str() const nothrow @trusted @nogc                            { return data(); }

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
//    extern(D) ref basic_string insert(size_type pos, const(T)[] s)                      { insert(pos, s.ptr, s.length); return this; }

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
    extern(D)        T[] opSlice() nothrow @trusted @nogc                                           { return as_array(); }
    extern(D) const(T)[] opSlice() const nothrow @trusted @nogc                                     { return as_array(); }
    extern(D)        T[] opSlice(size_type start, size_type end) @trusted                           { assert(start <= end && end <= size(), "Index out of bounds"); return as_array()[start .. end]; }
    extern(D) const(T)[] opSlice(size_type start, size_type end) const @trusted                     { assert(start <= end && end <= size(), "Index out of bounds"); return as_array()[start .. end]; }
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                            { static assert(pos == 0, "std::vector is one-dimensional"); return size(); }

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
        import core.stdcpp.utility : _Container_base, _Compressed_pair, _Xout_of_range;

        void _Xran() const @trusted @nogc { _Xout_of_range("invalid string position"); }

        extern(C++, class) struct _String_val
        {
            enum _BUF_SIZE = 16 / value_type.sizeof < 1 ? 1 : 16 / value_type.sizeof;

            union _Bxty
            {
                value_type[_BUF_SIZE] _Buf;
                pointer _Ptr;
            }

            _Container_base base;
            alias base this;

            _Bxty _Bx = void;
            size_type _Mysize;  // current length of string
            size_type _Myres;   // current storage reserved for string

            extern(D) @property inout(value_type)* _Myptr() inout nothrow @trusted @nogc    { return _BUF_SIZE <= _Myres ? _Bx._Ptr : _Bx._Buf.ptr; }
        }

        _Compressed_pair!(void, _String_val) _Mypair;

    public:
        // perf will be greatly improved by inlining the primitive access functions
        extern(D) size_type size() const nothrow @safe @nogc                                { return _Mypair._Myval2._Mysize; }
        extern(D) size_type capacity() const nothrow @safe @nogc                            { return _Mypair._Myval2._Myres; }

        extern(D) T* data() nothrow @safe @nogc                                             { return _Mypair._Myval2._Myptr; }
        extern(D) const(T)* data() const nothrow @safe @nogc                                { return _Mypair._Myval2._Myptr; }

        extern(D) ref T opIndex(size_type i) nothrow @trusted @nogc                         { return _Mypair._Myval2._Myptr[0 .. _Mypair._Myval2._Mysize][i]; }
        extern(D) ref const(T) opIndex(size_type i) const nothrow @trusted @nogc            { return _Mypair._Myval2._Myptr[0 .. _Mypair._Myval2._Mysize][i]; }
        extern(D) ref T at(size_type i) nothrow @trusted @nogc                              { if (_Mypair._Myval2._Mysize <= i) _Xran(); return _Mypair._Myval2._Myptr[i]; }
        extern(D) ref const(T) at(size_type i) const nothrow @trusted @nogc                 { if (_Mypair._Myval2._Mysize <= i) _Xran(); return _Mypair._Myval2._Myptr[i]; }

        extern(D)        T[] as_array() nothrow @trusted @nogc                              { return _Mypair._Myval2._Myptr[0 .. _Mypair._Myval2._Mysize]; }
        extern(D) const(T)[] as_array() const nothrow @trusted @nogc                        { return _Mypair._Myval2._Myptr[0 .. _Mypair._Myval2._Mysize]; }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}

alias basic_string!char string;
//alias basic_string!wchar u16string; // TODO: can't mangle these yet either...
//alias basic_string!dchar u32string;
//alias basic_string!wchar_t wstring; // TODO: we can't mangle wchar_t properly (yet?)
