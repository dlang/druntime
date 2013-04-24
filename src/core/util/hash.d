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
size_t computeHash(T)(auto ref T val) if(!(is(T U: U[])&&(is(Unqual!U == interface)||is(Unqual!U == class))) && !is(Unqual!T : Object) && !__traits(isAssociativeArray, T))
{
    static if(is(Unqual!T EType == enum))
    {
        EType e_val = cast(EType)val;
        return computeHash(e_val);
    }
    else static if(is(T: const(char)[]))
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
    else static if(__traits(isStaticArray, T))
    {
        size_t cur_hash = 0;
        foreach(ref cur; val)
        {
            cur_hash += computeHash(cur);
        }
        return cur_hash;
    }
    else static if(is(T S: S[])&&(is(Unqual!S == struct)||is(Unqual!S == union)) && is(typeof(val[0].toHash()) == size_t))
    {
        size_t hash = 0;
        foreach (o; val)
        {
            hash += o.toHash();
        }
        return hash;
    }
    else static if(is(typeof(toUbyte(val)) == const(ubyte)[]) && !is(Unqual!T == struct) && !is(Unqual!T == union))
    {
        auto bytes = toUbyte(val);
        return hashOf(bytes.ptr, bytes.length);
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
    else static if((is(Unqual!T == struct) || is(Unqual!T == union))  && is(typeof(val.toHash()) == size_t))
    {
        return val.toHash();
    }
    else static if(is(Unqual!T == struct) || is(Unqual!T == union))
    {

        auto bytes = toUbyte(val);
        return hashOf(bytes.ptr, bytes.length);
    }
    else
    {
        const(ubyte)[] bytes = cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
        return hashOf(bytes.ptr, bytes.length);
    }
}


@trusted nothrow
size_t computeHash(T)(auto ref T val) if((is(T U: U[])&&(is(Unqual!U == interface)||is(Unqual!U == class))) || is(Unqual!T: Object) || __traits(isAssociativeArray, T))
{
    static if(is(T U: U[])&&(is(Unqual!U == interface)||is(Unqual!U == class)))
    {
        size_t hash = 0;
        foreach (o; val)
        {
            if (o)
                hash += (cast(Object)o).toHash();
        }
        return hash;
    }
    else static if(is(Unqual!T == interface)||is(Unqual!T == class))
    {
        return val ? (cast(Object)val).toHash() : 0;
    } 
    else static if(__traits(isAssociativeArray, T))
    {
        return aaGetHashStatic(val);
    }
    else
    {
        static assert(0);
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
    enum int[int] aaexpr = [1:2, 3:4, 5:6];
    enum Gun eexpr = Gun.A;
    enum cdouble coxpr = 7+4i;
    enum Foo[] staexpr = [Foo(), Foo(), Foo()];

    //CTFE hashes
    enum h1 = dexpr.computeHash();
    enum h2 = fexpr.computeHash();
    enum h3 = wsexpr.computeHash();
    enum h4 = csexpr.computeHash();
    enum h5 = iexpr.computeHash();
    enum h6 = lexpr.computeHash();
    enum h7 = saexpr.computeHash();
    enum h8 = daexpr.computeHash();
    enum h9 = thsexpr.computeHash();
    enum h10 = vsexpr.computeHash();
    enum h11 = aaexpr.computeHash();
    enum h12 = eexpr.computeHash();
    enum h13 = coxpr.computeHash();
    enum h14 = computeHash(new Boo);
    enum h15 = staexpr.computeHash();
    enum h16 = computeHash([new Boo, new Boo, new Boo]);
    enum h17 = computeHash([cast(IBoo)new Boo, cast(IBoo)new Boo, cast(IBoo)new Boo]);
    
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
    auto v13 = coxpr;    
    auto v14 = new Boo;
    auto v15 = staexpr;
    auto v16 = [new Boo, new Boo, new Boo];
    auto v17 = [cast(IBoo)new Boo, cast(IBoo)new Boo, cast(IBoo)new Boo];
    
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
    
    import core.stdc.stdio;
    
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
    TypeInfo_Array ti = unqualTi!(TypeInfo_Array)(tiRaw);
    assert(ti);
    try
    {   //TypeInfo.opEquals not nothrow
        if(ti.next == typeid(const(char))||ti.next == typeid(shared(char)))
        {
            return typeid(string).getHash(p); //Use algorithm, optimized for strings
        }
        else if(cast(TypeInfo_Class)ti.next) //is class object
        {
            auto arr = *cast(Object[]*)p;
            size_t hash = 0;
            foreach(o; arr)
            {
                if(o)
                    hash += o.toHash(); //can throw exception
            }
            return hash;
        }
        else if(cast(TypeInfo_Interface)ti.next) //is class object
        {
            auto arr = *cast(void*[]*)p;
            size_t hash = 0;
            foreach(cur; arr)
            {
                if(cur)
                {
                    Interface* pi = **cast(Interface ***)cur;
                    Object o = cast(Object)(cur - pi.offset);
                    hash += o.toHash();
                }
            }
            return hash;
        }
        else if(cast(TypeInfo_Struct)ti.next && (cast(TypeInfo_Struct)ti.next).xtoHash) //is class object
        {
            auto struct_ti = cast(TypeInfo_Struct)ti.next;
            auto arr = *cast(void[]*)p;
            size_t hash = 0;
            size_t sz = struct_ti.tsize;
            auto xtoHash = struct_ti.xtoHash;
            for(size_t i=0; i<arr.length; i++)
            {
                void* cur = arr.ptr + i*sz;
                hash += xtoHash(cur);
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
private const(ubyte)[] toUbyte(T)(T[] arr) if(is(typeof(toUbyte(arr[0])) == const(ubyte)[])) 
{
    if(__ctfe)
    {
        const(ubyte)[] ret;
        foreach(cur; arr)
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
private const(ubyte)[] toUbyte(T)(ref T val) if(__traits(isIntegral, T)&&!is(Unqual!T == enum)) 
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
	Unqual!T val_ = val;
        for(size_t i=0; i<T.sizeof; ++i)
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
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == float)||is(Unqual!T == ifloat)) 
{
    if(__ctfe)
    {
        return toUbyte(*cast(int*)&val);
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
        return toUbyte(*cast(long*)&val);
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
        ubyte[T.sizeof] tmp;
        for(size_t i=0; i<T.sizeof; ++i)
        {
            tmp[idx] = (cast(ubyte*)(&val))[i];
        }

        return tmp[];

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


@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == enum)) 
{
    if(__ctfe)
    {
        static if(is(Unqual!T V == enum)){}
        V e_val = val;
        return toUbyte(e_val);
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}


private bool isNonReference(T)()
{
    static if(is(Unqual!T == struct) || is(Unqual!T == union))
    {
        return isNonReferenceStruct!T();
    }
    else static if(__traits(isStaticArray, T))
    {
      return isNonReference!(typeof(T.init[0]))();
    }
    else static if(is(Unqual!T E == enum))
    {
      return isNonReference!(E)();
    }
    else static if(!__traits(isScalar, T))
    {
        return false;
    }
    else static if(is(T V : V*))
    {
        return false;
    }
    else static if(is(T == function))
    {
        return false;
    }
    else
    {
        return true;
    }
}


private bool isNonReferenceStruct(T)() if(is(Unqual!T == struct) || is(Unqual!T == union))
{
    foreach(cur; T.init.tupleof)
    {
        static if(!isNonReference!(typeof(cur))()) return false;
    }
    
    return true;
}


@trusted pure nothrow
private const(ubyte)[] toUbyte(T)(ref T val) if(is(Unqual!T == struct) || is(Unqual!T == union)) 
{  
    static assert(isNonReferenceStruct!T(), "Unable to represent "~T.stringof~" as const(ubyte)[]");
    if(__ctfe)
    {
        ubyte[T.sizeof] bytes;
        foreach(key, cur; val.tupleof)
        {
            bytes[val.tupleof[key].offsetof .. val.tupleof[key].offsetof + cur.sizeof] = toUbyte(cur)[];
        }
        return bytes[];
    }
    else
    {
        return cast(const(ubyte)[])cast(const(void)[])((&val)[0..1]);
    }
}


