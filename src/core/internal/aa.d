/**
 * Written in the D programming language.
 * This module provides an back-end implementation of associative array
 *
 * Copyright: Copyright Igor Stepanov 2013-2014.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Igor Stepanov
 * Source: $(DRUNTIMESRC core/internal/_aa.d)
 */
module core.internal.aa;

import core.internal.traits;
import core.exception;
import core.memory;

struct AssociativeArray(Key, Value)
{
    this(Key[] keys,  Value[] values)
    {
        static bool testKey(Entry* pe, in size_t kh, ref Key k)
        {
            auto e = pe;

            while (e)
            {
                if (kh == e.hash && e.isEqualKey(k))
                {
                    return false;
                }
                e = e.next;
            }
            return true;
        }
        assert(keys.length == values.length);
        impl = new Impl();
        auto nodes = keys.length;
        impl.nodes = nodes;
        if (impl.binit.length <= impl.nodes)
            impl.buckets = impl.binit[];
        else
            impl.buckets = newBuckets(findGoodLength(impl.nodes));
        auto len = impl.buckets.length;

        impl.firstbucket = len;
        foreach (i; 0 .. nodes)
        {
            size_t key_hash = hashOf(keys[i]);
            size_t idx = bucket(key_hash, len);
            if (idx <  impl.firstbucket)
                impl.firstbucket = idx;
            assert(testKey(impl.buckets[idx], key_hash, keys[i]), "duplicate key");

            Entry *e;
            if (__ctfe)
            {
                e = new Entry(key_hash, keys[i], values[i], impl.buckets[idx]);
            }
            else
            {
                //Don't call postblits, because keys and values are already postblitted.
                e = new Entry(key_hash, impl.buckets[idx]);
                () @trusted {
                    (cast(ubyte*)&e.key)[0 .. Key.sizeof] = (cast(ubyte*)&keys[i])[0 .. Key.sizeof];
                    (cast(ubyte*)&e.value)[0 .. Value.sizeof] = (cast(ubyte*)&values[i])[0 .. Value.sizeof];
                }();
            }
            impl.buckets[idx] = e;
        }
    }

