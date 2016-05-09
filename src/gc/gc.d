/**
 * Contains the garbage collector implementation.
 *
 * Copyright: Copyright Digital Mars 2001 - 2013.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, David Friedman, Sean Kelly
 */

/*          Copyright Digital Mars 2005 - 2013.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.gc;

// D Programming Language Garbage Collector implementation

/************** Debugging ***************************/

//debug = PRINTF;               // turn on printf's
//debug = COLLECT_PRINTF;       // turn on printf's
//debug = PRINTF_TO_FILE;       // redirect printf's ouptut to file "gcx.log"
//debug = LOGGING;              // log allocations / frees
//debug = MEMSTOMP;             // stomp on memory
//debug = SENTINEL;             // add underrun/overrrun protection
                                // NOTE: this needs to be enabled globally in the makefiles
                                // (-debug=SENTINEL) to pass druntime's unittests.
//debug = PTRCHECK;             // more pointer checking
//debug = PTRCHECK2;            // thorough but slow pointer checking
//debug = INVARIANT;            // enable invariants
//debug = PROFILE_API;          // profile API calls for config.profile > 1

/*************** Configuration *********************/

version = STACKGROWSDOWN;       // growing the stack means subtracting from the stack pointer
                                // (use for Intel X86 CPUs)
                                // else growing the stack means adding to the stack pointer

/***************************************************/

import gc.bits;
import gc.stats;
import gc.os;
import gc.config;

import rt.util.container.treap;

import cstdlib = core.stdc.stdlib : calloc, free, malloc, realloc;
import core.stdc.string : memcpy, memset, memmove;
import core.bitop;
import core.thread;
static import core.memory;
private alias BlkAttr = core.memory.GC.BlkAttr;
private alias BlkInfo = core.memory.GC.BlkInfo;

version (GNU) import gcc.builtins;

debug (PRINTF_TO_FILE) import core.stdc.stdio : sprintf, fprintf, fopen, fflush, FILE;
else                   import core.stdc.stdio : sprintf, printf; // needed to output profiling results

import core.time;
alias currTime = MonoTime.currTime;

debug(PRINTF_TO_FILE)
{
    private __gshared MonoTime gcStartTick;
    private __gshared FILE* gcx_fh;

    private int printf(ARGS...)(const char* fmt, ARGS args) nothrow
    {
        if (!gcx_fh)
            gcx_fh = fopen("gcx.log", "w");
        if (!gcx_fh)
            return 0;

        int len;
        if (MonoTime.ticksPerSecond == 0)
        {
            len = fprintf(gcx_fh, "before init: ");
        }
        else
        {
            if (gcStartTick == MonoTime.init)
                gcStartTick = MonoTime.currTime;
            immutable timeElapsed = MonoTime.currTime - gcStartTick;
            immutable secondsAsDouble = timeElapsed.total!"hnsecs" / cast(double)convert!("seconds", "hnsecs")(1);
            len = fprintf(gcx_fh, "%10.6lf: ", secondsAsDouble);
        }
        len += fprintf(gcx_fh, fmt, args);
        fflush(gcx_fh);
        return len;
    }
}

debug(PRINTF) void printFreeInfo(Pool* pool) nothrow
{
    uint nReallyFree;
    foreach(i; 0..pool.npages) {
        if(pool.pagetable[i] >= B_FREE) nReallyFree++;
    }

    printf("Pool %p:  %d really free, %d supposedly free\n", pool, nReallyFree, pool.freepages);
}

// Track total time spent preparing for GC,
// marking, sweeping and recovering pages.
__gshared Duration prepTime;
__gshared Duration markTime;
__gshared Duration sweepTime;
__gshared Duration recoverTime;
__gshared Duration maxPauseTime;
__gshared size_t numCollections;
__gshared size_t maxPoolMemory;

__gshared long numMallocs;
__gshared long numFrees;
__gshared long numReallocs;
__gshared long numExtends;
__gshared long numOthers;
__gshared long mallocTime; // using ticks instead of MonoTime for better performance
__gshared long freeTime;
__gshared long reallocTime;
__gshared long extendTime;
__gshared long otherTime;
__gshared long lockTime;

private
{
    extern (C)
    {
        // to allow compilation of this module without access to the rt package,
        //  make these functions available from rt.lifetime
        void rt_finalizeFromGC(void* p, size_t size, uint attr) nothrow;
        int rt_hasFinalizerInSegment(void* p, size_t size, uint attr, in void[] segment) nothrow;

        // Declared as an extern instead of importing core.exception
        // to avoid inlining - see issue 13725.
        void onInvalidMemoryOperationError() @nogc nothrow;
        void onOutOfMemoryErrorNoGC() @nogc nothrow;
    }

    enum
    {
        OPFAIL = ~cast(size_t)0
    }
}


alias GC gc_t;


/* ======================= Leak Detector =========================== */


debug (LOGGING)
{
    struct Log
    {
        void*  p;
        size_t size;
        size_t line;
        char*  file;
        void*  parent;

        void print() nothrow
        {
            printf("    p = %p, size = %zd, parent = %p ", p, size, parent);
            if (file)
            {
                printf("%s(%u)", file, line);
            }
            printf("\n");
        }
    }


    struct LogArray
    {
        size_t dim;
        size_t allocdim;
        Log *data;

        void Dtor() nothrow
        {
            if (data)
                cstdlib.free(data);
            data = null;
        }

        void reserve(size_t nentries) nothrow
        {
            assert(dim <= allocdim);
            if (allocdim - dim < nentries)
            {
                allocdim = (dim + nentries) * 2;
                assert(dim + nentries <= allocdim);
                if (!data)
                {
                    data = cast(Log*)cstdlib.malloc(allocdim * Log.sizeof);
                    if (!data && allocdim)
                        onOutOfMemoryErrorNoGC();
                }
                else
                {   Log *newdata;

                    newdata = cast(Log*)cstdlib.malloc(allocdim * Log.sizeof);
                    if (!newdata && allocdim)
                        onOutOfMemoryErrorNoGC();
                    memcpy(newdata, data, dim * Log.sizeof);
                    cstdlib.free(data);
                    data = newdata;
                }
            }
        }


        void push(Log log) nothrow
        {
            reserve(1);
            data[dim++] = log;
        }

        void remove(size_t i) nothrow
        {
            memmove(data + i, data + i + 1, (dim - i) * Log.sizeof);
            dim--;
        }


        size_t find(void *p) nothrow
        {
            for (size_t i = 0; i < dim; i++)
            {
                if (data[i].p == p)
                    return i;
            }
            return OPFAIL; // not found
        }


        void copy(LogArray *from) nothrow
        {
            reserve(from.dim - dim);
            assert(from.dim <= allocdim);
            memcpy(data, from.data, from.dim * Log.sizeof);
            dim = from.dim;
        }
    }
}


/* ============================ GC =============================== */


const uint GCVERSION = 1;       // increment every time we change interface
                                // to GC.

struct GC
{
    // For passing to debug code (not thread safe)
    __gshared size_t line;
    __gshared char*  file;

    uint gcversion = GCVERSION;

    Gcx *gcx;                   // implementation

    import core.internal.spinlock;
    static gcLock = shared(AlignedSpinLock)(SpinLock.Contention.lengthy);
    static bool inFinalizer;

    /*
     * Lock the GC.
     *
     * Throws:
     *  InvalidMemoryOperationError on recursive locking during finalization.
     */
    static void lockNR() @nogc nothrow
    {
        if (inFinalizer)
            onInvalidMemoryOperationError();
        gcLock.lock();
    }

    __gshared Config config;


    /*
     * Initialize the GC based on command line configuration.
     *
     * Throws:
     *  OutOfMemoryError if failed to initialize GC due to not enough memory.
     */
    void initialize()
    {
        config.initialize();

        gcx = cast(Gcx*)cstdlib.calloc(1, Gcx.sizeof);
        if (!gcx)
            onOutOfMemoryErrorNoGC();
        gcx.initialize();

        if (config.initReserve)
            gcx.reserve(config.initReserve << 20);
        if (config.disable)
            gcx.disabled++;
    }


    void Dtor()
    {
        if (gcx)
        {
            gcx.Dtor();
            cstdlib.free(gcx);
            gcx = null;
        }
    }


    /**
     * Enables automatic garbage collection behavior if collections have
     * previously been suspended by a call to disable.  This function is
     * reentrant, and must be called once for every call to disable before
     * automatic collections are enabled.
     */
    void enable()
    {
        static void go(Gcx* gcx) nothrow
        {
            assert(gcx.disabled > 0);
            gcx.disabled--;
        }
        runLocked!(go, otherTime, numOthers)(gcx);
    }


    /**
     * Disables automatic garbage collections performed to minimize the
     * process footprint.  Collections may continue to occur in instances
     * where the implementation deems necessary for correct program behavior,
     * such as during an out of memory condition.  This function is reentrant,
     * but enable must be called once for each call to disable.
     */
    void disable()
    {
        static void go(Gcx* gcx) nothrow
        {
            gcx.disabled++;
        }
        runLocked!(go, otherTime, numOthers)(gcx);
    }

    /**
     * Run a function inside a lock/unlock set.
     *
     * Params:
     *  func = The function to run.
     *  args = The function arguments.
     */
    auto runLocked(alias func, Args...)(auto ref Args args)
    {
        debug(PROFILE_API) immutable tm = (GC.config.profile > 1 ? currTime.ticks : 0);
        lockNR();
        scope (failure) gcLock.unlock();
        debug(PROFILE_API) immutable tm2 = (GC.config.profile > 1 ? currTime.ticks : 0);

        static if (is(typeof(func(args)) == void))
            func(args);
        else
            auto res = func(args);

        debug(PROFILE_API) if (GC.config.profile > 1)
            lockTime += tm2 - tm;
        gcLock.unlock();

        static if (!is(typeof(func(args)) == void))
            return res;
    }

    /**
     * Run a function in an lock/unlock set that keeps track of
     * how much time was spend inside this function (in ticks)
     * and how many times this fuction was called.
     *
     * Params:
     *  func = The function to run.
     *  time = The variable keeping track of the time (in ticks).
     *  count = The variable keeping track of how many times this fuction was called.
     *  args = The function arguments.
     */
    auto runLocked(alias func, alias time, alias count, Args...)(auto ref Args args)
    {
        debug(PROFILE_API) immutable tm = (GC.config.profile > 1 ? currTime.ticks : 0);
        lockNR();
        scope (failure) gcLock.unlock();
        debug(PROFILE_API) immutable tm2 = (GC.config.profile > 1 ? currTime.ticks : 0);

        static if (is(typeof(func(args)) == void))
            func(args);
        else
            auto res = func(args);

        debug(PROFILE_API) if (GC.config.profile > 1)
        {
            count++;
            immutable now = currTime.ticks;
            lockTime += tm2 - tm;
            time += now - tm2;
        }
        gcLock.unlock();

        static if (!is(typeof(func(args)) == void))
            return res;
    }

