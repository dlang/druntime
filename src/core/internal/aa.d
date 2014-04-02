module core.internal.aa;

import core.internal.hash;
import core.exception;
import core.memory;

/**
    [a:b, c:d] should be converted to associativeArrayLiteral(a, b, c, d);
*/

enum Mutability
{
    Mutable,
    Const,
    Immutable,
    /*Shared,
    ConstShared*/
}

auto associativeArrayLiteral(Mutability mutability = Mutability.Mutable, KeyType = void, ValueType = void, T...)(T elems) @trusted //pure
{
    static assert(T.length, "Unable to determine associative array literal type, because it haven't elements.");
    static assert(T.length % 2 == 0, "associativeArrayLiteral should get even args count");
    static assert(is(commonType!(KeyValue.Key, T)), "unable to determine common key type for associativeArrayLiteral!("~T.stringof~")");
    static assert(is(commonType!(KeyValue.Value, T)), "unable to determine common value type for associativeArrayLiteral!("~T.stringof~")");
    
    static if(is(KeyType == void) || is(ValueType == void))
    {
        alias Key = commonType!(KeyValue.Key, T);
        alias Value = commonType!(KeyValue.Value, T);
    }
    else
    {
       alias Key = KeyType;
       alias Value = ValueType; 
    }
    static if(mutability == Mutability.Mutable)
        return AssociativeArray!(Key, Value)(elems);
    else static if(mutability == Mutability.Const)
        return cast(const(AssociativeArray!(Key, Value)))AssociativeArray!(Key, Value)(elems);
    else static if(mutability == Mutability.Immutable)
        return cast(immutable(AssociativeArray!(Key, Value)))AssociativeArray!(Key, Value)(elems);
    /*else static if(mutability == Mutability.Shared)
        return cast(shared(AssociativeArray!(Key, Value)))AssociativeArray!(Key, Value)(elems);
    else static if(mutability == Mutability.ConstShared)
        return cast(const(shared(AssociativeArray!(Key, Value))))AssociativeArray!(Key, Value)(elems);*/
    else
        static assert(0);
}

struct AssociativeArray(Key, Value)
{ 
    this(typeof(null)) pure
    {
        //do nothing
    }
    
    this(T...)(T args) if (T.length > 2 && T.length % 2 == 0)
    {
        template _Tuple(T...)
        {
            alias _Tuple = T;
        }

        template Step2Tuple(size_t len, size_t idx = 0)
        {
            static if (idx >= len)
            {
                alias Step2Tuple = _Tuple!();
            }
            else
            {
                alias Step2Tuple = _Tuple!(idx, Step2Tuple!(len, idx + 2));
            }
        }
        
        static bool testKey(const(Entry)* pe, in size_t kh, in Key k)
        {
            
            auto e = pe;
            
            while (e !is null)
            {
                if (kh == e.hash && k == e.key)
                {
                    return false;
                }
                e = e.next;
            }
            return true;
        }
        
        impl = new Impl();
        impl.nodes = args.length/2;
        if (impl.binit.length <= impl.nodes)
            impl.buckets = impl.binit[];
        else
            impl.buckets = newBuckets(findGoodPrime(impl.nodes));
        auto len = impl.buckets.length;
        
        foreach (i; Step2Tuple!(T.length))
        {
            alias key = args[i];
            alias value = args[i+1];
            size_t key_hash = hashOf(cast(Key)key);

            size_t idx = key_hash % len;

            assert(testKey(impl.buckets[idx], key_hash, key), "duplicate key");
            auto e = new Entry;
            e.next = impl.buckets[idx];
            e.hash = key_hash;
            cast()e.key = key;
            cast()e.value = value;
            impl.buckets[idx] = e;
            
        }
    }
    
    @property @safe pure nothrow const
    size_t length()
    out (result)
    {
        size_t len = 0;
        if (impl !is &null_impl)
        {
            foreach (const(Entry)* e; impl.buckets)
            {
                while (e !is null)
                {   
                    len++;
                    e = e.next;
                }
            }
        }
        assert(len == result);
    }
    body
    {
        return impl !is &null_impl ? impl.nodes : 0;
    }
    
    Value* opIn_r(in _Unqual!Key key) @trusted nothrow pure
    {
        return getRValue(&key);
    }
    
