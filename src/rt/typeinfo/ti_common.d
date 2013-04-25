module rt.typeinfo.ti_common; 

private import core.util.hash;
private import core.stdc.string;
private import rt.util.string;

class TypeInfoCommonArray(T) : TypeInfo_Array
{
    override string toString() const { return T.stringof~"[]"; }

    override bool opEquals(Object o) { return TypeInfo.opEquals(o); }

    override size_t getHash(in void* p) @trusted const
    {
        T[] s = *cast(T[]*)p;
        return s.computeHash();
    }

    override bool equals(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;

        if (s1.length == s2.length)
        {
            for (size_t u = 0; u < s1.length; u++)
            {
                if(!next.equals(s1.ptr + u, s2.ptr + u)) return false;
            }
            return true;
        }
        return false;
    }

    override int compare(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;
        auto     c  = cast(sizediff_t)(s1.length - s2.length);
        if (c == 0)
        {
            for (size_t u = 0; u < s1.length; u++)
            {
                int cmp = next.compare(s1.ptr + u, s2.ptr + u);
                if(cmp > 0) return 1;
                if(cmp < 0) return -1;
            }
        }
        return c < 0 ? -1 : c > 0 ? 1 : 0;
    }

    override @property inout(TypeInfo) next() inout
    {
        return cast(inout)typeid(T);
    }
}

class TypeInfoIntegerArray(T): TypeInfoCommonArray!(T)
{
    override bool equals(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;

        return s1.length == s2.length &&
               memcmp(cast(void *)s1, cast(void *)s2, s1.length * T.sizeof) == 0;
    }

    override int compare(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            if (s1[u] < s2[u])
                return -1;
            else if (s1[u] > s2[u])
                return 1;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
}

class TypeInfoShortArray(T): TypeInfoIntegerArray!(T)
{
    @trusted:
    const:
    pure:
    nothrow:

    override int compare(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            int result = s1[u] - s2[u];
            if (result)
                return cast(int)result;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
}

class TypeInfoUbyteArray(T): TypeInfoCommonArray!(T)
{
    @trusted:
    const:
    pure:
    nothrow:

    override bool equals(in void* p1, in void* p2) const
    {
        T[] s1 = *cast(T[]*)p1;
        T[] s2 = *cast(T[]*)p2;

        return s1.length == s2.length &&
               memcmp(cast(void *)s1, cast(void *)s2, s1.length * T.sizeof) == 0;
    }
    
    override int compare(in void* p1, in void* p2) const
    {
        char[] s1 = *cast(char[]*)p1; //char, not T
        char[] s2 = *cast(char[]*)p2;

        return dstrcmp(s1, s2);
    }
}

class TypeInfoCommonScalar(T): TypeInfo
{
    @trusted:
    const:
    //pure:
    //nothrow:
    
    override size_t getHash(in void* p)
    {
        return computeHash(*cast(T*)p);
    }
    
    override bool equals(in void* p1, in void* p2)
    {
        return *cast(T*)p1 == *cast(T*)p2;
    }
    
    override @property size_t tsize() nothrow pure
    {
        return T.sizeof;
    }
    
    override string toString() pure nothrow @safe { return T.stringof; }
    
    override void swap(void *p1, void *p2) pure nothrow @safe
    {
        T t;

        t = *cast(T*)p1;
        *cast(T*)p1 = *cast(T*)p2;
        *cast(T*)p2 = t;
    }
    
    override const(void)[] init() nothrow pure
    {
        static immutable T r;
        return (cast(T*)&r)[0 .. 1];
    }

    override @property size_t talign() nothrow pure
    {
        return T.alignof;
    }
}

class TypeInfoComplex(T): TypeInfoCommonScalar!(T)
{
    @trusted:
    pure:
    nothrow:
    const:

    override int compare(in void* p1, in void* p2)
    {
        int result;
        auto f1 = *cast(T*)p1;
        auto f2 = *cast(T*)p2;
        
        if (f1.re < f2.re)
            result = -1;
        else if (f1.re > f2.re)
            result = 1;
        else if (f1.im < f2.im)
            result = -1;
        else if (f1.im > f2.im)
            result = 1;
        else
            result = 0;
        return result;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(typeof(T.init.re));
        arg2 = typeid(typeof(T.init.re));
        return 0;
    }
}

class TypeInfoFloat(T): TypeInfoCommonScalar!(T)
{
    @trusted:
    pure:
    nothrow:
    const:

    override bool equals(in void* p1, in void* p2)
    {
        auto f1 = *cast(T*)p1;
        auto f2 = *cast(T*)p2;
        return f1 == f2 ||
                (f1 !<>= f1 && f2 !<>= f2);
    }

    override int compare(in void* p1, in void* p2)
    {
        auto f1 = *cast(T*)p1;
        auto f2 = *cast(T*)p2;
        if (f1 !<>= f1)         // if either are NaN
        {
            if (f1 !<>= f1)
            {
                if (f1 !<>= f1)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (f1 == f1) ? 0 : ((f1 < f1) ? -1 : 1);
    }
}

class TypeInfoInteger(T): TypeInfoCommonScalar!(T)
{
    @trusted:
    const:
    pure:
    nothrow:

    override int compare(in void* p1, in void* p2)
    {
        if (*cast(T*)p1 < *cast(T*)p2)
            return -1;
        else if (*cast(T*)p1 > *cast(T*)p2)
            return 1;
        return 0;
    }
}

class TypeInfoShort(T): TypeInfoInteger!(T)
{
    @trusted:
    const:
    pure:
    nothrow:

    override int compare(in void* p1, in void* p2)
    {
        return *cast(T*)p1 - *cast(T*)p2;
    }

}


