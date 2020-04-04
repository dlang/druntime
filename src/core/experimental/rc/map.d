// Written in the D programming language.
/**
This module provides `rcmap`, a hash map/associative array type using reference
counting for automatic memory management not reliant on the GC.

License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: Les De Ridder

Source: $(DRUNTIMESRC core/experimental/map.d)
*/
module core.experimental.rc.map;

import core.experimental.rc.slice;
import core.experimental.rc.array;
import core.experimental.rc.slist;

import core.internal.hash : hashOf;

///
pure nothrow @safe unittest
{
    import core.experimental.rc.map;

    auto m = rcmap!(char, int)(['a': 1, 'b': 2, 'c': 4]);
    assert(m.length == 3);
    assert(m['a'] == 1);
    assert('a' in m);

    m['a'] = 0;
    assert(m['a'] == 0);

    m.remove('a');
    assert('a' !in m);

    auto defaultValue = 8;
    assert(m.get('a', defaultValue) == 8);
    m['a'] = 16;
    assert(m.get('a', defaultValue) == 16);
}

/**
Creates an empty `rcmap`.

Params:
    bucketCount = initial bucket count (optional)

Returns:
     an empty `rcmap`
*/
auto make(Map : rcmap!(K, V), K, V)(size_t bucketCount = Map.defaultBucketCount)
in ((bucketCount & (bucketCount - 1)) == 0, "bucket count must be a power of two")
{
    return Map(bucketCount);
}

///
@safe @nogc unittest
{
    auto m = make!(rcmap!(int, int));
    assert(m.buckets.length == typeof(m).defaultBucketCount);
}

/**
Creates a `rcmap` out of an associative array.

Params:
    aa = an associative array

Returns:
    an `rcmap` containing the elements of the associative array
*/
auto make(Map : rcmap!(K, V), K, V)(K[V] aa)
{
    return Map(aa);
}

///
@safe unittest
{
    auto aa = [0: 1, 1: 2, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7];
    auto m = make!(rcmap!(int, int))(aa);
    assert(m[0] == 1);
    assert(m[7] == 7);
}

/**
Hash map type with deterministic control of memory, through reference counting,
that mimics the behaviour of built-in associative arrays. Memory is
automatically reclaimed when the last reference to the array is destroyed; there
is no reliance on the garbage collector.

Implementation:
    `rcmap` uses separate chaining with `rcslist` buckets stored in an
    `rcarray`.

Note:
    `rcmap` does not currently provide a range interface.
*/
struct rcmap(K, V)
{
    enum defaultBucketCount = 8;

    enum float loadFactor = 6.93145751953125E-1; //log(2)

    private static struct KVPair
    {
        import core.internal.traits : Unqual;

        Unqual!K key;
        Unqual!V value;

        this(K key, V value)
        {
            this.key = key;
            this.value = value;
        }

        bool opEquals()(auto ref K key)
        {
            return this.key == key;
        }
    }

    //TODO: Use an unrolled linked list?
    private alias Bucket = rcslist!KVPair;

    private rcarray!Bucket buckets;
    private __rcslice!size_t valueCount;