    const(Value)* opIn_r(in _Unqual!Key key) const @trusted nothrow pure
    {
        return getRValue(&key);
    }
    
    ref Value opIndex(in _Unqual!Key key) @trusted pure
    {
        auto v = getRValue(&key);
        if (v is null)
            onRangeError();
        else 
            return *v;
        assert(0);
    }
    
    ref const(Value) opIndex(in _Unqual!Key key) const @trusted pure
    {
        auto v = getRValue(&key);
        if (v is null)
            onRangeError();
        else 
            return *v;
        assert(0);
    }
    
    ref Value opIndexAssign(in _Unqual!Value value, in _Unqual!Key key) @trusted
    {
        auto v = getLValue(&key);
        *v = value;
        return *v;
    }

    bool remove(in Key key) @trusted nothrow pure
    {
        if (impl is &null_impl)
        {   
            return false;
        }

        auto key_hash = hashOf(cast()key);

        size_t i = key_hash % impl.buckets.length;
        Entry* pe = null;
        Entry* e = impl.buckets[i];

        while (e !is null)
        {
            if (key_hash == e.hash && key == e.key)
            {
                if (pe !is null)
                {
                    pe.next = e.next;
                }
                else
                {
                    impl.buckets[i] = e.next;
                }
                if (!__ctfe)
                {
                    GC.free(e.next); //Is it necessary?
                }
                impl.nodes--;
                return true;
            }
            pe = e;
            e = e.next;
        }

        return false;
    }           
    
    AssociativeArray rehash() @safe
    {
        return _rehash();
    }
    
    AssociativeArray dup() @safe const
    {
        return _dup();
    }


    Value[] values() @property /*nothrow @trusted pure: opAssign can be impure and doesn't @safe*/
    {
        if (!length) return null;
        size_t i = 0;
        
        Value[] elems = new Value[impl.nodes];
        //Do I need to set GC.BlkAttr.NO_SCAN?
        //a.length = _aaLen(aa);
        //a.ptr = cast(byte*) GC.malloc(a.length * valuesize,
        //                                valuesize < (void*).sizeof ? GC.BlkAttr.NO_SCAN : 0);

        foreach (e; impl.buckets) //Would be `for` cycle faster?
        {
            while (e !is null)
            {
                cast()elems[i] = e.value;
                e = e.next;
                i++;
            }
        }
        assert(i == impl.nodes);

        return elems;
    }
    
    Key[] keys() @property /*nothrow @trusted pure: opAssign can be impure and doesn't @safe*/
    {
        if (!length) return null;
        size_t i = 0;
        
        Key[] elems = new Key[impl.nodes];

        foreach (e; impl.buckets)
        {
            while (e !is null)
            {
                cast()elems[i] = e.key;
                e = e.next;
                i++;
            }
        }
        assert(i == impl.nodes);

        return elems;
    }    
    
    const(Value)[] values() const @property
    {
        return cast(const)(cast()this).values;
    }

    const(Key)[] keys() const @property
    {
        return cast(const)(cast()this).keys;
    } 

    inout(Value)[] inout_values() inout @property
    {
        return cast(inout(Value)[])values;
    }

    inout(Key)[] inout_keys() inout @property
    {
        return cast(inout(Key)[])keys;
    }    
    
    int opApply(scope int delegate(ref Value) dg)
    {
        if (impl is &null_impl)
        {
            return 0;
        }

        foreach (e; impl.buckets)
        {
            while (e !is null)
            {
                auto result = dg(e.value);
                if (result)
                    return result;
                e = e.next;
            }
        }
        return 0;
    }
    
    int opApply(scope int delegate(ref Key, ref Value) dg)
    {
        if (impl is &null_impl)
        {
            return 0;
        }

        foreach (e; impl.buckets)
        {
            while (e !is null)
            {
                auto result = dg(e.key, e.value);
                if (result)
                    return result;
                e = e.next;
            }
        }
        return 0;
    }
    
    int opApply(scope int delegate(ref const(Value)) dg) const
    {
        if (impl is &null_impl)
        {
            return 0;
        }

        foreach (const(Entry)* e; impl.buckets)
        {
            while (e !is null)
            {
                auto result = dg(e.value);
                if (result)
                    return result;
                e = e.next;
            }
        }
        return 0;
    }
    
