/**
 * The console module contains a hash implementation.
 *
 * Copyright: Copyright Sean Kelly 2009 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly    (bytesHash)
 *            Igor Stepanov (hashOf, aaGetHashStatic, xxxGetHash et c.)
 */

/*          Copyright Sean Kelly 2009 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.internal.hash;

/**
    Compute hash value for different types.
*/

//enum hash. CTFE depends on base type
@trusted nothrow
size_t hashOf(T)(auto ref T val) if (is(T == enum))
{
    static if (is(T EType == enum)) //for EType
    {
        EType e_val = cast(EType)val;
        return hashOf(e_val);
    }
    else
    {
        static assert(0);
    }
}

/**
    linked with
    size_t saGetHash(in void* p, const(TypeInfo) tiRaw)
 */
//CTFE ready (depends on base type). Can be merged with dynamic array hash
@trusted nothrow pure
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && __traits(isStaticArray, T))
{
    size_t cur_hash = 0;
    foreach (ref cur; val)
    {
        cur_hash += hashOf(cur);
    }
    return cur_hash;
}

/**
    Compute hash value of static array, when information of array static type is unavailable.
    linked with
    size_t hashOf(T)(auto ref T val) if (!is(T == enum) && __traits(isStaticArray, T))
*/
@trusted nothrow
size_t saGetHash(in void* p, const(TypeInfo) tiRaw)
{
    TypeInfo_StaticArray ti = unqualTi!(TypeInfo_StaticArray)(tiRaw);
    assert(ti);
    TypeInfo valueti = ti.next;
    size_t asz = ti.tsize;
    size_t vsz = valueti.tsize;

    size_t hash = 0;
    for (size_t i = 0; i < asz; i+=vsz)
        hash += valueti.getHash(p + i);
    return hash;
}

/**
    linked with
    size_t daGetHash(in void* p, const(TypeInfo) tiRaw)
 */
//dynamic array hash
@trusted nothrow
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T S: S[]) && !__traits(isStaticArray, T))
{
    alias ElementType = typeof(val[0]);
    static if (is(T: const(char)[])) //CTFE ready
    {
        return stringHash(val);
    }
    else static if (is(ElementType == interface) || is(ElementType == class))
    //class or interface array; CTFE depend on toHash() method
    {
        size_t hash = 0;
        foreach (o; val)
        {
            if (o)
                hash += (cast(Object)o).toHash();
        }
        return hash;
    }
    else static if ((is(ElementType == struct) || is(ElementType == union)) && is(typeof(val[0].toHash()) == size_t))
    //struct array with toHash(); CTFE depend on toHash() method
    {
        size_t hash = 0;
        foreach (o; val)
        {
            hash += o.toHash();
        }
        return hash;
    }
    else static if (is(typeof(toUbyte(val)) == const(ubyte)[]))
    //ubyteble array (arithmetic types and structs without toHash) CTFE ready for arithmetic types and structs without reference fields
    {
        auto bytes = toUbyte(val);
        return bytesHash(bytes.ptr, bytes.length);
    }
    else //Other types. CTFE unsupported
    {
        return bytesHash(val.ptr, ElementType.sizeof*val.length);
    }
}

/**
    Compute hash value of dynamic array, when information of array static type is unavailable.
    linked with
    size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T S: S[]) && !__traits(isStaticArray, T))
*/
@trusted nothrow
size_t daGetHash(in void* p, const(TypeInfo) tiRaw)
{
    TypeInfo_Array ti = unqualTi!(TypeInfo_Array)(tiRaw);
    assert(ti);
    try
    {   //TypeInfo.opEquals not nothrow
        if (ti.next == typeid(const(char)) || ti.next == typeid(shared(char)))
        {
            return typeid(string).getHash(p); //Use algorithm, optimized for strings
        }
        else if (cast(TypeInfo_Class)ti.next ||
                 cast(TypeInfo_Interface)ti.next ||
                 (cast(TypeInfo_Struct)ti.next) && (cast(TypeInfo_Struct)ti.next).xtoHash) //is class, or interface, or struct
        {
            auto arr = *cast(void[]*)p;
            size_t hash = 0;
            size_t sz = ti.next.tsize;
            for (size_t i=0; i<arr.length; i++)
            {
                void* cur = arr.ptr + i*sz;
                hash += ti.next.getHash(cur);
            }
            return hash;
        }
    }
    catch
    {
        assert(0);
    }

    size_t vsz = ti.next.tsize;
    auto arr = *cast(ubyte[]*)p;
    ubyte[] ubarr = arr.ptr[0 .. arr.length*vsz];
    return ubarr.hashOf();

}