    /**
     * Returns a bit field representing all block attributes set for the memory
     * referenced by p.  If p references memory not originally allocated by
     * this garbage collector, points to the interior of a memory block, or if
     * p is null, zero will be returned.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *
     * Returns:
     *  A bit field containing any bits set for the memory block referenced by
     *  p or zero on error.
     */
    uint getAttr(void* p) nothrow
    {
        if (!p)
        {
            return 0;
        }

        static uint go(Gcx* gcx, void* p) nothrow
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                p = sentinel_sub(p);
                auto biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;

                oldb = pool.getBits(biti);
            }
            return oldb;
        }

        return runLocked!(go, otherTime, numOthers)(gcx, p);
    }


    /**
     * Sets the specified bits for the memory references by p.  If p references
     * memory not originally allocated by this garbage collector, points to the
     * interior of a memory block, or if p is null, no action will be
     * performed.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *  mask = A bit field containing any bits to set for this memory block.
     *
     * Returns:
     *  The result of a call to getAttr after the specified bits have been
     *  set.
     */
    uint setAttr(void* p, uint mask) nothrow
    {
        if (!p)
        {
            return 0;
        }

        static uint go(Gcx* gcx, void* p, uint mask) nothrow
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                p = sentinel_sub(p);
                auto biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;

                //Based on the documetnation, shouldn't we set the
                //bits first and then get the new value of the bit field?
                oldb = pool.getBits(biti);
                pool.setBits(biti, mask);
            }
            return oldb;
        }

        return runLocked!(go, otherTime, numOthers)(gcx, p, mask);
    }


    /**
     * Clears the specified bits for the memory references by p.  If p
     * references memory not originally allocated by this garbage collector,
     * points to the interior of a memory block, or if p is null, no action
     * will be performed.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *  mask = A bit field containing any bits to clear for this memory block.
     *
     * Returns:
     *  The result of a call to getAttr after the specified bits have been
     *  cleared.
     */
    uint clrAttr(void* p, uint mask) nothrow
    {
        if (!p)
        {
            return 0;
        }

        static uint go(Gcx* gcx, void* p, uint mask) nothrow
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                p = sentinel_sub(p);
                auto biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;

                //Based on the documetnation, shouldn't we clear the
                //bits first and then get the new value of the bit field?
                oldb = pool.getBits(biti);
                pool.clrBits(biti, mask);
            }
            return oldb;
        }

        return runLocked!(go, otherTime, numOthers)(gcx, p, mask);
    }

    /**
     * Requests an aligned block of managed memory from the garbage collector.
     * This memory may be deleted at will with a call to free, or it may be
     * discarded and cleaned up automatically during a collection run.  If
     * allocation fails, this function will call onOutOfMemory which is
     * expected to throw an OutOfMemoryError.
     *
     * Params:
     *  size = The desired allocation size in bytes.
     *  bits = A bitmask of the attributes to set on this block.
     *  alloc_size = The actuall size allocated in bytes.
     *  ti = TypeInfo to describe the memory. The GC might use this information
     *       to improve scanning for pointers or to call finalizers.
     *
     * Returns:
     *  A reference to the allocated memory or null if no memory was requested.
     *
     * Throws:
     *  OutOfMemoryError on allocation failure.
     */
    void *malloc(size_t size, uint bits = 0, size_t *alloc_size = null, const TypeInfo ti = null) nothrow
    {
        if (!size)
        {
            if(alloc_size)
                *alloc_size = 0;
            return null;
        }

        size_t localAllocSize = void;
        if(alloc_size is null) alloc_size = &localAllocSize;

        auto p = runLocked!(mallocNoSync, mallocTime, numMallocs)(size, bits, *alloc_size, ti);

        if (!(bits & BlkAttr.NO_SCAN))
        {
            memset(p + size, 0, *alloc_size - size);
        }

        return p;
    }


    //
    // The allocation implementation used by malloc and calloc.
    //
    private void *mallocNoSync(size_t size, uint bits, ref size_t alloc_size, const TypeInfo ti = null) nothrow
    {
        assert(size != 0); //Is this assert needed? Both mallooc and calloc
                           //check the size before calling this function.
        assert(gcx);


        auto p = gcx.alloc(size + SENTINEL_EXTRA, alloc_size, bits);
        if (!p)
            onOutOfMemoryErrorNoGC();

        debug (SENTINEL)
        {
            p = sentinel_add(p);
            sentinel_init(p, size);
            alloc_size = size;
        }
        gcx.log_malloc(p, size);

        return p;
    }


    /**
     * Requests an aligned block of managed memory from the garbage collector,
     * which is initialized with all bits set to zero.  This memory may be
     * deleted at will with a call to free, or it may be discarded and cleaned
     * up automatically during a collection run.  If allocation fails, this
     * function will call onOutOfMemory which is expected to throw an
     * OutOfMemoryError.
     *
     * Params:
     *  size = The desired allocation size in bytes.
     *  bits = A bitmask of the attributes to set on this block.
     *  alloc_size = The actuall size allocated in bytes.
     *  ti = TypeInfo to describe the memory. The GC might use this information
     *       to improve scanning for pointers or to call finalizers.
     *
     * Returns:
     *  A reference to the allocated memory or null if no memory was requested.
     *
     * Throws:
     *  OutOfMemoryError on allocation failure.
     */
    void *calloc(size_t size, uint bits = 0, size_t *alloc_size = null, const TypeInfo ti = null) nothrow
    {
        if (!size)
        {
            if(alloc_size)
                *alloc_size = 0;
            return null;
        }

        size_t localAllocSize = void;
        if(alloc_size is null) alloc_size = &localAllocSize;

        auto p = runLocked!(mallocNoSync, mallocTime, numMallocs)(size, bits, *alloc_size, ti);

        memset(p, 0, size);
        if (!(bits & BlkAttr.NO_SCAN))
        {
            memset(p + size, 0, *alloc_size - size);
        }

        return p;
    }


     /**
     * A new memory block of "size" bytes will be allocated as if by a call to
     * malloc or the implementation may instead resize the memory block in place.
     * The contents of the new memory block will be the same as the contents of
     * the old memory block, up to the lesser of the new and old sizes.  Note
     * that existing memory will be deallocated by realloc if and only if size
     * is equal to zero, as if by a call to free.  The garbage collector is
     * otherwise expected to later reclaim the memory block if it is unused.
     * If allocation fails, this function will call onOutOfMemory which is
     * expected to throw an OutOfMemoryError.  If p references memory not
     * originally allocated by this garbage collector, or if it points to the
     * interior of a memory block, no action will be taken.  If bits is zero
     * (the default) and p references the head of a valid, known memory block
     * then any bits set on the current block will be set on the new block if a
     * reallocation is required.  If bits is not zero and p references the head
     * of a valid, known memory block then the bits in bits will replace those
     * on the current memory block and will also be set on the new block if a
     * reallocation is required.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *  size = The desired allocation size in bytes.
     *  bits = A bitmask of the attributes to set on this block.
     *  alloc_size = The actuall size allocated in bytes.
     *  ti = TypeInfo to describe the memory. The GC might use this information
     *       to improve scanning for pointers or to call finalizers.
     *
     * Returns:
     *  A reference to the allocated memory on success or null if size is
     *  zero.  On failure, the original value of p is returned.
     *
     * Throws:
     *  OutOfMemoryError on allocation failure.
     */

    void *realloc(void *p, size_t size, uint bits = 0, size_t *alloc_size = null, const TypeInfo ti = null) nothrow
    {
        size_t localAllocSize = void;
        auto oldp = p;
        if(alloc_size is null) alloc_size = &localAllocSize;

        p = runLocked!(reallocNoSync, mallocTime, numMallocs)(p, size, bits, *alloc_size, ti);

        if (p !is oldp && !(bits & BlkAttr.NO_SCAN))
        {
            memset(p + size, 0, *alloc_size - size);
        }

        return p;
    }


    //
    // The implementation of realloc.
    //
    private void *reallocNoSync(void *p, size_t size, ref uint bits, ref size_t alloc_size, const TypeInfo ti = null) nothrow
    {
        if (!size)
        {   if (p)
            {   freeNoSync(p);
                p = null;
            }
            alloc_size = 0;
        }
        else if (!p)
        {
            p = mallocNoSync(size, bits, alloc_size, ti);
        }
        else
        {   void *p2;
            size_t psize;

            debug (SENTINEL)
            {
                sentinel_Invariant(p);
                psize = *sentinel_size(p);
                if (psize != size)
                {
                    if (psize)
                    {
                        Pool *pool = gcx.findPool(p);

                        if (pool)
                        {
                            auto biti = cast(size_t)(sentinel_sub(p) - pool.baseAddr) >> pool.shiftBy;

                            if (bits)
                            {
                                pool.clrBits(biti, ~BlkAttr.NONE);
                                pool.setBits(biti, bits);
                            }
                            else
                            {
                                bits = pool.getBits(biti);
                            }
                        }
                    }
                    p2 = mallocNoSync(size, bits, alloc_size, ti);
                    if (psize < size)
                        size = psize;

                    memcpy(p2, p, size);
                    p = p2;
                }
            }
            else
            {
                auto pool = gcx.findPool(p);
                if (pool.isLargeObject)
                {
                    auto lpool = cast(LargeObjectPool*) pool;
                    psize = lpool.getSize(p);     // get allocated size

                    if (size <= PAGESIZE / 2)
                        goto Lmalloc; // switching from large object pool to small object pool

                    auto psz = psize / PAGESIZE;
                    auto newsz = (size + PAGESIZE - 1) / PAGESIZE;
                    if (newsz == psz)
                    {
                        alloc_size = psize;
                        return p;
                    }

                    auto pagenum = lpool.pagenumOf(p);

                    if (newsz < psz)
                    {   // Shrink in place
                        debug (MEMSTOMP) memset(p + size, 0xF2, psize - size);
                        lpool.freePages(pagenum + newsz, psz - newsz);
                    }
                    else if (pagenum + newsz <= pool.npages)
                    {   // Attempt to expand in place
                        foreach (binsz; lpool.pagetable[pagenum + psz .. pagenum + newsz])
                            if (binsz != B_FREE)
                                goto Lmalloc;

                        debug (MEMSTOMP) memset(p + psize, 0xF0, size - psize);
                        debug(PRINTF) printFreeInfo(pool);
                        memset(&lpool.pagetable[pagenum + psz], B_PAGEPLUS, newsz - psz);
                        gcx.usedLargePages += newsz - psz;
                        lpool.freepages -= (newsz - psz);
                        debug(PRINTF) printFreeInfo(pool);
                    }
                    else
                        goto Lmalloc; // does not fit into current pool

                    lpool.updateOffsets(pagenum);
                    if (bits)
                    {
                        immutable biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;
                        pool.clrBits(biti, ~BlkAttr.NONE);
                        pool.setBits(biti, bits);
                    }
                    alloc_size = newsz * PAGESIZE;
                    return p;
                }

                psize = (cast(SmallObjectPool*) pool).getSize(p);   // get allocated size
                if (psize < size ||             // if new size is bigger
                    psize > size * 2)           // or less than half
                {
                Lmalloc:
                    if (psize && pool)
                    {
                        auto biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;

                        if (bits)
                        {
                            pool.clrBits(biti, ~BlkAttr.NONE);
                            pool.setBits(biti, bits);
                        }
                        else
                        {
                            bits = pool.getBits(biti);
                        }
                    }
                    p2 = mallocNoSync(size, bits, alloc_size, ti);
                    if (psize < size)
                        size = psize;

                    memcpy(p2, p, size);
                    p = p2;
                }
                else
                    alloc_size = psize;
            }
        }
        return p;
    }


    /**
     * Requests that the managed memory block referenced by p be extended in
     * place by at least minsize bytes, with a desired extension of maxsize bytes.  If an
     * extension of the required size is not possible or if p references memory
     * not originally allocated by this garbage collector, no action will be
     * taken.
     *
     * Params:
     *  p  = A pointer to the root of a valid memory block or to null.
     *  minsize = The minimum extension size in bytes.
     *  maxsize = The desired extension size in bytes.
     *  ti = TypeInfo to describe the full memory block. The GC might use
     *       this information to improve scanning for pointers or to
     *       call finalizers.
     *
     * Returns:
     *  The size in bytes of the extended memory block referenced by p or zero
     *  if no extension occurred.
     *
     * Note:
     *  Extend may also be used to extend slices (or memory blocks with
     *  appendable info). However, use the return value only
     *  as an indicator of success. capacity should be used to
     *  retrieve actual useable slice capacity.
     */
    size_t extend(void* p, size_t minsize, size_t maxsize, const TypeInfo ti = null) nothrow
    {
        return runLocked!(extendNoSync, extendTime, numExtends)(p, minsize, maxsize, ti);
    }


    //
    // Implementation of extend.
    //
    private size_t extendNoSync(void* p, size_t minsize, size_t maxsize, const TypeInfo ti = null) nothrow
    in
    {
        assert(minsize <= maxsize);
    }
    body
    {
        //debug(PRINTF) printf("GC::extend(p = %p, minsize = %zu, maxsize = %zu)\n", p, minsize, maxsize);
        debug (SENTINEL)
        {
            return 0;
        }
        else
        {
            auto pool = gcx.findPool(p);
            if (!pool || !pool.isLargeObject)
                return 0;

            auto lpool = cast(LargeObjectPool*) pool;
            auto psize = lpool.getSize(p);   // get allocated size
            if (psize < PAGESIZE)
                return 0;                   // cannot extend buckets

            auto psz = psize / PAGESIZE;
            auto minsz = (minsize + PAGESIZE - 1) / PAGESIZE;
            auto maxsz = (maxsize + PAGESIZE - 1) / PAGESIZE;

            auto pagenum = lpool.pagenumOf(p);

            size_t sz;
            for (sz = 0; sz < maxsz; sz++)
            {
                auto i = pagenum + psz + sz;
                if (i == lpool.npages)
                    break;
                if (lpool.pagetable[i] != B_FREE)
                {   if (sz < minsz)
                        return 0;
                    break;
                }
            }
            if (sz < minsz)
                return 0;
            debug (MEMSTOMP) memset(pool.baseAddr + (pagenum + psz) * PAGESIZE, 0xF0, sz * PAGESIZE);
            memset(lpool.pagetable + pagenum + psz, B_PAGEPLUS, sz);
            lpool.updateOffsets(pagenum);
            lpool.freepages -= sz;
            gcx.usedLargePages += sz;
            return (psz + sz) * PAGESIZE;
        }
    }


    /**
     * Requests that at least size bytes of memory be obtained from the operating
     * system and marked as free.
     *
     * Params:
     *  size = The desired size in bytes.
     *
     * Returns:
     *  The actual number of bytes reserved or zero on error.
     */
    size_t reserve(size_t size) nothrow
    {
        if (!size)
        {
            return 0;
        }

        return runLocked!(reserveNoSync, otherTime, numOthers)(size);
    }


    //
    // Implementation of reserve
    //
    private size_t reserveNoSync(size_t size) nothrow
    {
        assert(size != 0); //Is this assert needed?
                           //reserve checks size before this is called
        assert(gcx);

        return gcx.reserve(size);
    }


     /**
     * Deallocates the memory referenced by p.  If p is null, no action occurs.
     * If p references memory not originally allocated by this garbage
     * collector, if p points to the interior of a memory block, or if this
     * method is called from a finalizer, no action will be taken.  The block
     * will not be finalized regardless of whether the FINALIZE attribute is
     * set.  If finalization is desired, use delete instead.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void free(void *p) nothrow
    {
        if (!p || inFinalizer)
        {
            return;
        }

        return runLocked!(freeNoSync, freeTime, numFrees)(p);
    }


    //
    // Implementation of free.
    //
    private void freeNoSync(void *p) nothrow
    {
        debug(PRINTF) printf("Freeing %p\n", cast(size_t) p);
        assert (p);

        Pool*  pool;
        size_t pagenum;
        Bins   bin;
        size_t biti;

        // Find which page it is in
        pool = gcx.findPool(p);
        if (!pool)                              // if not one of ours
            return;                             // ignore

        pagenum = pool.pagenumOf(p);

        debug(PRINTF) printf("pool base = %p, PAGENUM = %d of %d, bin = %d\n", pool.baseAddr, pagenum, pool.npages, pool.pagetable[pagenum]);
        debug(PRINTF) if(pool.isLargeObject) printf("Block size = %d\n", pool.bPageOffsets[pagenum]);

        bin = cast(Bins)pool.pagetable[pagenum];

        // Verify that the pointer is at the beginning of a block,
        //  no action should be taken if p is an interior pointer
        if (bin > B_PAGE) // B_PAGEPLUS or B_FREE
            return;
        if ((sentinel_sub(p) - pool.baseAddr) & (binsize[bin] - 1))
            return;

        sentinel_Invariant(p);
        p = sentinel_sub(p);
        biti = cast(size_t)(p - pool.baseAddr) >> pool.shiftBy;

        pool.clrBits(biti, ~BlkAttr.NONE);

        if (pool.isLargeObject)              // if large alloc
        {
            assert(bin == B_PAGE);
            auto lpool = cast(LargeObjectPool*) pool;

            // Free pages
            size_t npages = lpool.bPageOffsets[pagenum];
            debug (MEMSTOMP) memset(p, 0xF2, npages * PAGESIZE);
            lpool.freePages(pagenum, npages);
        }
        else
        {   // Add to free list
            List *list = cast(List*)p;

            debug (MEMSTOMP) memset(p, 0xF2, binsize[bin]);

            list.next = gcx.bucket[bin];
            list.pool = pool;
            gcx.bucket[bin] = list;
        }

        gcx.log_free(sentinel_add(p));
    }


    /**
     * Returns the base address of the memory block containing p.  This value
     * is useful to determine whether p is an interior pointer, and the result
     * may be passed to routines such as sizeOf which may otherwise fail.  If p
     * references memory not originally allocated by this garbage collector, if
     * p is null, or if the garbage collector does not support this operation,
     * null will be returned.
     *
     * Params:
     *  p = A pointer to the root or the interior of a valid memory block or to
     *      null.
     *
     * Returns:
     *  The base address of the memory block referenced by p or null on error.
     */
    void* addrOf(void *p) nothrow
    {
        if (!p)
        {
            return null;
        }

        return runLocked!(addrOfNoSync, otherTime, numOthers)(p);
    }


    //
    // Implementation of addrOf.
    //
    void* addrOfNoSync(void *p) nothrow
    {
        if (!p) //Is this needed? addrOf does the exact same thing before this is called.
        {
            return null;
        }

        auto q = gcx.findBase(p);
        if (q)
            q = sentinel_add(q);
        return q;
    }


    /**
     * Returns the true size of the memory block referenced by p.  This value
     * represents the maximum number of bytes for which a call to realloc may
     * resize the existing block in place.  If p references memory not
     * originally allocated by this garbage collector, points to the interior
     * of a memory block, or if p is null, zero will be returned.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *
     * Returns:
     *  The size in bytes of the memory block referenced by p or zero on error.
     */
    size_t sizeOf(void *p) nothrow
    {
        if (!p)
        {
            return 0;
        }

        return runLocked!(sizeOfNoSync, otherTime, numOthers)(p);
    }


    //
    // Implementation of sizeOf.
    //
    private size_t sizeOfNoSync(void *p) nothrow
    {
        assert (p);

        debug (SENTINEL)
        {
            p = sentinel_sub(p);
            size_t size = gcx.findSize(p);

            // Check for interior pointer
            // This depends on:
            // 1) size is a power of 2 for less than PAGESIZE values
            // 2) base of memory pool is aligned on PAGESIZE boundary
            if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
                size = 0;
            return size ? size - SENTINEL_EXTRA : 0;
        }
        else
        {
            size_t size = gcx.findSize(p);

            // Check for interior pointer
            // This depends on:
            // 1) size is a power of 2 for less than PAGESIZE values
            // 2) base of memory pool is aligned on PAGESIZE boundary
            if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
                return 0;
            return size;
        }
    }


    /**
     * Returns aggregate information about the memory block containing p.  If p
     * references memory not originally allocated by this garbage collector, if
     * p is null, or if the garbage collector does not support this operation,
     * BlkInfo.init will be returned.  Typically, support for this operation
     * is dependent on support for addrOf.
     *
     * Params:
     *  p = A pointer to the root or the interior of a valid memory block or to
     *      null.
     *
     * Returns:
     *  Information regarding the memory block referenced by p or BlkInfo.init
     *  on error.
     */
    BlkInfo query(void *p) nothrow
    {
        if (!p)
        {
            BlkInfo i;
            return  i;
        }

        return runLocked!(queryNoSync, otherTime, numOthers)(p);
    }


    //
    // Implementation of query.
    //
    BlkInfo queryNoSync(void *p) nothrow
    {
        assert(p); //Is this needed?

        BlkInfo info = gcx.getInfo(p);
        debug(SENTINEL)
        {
            if (info.base)
            {
                info.base = sentinel_add(info.base);
                info.size = *sentinel_size(info.base);
            }
        }
        return info;
    }


    /**
     * Performs certain checks on a pointer. These checks will cause asserts to
     * fail unless the following conditions are met:
     *  1) The poiinter belongs to this memory pool.
     *  2) The pointer points to the start of an allocated piece of memory.
     *  3) The pointer is not on a free list.
     *
     * Params:
     *  p = The pointer to be checked.
     */
    void check(void *p) nothrow
    {
        if (!p)
        {
            return;
        }

        return runLocked!(checkNoSync, otherTime, numOthers)(p);
    }


    //
    // Implementation of check
    //
    private void checkNoSync(void *p) nothrow
    {
        assert(p);

        sentinel_Invariant(p);
        debug (PTRCHECK)
        {
            Pool*  pool;
            size_t pagenum;
            Bins   bin;
            size_t size;

            p = sentinel_sub(p);
            pool = gcx.findPool(p);
            assert(pool);
            pagenum = pool.pagenumOf(p);
            bin = cast(Bins)pool.pagetable[pagenum];
            assert(bin <= B_PAGE);
            size = binsize[bin];
            assert((cast(size_t)p & (size - 1)) == 0);

            debug (PTRCHECK2)
            {
                if (bin < B_PAGE)
                {
                    // Check that p is not on a free list
                    List *list;

                    for (list = gcx.bucket[bin]; list; list = list.next)
                    {
                        assert(cast(void*)list != p);
                    }
                }
            }
        }
    }


    /**
     * Adds an internal root pointing to the GC memory block referenced by p.
     * As a result, the block referenced by p itself and any blocks accessible
     * via it will be considered live until the root is removed again.
     *
     * If p is null, no operation is performed.
     *
     * Params:
     *  p = A pointer into a GC-managed memory block or null.
     */
    void addRoot(void *p) nothrow
    {
        if (!p)
        {
            return;
        }

        gcx.addRoot(p);
    }


    /**
     * Removes the memory block referenced by p from an internal list of roots
     * to be scanned during a collection.  If p is null or is not a value
     * previously passed to addRoot() then no operation is performed.
     *
     * Params:
     *  p = A pointer into a GC-managed memory block or null.
     */
    void removeRoot(void *p) nothrow
    {
        if (!p)
        {
            return;
        }

        gcx.removeRoot(p);
    }


    /**
     * Returns an interator allowing roots to be traversed via a foreach loop.
     */
    @property auto rootIter() @nogc
    {
        return &gcx.rootsApply;
    }


    /**
     * Adds $(D p[0 .. sz]) to the list of memory ranges to be scanned for
     * pointers during a collection. If p is null, no operation is performed.
     *
     * Note that $(D p[0 .. sz]) is treated as an opaque range of memory assumed
     * to be suitably managed by the caller. In particular, if p points into a
     * GC-managed memory block, addRange does $(I not) mark this block as live.
     *
     * Params:
     *  p  = A pointer to a valid memory address or to null.
     *  sz = The size in bytes of the block to add. If sz is zero then the
     *       no operation will occur. If p is null then sz must be zero.
     *  ti = TypeInfo to describe the memory. The GC might use this information
     *       to improve scanning for pointers or to call finalizers
     */
    void addRange(void *p, size_t sz, const TypeInfo ti = null) nothrow @nogc
    {
        if (!p || !sz)
        {
            return;
        }

        gcx.addRange(p, p + sz, ti);
    }


    /**
     * Removes the memory range starting at p from an internal list of ranges
     * to be scanned during a collection. If p is null or does not represent
     * a value previously passed to addRange() then no operation is
     * performed.
     *
     * Params:
     *  p  = A pointer to a valid memory address or to null.
     */
    void removeRange(void *p) nothrow @nogc
    {
        if (!p)
        {
            return;
        }

        gcx.removeRange(p);
    }


    /**
     * Returns an interator allowing ranges to be traversed via a foreach loop.
     */
    @property auto rangeIter() @nogc
    {
        return &gcx.rangesApply;
    }


    /**
     * Runs any finalizer that is located in address range of the
     * given code segment.  This is used before unloading shared
     * libraries.  All matching objects which have a finalizer in this
     * code segment are assumed to be dead, using them while or after
     * calling this method has undefined behavior.
     *
     * Params:
     *  segment = address range of a code segment.
     */
    void runFinalizers(in void[] segment) nothrow
    {
        static void go(Gcx* gcx, in void[] segment) nothrow
        {
            gcx.runFinalizers(segment);
        }
        return runLocked!(go, otherTime, numOthers)(gcx, segment);
    }


    /**
     * Begins a full collection, scanning all stack segments for roots, mark
     * accessible memory blocks as alive, and then to reclaim free space. This
     * action may need to suspend all running threads for at least part of the
     * collection process.
     *
     * Returns:
     *  The number of pages freed.
     */
    size_t fullCollect() nothrow
    {
        debug(PRINTF) printf("GC.fullCollect()\n");

        // Since a finalizer could launch a new thread, we always need to lock
        // when collecting.
        static size_t go(Gcx* gcx) nothrow
        {
            return gcx.fullcollect();
        }
        immutable result = runLocked!go(gcx);

        version (none)
        {
            GCStats stats;

            getStats(stats);
            debug(PRINTF) printf("poolsize = %zx, usedsize = %zx, freelistsize = %zx\n",
                    stats.poolsize, stats.usedsize, stats.freelistsize);
        }

        gcx.log_collect();
        return result;
    }


    /**
     * Begins a full collection while ignoring all stack segments for roots.
     * This action may need to suspend all running threads for at least part of
     * the collection process.
     */
    void fullCollectNoStack() nothrow
    {
        // Since a finalizer could launch a new thread, we always need to lock
        // when collecting.
        static size_t go(Gcx* gcx) nothrow
        {
            return gcx.fullcollect(true);
        }
        runLocked!go(gcx);
    }


    /**
     * Indicates that the managed memory space be minimized by returning free
     * physical memory to the operating system.  The amount of free memory
     * returned depends on the allocator design and on program behavior.
     */
    void minimize() nothrow
    {
        static void go(Gcx* gcx) nothrow
        {
            gcx.minimize();
        }
        runLocked!(go, otherTime, numOthers)(gcx);
    }


    /**
     * Retrieve statistics about garbage collection.
     * Useful for debugging and tuning.
     */
    void getStats(out GCStats stats) nothrow
    {
        return runLocked!(getStatsNoSync, otherTime, numOthers)(stats);
    }


    //
    // Implementation of getStats.
    //
    private void getStatsNoSync(out GCStats stats) nothrow
    {
        size_t psize = 0;
        size_t usize = 0;
        size_t flsize = 0;

        size_t n;
        size_t bsize = 0;

        memset(&stats, 0, GCStats.sizeof);

        for (n = 0; n < gcx.npools; n++)
        {   Pool *pool = gcx.pooltable[n];

            psize += pool.npages * PAGESIZE;
            for (size_t j = 0; j < pool.npages; j++)
            {
                Bins bin = cast(Bins)pool.pagetable[j];
                if (bin == B_FREE)
                    stats.freeblocks++;
                else if (bin == B_PAGE)
                    stats.pageblocks++;
                else if (bin < B_PAGE)
                    bsize += PAGESIZE;
            }
        }

        for (n = 0; n < B_PAGE; n++)
        {
            for (List *list = gcx.bucket[n]; list; list = list.next)
            {
                flsize += binsize[n];
            }
        }

        usize = bsize - flsize;

        stats.poolsize = psize;
        stats.usedsize = bsize - flsize;
        stats.freelistsize = flsize;
    }
}


