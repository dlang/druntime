///
module core.experimental.array;

import core.internal.traits : Unqual;

// { "Imports" from Phobos

// { Allocators

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

private template isAbstractClass(T...)
if (T.length == 1)
{
    enum bool isAbstractClass = __traits(isAbstractClass, T[0]);
}

private template isInnerClass(T)
if (is(T == class))
{
    static if (is(typeof(T.outer)))
        enum isInnerClass = __traits(isSame, typeof(T.outer), __traits(parent, T));
    else
        enum isInnerClass = false;
}

private enum classInstanceAlignment(T) = size_t.alignof >= T.alignof ? size_t.alignof : T.alignof;

private T emplace(T, Args...)(T chunk, auto ref Args args)
if (is(T == class))
{
    static assert(!isAbstractClass!T, T.stringof ~
        " is abstract and it can't be emplaced");

    // Initialize the object in its pre-ctor state
    enum classSize = __traits(classInstanceSize, T);
    (() @trusted => (cast(void*) chunk)[0 .. classSize] = typeid(T).initializer[])();

    static if (isInnerClass!T)
    {
        static assert(Args.length > 0,
            "Initializing an inner class requires a pointer to the outer class");
        static assert(is(Args[0] : typeof(T.outer)),
            "The first argument must be a pointer to the outer class");

        chunk.outer = args[0];
        alias args1 = args[1..$];
    }
    else alias args1 = args;

    // Call the ctor if any
    static if (is(typeof(chunk.__ctor(args1))))
    {
        // T defines a genuine constructor accepting args
        // Go the classic route: write .init first, then call ctor
        chunk.__ctor(args1);
    }
    else
    {
        static assert(args1.length == 0 && !is(typeof(&T.__ctor)),
            "Don't know how to initialize an object of type "
            ~ T.stringof ~ " with arguments " ~ typeof(args1).stringof);
    }
    return chunk;
}

private T emplace(T, Args...)(void[] chunk, auto ref Args args)
if (is(T == class))
{
    enum classSize = __traits(classInstanceSize, T);
    testEmplaceChunk(chunk, classSize, classInstanceAlignment!T);
    return emplace!T(cast(T)(chunk.ptr), args);
}

private T* emplace(T, Args...)(void[] chunk, auto ref Args args)
if (!is(T == class))
{
    testEmplaceChunk(chunk, T.sizeof, T.alignof);
    emplaceRef!(T, Unqual!T)(*cast(Unqual!T*) chunk.ptr, args);
    return cast(T*) chunk.ptr;
}

private T* emplace(T)(T* chunk) @safe pure nothrow
{
    emplaceRef!T(*chunk);
    return chunk;
}

private T* emplace(T, Args...)(T* chunk, auto ref Args args)
if (is(T == struct) || Args.length == 1)
{
    emplaceRef!T(*chunk, args);
    return chunk;
}

private void emplaceRef(T, UT, Args...)(ref UT chunk, auto ref Args args)
{
    static if (args.length == 0)
    {
        static assert(is(typeof({static T i;})),
            convFormat("Cannot emplace a %1$s because %1$s.this() is annotated with @disable.", T.stringof));
        static if (is(T == class)) static assert(!isAbstractClass!T,
            T.stringof ~ " is abstract and it can't be emplaced");
        emplaceInitializer(chunk);
    }
    else static if (
        !is(T == struct) && Args.length == 1 /* primitives, enums, arrays */
        ||
        Args.length == 1 && is(typeof({T t = args[0];})) /* conversions */
        ||
        is(typeof(T(args))) /* general constructors */)
    {
        static struct S
        {
            T payload;
            this(ref Args x)
            {
                static if (Args.length == 1)
                    static if (is(typeof(payload = x[0])))
                        payload = x[0];
                    else
                        payload = T(x[0]);
                else
                    payload = T(x);
            }
        }
        if (__ctfe)
        {
            static if (is(typeof(chunk = T(args))))
                chunk = T(args);
            else static if (args.length == 1 && is(typeof(chunk = args[0])))
                chunk = args[0];
            else assert(0, "CTFE emplace doesn't support "
                ~ T.stringof ~ " from " ~ Args.stringof);
        }
        else
        {
            S* p = () @trusted { return cast(S*) &chunk; }();
            static if (UT.sizeof > 0)
                emplaceInitializer(*p);
            p.__ctor(args);
        }
    }
    else static if (is(typeof(chunk.__ctor(args))))
    {
        // This catches the rare case of local types that keep a frame pointer
        emplaceInitializer(chunk);
        chunk.__ctor(args);
    }
    else
    {
        //We can't emplace. Try to diagnose a disabled postblit.
        static assert(!(Args.length == 1 && is(Args[0] : T)),
            convFormat("Cannot emplace a %1$s because %1$s.this(this) is annotated with @disable.", T.stringof));

        //We can't emplace.
        static assert(false,
            convFormat("%s cannot be emplaced from %s.", T.stringof, Args[].stringof));
    }
}
// ditto
private void emplaceRef(UT, Args...)(ref UT chunk, auto ref Args args)
if (is(UT == Unqual!UT))
{
    emplaceRef!(UT, UT)(chunk, args);
}