//arithmetic type hash
@trusted nothrow pure
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && __traits(isArithmetic, T))
{
    static if (__traits(isIntegral, T) && (T.sizeof <= 4)) //CTFE ready
    {
        return val;
    }
    else static if (is(Unqual!T == float)) //CTFE ready
    {
        return *cast(int*)&val;
    }
    else static if (is(typeof(toUbyte(val)) == const(ubyte)[])) //most of numerics CTFE ready
    {
        auto bytes = toUbyte(val);
        return bytesHash(bytes.ptr, bytes.length);
    }
    else //real, ireal, creal. CTFE unsupproted
    {
        const(ubyte)[] bytes = (cast(const(ubyte)*)&val)[0 .. T.sizeof];
        return bytesHash(bytes.ptr, bytes.length);
    }
}

//Pointers hash. CTFE unsupported
@trusted nothrow pure
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T V : V*))
{
    return cast(size_t)val;
}

/**
    linked with
    size_t structGetHash(in void* p, const(TypeInfo_Struct) ti)
 */
//struct or union hash
@trusted nothrow pure
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && (is(T == struct) || is(T == union)))
{
    static if (is(typeof(val.toHash()) == size_t)) //CTFE depends on toHash()
    {
        return val.toHash();
    }
    else static if (is(typeof(toUbyte(val)) == const(ubyte)[]))//CTFE ready for structs without reference fields
    {
        auto bytes = toUbyte(val);
        return bytesHash(bytes.ptr, bytes.length);
    }
    else // CTFE unsupproreted for structs with reference fields
    {
        const(ubyte)[] bytes = (cast(const(ubyte)*)&val)[0 .. T.sizeof];
        return bytesHash(bytes.ptr, bytes.length);
    }
}

/**
    Compute hash value of struct, when information of array static type is unavailable.
    linked with
    size_t hashOf(T)(auto ref T val) if (is(T == struct) || is(T == union))
*/
@trusted nothrow pure
size_t structGetHash(in void* p, const(TypeInfo_Struct) ti)
{
    assert(p);
    if (ti.xtoHash)
    {
        return (*ti.xtoHash)(p);
    }
    else
    {
        const(void)[] bytes = p[0 .. ti.init().length];
        return bytes.hashOf();
    }
}

//delegate hash. CTFE unsupported
@trusted nothrow pure
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T == delegate))
{
    const(ubyte)[] bytes = (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    return bytesHash(bytes.ptr, bytes.length);
}

/**
    linked with
    size_t interfaceGetHash(in void* p)
 */
//class or interface hash. CTFE depends on toHash
@trusted nothrow
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T == interface) || is(T == class))
{
    return val ? (cast(Object)val).toHash() : 0;
}

/**
    Compute hash value of interface, when information of array static type is unavailable.
    linked with
    size_t hashOf(T)(auto ref T val) if (!is(T == enum) && is(T == interface) || is(T == class))
*/
@trusted nothrow
size_t interfaceGetHash(in void* p)
{
    if (!*cast(void**)p) return 0;
    Interface* pi = **cast(Interface ***)*cast(void**)p;
    Object o = cast(Object)(*cast(void**)p - pi.offset);
    return o.hashOf();
}

