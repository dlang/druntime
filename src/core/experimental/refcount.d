// Written in the D programming language.
/**
This module provides a composable reference count implementation in the form
of `__RefCount`.

License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: Eduard Staniloiu

Source: $(DRUNTIMESRC core/experimental/refcount.d)
*/
module core.experimental.refcount;

/**
A qualified reference counted `struct` that is intended to be composed by
user-defined types that desire to implement manual memory management by means of
reference counting.

`__RefCount` was designed to be composed as a field inside a user-defined type.
The user is responsible to initialize the `__RefCount` in that type's constructors.
The user will call the `isUnique()` method to decide if this is the last
reference to the enclosing type so memory can be safely deallocated.

Implementation: The internal implementation of `__RefCount` uses `malloc`/`free`.

Important: The `__RefCount` member must be initialized through a call to its
constructor before being used.
*/
struct __RefCount
{
    import core.atomic : atomicOp;

    alias CounterType = uint;
    private shared CounterType* rc = null;

    /*
    Perform `rc op val` operation. Always use atomics as the counter is shared.

    Returns:
         The result of the operation.
    */
    @nogc nothrow pure @trusted scope
    private CounterType rcOp(this Q, string op)(CounterType val) const
    {
        return cast(CounterType)(atomicOp!op(*(cast(shared CounterType*) rc), val));
    }

    /**
    Creates a new `__RefCount` instance. Its memory is internally managed with
    malloc/free.

    Params:
         _ = an unused int value; required because structs don't have a
             user defined default constructor
    */
    @nogc nothrow pure @trusted scope
    this(this Q)(int _)
    {
        // We are required to always use a shared support as the result of a `pure`
        // function is implicitly convertible to `immutable`.

        shared CounterType* support = cast(shared CounterType*) pureAllocate(CounterType.sizeof);
        *support = 1; // Start with 1 to avoid calling an `addRef` from 0 to 1
        rc = cast(typeof(rc)) support;
    }

    private enum copyCtorIncRef = q{
        rc = rhs.rc;
        assert(rc == rhs.rc);
        if (rhs.isInitialized())
        {
            addRef();
        }
    };

    /**
    Copy constructs a mutable `__RefCount` from a mutable reference, `rhs`.
    This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope ref typeof(this) rhs)
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a `shared` mutable `__RefCount` from a `shared` mutable
    reference, `rhs`. This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope ref shared typeof(this) rhs) shared
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const __RefCount) from a mutable reference, `rhs`.
    This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const shared __RefCount) from a `shared` mutable
    reference, `rhs`. This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope ref shared typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const __RefCount) from a `const` reference, `rhs`.
    This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope const ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const shared __RefCount) from a $(B const shared)
    reference, `rhs`. This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope const shared ref typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const __RefCount) from an `immutable` reference, `rhs`.
    This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope immutable ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    /**
    Copy constructs a $(B const shared __RefCount) from an $(B immutable shared)
    reference, `rhs`. This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope immutable shared ref typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }


    /**
    Copy construct an $(B immutable __RefCount) from an `immutable` reference, `rhs`.
    This increases the reference count.
    */
    @nogc nothrow pure @safe scope
    this(return scope immutable ref typeof(this) rhs) immutable
    {
        mixin(copyCtorIncRef);
    }

    /**
    Assign a `__RefCount` object into this. This will decrement the old reference
    count before assigning the new one. If the old reference was the last one,
    this will trigger the deallocation of the old ref. This increases the
    reference count of `rhs`.

    Params:
         rhs = the `__RefCount` object to be assigned.

    Returns:
         A reference to `this`.

    Complexity:
         $(BIGOH 1).
    */
    @nogc nothrow pure @safe scope
    ref __RefCount opAssign(return scope ref typeof(this) rhs) return
    {
        if (rhs.isInitialized() && rc == rhs.rc)
        {
            return this;
        }
        if (rhs.isInitialized())
        {
            rhs.addRef();
        }
        if (isInitialized())
        {
            delRef();
        }
        () @trusted { rc = rhs.rc; }();
        return this;
    }