    @property @safe pure nothrow const
    size_t length()
    out (result)
    {
        size_t len = 0;
        if (impl)
        {
            foreach (const(Entry)* e; impl.buckets)
            {
                while (e)
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
        return impl ? impl.nodes : 0;
    }


    inout(Value)* opIn_r()(auto ref in Key key) inout @trusted
    {
        auto e = getRValue(key);
        return e ? &e.value : null;
    }

    ref inout(Value) opIndex()(auto ref in Key key) inout
    {
        auto v = getRValue(key);
        if (!v)
            onRangeError();
        else
            return v.value;
        assert(0);
    }

    ref Value opIndexAssign()(auto ref Value value, in auto ref Key key)
    {
        if (!impl)
        {
            impl = newImpl();
        }

        auto v = getLValue(key);
        assert(v);
        v.setValue(value);

        return v.value;
    }

    bool remove()(auto ref in Key key)
    {
        if (!impl)
        {
            return false;
        }

        auto key_hash = hashOf(key);

        size_t i = bucket(key_hash, impl.buckets.length);
        Entry* pe = null;
        Entry* e = impl.buckets[i];

        while (e)
        {
            if (key_hash == e.hash && e.isEqualKey(key))
            {
                if (pe)
                {
                    pe.next = e.next;
                }
                else
                {
                    impl.buckets[i] = e.next;
                }
                impl.nodes--;

                // reset cache, we know there are no nodes in the aa.
                if (!impl.nodes)
                    impl.firstbucket = impl.buckets.length;

                if (!__ctfe)
                    GC.free(e);
                return true;
            }
            pe = e;
            e = e.next;
        }

        return false;
    }

    AssociativeArray rehash()
    {
        return _rehash();
    }

    AssociativeArray dup() const
    {
        return _dup();
    }

    Key[] keys() @property
    {
        static if (isCopyConstructable!Key)
        {
            if (!length)
                return null;
            size_t i = 0;
            Key[] elems;
            static if (isTrivialAssignable!Key)
            {
                elems = new Key[impl.nodes];
            }
            else if (!__ctfe)
            {
                elems.reserve(impl.nodes);
            }

            for (size_t j = impl.firstbucket; j < impl.buckets.length; ++j)
            {
                auto e = impl.buckets[j];
                while (e)
                {
                    static if (isTrivialAssignable!Key)
                    {
                        elems[i] = e.key;
                    }
                    else
                    {
                        elems ~= e.key;
                    }
                    e = e.next;
                    i++;
                }
            }
            assert(i == impl.nodes);

            return elems;
        }
        else
        {
            return null;
        }
    }

    const(Key)[] keys() const @property
    {
        return cast(const)(cast()this).keys;
    }

    inout(Key)[] inout_keys() inout @property
    {
        return cast(inout(Key)[])keys;
    }

    Value[] values() @property
    {
        static if (isCopyConstructable!Value)
        {
            if (!length)
                return null;
            size_t i = 0;
            Value[] elems;
            static if (isTrivialAssignable!Value)
            {
                elems = new Value[impl.nodes];
            }
            else if (!__ctfe)
            {
                elems.reserve(impl.nodes);
            }

            for (size_t j = impl.firstbucket; j < impl.buckets.length; ++j)
            {
                auto e = impl.buckets[j];
                while (e)
                {
                    static if (isTrivialAssignable!Value)
                    {
                        elems[i] = e.value;
                    }
                    else
                    {
                        elems ~= e.value;
                    }
                    e = e.next;
                    i++;
                }
            }
            assert(i == impl.nodes);

            return elems;
        }
        else
        {
            return null;
        }
    }

    const(Value)[] values() const @property
    {
        return cast(const)(cast()this).values;
    }

    inout(Value)[] inout_values() inout @property
    {
        return cast(inout(Value)[])values;
    }

    int opApply(scope int delegate(ref Value) dg)
    {
        if (!impl)
        {
            return 0;
        }

        foreach (e; impl.buckets[impl.updateCache() .. $])
        {
            while (e)
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
        if (!impl)
        {
            return 0;
        }

        foreach (e; impl.buckets[impl.updateCache() .. $])
        {
            while (e)
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
        if (!impl)
        {
            return 0;
        }

        foreach (const(Entry)* e; impl.buckets[impl.firstbucket .. $])
        {
            while (e)
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
        if (!impl)
        {
            return 0;
        }

        foreach (const(Entry)* e; impl.buckets[impl.firstbucket .. $])
        {
            while (e)
            {
                auto result = dg(e.key, e.value);
                if (result)
                    return result;
                e = e.next;
            }
        }
        return 0;
    }

    ref AssociativeArray opAssign(typeof(null)) @safe pure nothrow
    {
        impl = null;
        return this;
    }

    inout(Value) get(in Key key, lazy inout(Value) defaultValue) inout
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
        return getConstRange!(KeyValue.Key)();
    }

    auto byValue() @safe pure nothrow const
    {
        return getConstRange!(KeyValue.Value)();
    }

    bool opEquals(this LhsType, RhsType)(RhsType rhs) if (is(RhsType : const(AssociativeArray)))
    {
        alias LeftEntry = Unqual!(typeof(impl.buckets[0]));
        alias RightEntry = Unqual!(typeof(rhs.impl.buckets[0]));
        if (length != rhs.length) return false;
        if (!length) return true;

        foreach (LeftEntry e1; impl.buckets[impl.firstbucket .. $])
        {
            while (e1)
            {
                auto idx = e1.hash % rhs.impl.buckets.length;
                RightEntry e2 = rhs.impl.buckets[idx];
                while (e2)
                {
                    if (e2.hash == e1.hash && e1.isEqualKey(e2.key))
                    {
                        if (!e1.isEqualValue(e2.value))
                            return false;
                        break;
                    }
                    e2 = e2.next;
                }
                if (!e2)
                    return false;
                e1 = e1.next;
            }
        }
        return true;
    }

private:
    static size_t bucket(size_t hash, size_t length)
    {
        return hash & (length - 1);
    }

    // _rehash() frees old bucket array when rehashing has done.
    // Thus AA shouldn't be rehashed while old impl is being used (e.g. inside foreach)
    AssociativeArray _rehash() @system
    {
        AssociativeArray ret;
        if (!impl) return ret;

        if (!impl.buckets.length)
        {
            if (impl.buckets.ptr != impl.binit.ptr && !__ctfe)
            {
                GC.free(impl.buckets.ptr);
                impl.buckets = impl.binit[];
                impl.firstbucket = impl.buckets.length;
            }
            return this;
        }

        auto len = findGoodLength(impl.nodes);

        if (len == impl.buckets.length)
            return this;

        Impl new_impl;
        Impl* old_impl = impl;

        new_impl.buckets = newBuckets(len);
        new_impl.firstbucket = new_impl.buckets.length;

        foreach (e; old_impl.buckets[old_impl.firstbucket .. $])
        {
            while (e)
            {
                auto nexte = e.next;
                const j = e.hash % len;

                if (j <  new_impl.firstbucket)
                    new_impl.firstbucket = j;

                e.next = new_impl.buckets[j];
                new_impl.buckets[j] = e;
                e = nexte;
            }
        }
        new_impl.nodes = old_impl.nodes;

        if (old_impl.buckets.ptr == old_impl.binit.ptr)
            old_impl.binit[] = null;
        else if (!__ctfe)
            GC.free(old_impl.buckets.ptr);
        if (!__ctfe)
        {
            *impl = new_impl;
        }
        else
        {
            impl = new Impl(new_impl);
        }
        return this;
    }


    AssociativeArray _dup() const
    {
        AssociativeArray ret;
        if (!impl)
            return ret;

        ret.impl = new Impl;
        ret.impl.buckets = ret.impl.binit[];


        Impl new_impl;
        const Impl* old_impl = impl;

        auto len = findGoodLength(impl.nodes);

        new_impl.buckets = newBuckets(len);
        new_impl.firstbucket = new_impl.buckets.length;

        foreach (const(Entry)* e; old_impl.buckets[old_impl.firstbucket .. $])
        {
            while (e)
            {
                const j = e.hash % len;
                if (j <  new_impl.firstbucket)
                    new_impl.firstbucket = j;
                auto newe = new Entry(e.hash, e.key,  e.value, new_impl.buckets[j]);
                new_impl.buckets[j] = newe;
                e = e.next;
            }
        }

        new_impl.nodes = old_impl.nodes;

       if (!__ctfe)
       {
           *ret.impl = new_impl;
       }
       else
       {
           ret.impl = new Impl(new_impl);
       }
       return ret;
    }

    static Impl* newImpl() @safe pure
    {
        auto impl = new Impl();
        impl.buckets = impl.binit[];
        impl.firstbucket = impl.buckets.length;
        return impl;
    }

    Entry* getLValue(ref const(Unqual!Key) pkey)
    {
        assert(impl);

        auto key_hash = hashOf(pkey);

        size_t i = bucket(key_hash, impl.buckets.length);
        auto pe = impl.buckets[i];
        auto e = pe;

        while (e)
        {
            if (key_hash == e.hash && e.isEqualKey(pkey))
            {
                return e;
            }
            e = e.next;
        }

        if (i < impl.firstbucket)
            impl.firstbucket = i;
        e = new Entry(key_hash, pkey);
        e.next = pe;
        impl.buckets[i] = e;

        auto nodes = ++impl.nodes;

        if (nodes > impl.buckets.length * RehashOverflow)
        {
            rehash();
        }

        return e;
    }

    inout(Entry)* getRValue(ref const(Unqual!Key) pkey) inout
    {
        if (!impl)
        {
            return null;
        }

        auto key_hash = hashOf(pkey);

        size_t i = bucket(key_hash, impl.buckets.length);
        inout(Entry)* pe = impl.buckets[i];
        inout(Entry)* e = pe;

        while (e)
        {
            if (key_hash == e.hash && e.isEqualKey(pkey))
            {
                return e;
            }
            e = e.next;
        }

        return null;
    }

    static Entry*[] newBuckets(in size_t len) @trusted pure nothrow
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

    static size_t findGoodLength(size_t idx) @safe pure nothrow
    {
        //BUG, Why core.stdc.math.log2 is impure?
        size_t l = 4;
        while (l < idx)
            l *= 2;
        return l;
    }


    enum Mutability
    {
        Mutable,
        Const
    }

    Range!(Mutability.Mutable, kv) getRange(KeyValue kv)() @safe pure nothrow
    {
        Range!(Mutability.Mutable, kv) res;
        res.impl = impl;
        if (!length)
            return res;
        impl.updateCache();
        if (impl.firstbucket < impl.buckets.length)
            res.current = impl.buckets[impl.firstbucket];
        return res;
    }

    Range!(Mutability.Const, kv) getConstRange(KeyValue kv)() @safe pure nothrow const
    {
        Range!(Mutability.Const, kv) res;
        res.impl = impl;
        if (!length)
            return res;
        if (impl.firstbucket < impl.buckets.length)
            res.current = impl.buckets[impl.firstbucket];
        return res;
    }

    size_t toHash() const nothrow @trusted
    {
        if (!length) return 0;
        size_t h = 0;

        try
        {
            // The computed hash is independent of the foreach traversal order.
            // Maybe BUG, delegate 'core.internal.aa.AssociativeArray!(string[const(double)[]], short[immutable(wchar)[]]).AssociativeArray.toHash.__foreachbody1'
            // is nothrow yet may throw

            foreach (ref key, ref val; this)
            {
                try
                {
                    size_t[2] hpair;
                    hpair[0] = key.hashOf();
                    hpair[1] = val.hashOf();
                    h ^= hashOf(hpair[1], hashOf(hpair[0]));
                }
                catch(Exception e)
                {
                    return 0;
                }
            }
        }
        catch(Exception e)
        {
            assert(0);
        }
        return h;
    }

    static struct Range(Mutability mutability, KeyValue ckv = KeyValue.Unknown)
    {
        static if (mutability == Mutability.Mutable)
        {
            Impl* impl;
            Entry* current;
            alias RetKey = Key;
            alias RetValue = Value;
        }
        else
        {
            const(Impl)* impl;
            const(Entry)* current;
            alias RetKey = const(Key);
            alias RetValue = const(Value);
        }

        static Range fromAARange(AARange r) @nogc
        {
            Range ret;
            ret.impl = cast(typeof(ret.impl))r.impl;
            ret.current = cast(typeof(ret.current))r.current;
            return ret;
        }

        AARange toAARange() @nogc
        {
            AARange ret;
            ret.impl = cast(void*)impl;
            ret.current = cast(void*)current;
            return ret;
        }

        @property bool empty() @nogc
        {
            return !impl || !current;
        }

        static if (ckv == KeyValue.Key)
        {
            @property ref RetKey front() @nogc//really ref Key? may be ref const(Key) or Key?
            in
            {
                assert(current);
            }
            body
            {
                return current.key;
            }
        }

        else static if (ckv == KeyValue.Value)
        {
            @property ref RetValue front() @nogc
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
            @property ref RetKey front(KeyValue kv)() @nogc if (kv == KeyValue.Key && ckv == KeyValue.Unknown) //really ref Key? may be ref const(Key) or Key?
            in
            {
                assert(current);
            }
            body
            {
                return current.key;
            }


            @property ref RetValue front(KeyValue kv)() @nogc if (kv == KeyValue.Value && ckv == KeyValue.Unknown)
            in
            {
                assert(current);
            }
            body
            {
                return current.value;
            }
        }

        void popFront() @nogc
        in
        {
            assert(impl);
            assert(current);
        }
        body
        {
            if (current.next)
            {
                current = current.next;
            }
            else
            {
                immutable idx = current.hash % impl.buckets.length;
                current = null;
                foreach (entry; impl.buckets[idx + 1 .. $])
                {
                    if (entry)
                    {
                        current = entry;
                        break;
                    }
                }
            }
        }


        Range save() @nogc
        {
            return this;
        }
    }

    static struct Impl
    {
        immutable(AssociativeArrayHandle)* handle = &getAAHandle!(Key, Value);
        Entry*[] buckets;
        size_t nodes;       // total number of entries
        Entry*[4] binit;    // initial value of buckets[]
        size_t firstbucket;

        this(Impl i)
        {
            buckets = i.buckets;
            nodes = i.nodes;
            binit = i.binit;
            firstbucket = i.firstbucket;
        }

        size_t updateCache() @safe pure nothrow @nogc
        in
        {
            assert(firstbucket < buckets.length);
            foreach(i; 0 .. firstbucket)
                assert(buckets[i] is null);
        }
        body
        {
            size_t i;
            for(i = firstbucket; i < buckets.length; ++i)
                if(buckets[i] !is null)
                    break;
            return firstbucket = i;
        }
    }

    static struct Entry
    {
        Entry* next;
        size_t hash;
        Key key;
        Value value;

        this(size_t hash, Entry* next = null)
        {
            this.hash = hash;
            static if (is(Value == struct) && __traits(isNested, Value))
            {
                this.value = Value.init;
            }

            static if (is(Key == struct) && __traits(isNested, Key))
            {
                this.key = Key.init;
            }

            this.next = next;
        }

        this(K)(size_t hash, ref K key, Entry* next = null)
        {
            this.hash = hash;
            static if (isAssignable!(Key, K))
            {
                this.key = key;
            }
            else
            {
                static if (is(Key == struct) && __traits(isNested, Key))
                {
                    this.key = Key.init;
                }
                _emplace!true(this.key, key);
            }

            static if (is(Value == struct) && __traits(isNested, Value))
            {
                this.value = Value.init;
            }

            this.next = next;
        }

        this(K, V)(size_t hash, ref K key, ref V value, Entry* next = null)
        {
            this.hash = hash;

            static if (isAssignable!(Key, K))
            {
                this.key = key;
            }
            else
            {
                static if (is(Key == struct) && __traits(isNested, Key))
                {
                    this.key = Key.init;
                }
                _emplace!true(this.key, key);
            }

            this.next = next;

            static if (isAssignable!(Value, V))
            {
                this.value = value;
            }
            else
            {
                static if (is(Value == struct) && __traits(isNested, Value))
                {
                    this.value = Value.init;
                }
                _emplace!true(this.value, value);
            }
        }

        @disable this(this);

        void setValue(V)(ref V value)
        {
            static if (isAssignable!(Value, V))
            {
                this.value = value;
            }
            else
            {
                _emplace!false(this.value, value);
            }
        }

        bool isEqualKey(ref const(Unqual!Key) key) const
        {
            return this.key == key;
        }

        bool isEqualValue(this LhsType, RhsType)(ref RhsType value) if (is(RhsType : const(Unqual!Value)))
        {
            return this.value == value;
        }
    }

    Impl* impl = null;

    private enum RehashOverflow = 4;
    /**
        Compiler interface functions:
        Those functions are defined for compatibility with old compiler extern(C) interface.
        `Impl` contains a table of functions (unique for each AssociativeArray template instance),
        and global extern(C) _aaXXX functions accesses to AssociativeArray through this table.
        Some of this functions undeservedly marked with @trusted: for example _aaGetZ calculates key hash,
        and this code can be unsafe. However extern(C) interface doesn't know static AssociativeArray type,
        thus it can't determine own safety, but this function can be called from @safe code.
        This is fundamental trouble of current AA implementation and it's not relevant with this work.

    */
    static size_t _aaLen(in void* aa) @trusted pure nothrow
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.length;
    }

    static size_t _aaGetHash(in void* aa)
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.toHash();
    }

    static void* _aaGetZ(void** aa, in void* pkey) @trusted
    {
        auto _this = *cast(AssociativeArray*)aa;
        auto ret = cast(void*)&_this.getLValue(*cast(Key*)pkey).value;
        *aa = *cast(void**)&_this;
        return ret;
    }

    static inout(void)* _aaGetRvalueX(inout void* aa, in void* pkey) @trusted
    {
        auto _this = *cast(AssociativeArray*)&aa;
        auto e = _this.getRValue(*cast(Key*)pkey);
        return cast(inout(void)*)(e ? &e.value : null);
    }

    static bool _aaDelX(void* aa, in void* pkey) @trusted
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.remove(*cast(Key*)pkey);
    }

    static int _aaApply(void* aa, dg_t dg)
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.opApply(cast(int delegate(ref Value))dg);
    }

