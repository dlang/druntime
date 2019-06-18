///
module core.experimental.array;

import core.experimental.refcount;

import core.internal.traits : Unqual;

/**
Returns the size in bytes of the state that needs to be allocated to hold an
object of type `T`. `stateSize!T` is zero for `struct`s that are not
nested and have no nonstatic member variables.
 */
private template stateSize(T)
{
    static if (is(T == class) || is(T == interface))
        enum stateSize = __traits(classInstanceSize, T);
    else static if (is(T == void))
        enum size_t stateSize = 0;
    else
        enum stateSize = T.sizeof;
}

/**
The element type of `R`. `R` does not have to be a range. The element type is
determined as the type yielded by `r[0]` for an object `r` of type `R`.
 */
private template ElementType(R)
{
    static if (is(typeof(R.init[0].init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

///
struct rcarray(T)
{
    private T[] payload;
    private Unqual!T[] support;

    private __RefCount rc;

    private enum growthFactor = 1.5;

    //default construction leaves __RefCount uninitialised
    @disable this();

    this(size_t initialCapacity)
    {
        rc = __RefCount.make!__RefCount();
        reserve(initialCapacity);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(3);
        assert(a.length == 0);
        assert(a.capacity == 3);

        a.insert([1, 2, 3]);
        assert(a.length == 3);
        assert(a.capacity == 3);
    }

    this(U, this Q)(U[] items...)
    if (!is(Q == shared) && is(U : T))
    {
        rc = __RefCount.make!__RefCount();

        static if (is(Q == immutable) || is(Q == const))
        {
            mixin(immutableInsert!(typeof(items), "items")());
        }
        else
        {
            insert(items);
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        // Create a list from a list of ints
        {
            auto a = rcarray!int(1, 2, 3);
            assert(a == [1, 2, 3]);
        }
        // Create a list from an array of ints
        {
            auto a = rcarray!int([1, 2, 3]);
            assert(a == [1, 2, 3]);
        }
        // Create a list from a list from an input range
        {
            auto a = rcarray!int(1, 2, 3);
            auto a2 = rcarray!int(a);
            assert(a2 == [1, 2, 3]);
        }
    }

    private enum copyCtorIncRef = q{
        rc = rhs.rc;
        support = rhs.support;
        payload = rhs.payload;
    };

    private enum copyCtorAlloc = q{
        rc = __RefCount.make!(immutable __RefCount)();

        mixin(immutableInsert!(typeof(rhs.payload), "rhs.payload")());
    };

    this(return scope ref typeof(this) rhs)
    {
        mixin(copyCtorIncRef);
    }

    this(return scope ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    this(return scope const ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    this(return scope immutable ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    this(return scope ref typeof(this) rhs) immutable
    {
        mixin(copyCtorAlloc);
    }

    this(return scope const ref typeof(this) rhs) immutable
    {
        mixin(copyCtorAlloc);
    }

    this(return scope immutable ref typeof(this) rhs) immutable
    {
        mixin(copyCtorIncRef);
    }

    private this(RCQual, SuppQual, PaylQual, this Qualified)(RCQual _rc, SuppQual _support, PaylQual _payload)
        if (is(typeof(support) : typeof(_support)))
    {
        rc = _rc;
        support = _support;
        payload = _payload;
    }

    ~this()
    {
        if (rc.isUnique && support !is null)
        {
            // If this was the last reference to the payload,
            // we can safely free
            () @trusted { pureDeallocate(support); }();
        }
    }

    static if (is(T == int))
    unittest
    {
        auto a = rcarray!int(1, 2, 3);

        // Infer safety
        static assert( __traits(compiles, ()       { rcarray!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { rcarray!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = const rcarray!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = immutable rcarray!Unsafe(Unsafe(1)); }));

        static assert( __traits(compiles, ()       { rcarray!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { rcarray!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = const rcarray!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = immutable rcarray!UnsafeDtor(UnsafeDtor(1)); }));

        // Infer purity
        static assert( __traits(compiles, ()      { rcarray!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { rcarray!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = const rcarray!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = immutable rcarray!Impure(Impure(1)); }));

        static assert( __traits(compiles, ()      { rcarray!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { rcarray!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = const rcarray!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = immutable rcarray!ImpureDtor(ImpureDtor(1)); }));

        // Infer throwability
        static assert( __traits(compiles, ()         { rcarray!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { rcarray!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = const rcarray!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = immutable rcarray!Throws(Throws(1)); }));

        static assert( __traits(compiles, ()         { rcarray!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { rcarray!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = const rcarray!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = immutable rcarray!ThrowsDtor(ThrowsDtor(1)); }));
    }

    private @nogc nothrow pure @trusted scope
    size_t slackFront() const
    {
        return payload.ptr - support.ptr;
    }

    private @nogc nothrow pure @trusted scope
    size_t slackBack() const
    {
        return support.ptr + support.length - payload.ptr - payload.length;
    }

    /**
     * Return the number of elements in the array.
     *
     * Returns:
     *      the length of the array.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe scope
    size_t length() const
    {
        return payload.length;
    }

    /// ditto
    alias opDollar = length;

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        assert(a.length == 3);
        assert(a[$ - 1] == 3);
    }

    /**
     * Set the length of the array to `len`. If `len` exceeds the available
     * `capacity` of the array, an attempt to extend the array in place is made.
     * If extending is not possible, a reallocation will occur; if the new
     * length of the array is longer than `len`, the remainder will be default
     * initialized.
     *
     * Params:
     *      len = a positive integer
     *
     * Complexity: $(BIGOH n).
     */
    void length(size_t len)
    {
        if (capacity < len)
        {
            reserve(len);
        }
        payload = (() @trusted => cast(T[])(support[slackFront .. slackFront + len]))();
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        a.length = 2;
        assert(a.length == 2);

        auto b = a;
        assert(a.capacity < 10);
        a.length = 10; // will trigger a reallocation
        assert(a.length == 10);
        assert(b.length == 2);
        a[0] = 20;
        assert(a[0] != b[0]);
    }

    /**
     * Get the available capacity of the `array`; this is equal to `length` of
     * the array plus the available pre-allocated, free, space.
     *
     * Returns:
     *      a positive integer denoting the capacity.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe scope
    size_t capacity() const
    {
        return length + slackBack;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        a.reserve(10);
        assert(a.capacity == 10);
    }

    /**
     * Reserve enough memory from the allocator to store `n` elements.
     * If the current `capacity` exceeds `n` nothing will happen.
     * If `n` exceeds the current `capacity`, an attempt to `expand` the
     * current array is made. If `expand` is successful, all the expanded
     * elements are default initialized to `T.init`. If the `expand` fails
     * a new buffer will be allocated, the old elements of the array will be
     * copied and the new elements will be default initialized to `T.init`.
     *
     * Params:
     *      n = a positive integer
     *
     * Complexity: $(BIGOH max(length, n)).
     */
    void reserve(size_t n)
    {
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        if (n <= capacity) { return; }

        Unqual!T[] tmpSupport = (() @trusted pure => (cast(Unqual!T*)(pureAllocate(n * stateSize!T)))[0 .. n])();
        assert(tmpSupport !is null);

        for (size_t i = 0; i < tmpSupport.length; i++)
        {
            import core.lifetime : emplace;

            if (i < payload.length)
            {
                emplace(&tmpSupport[i], payload[i]);
            }
            else
            {
                emplace(&tmpSupport[i]);
            }
        }

        if (support !is null)
        {
            () @trusted { pureDeallocate(support); }();
        }

        support = tmpSupport;
        payload = (() @trusted => cast(T[])(support[0 .. payload.length]))();
        assert(capacity >= n);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = rcarray!int(0);
        a.reserve(stuff.length);
        a ~= stuff;
        assert(a == stuff);
    }

    /**
     * Inserts the elements of an array, or a built-in array or an element
     * at the back of the array.
     *
     * Params:
     *      stuff = an element, or an array, or built-in array of elements that
     *              are implitictly convertible to `T`
     *
     * Returns:
     *      the number of elements inserted
     *
     * Complexity: $(BIGOH max(length, m)), where `m` is the number of
     *             elements in the range.
     */
    size_t insert(Stuff)(auto ref Stuff stuff)
    if (is(Stuff == rcarray!T))
    {
        mixin(insertImpl);
    }

    size_t insert(U)(U[] stuff...)
    if (is(U : T))
    {
        mixin(insertImpl);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(0);
        assert(a.length == 0);

        a.insert(1);
        assert(a[0] == 1);

        a.insert([2, 3]);
        assert(a == [1, 2, 3]);

        a.insert(rcarray!int(4, 5, 6));
        assert(a == [1, 2, 3, 4, 5, 6]);
    }

    private enum insertImpl = q{
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        if (stuff.length == 0) return 0;
        if (stuff.length > slackBack)
        {
            double newCapacity = capacity ? capacity * growthFactor : stuff.length;
            while (newCapacity < capacity + stuff.length)
            {
                newCapacity = newCapacity * growthFactor;
            }
            reserve((() @trusted => cast(size_t)(newCapacity))());
        }

        // Can't use below, because it doesn't do opAssign, but memcpy
        //support[slackFront + length .. slackFront + length + stuff.length] = stuff[];
        for (size_t i = length, j = 0; i < length + stuff.length; ++i, ++j)
        {
            support[slackFront + i] = stuff[j];
        }

        payload = (() @trusted => cast(T[])(support[slackFront .. slackFront + payload.length + stuff.length]))();
        return stuff.length;
    };

    private static string immutableInsert(StuffType, string stuff)()
    {
        return q{
        size_t stuffLength = } ~ stuff ~ q{.length;

        void[] tmpSupport = (() @trusted => pureAllocate(stuffLength * stateSize!T)[0 .. stuffLength * stateSize!T])();

        assert(stuffLength == 0 || (stuffLength > 0 && tmpSupport !is null));
        for (size_t i = 0; i < stuffLength; ++i)
        } ~ "{" ~ q{
            alias E = ElementType!(typeof(payload));

            size_t s = i * stateSize!E;
            size_t e = (i + 1) * stateSize!E;
            void[] tmp = tmpSupport[s .. e];

            import core.lifetime : emplace;
            (() @trusted => emplace!E(tmp, } ~ stuff ~ q{[i]))();
        } ~ "}"
        ~ q{

        // In order to support D_BetterC, we need to cast the `void[]` to `T.ptr`
        // and then manually pass the length information again. This way we avoid
        // calling druntime's `_d_arraycast`, which is called whenever we cast between
        // two dynamic arrays.
        support = (() @trusted => (cast(typeof(support.ptr))(tmpSupport.ptr))[0 .. stuffLength])();
        payload = (() @trusted => cast(typeof(payload))(support[0 .. stuffLength]))();
        };
    }

    /**
     * Perform an immutable copy of the array. This will create a new array that
     * will copy the elements of the current array. This will `NOT` call `dup` on
     * the elements of the array, regardless if `T` defines it or not. If the array
     * is already immutable, this will just create a new reference to it.
     *
     * Returns:
     *      an immutable array.
     *
     * Complexity: $(BIGOH n).
     */
    immutable(rcarray!T) idup(this Q)()
    {
        static if (is(Q == immutable))
        {
            return this;
        }
        else
        {
            return immutable rcarray!T(this);
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        {
            auto a = rcarray!int(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = const rcarray!int(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = immutable rcarray!int(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }
    }

    /**
     * Perform a copy of the array. This will create a new array that will copy
     * the elements of the current array. This will `NOT` call `dup` on the
     * elements of the array, regardless if `T` defines it or not.
     *
     * Returns:
     *      a new mutable array.
     *
     * Complexity: $(BIGOH n).
     */
    auto ref dup()() const
    {
        return rcarray!T(payload);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        enum stuff = [1, 2, 3];
        auto a = immutable rcarray!int(stuff);
        auto aDup = a.dup;
        assert(aDup == stuff);
        aDup[0] = 0;
        assert(aDup[0] == 0);
        assert(a[0] == 1);
    }

    /**
     * Return a slice to the current array. This is equivalent to performing
     * a shallow copy of the array.
     *
     * Returns:
     *      an array that references the current array.
     *
     * Complexity: $(BIGOH 1)
     */
    auto ref opSlice() inout
    {
        return this;
    }

    /**
     * Return a slice to the current array that is bounded by `start` and `end`.
     * `start` must be less than or equal to `end` and `end` must be less than
     * or equal to `length`.
     *
     * Returns:
     *      an array that references the current array.
     *
     * Params:
     *      start = a positive integer
     *      end = a positive integer
     *
     * Complexity: $(BIGOH 1)
     */
    auto opSlice(this Qualified)(size_t start, size_t end)
    {
        return typeof(this)(rc, support, payload[start .. end]);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = immutable rcarray!int(stuff);
        assert(a[] == stuff);
        assert(a[1 .. $] == stuff[1 .. $]);
    }

    /**
     * Provide access to the element at `idx` in the array.
     * `idx` must be less than `length`.
     *
     * Returns:
     *      a reference to the element found at `idx`.
     *
     * Params:
     *      idx = a positive integer
     *
     * Complexity: $(BIGOH 1).
     */
    auto ref opIndex(size_t idx) inout
    {
        return payload[idx];
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        assert(a[2] == 3);
    }

    /**
     * Apply an unary operation to the element at `idx` in the array.
     * `idx` must be less than `length`.
     *
     * Returns:
     *      a reference to the element found at `idx`.
     *
     * Params:
     *      idx = a positive integer
     *
     * Complexity: $(BIGOH 1).
     */
    auto ref opIndexUnary(string op)(size_t idx)
    {
        mixin("return " ~ op ~ "payload[idx];");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        int x = --a[2];
        assert(a[2] == 2);
        assert(x == 2);
    }

    /**
     * Assign `elem` to the element at `idx` in the array.
     * `idx` must be less than `length`.
     *
     * Returns:
     *      a reference to the element found at `idx`.
     *
     * Params:
     *      elem = an element that is implicitly convertible to `T`
     *      idx = a positive integer
     *
     * Complexity: $(BIGOH 1).
     */
    auto ref opIndexAssign(U)(U elem, size_t idx)
    if (is(U : T))
    {
        return payload[idx] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        a[2] = 2;
        assert(a[2] == 2);
        (a[2] = 3)++;
        assert(a[2] == 4);
    }

    /**
     Assign `elem` to all element in the array.

     Returns:
          a reference to itself

     Params:
          elem = an element that is implicitly convertible to `T`

     Complexity: $(BIGOH n).
     */
    auto ref opIndexAssign(U)(U elem)
    if (is(U : T))
    {
        payload[] = elem;
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        a[] = 0;
        assert(a == [0, 0, 0]);
    }

    /**
    Assign `elem` to the element at `idx` in the array.
    `idx` must be less than `length`.

    Returns:
         a reference to the element found at `idx`.

    Params:
         elem = an element that is implicitly convertible to `T`
         indices = a positive integer

    Complexity: $(BIGOH n).
    */
    auto opSliceAssign(U)(U elem, size_t start, size_t end)
    if (is(U : T))
    {
        return payload[start .. end] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3, 4, 5, 6);
        a[1 .. 3] = 0;
        assert(a == [1, 0, 0, 4, 5, 6]);
    }

    /**
     * Assign to the element at `idx` in the array the result of
     * $(D a[idx] op elem).
     * `idx` must be less than `length`.
     *
     * Returns:
     *      a reference to the element found at `idx`.
     *
     * Params:
     *      elem = an element that is implicitly convertible to `T`
     *      idx = a positive integer
     *
     * Complexity: $(BIGOH 1).
     */
    auto ref opIndexOpAssign(string op, U)(U elem, size_t idx)
    if (is(U : T))
    {
        mixin("return payload[idx]" ~ op ~ "= elem;");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);
        a[2] += 2;
        assert(a[2] == 5);
        (a[2] += 3)++;
        assert(a[2] == 9);
    }

    /**
     * Create a new array that results from the concatenation of this array
     * with `rhs`.
     *
     * Params:
     *      rhs = can be an element that is implicitly convertible to `T`, an
     *            input range of such elements, or another `Array`
     *
     * Returns:
     *      the newly created array
     *
     * Complexity: $(BIGOH n + m), where `m` is the number of elements in `rhs`.
     */
    auto ref opBinary(string op, U)(auto ref U rhs)
        if (op == "~" &&
            (is (U : const typeof(this))
             || is (U : T)
             || (is (U == V[], V) && is(V : T))
            ))
    {
        auto newArray = this.dup();
        static if (is(U : const typeof(this)))
        {
            foreach (i; 0 .. rhs.length)
            {
                newArray ~= rhs[i];
            }
        }
        else
        {
            newArray.insert(rhs);
        }
        return newArray;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1]);
        auto a2 = a ~ 2;

        assert(a2 == [1, 2]);
        a[0] = 0;
        assert(a2 == [1, 2]);
    }

    /**
     * Assign `rhs` to this array. The current array will now become another
     * reference to `rhs`, unless `rhs` is `null`, in which case the current
     * array will become empty. If `rhs` refers to the current array nothing will
     * happen.
     *
     * If there are no more references to the previous array, the previous
     * array will be destroyed; this leads to a $(BIGOH n) complexity.
     *
     * Params:
     *      rhs = a reference to an array
     *
     * Returns:
     *      a reference to this array
     *
     * Complexity: $(BIGOH n).
     */
    auto ref opAssign()(auto ref typeof(this) rhs)
    {
        if (rc.isUnique && support !is null)
        {
            // If this was the last reference to the payload,
            // we can safely free
            () @trusted { pureDeallocate(support); }();
        }

        // This will update the reference count
        rc = rhs.rc;

        support = rhs.support;
        payload = rhs.payload;

        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(0);
        auto a2 = rcarray!int(1, 2);

        a = a2; // this will free the old a
        assert(a == [1, 2]);
        a[0] = 0;
        assert(a2 == [0, 2]);
    }

    static if (is(T == int))
    @safe unittest
    {
        auto arr = rcarray!int(1, 2, 3, 4, 5, 6);
        auto arr1 = arr[1 .. $];
        auto arr2 = arr[3 .. $];
        arr1 = arr2;
        assert(arr1 == [4, 5, 6]);
        assert(arr2 == [4, 5, 6]);
    }

    /**
     * Append the elements of `rhs` at the end of the array.
     *
     * If no allocator was provided when the list was created, the
     * $(REF, GCAllocator, std,experimental,allocator,gc_allocator) will be used.
     *
     * Params:
     *      rhs = can be an element that is implicitly convertible to `T`, an
     *            input range of such elements, or another `Array`
     *
     * Returns:
     *      a reference to this array
     *
     * Complexity: $(BIGOH n + m), where `m` is the number of elements in `rhs`.
     */
    auto ref opOpAssign(string op, U)(auto ref U rhs)
        if (op == "~" &&
            (is (U == typeof(this))
             || is (U : T)
             || (is (U == V[], V) && is(V : T))
            ))
    {
        return opAssign(this ~ rhs);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(0);
        auto a2 = rcarray!int(4, 5);
        assert(a.length == 0);

        a ~= 1;
        a ~= [2, 3];
        assert(a == [1, 2, 3]);

        // append an input range
        a ~= a2;
        assert(a == [1, 2, 3, 4, 5]);
        a2[0] = 0;
        assert(a == [1, 2, 3, 4, 5]);
    }

    ///
    bool opEquals(U)(auto ref const U rhs) const
    if (is(U : const typeof(this))
        || (is(U : const V[], V) && is(typeof(T.init == V.init))))
    {
        if (this.length != rhs.length) return false;

        foreach (size_t i, e; payload)
        {
            if (e != rhs[i]) return false;
        }
        return true;
    }

    static if (is(T == int))
    @safe unittest
    {
        auto a = [1, 2, 3];
        auto b = rcarray!int(a);

        assert(a == a);
        assert(a == b);
        assert(b == a);
        assert(b == b);
        a ~= 1;
        assert(a != b);

        static struct S
        {
            int x;
            bool opEquals(int rhs) const { return x == rhs; }
        }

        auto s = [S(1), S(2), S(3)];
        assert(b == s);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto arr1 = rcarray!int(1, 2);
        auto arr2 = rcarray!int(1, 2);
        auto arr3 = rcarray!int(2, 3);
        assert(arr1 == arr2);
        assert(arr2 == arr1);
        assert(arr1 != arr3);
        assert(arr3 != arr1);
        assert(arr2 != arr3);
        assert(arr3 != arr2);
    }

    ///
    int opCmp(U)(auto ref U rhs)
    if ((is(U == rcarray!V, V) || is(U == V[], V)) && is(V : T))
    {
        auto r1 = this;
        auto r2 = rhs;
        while (r1.length && r2.length)
        {
            if (r1[0] < r2[0])
                return -1;
            else if (r1[0] > r2[0])
                return 1;
            r1 = r1[1 .. $];
            r2 = r2[1 .. $];
        }
        // arrays are equal until here, but it could be that one of them is shorter
        if (!r1.length && !r2.length)
            return 0;
        return (r1.length == 0) ? -1 : 1;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto arr1 = rcarray!int(1, 2);
        auto arr2 = rcarray!int(1, 2);
        auto arr3 = rcarray!int(2, 3);
        auto arr4 = rcarray!int(0, 3);
        assert(arr1 <= arr2);
        assert(arr2 >= arr1);
        assert(arr1 < arr3);
        assert(arr3 > arr1);
        assert(arr4 < arr1);
        assert(arr4 < arr3);
        assert(arr3 > arr4);
    }

    static if (is(T == int))
    @safe unittest
    {
        auto arr1 = rcarray!int(1, 2);
        auto arr2 = [1, 2];
        auto arr3 = rcarray!int(2, 3);
        auto arr4 = [0, 3];
        assert(arr1 <= arr2);
        assert(arr2 >= arr1);
        assert(arr1 < arr3);
        assert(arr3 > arr1);
        assert(arr4 < arr1);
        assert(arr4 < arr3);
        assert(arr3 > arr4);
    }

    version (D_BetterC) {}
    else
    {
        ///
        auto toHash()
        {
            return payload.hashOf;
        }

        ///
        @safe unittest
        {
            auto arr1 = rcarray!int(1, 2);
            assert(arr1.toHash == rcarray!int(1, 2).toHash);
            arr1 ~= 3;
            assert(arr1.toHash == rcarray!int(1, 2, 3).toHash);
            assert(rcarray!int(0).toHash == rcarray!int(0).toHash);
        }
    }
}

version (CoreUnittest)
{
    private nothrow pure @safe
    void testConcatAndAppend()
    {
        auto a = rcarray!(int)(1, 2, 3);
        rcarray!(int) a2 = rcarray!(int)(1);

        auto a3 = a ~ a2;
        assert(a3 == [1, 2, 3]);

        auto a4 = a3;
        a3 = a3 ~ 4;
        assert(a3 == [1, 2, 3, 4]);
        a3 = a3 ~ [5];
        assert(a3 == [1, 2, 3, 4, 5]);
        assert(a4 == [1, 2, 3]);

        a4 = a3;
        a3 ~= 6;
        assert(a3 == [1, 2, 3, 4, 5, 6]);
        a3 ~= [7];
        assert(a3 == [1, 2, 3, 4, 5, 6, 7]);

        a3 ~= a3;
        assert(a3 == [1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7]);
        rcarray!int a5 = rcarray!(int)(1);
        a5 ~= [1, 2, 3];
        assert(a5 == [1, 2, 3]);
        auto a6 = a5;
        a5 = a5;
        a5[0] = 10;
        assert(a5 == a6);

        // Test concat with mixed qualifiers
        auto a7 = immutable rcarray!(int)(a5);
        assert(a7[0] == 10);
        a5[0] = 1;
        assert(a7[0] == 10);
        auto a8 = a5 ~ a7;
        assert(a8 == [1, 2, 3, 10, 2, 3]);

        auto a9 = const rcarray!(int)(a5);
        auto a10 = a5 ~ a9;
        assert(a10 == [1, 2, 3, 1, 2, 3]);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testConcatAndAppend();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testSimple()
    {
        auto a = rcarray!int(3);
        assert(a.capacity == 3);
        assert(a.length == 0);

        a.insert(1, 2, 3);
        assert(a[0] == 1);
        assert(a == a);
        assert(a == [1, 2, 3]);

        a = a[1 .. $];
        assert(a[0] == 2);
        assert(a == [2, 3]);

        a.insert([4, 5, 6]);
        a.insert(7);
        a.insert([8]);
        assert(a == [2, 3, 4, 5, 6, 7, 8]);

        a[0] = 9;
        assert(a == [9, 3, 4, 5, 6, 7, 8]);

        auto aTail = a[1 .. $];
        assert(aTail[0] == 3);
        aTail[0] = 8;
        assert(aTail[0] == 8);

        assert(a[1 .. $][0] == 8);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testSimple();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testSimpleImmutable()
    {
        auto a = rcarray!(immutable int)(1);
        assert(a.length == 0);

        a.insert(1, 2, 3);
        assert(a[0] == 1);
        assert(a == a);
        assert(a == [1, 2, 3]);

        a = a[1 .. $];
        assert(a[0] == 2);
        assert(a == [2, 3]);
        assert(a[1 .. $][0] == 3);

        a.insert([4, 5, 6]);
        a.insert(7);
        assert(a == [2, 3, 4, 5, 6, 7]);

        // Cannot modify immutable values
        static assert(!__traits(compiles, { a[0] = 9; }));
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testSimpleImmutable();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testCopyAndRef()
    {
        auto aFromList = rcarray!int(1, 2, 3);
        auto aFromRange = rcarray!int(aFromList);
        assert(aFromList == aFromRange);

        aFromList = aFromList[1 .. $];
        assert(aFromList == [2, 3]);
        assert(aFromRange == [1, 2, 3]);

        rcarray!int aInsFromRange = rcarray!int(0);
        aInsFromRange.insert(aFromList);
        aFromList = aFromList[1 .. $];
        assert(aFromList == [3]);
        assert(aInsFromRange == [2, 3]);

        auto aFromRef = aInsFromRange;
        auto aFromDup = aInsFromRange.dup;
        assert(aInsFromRange[0] == 2);
        aFromRef[0] = 5;
        assert(aInsFromRange[0] == 5);
        assert(aFromDup[0] == 2);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testCopyAndRef();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testImmutability()
    {
        auto a = immutable rcarray!(int)(1, 2, 3);
        auto a2 = a;

        assert(a2[0] == 1);
        assert(a2[0] == a2[0]);
        static assert(!__traits(compiles, { a2[0] = 4; }));
        static assert(!__traits(compiles, { a2 = a2[1 .. $]; }));

        auto a4 = a2[1 .. $];
        assert(a4[0] == 2);

        // Create a mutable copy from an immutable array
        auto a5 = a.dup();
        assert(a5 == [1, 2, 3]);
        assert(a5[0] == 1);
        a5[0] = 2;
        assert(a5[0] == 2);
        assert(a[0] == 1);
        assert(a5 == [2, 2, 3]);
    }

    private nothrow pure @safe
    void testConstness()
    {
        auto a = const rcarray!(int)(1, 2, 3);
        auto a2 = a;
        immutable rcarray!int a5 = a;

        assert(a2[0] == 1);
        assert(a2[0] == a2[0]);
        static assert(!__traits(compiles, { a2[0] = 4; }));
        static assert(!__traits(compiles, { a2 = a2[1 .. $]; }));

        auto a4 = a2[1 .. $];
        assert(a4[0] == 2);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testImmutability();
            testConstness();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testWithClass()
    {
        class MyClass
        {
            int x;
            this(int x) { this.x = x; }

            this(ref typeof(this) rhs) immutable { x = rhs.x; }

            this(const ref typeof(this) rhs) immutable { x = rhs.x; }
        }

        MyClass c = new MyClass(10);
        {
            auto a = rcarray!MyClass(c);
            assert(a[0].x == 10);
            assert(a[0] is c);
            a[0].x = 20;
        }
        assert(c.x == 20);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            //testWithClass();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private @nogc nothrow pure @safe
    void testOpOverloads()
    {
        auto a = rcarray!int(1, 2, 3, 4);
        assert(a[0] == 1); // opIndex

        // opIndexUnary
        ++a[0];
        assert(a[0] == 2);
        --a[0];
        assert(a[0] == 1);
        a[0]++;
        assert(a[0] == 2);
        a[0]--;
        assert(a[0] == 1);

        // opIndexAssign
        a[0] = 2;
        assert(a[0] == 2);

        // opIndexOpAssign
        a[0] /= 2;
        assert(a[0] == 1);
        a[0] *= 2;
        assert(a[0] == 2);
        a[0] -= 1;
        assert(a[0] == 1);
        a[0] += 1;
        assert(a[0] == 2);
    }

    @safe unittest
    {
        () @nogc nothrow pure @safe {
            testOpOverloads();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }

    private nothrow pure @safe
    void testSlice()
    {
        auto a = rcarray!int(1, 2, 3, 4);
        auto b = a[];
        assert(a == b);
        b[1] = 5;
        assert(a[1] == 5);

        size_t startPos = 2;
        auto c = b[startPos .. $];
        assert(c == [3, 4]);
        c[0] = 5;
        assert(a == b);
        assert(a == [1, 5, 5, 4]);
        assert(a.capacity == b.capacity && b.capacity == c.capacity + startPos);

        c ~= 5;
        assert(c == [5, 4, 5]);
        assert(a == b);
        assert(a == [1, 5, 5, 4]);
    }

    @safe unittest
    {
        () nothrow pure @safe {
            testSlice();
        }();

        assert(allocator.bytesUsed == 0, "rcarray leaked memory");
    }
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

    private @nogc nothrow pure @trusted
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

version (unittest)
{
    // Structs used to test the type system inference
    private static struct Unsafe
    {
        int _x;
        @system this(int x) {}
    }

    private static struct UnsafeDtor
    {
        int _x;
        @nogc nothrow pure @safe this(int x) {}
        @system ~this() {}
    }

    private static struct Impure
    {
        int i;
        @safe this(int i) { this.i = i; }
    }

    private static struct ImpureDtor
    {
        int i;
        @nogc nothrow pure @safe this(int x) {}
        @safe ~this() { i = 42; }
    }

    private static struct Throws
    {
        int _x;
        this(int id) { throw new Exception(null); }
    }

    private static struct ThrowsDtor
    {
        int _x;
        @nogc nothrow @safe this(int x) {}
        ~this() { throw new Exception(null); }
    }
}