    int opApply(scope int delegate(ref const(Key), ref const(Value)) dg) const
    {
        if (impl is &null_impl)
        {
            return 0;
        }

        foreach (const(Entry)* e; impl.buckets)
        {
            while (e !is null)
            {
                auto result = dg(e.key, e.value);
                if (result)
                    return result;
                e = e.next;
            }
        }
        return 0;
    }
    
    Value get(in Key key, lazy Value defaultValue)
    {
        auto p = key in this;
        return p ? *p : defaultValue;
    }

    const(Value) get(in Key key, lazy Value defaultValue) const
    {
        auto p = key in this;
        return p ? *p : defaultValue;
    }    
    
    auto byKey() @safe pure nothrow
    {
        return getRange!(KeyValue.Key)();
    }
    
    auto byValue() @safe pure nothrow
    {
        return getRange!(KeyValue.Value)();
    }
    
    auto byKey() @safe pure nothrow const
    {
        return getRange!(KeyValue.Key)();
    }
    
    auto byValue() @safe pure nothrow const
    {
        return getRange!(KeyValue.Value)();
    }
    
    bool opEquals()(auto ref const AssociativeArray rvl) const 
    { 
        if (length != rvl.length) return false;
        if (!length) return true;
        
        foreach (const(Entry)* e1; impl.buckets)
        {
            while (e1 !is null)
            {
                auto idx = e1.hash % rvl.impl.buckets.length;
                
                const(Entry)* e2 = rvl.impl.buckets[idx];
                while (e2 !is null)
                {
                    if (e2.hash == e1.hash && e2.key == e1.key)
                        break;
                    e2 = e2.next;
                }
                if (!e2)
                    return false;
                
                e1 = e1.next;
            }
        }
        return true;
    }
    
    ref AssociativeArray opAssign(typeof(null)) @trusted pure nothrow
    {
        impl = cast(Impl*)&null_impl;
        return this;
    }
    
    private AssociativeArray _rehash() @trusted
    {
        AssociativeArray ret;
        if (impl is &null_impl) return ret;
        
        if (!impl.buckets.length)
        {
            if (impl.buckets.ptr != impl.binit.ptr && !__ctfe)
            {
                GC.free(impl.buckets.ptr);
                impl.buckets = impl.binit[];
            }
            return this;
        }

        Impl newImpl;
        Impl* oldImpl = impl;

        auto len = findGoodPrime(impl.nodes);

        newImpl.buckets = newBuckets(len);

        foreach (e; oldImpl.buckets)
        {
            while (e !is null)
            {
                auto nexte = e.next;
                const j = e.hash % len;
                e.next = newImpl.buckets[j];
                newImpl.buckets[j] = e;
                e = nexte;
            }
        }
        newImpl.nodes = oldImpl.nodes;

        if (oldImpl.buckets.ptr == oldImpl.binit.ptr)
            oldImpl.binit[] = null;
        else if (!__ctfe)
            GC.free(oldImpl.buckets.ptr);
        if (!__ctfe)
        {
            *impl = newImpl;
        }
        else
        {
            impl = new Impl(newImpl);
        }
        return this;
    }

    private AssociativeArray _dup() @trusted const
    {
        AssociativeArray ret;
        if (impl is &null_impl) return ret;
        

        ret.impl = new Impl;
        ret.impl.buckets = ret.impl.binit[];


        Impl newImpl;
        const Impl* oldImpl = impl;

        auto len = findGoodPrime(impl.nodes);

        newImpl.buckets = newBuckets(len);
        

        foreach (const(Entry)* e; oldImpl.buckets)
        {
            while (e !is null)
            {
                const j = e.hash % len;
                auto newe = new Entry;
                newe.hash = e.hash;
                cast()newe.key = e.key;
                cast()newe.value = e.value;
                newe.next = newImpl.buckets[j];
                newImpl.buckets[j] = newe;
                e = e.next;
            }
        }

        newImpl.nodes = oldImpl.nodes;

       if (!__ctfe)
       {
           *ret.impl = newImpl;
       }
       else
       {
           ret.impl = new Impl(newImpl);
       }
       return ret;

    }

        
    
