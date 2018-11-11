///
module core.experimental.array;

// { "Imports" from Phobos

// Range functions

/**
Implements the range interface primitive `front` for built-in arrays. Due to the
fact that nonmember functions can be called with the first argument using the dot
notation, `array.front` is equivalent to `front(array)`. For $(GLOSSARY narrow strings),
`front` automatically returns the first $(GLOSSARY code point) as _a `dchar`.
*/
@property ref T front(T)(T[] a) @safe pure nothrow @nogc
//TODO: if (!isNarrowString!(T[]) && !is(T[] == void[]))
if (!is(T[] == void[]))
{
    assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
    return a[0];
}

/**
Implements the range interface primitive `empty` for types that obey `hasLength`
property and for narrow strings.
 */
@property bool empty(T)(auto ref scope const(T) a)
//TODO: if (is(typeof(a.length) : size_t) || isNarrowString!T)
if (is(typeof(a.length) : size_t))
{
    return !a.length;
}

/**
Implements the range interface primitive `popFront` for built-in arrays. For
$(GLOSSARY narrow strings), `popFront` automatically advances to the next
$(GLOSSARY code point).
*/
void popFront(T)(ref T[] a) @safe pure nothrow @nogc
//TODO: if (!isNarrowString!(T[]) && !is(T[] == void[]))
if (!is(T[] == void[]))
{
    assert(a.length, "Attempting to popFront() past the end of an array of " ~ T.stringof);
    a = a[1 .. $];
}

/**
This is a best-effort implementation of `length` for any kind of range.
*/
auto walkLength(Range)(Range range)
if (isInputRange!Range && !isInfinite!Range)
{
    static if (hasLength!Range)
        return range.length;
    else
    {
        size_t result;
        for ( ; !range.empty ; range.popFront() )
            ++result;
        return result;
    }
}

/**
*/
enum bool isInputRange(R) =
    is(typeof(R.init) == R)
    && is(typeof(R.init.empty()) == bool)
    && is(typeof((return ref R r) => r.front))
    && !is(typeof(R.init.front()) == void)
    && is(typeof((R r) => r.popFront));

/**
*/
template isInfinite(R)
{
    static if (isInputRange!R && __traits(compiles, { enum e = R.empty; }))
        enum bool isInfinite = !R.empty;
    else
        enum bool isInfinite = false;
}

// End Range functions

/**
Yields `true` if and only if `T` is an aggregate that defines a symbol called `name`.
 */
enum hasMember(T, string name) = __traits(hasMember, T, name);

/**
Detect whether type `T` is an array (static or dynamic.
*/
enum bool isArray(T) = isStaticArray!T || isDynamicArray!T;

/**
 * Detect whether type `T` is a static array.
 */
enum bool isStaticArray(T) = __traits(isStaticArray, T);

/**
 * Detect whether type `T` is a dynamic array.
 */
enum bool isDynamicArray(T) = is(DynamicArrayTypeOf!T) && !isAggregateType!T;

/*
 */
template DynamicArrayTypeOf(T)
{
    static if (is(AliasThisTypeOf!T AT) && !is(AT[] == AT))
        alias X = DynamicArrayTypeOf!AT;
    else
        alias X = OriginalType!T;

    static if (is(Unqual!X : E[], E) && !is(typeof({ enum n = X.length; })))
    {
        alias DynamicArrayTypeOf = X;
    }
    else
        static assert(0, T.stringof~" is not a dynamic array");
}

// SomethingTypeOf
private template AliasThisTypeOf(T)
if (isAggregateType!T)
{
    alias members = AliasSeq!(__traits(getAliasThis, T));

    static if (members.length == 1)
    {
        alias AliasThisTypeOf = typeof(__traits(getMember, T.init, members[0]));
    }
    else
        static assert(0, T.stringof~" does not have alias this type");
}

template AliasSeq(TList...)
{
    alias AliasSeq = TList;
}

/**
 * Strips off all `enum`s from type `T`.
 */
template OriginalType(T)
{
    template Impl(T)
    {
        static if (is(T U == enum)) alias Impl = OriginalType!U;
        else                        alias Impl =              T;
    }

    alias OriginalType = ModifyTypePreservingTQ!(Impl, T);
}

// [For internal use]
private template ModifyTypePreservingTQ(alias Modifier, T)
{
         static if (is(T U ==          immutable U)) alias ModifyTypePreservingTQ =          immutable Modifier!U;
    else static if (is(T U == shared inout const U)) alias ModifyTypePreservingTQ = shared inout const Modifier!U;
    else static if (is(T U == shared inout       U)) alias ModifyTypePreservingTQ = shared inout       Modifier!U;
    else static if (is(T U == shared       const U)) alias ModifyTypePreservingTQ = shared       const Modifier!U;
    else static if (is(T U == shared             U)) alias ModifyTypePreservingTQ = shared             Modifier!U;
    else static if (is(T U ==        inout const U)) alias ModifyTypePreservingTQ =        inout const Modifier!U;
    else static if (is(T U ==        inout       U)) alias ModifyTypePreservingTQ =              inout Modifier!U;
    else static if (is(T U ==              const U)) alias ModifyTypePreservingTQ =              const Modifier!U;
    else                                             alias ModifyTypePreservingTQ =                    Modifier!T;
}

/**
 * Detect whether type `T` is an aggregate type.
 */
enum bool isAggregateType(T) = is(T == struct) || is(T == union) ||
                               is(T == class) || is(T == interface);

/**
Removes all qualifiers, if any, from type `T`.
 */