//emplace helper functions
private void emplaceInitializer(T)(scope ref T chunk) @trusted pure nothrow
{
    static if (__traits(isZeroInit, T))
    {
        import core.stdc.string : memset;
        memset(&chunk, 0, T.sizeof);
    }
    else
    {
        import core.stdc.string : memcpy;
        static immutable T init = T.init;
        memcpy(&chunk, &init, T.sizeof);
    }
}

private @nogc pure nothrow @safe
void testEmplaceChunk(void[] chunk, size_t typeSize, size_t typeAlignment)
{
    assert(chunk.length >= typeSize, "emplace: Chunk size too small.");
    assert((cast(size_t) chunk.ptr) % typeAlignment == 0, "emplace: Chunk is not aligned.");
}

private void dispose(A, T)(auto ref A alloc, auto ref T* p)
{
    import core.internal.traits : hasElaborateDestructor;

    static if (hasElaborateDestructor!T)
    {
        destroy(*p);
    }
    alloc.deallocate((cast(void*) p)[0 .. T.sizeof]);
    static if (__traits(isRef, p))
        p = null;
}

private void dispose(A, T)(auto ref A alloc, auto ref T p)
if (is(T == class) || is(T == interface))
{
    if (!p) return;
    static if (is(T == interface))
    {
        version (Windows)
        {
            import core.sys.windows.unknwn : IUnknown;
            static assert(!is(T: IUnknown), "COM interfaces can't be destroyed in "
                ~ __PRETTY_FUNCTION__);
        }
        auto ob = cast(Object) p;
    }
    else
        alias ob = p;
    auto support = (cast(void*) ob)[0 .. typeid(ob).initializer.length];
    destroy(p);
    alloc.deallocate(support);
    static if (__traits(isRef, p))
        p = null;
}

private void dispose(A, T)(auto ref A alloc, auto ref T[] array)
{
    import core.internal.traits : hasElaborateDestructor;

    static if (hasElaborateDestructor!(typeof(array[0])))
    {
        foreach (ref e; array)
        {
            destroy(e);
        }
    }
    alloc.deallocate(array);
    static if (__traits(isRef, array))
        array = null;
}

// } Allocators

// } End "Imports" from Phobos

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

private struct PrefixAllocator
{
    /**
    The alignment is a static constant equal to `platformAlignment`, which
    ensures proper alignment for any D data type.
    */
    enum uint alignment = size_t.alignof;
    static enum prefixSize = size_t.sizeof;

    version (CoreUnittest)
    {
        // During unittesting, we are keeping a count of the number of bytes allocated
        size_t bytesUsed;
    }

    @trusted @nogc nothrow pure
    void[] allocate(size_t bytes) shared
    {
        import core.memory : pureMalloc;
        if (!bytes) return null;
        auto p = pureMalloc(bytes + prefixSize);

        if (p is null) return null;
        assert(cast(size_t) p % alignment == 0);
        // Init reference count to 0
        *(cast(size_t *) p) = 0;

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

        return p[prefixSize .. prefixSize + bytes];
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

        pureFree(b.ptr - prefixSize);
        return true;
    }

    private template Payload2Affix(Payload, Affix)
    {
        static if (is(Payload[] : void[]))
            alias Payload2Affix = Affix;
        else static if (is(Payload[] : shared(void)[]))
            alias Payload2Affix = shared Affix;
        else static if (is(Payload[] : immutable(void)[]))
            alias Payload2Affix = shared Affix;
        else static if (is(Payload[] : const(shared(void))[]))
            alias Payload2Affix = shared Affix;
        else static if (is(Payload[] : const(void)[]))
            alias Payload2Affix = const Affix;
        else
            static assert(0, "Internal error for type " ~ Payload.stringof);
    }

    static auto ref prefix(T)(T[] b)
    {
        assert(b.ptr && (cast(size_t) b.ptr % alignment == 0));
        return (cast(Payload2Affix!(T, size_t)*) b.ptr)[-1];
    }

    /**
    Returns the global instance of this allocator type. The C heap allocator is
    thread-safe, therefore all of its methods and `it` itself are `shared`.
    */
    static shared PrefixAllocator instance;
}

version (CoreUnittest)
@safe pure nothrow @nogc unittest
{
    shared PrefixAllocator a;
    auto b = a.allocate(42);
    assert(b.length == 42);
    assert(a.bytesUsed == 42);
    () @trusted {
        assert(a.prefix(b) == 0);
        a.prefix(b)++;
        assert(a.prefix(b) == 1);
        a.deallocate(b);
    }();
    assert(a.bytesUsed == 0);
}


