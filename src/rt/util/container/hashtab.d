/**
 * HashTab container for internal usage.
 *
 * Copyright: Copyright Martin Nowak 2013.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Martin Nowak
 */
module rt.util.container.hashtab;

import rt.util.container.array;
static import common = rt.util.container.common;

struct HashTab(Key, Value)
{
    static struct Node
    {
        Key _key;
        Value _value;
        Node* _next;
    }

    @disable this(this);

    ~this()
    {
        reset();
    }

    void reset()
    {
        foreach (p; _buckets)
        {
            while (p !is null)
            {
                auto pn = p._next;
                common.destroy(*p);
                common.free(p);
                p = pn;
            }
        }
        _buckets.reset();
        _length = 0;
    }

    @property size_t length() const
    {
        return _length;
    }

    @property bool empty() const
    {
        return !_length;
    }

    void remove(in Key key)
    in { assert(key in this); }
    body
    {
        ensureNotInOpApply();

        immutable hash = hashOf(key) & mask;
        auto pp = &_buckets[hash];
        while (*pp)
        {
            auto p = *pp;
            if (p._key == key)
            {
                *pp = p._next;
                common.destroy(*p);
                common.free(p);
                if (--_length < _buckets.length && _length >= 4)
                    shrink();
                return;
            }
            else
            {
                pp = &p._next;
            }
        }
        assert(0);
    }

    ref inout(Value) opIndex(Key key) inout
    {
        return *opIn_r(key);
    }

    void opIndexAssign(Value value, Key key)
    {
        *get(key) = value;
    }

    inout(Value)* opIn_r(in Key key) inout
    {
        if (_buckets.length)
        {
            immutable hash = hashOf(key) & mask;
            for (inout(Node)* p = _buckets[hash]; p !is null; p = p._next)
            {
                if (p._key == key)
                    return &p._value;
            }
        }
        return null;
    }

    int opApply(scope int delegate(ref Key, ref Value) dg)
    {
        immutable save = _inOpApply;
        _inOpApply = true;
        scope (exit) _inOpApply = save;
        foreach (p; _buckets)
        {
            while (p !is null)
            {
                if (auto res = dg(p._key, p._value))
                    return res;
                p = p._next;
            }
        }
        return 0;
    }

private:

    Value* get(Key key)
    {
        if (auto p = opIn_r(key))
            return p;

        ensureNotInOpApply();

        if (!_buckets.length)
            _buckets.length = 4;

        immutable hash = hashOf(key) & mask;
        auto p = cast(Node*)common.xmalloc(Node.sizeof);
        common.initialize(*p);
        p._key = key;
        p._next = _buckets[hash];
        _buckets[hash] = p;
        if (++_length >= 2 * _buckets.length)
            grow();
        return &p._value;
    }

    static hash_t hashOf(in ref Key key) @trusted
    {
        import rt.util.hash : hashOf;
        static if (is(Key U : U[]))
            return hashOf(key, 0);
        else
            return hashOf((&key)[0 .. 1], 0);
    }

    @property hash_t mask() const
    {
        return _buckets.length - 1;
    }

    void grow()
    in
    {
        assert(_buckets.length);
    }
    body
    {
        immutable ocnt = _buckets.length;
        immutable nmask = 2 * ocnt - 1;
        _buckets.length = 2 * ocnt;
        for (size_t i = 0; i < ocnt; ++i)
        {
            auto pp = &_buckets[i];
            while (*pp)
            {
                auto p = *pp;

                immutable nidx = hashOf(p._key) & nmask;
                if (nidx != i)
                {
                    *pp = p._next;
                    p._next = _buckets[nidx];
                    _buckets[nidx] = p;
                }
                else
                {
                    pp = &p._next;
                }
            }
        }
    }

    void shrink()
    in
    {
        assert(_buckets.length >= 2);
    }
    body
    {
        immutable ocnt = _buckets.length;
        immutable ncnt = ocnt >> 1;
        immutable nmask = ncnt - 1;

        for (size_t i = ncnt; i < ocnt; ++i)
        {
            if (auto tail = _buckets[i])
            {
                immutable nidx = i & nmask;
                auto pp = &_buckets[nidx];
                while (*pp)
                    pp = &(*pp)._next;
                *pp = tail;
                _buckets[i] = null;
            }
        }
        _buckets.length = ncnt;
    }

    void ensureNotInOpApply()
    {
        if (_inOpApply)
            assert(0, "Invalid HashTab manipulation during opApply iteration.");
    }

    Array!(Node*) _buckets;
    size_t _length;
    bool _inOpApply;
}

unittest
{
    HashTab!(int, int) tab;

    foreach(i; 0 .. 100)
        tab[i] = 100 - i;

    foreach(i; 0 .. 100)
        assert(tab[i] == 100 - i);

    foreach (k, v; tab)
        assert(v == 100 - k);

    foreach(i; 0 .. 50)
        tab.remove(2 * i);

    assert(tab.length == 50);

    foreach(i; 0 .. 50)
        assert(tab[2 * i + 1] == 100 - 2 * i - 1);

    assert(tab.length == 50);

    tab.reset();
    assert(tab.empty);
    tab[0] = 0;
    assert(!tab.empty);
    destroy(tab);
    assert(tab.empty);

    // not copyable
    static assert(!__traits(compiles, { HashTab!(int, int) tab2 = tab; }));
    HashTab!(int, int) tab2;
    static assert(!__traits(compiles, tab = tab2));
    static void foo(HashTab!(int, int) copy) {}
    static assert(!__traits(compiles, foo(tab)));
}

