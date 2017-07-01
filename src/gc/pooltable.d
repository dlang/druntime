/**
 * A sorted array to quickly lookup pools.
 *
 * Copyright: Copyright Digital Mars 2001 -.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, David Friedman, Sean Kelly, Martin Nowak
 */
module gc.pooltable;

static import cstdlib=core.stdc.stdlib;
import rt.util.container.hashtab;

enum
{
    POOLMAP_START_CAPACITY = 32,
    PAGESIZE =    4096,
    POOLSIZE =   (4096*256),
}

struct PoolTable(Pool)
{
    import core.stdc.string : memmove;

nothrow:
    void initialize()
    {
        poolMap = PoolMap(POOLMAP_START_CAPACITY);
    }

    void Dtor()
    {
        cstdlib.free(pools);
        pools = null;
        npools = 0;
    }

    bool insert(Pool* pool)
    {
        auto newpools = cast(Pool **)cstdlib.realloc(pools, (npools + 1) * pools[0].sizeof);
        if (!newpools)
            return false;

        pools = newpools;

        // Sort pool into newpooltable[]
        size_t i;
        for (; i < npools; ++i)
        {
            if (pool.baseAddr < pools[i].baseAddr)
                break;
        }
        if (i != npools)
            memmove(pools + i + 1, pools + i, (npools - i) * pools[0].sizeof);
        pools[i] = pool;

        ++npools;

        _minAddr = pools[0].baseAddr;
        _maxAddr = pools[npools - 1].topAddr;
        addToMap(pool.baseAddr, pool.topAddr, pool);
        return true;
    }

    @property size_t length() pure const
    {
        return npools;
    }

    ref inout(Pool*) opIndex(size_t idx) inout pure
    in { assert(idx < length); }
    body
    {
        return pools[idx];
    }

    inout(Pool*)[] opSlice(size_t a, size_t b) inout pure
    in { assert(a <= length && b <= length); }
    body
    {
        return pools[a .. b];
    }

    alias opDollar = length;

    /**
     * Find Pool that pointer is in.
     * Return null if not in a Pool.
     * Assume pooltable[] is sorted.
     */
    Pool *findPool(void *p) nothrow
    {
        if (p >= minAddr && p < maxAddr)
        {
            return findPoolDirect(p);
        }
        return null;
    }

    Pool *findPoolDirect(void *p) nothrow
    {
        assert(npools);
        size_t adjusted = cast(size_t)p & ~(POOLSIZE-1);
        return poolMap[adjusted];
    }

    // semi-stable partition, returns right half for which pred is false
    Pool*[] minimize()
    {
        static void swap(ref Pool* a, ref Pool* b)
        {
            auto c = a; a = b; b = c;
        }

        size_t i;
        // find first bad entry
        for (; i < npools; ++i)
            if (pools[i].isFree) break;

        // move good in front of bad entries
        size_t j = i + 1;
        for (; j < npools; ++j)
        {
            if (!pools[j].isFree) // keep
                swap(pools[i++], pools[j]);
        }
        // npooltable[0 .. i]      => used pools
        // npooltable[i .. npools] => free pools

        if (i)
        {
            _minAddr = pools[0].baseAddr;
            _maxAddr = pools[i - 1].topAddr;
        }
        else
        {
            _minAddr = _maxAddr = null;
        }

        immutable len = npools;
        npools = i;
        // rebuild hash map if there are changes to pools
        if(len != npools)
        {
            poolMap.reset();
            foreach (p; pools[0..npools])
            {
                addToMap(p.baseAddr, p.topAddr, p);
            }
        }
        // return freed pools to the caller
        return pools[npools .. len];
    }

    @property const(void)* minAddr() pure const { return _minAddr; }
    @property const(void)* maxAddr() pure const { return _maxAddr; }

package:
    static if(size_t.sizeof == 4)
        alias Index = ushort;
    else
        alias Index = uint;

    void addToMap(void* start, void* end, Pool* pool)
    {
        assert(cast(size_t)start % POOLSIZE == 0);
        assert(cast(size_t)end % POOLSIZE == 0);
        for(void* i = start; i < end; i+= POOLSIZE)
        {
            poolMap[cast(size_t)i] = pool;
        }
    }

