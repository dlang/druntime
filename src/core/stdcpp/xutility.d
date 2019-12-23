/**
 * D header file for interaction with Microsoft C++ <xutility>
 *
 * Copyright: Copyright (c) 2018 D Language Foundation
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/xutility.d)
 */

module core.stdcpp.xutility;

@nogc:

version (CppRuntime_Clang)
{
    import core.internal.traits : AliasSeq;
    enum StdNamespace = AliasSeq!("std", "__1");
}
else
{
    enum StdNamespace = "std";
}

enum CppStdRevision : uint
{
    cpp98 = 199711,
    cpp11 = 201103,
    cpp14 = 201402,
    cpp17 = 201703
}

enum __cplusplus = __traits(getTargetInfo, "cppStd");

// wrangle C++ features
enum __cpp_sized_deallocation = __cplusplus >= CppStdRevision.cpp14 || is(typeof(_MSC_VER)) ? 201309 : 0;
enum __cpp_aligned_new = __cplusplus >= CppStdRevision.cpp17 ? 201606 : 0;


version (CppRuntime_Microsoft)
{
    import core.stdcpp.type_traits : is_empty;

    version (_MSC_VER_1200)
        enum _MSC_VER = 1200;
    else version (_MSC_VER_1300)
        enum _MSC_VER = 1300;
    else version (_MSC_VER_1310)
        enum _MSC_VER = 1310;
    else version (_MSC_VER_1400)
        enum _MSC_VER = 1400;
    else version (_MSC_VER_1500)
        enum _MSC_VER = 1500;
    else version (_MSC_VER_1600)
        enum _MSC_VER = 1600;
    else version (_MSC_VER_1700)
        enum _MSC_VER = 1700;
    else version (_MSC_VER_1800)
        enum _MSC_VER = 1800;
    else version (_MSC_VER_1900)
        enum _MSC_VER = 1900;
    else version (_MSC_VER_1910)
        enum _MSC_VER = 1910;
    else version (_MSC_VER_1911)
        enum _MSC_VER = 1911;
    else version (_MSC_VER_1912)
        enum _MSC_VER = 1912;
    else version (_MSC_VER_1913)
        enum _MSC_VER = 1913;
    else version (_MSC_VER_1914)
        enum _MSC_VER = 1914;
    else version (_MSC_VER_1915)
        enum _MSC_VER = 1915;
    else version (_MSC_VER_1916)
        enum _MSC_VER = 1916;
    else version (_MSC_VER_1920)
        enum _MSC_VER = 1920;
    else version (_MSC_VER_1921)
        enum _MSC_VER = 1921;
    else version (_MSC_VER_1922)
        enum _MSC_VER = 1922;
    else version (_MSC_VER_1923)
        enum _MSC_VER = 1923;
    else
        enum _MSC_VER = 1923; // assume most recent compiler version

    // Client code can mixin the set of MSVC linker directives
    mixin template MSVCLinkDirectives(bool failMismatch = false)
    {
        import core.stdcpp.xutility : __CXXLIB__, _ITERATOR_DEBUG_LEVEL;

        static if (__CXXLIB__ == "libcmtd")
        {
            pragma(lib, "libcpmtd");
            static if (failMismatch)
                pragma(linkerDirective, "/FAILIFMISMATCH:RuntimeLibrary=MTd_StaticDebug");
        }
        else static if (__CXXLIB__ == "msvcrtd")
        {
            pragma(lib, "msvcprtd");
            static if (failMismatch)
                pragma(linkerDirective, "/FAILIFMISMATCH:RuntimeLibrary=MDd_DynamicDebug");
        }
        else static if (__CXXLIB__ == "libcmt")
        {
            pragma(lib, "libcpmt");
            static if (failMismatch)
                pragma(linkerDirective, "/FAILIFMISMATCH:RuntimeLibrary=MT_StaticRelease");
        }
        else static if (__CXXLIB__ == "msvcrt")
        {
            pragma(lib, "msvcprt");
            static if (failMismatch)
                pragma(linkerDirective, "/FAILIFMISMATCH:RuntimeLibrary=MD_DynamicRelease");
        }
        static if (failMismatch)
            pragma(linkerDirective, "/FAILIFMISMATCH:_ITERATOR_DEBUG_LEVEL=" ~ ('0' + _ITERATOR_DEBUG_LEVEL));
    }

    // HACK: should we guess _DEBUG for `debug` builds?
    version (NDEBUG) {}
    else debug version = _DEBUG;

    // By specific user request
    version (_ITERATOR_DEBUG_LEVEL_0)
        enum _ITERATOR_DEBUG_LEVEL = 0;
    else version (_ITERATOR_DEBUG_LEVEL_1)
        enum _ITERATOR_DEBUG_LEVEL = 1;
    else version (_ITERATOR_DEBUG_LEVEL_2)
        enum _ITERATOR_DEBUG_LEVEL = 2;
    else
    {
        // Match the C Runtime
        static if (__CXXLIB__ == "libcmtd" || __CXXLIB__ == "msvcrtd")
            enum _ITERATOR_DEBUG_LEVEL = 2;
        else static if (__CXXLIB__ == "libcmt" || __CXXLIB__ == "msvcrt" || __CXXLIB__ == "msvcrt100")
            enum _ITERATOR_DEBUG_LEVEL = 0;
        else
        {
            static if (__CXXLIB__.length > 0)
                pragma(msg, "Unrecognised C++ runtime library '" ~ __CXXLIB__ ~ "'");

            // No runtime specified; as a best-guess, -release will produce code that matches the MSVC release CRT
            version (_DEBUG)
                enum _ITERATOR_DEBUG_LEVEL = 2;
            else
                enum _ITERATOR_DEBUG_LEVEL = 0;
        }
    }

    // convenient alias for the C++ std library name
    enum __CXXLIB__ = __traits(getTargetInfo, "cppRuntimeLibrary");

extern(C++, "std"):
package:
    enum _LOCK_DEBUG = 3;

    extern(C++, class) struct _Lockit
    {
        this(int) nothrow @nogc @safe;
        ~this() nothrow @nogc @safe;

    private:
        int _Locktype;
    }
    void dummyDtor() { assert(false); }
    pragma(linkerDirective, "/ALTERNATENAME:" ~ _Lockit.__dtor.mangleof ~ "=" ~ dummyDtor.mangleof);

    struct _Container_base0
    {
    extern(D):
        void _Orphan_all()() nothrow @nogc @safe {}
        void _Swap_all()(ref _Container_base0) nothrow @nogc @safe {}
    }
    struct _Iterator_base0
    {
    extern(D):
        void _Adopt()(const(void)*) nothrow @nogc @safe {}
        const(_Container_base0)* _Getcont()() const nothrow @nogc @safe { return null; }

        enum bool _Unwrap_when_unverified = true;
    }

    struct _Container_proxy
    {
        const(_Container_base12)* _Mycont;
        _Iterator_base12* _Myfirstiter;
    }

    struct _Container_base12
    {
    extern(D):
        inout(_Iterator_base12*)*_Getpfirst()() inout nothrow @nogc @safe
        {
            return _Myproxy == null ? null : &_Myproxy._Myfirstiter;
        }
        void _Orphan_all()() nothrow @nogc @safe
        {
            static if (_ITERATOR_DEBUG_LEVEL == 2)
            {
                if (_Myproxy != null)
                {
                    auto _Lock = _Lockit(_LOCK_DEBUG);
                    for (_Iterator_base12 **_Pnext = &_Myproxy._Myfirstiter; *_Pnext != null; *_Pnext = (*_Pnext)._Mynextiter)
                        (*_Pnext)._Myproxy = null;
                    _Myproxy._Myfirstiter = null;
                }
            }
        }
//        void _Swap_all()(ref _Container_base12) nothrow @nogc;

        _Container_proxy* _Myproxy;
    }

    struct _Iterator_base12
    {
    extern(D):
        void _Adopt()(_Container_base12 *_Parent) nothrow @nogc @safe
        {
            if (_Parent == null)
            {
                static if (_ITERATOR_DEBUG_LEVEL == 2)
                {
                    auto _Lock = _Lockit(_LOCK_DEBUG);
                    _Orphan_me();
                }
            }
            else
            {
                _Container_proxy *_Parent_proxy = _Parent._Myproxy;

                static if (_ITERATOR_DEBUG_LEVEL == 2)
                {
                    if (_Myproxy != _Parent_proxy)
                    {
                        auto _Lock = _Lockit(_LOCK_DEBUG);
                        _Orphan_me();
                        _Mynextiter = _Parent_proxy._Myfirstiter;
                        _Parent_proxy._Myfirstiter = &this;
                        _Myproxy = _Parent_proxy;
                    }
                }
                else
                    _Myproxy = _Parent_proxy;
            }
        }
        void _Clrcont()() nothrow @nogc @safe
        {
            _Myproxy = null;
        }
        const(_Container_base12)* _Getcont()() const nothrow @nogc @safe
        {
            return _Myproxy == null ? null : _Myproxy._Mycont;
        }
        inout(_Iterator_base12*)*_Getpnext()() inout nothrow @nogc @safe
        {
            return &_Mynextiter;
        }
        void _Orphan_me()() nothrow @nogc @safe
        {
            static if (_ITERATOR_DEBUG_LEVEL == 2)
            {
                if (_Myproxy != null)
                {
                    _Iterator_base12 **_Pnext = &_Myproxy._Myfirstiter;
                    while (*_Pnext != null && *_Pnext != &this)
                        _Pnext = &(*_Pnext)._Mynextiter;
                    assert(*_Pnext, "ITERATOR LIST CORRUPTED!");
                    *_Pnext = _Mynextiter;
                    _Myproxy = null;
                }
            }
        }

        enum bool _Unwrap_when_unverified = _ITERATOR_DEBUG_LEVEL == 0;

        _Container_proxy *_Myproxy;
        _Iterator_base12 *_Mynextiter;
    }

    static if (_ITERATOR_DEBUG_LEVEL == 0)
    {
        alias _Container_base = _Container_base0;
        alias _Iterator_base = _Iterator_base0;
    }
    else
    {
        alias _Container_base = _Container_base12;
        alias _Iterator_base = _Iterator_base12;
    }

    extern (C++, class) struct _Compressed_pair(_Ty1, _Ty2, bool Ty1Empty = is_empty!_Ty1.value)
    {
    pragma (inline, true):
    extern(D):
    pure nothrow @nogc:
        enum _HasFirst = !Ty1Empty;

        ref inout(_Ty1) first() inout @safe { return _Myval1; }
        ref inout(_Ty2) second() inout @safe { return _Myval2; }

        static if (!Ty1Empty)
            _Ty1 _Myval1;
        else
        {
            @property ref inout(_Ty1) _Myval1() inout @trusted { return *_GetBase(); }
            private inout(_Ty1)* _GetBase() inout @trusted { return cast(inout(_Ty1)*)&this; }
        }
        _Ty2 _Myval2;
    }

    // these are all [[noreturn]]
    void _Xbad_alloc() nothrow;
    void _Xinvalid_argument(const(char)* message) nothrow;
    void _Xlength_error(const(char)* message) nothrow;
    void _Xout_of_range(const(char)* message) nothrow;
    void _Xoverflow_error(const(char)* message) nothrow;
    void _Xruntime_error(const(char)* message) nothrow;
}
else version (CppRuntime_Clang)
{
    import core.stdcpp.type_traits : is_empty;

extern(C++, (StdNamespace)):

    extern (C++, class) struct __compressed_pair(_T1, _T2)
    {
    pragma (inline, true):
    extern(D):
        enum Ty1Empty = is_empty!_T1.value;
        enum Ty2Empty = is_empty!_T2.value;

        ref inout(_T1) first() inout nothrow @safe @nogc { return __value1_; }
        ref inout(_T2) second() inout nothrow @safe @nogc { return __value2_; }

    private:
        private inout(_T1)* __get_base1() inout { return cast(inout(_T1)*)&this; }
        private inout(_T2)* __get_base2() inout { return cast(inout(_T2)*)&__get_base1()[Ty1Empty ? 0 : 1]; }

        static if (!Ty1Empty)
            _T1 __value1_;
        else
            @property ref inout(_T1) __value1_() inout nothrow @trusted @nogc { return *__get_base1(); }
        static if (!Ty2Empty)
            _T2 __value2_;
        else
            @property ref inout(_T2) __value2_() inout nothrow @trusted @nogc { return *__get_base2(); }
    }

    struct __split_buffer(T, Allocator = allocator!T)
    {
        import core.internal.traits : isPointer, RemovePointer;
        import core.lifetime : emplace, forward, move, moveEmplace;
        import core.stdcpp.allocator : allocator_traits;

    pragma (inline, true):
    extern(D):

    public:
        alias value_type = T;
        alias allocator_type = Allocator;
        alias __alloc_rr = RemovePointer!allocator_type;
        alias __alloc_traits = allocator_traits!__alloc_rr;
        alias size_type = __alloc_traits.size_type;
        alias difference_type = __alloc_traits.difference_type;
        alias pointer = __alloc_traits.pointer;

        pointer __first_;
        pointer __begin_;
        pointer __end_;
        __compressed_pair!(pointer, allocator_type) __end_cap_;

        ref inout(__alloc_rr) __alloc() inout pure nothrow @nogc @safe
        {

            static if (isPointer!allocator_type)
                return *__end_cap_.second();
            else
                return __end_cap_.second();
        }

        ref inout(pointer) __end_cap() inout pure nothrow @nogc @safe
        {
            return __end_cap_.first();
        }

        this()(auto ref allocator_type __a)
        {
            emplace(&__end_cap_.second, forward!__a);
        }

        this(size_type __cap, size_type __start, ref __alloc_rr __a)
        {
            __first_ = __cap != 0 ? __alloc().allocate(__cap) : null;
            __begin_ = __end_ = __first_ + __start;
            __end_cap() = __first_ + __cap;
        }

        @disable this(this);

        ~this()
        {
            clear();
            if (__first_)
                __alloc().deallocate(__first_, capacity());
        }

        this()(auto ref __split_buffer __c)
        if (!__traits(isRef, __c))
        {
            __first_ = move(__c.__first_);
            __begin_ = move(__c.__begin_);
            __end_ = move(__c.__end_);
            __end_cap_ = move(__c.__end_cap_());
            __c.__first_ = null;
            __c.__begin_ = null;
            __c.__end_ = null;
            __c.__end_cap() = null;
        }

        this()(auto ref __split_buffer __c, auto ref allocator_type __a)
        if (!__traits(isRef, __c))
        {
            emplace( & __end_cap_.second, __a);
            if (__a == __c.__alloc())
            {
                __first_ = __c.__first_;
                __begin_ = __c.__begin_;
                __end_ = __c.__end_;
                __end_cap() = __c.__end_cap();
                __c.__first_ = null;
                __c.__begin_ = null;
                __c.__end_ = null;
                __c.__end_cap() = null;
            }
            else
            {
                size_type __cap = __c.size();
                __first_ = __alloc().allocate(__cap);
                __begin_ = __end_ = __first_;
                __end_cap() = __first_ + __cap;
                __construct_move_at_end(__c.__begin_[0 .. __c.size()]);
            }
        }

        ref __split_buffer opAssign()(auto ref __split_buffer __c)
        if (!__traits(isRef, __c))
        {
            clear();
            shrink_to_fit();
            __first_ = __c.__first_;
            __begin_ = __c.__begin_;
            __end_ = __c.__end_;
            __end_cap() = __c.__end_cap();
            enum __propagate = __alloc_traits.propagate_on_container_move_assignment;
            __move_assign_alloc!__propagate(__c);
            __c.__first_ = __c.__begin_ = __c.__end_ = __c.__end_cap() = null;
            return this;
        }

        void clear() { __destruct_at_end(__begin_); }

        size_type size() const pure nothrow @nogc @safe
        {
            return cast(size_type)(__end_ - __begin_);
        }

        bool empty() const pure nothrow @nogc @safe
        {
            return __end_ == __begin_;
        }

        size_type capacity() const pure nothrow @nogc @safe
        {
            return cast(size_type)(__end_cap() - __first_);
        }

        size_type __front_spare() const pure nothrow @nogc @safe
        {
            return cast(size_type)(__begin_ - __first_);
        }

        size_type __back_spare() const pure nothrow @nogc @safe
        {
            return cast(size_type)(__end_cap() - __end_);
        }

        ref inout(T) front() inout pure nothrow @nogc @safe
        {
            return *__begin_;
        }

        ref inout(T) back() inout pure nothrow @nogc @trusted
        {
            return *(__end_ - 1);
        }

        void reserve(size_type __n)
        {
            import core.internal.lifetime : swap;

            if (__n < capacity())
            {
                auto __t = __split_buffer!(value_type, __alloc_rr*)(__n, 0, __alloc());
                __t.__construct_move_at_end(__begin_[0 .. size()]);
                swap(__first_, __t.__first_);
                swap(__begin_, __t.__begin_);
                swap(__end_, __t.__end_);
                swap(__end_cap(), __t.__end_cap());
            }
        }

        void shrink_to_fit() nothrow
        {
            import core.internal.lifetime : swap;

            if (capacity() > size())
            {
                try
                {
                    auto __t = __split_buffer!(value_type, __alloc_rr*)(size(), 0, __alloc());
                    __t.__construct_move_at_end(__begin_[0 .. size()]);
                    __t.__end_ = __t.__begin_ + (__end_ - __begin_);
                    swap(__first_, __t.__first_);
                    swap(__begin_, __t.__begin_);
                    swap(__end_, __t.__end_);
                    swap(__end_cap(), __t.__end_cap());
                }
                catch (Throwable e)
                {
                }
            }
        }

        void push_front()(auto ref T __x)
        {
            import core.internal.lifetime : swap;

            if (__begin_ == __first_)
            {
                if (__end_ < __end_cap())
                {
                    difference_type __d = __end_cap() - __end_;
                    __d = (__d + 1) / 2;
                    foreach_reverse (__i, ref __e; __begin_[0 .. size()])
                        move(__e, __begin_[__d + __i]);
                    __begin_ += __d;
                    __end_ += __d;
                }
                else
                {
                    size_type __c = max!size_type(2 * cast(size_t)(__end_cap() - __first_), 1);
                    auto __t = __split_buffer!(value_type, __alloc_rr*)(__c, (__c + 3) / 4, __alloc());
                    __t.__construct_move_at_end(__begin_[0 .. size()]);
                    swap(__first_, __t.__first_);
                    swap(__begin_, __t.__begin_);
                    swap(__end_, __t.__end_);
                    swap(__end_cap(), __t.__end_cap());
                }
            }
            static if (__traits(isRef, __x))
                emplace(__begin_ - 1, __x);
            else
                moveEmplace(__x,  * (__begin_ - 1));
            --__begin_;
        }

        void push_back()(auto ref T __x)
        {
            import core.internal.lifetime : swap;

            if (__end_ == __end_cap())
            {
                if (__begin_ > __first_)
                {
                    difference_type __d = __begin_ - __first_;
                    __d = (__d + 1) / 2;
                    foreach (__i, ref __e; __begin_[0 .. size()])
                        move(__e, (__begin_ - __d)[__i]);
                    __end_ -= __d;
                    __begin_ -= __d;
                }
                else
                {
                    size_type __c = max!size_type(2 * cast(size_t)(__end_cap() - __first_), 1);
                    auto __t = __split_buffer!(value_type, __alloc_rr*)(__c, __c / 4, __alloc());
                    __t.__construct_move_at_end(__begin_[0 .. size()]);
                    swap(__first_, __t.__first_);
                    swap(__begin_, __t.__begin_);
                    swap(__end_, __t.__end_);
                    swap(__end_cap(), __t.__end_cap());
                }
            }
            static if (__traits(isRef, __x))
                emplace(__end_, __x);
            else
                moveEmplace(__x,  * __end_);
            ++__end_;
        }

        void emplace_back(_Args...)(_Args __args)
        {
            import core.internal.lifetime : swap;

            if (__end_ == __end_cap())
            {
                if (__begin_ > __first_)
                {
                    difference_type __d = __begin_ - __first_;
                    __d = (__d + 1) / 2;
                    foreach (__i, ref __e; __begin_[0 .. size()])
                        move(__e, (__begin_ - __d)[__i]);
                    __end_ -= __d;
                    __begin_ -= __d;
                }
                else
                {
                    size_type __c = max!size_type(2 * cast(size_t)(__end_cap() - __first_), 1);
                    auto __t = __split_buffer!(value_type, __alloc_rr*)(__c, __c / 4, __alloc());
                    __t.__construct_move_at_end(__begin_[0 .. size()]);
                    swap(__first_, __t.__first_);
                    swap(__begin_, __t.__begin_);
                    swap(__end_, __t.__end_);
                    swap(__end_cap(), __t.__end_cap());
                }
            }
            emplace(__end_, forward!__args);
            ++__end_;
        }

        void pop_front() { __destruct_at_begin(__begin_ + 1); }

        void pop_back() { __destruct_at_end(__end_ - 1); }

        void __construct_at_end(size_type __n)
        {
            import core.internal.lifetime : emplaceInitializer;

            do
            {
                emplaceInitializer(*this.__end_);
                ++this.__end_;
                --__n;
            }
            while (__n > 0);
        }

        void __construct_at_end()(size_type __n, auto ref T __x)
        {
            do
            {
                emplace(this.__end_, __x);
                ++this.__end_;
                --__n;
            }
            while (__n > 0);
        }

        void __construct_at_end(T[] __array)
        {
            foreach (ref e; __array)
            {
                emplace(this.__end_, e);
                ++this.__end_;
            }
        }

        void __construct_move_at_end(T[] __array)
        {
            foreach (ref e; __array)
            {
                moveEmplace(e, *this.__end_);
                ++this.__end_;
            }
        }

        void __destruct_at_begin(pointer __new_begin)
        {
            import core.internal.traits : hasElaborateDestructor;

            static if (hasElaborateDestructor!value_type)
            {
                while (__begin_ != __new_begin)
                    destroy!false(*__begin_++);
            }
        }

        void __destruct_at_end(pointer __new_last)
        {
            while (__new_last != __end_)
                destroy!false(*--__end_);
        }

        void swap(ref __split_buffer __x)
        {
            import core.stdcpp.allocator : __swap_allocator;
            import core.internal.lifetime : swap;

            swap(__first_, __x.__first_);
            swap(__begin_, __x.__begin_);
            swap(__end_, __x.__end_);
            swap(__end_cap(), __x.__end_cap());
            __swap_allocator(__alloc(), __x.__alloc());
        }

        bool __invariants() const
        {
            if (__first_ == null)
            {
                if (__begin_ != null)
                    return false;
                if (__end_ != null)
                    return false;
                if (__end_cap() != null)
                    return false;
            }
            else
            {
                if (__begin_ < __first_)
                    return false;
                if (__end_ < __begin_)
                    return false;
                if (__end_cap() < __end_)
                    return false;
            }
            return true;
        }

    private:
        void __move_assign_alloc(bool __propagate : true)(ref __split_buffer __c)
        {
            __alloc() = move(__c.__alloc());
        }

        void __move_assign_alloc(bool __propagate : false)(ref __split_buffer) nothrow {}

        static max(T)(T a, T b) { return a > b ? a : b;}
    }

    struct __temp_value(T, Alloc)
    {
        import core.stdcpp.allocator : allocator_traits;

        alias _Traits = allocator_traits!Alloc;

        align(T.alignof) void[T.sizeof] __v;
        Alloc* __a;

        T* __addr() { return cast(T*)(&__v[0]); }
        ref T get() { return *__addr(); }

        this(Args...)(ref Alloc __alloc, auto ref Args __args)
        {
            import core.lifetime : emplace, forward;

            __a =  &__alloc;
            emplace(cast(T*)& __v[0], forward!__args);
        }

        ~this() { destroy!false(*__addr()); }
    }

    version (_LIBCPP_HAS_NO_ASAN)      enum _LIBCPP_HAS_NO_ASAN = true;
    else version (__SANITIZE_ADRESS__) enum _LIBCPP_HAS_NO_ASAN = false;
    else                               enum _LIBCPP_HAS_NO_ASAN = true;

    version (_LIBCPP_DEBUG_LEVEL)  enum _LIBCPP_DEBUG_LEVEL = 1;
    version (_LIBCPP_DEBUG_LEVEL2) enum _LIBCPP_DEBUG_LEVEL = 2;
    else                           enum _LIBCPP_DEBUG_LEVEL = 0;
}