version (CoreUnittest)
{
    private alias SCAlloc = shared PrefixAllocator;
    private alias SSCAlloc = shared PrefixAllocator;

    private SCAlloc localAllocator;
    private SSCAlloc sharedAllocator;

    private @nogc nothrow pure @trusted
    void[] pureAllocate(bool isShared, size_t n)
    {
        return (cast(void[] function(bool, size_t) @nogc nothrow pure)(&_allocate))(isShared, n);
    }

    private @nogc nothrow @safe
    void[] _allocate(bool isShared, size_t n)
    {
        return isShared ? sharedAllocator.allocate(n) : localAllocator.allocate(n);
    }

    static if (__traits(hasMember, typeof(localAllocator), "expand"))
    {
        private @nogc nothrow pure @trusted
        bool pureExpand(bool isShared, ref void[] b, size_t delta)
        {
            return (cast(bool function(bool, ref void[], size_t) @nogc nothrow pure)(&_expand))(isShared, b, delta);
        }

        private @nogc nothrow @safe
        bool _expand(bool isShared, ref void[] b, size_t delta)
        {
            return isShared ?  sharedAllocator.expand(b, delta) : localAllocator.expand(b, delta);
        }
    }

    private @nogc nothrow pure
    void pureDispose(T)(bool isShared, T[] b)
    {
        return (cast(void function(bool, T[]) @nogc nothrow pure)(&_dispose!(T)))(isShared, b);
    }

    private @nogc nothrow
    void _dispose(T)(bool isShared, T[] b)
    {
        return isShared ?  sharedAllocator.dispose(b) : localAllocator.dispose(b);
    }
}

///
struct rcarray(T)
{
    import core.atomic : atomicOp;

    private T[] payload;
    private Unqual!T[] support;

    version (CoreUnittest) { }
    else
    {
        alias localAllocator = shared PrefixAllocator.instance;
        alias sharedAllocator = shared PrefixAllocator.instance;
    }

    private static enum double capacityFactor = 3.0 / 2;
    private static enum initCapacity = 3;
    //private bool isShared;

    private static enum isSharedMask = 1UL << ((PrefixAllocator.prefixSize * 8) - 1);

    private @nogc nothrow pure @safe
    bool isShared() const
    {
        return opCmpPrefix!">="(support, isSharedMask);
    }

    private @nogc nothrow pure @trusted
    void setIsShared(T)(const T[] _support, bool _isShared) const
    {
        static size_t _sharedOpCmpPrefix(string op, T)(const T[] _support, size_t val)
        {
            return cast(size_t)(atomicOp!op(*cast(shared size_t *)&sharedAllocator.prefix(_support), val));
        }

        static size_t _sharedOpPrefix(string op, T)(const T[] _support, size_t val)
        {
            return cast(size_t)(atomicOp!op(*cast(shared size_t *)&sharedAllocator.prefix(_support), val));
        }


        if (_isShared)
        {
            //auto t = (cast(size_t delegate(const T[], size_t) const @nogc nothrow pure)(&_sharedOpCmpPrefix!("==", T)))(_support, 1);
            //assert(t);
            cast(void) (cast(size_t function(const T[], size_t) @nogc nothrow pure)(&_sharedOpPrefix!("|=", T)))(_support, isSharedMask);
            //atomicOp!op(*cast(shared size_t *)&sharedAllocator.prefix(support), val);
        }
    }

    private @trusted
    auto pref() const
    {
        assert(support !is null);
        auto _isShared = true;
        //if (isShared)
        if (_isShared)
        {
            return sharedAllocator.prefix(support);
        }
        else
        {
            return localAllocator.prefix(support);
        }
    }

    private size_t _opPrefix(string op, T)(const T[] _support, size_t val) const
    {
        assert(_support !is null);
        auto _isShared = true;
        //if (isShared)
        if (_isShared)
        {
            return cast(size_t)(atomicOp!op(*cast(shared size_t *)&sharedAllocator.prefix(_support), val));
        }
        else
        {
            mixin("return cast(size_t)(*cast(size_t *)&localAllocator.prefix(_support)" ~ op ~ "val);");
        }
    }

    private @nogc nothrow pure @trusted
    size_t opPrefix(string op, T)(const T[] _support, size_t val) const
    if ((op == "+=") || (op == "-="))
    {
        return (cast(size_t delegate(const T[], size_t) const @nogc nothrow pure)(&_opPrefix!(op, T)))(_support, val);
    }

