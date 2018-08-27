/**
 * D header file for interaction with C++ std::allocator.
 *
 * Copyright: Copyright Guillaume Chatelet 2014 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/allocator.d)
 */

module core.stdcpp.allocator;

alias allocator = std.allocator;

extern(C++, std):

/**
 * Allocators are classes that define memory models to be used by some parts of
 * the C++ Standard Library, and most specifically, by STL containers.
 */
extern(C++, class) struct allocator(T)
{
    static assert(!is(T == const), "The C++ Standard forbids containers of const elements because allocator!(const T) is ill-formed.");

    alias value_type = T;

    alias pointer = value_type*;
    alias const_pointer = const value_type*;

    alias reference = ref value_type;
    alias const_reference = ref const(value_type);

    alias size_type = size_t;
    alias difference_type = ptrdiff_t;

    extern(D) size_t max_size() const nothrow @safe @nogc { return size_t.max / T.sizeof; }

    // these need to be defined locally to work on local types...
    extern(D) void construct(Ty, Args...)(Ty* ptr, auto ref Args args)
    {
        // placement new...
        assert(false, "TODO: can't use emplace, cus it's in phobos...");
    }

    extern(D) void destroy(Ty)(Ty* ptr)
    {
        import object : destroy;
        ptr.destroy(); // TODO: use `destruct` instead of destroy, which should exist in the future...
    }


    // platform specific detail
    version(CRuntime_Microsoft)
    {
        extern(D) void deallocate(pointer ptr, size_type count) nothrow @safe @nogc     { _Deallocate(ptr, count, T.sizeof); }
        extern(D) pointer allocate(size_type count) nothrow @trusted @nogc              { return cast(pointer)_Allocate(count, T.sizeof); }
        extern(D) pointer allocate(size_type count, const(void)*) nothrow @safe @nogc   { return allocate(count); }
    }
    else
    {
        void deallocate(pointer ptr, size_type count) nothrow @trusted @nogc;
        pointer allocate(size_type count) nothrow @trusted @nogc;
        pointer allocate(size_type count, const(void)*) nothrow @trusted @nogc;
    }
}


// platform detail
version(CRuntime_Microsoft)
{
    void* _Allocate(size_t _Count, size_t _Sz, bool _Try_aligned_allocation = true) nothrow @trusted @nogc;
    void _Deallocate(void* _Ptr, size_t _Count, size_t _Sz) nothrow @trusted @nogc;
}