/* ============================ Gcx =============================== */

enum
{   PAGESIZE =    4096,
    POOLSIZE =   (4096*256),
}


enum
{
    B_16,
    B_32,
    B_64,
    B_128,
    B_256,
    B_512,
    B_1024,
    B_2048,
    B_PAGE,             // start of large alloc
    B_PAGEPLUS,         // continuation of large alloc
    B_FREE,             // free page
    B_MAX
}


alias ubyte Bins;


struct List
{
    List *next;
    Pool *pool;
}


struct Range
{
    void *pbot;
    void *ptop;
    alias pbot this; // only consider pbot for relative ordering (opCmp)
}

struct Root
{
    void *proot;
    alias proot this;
}


immutable uint[B_MAX] binsize = [ 16,32,64,128,256,512,1024,2048,4096 ];
immutable size_t[B_MAX] notbinsize = [ ~(16-1),~(32-1),~(64-1),~(128-1),~(256-1),
                                ~(512-1),~(1024-1),~(2048-1),~(4096-1) ];

alias PageBits = GCBits.wordtype[PAGESIZE / 16 / GCBits.BITS_PER_WORD];
static assert(PAGESIZE % (GCBits.BITS_PER_WORD * 16) == 0);

private void set(ref PageBits bits, size_t i) @nogc pure nothrow
{
    assert(i < PageBits.sizeof * 8);
    bts(bits.ptr, i);
}