    private _Unqual!Value* getLValue(in _Unqual!Key* pkey) @trusted
    {
        if (impl is &null_impl)
        {   
            impl = new Impl();
            impl.buckets = impl.binit[];
        }

        auto key_hash = hashOf(cast()*pkey); //!hashOf bug

        size_t i = key_hash % impl.buckets.length;
        auto pe = impl.buckets[i];
        auto e = pe;

        while (e !is null)
        {
            if (key_hash == e.hash && *pkey == e.key)
            {
                return cast(_Unqual!Value*)&e.value;
            }
            e = e.next;
        }

        e = new Entry;
        e.next = pe;
        e.hash = key_hash;
        cast()e.key = *pkey;
        impl.buckets[i] = e;

        auto nodes = ++impl.nodes;

        if (nodes > impl.buckets.length * RehashOverflow)
        {
            rehash();
        }

        return cast(_Unqual!Value*)&e.value;
    }    
    
    //!CTFE BUG: cannot cast &Entry(...) to inout(Entry)*
    private Value* getRValue(in _Unqual!Key* pkey) @safe nothrow pure
    {
        if (impl is &null_impl)
        {   
            return null;
        }

        auto key_hash = hashOf(cast(_Unqual!Key)*pkey); //!hashOf bug

        size_t i = key_hash % impl.buckets.length;
        Entry* pe = impl.buckets[i]; 
        Entry* e = pe;

        while (e !is null)
        {
            if (key_hash == e.hash && *pkey == e.key)
            {
                return &e.value;
            }
            e = e.next;
        }

        return null;
    }  
    
    private const(Value)* getRValue(in _Unqual!Key* pkey) @safe const nothrow pure
    {
        if (impl is &null_impl)
        {   
            return null;
        }

        auto key_hash = hashOf(cast(_Unqual!Key)*pkey); //!hashOf bug

        size_t i = key_hash % impl.buckets.length;
        const(Entry)* pe = impl.buckets[i];
        const(Entry)* e = pe;

        while (e !is null)
        {
            if (key_hash == e.hash && *pkey == e.key)
            {
                return &e.value;
            }
            e = e.next;
        }

        return null;
    }      

    private static Entry*[] newBuckets(in size_t len) @trusted pure nothrow
    {
        if (!__ctfe)
        {
            auto ptr = cast(Entry**) GC.calloc(
                len * (Entry*).sizeof, GC.BlkAttr.NO_INTERIOR);
            return ptr[0..len];
        }
        else
        {
            return new Entry*[len];
        }
    }
    

    // Auto-rehash and pre-allocate - Dave Fladebo

    private static immutable size_t[] prime_list = [
                31UL,
                97UL,            389UL,
             1_543UL,          6_151UL,
            24_593UL,         98_317UL,
           393_241UL,      1_572_869UL,
         6_291_469UL,     25_165_843UL,
       100_663_319UL,    402_653_189UL,
     1_610_612_741UL,  4_294_967_291UL,
 //  8_589_934_513UL, 17_179_869_143UL
    ];

    private static size_t findGoodPrime(size_t idx) @safe pure nothrow
    {
        foreach (i; 0 .. prime_list.length)
        {
            if (prime_list[i] > idx) 
                return prime_list[i];
        }
        return prime_list[$-1];
    }
    
    private Range!(Mutability.Mutable, kv) getRange(KeyValue kv)() @safe pure nothrow
    {
        Range!(Mutability.Mutable, kv) res;
        if (!length)
            return res;

        res.impl = impl is &null_impl ? null : impl;
        foreach (entry; impl.buckets)
        {
            if (entry !is null)
            {
                res.current = entry;
                break;
            }
        }
        return res;
    }
    
    private Range!(Mutability.Const, kv) getRange(KeyValue kv)() @safe pure nothrow const
    {
        Range!(Mutability.Const, kv) res;
        if (!length)
            return res;

        res.impl = impl is &null_impl ? null : impl;
        foreach (entry; impl.buckets)
        {
            if (entry !is null)
            {
                res.current = entry;
                break;
            }
        }
        return res;
    }    

