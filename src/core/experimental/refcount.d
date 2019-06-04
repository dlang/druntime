/**
  This module provides a composable reference count implementation in the form
  of `__RefCount`.
*/
module core.experimental.refcount;

/**
 * A qualified reference counted `struct` that is intended to be composed by
 * user-defined types that desire to implement manual memory management by means of
 * reference counting. Note to user: The internal implementation uses `malloc`/`free`.
 *
 * `__RefCount` was designed to be composed as a field inside a user-defined type.
 * The user is responsible to initialize the `__RefCount` in that type's constructors.
 * The user will call the `isUnique()` method to decide if this is the last
 * reference to the enclosing type so memory can be safely deallocated.
 *
 * $(B Important:) the `__RefCount` member must be initialized through a call to its
 * constructor before being used.
 */
struct __RefCount
{
    import core.atomic : atomicOp;

    alias CounterType = uint;
    private shared CounterType* rc = null;

    /*
     * Returns a Boolean value denoting if this can be used in a shared context.
     *
     * Returns:
     *      `true` if this started off as an immutable or shared object; `false` otherwise.
     *
     * Complexity:
     *      $(BIGOH 1).
     */
    @nogc nothrow pure @safe scope
    private bool isShared(this Q)() const
    {
        // Faster than ((cast(size_t) rc) % 8) == 0;
        return !((cast(size_t) rc) & 7);
    }

    /*
     * Perform `rc op val` operation. Use atomics if this is shared.
     *
     * Returns:
     *      The result of the operation.
     */
    @nogc nothrow pure @trusted scope
    private CounterType rcOp(this Q, string op)(CounterType val) const
    {
        return cast(CounterType)(atomicOp!op(*(cast(shared CounterType*) rc), val));
    }