//associative array hash. CTFE depends on base types
@trusted nothrow
size_t hashOf(T)(auto ref T val) if (!is(T == enum) && __traits(isAssociativeArray, T))
{
    return aaGetHashStatic(val);
}

/**
    Compute hash value of associative array, when information of array static type is available.
    CTFE ready.
    linked with aaGetHash
*/
@trusted /*pure*/ nothrow
size_t aaGetHashStatic(T)(T aa) if (__traits(isAssociativeArray, T))
{
    try
    {
        if (!aa.length) return 0;
        size_t h = 0;

        foreach (key, val; aa)
        {
            size_t[2] hpair;
            hpair[0] = key.hashOf();
            hpair[1] = val.hashOf();
            h ^= hpair.hashOf();
        }
        return h;
    }
    catch
    {
        return 0;
    }
}

/**
    Compute hash value of associative array, when information of array static type is unavailable.
    linked with aaGetHashStatic
*/
@trusted nothrow
size_t aaGetHash(in void* aa, const(TypeInfo) tiRaw)
{
    try //because _aaLen and _aaApply2 is not nothrow
    {
        if (!_aaLen(*cast(void**)aa))
            return 0;

        size_t h = 0;
        TypeInfo_AssociativeArray ti = unqualTi!(TypeInfo_AssociativeArray)(tiRaw);
        assert(ti);
        auto keyti = ti.key;
        auto valueti = ti.next;

        int dg(void* key, void* val)
        {
            size_t[2] hpair;
            hpair[0] = keyti.getHash(key);
            hpair[1] = valueti.getHash(val);
            h ^= hpair.hashOf();
            return 0;
        }
        _aaApply2(*cast(void**)aa, keyti.tsize, &dg);
        return h;
    }
    catch
    {
        return 0;
    }
}