    static private size_t _aaLen(in void* aa) @trusted pure nothrow
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.length;
    }
    
    static private void* _aaGetX(void** aa, in void* pkey) @trusted
    {
        auto _this = *cast(AssociativeArray*)aa;
        auto ret = cast(void*)_this.getLValue(cast(Key*)pkey);
        *aa = *cast(void**)&_this;
        return ret;
    }
    
    static private inout(void)* _aaGetRvalueX(inout void* aa, in void* pkey) @trusted pure
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return cast(inout(void)*)_this.getRValue(cast(Key*)pkey);
    }
    
    static private bool _aaDelX(void* aa, in void* pkey) @trusted
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.remove(*cast(Key*)pkey);
    }
    
    static private int _aaApply(void* aa, dg_t dg)
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.opApply(cast(int delegate(ref Value))dg);
    }
    
    static private int _aaApply2(void* aa, dg2_t dg)
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.opApply(cast(int delegate(ref Key, ref Value))dg);
    }
    
    static private int _aaEqual(in void* e1, in void* e2) @trusted pure nothrow
    {
        auto lvl = *cast(AssociativeArray*)&e1;
        auto rvl = *cast(AssociativeArray*)&e2;
        return lvl == rvl;
    }
    
    static private AssociativeArrayHandle getHandle()
    {
        AssociativeArrayHandle h;
        h.len        = &_aaLen;
        h.getX       = &_aaGetX;
        h.getRvalueX = &_aaGetRvalueX;
        h.delX       = &_aaDelX;
        h.apply      = &_aaApply;
        h.apply2     = &_aaApply2;
        h.equal      = &_aaEqual;        
        return h;
    }
    
    static struct Range(Mutability mutability, KeyValue kv)
    {
        static if(mutability == Mutability.Mutable)
        {
            private Impl* impl;
            private Entry* current;
            private alias RetKey = Key;
            private alias RetValue = Value;
        }
        else
        {
            private const(Impl)* impl;
            private const(Entry)* current;
            private alias RetKey = const(Key);
            private alias RetValue = const(Value);
        }   
        
        
        
        @property bool empty() 
        { 
            return current is null;
        }
        
        static if (kv == KeyValue.Key)
        {
            @property ref RetKey front() //really ref Key? may be ref const(Key) or Key?
            in
            {
                assert(current);
            }
            body
            { 
                return current.key; 
            }
        }
        else static if (kv == KeyValue.Value)
        {
            @property ref RetValue front() 
            in
            {
                assert(current);
            }
            body
            { 
                return current.value; 
            }
        }
        else
        {
            static assert(0);
        }
    
        void popFront() 
        in
        {
            assert(current);
        }
        body
        { 
            if (current.next !is null)
            {
                current = current.next;
            }
            else
            {
                immutable idx = current.hash % impl.buckets.length;
                current = null;
                foreach (entry; impl.buckets[idx + 1 .. $])
                {
                    if (entry !is null)
                    {
                        current = entry;
                        break;
                    }
                }
            }
        }
        
        
        Range save() 
        { 
            return this; 
        }
    }

    private static struct Impl
    {
        AssociativeArrayHandle* handle = &AssociativeArray.handle;
        Entry*[] buckets;
        size_t nodes;       // total number of entries
        Entry*[4] binit;    // initial value of buckets[]
        
        this(typeof(null)) immutable //null handle: initial value if AssociativeArray.impl field
        {
            nodes = 0;
            handle = cast(immutable)&AssociativeArray.handle;
        }
        
        this(Impl i)
        {
            buckets = i.buckets;
            nodes = i.nodes;
            binit = i.binit;
        }
    }

    private static struct Entry
    {
        Entry *next;
        size_t hash;
        Key key;
        Value value;
    }
    
    private __gshared AssociativeArrayHandle handle = getHandle();
    private __gshared immutable Impl null_impl = immutable(Impl)(null);
    private enum RehashOverflow = 4;
    
    /**
        impl is initialized with special value: &null_impl instead of null;
        This value is common for all instances of this AA type.
        This trick is required to use handle value in _aaXXX functions.
        Thus unitialized instance of AA should have a handle.
        This value will be replaced with new Impl during first AA change.
    */
    private Impl* impl = cast(Impl*)&null_impl;
}