/* ============================ Gcx =============================== */

struct Gcx
{
    import core.internal.spinlock;
    auto rootsLock = shared(AlignedSpinLock)(SpinLock.Contention.brief);
    auto rangesLock = shared(AlignedSpinLock)(SpinLock.Contention.brief);
    Treap!Root roots;
    Treap!Range ranges;

    bool log; // turn on logging
    debug(INVARIANT) bool initialized;
    uint disabled; // turn off collections if >0

    import gc.pooltable;
    @property size_t npools() pure const nothrow { return pooltable.length; }
    PoolTable!Pool pooltable;

    List*[B_PAGE] bucket; // free list for each small size

    // run a collection when reaching those thresholds (number of used pages)
    float smallCollectThreshold, largeCollectThreshold;
    uint usedSmallPages, usedLargePages;
    // total number of mapped pages
    uint mappedPages;

    void initialize()
    {
        (cast(byte*)&this)[0 .. Gcx.sizeof] = 0;
        log_init();
        roots.initialize();
        ranges.initialize();
        smallCollectThreshold = largeCollectThreshold = 0.0f;
        usedSmallPages = usedLargePages = 0;
        mappedPages = 0;
        //printf("gcx = %p, self = %x\n", &this, self);
        debug(INVARIANT) initialized = true;
    }


    void Dtor()
    {
        if (GC.config.profile)
        {
            printf("\tNumber of collections:  %llu\n", cast(ulong)numCollections);
            printf("\tTotal GC prep time:  %lld milliseconds\n",
                   prepTime.total!("msecs"));
            printf("\tTotal mark time:  %lld milliseconds\n",
                   markTime.total!("msecs"));
            printf("\tTotal sweep time:  %lld milliseconds\n",
                   sweepTime.total!("msecs"));
            printf("\tTotal page recovery time:  %lld milliseconds\n",
                   recoverTime.total!("msecs"));
            long maxPause = maxPauseTime.total!("msecs");
            printf("\tMax Pause Time:  %lld milliseconds\n", maxPause);
            long gcTime = (recoverTime + sweepTime + markTime + prepTime).total!("msecs");
            printf("\tGrand total GC time:  %lld milliseconds\n", gcTime);
            long pauseTime = (markTime + prepTime).total!("msecs");

            char[30] apitxt;
            apitxt[0] = 0;
            debug(PROFILE_API) if (GC.config.profile > 1)
            {
                static Duration toDuration(long dur)
                {
                    return MonoTime(dur) - MonoTime(0);
                }

                printf("\n");
                printf("\tmalloc:  %llu calls, %lld ms\n", cast(ulong)numMallocs, toDuration(mallocTime).total!"msecs");
                printf("\trealloc: %llu calls, %lld ms\n", cast(ulong)numReallocs, toDuration(reallocTime).total!"msecs");
                printf("\tfree:    %llu calls, %lld ms\n", cast(ulong)numFrees, toDuration(freeTime).total!"msecs");
                printf("\textend:  %llu calls, %lld ms\n", cast(ulong)numExtends, toDuration(extendTime).total!"msecs");
                printf("\tother:   %llu calls, %lld ms\n", cast(ulong)numOthers, toDuration(otherTime).total!"msecs");
                printf("\tlock time: %lld ms\n", toDuration(lockTime).total!"msecs");

                long apiTime = mallocTime + reallocTime + freeTime + extendTime + otherTime + lockTime;
                printf("\tGC API: %lld ms\n", toDuration(apiTime).total!"msecs");
                sprintf(apitxt.ptr, " API%5ld ms", toDuration(apiTime).total!"msecs");
            }

            printf("GC summary:%5lld MB,%5lld GC%5lld ms, Pauses%5lld ms <%5lld ms%s\n",
                   cast(long) maxPoolMemory >> 20, cast(ulong)numCollections, gcTime,
                   pauseTime, maxPause, apitxt.ptr);
        }

        debug(INVARIANT) initialized = false;

        for (size_t i = 0; i < npools; i++)
        {
            Pool *pool = pooltable[i];
            mappedPages -= pool.npages;
            pool.Dtor();
            cstdlib.free(pool);
        }
        assert(!mappedPages);
        pooltable.Dtor();

        roots.removeAll();
        ranges.removeAll();
        toscan.reset();
    }


    void Invariant() const { }

    debug(INVARIANT)
    invariant()
    {
        if (initialized)
        {
            //printf("Gcx.invariant(): this = %p\n", &this);
            pooltable.Invariant();

            rangesLock.lock();
            foreach (range; ranges)
            {
                assert(range.pbot);
                assert(range.ptop);
                assert(range.pbot <= range.ptop);
            }
            rangesLock.unlock();

            for (size_t i = 0; i < B_PAGE; i++)
            {
                for (auto list = cast(List*)bucket[i]; list; list = list.next)
                {
                }
            }
        }
    }


    /**
     *
     */
    void addRoot(void *p) nothrow
    {
        rootsLock.lock();
        scope (failure) rootsLock.unlock();
        roots.insert(Root(p));
        rootsLock.unlock();
    }


    /**
     *
     */
    void removeRoot(void *p) nothrow
    {
        rootsLock.lock();
        scope (failure) rootsLock.unlock();
        roots.remove(Root(p));
        rootsLock.unlock();
    }


    /**
     *
     */
    int rootsApply(scope int delegate(ref Root) nothrow dg) nothrow
    {
        rootsLock.lock();
        scope (failure) rootsLock.unlock();
        auto ret = roots.opApply(dg);
        rootsLock.unlock();
        return ret;
    }


    /**
     *
     */
    void addRange(void *pbot, void *ptop, const TypeInfo ti) nothrow @nogc
    {
        //debug(PRINTF) printf("Thread %x ", pthread_self());
        debug(PRINTF) printf("%p.Gcx::addRange(%p, %p)\n", &this, pbot, ptop);
        rangesLock.lock();
        scope (failure) rangesLock.unlock();
        ranges.insert(Range(pbot, ptop));
        rangesLock.unlock();
    }


    /**
     *
     */
    void removeRange(void *pbot) nothrow @nogc
    {
        //debug(PRINTF) printf("Thread %x ", pthread_self());
        debug(PRINTF) printf("Gcx.removeRange(%p)\n", pbot);
        rangesLock.lock();
        scope (failure) rangesLock.unlock();
        ranges.remove(Range(pbot, pbot)); // only pbot is used, see Range.opCmp
        rangesLock.unlock();

        // debug(PRINTF) printf("Wrong thread\n");
        // This is a fatal error, but ignore it.
        // The problem is that we can get a Close() call on a thread
        // other than the one the range was allocated on.
        //assert(zero);
    }

    /**
     *
     */
    int rangesApply(scope int delegate(ref Range) nothrow dg) nothrow
    {
        rangesLock.lock();
        scope (failure) rangesLock.unlock();
        auto ret = ranges.opApply(dg);
        rangesLock.unlock();
        return ret;
    }


    /**
     *
     */
    void runFinalizers(in void[] segment) nothrow
    {
        GC.inFinalizer = true;
        scope (failure) GC.inFinalizer = false;

        foreach (pool; pooltable[0 .. npools])
        {
            if (!pool.finals.nbits) continue;

            if (pool.isLargeObject)
            {
                auto lpool = cast(LargeObjectPool*) pool;
                lpool.runFinalizers(segment);
            }
            else
            {
                auto spool = cast(SmallObjectPool*) pool;
                spool.runFinalizers(segment);
            }
        }
        GC.inFinalizer = false;
    }

    Pool* findPool(void* p) pure nothrow
    {
        return pooltable.findPool(p);
    }

    /**
     * Find base address of block containing pointer p.
     * Returns null if not a gc'd pointer
     */
    void* findBase(void *p) nothrow
    {
        Pool *pool;

        pool = findPool(p);
        if (pool)
        {
            size_t offset = cast(size_t)(p - pool.baseAddr);
            size_t pn = offset / PAGESIZE;
            Bins   bin = cast(Bins)pool.pagetable[pn];

            // Adjust bit to be at start of allocated memory block
            if (bin <= B_PAGE)
            {
                return pool.baseAddr + (offset & notbinsize[bin]);
            }
            else if (bin == B_PAGEPLUS)
            {
                auto pageOffset = pool.bPageOffsets[pn];
                offset -= pageOffset * PAGESIZE;
                pn -= pageOffset;

                return pool.baseAddr + (offset & (offset.max ^ (PAGESIZE-1)));
            }
            else
            {
                // we are in a B_FREE page
                assert(bin == B_FREE);
                return null;
            }
        }
        return null;
    }


    /**
     * Find size of pointer p.
     * Returns 0 if not a gc'd pointer
     */
    size_t findSize(void *p) nothrow
    {
        Pool* pool = findPool(p);
        if (pool)
            return pool.slGetSize(p);
        return 0;
    }