    private @nogc nothrow pure @trusted
    bool opCmpPrefix(string op, T)(const T[] _support, size_t val) const
    if ((op == "==") || (op == "<=") || (op == "<") || (op == ">=") || (op == ">"))
    {
        return cast(bool) (cast(size_t delegate(const T[], size_t) const @nogc nothrow pure)(&_opPrefix!(op, T)))(_support, val);
    }

    private @nogc nothrow pure @trusted
    void addRef(SupportQual, this Q)(SupportQual _support)
    {
        assert(_support !is null);
        cast(void) opPrefix!("+=")(_support, 1);
    }

    private void delRef(Unqual!T[] _support)
    {
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        assert(_support !is null);
        size_t defaultRCVal = isShared * isSharedMask;
        if (opPrefix!("-=")(_support, 1) == defaultRCVal)
        {
            () @trusted {
                version (CoreUnittest)
                {
                    pureDispose(isShared, _support);
                }
                else
                {
                    localAllocator.dispose(_support);
                }
            }();
        }
    }

    private static string immutableInsert(StuffType, alias _isShared)(string stuff)
    {
        auto stuffLengthStr = q{
            size_t stuffLength = } ~ stuff ~ ".length;";

        return stuffLengthStr ~ q{

        version (CoreUnittest)
        {
            void[] tmpSupport = (() @trusted => pureAllocate(_isShared, stuffLength * stateSize!T))();
        }
        else
        {
            void[] tmpSupport;
            if (_isShared)
            {
                tmpSupport = (() @trusted => sharedAllocator.allocate(stuffLength * stateSize!T))();
            }
            else
            {
                tmpSupport = (() @trusted => localAllocator.allocate(stuffLength * stateSize!T))();
            }
        }

        assert(stuffLength == 0 || (stuffLength > 0 && tmpSupport !is null));
        for (size_t i = 0; i < stuffLength; ++i)
        } ~ ""
        ~"{"
        ~"    alias TT = ElementType!(typeof(payload));"
        ~"    size_t s = i * stateSize!TT;"
        ~"    size_t e = (i + 1) * stateSize!TT;"
        ~"    void[] tmp = tmpSupport[s .. e];"
        ~"    (() @trusted => emplace!TT(tmp, " ~ stuff ~ "[i]))();"
        ~"}"
        ~q{

        support = (() @trusted => cast(typeof(support))(tmpSupport))();
        payload = (() @trusted => cast(typeof(payload))(support[0 .. stuffLength]))();
        if (support) addRef(support);
        };
    }

    private void destroyUnused()
    {
        if (support !is null)
        {
            delRef(support);
        }
    }

