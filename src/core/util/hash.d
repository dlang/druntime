/**
 * The console module contains a hash implementation.
 *
 * Copyright: Copyright Sean Kelly 2009 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly    (hashOf)
 *            Igor Stepanov (computeHash, aaGetHashStatic, xxxGetHash et c.)
 */

/*          Copyright Sean Kelly 2009 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.util.hash;


version( X86 )
    version = AnyX86;
version( X86_64 )
    version = AnyX86;
version( AnyX86 )
    version = HasUnalignedOps;


@trusted pure nothrow
size_t hashOf( const (void)* buf, size_t len, size_t seed = 0 )
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

    if( len <= 0 || data is null )
        return 0;

    rem = len & 3;
    len >>= 2;

    for( ; len > 0; len-- )
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

// Check that hashOf works with CTFE
unittest
{
    size_t ctfeHash(string x)
    {
        return hashOf(x.ptr, x.length);
    }

    enum test_str = "Sample string";
    enum size_t hashVal = ctfeHash(test_str);
    assert(hashVal == hashOf(test_str.ptr, test_str.length));
}


/**
    Compute hash value of UTF-8 string.
*/
@trusted pure nothrow
size_t stringHash(in char[] arr)
{
    size_t hash = 0;
    foreach (char c; arr)
        hash = hash * 11 + c;
    return hash;
}

/**
    Compute hash value for different types.
*/
@trusted nothrow pure
size_t computeHash(T)(auto ref T val) if(!(is(T U: U[])&&is(Unqual!U: Object)) && !is(Unqual!T : Object))
{
    static if(is(T: const(char)[]))
    {
        return stringHash(val);
    }
    else static if(__traits(isIntegral, T) && (T.sizeof <= 4))
    {
        return val;
    }
    else static if(is(Unqual!T == float))
    {
        return *cast(int*)&val;
    }
    else static if(__traits(isArithmetic, T))
    {
        auto bytes = val.toUbyte();
        return hashOf(bytes.ptr, bytes.length);
    }
    else static if(__traits(isStaticArray, T) && __traits(compiles, val.toUbyte()))
    {
        auto bytes = val[].toUbyte();
        return hashOf(bytes.ptr, bytes.length);
    }
    else static if(__traits(compiles, val.toUbyte()))
    {
        auto bytes = val.toUbyte();
        return hashOf(bytes.ptr, bytes.length);
    }
    else static if(__traits(isStaticArray, T))
    {
        size_t cur_hash = 0;
        foreach(ref cur; val)
        {
            cur_hash = computeHash(cur, cur_hash);
        }
        return cur_hash;
    }
    else static if(is(T X : X[]))
    {
        const(ubyte)[] bytes = cast(const(ubyte)[])cast(const(void)[])val;
        return hashOf(bytes.ptr, bytes.length);
    }
    else static if(is(T V : V*))
    {
        return cast(size_t)val;
    }
    else static if((is(Unqual!T == struct) || is(Unqual!T == union))  &&__traits(compiles, val.toHash()))
    {
        return val.toHash();
    }
    else static if(__traits(isAssociativeArray, T))
    {
        return aaGetHashStatic(val);
    }
    else
    {
        const(ubyte)[] bytes = cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
        return hashOf(bytes.ptr, bytes.length);
    }
}


@trusted nothrow
size_t computeHash(T)(auto ref T val) if((is(T U: U[])&&is(Unqual!U: Object)) || is(Unqual!T: Object))
{
    static if(is(T U: U[])&&is(Unqual!U: Object))
    {
        size_t hash = 0;
        foreach (Object o; val)
        {
            if (o)
                hash += o.toHash();
        }
        return hash;
    }
    else static if(is(Unqual!T == interface)||is(Unqual!T == class))
    {
        return val ? (cast(Object)val).toHash() : 0;
    } 
    else
    {
        static assert(0);
    }
}