unittest
{
    static struct Foo
    {
        int a = 99;
        float b = 4.0;
        size_t toHash() const pure @safe nothrow
        {
            return a;
        }
    }

    static struct Bar
    {
        char c = 'x';
        int a = 99;
        float b = 4.0;
    }

    static struct Boom
    {
        char c = 'M';
        int* a = null;
    }

    interface IBoo
    {
        void boo();
    }

    static class Boo: IBoo
    {
        override void boo()
        {
        }

        override size_t toHash()
        {
            return 1;
        }
    }

    enum Gun: long
    {
        A = 99,
        B = 17
    }

    enum double dexpr = 3.14;
    enum float fexpr = 2.71;
    enum wstring wsexpr = "abcdef"w;
    enum string csexpr = "abcdef";
    enum int iexpr = 7;
    enum long lexpr = 42;
    enum int[2][3] saexpr = [[1, 2], [3, 4], [5, 6]];
    enum int[] daexpr = [7,8,9];
    enum Foo thsexpr = Foo();
    enum Bar vsexpr = Bar();
    enum int[int] aaexpr = [99:2, 12:6, 45:4];
    enum Gun eexpr = Gun.A;
    enum cdouble cexpr = 7+4i;
    enum Foo[] staexpr = [Foo(), Foo(), Foo()];

    //No CTFE:
    Boom rstructexpr = Boom();
    Boom[] rstrarrexpr = [Boom(), Boom(), Boom()];
    int delegate() dgexpr  = (){return 78;};
    void* ptrexpr = &dgexpr;
    real realexpr = 7.88;
    creal[] raexpr = [8.99L+86i, 3.12L+99i, 5.66L+12i];

    //CTFE hashes
    enum h1 = dexpr.hashOf();
    enum h2 = fexpr.hashOf();
    enum h3 = wsexpr.hashOf();
    enum h4 = csexpr.hashOf();
    enum h5 = iexpr.hashOf();
    enum h6 = lexpr.hashOf();
    enum h7 = saexpr.hashOf();
    enum h8 = daexpr.hashOf();
    enum h9 = thsexpr.hashOf();
    enum h10 = vsexpr.hashOf();
    enum h11 = aaexpr.hashOf();
    enum h12 = eexpr.hashOf();
    enum h13 = cexpr.hashOf();
    enum h14 = hashOf(new Boo);
    enum h15 = staexpr.hashOf();
    enum h16 = hashOf([new Boo, new Boo, new Boo]);
    enum h17 = hashOf([cast(IBoo)new Boo, cast(IBoo)new Boo, cast(IBoo)new Boo]);

    //NO CTFE:
    auto h18 = rstructexpr.hashOf();
    auto h19 = rstrarrexpr.hashOf();
    auto h20 = dgexpr.hashOf();
    auto h21 = ptrexpr.hashOf();
    auto h22 = realexpr.hashOf();
    auto h23 = raexpr.hashOf();

    auto v1 = dexpr;
    auto v2 = fexpr;
    auto v3 = wsexpr;
    auto v4 = csexpr;
    auto v5 = iexpr;
    auto v6 = lexpr;
    auto v7 = saexpr;
    auto v8 = daexpr;
    auto v9 = thsexpr;
    auto v10 = vsexpr;
    auto v11 = aaexpr;
    auto v12 = eexpr;
    auto v13 = cexpr;
    auto v14 = new Boo;
    auto v15 = staexpr;
    auto v16 = [new Boo, new Boo, new Boo];
    auto v17 = [cast(IBoo)new Boo, cast(IBoo)new Boo, cast(IBoo)new Boo];

    //NO CTFE:
    auto v18 = rstructexpr;
    auto v19 = rstrarrexpr;
    auto v20 = dgexpr;
    auto v21 = ptrexpr;
    auto v22 = realexpr;
    auto v23 = raexpr;

    //runtime hashes
    auto rth1 = typeid(typeof(v1)).getHash(&v1);
    auto rth2 = typeid(typeof(v2)).getHash(&v2);
    auto rth3 = typeid(typeof(v3)).getHash(&v3);
    auto rth4 = typeid(typeof(v4)).getHash(&v4);
    auto rth5 = typeid(typeof(v5)).getHash(&v5);
    auto rth6 = typeid(typeof(v6)).getHash(&v6);
    auto rth7 = typeid(typeof(v7)).getHash(&v7);
    auto rth8 = typeid(typeof(v8)).getHash(&v8);
    auto rth9 = typeid(typeof(v9)).getHash(&v9);
    auto rth10 = typeid(typeof(v10)).getHash(&v10);
    auto rth11 = typeid(typeof(v11)).getHash(&v11);
    auto rth12 = typeid(typeof(v12)).getHash(&v12);
    auto rth13 = typeid(typeof(v13)).getHash(&v13);
    auto rth14 = typeid(typeof(v14)).getHash(&v14);
    auto rth15 = typeid(typeof(v15)).getHash(&v15);
    auto rth16 = typeid(typeof(v16)).getHash(&v16);
    auto rth17 = typeid(typeof(v17)).getHash(&v17);

    //NO CTFE:
    auto rth18 = typeid(typeof(v18)).getHash(&v18);
    auto rth19 = typeid(typeof(v19)).getHash(&v19);
    auto rth20 = typeid(typeof(v20)).getHash(&v20);
    auto rth21 = typeid(typeof(v21)).getHash(&v21);
    auto rth22 = typeid(typeof(v22)).getHash(&v22);
    auto rth23 = typeid(typeof(v23)).getHash(&v23);

    assert(h1 == rth1);
    assert(h2 == rth2);
    assert(h3 == rth3);
    assert(h4 == rth4);
    assert(h5 == rth5);
    assert(h6 == rth6);
    assert(h7 == rth7);
    assert(h8 == rth8);
    assert(h9 == rth9);
    assert(h10 == rth10);
    assert(h11 == rth11);
    assert(h12 == rth12);
    assert(h13 == rth13);
    assert(h14 == rth14);
    assert(h15 == rth15);
    assert(h16 == rth16);
    assert(h17 == rth17);
    assert(h18 == rth18);
    assert(h19 == rth19);
    assert(h20 == rth20);
    assert(h21 == rth21);
    assert(h22 == rth22);
    assert(h23 == rth23);
}

