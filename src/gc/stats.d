/**
 * Utility to simplify calculating `core.memory.GC.Stats`
 *
 * Copyright: D Language Foundation, 2018
 * License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Source: $(DRUNTIMESRC gc/stats.d)
 */
module gc.stats;

/**
    Embeds `GC.Stats` instance and adds few simple wrapper methods
    to maniplate it while doing some sanity checks.
 */
package(gc) struct GCStatsTracker
{
    @nogc nothrow @safe pure:

    import core.memory;
    GC.Stats stats;

    /**
        Record new memory added to the GC pool from OS
        Params:
            bytes = amount of memory
    */
    void added(size_t bytes)
    {
        this.stats.freeSize += bytes;
    }

    /**
        Record memory returned from the GC pool to OS
        Params:
            bytes = amount of memory
    */
    void removed(size_t bytes)
    {
        assert(this.stats.freeSize >= bytes);
        this.stats.freeSize -= bytes;
    }

    /**
        Record new chunk of allocations from the GC pool
        Params:
            bytes = amount of memory
    */
    void allocated(size_t bytes)
    {
        assert(this.stats.freeSize >= bytes);
        this.stats.freeSize -= bytes;
        this.stats.usedSize += bytes;
    }

    /**
        Record return of allocated memory to the GC pool
        Params:
            bytes = amount of memory
    */
    void freed(size_t bytes)
    {
        assert(this.stats.usedSize >= bytes);
        this.stats.freeSize += bytes;
        this.stats.usedSize -= bytes;
    }

    /**
        Reset stored GC stats
    */
    void reset()
    {
        this.stats = this.stats.init;
    }
}
