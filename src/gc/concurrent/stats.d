/**
 * This module contains garbage collector statistics functionality.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, Sean Kelly, Leandro Lucarella
 */

module gc.concurrent.stats;

import gc = gc.concurrent.gc;
import gc.concurrent.bits: GCBits;
import gc.concurrent.opts: options;

import cstdio = core.stdc.stdio;
import ctime = core.sys.posix.sys.time;


private:


/**
 * Time information for a collection.
 *
 * This struct groups all the timing information for a particular collection.
 * It stores how much time it took the different parts of a collection, splat
 * in: allocation time (the time the mutator spent in the malloc() call that
 * triggered the collection), time the world was stopped because of the
 * collection and the time spent in the collection itself. The time the world
 * was stopped includes the time spent in the collection (in this
 * implementation, which is not concurrent) and the time spent in the
 * allocation includes the time the world was stopped (this is probably true
 * for any implementation).
 */
struct TimeInfo
{
    /// Collection time (in seconds).
    double collection = -1.0;
    /// Stop-the-world time (in seconds).
    double stop_the_world = -1.0;
    /// Time spent in the malloc that triggered the collection (in seconds).
    double malloc = -1.0;
}


/**
 * Memory (space) information for a collection.
 *
 * This struct groups all the space information for a particular collection.
 * The space is partitioned in four: used, free, wasted and overhead. "used" is
 * the net space needed by the mutator; "free" is the space the GC has ready to
 * be given to the mutator when needed; "wasted" is memory that can't be used
 * by neither the collector nor the mutator (usually because of fragmentation)
 * and "overhead" is the space needed by the GC itself.
 */
struct MemoryInfo
{
    /// Heap memory used by the program (in bytes).
    size_t used = 0;
    /// Free heap memory (in bytes).
    size_t free = 0;
    /// Memory that can't be used at all (in bytes).
    size_t wasted = 0;
    /// Memory used by the GC for bookkeeping (in bytes).
    size_t overhead = 0;
}


/**
 * Information about a particular collection.
 *
 * This struct groups all information related to a particular collection. The
 * timings for the collection as stored and the space requirements are both,
 * before and after that collection, logged to easily measure how effective
 * the collection was in terms of space. The time when this collection was
 * triggered is logged too (relative to the program start, in seconds).
 *
 * See_Also: TimeInfo and MemoryInfo structs.
 */
struct CollectionInfo
{
    /// When this information were taken (seconds since the program started).
    double timestamp = -1.0;
    /// Time statistics for this collection.
    TimeInfo time;
    /// Memory statistics before the collection.
    MemoryInfo before;
    /// Memory statistics after the collection.
    MemoryInfo after;
}


/**
 * Information about a particular allocation.
 *
 * This struct groups all the information about a particular allocation. The
 * size requested in that allocation is logged, as well as the attributes
 * assigned to that cell, the time malloc() took to complete and if
 * a collection was triggered. The time when this allocation was requested is
 * logged too (relative to the program start, in seconds).
 */
struct MallocInfo
{
    /// When this information were taken (seconds since the program started).
    double timestamp = -1.0;
    /// Time spent in the malloc() call (in seconds).
    double time = -1.0;
    /// Address of the pointer returned by malloc.
    void* ptr = null;
    /// Memory requested by the malloc() call (in bytes).
    size_t size = 0;
    /// Memory attributes as BlkAttr flags.
    uint attr = 0;
    /// True if this malloc() triggered a collection.
    bool collected = false;
    /// Used memory
    size_t used;
    /// free memory
    size_t free;
}


package:

/**
 * Control and store the GC statistics.
 *
 * This is the interface to this module, it has methods for the GC to inform
 * when a relevant event has happened. The events are the start and finish of
 * an allocation, when the world is stopped and restarted and when
 * a collection is triggered and done.
 *
 * All the data is logged in memory and printed to the standard output when
 * requested (usually at the end of the program).
 *
 * See_Also: CollectionInfo and MallocInfo structs.
 */
struct Stats
{

private:

    /// The GC instance we are collecting stats from.
    .gc.GC* gc = null;

    /// True if statistics should be collected.
    bool active = false;

