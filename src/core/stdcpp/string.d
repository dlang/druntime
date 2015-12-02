/**
 * D header file for interaction with C++ std::string.
 *
 * Copyright: Copyright Guillaume Chatelet 2014 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 * Source:    $(DRUNTIMESRC core/stdcpp/string.d)
 */

module core.stdcpp.string;

/**
 * Because of broken name mangling of extern C++, this file is only available
 * for Linux platform right now. Name mangling is hardcoded with pragmas.
 */
version(linux):
pragma(lib, "stdc++");

///////////////////////////////////////////////////////////////////////////////
// std::string declaration.
//
// Current caveats :
// - manual name mangling (=> only string is functionnal, wstring won't work)
//   https://issues.dlang.org/show_bug.cgi?id=14086
//   https://issues.dlang.org/show_bug.cgi?id=14178
// - won't work with custom allocators.
// - iterators are implemented as pointers
// - no reverse_iterator nor rbegin/rend
// - missing functions : replace, swap
///////////////////////////////////////////////////////////////////////////////

import core.stdcpp.allocator;

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
struct basic_string(T, TRAITS = char_traits!T, ALLOC = allocator!T)
{
    enum size_t npos = size_t.max;

    alias value_type = T;
    alias traits_type = TRAITS;
    alias allocator_type = ALLOC;
    alias reference = ref T;
    alias const_reference = ref const(T);
    alias pointer = T*;
    alias const_pointer = const(T*);
    alias iterator = pointer;
    alias const_iterator = const_pointer;
    // alias reverse_iterator
    // alias const_reverse_iterator
    alias difference_type = ptrdiff_t;
    alias size_type = size_t;

    // Ctor/dtor
    pragma(mangle, "_ZNSsC1Ev")
    @disable this();

    pragma(mangle, "_ZNSsC1ERKSs")
    this(ref const this);

    pragma(mangle, "_ZNSsC1EPKcRKSaIcE")
    this(const(T*) _, ref const allocator_type _ = defaultAlloc);

    pragma(mangle, "_ZNSsD1Ev")
    ~this();

    pragma(mangle, "_ZNSsaSERKSs")
    ref basic_string opAssign(ref const basic_string s);

    // Iterators
    pragma(mangle, "_ZNSs5beginEv")
    iterator begin() nothrow;

    pragma(mangle, "_ZNKSs5beginEv")
    const_iterator begin() nothrow const;

    pragma(mangle, "_ZNKSs6cbeginEv")
    const_iterator cbegin() nothrow const;

    pragma(mangle, "_ZNSs3endEv")
    iterator end() nothrow;

    pragma(mangle, "_ZNKSs3endEv")
    const_iterator end() nothrow const;

    pragma(mangle, "_ZNKSs4cendEv")
    const_iterator cend() nothrow const;

    // no reverse iterator for now.

    // Capacity
    pragma(mangle, "_ZNKSs4sizeEv")
    size_t size() nothrow const;

    pragma(mangle, "_ZNKSs6lengthEv")
    size_t length() nothrow const;

    pragma(mangle, "_ZNKSs8max_sizeEv")
    size_t max_size() nothrow const;

    pragma(mangle, "_ZNKSs8capacityEv")
    size_t capacity() nothrow const;

    pragma(mangle, "_ZNKSs5emptyEv")
    bool empty() nothrow const;

    pragma(mangle, "_ZNSs5clearEv")
    void clear() nothrow;

    pragma(mangle, "_ZNSs6resizeEm")
    void resize(size_t n);

    pragma(mangle, "_ZNSs6resizeEmc")
    void resize(size_t n, T c);

    pragma(mangle, "_ZNSs7reserveEm")
    void reserve(size_t n = 0);

    pragma(mangle, "_ZNSs13shrink_to_fitEv")
    void shrink_to_fit();

    // Element access
    pragma(mangle, "_ZNSsixEm")
    ref T opIndex(size_t i);