    /**
    Creates an empty map with the specified initial bucket count.

    Params:
        bucketCount = the initial bucket count, must be a power of two
    */
    this(size_t bucketCount)
    in ((bucketCount & (bucketCount - 1)) == 0, "bucket count must be a power of two")
    {
        initialize(bucketCount);
    }

    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)(4);
        assert(m.empty);
        assert(m.buckets.length == 4);
    }

    /**
    Creates an empty map out of an associative array.

    Params:
        aa = an associative array
    */
    this(U)(U aa)
    if (is(U == VFrom[KFrom], VFrom : V, KFrom : K))
    {
        import core.bitop : bsr;
        auto bucketCount = 1 << (bsr(cast(int)(aa.length / loadFactor)) + 1);
        initialize(bucketCount);

        foreach (e; aa.byKeyValue)
        {
            insertNew!false(e.key, e.value);
        }
        () @trusted { (*valueCount.ptr) += aa.length; }();

        assert(!shouldRehash);
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 1, 2: 2]);
        assert(m.length == 2);
        assert(m[0] == 1);
    }

    private void initialize(size_t bucketCount = defaultBucketCount)
    {
        assert(buckets.length == 0);
        assert(bucketCount % 2 == 0);

        valueCount = typeof(valueCount)(1);

        buckets = typeof(buckets)(bucketCount);
        buckets.length = bucketCount;
    }

    /**
    Returns the number of values in the map.

    Returns:
        the number of values in the map

    Complexity: $(BIGOH 1).
    */
    @trusted
    size_t length()
    {
        return valueCount == null ? 0 : *valueCount.ptr;
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)();
        assert(m.length == 0);
        m[0] = 0;
        assert(m.length == 1);
        m.remove(0);
        assert(m.length == 0);
    }

    /**
    Return true if the map is empty.

    Returns:
        true if the map is empty

    Complexity: $(BIGOH 1).
    */
    bool empty()
    {
        return length == 0;
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)();
        assert(m.empty);
    }

    /**
    Provide access to the element with key `key` in the map.

    Params:
        key = a valid key

    Returns:
        a reference to the value found with key `key`

    Complexity:
        $(BIGOH n), where n is the number of elements in the
        corresponding bucket.
    */
    ref V opIndex(K key)
    {
        return getPairByKey(key).value;
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 0, 1: 2]);
        assert(m[1] == 2);
    }

    /**
    Gets the value associated with the given key, or `defaultValue` if the key
    is not present.

    Params:
        key = the key
        defaultValue = the default value

    Returns:
        the value associated with `key`, or `defaultValue` if `key` is not in
        the map

    Complexity:
        $(BIGOH n), where n is the number of elements in the
        corresponding bucket.
    */
    V get(K key, V defaultValue)
    {
        auto pair = getPairByKey(key);
        if (pair !is null)
        {
            return pair.value;
        }
        else
        {
            return defaultValue;
        }
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 0, 1: 2]);
        assert(m.get(1, 5) == 2);
        assert(m.get(2, 5) == 5);
    }

    @trusted
    private KVPair* getPairByKey(K key)
    {
        if (buckets.length == 0) return null;

        auto hash = hashOf(key);
        auto index = getBucketIndex(hash);

        return buckets[index].find(key);
    }

    /**
    Assign `value` to the element corresponding to `key`.

    Params:
         value = the value to be set
         key = the key corresponding to the value

    Returns:
        the value that was set

    Complexity: $(BIGOH n), where n is the number of elements in the
                corresponding key bucket.
    */
    V opIndexAssign(V value, K key)
    {
        if (buckets.length == 0)
        {
            initialize();
        }

        auto pair = getPairByKey(key);
        if (pair !is null)
        {
            assert(!is(V == const), "rcmap: replacing const value is not allowed");
            assert(!is(V == immutable), "rcmap: replacing immutable value is not allowed");

            cast() pair.value = value;
        }
        else
        {
            insertNew!true(key, value);
        }

        return value;
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 0, 1: 2]);
        m[0] = 1;
        assert(m[0] == 1);
        m[2] = 3;
        assert(m[2] == 3);
    }

    private void insertNew(bool increaseValueCount)(K key, V value)
    {
        auto hash = hashOf(key);
        auto index = getBucketIndex(hash);
        buckets[index].insertFront(KVPair(key, value));

        static if (increaseValueCount)
        {
            () @trusted { (*valueCount.ptr)++; }();

            if (shouldRehash())
            {
                rehash();
            }
        }
    }

    /**
    Supports `key in map` syntax.

    Params:
        key = the key to be found

    Returns:
        pointer to the value corresponding to the given key, or null if the key
        is not present in the map.
    */
    V* opBinaryRight(string op)(K key)
    if (op == "in")
    {
        auto pair = getPairByKey(key);

        if (pair is null)
        {
            return null;
        }

        return &pair.value;
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 0, 1: 2]);

        assert(1 in m);
        assert(2 !in m);
    }

    /**
    Removes the value associated with the given key.

    Returns:
        true if the value was removed
    */
    bool remove(K key)
    {
        auto hash = hashOf(key);
        auto index = getBucketIndex(hash);
        if (!buckets[index].remove(key))
        {
            return false;
        }
        else
        {
            () @trusted { (*valueCount.ptr)--; }();

            return true;
        }
    }

    ///
    static if (is(K == int) && is(V == int))
    @safe unittest
    {
        auto m = rcmap!(int, int)([0: 0, 1: 2]);

        assert(1 in m);
        m.remove(1);
        assert(1 !in m);
    }

    /**
    Creates an `rcarray` containing the keys in the map.

    Returns:
        an `rcarray` containing the keys in the map
    */
    rcarray!K keys()
    {
        auto keys = rcarray!K(length);

        for (auto i = 0; i < buckets.length; i++)
        {
            auto bucket = buckets[i].dup;

            while (!bucket.empty)
            {
                keys.insert!K(bucket.front.key);
                bucket.removeFront();
            }
        }

        return keys;
    }

    ///
    static if (is(K == int) && is(V == int))
    unittest
    {
        auto m = rcmap!(int, int)([0: 1, 2: 2]);
        assert(m.keys.length == 2);
    }

    /**
    Creates an `rcarray` containing the values in the map.

    Returns:
        an `rcarray` containing the values in the map
    */
    rcarray!V values()
    {
        auto values = rcarray!V(length);

        for (auto i = 0; i < buckets.length; i++)
        {
            auto bucket = buckets[i].dup;

            while (!bucket.empty)
            {
                values.insert!V(bucket.front.value);
                bucket.removeFront();
            }
        }

        return values;
    }

    ///
    static if (is(K == int) && is(V == int))
    unittest
    {
        auto m = rcmap!(int, int)([0: 1, 2: 2]);
        assert(m.values.length == 2);
    }

    @trusted
    private bool shouldRehash() pure
    {
        return (cast(float) *valueCount.ptr) / buckets.length > loadFactor;
    }

    /**
    Rehashes the map.
    */
    void rehash()
    {
        auto oldBuckets = buckets;
        auto newBucketCount = oldBuckets.length * 2;

        buckets = typeof(buckets)(newBucketCount);
        buckets.length = newBucketCount;

        for (auto i = 0; i < oldBuckets.length; i++)
        {
            while (!oldBuckets[i].empty)
            {
                auto pair = oldBuckets[i].front;
                auto hash = hashOf(pair.key);
                auto index = getBucketIndex(hash);
                buckets[index].insertFront(pair);

                oldBuckets[i].removeFront();
            }
        }
    }

    /**
    Removes all the keys and values from the map.

    The map is not rehashed after clearing.
    */
    void clear()
    {
        if (empty) return;

        foreach (i; 0 .. buckets.length)
        {
            buckets[i].clear();
        }
        () @trusted { (*valueCount.ptr) = 0; }();
    }

    ///
    static if (is(K == int) && is(V == int))
    unittest
    {
        auto m = rcmap!(int, int)([0: 1, 2: 2]);
        assert(!m.empty);
        m.clear();
        assert(m.empty);
    }

    /*
    Algorithm courtesy of:
        https://probablydance.com/2018/06/16/fibonacci-hashing-the-optimization-that-the-world-forgot-or-a-better-alternative-to-integer-modulo/
    */
    private size_t getBucketIndex(size_t hash)
    {
        static if (size_t.sizeof == 8)
            enum magic = 11_400_714_819_323_198_485UL;
        else static if (size_t.sizeof == 4)
            enum magic = 2_654_435_769U;
        else
            static assert(0, "Platform not supported");

        size_t index;
        version (LDC)
        {
            import ldc.intrinsics : llvm_cttz;
            index = (hash * magic) >>> ((size_t.sizeof * 8) - llvm_cttz(buckets.length, true));
        }
        else
        {
            import core.bitop : bsf;
            index = (hash * magic) >>> ((size_t.sizeof * 8) - bsf(buckets.length));
        }

        assert(index < buckets.length);

        return index;
    }
}