    /**
     * Constructs a qualified array out of a number of items
     * that will use the collection deciced allocator object.
     *
     * Params:
     *      values = a variable number of items, either in the form of a
     *               list or as a built-in array
     *
     * Complexity: $(BIGOH m), where `m` is the number of items.
     */
    this(U, this Q)(U[] values...)
    if (!is(Q == shared) && is(U : T))
    {
        static if (is(Q == immutable) || is(Q == const))
        {
            static if (is(Q == immutable))
            {
                bool _isShared = true;
                mixin(immutableInsert!(typeof(values), true)("values"));
                setIsShared(support, true);
            }
            else
            {
                bool _isShared = false;
                mixin(immutableInsert!(typeof(values), true)("values"));
            }
        }
        else
        {
            insert(0, values);
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

    // Begin Copy Ctors
    // {

    private enum copyCtorIncRef = q{
        payload = rhs.payload;
        support = rhs.support;
        //isShared = rhs.isShared;
        setIsShared(support, rhs.isShared);

        if (support !is null)
        {
            addRef(support);
        }
    };

    this(ref typeof(this) rhs)
    {
        mixin(copyCtorIncRef);
    }

    // { Get a const obj

    this(ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    this(const ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }

    this(immutable ref typeof(this) rhs) const
    {
        mixin(copyCtorIncRef);
    }
    // } Get a const obj

    // { Get an immutable obj

    this(ref typeof(this) rhs) immutable
    {
                bool _isShared = true;
        mixin(immutableInsert!(typeof(rhs), true)("rhs"));
        //isShared = true;
        setIsShared(support, true);
    }

    this(const ref typeof(this) rhs) immutable
    {
        // TODO should infer rhs.isShared
                bool _isShared = true;
        mixin(immutableInsert!(typeof(rhs.payload), true)("rhs.payload"));
        //isShared = rhs.isShared;
        setIsShared(support, true);
        //setIsShared(support, rhs.isShared);
    }

    this(immutable ref typeof(this) rhs) immutable
    {
        mixin(copyCtorIncRef);
    }

    // } Get an immutable obj

    // }
    // End Copy Ctors

    // Immutable ctors
    private this(SuppQual, PaylQual, this Qualified)(SuppQual _support, PaylQual _payload, bool _isShared)
        if (is(typeof(support) : typeof(_support)))
    {
        support = _support;
        payload = _payload;
        //isShared = _isShared;
        setIsShared(support, _isShared);
        if (support !is null)
        {
            addRef(support);
        }
    }

    ~this()
    {
        destroyUnused();
    }

    static if (is(T == int))
    @nogc nothrow pure @safe unittest
    {
        auto a = rcarray!int(1, 2, 3);

        // Infer safety
        static assert(!__traits(compiles, () @safe { rcarray!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = const rcarray!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = immutable rcarray!Unsafe(Unsafe(1)); }));

        static assert(!__traits(compiles, () @safe { rcarray!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = const rcarray!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = immutable rcarray!UnsafeDtor(UnsafeDtor(1)); }));

        // Infer purity
        static assert(!__traits(compiles, () pure { rcarray!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = const rcarray!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = immutable rcarray!Impure(Impure(1)); }));

        static assert(!__traits(compiles, () pure { rcarray!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = const rcarray!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = immutable rcarray!ImpureDtor(ImpureDtor(1)); }));

        // Infer throwability
        static assert(!__traits(compiles, () nothrow { rcarray!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = const rcarray!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = immutable rcarray!Throws(Throws(1)); }));

        static assert(!__traits(compiles, () nothrow { rcarray!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = const rcarray!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = immutable rcarray!ThrowsDtor(ThrowsDtor(1)); }));
    }

    private @nogc nothrow pure @trusted
    size_t slackFront() const
    {
        return payload.ptr - support.ptr;
    }

    private @nogc nothrow pure @trusted
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
    @nogc nothrow pure @safe
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
        payload = (() @trusted => cast(T[])(support[slackFront .. len]))();
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
    @nogc nothrow pure @safe
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

        static if (__traits(hasMember, typeof(localAllocator), "expand"))
        if (support && opCmpPrefix!"=="(support, 1))
        {
            void[] buf = support;
            version (CoreUnittest)
            {
                auto successfulExpand = pureExpand(isShared, buf, (n - capacity) * stateSize!T);
            }
            else
            {
                auto successfulExpand = localAllocator.expand(buf, (n - capacity) * stateSize!T);
            }

            if (successfulExpand)
            {
                const oldLength = support.length;
                support = (() @trusted => cast(Unqual!T[])(buf))();
                // Emplace extended buf
                // TODO: maybe? emplace only if T has indirections
                foreach (i; oldLength .. support.length)
                {
                    emplace(&support[i]);
                }
                return;
            }
            else
            {
                assert(0, "Array.reserve: Failed to expand array.");
            }
        }

        version (CoreUnittest)
        {
            // TODO ok?
            auto tmpSupport = (() @trusted  => cast(Unqual!T[])(pureAllocate(false, n * stateSize!T)))();
            //auto tmpSupport = (() @trusted  => cast(Unqual!T[])(pureAllocate(isShared, n * stateSize!T)))();
        }
        else
        {
            auto tmpSupport = (() @trusted => cast(Unqual!T[])(localAllocator.allocate(n * stateSize!T)))();
        }
        assert(tmpSupport !is null);
        for (size_t i = 0; i < tmpSupport.length; ++i)
        {
            if (i < payload.length)
            {
                emplace(&tmpSupport[i], payload[i]);
            }
            else
            {
                emplace(&tmpSupport[i]);
            }
        }

        destroyUnused();
        support = tmpSupport;
        addRef(support);
        payload = (() @trusted => cast(T[])(support[0 .. payload.length]))();
        assert(capacity >= n);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        rcarray!int a;
        a.reserve(stuff.length);
        a ~= stuff;
        assert(a == stuff);
    }

    /**
     * Inserts the elements of an array, or a built-in array or an element
     * at the given `pos`.
     *
     * Params:
     *      pos = a positive integer
     *      stuff = an element, or an array, or built-in array of elements that
     *              are implitictly convertible to `T`
     *
     * Returns:
     *      the number of elements inserted
     *
     * Complexity: $(BIGOH max(length, pos + m)), where `m` is the number of
     *             elements in the range.
     */
    size_t insert(Stuff)(size_t pos, Stuff stuff)
    if (is(Stuff == rcarray!T))
    {
        mixin(insertImpl);
    }

    size_t insert(U)(size_t pos, U[] stuff...)
    if (is(U : T))
    {
        mixin(insertImpl);
    }

    private enum insertImpl = q{
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        assert(pos <= payload.length);

        if (stuff.length == 0) return 0;
        if (stuff.length > slackBack)
        {
            double newCapacity = capacity ? capacity * capacityFactor : stuff.length;
            while (newCapacity < capacity + stuff.length)
            {
                newCapacity = newCapacity * capacityFactor;
            }
            reserve((() @trusted => cast(size_t)(newCapacity))());
        }
        //support[pos + stuff.length .. payload.length + stuff.length] =
            //support[pos .. payload.length];
        for (size_t i = payload.length + stuff.length - 1; i >= pos +
                stuff.length; --i)
        {
            // Avoids underflow if payload is empty
            support[i] = support[i - stuff.length];
        }

        // Can't use below, because it doesn't do opAssign, but memcpy
        //support[pos .. pos + stuff.length] = stuff[];
        for (size_t i = pos, j = 0; i < pos + stuff.length; ++i, ++j) {
            support[i] = stuff[j];
        }

        payload = (() @trusted => cast(T[])(support[0 .. payload.length + stuff.length]))();
        return stuff.length;
    };

    ///
    static if (is(T == int))
    @safe unittest
    {
        rcarray!int a;
        assert(a.length == 0);

        size_t pos = 0;
        pos += a.insert(pos, 1);
        pos += a.insert(pos, [2, 3]);
        assert(a == [1, 2, 3]);
    }

    /**
     * Check whether there are no more references to this array instance.
     *
     * Returns:
     *      `true` if this is the only reference to this array instance;
     *      `false` otherwise.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe
    bool isUnique(this _)()
    {
        if (support !is null)
        {
            return cast(bool) opCmpPrefix!"=="(support, 1);
        }
        return true;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(24, 42);

        assert(a.isUnique);
        {
            auto a2 = a;
            assert(!a.isUnique);
            a2[0] = 0;
            assert(a[0] == 0);
        } // a2 goes out of scope
        assert(a.isUnique);
    }

    /**
     * Eagerly iterate over each element in the array and call `fun` over each
     * element. This should be used to iterate through `const` and `immutable`
     * arrays.
     *
     * Normally, the entire array is iterated. If partial iteration (early stopping)
     * is desired, `fun` needs to return a value of a comparable type, `CT`,
     * (`CT.init` to stop, or anything else to continue the iteration).
     *
     * Params:
     *      fun = unary function to apply on each element of the array.
     *
     * Returns:
     *      `true` if it has iterated through all the elements in the array, or
     *      `false` otherwise.
     *
     * Complexity: $(BIGOH n).
     */
    template each(alias fun)
    {
        //import std.functional : unaryFun;

        bool each(this Q)()
        //if (is (typeof(unaryFun!fun(T.init))))
        {
            //alias fn = unaryFun!fun;
            alias fn = fun;

            // Iterate through the underlying payload
            // The array is kept alive (rc > 0) from the caller scope
            foreach (ref e; this.payload)
            {
                alias Result = typeof(fn(e));
                static if (is(typeof(Result.init == Result.init)))
                {
                    if (fn(e) == Result.init)
                        return false;
                }
                else
                {
                    cast(void) fn(e);
                }
            }
            return true;
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto ia = immutable rcarray!int([3, 2, 1]);

        static bool foo(int x) { return x > 0; }
        static int bar(int x) { return x > 1 ? 1 : 0; }

        assert(ia.each!foo == true);
        assert(ia.each!bar == false);
    }

    @safe unittest
    {
        {
            auto ia = immutable rcarray!int([3, 2, 1]);

            static bool foo(int x) { return x > 0; }
            static int bar(int x) { return x > 1 ? 1 : 0; }

            assert(ia.each!foo == true);
            assert(ia.each!bar == false);
        }

        assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
        assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
    }

    //int opApply(int delegate(const ref T) dg) const
    //{
        //if (payload.length && dg(payload[0])) return 1;
        //if (!this.empty) this.tail.opApply(dg);
        //return 0;
    //}

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
        return immutable rcarray!T(this);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        {
            auto a = rcarray!(int)(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = const rcarray!(int)(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = immutable rcarray!(int)(1, 2, 3);
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
    rcarray!T dup(this Q)()
    {
        return rcarray!T(payload);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
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
    Qualified opSlice(this Qualified)()
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
    Qualified opSlice(this Qualified)(size_t start, size_t end)
    {
        version (D_NoBoundsChecks) { } else
        {
            assert(start <= end && end <= length,
                   "Array.opSlice(s, e): Invalid bounds: Ensure start <= end <= length");
        }
        return typeof(this)(support, payload[start .. end], isShared);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = rcarray!int(stuff);
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
    ref auto opIndex(this _)(size_t idx)
    {
        version (D_NoBoundsChecks) { } else
        {
            assert(idx < length, "Array.opIndex: Index out of bounds");
        }
        return payload[idx];
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3]);
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
    ref auto opIndexUnary(string op)(size_t idx)
    {
        version (D_NoBoundsChecks) { } else
        {
            assert(idx < length, "Array.opIndexUnary!" ~ op ~ ": Index out of bounds");
        }
        mixin("return " ~ op ~ "payload[idx];");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3]);
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
    ref auto opIndexAssign(U)(U elem, size_t idx)
    if (is(U : T))
    {
        version (D_NoBoundsChecks) { } else
        {
            assert(idx < length, "Array.opIndexAssign: Index out of bounds");
        }
        return payload[idx] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3]);
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
    ref auto opIndexAssign(U)(U elem)
    if (is(U : T))
    body
    {
        payload[] = elem;
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3]);
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
        version (D_NoBoundsChecks) { } else
        {
            assert(start <= end, "Array.opSliceAssign: Index out of bounds");
            assert(end < length, "Array.opSliceAssign: Index out of bounds");
        }
        return payload[start .. end] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3, 4, 5, 6]);
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
    ref auto opIndexOpAssign(string op, U)(U elem, size_t idx)
    if (is(U : T))
    {
        version (D_NoBoundsChecks) { } else
        {
            assert(idx < length, "Array.opIndexOpAssign!" ~ op ~ ": Index out of bounds");
        }
        mixin("return payload[idx]" ~ op ~ "= elem;");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int([1, 2, 3]);
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
            foreach(i; 0 .. rhs.length)
            {
                newArray ~= rhs[i];
            }
        }
        else
        {
            newArray.insert(length, rhs);
            // Or
            // newArray ~= rhs;
        }
        return newArray;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1);
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
        if (rhs.support !is null && support is rhs.support)
        {
            if (rhs.payload is payload)
                return this;
        }

        if (rhs.support !is null)
        {
            rhs.addRef(rhs.support);
        }
        destroyUnused();
        support = rhs.support;
        payload = rhs.payload;
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = rcarray!int(1);
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
        insert(length, rhs);
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        rcarray!int a;
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
    bool opEquals(U)(const U rhs) const
    if (is(U : const typeof(this))
        || (is(U : const V[], V) && is(typeof(T.init == V.init))))
    {
        auto a = this;
        if (a.length != rhs.length) return false;

        for (size_t i = 0; i < a.length; ++i)
        {
            if (a[i] != rhs[i]) return false;
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
        assert(rcarray!int().toHash == rcarray!int().toHash);
    }
}

version (CoreUnittest)
{ // Begin CoreUnittest - conditional compilation so we can check for mem leaks

template CommonType(T...)
{
    static if (is(typeof(T[0])))
    {
        alias CommonType = typeof(T[0]);
    }
    else
    {
        alias CommonType = T[0];
    }
}

CommonType!T[T.length] staticArray(T...)(T args)
if (is(CommonType!T))
{
    return [args];
}

unittest {
    auto a = staticArray(1,2,3,4);
    static assert(is(typeof(a) == int[4]));
}

private nothrow pure @safe
void testConcatAndAppend()
{
    auto a = rcarray!(int)(1, 2, 3);
    rcarray!(int) a2 = rcarray!(int)();

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

    a3 ~= a3;
    assert(a3 == [1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7]);

    rcarray!int a5 = rcarray!(int)();
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
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
}

private nothrow pure @safe
void testSimple()
{
    auto a = rcarray!int();
    assert(a.length == 0);
    assert(a.isUnique);

    size_t pos = 0;
    a.insert(pos, 1, 2, 3);
    assert(a[0] == 1);
    assert(a == a);
    assert(a == [1, 2, 3]);

    a = a[1 .. $];
    assert(a[0] == 2);
    assert(a == [2, 3]);

    a.insert(pos, [4, 5, 6]);
    a.insert(pos, 7);
    a.insert(pos, [8]);
    assert(a == [8, 7, 4, 5, 6, 2, 3]);

    a.insert(a.length, 0, 1);
    a.insert(a.length, [-1, -2]);
    assert(a == [8, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]);

    a[0] = 9;
    assert(a == [9, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]);

    auto aTail = a[1 .. $];
    assert(aTail[0] == 7);
    aTail[0] = 8;
    assert(aTail[0] == 8);
    assert(a[1 .. $][0] == 8);
    assert(!a.isUnique);
}

@safe unittest
{
    () nothrow pure @safe {
        testSimple();
    }();
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
}

private nothrow pure @safe
void testSimpleImmutable()
{
    auto a = rcarray!(immutable int)();
    assert(a.length == 0);

    size_t pos = 0;
    a.insert(pos, 1, 2, 3);
    assert(a[0] == 1);
    assert(a == a);
    assert(a == [1, 2, 3]);

    a = a[1 .. $];
    assert(a[0] == 2);
    assert(a == [2, 3]);
    assert(a[1 .. $][0] == 3);

    a.insert(pos, [4, 5, 6]);
    a.insert(pos, 7);
    a.insert(pos, [8]);
    assert(a == [8, 7, 4, 5, 6, 2, 3]);

    a.insert(a.length, 0, 1);
    a.insert(a.length, [-1, -2]);
    assert(a == [8, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]);

    // Cannot modify immutable values
    static assert(!__traits(compiles, { a[0] = 9; }));
}

@safe unittest
{
    () nothrow pure @safe {
        testSimpleImmutable();
    }();
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
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

    size_t pos = 0;
    rcarray!int aInsFromRange = rcarray!int();
    aInsFromRange.insert(pos, aFromList);
    aFromList = aFromList[1 .. $];
    assert(aFromList == [3]);
    assert(aInsFromRange == [2, 3]);

    rcarray!int aInsBackFromRange = rcarray!int();
    aInsBackFromRange.insert(pos, aFromList);
    aFromList = aFromList[1 .. $];
    assert(aFromList.length == 0);
    assert(aInsBackFromRange == [3]);

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
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
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
    static assert(!__traits(compiles, a4 = a4.tail));

    // Create a mutable copy from an immutable array
    auto a5 = a.dup();
    assert(a5 == [1, 2, 3]);
    assert(a5[0] == 1);
    a5[0] = 2;
    assert(a5[0] == 2);
    assert(a[0] == 1);
    assert(a5 == [2, 2, 3]);

    enum isSharedMask = 1UL << ((PrefixAllocator.prefixSize * 8) - 1);

    // Create immtable copies from mutable, const and immutable
    {
        auto aa = rcarray!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa.support, 1));
        assert(aa2.opCmpPrefix!"=="(aa2.support, (1 | isSharedMask)));
    }

    {
        auto aa = const rcarray!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa.support, 1));
        assert(aa2.opCmpPrefix!"=="(aa2.support, (1 | isSharedMask)));
    }

    {
        auto aa = immutable rcarray!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa.support, (2 | isSharedMask)));
        assert(aa2.opCmpPrefix!"=="(aa2.support, (2 | isSharedMask)));
    }
}