    /**
     *
     */
    BlkInfo getInfo(void* p) nothrow
    {
        Pool* pool = findPool(p);
        if (pool)
            return pool.slGetInfo(p);
        return BlkInfo();
    }

    /**
     * Computes the bin table using CTFE.
     */
    static byte[2049] ctfeBins() nothrow
    {
        byte[2049] ret;
        size_t p = 0;
        for (Bins b = B_16; b <= B_2048; b++)
            for ( ; p <= binsize[b]; p++)
                ret[p] = b;

        return ret;
    }

    static const byte[2049] binTable = ctfeBins();

    /**
     * Allocate a new pool of at least size bytes.
     * Sort it into pooltable[].
     * Mark all memory in the pool as B_FREE.
     * Return the actual number of bytes reserved or 0 on error.
     */
    size_t reserve(size_t size) nothrow
    {
        size_t npages = (size + PAGESIZE - 1) / PAGESIZE;

        // Assume reserve() is for small objects.
        Pool*  pool = newPool(npages, false);

        if (!pool)
            return 0;
        return pool.npages * PAGESIZE;
    }

    /**
     * Update the thresholds for when to collect the next time
     */
    void updateCollectThresholds() nothrow
    {
        static float max(float a, float b) nothrow
        {
            return a >= b ? a : b;
        }

        // instantly increases, slowly decreases
        static float smoothDecay(float oldVal, float newVal) nothrow
        {
            // decay to 63.2% of newVal over 5 collections
            // http://en.wikipedia.org/wiki/Low-pass_filter#Simple_infinite_impulse_response_filter
            enum alpha = 1.0 / (5 + 1);
            immutable decay = (newVal - oldVal) * alpha + oldVal;
            return max(newVal, decay);
        }

        immutable smTarget = usedSmallPages * GC.config.heapSizeFactor;
        smallCollectThreshold = smoothDecay(smallCollectThreshold, smTarget);
        immutable lgTarget = usedLargePages * GC.config.heapSizeFactor;
        largeCollectThreshold = smoothDecay(largeCollectThreshold, lgTarget);
    }

    /**
     * Minimizes physical memory usage by returning free pools to the OS.
     */
    void minimize() nothrow
    {
        debug(PRINTF) printf("Minimizing.\n");

        foreach (pool; pooltable.minimize())
        {
            debug(PRINTF) printFreeInfo(pool);
            mappedPages -= pool.npages;
            pool.Dtor();
            cstdlib.free(pool);
        }

        debug(PRINTF) printf("Done minimizing.\n");
    }

    private @property bool lowMem() const nothrow
    {
        return isLowOnMem(mappedPages * PAGESIZE);
    }

    void* alloc(size_t size, ref size_t alloc_size, uint bits) nothrow
    {
        return size <= 2048 ? smallAlloc(binTable[size], alloc_size, bits)
                            : bigAlloc(size, alloc_size, bits);
    }

    void* smallAlloc(Bins bin, ref size_t alloc_size, uint bits) nothrow
    {
        alloc_size = binsize[bin];

        void* p;
        bool tryAlloc() nothrow
        {
            if (!bucket[bin])
            {
                bucket[bin] = allocPage(bin);
                if (!bucket[bin])
                    return false;
            }
            p = bucket[bin];
            return true;
        }

        if (!tryAlloc())
        {
            if (!lowMem && (disabled || usedSmallPages < smallCollectThreshold))
            {
                // disabled or threshold not reached => allocate a new pool instead of collecting
                if (!newPool(1, false))
                {
                    // out of memory => try to free some memory
                    fullcollect();
                    if (lowMem) minimize();
                }
            }
            else
            {
                fullcollect();
                if (lowMem) minimize();
            }
            // tryAlloc will succeed if a new pool was allocated above, if it fails allocate a new pool now
            if (!tryAlloc() && (!newPool(1, false) || !tryAlloc()))
                // out of luck or memory
                onOutOfMemoryErrorNoGC();
        }
        assert(p !is null);

        // Return next item from free list
        bucket[bin] = (cast(List*)p).next;
        auto pool = (cast(List*)p).pool;
        if (bits)
            pool.setBits((p - pool.baseAddr) >> pool.shiftBy, bits);
        //debug(PRINTF) printf("\tmalloc => %p\n", p);
        debug (MEMSTOMP) memset(p, 0xF0, alloc_size);
        return p;
    }

    /**
     * Allocate a chunk of memory that is larger than a page.
     * Return null if out of memory.
     */
    void* bigAlloc(size_t size, ref size_t alloc_size, uint bits, const TypeInfo ti = null) nothrow
    {
        debug(PRINTF) printf("In bigAlloc.  Size:  %d\n", size);

        LargeObjectPool* pool;
        size_t pn;
        immutable npages = (size + PAGESIZE - 1) / PAGESIZE;
        if (npages == 0)
            onOutOfMemoryErrorNoGC(); // size just below size_t.max requested

        bool tryAlloc() nothrow
        {
            foreach (p; pooltable[0 .. npools])
            {
                if (!p.isLargeObject || p.freepages < npages)
                    continue;
                auto lpool = cast(LargeObjectPool*) p;
                if ((pn = lpool.allocPages(npages)) == OPFAIL)
                    continue;
                pool = lpool;
                return true;
            }
            return false;
        }

        bool tryAllocNewPool() nothrow
        {
            pool = cast(LargeObjectPool*) newPool(npages, true);
            if (!pool) return false;
            pn = pool.allocPages(npages);
            assert(pn != OPFAIL);
            return true;
        }

        if (!tryAlloc())
        {
            if (!lowMem && (disabled || usedLargePages < largeCollectThreshold))
            {
                // disabled or threshold not reached => allocate a new pool instead of collecting
                if (!tryAllocNewPool())
                {
                    // disabled but out of memory => try to free some memory
                    fullcollect();
                    minimize();
                }
            }
            else
            {
                fullcollect();
                minimize();
            }
            // If alloc didn't yet succeed retry now that we collected/minimized
            if (!pool && !tryAlloc() && !tryAllocNewPool())
                // out of luck or memory
                return null;
        }
        assert(pool);

        debug(PRINTF) printFreeInfo(&pool.base);
        pool.pagetable[pn] = B_PAGE;
        if (npages > 1)
            memset(&pool.pagetable[pn + 1], B_PAGEPLUS, npages - 1);
        pool.updateOffsets(pn);
        usedLargePages += npages;
        pool.freepages -= npages;

        debug(PRINTF) printFreeInfo(&pool.base);

        auto p = pool.baseAddr + pn * PAGESIZE;
        debug(PRINTF) printf("Got large alloc:  %p, pt = %d, np = %d\n", p, pool.pagetable[pn], npages);
        debug (MEMSTOMP) memset(p, 0xF1, size);
        alloc_size = npages * PAGESIZE;
        //debug(PRINTF) printf("\tp = %p\n", p);

        if (bits)
            pool.setBits(pn, bits);
        return p;
    }


    /**
     * Allocate a new pool with at least npages in it.
     * Sort it into pooltable[].
     * Return null if failed.
     */
    Pool *newPool(size_t npages, bool isLargeObject) nothrow
    {
        //debug(PRINTF) printf("************Gcx::newPool(npages = %d)****************\n", npages);

        // Minimum of POOLSIZE
        size_t minPages = (GC.config.minPoolSize << 20) / PAGESIZE;
        if (npages < minPages)
            npages = minPages;
        else if (npages > minPages)
        {   // Give us 150% of requested size, so there's room to extend
            auto n = npages + (npages >> 1);
            if (n < size_t.max/PAGESIZE)
                npages = n;
        }

        // Allocate successively larger pools up to 8 megs
        if (npools)
        {   size_t n;

            n = GC.config.minPoolSize + GC.config.incPoolSize * npools;
            if (n > GC.config.maxPoolSize)
                n = GC.config.maxPoolSize;                 // cap pool size
            n *= (1 << 20) / PAGESIZE;                     // convert MB to pages
            if (npages < n)
                npages = n;
        }

        //printf("npages = %d\n", npages);

        auto pool = cast(Pool *)cstdlib.calloc(1, isLargeObject ? LargeObjectPool.sizeof : SmallObjectPool.sizeof);
        if (pool)
        {
            pool.initialize(npages, isLargeObject);
            if (!pool.baseAddr || !pooltable.insert(pool))
            {
                pool.Dtor();
                cstdlib.free(pool);
                return null;
            }
        }

        mappedPages += npages;

        if (GC.config.profile)
        {
            if (mappedPages * PAGESIZE > maxPoolMemory)
                maxPoolMemory = mappedPages * PAGESIZE;
        }
        return pool;
    }

    /**
    * Allocate a page of bin's.
    * Returns:
    *           head of a single linked list of new entries
    */
    List* allocPage(Bins bin) nothrow
    {
        //debug(PRINTF) printf("Gcx::allocPage(bin = %d)\n", bin);
        for (size_t n = 0; n < npools; n++)
        {
            Pool* pool = pooltable[n];
            if(pool.isLargeObject)
                continue;
            if (List* p = (cast(SmallObjectPool*)pool).allocPage(bin))
            {
                ++usedSmallPages;
                return p;
            }
        }
        return null;
    }

    static struct ToScanStack
    {
    nothrow:
        @disable this(this);

        void reset()
        {
            _length = 0;
            os_mem_unmap(_p, _cap * Range.sizeof);
            _p = null;
            _cap = 0;
        }

        void push(Range rng)
        {
            if (_length == _cap) grow();
            _p[_length++] = rng;
        }

        Range pop()
        in { assert(!empty); }
        body
        {
            return _p[--_length];
        }

        ref inout(Range) opIndex(size_t idx) inout
        in { assert(idx < _length); }
        body
        {
            return _p[idx];
        }

        @property size_t length() const { return _length; }
        @property bool empty() const { return !length; }

    private:
        void grow()
        {
            enum initSize = 64 * 1024; // Windows VirtualAlloc granularity
            immutable ncap = _cap ? 2 * _cap : initSize / Range.sizeof;
            auto p = cast(Range*)os_mem_map(ncap * Range.sizeof);
            if (p is null) onOutOfMemoryErrorNoGC();
            if (_p !is null)
            {
                p[0 .. _length] = _p[0 .. _length];
                os_mem_unmap(_p, _cap * Range.sizeof);
            }
            _p = p;
            _cap = ncap;
        }

        size_t _length;
        Range* _p;
        size_t _cap;
    }

    ToScanStack toscan;