template Unqual(T)
{
    version (none) // Error: recursive alias declaration @@@BUG1308@@@
    {
             static if (is(T U ==     const U)) alias Unqual = Unqual!U;
        else static if (is(T U == immutable U)) alias Unqual = Unqual!U;
        else static if (is(T U ==     inout U)) alias Unqual = Unqual!U;
        else static if (is(T U ==    shared U)) alias Unqual = Unqual!U;
        else                                    alias Unqual =        T;
    }
    else // workaround
    {
             static if (is(T U ==          immutable U)) alias Unqual = U;
        else static if (is(T U == shared inout const U)) alias Unqual = U;
        else static if (is(T U == shared inout       U)) alias Unqual = U;
        else static if (is(T U == shared       const U)) alias Unqual = U;
        else static if (is(T U == shared             U)) alias Unqual = U;
        else static if (is(T U ==        inout const U)) alias Unqual = U;
        else static if (is(T U ==        inout       U)) alias Unqual = U;
        else static if (is(T U ==              const U)) alias Unqual = U;
        else                                             alias Unqual = T;
    }
}

/**
Is `From` implicitly convertible to `To`?
 */
enum bool isImplicitlyConvertible(From, To) = is(From : To);

/**
The element type of `R`. `R` does not have to be a range. The element type is
determined as the type yielded by `r.front` for an object `r` of type `R`. For
example, `ElementType!(T[])` is `T` if `T[]` isn't a narrow string; if it is, the
element type is `dchar`. If `R` doesn't have `front`, `ElementType!R` is `void`.
 */