    static int _aaApply2(void* aa, dg2_t dg)
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.opApply(cast(int delegate(ref Key, ref Value))dg);
    }

    static int _aaEqual(in void* e1, in void* e2) @trusted
    {
        auto lhs = *cast(AssociativeArray*)&e1;
        auto rhs = *cast(AssociativeArray*)&e2;
        return lhs == rhs;
    }

    static inout(void)[] _aaValues(inout void* aa)
    {
        static if (isCopyConstructable!Value)
        {
            auto _this = *cast(AssociativeArray*)&aa;
            auto val = _this.values;
            return *cast(inout(void)[]*)&val;
        }
        else
        {
            return null;
        }
    }

    static inout(void)[] _aaKeys(inout void* aa)
    {
        static if (isCopyConstructable!Key)
        {
            auto _this = *cast(AssociativeArray*)&aa;
            auto key = _this.keys;
            return *cast(inout(void)[]*)&key;
        }
        else
        {
            return null;
        }
    }

    static void* _aaRehash(void** paa) pure nothrow
    {
        assert(*paa);
        auto pthis = *cast(AssociativeArray**)&paa;
        auto _this = *pthis;
        _this.rehash();
        *pthis = _this;
        return *cast(void**)&_this;
    }

    static void* _aaDup(void* aa)
    {
       auto _this = *cast(AssociativeArray*)&aa;
       auto copy = _this.dup();
       return *cast(void**)&copy;
    }

    static AARange _aaRange(void* aa) pure nothrow @nogc
    {
        auto _this = *cast(AssociativeArray*)&aa;
        return _this.getRange!(KeyValue.Unknown)().toAARange();
    }

    static bool _aaRangeEmpty(AARange r) pure nothrow @nogc
    {
        return Range!(Mutability.Mutable).fromAARange(r).empty;
    }

    static void* _aaRangeFrontKey(AARange r) pure nothrow @nogc
    {
        auto _range = Range!(Mutability.Mutable).fromAARange(r);
        return cast(void*)&_range.front!(KeyValue.Key)();
    }

    static void* _aaRangeFrontValue(AARange r) pure nothrow @nogc
    {
        auto _range = Range!(Mutability.Mutable).fromAARange(r);
        return cast(void*)&_range.front!(KeyValue.Value)();
    }

    static void _aaRangePopFront(ref AARange r) pure nothrow @nogc
    {
        auto _range = Range!(Mutability.Mutable).fromAARange(r);
        _range.popFront();
        r = _range.toAARange();
    }
}

