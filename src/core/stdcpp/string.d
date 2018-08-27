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
import core.stdcpp.utility : _ITERATOR_DEBUG_LEVEL;
import core.stdc.stddef : wchar_t;
import core.stdc.string : strlen;

alias std_string = std.string;
//alias std_u16string = std.u16string;
//alias std_u32string = std.u32string;
//alias std_wstring = std.wstring;

extern(C++, std):

alias basic_string!char string;
//alias basic_string!wchar u16string; // TODO: can't mangle these yet either...
//alias basic_string!dchar u32string;
//alias basic_string!wchar_t wstring; // TODO: we can't mangle wchar_t properly (yet?)


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

//    alias iterator = pointer;
//    alias const_iterator = const_pointer;
//    alias reverse_iterator
//    alias const_reverse_iterator

    alias as_array this;

    // MSVC allocates on default initialisation in debug, which can't be modelled by D `struct`
    @disable this();

    // ctor/dtor
    extern(D) this(const(T)[] dstr) nothrow @safe @nogc                                 { this(&dstr[0], dstr.length); }
    extern(D) this(const(T)[] dstr, ref const(allocator_type) al) nothrow @safe @nogc   { this(&dstr[0], dstr.length, al); }
    ~this() nothrow;

    ref basic_string opAssign(ref const(basic_string) s);

    // Iterators