    ///
    @nogc nothrow pure @safe scope
    ref shared(__RefCount) opAssign(return scope shared ref typeof(this) rhs) return shared
    {
        if (rhs.isInitialized() && rc == rhs.rc)
        {
            return this;
        }
        if (rhs.isInitialized())
        {
            rhs.addRef();
        }
        if (isInitialized())
        {
            delRef();
        }
        () @trusted { rc = rhs.rc; }();
        return this;
    }

    /*
    Increase the reference count. This asserts that `__RefCount` is initialized.

    Returns:
         This returns a `void*` so the compiler won't optimize away the call
         to this `const pure` function.
    */
    @nogc nothrow pure @safe scope
    private void* addRef(this Q)() const
    {
        assert(isInitialized(), "[__RefCount.addRef] __RefCount is uninitialized");
        cast(void) rcOp!(Q, "+=")(1);
        return null;
    }

    /*
    Decrease the reference count. If this was the last reference, `free` the
    support. This asserts that `__RefCount` is initialized.

    Returns:
         This returns a `void*` so the compiler won't optimize away the call
         to this `const pure` function.
    */
    @nogc nothrow pure @trusted scope
    private void* delRef(this Q)() const
    {
        assert(isInitialized(), "[__RefCount.delRef] __RefCount is uninitialized");
        /*
         * This is an optimization. Most likely, most of the time, the refcount
         * is `1`, so we don't want to make more ops to update that value only
         * to free it afterwards. This is why we first check if the value is `1`.
         * The `or` part decrements and checks for `0` in the case that we had
         * two threads that both questioned at the same time if the value was `1`;
         * they both will decrement, but only one will have the final value `0`.
         */
        if (rcOp!(Q, "==")(1) || (rcOp!(Q, "-=")(1) == 0))
        {
            return deallocate();
        }
        return null;
    }

    /*
    `free` the support.

    Returns:
         This returns a $(B void*) so the compiler won't optimize away the call
         to this `const pure` function.
    */
    @nogc nothrow pure @system scope
    private void* deallocate(this Q)() const
    {
        return pureDeallocate((cast(CounterType*) rc)[0 .. 1]);
    }

    /**
    Destruct the `__RefCount`. If it's initialized, decrement the refcount.
    */
    @nogc nothrow pure @trusted scope
    ~this()
    {
        if (isInitialized())
        {
            delRef();
        }
    }

    /**
    Return a boolean value denoting if this is the only reference to this object.

    Returns:
         `true` if this reference count is unique; `false` if this `__RefCount`
         object is uninitialized or there are multiple references to it.

    Complexity:
         $(BIGOH 1).
    */
    pure nothrow @safe @nogc scope
    bool isUnique(this Q)() const
    {
        return isInitialized() && (!!rcOp!(Q, "==")(1));
    }

    /**
    Return a boolean value denoting if this `__RefCount` object is initialized.

    Returns:
         `true` if initialized; `false` otherwise

    Complexity:
         $(BIGOH 1).
    */
    pure nothrow @safe @nogc scope
    bool isInitialized(this Q)() const
    {
        return rc !is null;
    }

    version (CoreUnittest)
    {
        pure nothrow @nogc @trusted scope
        private bool isValueEq(this Q)(uint val) const
        {
            return *getUnsafeValue == val;
        }
    }

    /**
    Return a raw pointer to the underlying reference count pointer.
    This is unsafe and may lead to dangling pointers to invalid memory.

    Returns:
         A raw pointer to the reference count.

    Complexity:
         $(BIGOH 1).
    */
    pure nothrow @nogc @system
    const(CounterType*) getUnsafeValue(this Q)() const
    {
        return cast(CounterType*) rc;
    }

    /**
    A factory function that creates and returns a new instance of a qualified
    `__RefCount`.

    Params:
         QualifiedRefCount = a template parameter that is a qualified
         `__RefCount` type.

    Returns:
         A new instance of `QualifiedRefCount`.

    Complexity:
         $(BIGOH 1).
    */
    static pure nothrow @nogc @safe
    auto make(QualifiedRefCount)()
    {
        return QualifiedRefCount(1);
    }
}