    /**
     * Search a range of memory values and mark any pointers into the GC pool.
     */
    void mark(void *pbot, void *ptop) nothrow
    {
        void **p1 = cast(void **)pbot;
        void **p2 = cast(void **)ptop;

        // limit the amount of ranges added to the toscan stack
        enum FANOUT_LIMIT = 32;
        size_t stackPos;
        Range[FANOUT_LIMIT] stack = void;

    Lagain:
        size_t pcache = 0;

        // let dmd allocate a register for this.pools
        auto pools = pooltable.pools;
        const highpool = pooltable.npools - 1;
        const minAddr = pooltable.minAddr;
        const maxAddr = pooltable.maxAddr;

        //printf("marking range: [%p..%p] (%#zx)\n", p1, p2, cast(size_t)p2 - cast(size_t)p1);
    Lnext: for (; p1 < p2; p1++)
        {
            auto p = cast(byte *)(*p1);

            //if (log) debug(PRINTF) printf("\tmark %p\n", p);
            if (p >= minAddr && p < maxAddr)
            {
                if ((cast(size_t)p & ~cast(size_t)(PAGESIZE-1)) == pcache)
                    continue;

                Pool* pool = void;
                size_t low = 0;
                size_t high = highpool;
                while (true)
                {
                    size_t mid = (low + high) >> 1;
                    pool = pools[mid];
                    if (p < pool.baseAddr)
                        high = mid - 1;
                    else if (p >= pool.topAddr)
                        low = mid + 1;
                    else break;

                    if (low > high)
                        continue Lnext;
                }
                size_t offset = cast(size_t)(p - pool.baseAddr);
                size_t biti = void;
                size_t pn = offset / PAGESIZE;
                Bins   bin = cast(Bins)pool.pagetable[pn];
                void* base = void;

                //debug(PRINTF) printf("\t\tfound pool %p, base=%p, pn = %zd, bin = %d, biti = x%x\n", pool, pool.baseAddr, pn, bin, biti);

                // Adjust bit to be at start of allocated memory block
                if (bin < B_PAGE)
                {
                    // We don't care abou setting pointsToBase correctly
                    // because it's ignored for small object pools anyhow.
                    auto offsetBase = offset & notbinsize[bin];
                    biti = offsetBase >> pool.shiftBy;
                    base = pool.baseAddr + offsetBase;
                    //debug(PRINTF) printf("\t\tbiti = x%x\n", biti);

                    if (!pool.mark.set(biti) && !pool.noscan.test(biti)) {
                        stack[stackPos++] = Range(base, base + binsize[bin]);
                        if (stackPos == stack.length)
                            break;
                    }
                }
                else if (bin == B_PAGE)
                {
                    auto offsetBase = offset & notbinsize[bin];
                    base = pool.baseAddr + offsetBase;
                    biti = offsetBase >> pool.shiftBy;
                    //debug(PRINTF) printf("\t\tbiti = x%x\n", biti);

                    pcache = cast(size_t)p & ~cast(size_t)(PAGESIZE-1);

                    // For the NO_INTERIOR attribute.  This tracks whether
                    // the pointer is an interior pointer or points to the
                    // base address of a block.
                    bool pointsToBase = (base == sentinel_sub(p));
                    if(!pointsToBase && pool.nointerior.nbits && pool.nointerior.test(biti))
                        continue;

                    if (!pool.mark.set(biti) && !pool.noscan.test(biti)) {
                        stack[stackPos++] = Range(base, base + pool.bPageOffsets[pn] * PAGESIZE);
                        if (stackPos == stack.length)
                            break;
                    }
                }
                else if (bin == B_PAGEPLUS)
                {
                    pn -= pool.bPageOffsets[pn];
                    base = pool.baseAddr + (pn * PAGESIZE);
                    biti = pn * (PAGESIZE >> pool.shiftBy);

                    pcache = cast(size_t)p & ~cast(size_t)(PAGESIZE-1);
                    if(pool.nointerior.nbits && pool.nointerior.test(biti))
                        continue;

                    if (!pool.mark.set(biti) && !pool.noscan.test(biti)) {
                        stack[stackPos++] = Range(base, base + pool.bPageOffsets[pn] * PAGESIZE);
                        if (stackPos == stack.length)
                            break;
                    }
                }
                else
                {
                    // Don't mark bits in B_FREE pages
                    assert(bin == B_FREE);
                    continue;
                }
            }
        }

        Range next=void;
        if (p1 < p2)
        {
            // local stack is full, push it to the global stack
            assert(stackPos == stack.length);
            toscan.push(Range(p1, p2));
            // reverse order for depth-first-order traversal
            foreach_reverse (ref rng; stack[0 .. $ - 1])
                toscan.push(rng);
            stackPos = 0;
            next = stack[$-1];
        }
        else if (stackPos)
        {
            // pop range from local stack and recurse
            next = stack[--stackPos];
        }
        else if (!toscan.empty)
        {
            // pop range from global stack and recurse
            next = toscan.pop();
        }
        else
        {
            // nothing more to do
            return;
        }
        p1 = cast(void**)next.pbot;
        p2 = cast(void**)next.ptop;
        // printf("  pop [%p..%p] (%#zx)\n", p1, p2, cast(size_t)p2 - cast(size_t)p1);
        goto Lagain;
    }

    // collection step 1: prepare freebits and mark bits
    void prepare() nothrow
    {
        size_t n;
        Pool*  pool;

        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            pool.mark.zero();
            if(!pool.isLargeObject) pool.freebits.zero();
        }

        debug(COLLECT_PRINTF) printf("Set bits\n");

        // Mark each free entry, so it doesn't get scanned
        for (n = 0; n < B_PAGE; n++)
        {
            for (List *list = bucket[n]; list; list = list.next)
            {
                pool = list.pool;
                assert(pool);
                pool.freebits.set(cast(size_t)(cast(byte*)list - pool.baseAddr) / 16);
            }
        }

        debug(COLLECT_PRINTF) printf("Marked free entries.\n");

        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            if(!pool.isLargeObject)
            {
                pool.mark.copy(&pool.freebits);
            }
        }
    }

    // collection step 2: mark roots and heap
    void markAll(bool nostack) nothrow
    {
        if (!nostack)
        {
            debug(COLLECT_PRINTF) printf("\tscan stacks.\n");
            // Scan stacks and registers for each paused thread
            thread_scanAll(&mark);
        }

        // Scan roots[]
        debug(COLLECT_PRINTF) printf("\tscan roots[]\n");
        foreach (root; roots)
        {
            mark(cast(void*)&root.proot, cast(void*)(&root.proot + 1));
        }

        // Scan ranges[]
        debug(COLLECT_PRINTF) printf("\tscan ranges[]\n");
        //log++;
        foreach (range; ranges)
        {
            debug(COLLECT_PRINTF) printf("\t\t%p .. %p\n", range.pbot, range.ptop);
            mark(range.pbot, range.ptop);
        }
        //log--;
    }

    // collection step 3: free all unreferenced objects
    size_t sweep() nothrow
    {
        // Free up everything not marked
        debug(COLLECT_PRINTF) printf("\tfree'ing\n");
        size_t freedLargePages;
        size_t freed;
        for (size_t n = 0; n < npools; n++)
        {
            size_t pn;
            Pool* pool = pooltable[n];

            if(pool.isLargeObject)
            {
                for(pn = 0; pn < pool.npages; pn++)
                {
                    Bins bin = cast(Bins)pool.pagetable[pn];
                    if(bin > B_PAGE) continue;
                    size_t biti = pn;

                    if (!pool.mark.test(biti))
                    {
                        byte *p = pool.baseAddr + pn * PAGESIZE;
                        void* q = sentinel_add(p);
                        sentinel_Invariant(q);

                        if (pool.finals.nbits && pool.finals.clear(biti))
                        {
                            size_t size = pool.bPageOffsets[pn] * PAGESIZE - SENTINEL_EXTRA;
                            uint attr = pool.getBits(biti);
                            rt_finalizeFromGC(q, size, attr);
                        }

                        pool.clrBits(biti, ~BlkAttr.NONE ^ BlkAttr.FINALIZE);

                        debug(COLLECT_PRINTF) printf("\tcollecting big %p\n", p);
                        log_free(q);
                        pool.pagetable[pn] = B_FREE;
                        if(pn < pool.searchStart) pool.searchStart = pn;
                        freedLargePages++;
                        pool.freepages++;

                        debug (MEMSTOMP) memset(p, 0xF3, PAGESIZE);
                        while (pn + 1 < pool.npages && pool.pagetable[pn + 1] == B_PAGEPLUS)
                        {
                            pn++;
                            pool.pagetable[pn] = B_FREE;

                            // Don't need to update searchStart here because
                            // pn is guaranteed to be greater than last time
                            // we updated it.

                            pool.freepages++;
                            freedLargePages++;

                            debug (MEMSTOMP)
                            {   p += PAGESIZE;
                                memset(p, 0xF3, PAGESIZE);
                            }
                        }
                        pool.largestFree = pool.freepages; // invalidate
                    }
                }
            }
            else
            {

                for (pn = 0; pn < pool.npages; pn++)
                {
                    Bins bin = cast(Bins)pool.pagetable[pn];

                    if (bin < B_PAGE)
                    {
                        immutable size = binsize[bin];
                        byte *p = pool.baseAddr + pn * PAGESIZE;
                        byte *ptop = p + PAGESIZE;
                        immutable base = pn * (PAGESIZE/16);
                        immutable bitstride = size / 16;

                        bool freeBits;
                        PageBits toFree;

                        for (size_t i; p < ptop; p += size, i += bitstride)
                        {
                            immutable biti = base + i;

                            if (!pool.mark.test(biti))
                            {
                                void* q = sentinel_add(p);
                                sentinel_Invariant(q);

                                if (pool.finals.nbits && pool.finals.test(biti))
                                    rt_finalizeFromGC(q, size - SENTINEL_EXTRA, pool.getBits(biti));

                                freeBits = true;
                                toFree.set(i);

                                debug(COLLECT_PRINTF) printf("\tcollecting %p\n", p);
                                log_free(sentinel_add(p));

                                debug (MEMSTOMP) memset(p, 0xF3, size);

                                freed += size;
                            }
                        }

                        if (freeBits)
                            pool.freePageBits(pn, toFree);
                    }
                }
            }
        }

        assert(freedLargePages <= usedLargePages);
        usedLargePages -= freedLargePages;
        debug(COLLECT_PRINTF) printf("\tfree'd %u bytes, %u pages from %u pools\n", freed, freedLargePages, npools);
        return freedLargePages;
    }

    // collection step 4: recover pages with no live objects, rebuild free lists
    size_t recover() nothrow
    {
        // init tail list
        List**[B_PAGE] tail = void;
        foreach (i, ref next; tail)
            next = &bucket[i];

        // Free complete pages, rebuild free list
        debug(COLLECT_PRINTF) printf("\tfree complete pages\n");
        size_t freedSmallPages;
        for (size_t n = 0; n < npools; n++)
        {
            size_t pn;
            Pool* pool = pooltable[n];

            if(pool.isLargeObject)
                continue;

            for (pn = 0; pn < pool.npages; pn++)
            {
                Bins   bin = cast(Bins)pool.pagetable[pn];
                size_t biti;
                size_t u;

                if (bin < B_PAGE)
                {
                    size_t size = binsize[bin];
                    size_t bitstride = size / 16;
                    size_t bitbase = pn * (PAGESIZE / 16);
                    size_t bittop = bitbase + (PAGESIZE / 16);
                    byte*  p;

                    biti = bitbase;
                    for (biti = bitbase; biti < bittop; biti += bitstride)
                    {
                        if (!pool.freebits.test(biti))
                            goto Lnotfree;
                    }
                    pool.pagetable[pn] = B_FREE;
                    if(pn < pool.searchStart) pool.searchStart = pn;
                    pool.freepages++;
                    freedSmallPages++;
                    continue;

                Lnotfree:
                    p = pool.baseAddr + pn * PAGESIZE;
                    for (u = 0; u < PAGESIZE; u += size)
                    {
                        biti = bitbase + u / 16;
                        if (!pool.freebits.test(biti))
                            continue;
                        auto elem = cast(List *)(p + u);
                        elem.pool = pool;
                        *tail[bin] = elem;
                        tail[bin] = &elem.next;
                    }
                }
            }
        }
        // terminate tail list
        foreach (ref next; tail)
            *next = null;

        assert(freedSmallPages <= usedSmallPages);
        usedSmallPages -= freedSmallPages;
        debug(COLLECT_PRINTF) printf("\trecovered pages = %d\n", freedSmallPages);
        return freedSmallPages;
    }

    /**
     * Return number of full pages free'd.
     */
    size_t fullcollect(bool nostack = false) nothrow
    {
        MonoTime start, stop, begin;

        if (GC.config.profile)
        {
            begin = start = currTime;
        }

        debug(COLLECT_PRINTF) printf("Gcx.fullcollect()\n");
        //printf("\tpool address range = %p .. %p\n", minAddr, maxAddr);

        {
            // lock roots and ranges around suspending threads b/c they're not reentrant safe
            rangesLock.lock();
            rootsLock.lock();
            scope (exit)
            {
                rangesLock.unlock();
                rootsLock.unlock();
            }
            thread_suspendAll();

            prepare();

            if (GC.config.profile)
            {
                stop = currTime;
                prepTime += (stop - start);
                start = stop;
            }

            markAll(nostack);

            thread_processGCMarks(&isMarked);
            thread_resumeAll();
        }

        if (GC.config.profile)
        {
            stop = currTime;
            markTime += (stop - start);
            Duration pause = stop - begin;
            if (pause > maxPauseTime)
                maxPauseTime = pause;
            start = stop;
        }

        GC.inFinalizer = true;
        size_t freedLargePages=void;
        {
            scope (failure) GC.inFinalizer = false;
            freedLargePages = sweep();
            GC.inFinalizer = false;
        }

        if (GC.config.profile)
        {
            stop = currTime;
            sweepTime += (stop - start);
            start = stop;
        }

        immutable freedSmallPages = recover();

        if (GC.config.profile)
        {
            stop = currTime;
            recoverTime += (stop - start);
            ++numCollections;
        }

        updateCollectThresholds();

        return freedLargePages + freedSmallPages;
    }

    /**
     * Returns true if the addr lies within a marked block.
     *
     * Warning! This should only be called while the world is stopped inside
     * the fullcollect function.
     */
    int isMarked(void *addr) nothrow
    {
        // first, we find the Pool this block is in, then check to see if the
        // mark bit is clear.
        auto pool = findPool(addr);
        if(pool)
        {
            auto offset = cast(size_t)(addr - pool.baseAddr);
            auto pn = offset / PAGESIZE;
            auto bins = cast(Bins)pool.pagetable[pn];
            size_t biti = void;
            if(bins <= B_PAGE)
            {
                biti = (offset & notbinsize[bins]) >> pool.shiftBy;
            }
            else if(bins == B_PAGEPLUS)
            {
                pn -= pool.bPageOffsets[pn];
                biti = pn * (PAGESIZE >> pool.shiftBy);
            }
            else // bins == B_FREE
            {
                assert(bins == B_FREE);
                return IsMarked.no;
            }
            return pool.mark.test(biti) ? IsMarked.yes : IsMarked.no;
        }
        return IsMarked.unknown;
    }


    /***** Leak Detector ******/


    debug (LOGGING)
    {
        LogArray current;
        LogArray prev;


        void log_init()
        {
            //debug(PRINTF) printf("+log_init()\n");
            current.reserve(1000);
            prev.reserve(1000);
            //debug(PRINTF) printf("-log_init()\n");
        }


        void log_malloc(void *p, size_t size) nothrow
        {
            //debug(PRINTF) printf("+log_malloc(p = %p, size = %zd)\n", p, size);
            Log log;

            log.p = p;
            log.size = size;
            log.line = GC.line;
            log.file = GC.file;
            log.parent = null;

            GC.line = 0;
            GC.file = null;

            current.push(log);
            //debug(PRINTF) printf("-log_malloc()\n");
        }


        void log_free(void *p) nothrow
        {
            //debug(PRINTF) printf("+log_free(%p)\n", p);
            auto i = current.find(p);
            if (i == OPFAIL)
            {
                debug(PRINTF) printf("free'ing unallocated memory %p\n", p);
            }
            else
                current.remove(i);
            //debug(PRINTF) printf("-log_free()\n");
        }


        void log_collect() nothrow
        {
            //debug(PRINTF) printf("+log_collect()\n");
            // Print everything in current that is not in prev

            debug(PRINTF) printf("New pointers this cycle: --------------------------------\n");
            size_t used = 0;
            for (size_t i = 0; i < current.dim; i++)
            {
                auto j = prev.find(current.data[i].p);
                if (j == OPFAIL)
                    current.data[i].print();
                else
                    used++;
            }

            debug(PRINTF) printf("All roots this cycle: --------------------------------\n");
            for (size_t i = 0; i < current.dim; i++)
            {
                void* p = current.data[i].p;
                if (!findPool(current.data[i].parent))
                {
                    auto j = prev.find(current.data[i].p);
                    debug(PRINTF) printf(j == OPFAIL ? "N" : " ");
                    current.data[i].print();
                }
            }

            debug(PRINTF) printf("Used = %d-------------------------------------------------\n", used);
            prev.copy(&current);

            debug(PRINTF) printf("-log_collect()\n");
        }


        void log_parent(void *p, void *parent) nothrow
        {
            //debug(PRINTF) printf("+log_parent()\n");
            auto i = current.find(p);
            if (i == OPFAIL)
            {
                debug(PRINTF) printf("parent'ing unallocated memory %p, parent = %p\n", p, parent);
                Pool *pool;
                pool = findPool(p);
                assert(pool);
                size_t offset = cast(size_t)(p - pool.baseAddr);
                size_t biti;
                size_t pn = offset / PAGESIZE;
                Bins bin = cast(Bins)pool.pagetable[pn];
                biti = (offset & notbinsize[bin]);
                debug(PRINTF) printf("\tbin = %d, offset = x%x, biti = x%x\n", bin, offset, biti);
            }
            else
            {
                current.data[i].parent = parent;
            }
            //debug(PRINTF) printf("-log_parent()\n");
        }

    }
    else
    {
        void log_init() nothrow { }
        void log_malloc(void *p, size_t size) nothrow { }
        void log_free(void *p) nothrow { }
        void log_collect() nothrow { }
        void log_parent(void *p, void *parent) nothrow { }
    }
}