//    iterator begin() nothrow @trusted @nogc;
//    const_iterator begin() const nothrow @trusted @nogc;
//    const_iterator cbegin() const nothrow @trusted @nogc;
//    iterator end() nothrow @trusted @nogc;
//    const_iterator end() const nothrow @trusted @nogc;
//    const_iterator cend() const nothrow @trusted @nogc;

    // no reverse iterator for now.

    // Capacity
    size_type length() const nothrow @safe @nogc                                        { return size(); }
    size_type max_size() const nothrow @trusted @nogc;

    bool empty() const nothrow @safe @nogc                                              { return size() == 0; }

    void clear() nothrow;
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0) @trusted @nogc;
    void shrink_to_fit();

    // Element access
    extern(D) reference front() @safe @nogc                                             { return as_array()[0]; }
    extern(D) const_reference front() const @safe @nogc                                 { return as_array()[0]; }
    extern(D) reference back() @safe @nogc                                              { return as_array()[size()-1]; }
    extern(D) const_reference back() const @safe @nogc                                  { return as_array()[size()-1]; }

    extern(D) const(T)* c_str() const nothrow @safe @nogc                               { return data(); }

    // Modifiers
    ref basic_string opOpAssign(string op : "+")(ref const(basic_string) s);
    ref basic_string opOpAssign(string op : "+")(const(T)* s);
    ref basic_string opOpAssign(string op : "+")(T s);
    extern(D) ref basic_string opOpAssign(string op : "~")(ref const(basic_string) s)   { this += s; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(const(T)* s)                 { this += s; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(const(T)[] s)                { auto t = basic_string(s.ptr, s.length); this += t; return this; }
    extern(D) ref basic_string opOpAssign(string op : "~")(T s)                         { this += s; return this; }

    ref basic_string append(size_type n, T c);
    extern(D) ref basic_string append(const(T)* s) nothrow @nogc                        { assert(s); return append(s, strlen(s)); }
    ref basic_string append(const(T)* s, size_type n) nothrow @trusted @nogc;
    ref basic_string append(ref const(basic_string) str);
    ref basic_string append(ref const(basic_string) str, size_type subpos, size_type sublen);
    extern(D) ref basic_string append(const(T)[] s) nothrow @safe @nogc                 { append(&s[0], s.length); return this; }

    void push_back(T c);

    ref basic_string assign(size_type n, T c);
    extern(D) ref basic_string assign(const(T)* s) nothrow @nogc                        { assert(s); return assign(s, strlen(s)); }
    ref basic_string assign(const(T)* s, size_type n) nothrow @trusted @nogc;
    ref basic_string assign(ref const(basic_string) str);
    ref basic_string assign(ref const(basic_string) str, size_type subpos, size_type sublen);
    extern(D) ref basic_string assign(const(T)[] s) nothrow @safe @nogc                 { assign(&s[0], s.length); return this; }

    ref basic_string insert(size_type pos, ref const(basic_string) str);
    ref basic_string insert(size_type pos, ref const(basic_string) str, size_type subpos, size_type sublen);
//    ref basic_string insert(size_type pos, const(T)* s) nothrow @nogc                   { assert(s); return insert(pos, s, strlen(s)); }
    ref basic_string insert(size_type pos, const(T)* s, size_type n) nothrow @trusted @nogc;
    ref basic_string insert(size_type pos, size_type n, T c);
//    extern(D) ref basic_string insert(size_type pos, const(T)[] s) nothrow @safe @nogc  { insert(pos, &s[0], s.length); return this; }

    ref basic_string erase(size_type pos = 0, size_type len = npos);

    // replace
    // swap
    void pop_back();

    // String operations
    deprecated size_type copy(T* s, size_type len, size_type pos = 0) const;

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
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                        { static assert(pos == 0, "std::vector is one-dimensional"); return size(); }

    version(CRuntime_Microsoft)
    {
        this(const(T)* ptr, size_type count) nothrow @safe @nogc                                { _Tidy(); assign(ptr, count); }
        this(const(T)* ptr, size_type count, ref const(allocator_type) al) nothrow @safe @nogc  { _AssignAllocator(al); _Tidy(); assign(ptr, count); }
        this(const(T)* ptr) nothrow @nogc                                                       { _Tidy(); assign(ptr); }
        this(const(T)* ptr, ref const(allocator_type) al) nothrow @nogc                         { _AssignAllocator(al); _Tidy(); assign(ptr); }

        // perf will be greatly improved by inlining the primitive access functions
        extern(D) size_type size() const nothrow @safe @nogc                                    { return _Get_data()._Mysize; }
        extern(D) size_type capacity() const nothrow @safe @nogc                                { return _Get_data()._Myres; }

        extern(D)        T* data() nothrow @safe @nogc                                          { return _Get_data()._Myptr; }
        extern(D) const(T)* data() const nothrow @safe @nogc                                    { return _Get_data()._Myptr; }

        extern(D) ref        T at(size_type i) nothrow @trusted @nogc                           { if (_Get_data()._Mysize <= i) _Xran(); return _Get_data()._Myptr[i]; }
        extern(D) ref const(T) at(size_type i) const nothrow @trusted @nogc                     { if (_Get_data()._Mysize <= i) _Xran(); return _Get_data()._Myptr[i]; }

        extern(D)        T[] as_array() nothrow @trusted @nogc                                  { return _Get_data()._Myptr[0 .. _Get_data()._Mysize]; }
        extern(D) const(T)[] as_array() const nothrow @trusted @nogc                            { return _Get_data()._Myptr[0 .. _Get_data()._Mysize]; }

        extern(D) this(this)
        {
            // we meed a compatible postblit
            static if (_ITERATOR_DEBUG_LEVEL > 0)
            {
                _Base._Alloc_proxy();
            }

            if (_Get_data()._IsAllocated())
            {
                pointer _Ptr = _Get_data()._Myptr;
                size_type _Count = _Get_data()._Mysize;

                // re-init to zero
                _Get_data()._Mysize = 0;
                _Get_data()._Myres = 0;

                _Tidy();
                assign(_Ptr, _Count);
            }
        }

    private:
        import core.stdcpp.utility : _Xout_of_range;

        pragma(inline, true) 
        {
            extern (D) ref _Base.Alloc _Getal() nothrow @safe @nogc                 { return _Base._Mypair._Myval1; }
            extern (D) ref inout(_Base.ValTy) _Get_data() inout nothrow @safe @nogc { return _Base._Mypair._Myval2; }

            extern (D) void _Eos(size_type _Newsize) nothrow @nogc                  { _Get_data()._Myptr()[_Get_data()._Mysize = _Newsize] = T(0); }
        }

        extern (D) void _AssignAllocator(ref const(allocator_type) al) nothrow @nogc
        {
            static if (_Base._Mypair._HasFirst)
                _Getal() = al;
        }

        extern (D) void _Tidy(bool _Built = false, size_type _Newsize = 0) nothrow @trusted @nogc
        {
            if (_Built && _Base.ValTy._BUF_SIZE <= _Get_data()._Myres)
            {
                assert(false); // TODO: free buffer...
            }
            _Get_data()._Myres = _Base.ValTy._BUF_SIZE - 1;
            _Eos(_Newsize);
        }

        void _Xran() const @trusted @nogc { _Xout_of_range("invalid string position"); }

        _String_alloc!(_String_base_types!(T, Alloc)) _Base;
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }

private:
    // HACK: because no rvalue->ref
    extern (D) __gshared static immutable allocator_type defaultAlloc;
}


// platform detail
version(CRuntime_Microsoft)
{
    extern (C++, struct) struct _String_base_types(_Elem, _Alloc)
    {
        alias Ty = _Elem;
        alias Alloc = _Alloc;
    }

    extern (C++, class) struct _String_alloc(_Alloc_types)
    {
        import core.stdcpp.utility : _Compressed_pair;

        alias Ty = _Alloc_types.Ty;
        alias Alloc = _Alloc_types.Alloc;
        alias ValTy = _String_val!Ty;

        void _Orphan_all() nothrow @trusted @nogc;

        static if (_ITERATOR_DEBUG_LEVEL > 0)
        {
            void _Alloc_proxy() nothrow @trusted @nogc;
            void _Free_proxy() nothrow @trusted @nogc;
        }

        _Compressed_pair!(Alloc, ValTy) _Mypair;
    }

    extern (C++, class) struct _String_val(T)
    {
        import core.stdcpp.utility : _Container_base;
        import core.stdcpp.type_traits : is_empty;

        enum _BUF_SIZE = 16 / T.sizeof < 1 ? 1 : 16 / T.sizeof;
        enum _ALLOC_MASK = T.sizeof <= 1 ? 15 : T.sizeof <= 2 ? 7 : T.sizeof <= 4 ? 3 : T.sizeof <= 8 ? 1 : 0;

        static if (!is_empty!_Container_base.value)
        {
            _Container_base _Base;
        }

        union _Bxty
        {
            T[_BUF_SIZE] _Buf;
            T* _Ptr;
        }

        _Bxty _Bx = void;
        size_t _Mysize;  // current length of string
        size_t _Myres;   // current storage reserved for string

        pragma(inline, true) 
        {
            extern(D) bool _IsAllocated() const @safe @nogc                     { return _BUF_SIZE <= _Myres; }
            extern(D) @property T* _Myptr() nothrow @trusted @nogc              { return _BUF_SIZE <= _Myres ? _Bx._Ptr : _Bx._Buf.ptr; }
            extern(D) @property const(T)* _Myptr() const nothrow @trusted @nogc { return _BUF_SIZE <= _Myres ? _Bx._Ptr : _Bx._Buf.ptr; }
        }
    }
}