/***************************************************************
                    compiler interface
***************************************************************/

auto aaLiteral(Key, Value)(Key[] keys, Value[] values)
{
    // AA backend doesn't support shared or inout keys or values.
    // Correctness is ensured by compiler.
    alias UnShKey = UnSharedInout!Key;
    alias UnShValue = UnSharedInout!Value;

    UnShKey[] key_slice;
    UnShValue[] value_slice;
    () @trusted {
        key_slice = *cast(UnShKey[]*)&keys;
        value_slice = *cast(UnShValue[]*)&values;
    }();
    assert(key_slice.length == value_slice.length);
    auto aa = AssociativeArray!(UnShKey, UnShValue)(key_slice, value_slice);
    return aa.impl;
}

extern (D) alias int delegate(void *) dg_t;
extern (D) alias int delegate(void *, void *) dg2_t;
extern (D) alias AssociativeArrayHandle** function(void[],  void[]) init_t;

//!Note: this functions are extern(D) now and doesn't conflict with rt.aaA _aaXXX functions
extern(D)
{
    size_t _aaLen(in AssociativeArrayHandle** aa) @trusted pure nothrow
    {
        if (!aa)
            return 0;
        auto handle = *aa;
        return handle.len(aa);
    }

    size_t _aaGetHash(in AssociativeArrayHandle** aa)
    {
        if (!aa)
            return 0;
        auto handle = *aa;
        return handle.getHash(aa);
    }

    void* _aaGetZ(AssociativeArrayHandle*** aa, const TypeInfo ti, in size_t, in void* pkey, init_t init) @trusted
    in
    {
        assert(aa);
    }
    body
    {
        if (!*aa)
        {
            *aa = init([], []);
        }
        auto handle = **aa;
        return handle.getZ(cast(void**)aa, pkey);
    }

    inout(void)* _aaGetRvalueX(inout AssociativeArrayHandle** aa, const TypeInfo, in size_t, in void* pkey) @trusted
    {
        if (!aa)
            return null;
        auto handle = *aa;
        return handle.getRvalueX(aa, pkey);
    }

    inout(void)* _aaInX(inout AssociativeArrayHandle** aa, in TypeInfo unused_1, in void* pkey) @trusted
    in
    {
        assert(aa);
    }
    body
    {
        return _aaGetRvalueX(aa, unused_1, 0, pkey);
    }

    bool _aaDelX(AssociativeArrayHandle** aa, in TypeInfo, in void* pkey) @trusted
    {
        if (!aa)
            return false;
        auto handle = *aa;
        return handle.delX(aa, pkey);
    }

    int _aaApply(AssociativeArrayHandle** aa, in size_t keysize, dg_t dg)
    {
        if (!aa)
            return 0;
        auto handle = *aa;
        return handle.apply(aa, dg);
    }

    int _aaApply2(AssociativeArrayHandle** aa, in size_t keysize, dg2_t dg)
    {
        if (!aa)
            return 0;
        auto handle = *aa;
        return handle.apply2(aa, dg);
    }

    int _aaEqual(in TypeInfo, in AssociativeArrayHandle** e1, AssociativeArrayHandle** e2) @trusted
    in
    {
        if (e1 && e2)
        {
            auto handle1 = *e1;
            auto handle2 = *e2;
            assert(handle1 == handle2); //ensure that both objects has a same type
        }

    }
    body
    {
        if (!e1 && !e2)
        {
            return true;
        }

        if (e1 && e2)
        {
            auto handle = *e1;
            return handle.equal(e1, e2);
        }
        return false;
    }


    inout(void)[] _aaValues(inout AssociativeArrayHandle** aa, in size_t keysize, in size_t valuesize)
    {
        if (!aa)
            return [];
        auto handle = *aa;
        return handle.values(aa);
    }

    inout(void)[] _aaKeys(inout AssociativeArrayHandle** aa, in size_t keysize)
    {
        if (!aa)
            return [];
        auto handle = *aa;
        return handle.keys(aa);
    }

    void* _aaRehash(AssociativeArrayHandle*** paa, in TypeInfo keyti) pure nothrow
    in
    {
        assert(paa);
    }
    body
    {
        auto aa = *paa;
        if (!aa)
            return null;

        auto handle = *aa;
        return handle.rehash(cast(void**)paa);
    }

    void* _aaDup(AssociativeArrayHandle** aa, in TypeInfo keyti)
    {
        if (!aa)
            return null;
        auto handle = *aa;
        return handle.dup(aa);
    }


    struct AARange
    {
        void* impl;
        void* current;
    }

    AARange _aaRange(AssociativeArrayHandle** aa) pure nothrow @nogc
    {
        if (!aa)
        {
            return AARange(null, null);
        }
        auto handle = *aa;
        return handle.range(aa);
    }

    bool _aaRangeEmpty(AARange r) pure nothrow @nogc
    {
        auto aa = r.impl;
        if (!aa)
        {
            return true;
        }
        auto handle = *cast(AssociativeArrayHandle**)aa;
        return handle.rangeEmpty(r);
    }

    void* _aaRangeFrontKey(AARange r) pure nothrow @nogc
    in
    {
        assert(r.impl && r.current);
    }
    body
    {
        auto aa = r.impl;
        auto handle = *cast(AssociativeArrayHandle**)aa;
        return handle.rangeFrontKey(r);
    }

    void* _aaRangeFrontValue(AARange r) pure nothrow @nogc
    in
    {
        assert(r.impl && r.current);
    }
    body
    {
        auto aa = r.impl;
        auto handle = *cast(AssociativeArrayHandle**)aa;
        return handle.rangeFrontValue(r);
    }

    void _aaRangePopFront(ref AARange r) pure nothrow @nogc
    {
        if (!r.impl)
            return;
        auto aa = r.impl;
        auto handle = *cast(AssociativeArrayHandle**)aa;
        return handle.rangePopFront(r);
    }
}