private template _Unqual(T)
{
         static if (is(T U == shared(const U))) alias U _Unqual;
    else static if (is(T U ==        const U )) alias U _Unqual;
    else static if (is(T U ==    immutable U )) alias U _Unqual;
    else static if (is(T U ==        inout U )) alias U _Unqual;
    else static if (is(T U ==       shared U )) alias U _Unqual;
    else                                        alias T _Unqual;
}

private enum KeyValue
{
    Key = 0,
    Value = 1
}

private template commonType(KeyValue kv, T...)
{
    static assert(T.length && T.length % 2 == 0);
    
    static if (T.length == 2)
    {
        alias commonType = T[kv];
    }
    else
    {
        alias commonType = typeof(true ? T[kv].init : commonType!(kv, T[2 .. $]));
    }
}

private struct AssociativeArrayHandle
{
    @trusted pure nothrow size_t function(in void* aa) len;
    @trusted               void* function(void** aa, in void* pkey) getX;
    @trusted pure   inout(void)* function(inout void* aa, in void* pkey) getRvalueX;
    @trusted                bool function(void* aa, in void* pkey) delX;
                             int function(void* aa, dg_t dg) apply;
                             int function(void* aa, dg2_t dg) apply2;
    @trusted pure nothrow    int function(in void* e1, in void* e2) equal;
}

void* aaLiteral(Key, Value, T...)(T args) @safe
{
    return associativeArrayLiteral!(Mutability.Mutable, Key, Value)(args).impl;
}

void* aaInit(Key, Value)() pure @trusted nothrow
{
    return cast(void*)&AssociativeArray!(Key, Value).null_impl;
}

//!Note: this functions are extern(D) now and doesn't conflict with aaA _aaXXX functions
extern (D) alias int delegate(void *) dg_t;
extern (D) alias int delegate(void *, void *) dg2_t;

size_t _aaLen(in void* aa) @trusted pure nothrow
in
{
    assert(aa);
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)aa;
    return handle.len(aa);
}

void* _aaGetX(void** aa, const TypeInfo, in size_t, in void* pkey) @trusted
in
{
    assert(aa);
    assert(*aa);
}
body
{
    auto handle = **cast(AssociativeArrayHandle***)aa;
    return handle.getX(aa, pkey);    
}

inout(void)* _aaGetRvalueX(inout void* aa, const TypeInfo, in size_t, in void* pkey) @trusted pure
in
{
    assert(aa);
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)aa;
    return handle.getRvalueX(aa, pkey);   
}

inout(void)* _aaInX(inout void* aa, in TypeInfo unused_1, in void* pkey) @trusted pure
in
{
    assert(aa);
}
body
{
    return _aaGetRvalueX(aa, unused_1, 0, pkey);   
}

bool _aaDelX(void* aa, in TypeInfo, in void* pkey) @trusted
in
{
    assert(aa);
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)aa;
    return handle.delX(aa, pkey);    
}

int _aaApply(void* aa, in size_t keysize, dg_t dg)
in
{
    assert(aa);
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)aa;
    return handle.apply(aa, dg);    
}

int _aaApply2(void* aa, in size_t keysize, dg2_t dg)
in
{
    assert(aa);
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)aa;
    return handle.apply2(aa, dg);    
}

int _aaEqual(in TypeInfo, in void* e1, in void* e2) @trusted pure nothrow
in
{
    assert(e1);
    assert(e2);
    
    auto handle1 = *cast(AssociativeArrayHandle**)e1;
    auto handle2 = *cast(AssociativeArrayHandle**)e2;
    assert(handle1 == handle2); //ensure that both objects has a same type
}
body
{
    auto handle = *cast(AssociativeArrayHandle**)e1;
    return handle.equal(e1, e2);    
}