///
@system @nogc nothrow
unittest
{
    import core.stdc.stdlib : free, malloc;

    struct rcarray
    {
        @nogc nothrow:

        private __RefCount rc;
        int[] payload;

        this(int sz)
        {
            rc = __RefCount.make!__RefCount();
            payload = (cast(int*) malloc(sz * int.sizeof))[0 .. sz];
        }

        void opAssign(ref rcarray rhs)
        {
            if (rc.isUnique)
            {
                // If this was the last reference to the payload,
                // we can safely free
                free(payload.ptr);
            }

            // This will update the reference count
            rc = rhs.rc;
            // Update the payload
            payload = rhs.payload;
        }

        /* Implement copy constructors */
        this(return scope ref typeof(this) rhs)
        {
            rc = rhs.rc;
            payload = rhs.payload;
        }

        ~this()
        {
            if (rc.isUnique)
            {
                // If this was the last reference to the payload,
                // we can safely free
                free(payload.ptr);
            }
        }
    }

    auto a = rcarray(42);
    assert(a.rc.isUnique);
    {
        auto a2 = a; // Construct a2 by copy construction
        assert(!a.rc.isUnique);
        auto a3 = rcarray(4242);
        a2 = a3; // Assign a3 into a2; a's ref count drops
        assert(a.rc.isUnique);
        a3 = a; // Assign a into a3; a's ref count increases
        assert(!a.rc.isUnique);
        // a2 and a3 go out of scope here
        // a2 is the last ref to rcarray(4242) -> gets freed
    }
    assert(a.rc.isUnique);
}

version (CoreUnittest)
{
    private struct StatsAllocator
    {
        version (CoreUnittest) size_t bytesUsed;

        @trusted @nogc nothrow pure
        void* allocate(size_t bytes) shared
        {
            import core.memory : pureMalloc;
            if (!bytes) return null;

            auto p = pureMalloc(bytes);
            if (p is null) return null;
            enum alignment = size_t.sizeof;
            assert(cast(size_t) p % alignment == 0);

            version (CoreUnittest)
            {
                static if (is(typeof(this) == shared))
                {
                    import core.atomic : atomicOp;
                    atomicOp!"+="(bytesUsed, bytes);
                }
                else
                {
                    bytesUsed += bytes;
                }
            }
            return p;
        }

        @system @nogc nothrow pure
        bool deallocate(void[] b) shared
        {
            import core.memory : pureFree;
            assert(b !is null);

            version (CoreUnittest)
            {
                static if (is(typeof(this) == shared))
                {
                    import core.atomic : atomicOp;
                    assert(atomicOp!">="(bytesUsed, b.length));
                    atomicOp!"-="(bytesUsed, b.length);
                }
                else
                {
                    assert(bytesUsed >= b.length);
                    bytesUsed -= b.length;
                }
            }
            pureFree(b.ptr);
            return true;
        }
    }

    private shared StatsAllocator allocator;

    private @nogc nothrow pure @trusted
    void* pureAllocate(size_t n)
    {
        return (cast(void* function(size_t) @nogc nothrow pure)(&_allocate))(n);
    }

    private @nogc nothrow @safe
    void* _allocate(size_t n)
    {
        return allocator.allocate(n);
    }

    private @nogc nothrow pure
    void* pureDeallocate(T)(T[] b)
    {
        return (cast(void* function(T[]) @nogc nothrow pure)(&_deallocate!(T)))(b);
    }

    private @nogc nothrow
    void* _deallocate(T)(T[] b)
    {
        allocator.deallocate(b);
        return null;
    }
}
else
{
    import core.memory : pureMalloc, pureFree;

    private alias pureAllocate = pureMalloc;

    @nogc nothrow pure
    private static void* pureDeallocate(T)(T[] b)
    {
        pureFree(b.ptr);
        return null;
    }
}