version(unittest)
{

    int test1(bool isstatic)()
    {
        static if (isstatic)
            static aa1 = AssociativeArray!(real, real)([1, 3.9L, 5UL], [2.0L, 4UL, 6]);
        else
            auto aa1 = AssociativeArray!(real, real)([1, 3.9L, 5UL], [2.0L, 4UL, 6]);

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

    int test2()
    {
        auto aa1 = AssociativeArray !(int, int)([1, 3, 5],  [2, 4, 6]);

        //test length
        assert(_aaLen(*cast(AssociativeArrayHandle***)&aa1));
        int newkey = 7;

        //create a new elem
        auto pval = _aaGetZ(cast(AssociativeArrayHandle***)&aa1, null, 0, &newkey, cast(init_t)&aaLiteral!(int, int));
        *cast(int*)pval = 8;
        assert(aa1[7] == 8);
        newkey = 1;

        //find the existing elem
        pval = _aaGetZ(cast(AssociativeArrayHandle***)&aa1, null, 0, &newkey, cast(init_t)&aaLiteral!(int, int));
        *cast(int*)pval = 1;
        assert(aa1[1] == 1);

        AssociativeArray!(int, int) aa2;
        auto impl1 = aa2.impl;
        newkey = 1;

        //create a new elem in aa with null impl
        pval = _aaGetZ(cast(AssociativeArrayHandle***)&aa2, null, 0, &newkey, cast(init_t)&aaLiteral!(int, int));
        *cast(int*)pval = 1;
        auto impl2 = aa2.impl;
        assert(impl2 != impl1);
        assert(aa2[1] == 1);

        //find the existing elem
        int key = 3;
        auto rval1 = _aaGetRvalueX(*cast(AssociativeArrayHandle***)&aa1, null, 0, &key);
        auto rval2 = _aaInX(*cast(AssociativeArrayHandle***)&aa1, null, &key);
        assert(rval1 == rval2 && *cast(int*)rval1 == 4);

        //find non-existing elem
        key = 4;
        rval1 = _aaGetRvalueX(*cast(AssociativeArrayHandle***)&aa1, null, 0, &key);
        rval2 = _aaInX(*cast(AssociativeArrayHandle***)&aa1, null, &key);
        assert(!rval1 && !rval2);

        //delete non-existing elem
        auto rem = _aaDelX(*cast(AssociativeArrayHandle***)&aa1, null, &key);
        assert(!rem);

        //delete the existing elem
        key = 3;
        rem = _aaDelX(*cast(AssociativeArrayHandle***)&aa1, null, &key);
        assert(rem);
        assert(_aaLen(*cast(AssociativeArrayHandle***)&aa1) == 3);

        //test _aaApply and _aaApply2
        int sum = 0;
        int dg1(void* v)
        {
            sum += *cast(int*)v;
            return 0;
        }
        _aaApply(*cast(AssociativeArrayHandle***)&aa1, 0, &dg1);
        assert(sum == 15);

        sum = 0;
        int dg2(void* k, void* v)
        {
            sum += *cast(int*)k;
            sum += *cast(int*)v;
            return 0;
        }
        _aaApply2(*cast(AssociativeArrayHandle***)&aa1, 0, &dg2);
        assert(sum == 28);

        //test _aaEqual
        auto aa3 = aa1.dup;
        assert(_aaEqual(null, *cast(AssociativeArrayHandle***)&aa1, *cast(AssociativeArrayHandle***)&aa3));

        int k1 = 1, k2 = 3, v1 = 2, v2 = 4;
        auto aalit = aaLiteral!(int, int)([k1, k2], [v1, v2]);
        return 0;
    }

    int test3()
    {
        AssociativeArray!(int, int) aa1;
        auto impl1 = aa1.impl;

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

        AssociativeArray!(int, int) aa4;
        assert(aa4.impl is impl1);

        aa1 = aa2;
        assert(aa1.impl == aa2.impl);

        aa1 = null;
        assert(aa1.impl == impl1);

        return 0;
    }

    int test4(bool isstatic)()
    {
        static if (isstatic)
            static aa1 = AssociativeArray!(int, int)([1, 3, 5],  [2, 4, 6]);
        else
            auto aa1 = AssociativeArray!(int, int)([1, 3, 5],  [2, 4, 6]);
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
        return 0;
    }

    int test5()
    {
        // If this struct if declared as non-template we will get a undefined reference to Test5
        // if program is compiled with unittest and this module is not root module. dmd BUG?
        // If this module is root, all works correctly.
        static struct Test5()
        {
            this(int a)
            {
                this.a = a;
            }

            size_t toHash() const @safe nothrow pure
            {
                return hashOf(a);
            }

            bool opEquals(const Test5 rhs) const @safe nothrow pure
            {
                return a == rhs.a;
            }

            int a;
            AssociativeArray!(Test5, string) aarr1;
            AssociativeArray!(string, Test5) aarr2;
        }
        Test5!() f;
        f.aarr1[Test5!()(1)] = "yyy";
        f.aarr2["xxx"] = Test5!()(2);
        assert(f.aarr1[Test5!()(1)] == "yyy");
        assert(f.aarr2["xxx"] == Test5!()(2));

        return 0;
    }

    unittest
    {
        auto runtime1 = test1!false();
        auto runtime1_1 = test1!true();
        enum compiletime1 = test1!false();
        auto runtime2 = test2();
        auto runtime3 = test3();
        enum compiletime3 = test3();
        auto runtime4 = test4!(false)();
        auto runtime4_1 = test4!(true)();
        enum compiletime4 = test4!(false)();
        auto runtime5 = test5();
    }
}

private void _emplace(bool new_obj, V1, V2)(ref V1 dst, ref V2 src) @trusted if (is(V1 == struct))
{
    static if (new_obj)
    {
        V1 tmp = cast(V1)src; //create copy and call postblit
        V1 init = V1.init;
        (cast(void*)&dst)[0 .. V1.sizeof] = (cast(void*)&tmp)[0 .. V1.sizeof]; //bitwise copy of object, which already postblitted
        (cast(void*)&tmp)[0 .. V1.sizeof] = (cast(void*)&init)[0 .. V1.sizeof];
    }
    else
    {
        V1 tmp = src; //create copy and call postblit
        V1 tmp2 = void;
        V1 init = V1.init;
        (cast(void*)&tmp2)[0 .. V1.sizeof] = (cast(void*)dst)[0 .. V1.sizeof];
        (cast(void*)&dst)[0 .. V1.sizeof] = (cast(void*)&tmp)[0 .. V1.sizeof];
        (cast(void*)&tmp)[0 .. V1.sizeof] = (cast(void*)&init)[0 .. V1.sizeof];
        //Now tmp2 contains the old dst value (and it will be destructed)
        //dst contains src value, which corrctly postblitted
        //tmp contains init and it desctuctor shouldn't do any non-trivial actions
    }
}

private void _emplace(bool new_obj, V1, V2)(ref V1 dst, ref V2 src) @trusted if (__traits(isStaticArray, V1))
{
    static assert(V1.sizeof == V2.sizeof);

    foreach(i; 0 .. dst.length)
    {
        _emplace!(new_obj)(dst[i], src[i]);
    }
}

private void _emplace(bool new_obj, V1, V2)(ref V1 dst, ref V2 src) @trusted if (!__traits(isStaticArray, V1) && !is(V1 == struct))
{
    static assert(V1.sizeof == V2.sizeof);
    *(cast(Unqual!V1*)&dst) = *(cast(Unqual!V1*)&src);
}

private template isCopyConstructable(T)
{
    static if (is(typeof({
        T v;
        T v2 = v;
    })))
    {
        enum isCopyConstructable = true;
    }
    else
    {
        enum isCopyConstructable = false;
    }
}

private enum isAssignable(V1, V2) = __traits(compiles, {V1 val = V1.init; V2 val2 = V2.init; val = val2;});

private template isTrivialAssignable(V)
{
    static if (!isAssignable!(V, V))
    {
        enum isTrivialAssignable = false;
    }
    else static if ((is(V == struct) || is(V == union)) && !__traits(isPOD, V))
    {
        enum isTrivialAssignable = false;
    }
    else
    {
        enum isTrivialAssignable = true;
    }
}

private template UnSharedInout(T)
{
    static if(is(T: typeof(null)))
    {
        alias UnSharedInout = UnSharedInout2!(T);
    }
    else static if(__traits(isStaticArray, T))
    {
        alias UnSharedInout = UnSharedInout!(typeof(T.init[0]))[T.length];
    }
    else static if(is(UnSharedInout2!T U : U*))
    {
        alias UnSharedInout = UnSharedInout!(U)*;
    }
    else static if(is(UnSharedInout2!T U : U[]))
    {
        alias UnSharedInout = UnSharedInout!(U)[];
    }
    else static if(__traits(isAssociativeArray, T))
    {
        alias UnSharedInout = UnSharedInout!(typeof(T.init.values[0]))[UnSharedInout!(typeof(T.init.keys[0]))];
    }
    else
    {
        alias UnSharedInout = UnSharedInout2!(T);
    }
}

private template UnSharedInout2(T)
{
         static if (is(T U ==         inout U )) alias UnSharedInout2 = const(U);
    else static if (is(T U ==         const U )) alias UnSharedInout2 = const(U);
    else static if (is(T U ==        shared U )) alias UnSharedInout2 = U;
    else static if (is(T U ==      immutable U)) alias UnSharedInout2 = immutable(U);

    else static if (is(T U ==         inout(const U))) alias UnSharedInout2 = const(U);
    else static if (is(T U ==     inout(immutable U))) alias UnSharedInout2 = immutable(U);
    else static if (is(T U ==        inout(shared U))) alias UnSharedInout2 = const(U);

    else static if (is(T U ==        shared(const U))) alias UnSharedInout2 = const(U);

    else static if (is(T U == inout(shared(const U)))) alias UnSharedInout2 = const(U);

    else                                        alias UnSharedInout2 = T;
}

private enum KeyValue
{
    Key = 0,
    Value = 1,
    Unknown = 2
}

private template getAAHandle(Key, Value)
{
    __gshared immutable AssociativeArrayHandle getAAHandle = AssociativeArrayHandle(&AssociativeArray!(Key, Value)._aaLen,
                                   &AssociativeArray!(Key, Value)._aaGetZ,
                                   &AssociativeArray!(Key, Value)._aaGetRvalueX,
                                   &AssociativeArray!(Key, Value)._aaDelX,
                                   &AssociativeArray!(Key, Value)._aaApply,
                                   &AssociativeArray!(Key, Value)._aaApply2,
                                   &AssociativeArray!(Key, Value)._aaEqual,
                                   &AssociativeArray!(Key, Value)._aaValues,
                                   &AssociativeArray!(Key, Value)._aaKeys,
                                   &AssociativeArray!(Key, Value)._aaRehash,
                                   &AssociativeArray!(Key, Value)._aaDup,
                                   &AssociativeArray!(Key, Value)._aaRange,
                                   &AssociativeArray!(Key, Value)._aaRangeEmpty,
                                   &AssociativeArray!(Key, Value)._aaRangeFrontKey,
                                   &AssociativeArray!(Key, Value)._aaRangeFrontValue,
                                   &AssociativeArray!(Key, Value)._aaRangePopFront,
                                   &AssociativeArray!(Key, Value)._aaGetHash);
}

private struct AssociativeArrayHandle
{
    @trusted pure nothrow size_t function(in void* aa) len;
    @trusted               void* function(void** aa, in void* pkey) getZ;
    @trusted        inout(void)* function(inout void* aa, in void* pkey) getRvalueX;
    @trusted                bool function(void* aa, in void* pkey) delX;
                             int function(void* aa, dg_t dg) apply;
                             int function(void* aa, dg2_t dg) apply2;
    @trusted                 int function(in void* e1, in void* e2) equal;

    inout(void)[] function(inout void* p) values;
    inout(void)[] function(inout void* p) keys;
    pure nothrow void* function(void** pp) rehash;
    void* function(void* pp) dup;
    @nogc pure nothrow AARange function(void* aa)  range;
    @nogc pure nothrow bool function(AARange r) rangeEmpty;
    @nogc pure nothrow void* function(AARange r) rangeFrontKey;
    @nogc pure nothrow void* function(AARange r) rangeFrontValue;
    @nogc pure nothrow void function(ref AARange r) rangePopFront;
    size_t function(in void* aa) getHash;
}