version(unittest)
{

    int test1(bool isstatic)()
    {
        static if (isstatic)
            static aa1 = associativeArrayLiteral(1,2.0,  3.9L,4UL,  5UL,6);
        else
            auto aa1 = associativeArrayLiteral(1,2.0,  3.9L,4UL,  5UL,6);
            
        assert(aa1[1] == 2);
        assert(aa1[3.9] == 4);
        assert(aa1[5] == 6);
        assert(aa1.length == 3);
        aa1[2] = 3;
        aa1[3.9] = 8;
        aa1[5] += 4;
        
        aa1[8]  = 8;
        aa1[9]  = 9;
        aa1[10] = 10;
        
        assert(aa1[1] == 2);
        assert(aa1[2] == 3);
        assert(aa1[3.9] == 8);
        assert(aa1[5] == 10);
        assert(aa1[8] == 8);
        assert(aa1[9] == 9);
        assert(aa1[10] == 10);
        
        assert(aa1.length == 7);
        aa1 = aa1.rehash();
        
        assert(aa1[1] == 2);
        assert(aa1[2] == 3);
        assert(aa1[3.9] == 8);
        assert(aa1[5] == 10);
        assert(aa1[8] == 8);
        assert(aa1[9] == 9);
        assert(aa1[10] == 10);
        assert(aa1.length == 7);
        auto aa2 = aa1.dup;

        assert(aa2[1] == 2);
        assert(aa2[2] == 3);
        assert(aa2[3.9] == 8);
        assert(aa2[5] == 10);
        assert(aa2[8] == 8);
        assert(aa2[9] == 9);
        assert(aa2[10] == 10);
        assert(aa2.length == 7);

        assert(aa1 == aa2);
        
        aa2[99] = 99;
        assert(aa2.length == 8);
        assert(aa1 != aa2);

        return 0;
    }

    struct TestKey
    {
        int a;
        
        size_t toHash() @safe pure nothrow const
        {
            return a.hashOf();
        }
        
        void opAssign(TestKey tk)
        {
            a = tk.a;
        }
        
        bool opEquals(in TestKey rvl) const @safe pure nothrow
        {
            return a == rvl.a;
        }
    }

    struct TestValue
    {
        int a;

        void opAssign(TestValue tv)
        {
            a = tv.a;
        }
    }

    int test2()
    {
        auto aa1 = associativeArrayLiteral(const(TestKey)(1),const(TestValue)(2),  const(TestKey)(3),const(TestValue)(4),  const(TestKey)(5),const(TestValue)(6));
        
        //writeAA(aa1);
        assert(aa1[const(TestKey)(3)] == TestValue(4));
        
        return 1;
    }


    int test3()
    {
        auto aa1 = associativeArrayLiteral(1,2,  3,4,  5,6);
        
        //test length
        assert(_aaLen(*cast(void**)&aa1));
        int newkey = 7;
        
        //create a new elem
        auto pval = _aaGetX(cast(void**)&aa1, null, 0, &newkey);
        *cast(int*)pval = 8;
        assert(aa1[7] == 8);
        newkey = 1;
        
        //find the existing elem
        pval = _aaGetX(cast(void**)&aa1, null, 0, &newkey);
        *cast(int*)pval = 1;
        assert(aa1[1] == 1);
        
        AssociativeArray!(int, int) aa2;
        auto impl1 = aa2.impl;
        newkey = 1;
        
        //create a new elem in aa with null impl
        pval = _aaGetX(cast(void**)&aa2, null, 0, &newkey);
        *cast(int*)pval = 1;
        auto impl2 = aa2.impl;
        assert(impl2 != impl1);
        assert(aa2[1] == 1);
        
        //find the existing elem
        int key = 3;
        auto rval1 = _aaGetRvalueX(*cast(void**)&aa1, null, 0, &key);
        auto rval2 = _aaInX(*cast(void**)&aa1, null, &key);
        assert(rval1 == rval2 && *cast(int*)rval1 == 4);
        
        //find non-existing elem
        key = 4;
        rval1 = _aaGetRvalueX(*cast(void**)&aa1, null, 0, &key);
        rval2 = _aaInX(*cast(void**)&aa1, null, &key);
        assert(rval1 is null && rval2 is null);
        
        //delete non-existing elem
        auto rem = _aaDelX(*cast(void**)&aa1, null, &key);
        assert(!rem);
        
        //delete the existing elem
        key = 3;
        rem = _aaDelX(*cast(void**)&aa1, null, &key);
        assert(rem);
        assert(_aaLen(*cast(void**)&aa1) == 3);
        
        //test _aaApply and _aaApply2
        int sum = 0;
        int dg1(void* v)
        {
            sum += *cast(int*)v;
            return 0;
        }
        _aaApply(*cast(void**)&aa1, 0, &dg1);
        assert(sum == 15);
        
        sum = 0;
        int dg2(void* k, void* v)
        {
            sum += *cast(int*)k;
            sum += *cast(int*)v;
            return 0;
        }
        _aaApply2(*cast(void**)&aa1, 0, &dg2);
        assert(sum == 28);
        
        //test _aaEqual
        auto aa3 = aa1.dup;
        assert(_aaEqual(null, *cast(void**)&aa1, *cast(void**)&aa3));
        
        auto aalit = aaLiteral!(int, int)(1, 2, 3, 4);
        auto aanull = aaInit!(int, int)();
        
        return 0;
    }

    int test4()
    {
        AssociativeArray!(int, int) aa1;
        auto impl1 = aa1.impl;
        assert(impl1 !is null);
        assert(aa1.length == 0);
        
        assert(aa1.keys.length == 0);
        assert(aa1.values.length == 0);
        assert(aa1.byKey().empty);
        assert(aa1.byValue().empty);

        foreach (cur; aa1)
        {
            assert(0);
        }
        
        foreach (key, val; aa1)
        {
            assert(0);
        }
        auto aa2 = aa1.dup;
        assert(aa2 == aa1);
        aa1.rehash;
        assert(aa1.impl is impl1);
        AssociativeArray!(int, int) aa3;
        auto impl2 = aa3.impl;
        assert(impl1 is impl2);
        aa3[1] = 2;
        assert(aa3.impl !is impl2);
        
        AssociativeArray!(int, int) aa4 = null;
        assert(aa4.impl is impl1);
        
        aa1 = aa2;
        assert(aa1.impl == aa2.impl);
        
        aa1 = null;
        assert(aa1.impl == impl1);

        return 0;
    }

    int test5(Mutability mutability, bool isstatic)()
    {
        static if(isstatic)
            static aa1 = associativeArrayLiteral!(mutability)(1,2,  3,4,  5,6);
        else
            auto aa1 = associativeArrayLiteral!(mutability)(1,2,  3,4,  5,6);
        assert(aa1[1] == 2);
        
        assert(aa1.length == 3);
        
        auto aa2 = aa1.dup;
        aa2[1] = 8; //Mutable copy
        
        int sum = 0;
        foreach (key, val; aa1)
        {
            sum += key;
            sum += val;
        }
        
        assert(sum == 21);
        sum = 0;
        foreach (cur; aa1.byKey())
        {
            sum += cur;
        }
        assert(sum == 9);
        sum = 0;
        foreach (cur; aa1.keys)
        {
            sum += cur;
        }
        assert(sum == 9);
        sum = 0;
        foreach (cur; aa1.byValue())
        {
            sum += cur;
        }
        assert(sum == 12);
        sum = 0;
        foreach (cur; aa1.values)
        {
            sum += cur;
        }
        assert(sum == 12);
        sum = 0;
        foreach (cur; aa1)
        {
            sum += cur;
        }
        assert(sum == 12);
        assert(aa1.get(3, 42) == 4);
        assert(aa1.get(7, 42) == 42);
        
        auto val = 5 in aa1;
        assert(val && *val == 6);
        return 5;
    }
    
    unittest
    {
        auto runtime1 = test1!false();
        auto runtime1_1 = test1!true();
        enum compiletime1 = test1!false();
        auto runtime2 = test2();
        auto runtime3 = test3();
        auto runtime4 = test4();
        enum compiletime4 = test4();
        auto runtime5 = test5!(Mutability.Mutable, false)();
        auto runtime5_2 = test5!(Mutability.Immutable, false)();
        auto runtime5_3 = test5!(Mutability.Const, false)();
        auto runtime5_4 = test5!(Mutability.Mutable, true)();
        auto runtime5_5 = test5!(Mutability.Immutable, true)();
        auto runtime5_6 = test5!(Mutability.Const, true)();        
        
        enum compiletime5 = test5!(Mutability.Mutable, false)();
        enum compiletime5_2 = test5!(Mutability.Immutable, false)();
        enum compiletime5_3 = test5!(Mutability.Const, false)();
    }
    
    

}