    /**
     * Creates a new `__RefCount` instance. Its memory is internally managed with
     * malloc/free.
     *
     * Params:
     *      _ = an unused int value; required because structs don't have a
     *          user defined default constructor
     */
    @nogc nothrow pure @trusted scope
    this(this Q)(int)
    {
        /* We allocate a `size_t` chunk that will serve as our support. We
         * logically split the chunk into two `uint`s, using only one of the
         * two as our counter, depending if we are creating an immutable `__RefCount`
         * or not. The logic is as follows:
         *  - if we are creating an immutable RC, then a pointer to the first
         *    `uint` (aligned at 8) will serve as the reference count. On this
         *     counter we will only perform atomic operations, as immutable can
         *     be used in shared contextes.
         *  - if we are creating a const/mutable RC, then a pointer to the second
         *    `uint` (aligned at 4) will serve as the reference count.
         */

        shared CounterType* support = cast(shared CounterType*) pureAllocate(CounterType.sizeof);
        *support = 0;
        rc = cast(typeof(rc)) support;
        addRef();
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
     * Copy constructs a mutable `__RefCount` from a mutable reference, `rhs`.
     * This increases the reference count.
     */
    @nogc nothrow pure @safe scope
    this(return scope ref typeof(this) rhs)
    {
        mixin(copyCtorIncRef);
    }

    ///
    @nogc nothrow pure @safe scope
    this(return scope ref shared typeof(this) rhs) shared
    {
        mixin(copyCtorIncRef);
    }

    // { Get a const obj

    /**
     * Copy constructs a const `__RefCount` from a mutable reference, `rhs`.
     * This increases the reference count.
     */
    @nogc nothrow pure @safe scope
    this(return scope ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    ///
    @nogc nothrow pure @safe scope
    this(return scope ref shared typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }

    /**
     * Copy constructs a const `__RefCount` from a const reference, `rhs`.
     * This increases the reference count.
     */
    @nogc nothrow pure @safe scope
    this(return scope const ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    @nogc nothrow pure @safe scope
    this(return scope const shared ref typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }

    /**
     * Copy constructs a const `__RefCount` from an immutable reference, `rhs`.
     * This increases the reference count.
     */
    @nogc nothrow pure @safe scope
    this(return scope immutable ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    @nogc nothrow pure @safe scope
    this(return scope immutable shared ref typeof(this) rhs) const shared
    {
        mixin(copyCtorIncRef);
    }
    // } Get a const obj

    // { Get an immutable obj

    version (none)
    { // Allow only immutable from immutable

    /**
     * Creates a new immutable `__RefCount`. This is because we cannot have an
     * immutable reference to a mutable reference, `rhs`.
     */
    @nogc nothrow pure @trusted scope
    this(return scope ref typeof(this) rhs) immutable
    {
        // Can't have an immutable ref to a mutable. Create a new RC
        CounterType* support = cast(CounterType*) pureAllocate(2 * CounterType.sizeof);
        *support = 0;
        rc = cast(immutable CounterType*) support;
        addRef();
    }

    /**
     * By means of internal implementation details we can deduce, at runtime,
     * if the const reference `rhs` comes from an original immutable object
     * or not.
     *
     * If `rhs` is a const reference to an immutable object, this will copy
     * construct an immutable `__RefCount`, increasing the reference count.
     *
     * Otherwise, this creates a new immutable `__RefCount`. This is because
     * we cannot have an immutable reference to a mutable/const reference.
     */
    @nogc nothrow pure @trusted scope
    this(return scope const ref typeof(this) rhs) immutable
    {
        if (rhs.isShared())
        {
            // By implementation, only immutable RC is shared, so it's ok to inc ref
            rc = cast(immutable) rhs.rc;
            if (isInitialized())
            {
                addRef();
            }
        }
        else
        {
            // Can't have an immutable ref to a mutable. Create a new RC
            CounterType* support = cast(CounterType*) pureAllocate(2 * CounterType.sizeof);
            *support = 0;
            rc = cast(immutable CounterType*) support;
            addRef();
        }
    }

    } // Allow only immutable from immutable

    /*
     * Copy construct an immutable `__RefCount` from an immutable reference, `rhs`.
     * This increases the reference count.
     */
    @nogc nothrow pure @safe scope
    this(return scope immutable ref typeof(this) rhs) immutable
    {
        mixin(copyCtorIncRef);
    }
    // } Get an immutable obj

    /*
     * Assign a `__RefCount` object into this. This will decrement the old reference
     * count before assigning the new one. If the old reference was the last one,
     * this will trigger the deallocation of the old ref. This increases the
     * reference count of `rhs`.
     *
     * Params:
     *      rhs = the `__RefCount` object to be assigned.
     *
     * Returns:
     *      A reference to `this`.
     *
     * Complexity:
     *      $(BIGOH 1).
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
     * Increase the reference count. This asserts that `__RefCount` is initialized.
     *
     * Returns:
     *      This returns a `void*` so the compiler won't optimize away the call
     *      to this `const pure` function.
     */
    @nogc nothrow pure @safe scope
    private void* addRef(this Q)() const
    {
        assert(isInitialized(), "[__RefCount.addRef] __RefCount is uninitialized");
        cast(void) rcOp!(Q, "+=")(1);
        return null;
    }

    /*
     * Decrease the reference count. If this was the last reference, `free` the
     * support. This asserts that `__RefCount` is initialized.
     *
     * Returns:
     *      This returns a `void*` so the compiler won't optimize away the call
     *      to this `const pure` function.
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
     * `free` the support. This checks if this isShared or not in order to
     * correctly offset the pointer value for the `free` operation; this is
     * done by performing the opposite pointer arithmetics that the ctor does.
     *
     * Returns:
     *      This returns a `void*` so the compiler won't optimize away the call
     *      to this `const pure` function.
     */
    @nogc nothrow pure @system scope
    private void* deallocate(this Q)() const
    {
        return pureDeallocate((cast(CounterType*) rc)[0 .. 1]);
    }

    /**
     * Destruct the `__RefCount`. If it's initialized, decrement the refcount.
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
     * Return a boolean value denoting if this is the only reference to this object.
     *
     * Returns:
     *      `true` if this reference count is unique; `false` if this `__RefCount`
     *      object is uninitialized or there are multiple references to it.
     *
     * Complexity:
     *      $(BIGOH 1).
     */
    pure nothrow @safe @nogc scope
    bool isUnique(this Q)() const
    {
        return isInitialized() && (!!rcOp!(Q, "==")(1));
    }

    /**
     * Return a boolean value denoting if this `__RefCount` object is initialized.
     *
     * Returns:
     *      `true` if initialized; `false` otherwise
     *
     * Complexity:
     *      $(BIGOH 1).
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
     * Return a raw pointer to the underlying reference count pointer.
     * This is unsafe and may lead to dangling pointers to invalid memory.
     *
     * Returns:
     *      A raw pointer to the reference count.
     *
     * Complexity:
     *      $(BIGOH 1).
     */
    pure nothrow @nogc @system
    CounterType* getUnsafeValue(this Q)() const
    {
        return cast(CounterType*) rc;
    }

    /**
     * A factory function that creates and returns a new instance of a qualified
     * `__RefCount`.
     *
     * Params:
     *      QualifiedRefCount = a template parameter that is a qualified
     *      `__RefCount` type.
     *
     * Returns:
     *      A new instance of `QualifiedRefCount`.
     *
     * Complexity:
     *      $(BIGOH 1).
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
    import core.stdc.stdlib;

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

        /* Implement copy ctors */
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
        auto a2 = a; // Construct a2 by Copy Ctor
        assert(!a.rc.isUnique);
        auto a3 = rcarray(4242);
        a2 = a3; // Assign a3 into a2; a's ref count drops
        assert(a.rc.isUnique);
        a3 = a; // Assign a into a3; a's ref count increases
        assert(!a.rc.isUnique);
        // a2 and a3 go out of scope here
        // a2 is the last ref to arr(4242) -> gets freed
    }
    assert(a.rc.isUnique);
}

version (CoreUnittest)
@safe unittest
{
    @safe @nogc pure nothrow
    void test(MutRC, ConstRC, ImmRC)()
    {
        MutRC a = __RefCount.make!MutRC();
        assert(a.isUnique);
        ConstRC ca = __RefCount.make!ConstRC();
        assert(ca.isUnique);
        ImmRC ia = __RefCount.make!ImmRC();
        assert(ia.isUnique);

        // A const reference will increase the ref count
        ConstRC c_cp_a = a;
        assert(a.isValueEq(2));
        ConstRC c_cp_ca = ca;
        assert(ca.isValueEq(2));
        ConstRC c_cp_ia = ia;
        assert(ia.isValueEq(2));

        // An immutable from a mutable reference won't compile
        static assert(!__traits(compiles, { ImmRC i_cp_a = a; }));
        // An immutable from a const to a mutable reference won't compile
        static assert(!__traits(compiles, { ImmRC i_cp_ca = ca; }));
        // An immutable from an immutable reference will increase the ref count
        ImmRC i_cp_ia = ia;
        assert(ia.isValueEq(3));
        assert(i_cp_ia.isValueEq(3));

        // Check opAssign
        MutRC a2 = __RefCount.make!MutRC();
        a2 = a;
        assert(a.isValueEq(3));

        MutRC t;
        assert(!t.isInitialized());
        MutRC t2 = t;
        assert(!t.isInitialized());
        assert(!t2.isInitialized());
    }

    test!(__RefCount, const __RefCount, immutable __RefCount)();
    test!(shared __RefCount, const shared __RefCount, immutable shared __RefCount)();
    assert(allocator.bytesUsed == 0, "__RefCount leaked memory");
}

version (none)
@safe unittest
{
    () @safe @nogc pure nothrow scope
    {
        immutable __RefCount rc = __RefCount.make!__RefCount();
        assert(rc.isShared(), "OOPS!");
    }();

    assert(allocator.bytesUsed == 0, "__RefCount leaked memory");
}

version (CoreUnittest)
@system unittest
{
    import core.stdc.stdio;

    ()
    {
        auto x = __RefCount.make!(shared __RefCount)();
        static void fun(shared __RefCount * rc)
        {
            static void bar(shared __RefCount lrc)
            {
                shared cp = lrc;
                //debug printf("Ja %d\n", *(cast(uint*) cp.getUnsafeValue()));
                assert(*(cast(uint*) cp.getUnsafeValue()) > 0);
            }

            auto x = *rc;
            bar(x);
        }
        fun(&x);

        version (none)
        {
        import std.parallelism;
        alias TaskT = typeof(task!fun(&x));
        TaskT[] taskArr;
        foreach (i; 0 .. 100)
        {
            taskArr ~= task!fun(&x);
            taskArr[$ - 1].executeInNewThread();
        }
        foreach (i; 0 .. 100)
        {
            taskArr[i].spinForce();
        }
            //auto t = task!fun(&x);
            //t.executeInNewThread();
            //t.spinForce();
        //debug printf("Ja %d\n", *(cast(uint*) x.getUnsafeValue()));
        }
        else
        {

        import core.thread;
        Thread[] threadArr;
        foreach (i; 0 .. 100)
        {
            threadArr ~= new Thread({fun(&x);});
            threadArr[$ - 1].start();
        }
        foreach (i; 0 .. 100)
        {
            threadArr[i].join();
        }

        }

        assert(x.isValueEq(1));
    }();

    assert(allocator.bytesUsed == 0, "__RefCount leaked memory");
}

version (CoreUnittest)
@safe unittest
{
    () @safe @nogc pure nothrow scope
    {
        __RefCount a = __RefCount.make!__RefCount();
        assert(a.isUnique);
        __RefCount a2 = a;
        assert(a.isValueEq(2));
        __RefCount a3 = __RefCount.make!__RefCount();
        a2 = a3;
        assert(a.isValueEq(1));
        assert(a.isUnique);
    }();

    assert(allocator.bytesUsed == 0, "__RefCount leaked memory");
}

version (CoreUnittest)
@safe unittest
{
    struct TestRC
    {
        private __RefCount rc;
        int[] payload;

        @nogc nothrow pure @trusted scope
        this(this Q)(int sz)
        {
            static if (is(Q == immutable))
            {
                rc = __RefCount.make!(immutable __RefCount)();
                payload = (cast(immutable int*) pureAllocate(sz * int.sizeof))[0 .. sz];
            }
            else
            {
                rc = __RefCount.make!__RefCount();
                payload = (cast(int*) pureAllocate(sz * int.sizeof))[0 .. sz];
            }
        }

        private enum copyCtorIncRef = q{
            rc = rhs.rc;
            payload = rhs.payload;
        };

        @nogc nothrow pure @safe scope
        this(return scope ref typeof(this) rhs)
        {
            mixin(copyCtorIncRef);
        }

        // { Create a const obj
        @nogc nothrow pure @safe scope
        this(return scope ref typeof(this) rhs) const
        {
            mixin(copyCtorIncRef);
        }

        @nogc nothrow pure @safe scope
        this(return scope const ref typeof(this) rhs) const
        {
            mixin(copyCtorIncRef);
        }

        @nogc nothrow pure @safe scope
        this(return scope immutable ref typeof(this) rhs) const
        {
            mixin(copyCtorIncRef);
        }
        // } Create a const obj

        // { Create an immutable obj
        @nogc nothrow pure @trusted scope
        this(return scope ref typeof(this) rhs) immutable
        {
            // Can't have an immutable ref to a mutable. Create a new RC
            rc = __RefCount.make!(immutable __RefCount)();
            auto sz = rhs.payload.length;
            int[] tmp = (cast(int*) pureAllocate(sz * int.sizeof))[0 .. sz];
            tmp[] = rhs.payload[];
            payload = cast(immutable) tmp;
        }

        @nogc nothrow pure @safe scope
        this(return scope const ref typeof(this) rhs) immutable
        {
            rc = __RefCount.make!(immutable __RefCount)();
            // Can't have an immutable ref to a mutable. Create a new RC
            auto sz = rhs.payload.length;
            int[] tmp = (() @trusted => (cast(int*) pureAllocate(sz * int.sizeof))[0 .. sz])();
            tmp[] = rhs.payload[];
            payload = (() @trusted => cast(immutable) tmp)();
        }

        @nogc nothrow pure @safe scope
        this(return scope immutable ref typeof(this) rhs) immutable
        {
            mixin(copyCtorIncRef);
        }
        // } Create an immutable obj

        @nogc nothrow pure @safe scope
        ref TestRC opAssign(return ref typeof(this) rhs) return
        {
            if (payload is rhs.payload)
            {
                return this;
            }
            if (rc.isUnique)
            {
                () @trusted { pureDeallocate(payload); }();
            }
            payload = rhs.payload;
            rc = rhs.rc;
            return this;
        }

        @nogc nothrow pure @trusted scope
        ~this()
        {
            if (rc.isUnique())
            {
                pureDeallocate(cast(int[]) payload);
            }
        }
    }

    () @safe @nogc pure nothrow scope
    {
        enum numElem = 10;
        auto t = TestRC(numElem);
        assert(t.rc.isUnique);
        const TestRC ct = const TestRC(numElem);
        assert(ct.rc.isUnique);
        immutable TestRC it = immutable TestRC(numElem);
        assert(it.rc.isUnique);

        // A const reference will increase the ref count
        const c_cp_t = t;
        assert(t.rc.isValueEq(2));
        assert(t.payload is c_cp_t.payload);
        const c_cp_ct = ct;
        assert(ct.rc.isValueEq(2));
        assert(ct.payload is c_cp_ct.payload);
        const c_cp_it = it;
        assert(it.rc.isValueEq(2));
        assert(it.payload is c_cp_it.payload);

        // An immutable from a mutable reference will create a copy
        immutable i_cp_t = t;
        assert(t.rc.isValueEq(2));
        assert(i_cp_t.rc.isValueEq(1));
        assert(t.payload !is i_cp_t.payload);
        // An immutable from a const to a mutable reference will create a copy
        immutable i_cp_ct = ct;
        assert(ct.rc.isValueEq(2));
        assert(i_cp_ct.rc.isValueEq(1));
        assert(ct.payload !is i_cp_ct.payload);
        // An immutable from an immutable reference will increase the ref count
        immutable i_cp_it = it;
        assert(it.rc.isValueEq(3));
        assert(i_cp_it.rc.isValueEq(3));
        assert(it.payload is i_cp_it.payload);
        // An immutable from a const to an immutable reference will increase the ref count
        immutable i_cp_c_cp_it = c_cp_it;
        assert(c_cp_it.rc.isValueEq(4));
        assert(i_cp_c_cp_it.rc.isValueEq(4));
        assert((() @trusted => i_cp_c_cp_it.rc.getUnsafeValue() == c_cp_it.rc.getUnsafeValue())());
        assert(c_cp_it.payload is i_cp_c_cp_it.payload);

        // Ensure uninitialized structs don't crash
        TestRC t1;
        assert(!t1.rc.isUnique);
        TestRC t2 = t1;
        assert(!t1.rc.isUnique);
        assert(!t2.rc.isUnique);
        TestRC t3 = TestRC(numElem);
        t2 = t3;
    }();

    assert(allocator.bytesUsed == 0, "__RefCount leaked memory");
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