/* ============================ Pool  =============================== */

struct Pool
{
    byte* baseAddr;
    byte* topAddr;
    GCBits mark;        // entries already scanned, or should not be scanned
    GCBits freebits;    // entries that are on the free list
    GCBits finals;      // entries that need finalizer run on them
    GCBits structFinals;// struct entries that need a finalzier run on them
    GCBits noscan;      // entries that should not be scanned
    GCBits appendable;  // entries that are appendable
    GCBits nointerior;  // interior pointers should be ignored.
                        // Only implemented for large object pools.
    size_t npages;
    size_t freepages;     // The number of pages not in use.
    ubyte* pagetable;

    bool isLargeObject;

    uint shiftBy;    // shift count for the divisor used for determining bit indices.

    // This tracks how far back we have to go to find the nearest B_PAGE at
    // a smaller address than a B_PAGEPLUS.  To save space, we use a uint.
    // This limits individual allocations to 16 terabytes, assuming a 4k
    // pagesize.
    uint* bPageOffsets;

    // This variable tracks a conservative estimate of where the first free
    // page in this pool is, so that if a lot of pages towards the beginning
    // are occupied, we can bypass them in O(1).
    size_t searchStart;
    size_t largestFree; // upper limit for largest free chunk in large object pool

    void initialize(size_t npages, bool isLargeObject) nothrow
    {
        this.isLargeObject = isLargeObject;
        size_t poolsize;

        shiftBy = isLargeObject ? 12 : 4;

        //debug(PRINTF) printf("Pool::Pool(%u)\n", npages);
        poolsize = npages * PAGESIZE;
        assert(poolsize >= POOLSIZE);
        baseAddr = cast(byte *)os_mem_map(poolsize);

        // Some of the code depends on page alignment of memory pools
        assert((cast(size_t)baseAddr & (PAGESIZE - 1)) == 0);

        if (!baseAddr)
        {
            //debug(PRINTF) printf("GC fail: poolsize = x%zx, errno = %d\n", poolsize, errno);
            //debug(PRINTF) printf("message = '%s'\n", sys_errlist[errno]);

            npages = 0;
            poolsize = 0;
        }
        //assert(baseAddr);
        topAddr = baseAddr + poolsize;
        auto nbits = cast(size_t)poolsize >> shiftBy;

        mark.alloc(nbits);

        // pagetable already keeps track of what's free for the large object
        // pool.
        if(!isLargeObject)
        {
            freebits.alloc(nbits);
        }

        noscan.alloc(nbits);
        appendable.alloc(nbits);

        pagetable = cast(ubyte*)cstdlib.malloc(npages);
        if (!pagetable)
            onOutOfMemoryErrorNoGC();

        if(isLargeObject)
        {
            bPageOffsets = cast(uint*)cstdlib.malloc(npages * uint.sizeof);
            if (!bPageOffsets)
                onOutOfMemoryErrorNoGC();
        }

        memset(pagetable, B_FREE, npages);

        this.npages = npages;
        this.freepages = npages;
        this.searchStart = 0;
        this.largestFree = npages;
    }


    void Dtor() nothrow
    {
        if (baseAddr)
        {
            int result;

            if (npages)
            {
                result = os_mem_unmap(baseAddr, npages * PAGESIZE);
                assert(result == 0);
                npages = 0;
            }

            baseAddr = null;
            topAddr = null;
        }
        if (pagetable)
        {
            cstdlib.free(pagetable);
            pagetable = null;
        }

        if(bPageOffsets)
            cstdlib.free(bPageOffsets);

        mark.Dtor();
        if(isLargeObject)
        {
            nointerior.Dtor();
        }
        else
        {
            freebits.Dtor();
        }
        finals.Dtor();
        structFinals.Dtor();
        noscan.Dtor();
        appendable.Dtor();
    }

    /**
    *
    */
    uint getBits(size_t biti) nothrow
    {
        uint bits;

        if (finals.nbits && finals.test(biti))
            bits |= BlkAttr.FINALIZE;
        if (structFinals.nbits && structFinals.test(biti))
            bits |= BlkAttr.STRUCTFINAL;
        if (noscan.test(biti))
            bits |= BlkAttr.NO_SCAN;
        if (nointerior.nbits && nointerior.test(biti))
            bits |= BlkAttr.NO_INTERIOR;
        if (appendable.test(biti))
            bits |= BlkAttr.APPENDABLE;
        return bits;
    }

    /**
     *
     */
    void clrBits(size_t biti, uint mask) nothrow
    {
        immutable dataIndex =  biti >> GCBits.BITS_SHIFT;
        immutable bitOffset = biti & GCBits.BITS_MASK;
        immutable keep = ~(GCBits.BITS_1 << bitOffset);

        if (mask & BlkAttr.FINALIZE && finals.nbits)
            finals.data[dataIndex] &= keep;

        if (structFinals.nbits && (mask & BlkAttr.STRUCTFINAL))
            structFinals.data[dataIndex] &= keep;

        if (mask & BlkAttr.NO_SCAN)
            noscan.data[dataIndex] &= keep;
        if (mask & BlkAttr.APPENDABLE)
            appendable.data[dataIndex] &= keep;
        if (nointerior.nbits && (mask & BlkAttr.NO_INTERIOR))
            nointerior.data[dataIndex] &= keep;
    }

    /**
     *
     */
    void setBits(size_t biti, uint mask) nothrow
    {
        // Calculate the mask and bit offset once and then use it to
        // set all of the bits we need to set.
        immutable dataIndex = biti >> GCBits.BITS_SHIFT;
        immutable bitOffset = biti & GCBits.BITS_MASK;
        immutable orWith = GCBits.BITS_1 << bitOffset;

        if (mask & BlkAttr.STRUCTFINAL)
        {
            if (!structFinals.nbits)
                structFinals.alloc(mark.nbits);
            structFinals.data[dataIndex] |= orWith;
        }

        if (mask & BlkAttr.FINALIZE)
        {
            if (!finals.nbits)
                finals.alloc(mark.nbits);
            finals.data[dataIndex] |= orWith;
        }

        if (mask & BlkAttr.NO_SCAN)
        {
            noscan.data[dataIndex] |= orWith;
        }
//        if (mask & BlkAttr.NO_MOVE)
//        {
//            if (!nomove.nbits)
//                nomove.alloc(mark.nbits);
//            nomove.data[dataIndex] |= orWith;
//        }
        if (mask & BlkAttr.APPENDABLE)
        {
            appendable.data[dataIndex] |= orWith;
        }

        if (isLargeObject && (mask & BlkAttr.NO_INTERIOR))
        {
            if(!nointerior.nbits)
                nointerior.alloc(mark.nbits);
            nointerior.data[dataIndex] |= orWith;
        }
    }

    void freePageBits(size_t pagenum, in ref PageBits toFree) nothrow
    {
        assert(!isLargeObject);
        assert(!nointerior.nbits); // only for large objects

        import core.internal.traits : staticIota;
        immutable beg = pagenum * (PAGESIZE / 16 / GCBits.BITS_PER_WORD);
        foreach (i; staticIota!(0, PageBits.length))
        {
            immutable w = toFree[i];
            if (!w) continue;

            immutable wi = beg + i;
            freebits.data[wi] |= w;
            noscan.data[wi] &= ~w;
            appendable.data[wi] &= ~w;
        }

        if (finals.nbits)
        {
            foreach (i; staticIota!(0, PageBits.length))
                if (toFree[i])
                    finals.data[beg + i] &= ~toFree[i];
        }

        if (structFinals.nbits)
        {
            foreach (i; staticIota!(0, PageBits.length))
                if (toFree[i])
                    structFinals.data[beg + i] &= ~toFree[i];
        }
    }

    /**
     * Given a pointer p in the p, return the pagenum.
     */
    size_t pagenumOf(void *p) const nothrow
    in
    {
        assert(p >= baseAddr);
        assert(p < topAddr);
    }
    body
    {
        return cast(size_t)(p - baseAddr) / PAGESIZE;
    }

    @property bool isFree() const pure nothrow
    {
        return npages == freepages;
    }

    size_t slGetSize(void* p) nothrow
    {
        if (isLargeObject)
            return (cast(LargeObjectPool*)&this).getSize(p);
        else
            return (cast(SmallObjectPool*)&this).getSize(p);
    }

