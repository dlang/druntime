// Written in the D programming language.
/**
This module provides a composable reference count implementation in the form
of `__RefCount`.

License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: Eduard Staniloiu

Source: $(DRUNTIMESRC core/experimental/refcount.d)
*/
module core.experimental.refcount;

///
unittest
{
    auto rc = __RefCount.make!__RefCount();
    assert(rc.isUnique);
    {
        auto rc2 = rc; // Construct rc2 by copy construction
        assert(!rc.isUnique);
        auto rc3 = __RefCount.make!__RefCount();
        rc2 = rc3; // Assign rc3 into rc2; rc's ref count drops
        assert(rc.isUnique);
        rc3 = rc; // Assign rc into rc3; rc's ref count increases
        assert(!rc.isUnique);
        // rc2 and rc3 go out of scope here
        // rc2 is the last ref to the `__RefCount` created in this block -> gets freed
    }
    assert(rc.isUnique);
}

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
    private shared(CounterType)* rc = null;

    /*
    Perform `rc op val` operation. Always use atomics as the counter is shared.

    Returns:
         The result of the operation.
    */
    @nogc nothrow pure @trusted scope
    private shared(CounterType) rcOp(this Q, string op)(CounterType val) const
    {
        return cast(shared(CounterType)) (atomicOp!op(*(cast(shared(CounterType)*) rc), val));
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

        import core.memory : pureMalloc;
        shared(CounterType)* support = cast(shared(CounterType)*) pureMalloc(CounterType.sizeof);
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
        mixin(opAssignImpl);
    }

    ///
    @nogc nothrow pure @safe scope
    ref shared(__RefCount) opAssign(return scope shared ref typeof(this) rhs) return shared
    {
        mixin(opAssignImpl);
    }

    private enum opAssignImpl =
    q{
        if (rhs.isInitialized())
        {
            if (rc == rhs.rc)
            {
                return this;
            }
            rhs.addRef();
        }
        if (isInitialized())
        {
            delRef();
        }
        () @trusted { rc = rhs.rc; }();
        return this;
    };

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
        import core.memory : pureFree;
        pureFree(cast(void*) rc);
        return null;
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