private nothrow pure @safe
void testConstness()
{
    auto a = const rcarray!(int)(1, 2, 3);
    auto a2 = a;
    immutable rcarray!int a5 = a;
    enum isSharedMask = 1UL << ((PrefixAllocator.prefixSize * 8) - 1);

    assert(a5.opCmpPrefix!"=="(a5.support, (1 | isSharedMask)));
    assert(a.opCmpPrefix!"=="(a.support, 2));

    assert(a2[0] == 1);
    assert(a2[0] == a2[0]);
    static assert(!__traits(compiles, { a2[0] = 4; }));
    static assert(!__traits(compiles, { a2 = a2[1 .. $]; }));

    auto a4 = a2[1 .. $];
    assert(a4[0] == 2);
    static assert(!__traits(compiles, a4 = a4.tail));
}

@safe unittest
{
    () nothrow pure @safe {
        testImmutability();
        testConstness();
    }();
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
}

private nothrow pure @safe
void testWithStruct()
{
    enum isSharedMask = 1UL << ((PrefixAllocator.prefixSize * 8) - 1);
    auto array = rcarray!int(1, 2, 3);
    {
        assert(array.opCmpPrefix!"=="(array.support, 1));

        auto arrayOfArrays = rcarray!(rcarray!int)(array);
        assert(array.opCmpPrefix!"=="(array.support, 2));
        assert(arrayOfArrays[0] == [1, 2, 3]);
        arrayOfArrays[0][0] = 2;
        assert(arrayOfArrays[0] == [2, 2, 3]);
        assert(arrayOfArrays[0] == array);
        static assert(!__traits(compiles, arrayOfArrays.insert(1)));

        auto immArrayOfArrays = immutable rcarray!(rcarray!int)(array);

        // immutable is transitive, so it must iterate over array and
        // create a copy, and not set a ref
        assert(array.opCmpPrefix!"=="(array.support, 2));
        array[0] = 3;
        assert(immArrayOfArrays[0][0] == 2);
        assert(immArrayOfArrays.opCmpPrefix!"=="(immArrayOfArrays.support, (1 | isSharedMask)));
        assert(immArrayOfArrays[0].opCmpPrefix!"=="(immArrayOfArrays[0].support, (1 | isSharedMask)));
        static assert(!__traits(compiles, { immArrayOfArrays[0][0] = 2; }));
        static assert(!__traits(compiles, { immArrayOfArrays[0] = array; }));
    }
    assert(array.opCmpPrefix!"=="(array.support, 1));
    assert(array == [3, 2, 3]);
}

@safe unittest
{
    () nothrow pure @safe {
        testWithStruct();
    }();
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
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
        rcarray!MyClass a = rcarray!MyClass(c);
        assert(a[0].x == 10);
        assert(a[0] is c);
        a[0].x = 20;
    }
    assert(c.x == 20);
}

@safe unittest
{
    () nothrow pure @safe {
        testWithClass();
    }();
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
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
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
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
    assert(localAllocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(sharedAllocator.bytesUsed == 0, "Array ref count leaks memory");
}

} // End CoreUnittest