    pragma(mangle, "_ZNKSsixEm")
    ref const(T) opIndex(size_t i) const;

    pragma(mangle, "_ZNSs2atEm")
    ref T at(size_t i);

    pragma(mangle, "_ZNKSs2atEm")
    ref const(T) at(size_t i) const;

    pragma(mangle, "_ZNSs4backEv")
    ref T back();

    pragma(mangle, "_ZNKSs4backEv")
    ref const(T) back() const;

    pragma(mangle, "_ZNSs5frontEv")
    ref T front();

    pragma(mangle, "_ZNKSs5frontEv")
    ref const(T) front() const;

    // Modifiers
    pragma(mangle, "_ZNSspLERKSs")
    ref basic_string opOpAssign(string op)(ref const basic_string _) if (op == "+");

    pragma(mangle, "_ZNSspLEPKc")
    ref basic_string opOpAssign(string op)(const(T*) _) if (op == "+");

    pragma(mangle, "_ZNSspLEc")
    ref basic_string opOpAssign(string op)(T _) if (op == "+");

    pragma(mangle, "_ZNSs6appendEmc")
    ref basic_string append(size_t n, char c);

    pragma(mangle, "_ZNSs6appendEPKc")
    ref basic_string append(const char* s);

    pragma(mangle, "_ZNSs6appendEPKcm")
    ref basic_string append(const char* s, size_t n);

    pragma(mangle, "_ZNSs6appendERKSs")
    ref basic_string append(ref const basic_string str);

    pragma(mangle, "_ZNSs6appendERKSsmm")
    ref basic_string append(ref const basic_string str, size_t subpos, size_t sublen);

    pragma(mangle, "_ZNSs9push_backEc")
    void push_back(T c);

    pragma(mangle, "_ZNSs6assignEmc")
    ref basic_string assign(size_t n, char c);

    pragma(mangle, "_ZNSs6assignEPKc")
    ref basic_string assign(const char* s);

    pragma(mangle, "_ZNSs6assignEPKcm")
    ref basic_string assign(const char* s, size_t n);

    pragma(mangle, "_ZNSs6assignERKSs")
    ref basic_string assign(ref const basic_string str);

    pragma(mangle, "_ZNSs6assignERKSsmm")
    ref basic_string assign(ref const basic_string str, size_t subpos, size_t sublen);

    pragma(mangle, "_ZNSs6insertEmRKSs")
    ref basic_string insert (size_t pos, ref const basic_string str);

    pragma(mangle, "_ZNSs6insertEmRKSsmm")
    ref basic_string insert (size_t pos, ref const basic_string str, size_t subpos, size_t sublen);

    pragma(mangle, "_ZNSs6insertEmPKc")
    ref basic_string insert (size_t pos, const char* s);

    pragma(mangle, "_ZNSs6insertEmPKcm")
    ref basic_string insert (size_t pos, const char* s, size_t n);

    pragma(mangle, "_ZNSs6insertEmmc")
    ref basic_string insert (size_t pos, size_t n, char c);

    pragma(mangle, "_ZNSs5eraseEmm")
    ref basic_string erase(size_t pos = 0, size_t len = npos);

    // replace
    // swap
    pragma(mangle, "_ZNSs8pop_backEv")
    void pop_back();

    // String operations
    pragma(mangle, "_ZNKSs5c_strEv")
    const(T*) c_str() nothrow const;

    pragma(mangle, "_ZNKSs4dataEv")
    const(T*) data() nothrow const;

    pragma(mangle, "_ZNKSs4copyEPcmm")
    size_t copy(T* s, size_t len, size_t pos = 0) const;