template ElementType(R)
{
    static if (is(typeof(R.init.front.init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

/**
Yields `true` if `R` has a `length` member that returns a value of `size_t`
type. `R` does not have to be a range. If `R` is a range, algorithms in the
standard library are only guaranteed to support `length` with type `size_t`.
*/
template hasLength(R)
{
    static if (is(typeof(((R* r) => r.length)(null)) Length))
        enum bool hasLength = is(Length == size_t);
        //TODO: enum bool hasLength = is(Length == size_t) && !isNarrowString!R;
    else
        enum bool hasLength = false;
}

// { Allocators

/**
Returns the size in bytes of the state that needs to be allocated to hold an
object of type `T`. `stateSize!T` is zero for `struct`s that are not
nested and have no nonstatic member variables.
 */
template stateSize(T)
{
    static if (is(T == class) || is(T == interface))
        enum stateSize = __traits(classInstanceSize, T);
    else static if (is(T == void))
        enum size_t stateSize = 0;
    else
        enum stateSize = T.sizeof;
}

template isAbstractClass(T...)
if (T.length == 1)
{
    enum bool isAbstractClass = __traits(isAbstractClass, T[0]);
}

template isInnerClass(T)
if (is(T == class))
{
    static if (is(typeof(T.outer)))
        enum isInnerClass = __traits(isSame, typeof(T.outer), __traits(parent, T));
    else
        enum isInnerClass = false;
}

enum classInstanceAlignment(T) = size_t.alignof >= T.alignof ? size_t.alignof : T.alignof;

T emplace(T, Args...)(T chunk, auto ref Args args)
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

T emplace(T, Args...)(void[] chunk, auto ref Args args)
if (is(T == class))
{
    enum classSize = __traits(classInstanceSize, T);
    testEmplaceChunk(chunk, classSize, classInstanceAlignment!T);
    return emplace!T(cast(T)(chunk.ptr), args);
}

T* emplace(T, Args...)(void[] chunk, auto ref Args args)
if (!is(T == class))
{
    testEmplaceChunk(chunk, T.sizeof, T.alignof);
    emplaceRef!(T, Unqual!T)(*cast(Unqual!T*) chunk.ptr, args);
    return cast(T*) chunk.ptr;
}

T* emplace(T)(T* chunk) @safe pure nothrow
{
    emplaceRef!T(*chunk);
    return chunk;
}

T* emplace(T, Args...)(T* chunk, auto ref Args args)
if (is(T == struct) || Args.length == 1)
{
    emplaceRef!T(*chunk, args);
    return chunk;
}

package void emplaceRef(T, UT, Args...)(ref UT chunk, auto ref Args args)
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
package void emplaceRef(UT, Args...)(ref UT chunk, auto ref Args args)
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

enum hasElaborateDestructor(T) = __traits(compiles, { T t; t.__dtor(); })
                                 ||  __traits(compiles, { T t; t.__xdtor(); });

void dispose(A, T)(auto ref A alloc, auto ref T* p)
{
    static if (hasElaborateDestructor!T)
    {
        destroy(*p);
    }
    alloc.deallocate((cast(void*) p)[0 .. T.sizeof]);
    static if (__traits(isRef, p))
        p = null;
}

void dispose(A, T)(auto ref A alloc, auto ref T p)
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

void dispose(A, T)(auto ref A alloc, auto ref T[] array)
{
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

auto tail(Collection)(Collection collection)
if (isInputRange!Collection)
{
    collection.popFront();
    return collection;
}

auto equal(T, U)(T a, U b)
if (is(ElementType!T : ElementType!U)
     && (is(T : V[], V) || is(T : Array!V2, V2))
     && (is(U : V4[], V4) || is(U : Array!V3, V3)))
{
    if (a.length != b.length) return false;

    while (!a.empty)
    {
        if (a.front != b.front) return false;
        a.popFront();
        b.popFront();
    }
    return true;
}

@safe unittest
{
    auto a = [1, 2, 3];
    auto b = Array!int(a);

    assert(equal(a, a));
    assert(equal(a, b));
    assert(equal(b, a));
    assert(equal(b, b));
    a ~= 1;
    assert(!equal(a, b));
}

struct PrefixAllocator
{
    /**
    The alignment is a static constant equal to `platformAlignment`, which
    ensures proper alignment for any D data type.
    */
    enum uint alignment = size_t.alignof;
    static enum prefixSize = size_t.sizeof;

    version(unittest)
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

        version(unittest)
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

        version(unittest)
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


version(unittest)
{
    private alias SCAlloc = shared PrefixAllocator;
    private alias SSCAlloc = shared PrefixAllocator;

    SCAlloc _allocator;
    SSCAlloc _sallocator;

    @nogc nothrow pure @trusted
    void[] pureAllocate(bool isShared, size_t n)
    {
        return (cast(void[] function(bool, size_t) @nogc nothrow pure)(&_allocate))(isShared, n);
    }

    @nogc nothrow @safe
    void[] _allocate(bool isShared, size_t n)
    {
        return isShared ? _sallocator.allocate(n) : _allocator.allocate(n);
    }

    static if (hasMember!(typeof(_allocator), "expand"))
    {
        @nogc nothrow pure @trusted
        bool pureExpand(bool isShared, ref void[] b, size_t delta)
        {
            return (cast(bool function(bool, ref void[], size_t) @nogc nothrow pure)(&_expand))(isShared, b, delta);
        }

        @nogc nothrow @safe
        bool _expand(bool isShared, ref void[] b, size_t delta)
        {
            return isShared ?  _sallocator.expand(b, delta) : _allocator.expand(b, delta);
        }
    }

    @nogc nothrow pure
    void pureDispose(T)(bool isShared, T[] b)
    {
        return (cast(void function(bool, T[]) @nogc nothrow pure)(&_dispose!(T)))(isShared, b);
    }

    @nogc nothrow
    void _dispose(T)(bool isShared, T[] b)
    {
        return isShared ?  _sallocator.dispose(b) : _allocator.dispose(b);
    }
}

///
struct Array(T)
{
    import core.atomic : atomicOp;

    package T[] _payload;
    package Unqual!T[] _support;

    version(unittest)
    {
    }
    else
    {
        alias _allocator = shared PrefixAllocator.instance;
        alias _sallocator = shared PrefixAllocator.instance;
    }

private:

    static enum double capacityFactor = 3.0 / 2;
    static enum initCapacity = 3;

    bool _isShared;

    @trusted
    auto pref() const
    {
        assert(_support !is null);
        if (_isShared)
        {
            return _sallocator.prefix(_support);
        }
        else
        {
            return _allocator.prefix(_support);
        }
    }

    private size_t _opPrefix(string op, T)(const T[] support, size_t val) const
    {
        assert(support !is null);
        if (_isShared)
        {
            return cast(size_t)(atomicOp!op(*cast(shared size_t *)&_sallocator.prefix(support), val));
        }
        else
        {
            mixin("return cast(size_t)(*cast(size_t *)&_allocator.prefix(support)" ~ op ~ "val);");
        }
    }

    @nogc nothrow pure @trusted
    size_t opPrefix(string op, T)(const T[] support, size_t val) const
    if ((op == "+=") || (op == "-="))
    {

        return (cast(size_t delegate(const T[], size_t) const @nogc nothrow pure)(&_opPrefix!(op, T)))(support, val);
    }

    @nogc nothrow pure @trusted
    size_t opCmpPrefix(string op, T)(const T[] support, size_t val) const
    if ((op == "==") || (op == "<=") || (op == "<") || (op == ">=") || (op == ">"))
    {
        return (cast(size_t delegate(const T[], size_t) const @nogc nothrow pure)(&_opPrefix!(op, T)))(support, val);
    }

    @nogc nothrow pure @trusted
    void addRef(SupportQual, this Q)(SupportQual support)
    {
        assert(support !is null);
        cast(void) opPrefix!("+=")(support, 1);
    }

    void delRef(Unqual!T[] support)
    {
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        assert(support !is null);
        if (opPrefix!("-=")(support, 1) == 0)
        {
            () @trusted {
                version(unittest)
                {
                    pureDispose(_isShared, support);
                }
                else
                {
                    _allocator.dispose(support);
                }
            }();
        }
    }

    static string immutableInsert(StuffType)(string stuff)
    {
        static if (hasLength!StuffType)
        {
            auto stuffLengthStr = q{
                size_t stuffLength = } ~ stuff ~ ".length;";
        }
        else
        {
            auto stuffLengthStr = q{
                size_t stuffLength = walkLength(} ~ stuff ~ ");";
        }

        return stuffLengthStr ~ q{

        version(unittest)
        {
            void[] tmpSupport = (() @trusted => pureAllocate(_isShared, stuffLength * stateSize!T))();
        }
        else
        {
            void[] tmpSupport;
            if (_isShared)
            {
                tmpSupport = (() @trusted => _sallocator.allocate(stuffLength * stateSize!T))();
            }
            else
            {
                tmpSupport = (() @trusted => _allocator.allocate(stuffLength * stateSize!T))();
            }
        }

        assert(stuffLength == 0 || (stuffLength > 0 && tmpSupport !is null));
        size_t i = 0;
        foreach (ref item; } ~ stuff ~ q{)
        {
            //writefln("the type is %s %s %s", T.stringof, typeof(_support).stringof, typeof(_payload).stringof);
            alias TT = ElementType!(typeof(_payload));
            //pragma(msg, typeof(item).stringof, " TT is ", TT.stringof);

            size_t s = i * stateSize!TT;
            size_t e = (i + 1) * stateSize!TT;
            void[] tmp = tmpSupport[s .. e];
            i++;
            (() @trusted => emplace!TT(tmp, item))();
        }

        _support = (() @trusted => cast(typeof(_support))(tmpSupport))();
        _payload = (() @trusted => cast(typeof(_payload))(_support[0 .. stuffLength]))();
        if (_support) addRef(_support);
        };
    }

    void destroyUnused()
    {
        if (_support !is null)
        {
            delRef(_support);
        }
    }

public:
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
    //version(none)
    this(U, this Q)(U[] values...)
    if (!is(Q == shared)
        && isImplicitlyConvertible!(U, T))
    {
        static if (is(Q == immutable) || is(Q == const))
        {
            _isShared = true;
            mixin(immutableInsert!(typeof(values))("values"));
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
            auto a = Array!int(1, 2, 3);
            assert(equal(a, [1, 2, 3]));
        }
        // Create a list from an array of ints
        {
            auto a = Array!int([1, 2, 3]);
            assert(equal(a, [1, 2, 3]));
        }
        // Create a list from a list from an input range
        {
            auto a = Array!int(1, 2, 3);
            auto a2 = Array!int(a);
            assert(equal(a2, [1, 2, 3]));
        }
    }

    /**
     * Constructs a qualified array out of an
     * $(REF_ALTTEXT input range, isInputRange, std,range,primitives)
     * that will use the collection decided allocator object.
     * If `Stuff` defines `length`, `Array` will use it to reserve the
     * necessary amount of memory.
     *
     * Params:
     *      stuff = an input range of elements that are implitictly convertible
     *              to `T`
     *
     * Complexity: $(BIGOH m), where `m` is the number of elements in the range.
     */
    this(Stuff, this Q)(Stuff stuff)
    if (!is(Q == shared)
        && isInputRange!Stuff && !isInfinite!Stuff
        && isImplicitlyConvertible!(ElementType!Stuff, T)
        && !is(Stuff == T[]))
    {
        static if (is(Q == immutable) || is(Q == const))
        {
            _isShared = true;
            mixin(immutableInsert!(typeof(stuff))("stuff"));
        }
        else
        {
            insert(0, stuff);
        }
    }

    // Begin Copy Ctors
    // {

    private static enum copyCtorIncRef = q{
        _payload = rhs._payload;
        _support = rhs._support;
        _isShared = rhs._isShared;

        if (_support !is null)
        {
            addRef(_support);
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
        _isShared = true;
        mixin(immutableInsert!(typeof(rhs))("rhs"));
    }

    this(const ref typeof(this) rhs) immutable
    {
        _isShared = rhs._isShared;
        mixin(immutableInsert!(typeof(rhs._payload))("rhs._payload"));
    }

    this(immutable ref typeof(this) rhs) immutable
    {
        mixin(copyCtorIncRef);
    }

    // } Get an immutable obj

    // }
    // End Copy Ctors

    // Immutable ctors
    private this(SuppQual, PaylQual, this Qualified)(SuppQual support, PaylQual payload, bool isShared)
        if (is(typeof(_support) : typeof(support)))
    {
        _support = support;
        _payload = payload;
        _isShared = isShared;
        if (_support !is null)
        {
            addRef(_support);
        }
    }

    ~this()
    {
        destroyUnused();
    }

    static if (is(T == int))
    @nogc nothrow pure @safe unittest
    {
        auto a = Array!int(1, 2, 3);

        // Infer safety
        static assert(!__traits(compiles, () @safe { Array!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = const Array!Unsafe(Unsafe(1)); }));
        static assert(!__traits(compiles, () @safe { auto a = immutable Array!Unsafe(Unsafe(1)); }));

        static assert(!__traits(compiles, () @safe { Array!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = const Array!UnsafeDtor(UnsafeDtor(1)); }));
        static assert(!__traits(compiles, () @safe { auto s = immutable Array!UnsafeDtor(UnsafeDtor(1)); }));

        // Infer purity
        static assert(!__traits(compiles, () pure { Array!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = const Array!Impure(Impure(1)); }));
        static assert(!__traits(compiles, () pure { auto a = immutable Array!Impure(Impure(1)); }));

        static assert(!__traits(compiles, () pure { Array!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = const Array!ImpureDtor(ImpureDtor(1)); }));
        static assert(!__traits(compiles, () pure { auto s = immutable Array!ImpureDtor(ImpureDtor(1)); }));

        // Infer throwability
        static assert(!__traits(compiles, () nothrow { Array!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = const Array!Throws(Throws(1)); }));
        static assert(!__traits(compiles, () nothrow { auto a = immutable Array!Throws(Throws(1)); }));

        static assert(!__traits(compiles, () nothrow { Array!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = const Array!ThrowsDtor(ThrowsDtor(1)); }));
        static assert(!__traits(compiles, () nothrow { auto s = immutable Array!ThrowsDtor(ThrowsDtor(1)); }));
    }

    private @nogc nothrow pure @trusted
    size_t slackFront() const
    {
        return _payload.ptr - _support.ptr;
    }

    private @nogc nothrow pure @trusted
    size_t slackBack() const
    {
        return _support.ptr + _support.length - _payload.ptr - _payload.length;
    }

    /**
     * Return the number of elements in the array..
     *
     * Returns:
     *      the length of the array.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe
    size_t length() const
    {
        return _payload.length;
    }

    /// ditto
    alias opDollar = length;

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int(1, 2, 3);
        assert(a.length == 3);
        assert(a[$ - 1] == 3);
    }

    /**
     * Set the length of the array to `len`. `len` must be less than or equal
     * to the `capacity` of the array.
     *
     * Params:
     *      len = a positive integer
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @trusted
    void forceLength(size_t len)
    {
        assert(len <= capacity);
        _payload = cast(T[])(_support[slackFront .. len]);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int(1, 2, 3);
        a.forceLength(2);
        assert(a.length == 2);
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
        auto a = Array!int(1, 2, 3);
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

        static if (hasMember!(typeof(_allocator), "expand"))
        if (_support && opCmpPrefix!"=="(_support, 1))
        {
            void[] buf = _support;
            version(unittest)
            {
                auto successfulExpand = pureExpand(_isShared, buf, (n - capacity) * stateSize!T);
            }
            else
            {
                auto successfulExpand = _allocator.expand(buf, (n - capacity) * stateSize!T);
            }

            if (successfulExpand)
            {
                const oldLength = _support.length;
                _support = (() @trusted => cast(Unqual!T[])(buf))();
                // Emplace extended buf
                // TODO: maybe? emplace only if T has indirections
                foreach (i; oldLength .. _support.length)
                {
                    emplace(&_support[i]);
                }
                return;
            }
            else
            {
                assert(0, "Array.reserve: Failed to expand array.");
            }
        }

        version(unittest)
        {
            auto tmpSupport = (() @trusted  => cast(Unqual!T[])(pureAllocate(_isShared, n * stateSize!T)))();
        }
        else
        {
            auto tmpSupport = (() @trusted => cast(Unqual!T[])(_allocator.allocate(n * stateSize!T)))();
        }
        assert(tmpSupport !is null);
        for (size_t i = 0; i < tmpSupport.length; ++i)
        {
            if (i < _payload.length)
            {
                emplace(&tmpSupport[i], _payload[i]);
                //pragma(msg, typeof(&tmpSupport[i]).stringof);
            }
            else
            {
                emplace(&tmpSupport[i]);
            }
        }

        destroyUnused();
        _support = tmpSupport;
        addRef(_support);
        _payload = (() @trusted => cast(T[])(_support[0 .. _payload.length]))();
        assert(capacity >= n);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        Array!int a;
        a.reserve(stuff.length);
        a ~= stuff;
        assert(equal(a, stuff));
    }

    /**
     * Inserts the elements of an
     * $(REF_ALTTEXT input range, isInputRange, std,range,primitives), or a
     * variable number of items, at the given `pos`.
     *
     * If no allocator was provided when the array was created, the
     * $(REF, GCAllocator, std,experimental,allocator,gc_allocator) will be used.
     * If `Stuff` defines `length`, `Array` will use it to reserve the
     * necessary amount of memory.
     *
     * Params:
     *      pos = a positive integer
     *      stuff = an input range of elements that are implitictly convertible
     *              to `T`; a variable number of items either in the form of a
     *              list or as a built-in array
     *
     * Returns:
     *      the number of elements inserted
     *
     * Complexity: $(BIGOH max(length, pos + m)), where `m` is the number of
     *             elements in the range.
     */
    size_t insert(Stuff)(size_t pos, Stuff stuff)
    if (!isArray!(typeof(stuff)) && isInputRange!Stuff && !isInfinite!Stuff
        && isImplicitlyConvertible!(ElementType!Stuff, T))
    {
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        static if (hasLength!Stuff)
        {
            size_t stuffLength = stuff.length;
        }
        else
        {
            size_t stuffLength = walkLength(stuff);
        }
        if (stuffLength == 0) return 0;

        version(unittest)
        {
            auto tmpSupport = (() @trusted => cast(Unqual!T[])(pureAllocate(_isShared, stuffLength * stateSize!T)))();
        }
        else
        {
            auto tmpSupport = (() @trusted => cast(Unqual!T[])(_allocator.allocate(stuffLength * stateSize!T)))();
        }
        assert(stuffLength == 0 || (stuffLength > 0 && tmpSupport !is null));
        for (size_t i = 0; i < tmpSupport.length; ++i)
        {
                emplace(&tmpSupport[i]);
        }

        size_t i = 0;
        foreach (ref item; stuff)
        {
            tmpSupport[i++] = item;
        }
        size_t result = insert(pos, tmpSupport);
        version(unittest)
        {
            () @trusted { pureDispose(_isShared, tmpSupport); }();
        }
        else
        {
            () @trusted { _allocator.dispose(tmpSupport); }();
        }
        return result;
    }

    /// ditto
    size_t insert(Stuff)(size_t pos, Stuff[] stuff...)
    if (isImplicitlyConvertible!(Stuff, T))
    {
        // Will be optimized away, but the type system infers T's safety
        if (0) { T t = T.init; }

        assert(pos <= _payload.length);

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
        //_support[pos + stuff.length .. _payload.length + stuff.length] =
            //_support[pos .. _payload.length];
        for (size_t i = _payload.length + stuff.length - 1; i >= pos +
                stuff.length; --i)
        {
            // Avoids underflow if payload is empty
            _support[i] = _support[i - stuff.length];
        }

        //writefln("typeof support[i] %s", typeof(_support[0]).stringof);

        //_support[pos .. pos + stuff.length] = stuff[];
        for (size_t i = pos, j = 0; i < pos + stuff.length; ++i, ++j) {
            _support[i] = stuff[j];
        }

        _payload = (() @trusted => cast(T[])(_support[0 .. _payload.length + stuff.length]))();
        return stuff.length;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        Array!int a;
        assert(a.empty);

        size_t pos = 0;
        pos += a.insert(pos, 1);
        pos += a.insert(pos, [2, 3]);
        assert(equal(a, [1, 2, 3]));
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
        if (_support !is null)
        {
            return cast(bool) opCmpPrefix!"=="(_support, 1);
        }
        return true;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int(24, 42);

        assert(a.isUnique);
        {
            auto a2 = a;
            assert(!a.isUnique);
            a2.front = 0;
            assert(a.front == 0);
        } // a2 goes out of scope
        assert(a.isUnique);
    }

    /**
     * Check if the array is empty.
     *
     * Returns:
     *      `true` if there are no elements in the array; `false` otherwise.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe
    bool empty() const
    {
        return length == 0;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        Array!int a;
        assert(a.empty);
        size_t pos = 0;
        a.insert(pos, 1);
        assert(!a.empty);
    }

    /**
     * Provide access to the first element in the array. The user must check
     * that the array isn't `empty`, prior to calling this function.
     *
     * Returns:
     *      a reference to the first element.
     *
     * Complexity: $(BIGOH 1).
     */
    ref auto front(this _)()
    {
        assert(!empty, "Array.front: Array is empty");
        return _payload[0];
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int(1, 2, 3);
        assert(a.front == 1);
        a.front = 0;
        assert(a.front == 0);
    }

    /**
     * Advance to the next element in the array. The user must check
     * that the array isn't `empty`, prior to calling this function.
     *
     * Complexity: $(BIGOH 1).
     */
    @nogc nothrow pure @safe
    void popFront()
    {
        assert(!empty, "Array.popFront: Array is empty");
        _payload = _payload[1 .. $];
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = Array!int(stuff);
        size_t i = 0;
        while (!a.empty)
        {
            assert(a.front == stuff[i++]);
            a.popFront;
        }
        assert(a.empty);
    }

    /**
     * Advance to the next element in the array. The user must check
     * that the array isn't `empty`, prior to calling this function.
     *
     * This must be used in order to iterate through a `const` or `immutable`
     * array For a mutable array this is equivalent to calling `popFront`.
     *
     * Returns:
     *      an array that starts with the next element in the original array.
     *
     * Complexity: $(BIGOH 1).
     */
    Qualified tail(this Qualified)()
    {
        assert(!empty, "Array.tail: Array is empty");

        static if (is(Qualified == immutable) || is(Qualified == const))
        {
            return this[1 .. $];
        }
        else
        {
            return .tail(this);
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto ia = immutable Array!int([1, 2, 3]);
        assert(ia.tail.front == 2);
    }

    /**
     * Eagerly iterate over each element in the array and call `fun` over each
     * element. This should be used to iterate through `const` and `immutable`
     * arrays.
     *
     * Normally, the entire array is iterated. If partial iteration (early stopping)
     * is desired, `fun` needs to return a value of type `int` (`-1` to stop, or
     * anything else to continue the iteration.
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
            foreach (ref e; this._payload)
            {
                static if (!is(typeof(fn(T.init)) == int))
                {
                    cast(void) fn(e);
                }
                else
                {
                    if (fn(e) == -1)
                        return false;
                }
            }
            return true;
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto ia = immutable Array!int([3, 2, 1]);

        static bool foo(int x) { return x > 0; }
        static int bar(int x) { return x > 1 ? 1 : -1; }

        assert(ia.each!foo == true);
        assert(ia.each!bar == false);
    }

    @safe unittest
    {
        {
            auto ia = immutable Array!int([3, 2, 1]);

            static bool foo(int x) { return x > 0; }
            static int bar(int x) { return x > 1 ? 1 : -1; }

            assert(ia.each!foo == true);
            assert(ia.each!bar == false);
        }

        assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
        assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
    }

    //int opApply(int delegate(const ref T) dg) const
    //{
        //if (_payload.length && dg(_payload[0])) return 1;
        //if (!this.empty) this.tail.opApply(dg);
        //return 0;
    //}

    /**
     * Perform a shallow copy of the array.
     *
     * Returns:
     *      a new reference to the current array.
     *
     * Complexity: $(BIGOH 1).
     */
    ref auto save(this _)()
    {
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = Array!int(stuff);
        size_t i = 0;

        auto tmp = a.save;
        while (!tmp.empty)
        {
            assert(tmp.front == stuff[i++]);
            tmp.popFront;
        }
        assert(tmp.empty);
        assert(!a.empty);
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
    immutable(Array!T) idup(this Q)()
    {
        auto r = immutable Array!T(this);
        return r;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        {
            auto a = Array!(int)(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = const Array!(int)(1, 2, 3);
            auto a2 = a.idup();
            static assert (is(typeof(a2) == immutable));
        }

        {
            auto a = immutable Array!(int)(1, 2, 3);
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
    Array!T dup(this Q)()
    {
        Array!T result;

        static if (is(Q == immutable) || is(Q == const))
        {
            result.reserve(length);
            foreach(i; 0 .. length)
            {
                result ~= this[i];
            }
        }
        else
        {
            result.insert(0, this);
        }
        return result;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = immutable Array!int(stuff);
        auto aDup = a.dup;
        assert(equal(aDup, stuff));
        aDup.front = 0;
        assert(aDup.front == 0);
        assert(a.front == 1);
    }

    /**
     * Return a slice to the current array. This is equivalent to calling
     * `save`.
     *
     * Returns:
     *      an array that references the current array.
     *
     * Complexity: $(BIGOH 1)
     */
    Qualified opSlice(this Qualified)()
    {
        return this.save;
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
    in
    {
        assert(start <= end && end <= length,
               "Array.opSlice(s, e): Invalid bounds: Ensure start <= end <= length");
    }
    body
    {
        return typeof(this)(_support, _payload[start .. end], _isShared);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto stuff = [1, 2, 3];
        auto a = Array!int(stuff);
        assert(equal(a[], stuff));
        assert(equal(a[1 .. $], stuff[1 .. $]));
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
    in
    {
        assert(idx < length, "Array.opIndex: Index out of bounds");
    }
    body
    {
        return _payload[idx];
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3]);
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
    in
    {
        assert(idx < length, "Array.opIndexUnary!" ~ op ~ ": Index out of bounds");
    }
    body
    {
        mixin("return " ~ op ~ "_payload[idx];");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3]);
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
    if (isImplicitlyConvertible!(U, T))
    in
    {
        assert(idx < length, "Array.opIndexAssign: Index out of bounds");
    }
    body
    {
        return _payload[idx] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3]);
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
    if (isImplicitlyConvertible!(U, T))
    body
    {
        _payload[] = elem;
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3]);
        a[] = 0;
        assert(a.equal([0, 0, 0]));
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
    if (isImplicitlyConvertible!(U, T))
    in
    {
        assert(start <= end, "Array.opSliceAssign: Index out of bounds");
        assert(end < length, "Array.opSliceAssign: Index out of bounds");
    }
    body
    {
        return _payload[start .. end] = elem;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3, 4, 5, 6]);
        a[1 .. 3] = 0;
        assert(a.equal([1, 0, 0, 4, 5, 6]));
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
    if (isImplicitlyConvertible!(U, T))
    in
    {
        assert(idx < length, "Array.opIndexOpAssign!" ~ op ~ ": Index out of bounds");
    }
    body
    {
        mixin("return _payload[idx]" ~ op ~ "= elem;");
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int([1, 2, 3]);
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
             || (isInputRange!U && isImplicitlyConvertible!(ElementType!U, T))
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
        auto a = Array!int(1);
        auto a2 = a ~ 2;

        assert(equal(a2, [1, 2]));
        a.front = 0;
        assert(equal(a2, [1, 2]));
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
        if (rhs._support !is null && _support is rhs._support)
        {
            if (rhs._payload is _payload)
                return this;
        }

        if (rhs._support !is null)
        {
            rhs.addRef(rhs._support);
        }
        destroyUnused();
        _support = rhs._support;
        _payload = rhs._payload;
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = Array!int(1);
        auto a2 = Array!int(1, 2);

        a = a2; // this will free the old a
        assert(equal(a, [1, 2]));
        a.front = 0;
        assert(equal(a2, [0, 2]));
    }

    static if (is(T == int))
    @safe unittest
    {
        auto arr = Array!int(1, 2, 3, 4, 5, 6);
        auto arr1 = arr[1 .. $];
        auto arr2 = arr[3 .. $];
        arr1 = arr2;
        assert(arr1.equal([4, 5, 6]));
        assert(arr2.equal([4, 5, 6]));
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
             || (isInputRange!U && isImplicitlyConvertible!(ElementType!U, T))
            ))
    {
        insert(length, rhs);
        return this;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        Array!int a;
        auto a2 = Array!int(4, 5);
        assert(a.empty);

        a ~= 1;
        a ~= [2, 3];
        assert(equal(a, [1, 2, 3]));

        // append an input range
        a ~= a2;
        assert(equal(a, [1, 2, 3, 4, 5]));
        a2.front = 0;
        assert(equal(a, [1, 2, 3, 4, 5]));
    }

    ///
    bool opEquals()(auto ref typeof(this) rhs) const
    {
        return _support.equal(rhs);
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto arr1 = Array!int(1, 2);
        auto arr2 = Array!int(1, 2);
        auto arr3 = Array!int(2, 3);
        assert(arr1 == arr2);
        assert(arr2 == arr1);
        assert(arr1 != arr3);
        assert(arr3 != arr1);
        assert(arr2 != arr3);
        assert(arr3 != arr2);
    }

    ///
    int opCmp(U)(auto ref U rhs)
    if (isInputRange!U && isImplicitlyConvertible!(ElementType!U, T))
    {
        auto r1 = this;
        auto r2 = rhs;
        for (; !r1.empty && !r2.empty; r1.popFront, r2.popFront)
        {
            if (r1.front < r2.front)
                return -1;
            else if (r1.front > r2.front)
                return 1;
        }
        // arrays are equal until here, but it could be that one of them is shorter
        if (r1.empty && r2.empty)
            return 0;
        return r1.empty ? -1 : 1;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto arr1 = Array!int(1, 2);
        auto arr2 = Array!int(1, 2);
        auto arr3 = Array!int(2, 3);
        auto arr4 = Array!int(0, 3);
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
        auto arr1 = Array!int(1, 2);
        auto arr2 = [1, 2];
        auto arr3 = Array!int(2, 3);
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
        // will be safe with 2.082
        return () @trusted { return _support.hashOf; }();
    }

    ///
    @safe unittest
    {
        auto arr1 = Array!int(1, 2);
        assert(arr1.toHash == Array!int(1, 2).toHash);
        arr1 ~= 3;
        assert(arr1.toHash == Array!int(1, 2, 3).toHash);
        assert(Array!int().toHash == Array!int().toHash);
    }
}

version(unittest) private nothrow pure @safe
void testConcatAndAppend()
{
    auto a = Array!(int)(1, 2, 3);
    Array!(int) a2 = Array!(int)();

    auto a3 = a ~ a2;
    assert(equal(a3, [1, 2, 3]));

    auto a4 = a3;
    a3 = a3 ~ 4;
    assert(equal(a3, [1, 2, 3, 4]));
    a3 = a3 ~ [5];
    assert(equal(a3, [1, 2, 3, 4, 5]));
    assert(equal(a4, [1, 2, 3]));

    a4 = a3;
    a3 ~= 6;
    assert(equal(a3, [1, 2, 3, 4, 5, 6]));
    a3 ~= [7];

    a3 ~= a3;
    assert(equal(a3, [1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7]));

    Array!int a5 = Array!(int)();
    a5 ~= [1, 2, 3];
    assert(equal(a5, [1, 2, 3]));
    auto a6 = a5;
    a5 = a5;
    a5[0] = 10;
    assert(equal(a5, a6));

    // Test concat with mixed qualifiers
    auto a7 = immutable Array!(int)(a5);
    assert(a7.front == 10);
    a5.front = 1;
    assert(a7.front == 10);
    auto a8 = a5 ~ a7;
    assert(equal(a8, [1, 2, 3, 10, 2, 3]));

    auto a9 = const Array!(int)(a5);
    auto a10 = a5 ~ a9;
    assert(equal(a10, [1, 2, 3, 1, 2, 3]));
}

@safe unittest
{
    () nothrow pure @safe {
        testConcatAndAppend();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testSimple()
{
    auto a = Array!int();
    assert(a.empty);
    assert(a.isUnique);

    size_t pos = 0;
    a.insert(pos, 1, 2, 3);
    assert(a.front == 1);
    assert(equal(a, a));
    assert(equal(a, [1, 2, 3]));

    a.popFront();
    assert(a.front == 2);
    assert(equal(a, [2, 3]));

    a.insert(pos, [4, 5, 6]);
    a.insert(pos, 7);
    a.insert(pos, [8]);
    assert(equal(a, [8, 7, 4, 5, 6, 2, 3]));

    a.insert(a.length, 0, 1);
    a.insert(a.length, [-1, -2]);
    assert(equal(a, [8, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]));

    a.front = 9;
    assert(equal(a, [9, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]));

    auto aTail = a.tail;
    assert(aTail.front == 7);
    aTail.front = 8;
    assert(aTail.front == 8);
    assert(a.tail.front == 8);
    assert(!a.isUnique);
}

@safe unittest
{
    () nothrow pure @safe {
        testSimple();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testSimpleImmutable()
{
    auto a = Array!(immutable int)();
    assert(a.empty);

    size_t pos = 0;
    a.insert(pos, 1, 2, 3);
    assert(a.front == 1);
    assert(equal(a, a));
    assert(equal(a, [1, 2, 3]));

    a.popFront();
    assert(a.front == 2);
    assert(equal(a, [2, 3]));
    assert(a.tail.front == 3);

    a.insert(pos, [4, 5, 6]);
    a.insert(pos, 7);
    a.insert(pos, [8]);
    assert(equal(a, [8, 7, 4, 5, 6, 2, 3]));

    a.insert(a.length, 0, 1);
    a.insert(a.length, [-1, -2]);
    assert(equal(a, [8, 7, 4, 5, 6, 2, 3, 0, 1, -1, -2]));

    // Cannot modify immutable values
    static assert(!__traits(compiles, a.front = 9));
}

@safe unittest
{
    () nothrow pure @safe {
        testSimpleImmutable();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testCopyAndRef()
{
    auto aFromList = Array!int(1, 2, 3);
    auto aFromRange = Array!int(aFromList);
    assert(equal(aFromList, aFromRange));

    aFromList.popFront();
    assert(equal(aFromList, [2, 3]));
    assert(equal(aFromRange, [1, 2, 3]));

    size_t pos = 0;
    Array!int aInsFromRange = Array!int();
    aInsFromRange.insert(pos, aFromList);
    aFromList.popFront();
    assert(equal(aFromList, [3]));
    assert(equal(aInsFromRange, [2, 3]));

    Array!int aInsBackFromRange = Array!int();
    aInsBackFromRange.insert(pos, aFromList);
    aFromList.popFront();
    assert(aFromList.empty);
    assert(equal(aInsBackFromRange, [3]));

    auto aFromRef = aInsFromRange;
    auto aFromDup = aInsFromRange.dup;
    assert(aInsFromRange.front == 2);
    aFromRef.front = 5;
    assert(aInsFromRange.front == 5);
    assert(aFromDup.front == 2);
}

@safe unittest
{
    () nothrow pure @safe {
        testCopyAndRef();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testImmutability()
{
    auto a = immutable Array!(int)(1, 2, 3);
    auto a2 = a;
    auto a3 = a2.save();

    assert(a2.front == 1);
    assert(a2[0] == a2.front);
    static assert(!__traits(compiles, a2.front = 4));
    static assert(!__traits(compiles, a2.popFront()));

    auto a4 = a2.tail;
    assert(a4.front == 2);
    static assert(!__traits(compiles, a4 = a4.tail));

    // Create a mutable copy from an immutable array
    auto a5 = a.dup();
    assert(equal(a5, [1, 2, 3]));
    assert(a5.front == 1);
    a5.front = 2;
    assert(a5.front == 2);
    assert(a.front == 1);
    assert(equal(a5, [2, 2, 3]));

    // Create immtable copies from mutable, const and immutable
    {
        auto aa = Array!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa._support, 1));
        assert(aa2.opCmpPrefix!"=="(aa2._support, 1));
    }

    {
        auto aa = const Array!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa._support, 1));
        assert(aa2.opCmpPrefix!"=="(aa2._support, 1));
    }

    {
        auto aa = immutable Array!(int)(1, 2, 3);
        auto aa2 = aa.idup();
        assert(aa.opCmpPrefix!"=="(aa._support, 2));
        assert(aa2.opCmpPrefix!"=="(aa2._support, 2));
    }
}

version(unittest) private nothrow pure @safe
void testConstness()
{
    auto a = const Array!(int)(1, 2, 3);
    auto a2 = a;
    auto a3 = a2.save();
    immutable Array!int a5 = a;
    assert(a5.opCmpPrefix!"=="(a5._support, 1));
    assert(a.opCmpPrefix!"=="(a._support, 3));

    assert(a2.front == 1);
    assert(a2[0] == a2.front);
    static assert(!__traits(compiles, a2.front = 4));
    static assert(!__traits(compiles, a2.popFront()));

    auto a4 = a2.tail;
    assert(a4.front == 2);
    static assert(!__traits(compiles, a4 = a4.tail));
}

@safe unittest
{
    () nothrow pure @safe {
        testImmutability();
        testConstness();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testWithStruct()
{
    auto array = Array!int(1, 2, 3);
    {
        assert(array.opCmpPrefix!"=="(array._support, 1));

        auto arrayOfArrays = Array!(Array!int)(array);
        assert(array.opCmpPrefix!"=="(array._support, 2));
        assert(equal(arrayOfArrays.front, [1, 2, 3]));
        arrayOfArrays.front.front = 2;
        assert(equal(arrayOfArrays.front, [2, 2, 3]));
        assert(equal(arrayOfArrays.front, array));
        static assert(!__traits(compiles, arrayOfArrays.insert(1)));

        auto immArrayOfArrays = immutable Array!(Array!int)(array);

        // immutable is transitive, so it must iterate over array and
        // create a copy, and not set a ref
        assert(array.opCmpPrefix!"=="(array._support, 2));
        array.front = 3;
        assert(immArrayOfArrays.front.front == 2);
        assert(immArrayOfArrays.opCmpPrefix!"=="(immArrayOfArrays._support, 1));
        assert(immArrayOfArrays.front.opCmpPrefix!"=="(immArrayOfArrays.front._support, 1));
        static assert(!__traits(compiles, immArrayOfArrays.front.front = 2));
        static assert(!__traits(compiles, immArrayOfArrays.front = array));
    }
    assert(array.opCmpPrefix!"=="(array._support, 1));
    assert(equal(array, [3, 2, 3]));
}

@safe unittest
{
    () nothrow pure @safe {
        testWithStruct();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
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
        Array!MyClass a = Array!MyClass(c);
        assert(a.front.x == 10);
        assert(a.front is c);
        a.front.x = 20;
    }
    assert(c.x == 20);
}

@safe unittest
{
    () nothrow pure @safe {
        testWithClass();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private @nogc nothrow pure @safe
void testOpOverloads()
{
    auto a = Array!int(1, 2, 3, 4);
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
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}

version(unittest) private nothrow pure @safe
void testSlice()
{
    auto a = Array!int(1, 2, 3, 4);
    auto b = a[];
    assert(equal(a, b));
    b[1] = 5;
    assert(a[1] == 5);

    size_t startPos = 2;
    auto c = b[startPos .. $];
    assert(equal(c, [3, 4]));
    c[0] = 5;
    assert(equal(a, b));
    assert(equal(a, [1, 5, 5, 4]));
    assert(a.capacity == b.capacity && b.capacity == c.capacity + startPos);

    c ~= 5;
    assert(equal(c, [5, 4, 5]));
    assert(equal(a, b));
    assert(equal(a, [1, 5, 5, 4]));
}

@safe unittest
{
    () nothrow pure @safe {
        testSlice();
    }();
    assert(_allocator.bytesUsed == 0, "Array ref count leaks memory");
    assert(_sallocator.bytesUsed == 0, "Array ref count leaks memory");
}