private
{
    extern(D) alias int delegate(void*, void*) dg2_t;
    extern(C) size_t _aaLen(in void* p) nothrow;
    extern(C) size_t _aaApply2(void* aa, size_t keysize, dg2_t dg) nothrow; //nothrow if dg is nothrow
    extern(C) hash_t _aaGetHash(void* aa, const(TypeInfo) tiRaw) nothrow;
}

@trusted pure nothrow
private T unqualTi(T=TypeInfo)(const(TypeInfo) tiRaw) nothrow if (is(T:TypeInfo))
{
    TypeInfo ti = cast(TypeInfo)tiRaw;
    while (true)
    {
        if (auto ti_const = cast(TypeInfo_Const)ti)
        {
            static if (is(typeof(&ti_const.base) == TypeInfo*))
                ti = ti_const.base;
            else
                ti = ti_const.next;
        }
        else
            break;
    }

    return cast(T)ti;
}


version( X86 )
    version = AnyX86;
version( X86_64 )
    version = AnyX86;
version( AnyX86 )
    version = HasUnalignedOps;

//  Compute hash for bytes array. Can be evaluated at compile time.
//  Author: Sean Kelly
@trusted pure nothrow
private size_t bytesHash( const (void)* buf, size_t len, size_t seed = 0 )
{
    /*
     * This is Paul Hsieh's SuperFastHash algorithm, described here:
     *   http://www.azillionmonkeys.com/qed/hash.html
     * It is protected by the following open source license:
     *   http://www.azillionmonkeys.com/qed/weblicense.html
     */
    static uint get16bits( const (ubyte)* x ) pure nothrow
    {
        // CTFE doesn't support casting ubyte* -> ushort*, so revert to
        // per-byte access when in CTFE.
        version( HasUnalignedOps )
        {
            if (!__ctfe)
                return *cast(ushort*) x;
        }

        return ((cast(uint) x[1]) << 8) + (cast(uint) x[0]);
    }

    // NOTE: SuperFastHash normally starts with a zero hash value.  The seed
    //       value was incorporated to allow chaining.
    auto data = cast(const (ubyte)*) buf;
    auto hash = seed;
    int  rem;

    if ( len <= 0 || data is null )
        return 0;

    rem = len & 3;
    len >>= 2;

    for ( ; len > 0; len-- )
    {
        hash += get16bits( data );
        auto tmp = (get16bits( data + 2 ) << 11) ^ hash;
        hash  = (hash << 16) ^ tmp;
        data += 2 * ushort.sizeof;
        hash += hash >> 11;
    }

    switch( rem )
    {
    case 3: hash += get16bits( data );
            hash ^= hash << 16;
            hash ^= data[ushort.sizeof] << 18;
            hash += hash >> 11;
            break;
    case 2: hash += get16bits( data );
            hash ^= hash << 11;
            hash += hash >> 17;
            break;
    case 1: hash += *data;
            hash ^= hash << 10;
            hash += hash >> 1;
            break;
     default:
            break;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;

    return hash;
}

//  Check that bytesHash works with CTFE
unittest
{
    size_t ctfeHash(string x)
    {
        return bytesHash(x.ptr, x.length);
    }

    enum test_str = "Sample string";
    enum size_t hashVal = ctfeHash(test_str);
    assert(hashVal == bytesHash(test_str.ptr, test_str.length));
}



 //   Compute hash value of UTF-8 string.
//    Should be reworked in future.
@trusted pure nothrow
private size_t stringHash(in char[] arr)
{
    size_t hash = 0;
    foreach (char c; arr)
        hash = hash * 11 + c;
    return hash;
}

private template Unqual(T)
{
         static if (is(T U == shared(const U))) alias U Unqual;
    else static if (is(T U ==        const U )) alias U Unqual;
    else static if (is(T U ==    immutable U )) alias U Unqual;
    else static if (is(T U ==        inout U )) alias U Unqual;
    else static if (is(T U ==       shared U )) alias U Unqual;
    else                                        alias T Unqual;
}

//  all toUbyte funtions must be evaluatable at compile time
@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(T[] arr) if (T.sizeof == 1)
{
    return cast(const(ubyte)[])arr;
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(T[] arr) if (is(typeof(toUbyte(arr[0])) == const(ubyte)[]))
{
    if (__ctfe)
    {
        const(ubyte)[] ret;
        foreach (cur; arr)
        {
            ret ~= toUbyte(cur);
        }
        return ret;
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])arr;
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (__traits(isIntegral, T) && !is(T == enum))
{
    static if (T.sizeof == 1)
    {
        if (__ctfe)
        {
            return cast(const(ubyte)[])[val];
        }
        else
        {
            return cast(const(ubyte)[])((&val)[0..1]);
        }
    }
    else if (__ctfe)
    {
        ubyte[T.sizeof] tmp;
        Unqual!T val_ = val;
        for (size_t i=0; i<T.sizeof; ++i)
        {
            size_t idx;
            version(LittleEndian) idx = i;
            else idx = T.sizeof-i-1;
            tmp[idx] = cast(ubyte)(val_&0xff);
            val_ >>= 8;
        }

        return tmp[];

    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (is(Unqual!T == float) || is(Unqual!T == ifloat))
{
    if (__ctfe)
    {
        return toUbyte(*cast(int*)&val);
    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (is(Unqual!T == double) || is(Unqual!T == idouble))
{
    if (__ctfe)
    {
        return toUbyte(*cast(long*)&val);
    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}

//unable to convert real to ubyte[] at ctfe.
@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (false && is(Unqual!T == real) || is(Unqual!T == ireal))
{
    if (__ctfe)
    {
        ubyte[T.sizeof] tmp;
        for (size_t i=0; i<T.sizeof; ++i)
        {
            tmp[idx] = (cast(ubyte*)(&val))[i];
        }

        return tmp[];

    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (is(Unqual!T == cfloat) || is(Unqual!T == cdouble)/*||is(Unqual!T == creal)*/)
{
    if (__ctfe)
    {
        auto re = val.re;
        auto im = val.im;
        return (re.toUbyte() ~ im.toUbyte());
    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (is(T == enum) && is(typeof(toUbyte(cast(V)val)) == const(ubyte)[]))
{
    if (__ctfe)
    {
        static if (is(T V == enum)){}
        V e_val = val;
        return toUbyte(e_val);
    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}

private bool isNonReference(T)()
{
    static if (is(T == struct) || is(T == union))
    {
        return isNonReferenceStruct!T();
    }
    else static if (__traits(isStaticArray, T))
    {
      return isNonReference!(typeof(T.init[0]))();
    }
    else static if (is(T E == enum))
    {
      return isNonReference!(E)();
    }
    else static if (!__traits(isScalar, T))
    {
        return false;
    }
    else static if (is(T V : V*))
    {
        return false;
    }
    else static if (is(T == function))
    {
        return false;
    }
    else
    {
        return true;
    }
}

private bool isNonReferenceStruct(T)() if (is(T == struct) || is(T == union))
{
    foreach (cur; T.init.tupleof)
    {
        static if (!isNonReference!(typeof(cur))()) return false;
    }

    return true;
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if (is(T == struct) || is(T == union) && isNonReferenceStruct!T())
{
    if (__ctfe)
    {
        ubyte[T.sizeof] bytes;
        foreach (key, cur; val.tupleof)
        {
            bytes[val.tupleof[key].offsetof .. val.tupleof[key].offsetof + cur.sizeof] = toUbyte(cur)[];
        }
        return bytes[];
    }
    else
    {
        return (cast(const(ubyte)*)&val)[0 .. T.sizeof];
    }
}