@safe @nogc nothrow unittest
{
    auto hm = rcmap!(string, int)(16);

    assert(hm.length == 0);
    assert(!hm.remove("abc"));
    hm["answer"] = 42;
    assert(hm.length == 1);
    assert("answer" in hm);
    hm.remove("answer");
    assert(hm.length == 0);
    assert("answer" !in hm);
    assert(hm.get("answer", 1000) == 1000);
    hm["one"] = 1;
    hm["one"] = 1;
    assert(hm.length == 1);
    assert(hm["one"] == 1);
    hm["one"] = 2;
    assert(hm["one"] == 2);
    assert(hm.keys().length == hm.length);
    assert(hm.values().length == hm.length);

    auto hm2 = rcmap!(char, char)(4);
    hm2['a'] = 'a';

    rcmap!(int, int) hm3;
    assert(hm3.get(100, 20) == 20);
    hm3[100] = 1;
    assert(hm3.get(100, 20) == 1);
    auto pValue = 100 in hm3;
    assert(*pValue == 1);
}

@safe nothrow unittest
{
    auto h = rcmap!(int, int)([1 : 10]);

    assert(h.keys() == [1]);
    assert(h.values() == [10]);
    assert(h.get(1, -1) == 10);
    assert(h.get(200, -1) == -1);
    assert(--h[1] == 9);
    assert(h.get(1, -1) == 9);
}

@safe nothrow unittest
{
    auto h = rcmap!(int, int)();
    assert(h.length == 0);
    h[1] = 10;
    assert(h.length == 1);
    h.clear();
    assert(h.length == 0);
    assert(h.empty);

    h[1] = 10;
    assert(h.keys() == [1]);
}