    /*void removeFromMap(void* start, void* end)
    {
        assert(cast(size_t)start % POOLSIZE == 0);
        assert(cast(size_t)end % POOLSIZE == 0);
        Index s = cast(Index)(cast(size_t)start / POOLSIZE);
        Index e = cast(Index)(cast(size_t)end / POOLSIZE);
        for(Index i = s; i < e; i++)
        {
            poolMap.remove(i);
        }
    }*/

    alias PoolMap = FlatHashTab!(size_t, Pool*, null,
        x => (x >> 20) ^ 0xAAAA_AAAA);
    PoolMap poolMap;
    Pool** pools;
    size_t npools;
    void* _minAddr, _maxAddr;
}

unittest
{
    enum NPOOLS = 6;
    enum NPAGES = 10;

    static struct MockPool
    {
        byte* baseAddr, topAddr;
        size_t freepages, npages;
        @property bool isFree() const pure nothrow { return freepages == npages; }
    }
    PoolTable!MockPool pooltable;

    void reset()
    {
        foreach(ref pool; pooltable[0 .. $])
            pool.freepages = pool.npages;
        pooltable.minimize();
        assert(pooltable.length == 0);

        foreach(i; 0 .. NPOOLS)
        {
            auto pool = cast(MockPool*)cstdlib.malloc(MockPool.sizeof);
            *pool = MockPool.init;
            assert(pooltable.insert(pool));
        }
    }

    void usePools()
    {
        foreach(pool; pooltable[0 .. $])
        {
            pool.npages = NPAGES;
            pool.freepages = NPAGES / 2;
        }
    }

    // all pools are free
    reset();
    assert(pooltable.length == NPOOLS);
    auto freed = pooltable.minimize();
    assert(freed.length == NPOOLS);
    assert(pooltable.length == 0);

    // all pools used
    reset();
    usePools();
    assert(pooltable.length == NPOOLS);
    freed = pooltable.minimize();
    assert(freed.length == 0);
    assert(pooltable.length == NPOOLS);

    // preserves order of used pools
    reset();
    usePools();

    {
        MockPool*[NPOOLS] opools = pooltable[0 .. NPOOLS];
        // make the 2nd pool free
        pooltable[2].freepages = NPAGES;

        pooltable.minimize();
        assert(pooltable.length == NPOOLS - 1);
        assert(pooltable[0] == opools[0]);
        assert(pooltable[1] == opools[1]);
        assert(pooltable[2] == opools[3]);
    }

    // test that PoolTable reduces min/max address span
    reset();
    usePools();

    byte* base, top;

    {
        // fill with fake addresses
        size_t i;
        foreach(pool; pooltable[0 .. NPOOLS])
        {
            pool.baseAddr = cast(byte*)(i++ * NPAGES * POOLSIZE);
            pool.topAddr = pool.baseAddr + NPAGES * POOLSIZE;
        }
        base = pooltable[0].baseAddr;
        top = pooltable[NPOOLS - 1].topAddr;
    }

    freed = pooltable.minimize();
    assert(freed.length == 0);
    assert(pooltable.length == NPOOLS);
    assert(pooltable.minAddr == base);
    assert(pooltable.maxAddr == top);

    pooltable[NPOOLS - 1].freepages = NPAGES;
    pooltable[NPOOLS - 2].freepages = NPAGES;

    freed = pooltable.minimize();
    assert(freed.length == 2);
    assert(pooltable.length == NPOOLS - 2);
    assert(pooltable.minAddr == base);
    assert(pooltable.maxAddr == pooltable[NPOOLS - 3].topAddr);

    pooltable[0].freepages = NPAGES;

    freed = pooltable.minimize();
    assert(freed.length == 1);
    assert(pooltable.length == NPOOLS - 3);
    assert(pooltable.minAddr != base);
    assert(pooltable.minAddr == pooltable[0].baseAddr);
    assert(pooltable.maxAddr == pooltable[NPOOLS - 4].topAddr);

    // free all
    foreach(pool; pooltable[0 .. $])
        pool.freepages = NPAGES;
    freed = pooltable.minimize();
    assert(freed.length == NPOOLS - 3);
    assert(pooltable.length == 0);
    pooltable.Dtor();
}