    /// Current collection information (printed when the malloc finishes).
    MallocInfo malloc_info;

    /// File where to write the malloc information to.
    cstdio.FILE* mallocs_file;

    /// Current collection information (printed when the collection finishes).
    CollectionInfo collection_info;

    /// File where to write the collections information to.
    cstdio.FILE* collections_file;

    /// Time when the program started.
    double program_start = -1.0;

    /// Return the current time as seconds since the epoch.
    static double now()
    {
        ctime.timeval tv;
        ctime.gettimeofday(&tv, null);
        return cast(double) tv.tv_sec + cast(double) tv.tv_usec / 1_000_000.0;
    }

    /// Fill a MemoryInfo struct with the current state of the GC heap.
    void fill_memory_info(MemoryInfo* mem_info)
    {
        mem_info.overhead += .gc.GC.sizeof + gc.pools.elements_sizeof +
                gc.roots.elements_sizeof + gc.ranges.elements_sizeof;

        // pools
        for (size_t i = 0; i < gc.pools.length; i++)
        {
            auto pool = gc.pools[i];
            mem_info.overhead += pool.npages * ubyte.sizeof;
            // the 5 bitmaps (mark, scan, free, final, noscan)
            mem_info.overhead += 5 * (GCBits.sizeof
                    + (pool.mark.nwords + 2) * uint.sizeof);

            for (size_t pn = 0; pn < pool.npages; pn++)
            {
                auto bin = cast(.gc.Bins) pool.pagetable[pn];
                if (bin < .gc.B_PAGE)
                {
                    size_t size = .gc.binsize[bin];
                    size_t attrstride = size / 16;
                    size_t attrbase = pn * (.gc.PAGESIZE / 16);
                    size_t attrtop = attrbase + (.gc.PAGESIZE / 16);
                    for (auto attri = attrbase; attri < attrtop; attri += attrstride)
                    {
                        if (pool.freebits.test(attri))
                            mem_info.free += size;
                        else
                            mem_info.used += size; // TODO: wasted
                    }
                }
                else if (bin == .gc.B_FREE)
                    mem_info.free += .gc.PAGESIZE;
                else // B_PAGE / B_PAGEPLUS
                    mem_info.used += .gc.PAGESIZE; // TODO: wasted
            }
        }
    }

    cstdio.FILE* start_file(const char* filename, const char* header)
    {
        cstdio.FILE* file = cstdio.fopen(filename, "w");
        if (file !is null)
            cstdio.fputs(header, file);
        return file;
    }

    void print_malloc()
    {
        if (this.mallocs_file is null)
            return;
        cstdio.fprintf(this.mallocs_file,
                "%f,%f,%p,%zu,%zu,%zu,%zu,%zu,%u,%u\n",
                //0  1  2   3   4   5   6   7  8  9
                this.malloc_info.timestamp,                   // 0
                this.malloc_info.time,                        // 1
                this.malloc_info.ptr,                         // 2
                this.malloc_info.size,                        // 3
                this.malloc_info.collected ? 1u : 0u,         // 4
                this.malloc_info.attr & .gc.BlkAttr.FINALIZE, // 5
                this.malloc_info.attr & .gc.BlkAttr.NO_SCAN,  // 6
                this.malloc_info.attr & .gc.BlkAttr.NO_MOVE,  // 7
                this.malloc_info.used,                        // 8
                this.malloc_info.free);                       // 9
        // TODO: make it an option
        cstdio.fflush(this.mallocs_file);
    }

    void print_collection()
    {
        if (this.collections_file is null)
            return;
        cstdio.fprintf(this.collections_file,
                "%f,%f,%f,%f,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu\n",
                //0  1  2  3   4   5   6   7   8   9  10  11
                this.collection_info.timestamp,           // 0
                this.collection_info.time.malloc,         // 1
                this.collection_info.time.collection,     // 2
                this.collection_info.time.stop_the_world, // 3
                this.collection_info.before.used,         // 4
                this.collection_info.before.free,         // 5
                this.collection_info.before.wasted,       // 6
                this.collection_info.before.overhead,     // 7
                this.collection_info.after.used,          // 8
                this.collection_info.after.free,          // 9
                this.collection_info.after.wasted,        // 10
                this.collection_info.after.overhead);     // 11
        // TODO: make it an option
        cstdio.fflush(this.collections_file);
    }


public:

