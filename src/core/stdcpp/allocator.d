/**
 * D header file for interaction with C++ std::allocator.
 *
 * Copyright: Copyright (c) 2018 D Language Foundation
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/allocator.d)
 */

module core.stdcpp.allocator;

extern(C++, "std"):

/**
 * Allocators are classes that define memory models to be used by some parts of
 * the C++ Standard Library, and most specifically, by STL containers.
 */
extern(C++, class) struct allocator(T)
{
    static assert(!is(T == const), "The C++ Standard forbids containers of const elements because allocator!(const T) is ill-formed.");
    static assert(!is(T == immutable), "immutable is not representable in C++");

    alias value_type = T;

    version (CppRuntime_Microsoft)
    {
        T* allocate(size_t count) nothrow @nogc;
        // HACK: workaround to make `deallocate` link as a `T * const`
        extern (D) private static string constHack(string name)
        {
            version (Win64)
                enum sub = "AAXPE";
            else
                enum sub = "AEXPA";
            foreach (i; 0 .. name.length - sub.length)
                if (name[i .. i + sub.length] == sub[])
                    return name[0 .. i + 3] ~ 'Q' ~ name[i + 4 .. $];
            assert(false, "substitution string not found!");
        }
        pragma(mangle, constHack(deallocate.mangleof))
        void deallocate(T* ptr, size_t count) nothrow @nogc;
    }
    else
    {
        T* allocate(size_t count, const(void)* = null) nothrow @nogc;
        void deallocate(T* ptr, size_t count) nothrow @nogc;
    }

    extern (D) T[] allocArray(size_t count) nothrow @nogc   { return allocate(count)[0 .. count]; }
    extern (D) void deallocArray(ref T[] array) nothrow @nogc   { deallocate(array.ptr, array.length); }
}