    pragma(mangle, "_ZNKSs4findERKSsm")
    size_t find(ref const basic_string str, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs4findEPKcm")
    size_t find(const(T*) s, size_t pos = 0) const;

    pragma(mangle, "_ZNKSs4findEPKcmm")
    size_t find(const(T*) s, size_t pos, size_type n) const;

    pragma(mangle, "_ZNKSs4findEcm")
    size_t find(T c, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs5rfindERKSsm")
    size_t rfind(ref const basic_string str, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs5rfindEPKcm")
    size_t rfind(const(T*) s, size_t pos = npos) const;

    pragma(mangle, "_ZNKSs5rfindEPKcmm")
    size_t rfind(const(T*) s, size_t pos, size_t n) const;

    pragma(mangle, "_ZNKSs5rfindEcm")
    size_t rfind(T c, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs13find_first_ofERKSsm")
    size_t find_first_of(ref const basic_string str, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs13find_first_ofEPKcm")
    size_t find_first_of(const(T*) s, size_t pos = 0) const;

    pragma(mangle, "_ZNKSs13find_first_ofEPKcmm")
    size_t find_first_of(const(T*) s, size_t pos, size_t n) const;

    pragma(mangle, "_ZNKSs13find_first_ofEcm")
    size_t find_first_of(T c, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs12find_last_ofERKSsm")
    size_t find_last_of(ref const basic_string str, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs12find_last_ofEPKcm")
    size_t find_last_of(const(T*) s, size_t pos = npos) const;

    pragma(mangle, "_ZNKSs12find_last_ofEPKcmm")
    size_t find_last_of(const(T*) s, size_t pos, size_t n) const;

    pragma(mangle, "_ZNKSs12find_last_ofEcm")
    size_t find_last_of(T c, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs17find_first_not_ofERKSsm")
    size_t find_first_not_of(ref const basic_string str, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs17find_first_not_ofEPKcm")
    size_t find_first_not_of(const(T*) s, size_t pos = 0) const;

    pragma(mangle, "_ZNKSs17find_first_not_ofEPKcmm")
    size_t find_first_not_of(const(T*) s, size_t pos, size_t n) const;

    pragma(mangle, "_ZNKSs17find_first_not_ofEcm")
    size_t find_first_not_of(T c, size_t pos = 0) nothrow const;

    pragma(mangle, "_ZNKSs16find_last_not_ofERKSsm")
    size_t find_last_not_of(ref const basic_string str, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs16find_last_not_ofEPKcm")
    size_t find_last_not_of(const(T*) s, size_t pos = npos) const;

    pragma(mangle, "_ZNKSs16find_last_not_ofEPKcmm")
    size_t find_last_not_of(const(T*) s, size_t pos, size_t n) const;

    pragma(mangle, "_ZNKSs16find_last_not_ofEcm")
    size_t find_last_not_of(T c, size_t pos = npos) nothrow const;

    pragma(mangle, "_ZNKSs6substrEmm")
    basic_string substr(size_t pos = 0, size_t len = npos) const;

    pragma(mangle, "_ZNKSs7compareERKSs")
    int compare(ref const basic_string str) nothrow const;

    pragma(mangle, "_ZNKSs7compareEmmRKSs")
    int compare(size_t pos, size_t len, ref const basic_string str) const;

    pragma(mangle, "_ZNKSs7compareEmmRKSsmm")
    int compare(size_t pos, size_t len, ref const basic_string str, size_t subpos, size_t sublen) const;

    pragma(mangle, "_ZNKSs7compareEPKc")
    int compare(const(T*) s) const;

    pragma(mangle, "_ZNKSs7compareEmmPKc")
    int compare(size_t pos, size_t len, const(T*) s) const;

    pragma(mangle, "_ZNKSs7compareEmmPKcm")
    int compare(size_t pos, size_t len, const(T*) s, size_t n) const;

    // D helpers
    const(T[]) asArray() const { return c_str()[0 .. size()]; }

private:
    void[8] _ = void; // to match sizeof(std::string) and pad the object correctly.
    __gshared static immutable allocator!T defaultAlloc;
}

alias basic_string!char std_string;
alias basic_string!wchar std_wstring;