    /**
     * Construct a Stats object (useful for easy initialization).
     *
     * This function should be always used to initialize a Stats object because
     * the program start time (in seconds since the epoch) needs to be taken to
     * properly add timestamps to allocations and collections.
     */
    static Stats opCall(.gc.GC* gc)
    {
        Stats this_;
        this_.gc = gc;
        if (options.malloc_stats_file[0] != '\0') {
            this_.mallocs_file = this_.start_file(
                    options.malloc_stats_file.ptr,
                    "Timestamp,Time,Pointer,Size,Collection triggered,"
                    "Finalize,No scan,No move,Pointer map,Type size\n");
            if (this_.mallocs_file !is null)
                this_.active = true;
        }
        // collection
        if (options.collect_stats_file[0] != '\0') {
            this_.collections_file = this_.start_file(
                    options.collect_stats_file.ptr,
                    "Timestamp,Malloc time,Collection time,Stop-the-world time,"
                    "Used before,Free before,Wasted before,Overhead before,"
                    "Used after,Free after,Wasted after,Overhead after\n");
            if (this_.collections_file !is null)
                this_.active = true;
        }
        this_.program_start = this_.now();
        return this_;
    }

    void finalize()
    {
        if (this.mallocs_file !is null)
            cstdio.fclose(this.mallocs_file);
        if (this.collections_file !is null)
            cstdio.fclose(this.collections_file);
    }

    /// Inform the start of an allocation.
    // TODO: store/use type information
    void malloc_started(size_t size, uint attr, size_t
            used, size_t free)
    {
        if (!this.active)
            return;
        auto now = this.now();
        auto relative_now = now - this.program_start;
        // malloc
        this.malloc_info = this.malloc_info.init;
        this.malloc_info.timestamp = relative_now;
        this.malloc_info.time = now;
        this.malloc_info.size = size;
        this.malloc_info.attr = attr;
        this.malloc_info.used   = used;
        this.malloc_info.free   = free;
        // this.malloc_info.collected is filled in malloc_finished()
        // collection
        this.collection_info = this.collection_info.init;
        this.collection_info.timestamp = relative_now;
        // this.collection_info.time.malloc is the same as malloc_info.time
    }

    /// Inform the end of an allocation.
    void malloc_finished(void* ptr)
    {
        if (!this.active)
            return;
        auto now = this.now();
        auto collected = !(this.collection_info.time.collection < 0.0);
        // malloc
        this.malloc_info.time = now - this.malloc_info.time;
        if (collected)
            this.malloc_info.collected = true;
        this.malloc_info.ptr = ptr;
        this.print_malloc();
        if (!collected)
            return;
        // collection
        this.collection_info.time.malloc = this.malloc_info.time;
        this.print_collection();
    }

    /// Inform that all threads (the world) have been stopped.
    void world_stopped()
    {
        if (!this.active)
            return;
        this.collection_info.time.stop_the_world = this.now();
    }

    /// Inform that all threads (the world) have been resumed.
    void world_started()
    {
        if (!this.active)
            return;
        this.collection_info.time.stop_the_world =
                this.now() - this.collection_info.time.stop_the_world;
    }

    /// Inform the start of a collection.
    void collection_started()
    {
        if (!this.active)
            return;
        this.fill_memory_info(&this.collection_info.before);
        this.collection_info.time.collection = this.now();
    }

    /// Inform the end of a collection.
    void collection_finished()
    {
        if (!this.active)
            return;
        this.collection_info.time.collection =
                this.now() - this.collection_info.time.collection;
        this.fill_memory_info(&this.collection_info.after);
    }

}


/**
 *
 */
struct GCStats
{
    size_t poolsize;        // total size of pool
    size_t usedsize;        // bytes allocated
    size_t freeblocks;      // number of blocks marked FREE
    size_t freelistsize;    // total of memory on free lists
    size_t pageblocks;      // number of blocks marked PAGE
}


// vim: set et sw=4 sts=4 :
