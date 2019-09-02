// Written in the D programming language.
/**
This module provides a barebones reference counted slice.

License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: Les De Ridder

Source: $(DRUNTIMESRC core/experimental/rcslice.d)
*/
module core.experimental.rc.slice;

///
unittest
{
    __rcslice!int a; //default ctor
    assert(a.ptr is null);

    auto b = __rcslice!int(10); //allocating ctor

    {
        auto c = a; //copy ctor
        assert(c.ptr == a.ptr);
        assert(c.ptr != b.ptr);

        c = b; //opAssign
        assert(c.ptr != a.ptr);
        assert(c.ptr == b.ptr);
    }

    assert(a.count is null);
    assert(*b.count == 0);
}

/**
A reference counted slice can be used to implement reference counted data
structures.

The reference count is automatically incremented/decremented on assignment,
copy (construction), and destruction. When there are no more references to the
slice, the slice and the reference count are automatically deallocated.

Implementation: The internal implementation of `__rcslice` uses `malloc`/`free`.
*/
struct __rcslice(T, alias onDeallocate = null, bool defaultInitialize = true)
{
    alias CounterType = int;

    private T[] slice;
    private shared(CounterType)* count = null;

    /**
    Creates a new `__rcslice` instance, allocating memory for the slice.

    Params:
         size = size of the slice, in number of elements of type `T`
    */
    this(size_t size) inout
    {
        import core.memory : pureMalloc;

        auto memory = pureMalloc(CounterType.sizeof + T.sizeof * size);

        this.slice = (() @trusted inout => (cast(inout T*) (memory + CounterType.sizeof))[0 .. size])();

        this.count = (() @trusted inout => cast(typeof(count)) memory)();
        cast() *this.count = 0;

        static if (defaultInitialize)
        {
            import core.internal.lifetime : emplaceRef;
            foreach (i; 0 .. size)
            {
                () @trusted { emplaceRef((cast(T*) slice.ptr)[i]); }();
            }
        }
    }

    ///
    inout(T[]) opSlice(size_t start, size_t end) inout return scope
    {
        return slice[start .. end];
    }

    ///
    ref inout(T[]) opSlice() inout return scope
    {
        return slice;
    }

    ///
    ref inout(T) opIndex(size_t i) inout return scope
    {
        return slice[i];
    }

    ///
    inout(T*) ptr() inout return scope
    {
        return slice.ptr;
    }

    ///
    size_t length() inout
    {
        return slice.length;
    }

    ///
    bool opEquals(typeof(null)) inout
    {
        return slice is null;
    }

    ~this()
    {
        () @trusted { delRef(); }();
    }

    ///
    void opAssign(typeof(this) rhs)
    {
        if (rhs.count == count)
        {
            return;
        }

        //TODO: Move std.algorithm.mutation.swap to druntime
        auto tmp1 = rhs.slice;
        rhs.slice = slice;
        slice = tmp1;

        auto tmp2 = rhs.count;
        rhs.count = count;
        count = tmp2;
    }

    ///
    void opAssign(typeof(null))
    {
        delRef();

        slice = null;
    }

    ///
    static if (is(T == int))
    unittest
    {
        auto rcs = __rcslice!int(1);
        rcs = null;
        assert(rcs.length == 0);
    }

    ///
    this(scope ref inout typeof(this) rhs) inout
    {
        slice = rhs.slice;
        count = rhs.count;

        addRef();
    }

    private void addRef() inout
    {
        import core.atomic : atomicOp;

        if (slice is null)
        {
            return;
        }

        //TODO: Use `atomicFetchAdd` with `MemoryOrder.seq` once LDC has it
        () @trusted { atomicOp!"+="(*(cast(shared(CounterType)*) count), 1); } ();
    }

    private void delRef()
    {
        import core.atomic : atomicLoad, atomicOp, MemoryOrder;

        if (slice is null)
        {
            return;
        }

        // The counter is left at -1 when this was the last reference
        // (i.e. the counter is 0-based, because we use calloc)
        //TODO: Use `atomicFetchSub` with `MemoryOrder.raw` once LDC has it
        if (atomicLoad!(MemoryOrder.raw)(*count) == 0 || atomicOp!("-=")(*count, 1) == -1)
        {
            deallocate();
        }
    }

    private void deallocate()
    {
        import core.memory : pureFree;

        static if (!is(typeof(onDeallocate) == typeof(null)))
        {
            if (this != null)
            {
                onDeallocate(this);
            }
        }

        pureFree(cast(CounterType*) count);
    }
}

@safe unittest
{
    auto a = __rcslice!int(42);
    assert(*a.count == 0);
    {
        auto a2 = a; // Construct a2 by copy construction
        assert(*a.count == 1);
        auto a3 = __rcslice!int(4242);
        a2 = a3; // Assign a3 into a2; a's ref count drops
        assert(*a.count == 0);
        a3 = a; // Assign a into a3; a's ref count increases
        assert(*a.count == 1);
        // a2 and a3 go out of scope here
        // a2 is the last ref to __rcslice!int(4242) -> gets freed
    }
    assert(*a.count == 0);
}
