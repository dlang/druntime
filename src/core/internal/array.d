module core.internal.array;
import core.stdc.stdint : uintptr_t;

/*
 * This allows safe use of a pointer without dereferencing. Useful when you
 * want to declare that all you care about it the pointer value itself. Keeps
 * the pointer as a pointer to allow GC to properly track things.
 *
 * Note that PtrVal has all the same characteristics of a normal pointer,
 * except it doesn't allow dereferencing, and doesn't allow pointer math
 * without jumping into simple integer types.
 */
struct PtrVal(T)
{
    private T *_ptr;

    /*
     * Get the pointer as a non-dereferencable unsigned integer.
     */
    uintptr_t value() const @trusted
    {
        return cast(uintptr_t)_ptr;
    }

    /*
     * Keep the mechanism that returns a signed pointer difference between pointers.
     */
    ptrdiff_t opBinary(string op : "-")(const(PtrVal) other) const @trusted
    {
        return _ptr - other._ptr;
    }

    // ditto
    ptrdiff_t opBinary(string op : "-")(const(T*) other) const @trusted
    {
        return _ptr - other;
    }

    // ditto
    ptrdiff_t opBinaryRight(string op : "-")(const(T*) other) const @trusted
    {
        return other - _ptr;
    }

    // disable subtraction between undefined types -- we don't want to
    // accidentally subtract between the value() and some unknown type.
    ptrdiff_t opBinary(string op : "-", X)(X) const @safe
    {
        static assert(0, "Cannot subtract between " ~ typeof(this).stringof ~ " and " ~ X.stringof);
    }

    /*
     * Use this if you are in system code and wish to get back to unsafe
     * pointer-land.
     */
    inout(T) *ptr() inout @system
    {
        return _ptr;
    }

    /*
     * Devolves to simple unsigned integer if any other operations are used
     */
    alias value this;


    /*
     * Cast to void pointer type. TODO: see if there is a way to make this
     * implicit.
     */
    auto toVoid() inout @trusted
    {
        static if(is(const(T)* == const(void)*))
        {
            // already a void pointer
            return this;
        }
        else
        {
            // need to transfer mutability modifier of _ptr
            import core.internal.traits: ModifyTypePreservingTQ;
            alias voidify(M) = void;
            alias VType = ModifyTypePreservingTQ!(voidify, T);
            return inout(.PtrVal!(VType))(_ptr);
        }
    }
}

/*
 * Factory method
 */
inout(PtrVal!T) ptrval(T)(inout(T)* ptr) @safe
{
    return inout(PtrVal!T)(ptr);
}

/*
 * Allow safe access to array.ptr as a PtrVal.
 */
inout(PtrVal!T) ptrval(T)(inout(T)[] arr) @trusted
{
    return arr.ptr.ptrval;
}

unittest
{
    import core.internal.traits: TypeTuple;
    void testItSafe(T)(T[] t1, T[] t2) @safe
    {
        auto p1 = t1.ptrval;
        auto p2 = t2.ptrval;

        assert(p2 - p1 == 5, T.stringof);
        assert(p1 - p2 == -5, T.stringof);
        assert(p2.toVoid - p1.toVoid == 5 * T.sizeof, T.stringof);
        assert(p1.toVoid - p2.toVoid == -5 * T.sizeof, T.stringof);

        auto p3 = &t1[0];
        auto p4 = &t2[0];

        assert(p1 - p3 == 0, T.stringof);
        assert(p4 - p2 == 0, T.stringof);
    }

    void testIt(T)(inout int = 0)
    {
        T[] arr = new T[10];
        testItSafe(arr[0 .. 5], arr[5 .. $]);

        // test getting pointer back from PtrVal.
        auto p1 = arr.ptrval;
        auto p2 = arr[5 .. $].ptrval;

        assert(p1.ptr + 5 == p2.ptr, T.stringof);
        assert(p1.ptr == arr.ptr, T.stringof);
    }

    class C {}
    struct S {ubyte x;}
    foreach(T; TypeTuple!(ubyte, byte, ushort, short, uint, int, ulong, long, float, double, real, C, S))
    {
        testIt!(T)();
        testIt!(const(T))();
        testIt!(immutable(T))();
        testIt!(inout(T))();
    }
}