    BlkInfo slGetInfo(void* p) nothrow
    {
        if (isLargeObject)
            return (cast(LargeObjectPool*)&this).getInfo(p);
        else
            return (cast(SmallObjectPool*)&this).getInfo(p);
    }


    void Invariant() const {}

    debug(INVARIANT)
    invariant()
    {
        //mark.Invariant();
        //scan.Invariant();
        //freebits.Invariant();
        //finals.Invariant();
        //structFinals.Invariant();
        //noscan.Invariant();
        //appendable.Invariant();
        //nointerior.Invariant();

        if (baseAddr)
        {
            //if (baseAddr + npages * PAGESIZE != topAddr)
                //printf("baseAddr = %p, npages = %d, topAddr = %p\n", baseAddr, npages, topAddr);
            assert(baseAddr + npages * PAGESIZE == topAddr);
        }

        if(pagetable !is null)
        {
            for (size_t i = 0; i < npages; i++)
            {
                Bins bin = cast(Bins)pagetable[i];
                assert(bin < B_MAX);
            }
        }
    }
}

struct LargeObjectPool
{
    Pool base;
    alias base this;

    void updateOffsets(size_t fromWhere) nothrow
    {
        assert(pagetable[fromWhere] == B_PAGE);
        size_t pn = fromWhere + 1;
        for(uint offset = 1; pn < npages; pn++, offset++)
        {
            if(pagetable[pn] != B_PAGEPLUS) break;
            bPageOffsets[pn] = offset;
        }

        // Store the size of the block in bPageOffsets[fromWhere].
        bPageOffsets[fromWhere] = cast(uint) (pn - fromWhere);
    }

    /**
     * Allocate n pages from Pool.
     * Returns OPFAIL on failure.
     */
    size_t allocPages(size_t n) nothrow
    {
        if(largestFree < n || searchStart + n > npages)
            return OPFAIL;

        //debug(PRINTF) printf("Pool::allocPages(n = %d)\n", n);
        size_t largest = 0;
        if (pagetable[searchStart] == B_PAGEPLUS)
        {
            searchStart -= bPageOffsets[searchStart]; // jump to B_PAGE
            searchStart += bPageOffsets[searchStart];
        }
        while (searchStart < npages && pagetable[searchStart] == B_PAGE)
            searchStart += bPageOffsets[searchStart];

        for (size_t i = searchStart; i < npages; )
        {
            assert(pagetable[i] == B_FREE);
            size_t p = 1;
            while (p < n && i + p < npages && pagetable[i + p] == B_FREE)
                p++;

            if (p == n)
                return i;

            if (p > largest)
                largest = p;

            i += p;
            while(i < npages && pagetable[i] == B_PAGE)
            {
                // we have the size information, so we skip a whole bunch of pages.
                i += bPageOffsets[i];
            }
        }

        // not enough free pages found, remember largest free chunk
        largestFree = largest;
        return OPFAIL;
    }

    /**
     * Free npages pages starting with pagenum.
     */
    void freePages(size_t pagenum, size_t npages) nothrow
    {
        //memset(&pagetable[pagenum], B_FREE, npages);
        if(pagenum < searchStart)
            searchStart = pagenum;

        for(size_t i = pagenum; i < npages + pagenum; i++)
        {
            if(pagetable[i] < B_FREE)
            {
                freepages++;
            }

            pagetable[i] = B_FREE;
        }
        largestFree = freepages; // invalidate
    }

    /**
     * Get size of pointer p in pool.
     */
    size_t getSize(void *p) const nothrow
    in
    {
        assert(p >= baseAddr);
        assert(p < topAddr);
    }
    body
    {
        size_t pagenum = pagenumOf(p);
        Bins bin = cast(Bins)pagetable[pagenum];
        assert(bin == B_PAGE);
        return bPageOffsets[pagenum] * PAGESIZE;
    }

    /**
    *
    */
    BlkInfo getInfo(void* p) nothrow
    {
        BlkInfo info;

        size_t offset = cast(size_t)(p - baseAddr);
        size_t pn = offset / PAGESIZE;
        Bins bin = cast(Bins)pagetable[pn];

        if (bin == B_PAGEPLUS)
            pn -= bPageOffsets[pn];
        else if (bin != B_PAGE)
            return info;           // no info for free pages

        info.base = baseAddr + pn * PAGESIZE;
        info.size = bPageOffsets[pn] * PAGESIZE;

        info.attr = getBits(pn);
        return info;
    }

    void runFinalizers(in void[] segment) nothrow
    {
        foreach (pn; 0 .. npages)
        {
            Bins bin = cast(Bins)pagetable[pn];
            if (bin > B_PAGE)
                continue;
            size_t biti = pn;

            if (!finals.test(biti))
                continue;

            auto p = sentinel_add(baseAddr + pn * PAGESIZE);
            size_t size = bPageOffsets[pn] * PAGESIZE - SENTINEL_EXTRA;
            uint attr = getBits(biti);

            if(!rt_hasFinalizerInSegment(p, size, attr, segment))
                continue;

            rt_finalizeFromGC(p, size, attr);

            clrBits(biti, ~BlkAttr.NONE);

            if (pn < searchStart)
                searchStart = pn;

            debug(COLLECT_PRINTF) printf("\tcollecting big %p\n", p);
            //log_free(sentinel_add(p));

            size_t n = 1;
            for (; pn + n < npages; ++n)
                if (pagetable[pn + n] != B_PAGEPLUS)
                    break;
            debug (MEMSTOMP) memset(baseAddr + pn * PAGESIZE, 0xF3, n * PAGESIZE);
            freePages(pn, n);
        }
    }
}


struct SmallObjectPool
{
    Pool base;
    alias base this;

    /**
    * Get size of pointer p in pool.
    */
    size_t getSize(void *p) const nothrow
    in
    {
        assert(p >= baseAddr);
        assert(p < topAddr);
    }
    body
    {
        size_t pagenum = pagenumOf(p);
        Bins bin = cast(Bins)pagetable[pagenum];
        assert(bin < B_PAGE);
        return binsize[bin];
    }

    BlkInfo getInfo(void* p) nothrow
    {
        BlkInfo info;
        size_t offset = cast(size_t)(p - baseAddr);
        size_t pn = offset / PAGESIZE;
        Bins   bin = cast(Bins)pagetable[pn];

        if (bin >= B_PAGE)
            return info;

        info.base = cast(void*)((cast(size_t)p) & notbinsize[bin]);
        info.size = binsize[bin];
        offset = info.base - baseAddr;
        info.attr = getBits(cast(size_t)(offset >> shiftBy));

        return info;
    }

    void runFinalizers(in void[] segment) nothrow
    {
        foreach (pn; 0 .. npages)
        {
            Bins bin = cast(Bins)pagetable[pn];
            if (bin >= B_PAGE)
                continue;

            immutable size = binsize[bin];
            auto p = baseAddr + pn * PAGESIZE;
            const ptop = p + PAGESIZE;
            immutable base = pn * (PAGESIZE/16);
            immutable bitstride = size / 16;

            bool freeBits;
            PageBits toFree;

            for (size_t i; p < ptop; p += size, i += bitstride)
            {
                immutable biti = base + i;

                if (!finals.test(biti))
                    continue;

                auto q = sentinel_add(p);
                uint attr = getBits(biti);

                if(!rt_hasFinalizerInSegment(q, size, attr, segment))
                    continue;

                rt_finalizeFromGC(q, size, attr);

                freeBits = true;
                toFree.set(i);

                debug(COLLECT_PRINTF) printf("\tcollecting %p\n", p);
                //log_free(sentinel_add(p));

                debug (MEMSTOMP) memset(p, 0xF3, size);
            }

            if (freeBits)
                freePageBits(pn, toFree);
        }
    }

    /**
    * Allocate a page of bin's.
    * Returns:
    *           head of a single linked list of new entries
    */
    List* allocPage(Bins bin) nothrow
    {
        size_t pn;
        for (pn = searchStart; pn < npages; pn++)
            if (pagetable[pn] == B_FREE)
                goto L1;

        return null;

    L1:
        searchStart = pn + 1;
        pagetable[pn] = cast(ubyte)bin;
        freepages--;

        // Convert page to free list
        size_t size = binsize[bin];
        void* p = baseAddr + pn * PAGESIZE;
        void* ptop = p + PAGESIZE - size;
        auto first = cast(List*) p;

        for (; p < ptop; p += size)
        {
            (cast(List *)p).next = cast(List *)(p + size);
            (cast(List *)p).pool = &base;
        }
        (cast(List *)p).next = null;
        (cast(List *)p).pool = &base;
        return first;
    }
}

unittest // bugzilla 14467
{
    int[] arr = new int[10];
    assert(arr.capacity);
    arr = arr[$..$];
    assert(arr.capacity);
}

unittest // bugzilla 15353
{
    import core.memory : GC;

    static struct Foo
    {
        ~this()
        {
            GC.free(buf); // ignored in finalizer
        }

        void* buf;
    }
    new Foo(GC.malloc(10));
    GC.collect();
}

unittest // bugzilla 15822
{
    import core.memory : GC;

    ubyte[16] buf;
    static struct Foo
    {
        ~this()
        {
            GC.removeRange(ptr);
            GC.removeRoot(ptr);
        }

        ubyte* ptr;
    }
    GC.addRoot(buf.ptr);
    GC.addRange(buf.ptr, buf.length);
    new Foo(buf.ptr);
    GC.collect();
}

unittest // bugzilla 1180
{
    import core.exception;
    try
    {
        size_t x = size_t.max - 100;
        byte[] big_buf = new byte[x];
    }
    catch(OutOfMemoryError)
    {
    }
}

/* ============================ SENTINEL =============================== */


debug (SENTINEL)
{
    const size_t SENTINEL_PRE = cast(size_t) 0xF4F4F4F4F4F4F4F4UL; // 32 or 64 bits
    const ubyte SENTINEL_POST = 0xF5;           // 8 bits
    const uint SENTINEL_EXTRA = 2 * size_t.sizeof + 1;


    inout(size_t*) sentinel_size(inout void *p) nothrow { return &(cast(inout size_t *)p)[-2]; }
    inout(size_t*) sentinel_pre(inout void *p)  nothrow { return &(cast(inout size_t *)p)[-1]; }
    inout(ubyte*) sentinel_post(inout void *p)  nothrow { return &(cast(inout ubyte *)p)[*sentinel_size(p)]; }


    void sentinel_init(void *p, size_t size) nothrow
    {
        *sentinel_size(p) = size;
        *sentinel_pre(p) = SENTINEL_PRE;
        *sentinel_post(p) = SENTINEL_POST;
    }


    void sentinel_Invariant(const void *p) nothrow
    {
        debug
        {
            assert(*sentinel_pre(p) == SENTINEL_PRE);
            assert(*sentinel_post(p) == SENTINEL_POST);
        }
        else if(*sentinel_pre(p) != SENTINEL_PRE || *sentinel_post(p) != SENTINEL_POST)
            onInvalidMemoryOperationError(); // also trigger in release build
    }


    void *sentinel_add(void *p) nothrow
    {
        return p + 2 * size_t.sizeof;
    }


    void *sentinel_sub(void *p) nothrow
    {
        return p - 2 * size_t.sizeof;
    }
}
else
{
    const uint SENTINEL_EXTRA = 0;


    void sentinel_init(void *p, size_t size) nothrow
    {
    }


    void sentinel_Invariant(const void *p) nothrow
    {
    }


    void *sentinel_add(void *p) nothrow
    {
        return p;
    }


    void *sentinel_sub(void *p) nothrow
    {
        return p;
    }
}

debug (MEMSTOMP)
unittest
{
    import core.memory;
    auto p = cast(uint*)GC.malloc(uint.sizeof*3);
    assert(*p == 0xF0F0F0F0);
    p[2] = 0; // First two will be used for free list
    GC.free(p);
    assert(p[2] == 0xF2F2F2F2);
}

debug (SENTINEL)
unittest
{
    import core.memory;
    auto p = cast(ubyte*)GC.malloc(1);
    assert(p[-1] == 0xF4);
    assert(p[ 1] == 0xF5);
/*
    p[1] = 0;
    bool thrown;
    try
        GC.free(p);
    catch (Error e)
        thrown = true;
    p[1] = 0xF5;
    assert(thrown);
*/
}
