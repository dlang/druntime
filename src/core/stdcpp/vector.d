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
import core.stdcpp.utility : _ITERATOR_DEBUG_LEVEL;

alias vector = std.vector;

extern(C++, std):

extern(C++, class) struct vector(T, Alloc = allocator!T)
{
    static assert(!is(T == bool), "vector!bool not supported!");

    alias value_type = T;
    alias allocator_type = Alloc;
    alias reference = ref T;
    alias const_reference = ref const(T);
    alias pointer = T*;
    alias const_pointer = const(T)*;
    alias difference_type = ptrdiff_t;
    alias size_type = size_t;

//    alias iterator = pointer;
//    alias const_iterator = const_pointer;
//    alias reverse_iterator
//    alias const_reverse_iterator

    alias as_array this;

    // ctor/dtor
    this(size_type count);
    this(size_type count, ref const(value_type) val);
    this(size_type count, ref const(value_type) val, ref const(allocator_type) al);
    this(ref const(vector) x);
//    this(iterator first, iterator last);
//    this(iterator first, iterator last, ref const(allocator_type) al = defaultAlloc);
//    this(const_iterator first, const_iterator last);
//    this(const_iterator first, const_iterator last, ref const(allocator_type) al = defaultAlloc);
//    extern(D) this(T[] arr)                                                     { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(T[] arr, ref const(allocator_type) al = defaultAlloc)        { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(const(T)[] arr)                                              { this(arr.ptr, arr.ptr + arr.length); }
//    extern(D) this(const(T)[] arr, ref const(allocator_type) al = defaultAlloc) { this(arr.ptr, arr.ptr + arr.length); }
    ~this();

    ref vector opAssign(ref const(vector) s);

    // Iterators
//    iterator begin() @trusted @nogc;
//    const_iterator begin() const @trusted @nogc;
//    const_iterator cbegin() const @trusted @nogc;
//    iterator end() @trusted @nogc;
//    const_iterator end() const @trusted @nogc;
//    const_iterator cend() const @trusted @nogc;

    // no reverse iterator for now.

    // MSVC allocates on default initialisation in debug, which can't be modelled by D `struct`
    @disable this();

    // Capacity
    size_type max_size() const nothrow @trusted @nogc;

    void clear() nothrow;
    void resize(size_type n);
    void resize(size_type n, T c);
    void reserve(size_type n = 0) @trusted @nogc;
    void shrink_to_fit();

    // Element access
    extern(D) reference front() @safe @nogc                                                         { return as_array()[0]; }
    extern(D) const_reference front() const @safe @nogc                                             { return as_array()[0]; }
    extern(D) reference back() @safe @nogc                                                          { return as_array()[size()-1]; }
    extern(D) const_reference back() const @safe @nogc                                              { return as_array()[size()-1]; }

    // Modifiers
    void push_back(ref const(T) _);
    extern(D) void push_back(const(T) el) { push_back(el); } // forwards to ref version

    void pop_back();

    // D helpers
    extern(D) size_type opDollar(size_t pos)() const nothrow @safe @nogc                            { static assert(pos == 0, "std::vector is one-dimensional"); return size(); }

    version(CRuntime_Microsoft)
    {
        // perf will be greatly improved by inlining the primitive access functions
        extern(D) size_type size() const nothrow @safe @nogc                        { return _Get_data()._Mylast - _Get_data()._Myfirst; }
        extern(D) size_type capacity() const nothrow @safe @nogc                    { return _Get_data()._Myend - _Get_data()._Myfirst; }
        extern(D) bool empty() const nothrow @safe @nogc                            { return _Get_data()._Myfirst == _Get_data()._Mylast; }

        extern(D)        T* data() nothrow @safe @nogc                              { return _Get_data()._Myfirst; }
        extern(D) const(T)* data() const nothrow @safe @nogc                        { return _Get_data()._Myfirst; }

        extern(D) ref        T at(size_type i) @trusted @nogc                       { if (size() <= i) _Xran(); return _Get_data()._Myfirst[i]; }
        extern(D) ref const(T) at(size_type i) const @trusted @nogc                 { if (size() <= i) _Xran(); return _Get_data()._Myfirst[i]; }

        extern(D)        T[] as_array() nothrow @trusted @nogc                      { return _Get_data()._Myfirst[0 .. size()]; }
        extern(D) const(T)[] as_array() const nothrow @trusted @nogc                { return _Get_data()._Myfirst[0 .. size()]; }

        extern(D) this(this)
        {
            // we meed a compatible postblit
            static if (_ITERATOR_DEBUG_LEVEL > 0)
            {
                _Base._Alloc_proxy();
            }

            size_t len = size(); // the alloc len should probably keep a few in excess? (check the MS implementation)
            pointer newAlloc = _Getal().allocate(len);

            newAlloc[0 .. len] = _Get_data()._Myfirst[0 .. len];

            _Get_data()._Myfirst = newAlloc;
            _Get_data()._Mylast = newAlloc + len;
            _Get_data()._Myend = newAlloc + len;
        }

    private:
        import core.stdcpp.utility : _Xlength_error, _Xout_of_range;

        pragma(inline, true) 
        {
            extern (D) ref _Base.Alloc _Getal() nothrow @safe @nogc                 { return _Base._Mypair._Myval1; }
            extern (D) ref inout(_Base.ValTy) _Get_data() inout nothrow @safe @nogc { return _Base._Mypair._Myval2; }
        }

        extern(D) void _Xlen() const @trusted @nogc                                 { _Xlength_error("vector!T too long"); }
        extern(D) void _Xran() const @trusted @nogc                                 { _Xout_of_range("invalid vector!T subscript"); }

        _Vector_alloc!(_Vec_base_types!(T, Alloc)) _Base;

        // extern to functions that we are sure will be instantiated
//        void _Destroy(pointer _First, pointer _Last) nothrow @trusted @nogc;
//        size_type _Grow_to(size_type _Count) const nothrow @trusted @nogc;
//        void _Reallocate(size_type _Count) nothrow @trusted @nogc;
//        void _Reserve(size_type _Count) nothrow @trusted @nogc;
//        void _Tidy() nothrow @trusted @nogc;
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
    extern (C++, struct) struct _Vec_base_types(_Ty, _Alloc0)
    {
        alias Ty = _Ty;
        alias Alloc = _Alloc0;
    }

    extern (C++, class) struct _Vector_alloc(_Alloc_types)
    {
        import core.stdcpp.utility : _Compressed_pair;

        alias Ty = _Alloc_types.Ty;
        alias Alloc = _Alloc_types.Alloc;
        alias ValTy = _Vector_val!Ty;

        void _Orphan_all() nothrow @trusted @nogc;

        static if (_ITERATOR_DEBUG_LEVEL > 0)
        {
            void _Alloc_proxy() nothrow @trusted @nogc;
            void _Free_proxy() nothrow @trusted @nogc;
        }

        _Compressed_pair!(Alloc, ValTy) _Mypair;
    }

    extern (C++, class) struct _Vector_val(T)
    {
        import core.stdcpp.utility : _Container_base;
        import core.stdcpp.type_traits : is_empty;

        static if (!is_empty!_Container_base.value)
        {
            _Container_base _Base;
        }

        T* _Myfirst;   // pointer to beginning of array
        T* _Mylast;    // pointer to current end of sequence
        T* _Myend;     // pointer to end of array
    }
}
