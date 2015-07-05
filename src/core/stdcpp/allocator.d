/**
 * D header file for interaction with C++ std::allocator.
 *
 * Copyright: Copyright Guillaume Chatelet 2014 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 * Source:    $(DRUNTIMESRC core/stdcpp/allocator.d)
 */

module core.stdcpp.allocator;

extern(C++, std):

/**
 * Allocators are classes that define memory models to be used by some parts of
 * the C++ Standard Library, and most specifically, by STL containers.
 */
struct allocator(T) { }