/**
    Compute hash value of associative array, when information of array static type is available.
    CTFE ready.
*/
@trusted /*pure*/ nothrow
size_t aaGetHashStatic(T)(T aa) if(__traits(isAssociativeArray, T))
{
    try
    {
        if(!aa.length) return 0;
        size_t h = 0;
     
        foreach (key, val; aa)
        {
            size_t[2] hpair;
            hpair[0] = key.computeHash();
            hpair[1] = val.computeHash();
            h += hpair.computeHash();
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
            h += hpair.computeHash();
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

/**
    Compute hash value of static array, when information of array static type is unavailable.
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
    Compute hash value of dynamic array, when information of array static type is unavailable.
*/
@trusted nothrow
size_t daGetHash(in void* p, const(TypeInfo) tiRaw) 
{
    TypeInfo_StaticArray ti = unqualTi!(TypeInfo_StaticArray)(tiRaw);
    assert(ti);
    size_t vsz = ti.next.tsize;
    auto arr = *cast(ubyte[]*)p;
    ubyte[] ubarr = arr.ptr[0 .. arr.length*vsz];
    return ubarr.computeHash();
}

/**
    Compute hash value of interface, when information of array static type is unavailable.
*/
@trusted nothrow
size_t interfaceGetHash(in void* p) 
{
    if(!*cast(void**)p) return 0;
    Interface* pi = **cast(Interface ***)*cast(void**)p;
    Object o = cast(Object)(*cast(void**)p - pi.offset);
    return o.computeHash();
}

/**
    Compute hash value of struct, when information of array static type is unavailable.
*/
@safe nothrow pure
size_t structGetHash(in void* p, const(TypeInfo_Struct) ti)  //pure
{
    assert(p);
    if (ti.xtoHash)
    {
        return (*ti.xtoHash)(p);
    }
    else
    {
        const(void)[] bytes = p[0 .. ti.init().length];
        return bytes.computeHash();
    }
}

private 
{
    extern(D) alias int delegate(void*, void*) dg2_t;
    extern(C) size_t _aaLen(void* p) nothrow;
    extern(C) size_t _aaApply2(void* aa, size_t keysize, dg2_t dg) nothrow; //nothrow if dg is nothrow
    extern(C) hash_t _aaGetHash(void* aa, const(TypeInfo) tiRaw) nothrow;
}

@trusted pure nothrow
private T unqualTi(T=TypeInfo)(const(TypeInfo) tiRaw) nothrow if(is(T:TypeInfo))
{
    TypeInfo ti = cast(TypeInfo)tiRaw;
    while(true)
    {
        if(auto ti_const = cast(TypeInfo_Const)ti) 
        {
            static if(is(typeof(&tiConst.base) == TypeInfo*))
                ti = ti_const.base;
            else
                ti = ti_const.next;
        }
        else
            break;
    }
    
    T ret = cast(T)ti;
    
    return ret;
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

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(T[] arr) if(T.sizeof == 1)
{
    return cast(const(ubyte)[])arr;
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(T[] arr) if(__traits(isIntegral, T) && !is(T[] : const(wchar)[]) && !is(T[] : const(dchar)[]) && (T.sizeof != 1)) 
{
    if(__ctfe)
    {
        const(ubyte)[] ret;
        foreach(cur; arr)
        {
            ret ~= cur.toUbyte();
        }
        return ret;
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])arr;
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(T[] arr) if(__traits(isFloating, T) || is(T[]: const(wchar)[]) || is(T[]: const(dchar)[])) 
{
    if(__ctfe)
    {
        const(ubyte)[] ret;
        foreach(cur; arr)
        {
            ret ~= cur.toUbyte();
        }
        return ret;
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])arr;
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(__traits(isIntegral, T)) 
{
    static if(T.sizeof == 1)
    {
        if(__ctfe)
        {
            return cast(const(ubyte)[])[val];
        }
        else
        {
            return cast(const(ubyte)[])((&val)[0..1]);
        }
    }
    else if(__ctfe)
    {
        ubyte[T.sizeof] tmp;
        for(size_t i=0; i<T.sizeof; ++i)
        {
            size_t idx;
            version(LittleEndian) idx = i;
            else idx = T.sizeof-i-1;
            tmp[idx] = cast(ubyte)(val&0xff);
            val >>= 8;
        }
        try
        {
            return tmp.dup; //nothrow in CTFE
        }
        catch
        {
            assert(0);
        }
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == float)||is(Unqual!T == ifloat)) 
{
    if(__ctfe)
    {
        return (*cast(int*)&val).toUbyte();
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == double)||is(Unqual!T == idouble)) 
{
    if(__ctfe)
    {
        return (*cast(long*)&val).toUbyte();
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == real)||is(Unqual!T == ireal)) 
{
    if(__ctfe)
    {
        try //CTFE .dup is nothrow
        {
            return cast(const(ubyte)[])cast(const(void)[])[val].dup;
        }
        catch
        {
            assert(0);
        }
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}

@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == cfloat)||is(Unqual!T == cdouble)||is(Unqual!T == creal)) 
{
    if(__ctfe)
    {
        auto re = val.re;
        auto im = val.im;
        return (re.toUbyte() ~ im.toUbyte());
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}