unittest
{
    HashTab!(string, size_t) tab;

    tab["foo"] = 0;
    assert(tab["foo"] == 0);
    ++tab["foo"];
    assert(tab["foo"] == 1);
    tab["foo"]++;
    assert(tab["foo"] == 2);

    auto s = "fo";
    s ~= "o";
    assert(tab[s] == 2);
    assert(tab.length == 1);
    tab[s] -= 2;
    assert(tab[s] == 0);
    tab["foo"] = 12;
    assert(tab[s] == 12);

    tab.remove("foo");
    assert(tab.empty);
}

unittest
{
    alias RC = common.RC;
    HashTab!(size_t, RC) tab;

    size_t cnt;
    assert(cnt == 0);
    tab[0] = RC(&cnt);
    assert(cnt == 1);
    tab[1] = tab[0];
    assert(cnt == 2);
    tab.remove(0);
    assert(cnt == 1);
    tab.remove(1);
    assert(cnt == 0);
}

unittest
{
    import core.exception;

    HashTab!(uint, uint) tab;
    foreach (i; 0 .. 5)
        tab[i] = i;
    bool thrown;
    foreach (k, v; tab)
    {
        try
        {
            if (k == 3) tab.remove(k);
        }
        catch (AssertError e)
        {
            thrown = true;
        }
    }
    assert(thrown);
    assert(tab[3] == 3);
}

/// An open-addressing hash table with quadratic probing
/// roughly follows the description of Google's dense_hash_map.
/// WARNING: supports only POD types and no removal by key for now.
struct FlatHashTab(K, V, alias nullValue, alias hashFunc=hashOf)
{
nothrow:
    this(size_t capacity)
    {
        import core.bitop : bsr;
        if(!capacity)
            capacity = 32;
        else
            capacity = 1<<bsr(capacity);
        table.length = capacity;
    }

    @disable this(this);

    ~this()
    {
        if(table.length) common.free(table.ptr);
    }

    void reset()
    {
        table[] = Entry.init;
        items = 0;
    }

    @property size_t length() const
    {
        return items;
    }

    @property bool empty() const
    {
        return items == 0;
    }

    void opIndexAssign(V value, K key)
    in
    {
        assert(value != nullValue);
    }
    body
    {
        if(items * 2 == table.length) rehash();
        size_t h = hashFunc(key);
        size_t mask = (table.length-1);
        size_t i = h & mask;
        if (table[i].value == nullValue)
        {
            table[i] = Entry(key, value);
            items++;
            return;
        }
        if (table[i].key == key)
        {
            table[i].value = value;
            return;
        }
        for (size_t n = 1; ; n++)
        {
            size_t j = (i + triangular(n)) & mask;
            if (table[j].value == nullValue)
            {
                table[j] = Entry(key, value);
                items++;
                return;
            }
            if (table[j].key == key)
            {
                table[j].value = value;
                return;
            }
        }
    }

    inout(V) opIndex(K key) inout
    in
    {
        assert((table.length & (table.length-1)) == 0);
    }
    body
    {
        size_t h = hashFunc(key);
        size_t mask = table.length - 1;
        size_t i = h & mask;
        return table[i].key == key ? table[i].value :
            (table[i].value == nullValue ? nullValue : slowLookup(key, i));

    }

    inout(V) slowLookup(K key, size_t i) inout
    {
        size_t mask = table.length - 1;
        for (size_t n = 1; ; n++)
        {
            size_t j = (i + triangular(n)) & mask;
            if (table[j].value == nullValue) return nullValue;
            if (table[j].key == key) return table[j].value;
        }
    }

    int opApply(scope int delegate(ref K, ref V) nothrow dg)
    {
        foreach (e; table)
        {
            if (e.value != nullValue)
            {
                if(auto res = dg(e.key, e.value))
                    return res;
            }
        }
        return 0;
    }

private:
    struct Entry
    {
        K key;
        V value = nullValue;
    }

    Entry[] table;
    size_t items;

    static size_t triangular(size_t n){ return n * (n + 1) / 2; }

    void rehash()
    {
        import core.stdc.stdio;
        Entry[] old = table;
        size_t newSize = items == 0 ? 32 : table.length * 2;
        table = (cast(Entry*)common.xmalloc(Entry.sizeof * newSize))[0..newSize];
        table[] = Entry.init;
        items = 0;
        foreach(e; old)
        {
            if(e.value != nullValue) this[e.key] = e.value;
        }
        if(old.length) common.free(old.ptr);
    }
}

unittest
{
    import core.stdc.stdio;
    FlatHashTab!(ushort, ushort, ushort.max, x => x) htab;
    // Make collisions
    htab[1] = 1;
    htab[33] = 2;
    htab[65] = 3;
    htab[97] = 4;
    int[1024] array;
    foreach(k,v; htab) {
        array[k] = v;
    }
    assert(array[1] == 1);
    assert(array[33] == 2);
    assert(array[65] == 3);
    assert(array[97] == 4);
    assert(htab[1] == 1);
    assert(htab[33] == 2);
    assert(htab[65] == 3);
    assert(htab[97] == 4);

    // Trigger rehash
    for(ushort x = 3; x<ushort.max-31; x+=31)
    {
        htab[x] = cast(ushort)(x + 1);
        assert(htab[x] == x + 1);
    }

    for(ushort x = 3; x<ushort.max-31; x+=31)
    {
        assert(htab[x] == x + 1);
    }
}
