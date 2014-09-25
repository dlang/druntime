/**
 * This module contains the garbage collector implementation.
 *
 * Copyright: Copyright (C) 2001-2007 Digital Mars, www.digitalmars.com.
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
 * Authors:   Walter Bright, David Friedman, Sean Kelly
 */

module gc.concurrent.gc;

// D Programming Language Garbage Collector implementation

/************** Debugging ***************************/

//debug = COLLECT_PRINTF;       // turn on printf's
//debug = PTRCHECK;             // more pointer checking
//debug = PTRCHECK2;            // thorough but slow pointer checking

/*************** Configuration *********************/

version = STACKGROWSDOWN;       // growing the stack means subtracting from the stack pointer
                                // (use for Intel X86 CPUs)
                                // else growing the stack means adding to the stack pointer

import core.stdc.stdio : printf;

// pointer map stub
// not used, to be removed completely

struct PointerMap
{
     size_t[] bits = [1, 1, 0];

     private enum BITS = size_t.sizeof * 8;

     size_t size()
     {
         return 0;
     }

     private bool getbit(size_t offset, bool pointer_bit)
     {
         return false;
     }

     bool mustScanWordAt(size_t offset)
     {
         return false;
     }

     bool isPointerAt(size_t offset)
     {
         return false;
     }

     bool canUpdatePointers()
     {
         return false;
     }
}

/***************************************************/

import gc.concurrent.bits: GCBits;
import gc.concurrent.stats: GCStats, Stats;
import dynarray = gc.concurrent.dynarray;
import os = gc.concurrent.os;
import opts = gc.concurrent.opts;
import core.thread;

import cstdlib = core.stdc.stdlib;
import cstring = core.stdc.string;
import cstdio = core.stdc.stdio;
debug(COLLECT_PRINTF) alias cstdio.printf printf;

/*
 * This is a small optimization that proved it's usefulness. For small chunks
 * or memory memset() seems to be slower (probably because of the call) that
 * simply doing a simple loop to set the memory.
 */
void memset(void* dst, ubyte c, size_t n)
{
    // This number (32) has been determined empirically
    if (n > 32) {
        cstring.memset(dst, c, n);
        return;
    }
    auto p = cast(ubyte*)(dst);
    while (n-- > 0)
        *p++ = c;
}

version (GNU)
{
    // BUG: The following import will likely not work, since the gcc
    //      subdirectory is elsewhere.  Instead, perhaps the functions
    //      could be declared directly or some other resolution could
    //      be found.
    static import gcc.builtins; // for __builtin_unwind_int
}

static import core.memory;

alias BlkInfo = core.memory.GC.BlkInfo;
alias BlkAttr = core.memory.GC.BlkAttr;


package bool has_pointermap(uint attrs)
{
    return !opts.options.conservative && !(attrs & BlkAttr.NO_SCAN);
}

private size_t round_up(size_t n, size_t to)
{
    return (n + to - 1) / to;
}

private
{
    alias void delegate(Object) DEvent;
    alias void delegate( void*, void* ) scanFn;
    enum { OPFAIL = ~cast(size_t)0 }

    extern (C)
    {
        version (DigitalMars) version(OSX)
            void _d_osx_image_init();

        void* thread_stackBottom();
        void* thread_stackTop();
        void rt_finalize( void* p, bool det = true );
        void rt_attachDisposeEvent(Object h, DEvent e);
        bool rt_detachDisposeEvent(Object h, DEvent e);

        void thread_init();
        void thread_suspendAll();
        void thread_resumeAll();

        void onOutOfMemoryError();
    }
}


enum
{
    PAGESIZE =    4096,
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
    List* next;
    Pool* pool;
}


struct Range
{
    void *pbot;
    void *ptop;
    int opCmp(in Range other)
    {
        if (pbot < other.pbot)
            return -1;
        else
        return cast(int)(pbot > other.pbot);
    }
    int opEquals(in Range other)
    {
        return pbot is other.pbot;
    }
}


enum uint binsize[B_MAX] = [ 16,32,64,128,256,512,1024,2048,4096 ];
enum uint notbinsize[B_MAX] = [ ~(16u-1),~(32u-1),~(64u-1),~(128u-1),~(256u-1),
                                ~(512u-1),~(1024u-1),~(2048u-1),~(4096u-1) ];


/* ============================ GC =============================== */


class GCLock {} // just a dummy so we can get a global lock


struct GC
{
    // global lock
    ClassInfo lock;

    void* p_cache;
    size_t size_cache;

    // !=0 means don't scan stack
    uint no_stack;
    bool any_changes;
    void* stack_bottom;
    uint inited;
    /// Turn off collections if > 0
    int disabled;

    // PID of the fork()ed process doing the mark() (0 if is not running)
    int mark_proc_pid;

    /// min(pool.baseAddr)
    byte *min_addr;
    /// max(pool.topAddr)
    byte *max_addr;

    /// Total heap memory
    size_t total_mem;
    /// Free heap memory
    size_t free_mem;

    /// Free list for each size
    List*[B_MAX] free_list;

    dynarray.DynArray!(void*) roots;
    dynarray.DynArray!(Range) ranges;
    dynarray.DynArray!(Pool*) pools;

    Stats stats;

    // Monitoring callbacks
    void delegate() collect_begin_cb;
    void delegate(ulong freed, ulong pagebytes) collect_end_cb;
}

// call locked if necessary
private T locked(T, alias Code)()
{
    synchronized (gc.lock) return Code();
}

private GC* gc;


bool collect_in_progress()
{
    return gc.mark_proc_pid != 0;
}


bool Invariant()
{
    assert (gc !is null);
    if (gc.inited) {
        size_t total_mem = 0;
        size_t free_mem = 0;
        for (size_t i = 0; i < gc.pools.length; i++) {
            Pool* pool = gc.pools[i];
            pool.Invariant();
            if (i == 0)
                assert(gc.min_addr == pool.baseAddr);
            if (i + 1 < gc.pools.length)
                assert(*pool < *gc.pools[i + 1]);
            else if (i + 1 == gc.pools.length)
                assert(gc.max_addr == pool.topAddr);
            total_mem += pool.npages * PAGESIZE;
            for (size_t pn = 0; pn < pool.npages; ++pn)
                if (pool.pagetable[pn] == B_FREE)
                    free_mem += PAGESIZE;
        }

        gc.roots.Invariant();
        gc.ranges.Invariant();

        for (size_t i = 0; i < gc.ranges.length; i++) {
            assert(gc.ranges[i].pbot);
            assert(gc.ranges[i].ptop);
            assert(gc.ranges[i].pbot <= gc.ranges[i].ptop);
        }

        for (size_t i = 0; i < B_PAGE; i++) {
            for (List *list = gc.free_list[i]; list; list = list.next) {
                auto pool = list.pool;
                assert (pool !is null);
                auto p = cast(byte*) list;
                assert (p >= pool.baseAddr);
                assert (p < pool.topAddr);
                assert (pool.freebits.test((p - pool.baseAddr) / 16));
                free_mem += binsize[i];
            }
        }
        assert (gc.total_mem == total_mem);
        assert (gc.free_mem == free_mem);
    }
    return true;
}


/**
 * Find Pool that pointer is in.
 * Return null if not in a Pool.
 * Assume pools is sorted.
 */
Pool* findPool(void* p)
{
    if (p < gc.min_addr || p >= gc.max_addr)
        return null;
    if (gc.pools.length == 0)
        return null;
    if (gc.pools.length == 1)
        return gc.pools[0];
    /// The pooltable[] is sorted by address, so do a binary search
    size_t low = 0;
    size_t high = gc.pools.length - 1;
    while (low <= high) {
        size_t mid = (low + high) / 2;
        auto pool = gc.pools[mid];
        if (p < pool.baseAddr)
            high = mid - 1;
        else if (p >= pool.topAddr)
            low = mid + 1;
        else
            return pool;
    }
    // Not found
    return null;
}


/**
 * Determine the base address of the block containing p.  If p is not a gc
 * allocated pointer, return null.
 */
BlkInfo getInfo(void* p)
{
    assert (p !is null);
    Pool* pool = findPool(p);
    if (pool is null)
        return BlkInfo.init;
    BlkInfo info;
    info.base = pool.findBase(p);
    if (info.base is null)
        return BlkInfo.init;
    info.size = pool.findSize(info.base);
    size_t bit_i = (info.base - pool.baseAddr) / 16;
    info.attr = getAttr(pool, bit_i);
    if (has_pointermap(info.attr)) {
        info.size -= size_t.sizeof; // PointerMap bitmask
        // Points to the PointerMap bitmask pointer, not user data
        if (p >= (info.base + info.size)) {
            return BlkInfo.init;
        }
    }
    if (opts.options.sentinel) {
        info.base = sentinel_add(info.base);
        // points to sentinel data, not user data
        if (p < info.base || p >= sentinel_post(info.base))
            return BlkInfo.init;
        info.size -= SENTINEL_EXTRA;
    }
    return info;
}


/**
 * Compute bin for size.
 */
Bins findBin(size_t size)
{
    Bins bin;
    if (size <= 256)
    {
        if (size <= 64)
        {
            if (size <= 16)
                bin = B_16;
            else if (size <= 32)
                bin = B_32;
            else
                bin = B_64;
        }
        else
        {
            if (size <= 128)
                bin = B_128;
            else
                bin = B_256;
        }
    }
    else
    {
        if (size <= 1024)
        {
            if (size <= 512)
                bin = B_512;
            else
                bin = B_1024;
        }
        else
        {
            if (size <= 2048)
                bin = B_2048;
            else
                bin = B_PAGE;
        }
    }
    return bin;
}


/**
 * Allocate a new pool of at least size bytes.
 * Sort it into pools.
 * Mark all memory in the pool as B_FREE.
 * Return the actual number of bytes reserved or 0 on error.
 */
size_t reserve(size_t size)
{
    assert(size != 0);
    size_t npages = round_up(size, PAGESIZE);
    Pool*  pool = newPool(npages);

    if (!pool)
        return 0;
    return pool.npages * PAGESIZE;
}


/**
 * Minimizes physical memory usage by returning free pools to the OS.
 *
 * If full is false, keep some pools alive if the resulting free memory would
 * be too small.
 */
void minimize(bool full = true)
{
    // The shared mark bits of the freed pool might be used by the mark process
    if (collect_in_progress())
        return;

    if (gc.pools.length == 0)
        return;

    for (size_t n = 0; n < gc.pools.length; n++)
    {
        Pool* pool = gc.pools[n];
        size_t pn;
        for (pn = 0; pn < pool.npages; pn++)
        {
            if (cast(Bins)pool.pagetable[pn] != B_FREE)
                break;
        }
        if (pn < pool.npages)
            continue;
        // Free pool
        size_t pool_size = pool.npages * PAGESIZE;
        if (!full) {
            double percent_free = (gc.free_mem - pool_size) * 100.0 /
                    (gc.total_mem - pool_size);
            if (percent_free < opts.options.min_free)
                continue; // not enough free, don't remove this pool
        }
        gc.total_mem -= pool_size;
        gc.free_mem -= pool_size;
        pool.Dtor();
        cstdlib.free(pool);
        gc.pools.remove_at(n);
        n--;
    }
    gc.min_addr = gc.pools[0].baseAddr;
    gc.max_addr = gc.pools[gc.pools.length - 1].topAddr;
}


/**
 * Allocate a chunk of memory that is larger than a page.
 * Return null if out of memory.
 */
void* bigAlloc(size_t npages, out Pool* pool, size_t* pn, bool* collected)
{
    *collected = false;
    // This code could use some refinement when repeatedly
    // allocating very large arrays.

    void* find_block()
    {
        for (size_t n = 0; n < gc.pools.length; n++)
        {
            pool = gc.pools[n];
            *pn = pool.allocPages(npages);
            if (*pn != OPFAIL)
                return pool.baseAddr + *pn * PAGESIZE;
        }
        return null;
    }

    void* alloc_more()
    {
        // Allocate new pool
        pool = newPool(npages);
        if (!pool)
            return null; // let malloc handle the error
        *pn = pool.allocPages(npages);
        assert(*pn != OPFAIL);
        return pool.baseAddr + *pn * PAGESIZE;
    }

    if (void* p = find_block())
        return p;

    if (gc.disabled)
        return alloc_more();

    // Try collecting
    size_t freedpages = fullcollectshell();
    *collected = true;
    if (freedpages >= npages) {
        if (void* p = find_block())
            return p;
    }

    return alloc_more();
}


/**
 * Allocate a new pool with at least npages in it.
 * Sort it into pools.
 * Return null if failed.
 */
Pool *newPool(size_t npages)
{
    // Minimum of POOLSIZE
    if (npages < POOLSIZE/PAGESIZE)
        npages = POOLSIZE/PAGESIZE;
    else if (npages > POOLSIZE/PAGESIZE)
    {
        // Give us 150% of requested size, so there's room to extend
        auto n = npages + (npages >> 1);
        if (n < size_t.max/PAGESIZE)
            npages = n;
    }

    // Allocate successively larger pools up to 8 megs
    if (gc.pools.length)
    {
        size_t n = gc.pools.length;
        if (n > 8)
            n = 8;                  // cap pool size at 8 megs
        n *= (POOLSIZE / PAGESIZE);
        if (npages < n)
            npages = n;
    }

    auto pool = cast(Pool*) cstdlib.calloc(1, Pool.sizeof);
    if (pool is null)
        return null;
    pool.initialize(npages);
    if (!pool.baseAddr)
    {
        pool.Dtor();
        return null;
    }

    auto inserted_pool = *gc.pools.insert_sorted!("*a < *b")(pool);
    if (inserted_pool is null) {
        pool.Dtor();
        return null;
    }
    assert (inserted_pool is pool);
    gc.min_addr = gc.pools[0].baseAddr;
    gc.max_addr = gc.pools[gc.pools.length - 1].topAddr;
    size_t pool_size = pool.topAddr - pool.baseAddr;
    gc.total_mem += pool_size;
    gc.free_mem += pool_size;
    return pool;
}


/**
 * Allocate a page of bin's.
 * Returns:
 *  0       failed
 */
int allocPage(Bins bin)
{
    Pool*  pool;
    size_t pn;

    for (size_t n = 0; n < gc.pools.length; n++)
    {
        pool = gc.pools[n];
        pn = pool.allocPages(1);
        if (pn != OPFAIL)
            goto L1;
    }
    return 0;               // failed

  L1:
    pool.pagetable[pn] = cast(ubyte)bin;

    // Convert page to free list
    size_t size = binsize[bin];
    auto list_head = &gc.free_list[bin];

    byte* p = pool.baseAddr + pn * PAGESIZE;
    byte*  ptop = p + PAGESIZE;
    size_t bit_i = pn * (PAGESIZE / 16);
    pool.freebits.set_group(bit_i, PAGESIZE / 16);
    for (; p < ptop; p += size)
    {
        List* l = cast(List *) p;
        l.next = *list_head;
        l.pool = pool;
        *list_head = l;
    }
    return 1;
}


/**
 * Search a range of memory values and mark any pointers into the GC pool using
 * type information (bitmask of pointer locations).
 */
void mark_range(void *pbot, void *ptop, size_t* pm_bitmask)
{
    // TODO: make our own assert because assert uses the GC
    assert (pbot <= ptop);

    enum BITS_PER_WORD = size_t.sizeof * 8;

    void **p1 = cast(void **)pbot;
    void **p2 = cast(void **)ptop;
    size_t pcache = 0;
    bool changes = false;

    size_t type_size = pm_bitmask[0];
    size_t* pm_bits = pm_bitmask + 1;
    bool has_type_info = type_size != 1 || pm_bits[0] != 1 || pm_bits[1] != 0;

    //printf("marking range: %p -> %p\n", pbot, ptop);
    for (; p1 + type_size <= p2; p1 += type_size) {
        for (size_t n = 0; n < type_size; n++) {
            // scan bit set for this word
            if (has_type_info &&
                    !(pm_bits[n / BITS_PER_WORD] & (1 << (n % BITS_PER_WORD))))
                continue;

            void* p = *(p1 + n);

            if (p < gc.min_addr || p >= gc.max_addr)
                continue;

            if ((cast(size_t)p & ~(PAGESIZE-1)) == pcache)
                continue;

            Pool* pool = findPool(p);
            if (pool)
            {
                size_t offset = cast(size_t)(p - pool.baseAddr);
                size_t bit_i = void;
                size_t pn = offset / PAGESIZE;
                Bins   bin = cast(Bins)pool.pagetable[pn];

                // Cache B_PAGE, B_PAGEPLUS and B_FREE lookups
                if (bin >= B_PAGE)
                    pcache = cast(size_t)p & ~(PAGESIZE-1);

                // Adjust bit to be at start of allocated memory block
                if (bin <= B_PAGE)
                    bit_i = (offset & notbinsize[bin]) / 16;
                else if (bin == B_PAGEPLUS)
                {
                    do
                    {
                        --pn;
                    }
                    while (cast(Bins)pool.pagetable[pn] == B_PAGEPLUS);
                    bit_i = pn * (PAGESIZE / 16);
                }
                else // Don't mark bits in B_FREE pages
                    continue;

                if (!pool.mark.test(bit_i))
                {
                    pool.mark.set(bit_i);
                    if (!pool.noscan.test(bit_i))
                    {
                        pool.scan.set(bit_i);
                        changes = true;
                    }
                }
            }
        }
    }
    if (changes)
        gc.any_changes = true;
}

/**
 * Return number of full pages free'd.
 */
size_t fullcollectshell(bool early = false, bool force_block = false)
{
    gc.stats.collection_started();
    scope (exit)
        gc.stats.collection_finished();

    // The purpose of the 'shell' is to ensure all the registers
    // get put on the stack so they'll be scanned
    void *sp;
    size_t result;
    version (GNU)
    {
        gcc.builtins.__builtin_unwind_init();
        sp = & sp;
    }
    else version(LDC)
    {
        version(X86)
        {
            uint eax,ecx,edx,ebx,ebp,esi,edi;
            asm
            {
                mov eax[EBP], EAX      ;
                mov ecx[EBP], ECX      ;
                mov edx[EBP], EDX      ;
                mov ebx[EBP], EBX      ;
                mov ebp[EBP], EBP      ;
                mov esi[EBP], ESI      ;
                mov edi[EBP], EDI      ;
                mov  sp[EBP], ESP      ;
            }
        }
        else version (X86_64)
        {
            ulong rax,rbx,rcx,rdx,rbp,rsi,rdi,r8,r9,r10,r11,r12,r13,r14,r15;
            asm
            {
                movq rax[RBP], RAX      ;
                movq rbx[RBP], RBX      ;
                movq rcx[RBP], RCX      ;
                movq rdx[RBP], RDX      ;
                movq rbp[RBP], RBP      ;
                movq rsi[RBP], RSI      ;
                movq rdi[RBP], RDI      ;
                movq r8 [RBP], R8       ;
                movq r9 [RBP], R9       ;
                movq r10[RBP], R10      ;
                movq r11[RBP], R11      ;
                movq r12[RBP], R12      ;
                movq r13[RBP], R13      ;
                movq r14[RBP], R14      ;
                movq r15[RBP], R15      ;
                movq  sp[RBP], RSP      ;
            }
        }
        else
        {
            static assert( false, "Architecture not supported." );
        }
    }
    else
    {
        version (D_InlineAsm_X86)
        {
            asm
            {
                pushad              ;
                mov sp[EBP],ESP     ;
            }
        }
        else version (D_InlineAsm_X86_64)
        {
            asm
            {
                push RAX ;
                push RBX ;
                push RCX ;
                push RDX ;
                push RSI ;
                push RDI ;
                push RBP ;
                push R8  ;
                push R9  ;
                push R10  ;
                push R11  ;
                push R12  ;
                push R13  ;
                push R14  ;
                push R15  ;
                push RAX ;   // 16 byte align the stack
            }
        }
        else
        {
            static assert( false, "Architecture not supported." );
        }
    }
    result = fullcollect(sp, early, force_block);
    version (GNU)
    {
        // nothing to do
    }
    else version(LDC)
    {
        // nothing to do
    }
    else
    {
        version (D_InlineAsm_X86_64)
        {
            asm
            {
                pop RAX ;
                pop R15  ;
                pop R14  ;
                pop R13  ;
                pop R12  ;
                pop R11  ;
                pop R10  ;
                pop R9  ;
                pop R8  ;
                pop RBP ;
                pop RDI ;
                pop RSI ;
                pop RDX ;
                pop RCX ;
                pop RBX ;
                pop RAX ;
            }
        }
        else
        {
            asm
            {
                popad               ;
            }
        }
    }
    return result;
}


/**
 *
 */
size_t fullcollect(void *stackTop, bool early = false, bool force_block = false)
{
    debug(COLLECT_PRINTF) printf("Gcx.fullcollect(early=%d)\n",
            cast(int) early);

    // We will block the mutator only if eager allocation is not used and this
    // is not an early collection.
    bool block = force_block || !opts.options.eager_alloc && !early;

    // If there is a mark process running, check if it already finished.  If
    // that is the case, we lunch the sweep phase and hope enough memory is
    // freed.  If it's still running, either we block until the mark phase is
    // done (and then sweep to finish the collection), or we tell the caller
    // process no memory has been recovered (it will allocated more to fulfill
    // the current request if eager allocation is used) and let the mark phase
    // keep running in parallel.
    if (collect_in_progress()) {
        os.WRes r = os.wait_pid(gc.mark_proc_pid, block);
        assert (r != os.WRes.ERROR);
        final switch (r) {
            case os.WRes.DONE:
                debug(COLLECT_PRINTF) printf("\t\tmark proc DONE (block=%d)\n",
                        cast(int) block);
                gc.mark_proc_pid = 0;
                return sweep();
            case os.WRes.RUNNING:
                debug(COLLECT_PRINTF) printf("\t\tmark proc RUNNING\n");
                if (!block)
                    return 0;
                // Something went wrong, if block is true, wait() should never
                // returned RUNNING.
                goto case os.WRes.ERROR;
            case os.WRes.ERROR:
                debug(COLLECT_PRINTF) printf("\t\tmark proc ERROR\n");
                disable_fork(); // Try to keep going without forking
                break;
        }
    }

    // Notify the GC monitor, if any
    if (gc.collect_begin_cb.funcptr) {
        debug(COLLECT_PRINTF) printf("\t\tcalling monitor (begin)\n");
        gc.collect_begin_cb();
    }

    // We always need to stop the world to make threads save the CPU registers
    // in the stack and prepare themselves for thread_scanAll()
    thread_suspendAll();
    gc.stats.world_stopped();

    // If forking is enabled, we fork() and start a new mark phase in the
    // child. If the collection should not block, the parent process tells the
    // caller no memory could be recycled immediately (if eager allocation is
    // used, and this collection was triggered by an allocation, the caller
    // should allocate more memory to fulfill the request). If the collection
    // should block, the parent will wait for the mark phase to finish before
    // returning control to the mutator, but other threads are restarted and
    // may run in parallel with the mark phase (unless they allocate or use the
    // GC themselves, in which case the global GC lock will stop them).
    if (opts.options.fork) {
        cstdio.fflush(null); // avoid duplicated FILE* output
        os.pid_t child_pid = os.fork();
        assert (child_pid != -1); // don't accept errors in non-release mode
        switch (child_pid) {
        case -1: // if fork() fails, fall-back to stop-the-world
            disable_fork();
            break;
        case 0: // child process (i.e. the collectors mark phase)
            mark(stackTop);
            cstdlib._Exit(0);
            break; // bogus, will never reach here
        default: // parent process (i.e. the mutator)
            thread_resumeAll();
            gc.stats.world_started();
            if (!block) {
                gc.mark_proc_pid = child_pid;
                return 0;
            }
            os.WRes r = os.wait_pid(child_pid); // block until it finishes
            assert (r == os.WRes.DONE);
            debug(COLLECT_PRINTF) printf("\t\tmark proc DONE (block=%d)\n",
                    cast(int) block);
            if (r == os.WRes.DONE)
                return sweep();
            debug(COLLECT_PRINTF) printf("\tmark() proc ERROR\n");
            // If there was some error, try to keep going without forking
            disable_fork();
            // Re-suspend the threads to do the marking in this process
            thread_suspendAll();
            gc.stats.world_stopped();
        }

    }

    // If we reach here, we are using the standard stop-the-world collection,
    // either because fork was disabled in the first place, or because it was
    // disabled because of some error.
    mark(stackTop);
    thread_resumeAll();
    gc.stats.world_started();

    return sweep();
}


/**
 *
 */
void mark(void *stackTop)
{
    debug(COLLECT_PRINTF) printf("\tmark()\n");

    gc.any_changes = false;

    for (size_t n = 0; n < gc.pools.length; n++)
    {
        Pool* pool = gc.pools[n];
        pool.mark.copy(&pool.freebits);
        pool.scan.zero();
    }

    /// Marks a range of memory in conservative mode.
    void mark_conservative_range(void* pbot, void* ptop) nothrow
    {
        try
        {
            mark_range(pbot, ptop, PointerMap.init.bits.ptr);
        }
        catch (Exception e)
        {
            throw new Error(e.msg);
        }
    }

    thread_scanAll(&mark_conservative_range);

/*
    if (!gc.no_stack)
    {
        // Scan stacks and registers for each paused thread
        thread_scanAll(&mark_conservative_range, stackTop);
    } */

    // Scan roots
    debug(COLLECT_PRINTF) printf("scan roots[]\n");
    mark_conservative_range(gc.roots.ptr, gc.roots.ptr + gc.roots.length);

    // Scan ranges
    debug(COLLECT_PRINTF) printf("scan ranges[]\n");
    for (size_t n = 0; n < gc.ranges.length; n++)
    {
        debug(COLLECT_PRINTF) printf("\t%x .. %x\n", gc.ranges[n].pbot, gc.ranges[n].ptop);
        mark_conservative_range(gc.ranges[n].pbot, gc.ranges[n].ptop);
    }

    debug(COLLECT_PRINTF) printf("\tscan heap\n");
    while (gc.any_changes)
    {
        gc.any_changes = false;
        for (size_t n = 0; n < gc.pools.length; n++)
        {
            uint *bbase;
            uint *b;
            uint *btop;

            Pool* pool = gc.pools[n];

            bbase = pool.scan.base();
            btop = bbase + pool.scan.nwords;
            for (b = bbase; b < btop;)
            {
                Bins   bin;
                size_t pn;
                size_t u;
                size_t bitm;
                byte*  o;

                bitm = *b;
                if (!bitm)
                {
                    b++;
                    continue;
                }
                *b = 0;

                o = pool.baseAddr + (b - bbase) * 32 * 16;
                if (!(bitm & 0xFFFF))
                {
                    bitm >>= 16;
                    o += 16 * 16;
                }
                for (; bitm; o += 16, bitm >>= 1)
                {
                    if (!(bitm & 1))
                        continue;

                    pn = cast(size_t)(o - pool.baseAddr) / PAGESIZE;
                    bin = cast(Bins)pool.pagetable[pn];
                    if (bin < B_PAGE) {
                        if (opts.options.conservative)
                            mark_conservative_range(o, o + binsize[bin]);
                        else {
                            auto end_of_blk = cast(size_t**)(o +
                                    binsize[bin] - size_t.sizeof);
                            size_t* pm_bitmask = *end_of_blk;
                            mark_range(o, end_of_blk, pm_bitmask);
                        }
                    }
                    else if (bin == B_PAGE || bin == B_PAGEPLUS)
                    {
                        if (bin == B_PAGEPLUS)
                        {
                            while (pool.pagetable[pn - 1] != B_PAGE)
                                pn--;
                        }
                        u = 1;
                        while (pn + u < pool.npages &&
                                pool.pagetable[pn + u] == B_PAGEPLUS)
                            u++;

                        size_t blk_size = u * PAGESIZE;
                        if (opts.options.conservative)
                            mark_conservative_range(o, o + blk_size);
                        else {
                            auto end_of_blk = cast(size_t**)(o + blk_size -
                                    size_t.sizeof);
                            size_t* pm_bitmask = *end_of_blk;
                            mark_range(o, end_of_blk, pm_bitmask);
                        }
                    }
                }
            }
        }
    }
}


/**
 *
 */
size_t sweep()
{
    // Free up everything not marked
    debug(COLLECT_PRINTF) printf("\tsweep\n");
    gc.p_cache = null;
    gc.size_cache = 0;
    gc.free_mem = 0; // will be recalculated
    size_t freedpages = 0;
    size_t freed = 0;
    for (size_t n = 0; n < gc.pools.length; n++)
    {
        Pool* pool = gc.pools[n];
        pool.clear_cache();
        uint*  bbase = pool.mark.base();
        size_t pn;
        for (pn = 0; pn < pool.npages; pn++, bbase += PAGESIZE / (32 * 16))
        {
            Bins bin = cast(Bins)pool.pagetable[pn];

            if (bin < B_PAGE)
            {
                auto size = binsize[bin];
                byte* p = pool.baseAddr + pn * PAGESIZE;
                byte* ptop = p + PAGESIZE;
                size_t bit_i = pn * (PAGESIZE/16);
                size_t bit_stride = size / 16;

version(none) // BUG: doesn't work because freebits() must also be cleared
{
                // If free'd entire page
                if (bbase[0] == 0 && bbase[1] == 0 && bbase[2] == 0 &&
                        bbase[3] == 0 && bbase[4] == 0 && bbase[5] == 0 &&
                        bbase[6] == 0 && bbase[7] == 0)
                {
                    for (; p < ptop; p += size, bit_i += bit_stride)
                    {
                        if (pool.finals.testClear(bit_i)) {
                            if (opts.options.sentinel)
                                rt_finalize(sentinel_add(p), false/*gc.no_stack > 0*/);
                            else
                                rt_finalize(p, false/*gc.no_stack > 0*/);
                        }
                        clrAttr(pool, bit_i, uint.max);

                        if (opts.options.mem_stomp)
                            memset(p, 0xF3, size);
                    }
                    pool.pagetable[pn] = B_FREE;
                    freed += PAGESIZE;
                    continue;
                }
}
                for (; p < ptop; p += size, bit_i += bit_stride)
                {
                    if (!pool.mark.test(bit_i))
                    {
                        if (opts.options.sentinel)
                            sentinel_Invariant(sentinel_add(p));

                        pool.freebits.set(bit_i);
                        if (pool.finals.testClear(bit_i)) {
                            if (opts.options.sentinel)
                                rt_finalize(sentinel_add(p), false/*gc.no_stack > 0*/);
                            else
                                rt_finalize(p, false/*gc.no_stack > 0*/);
                        }
                        clrAttr(pool, bit_i, uint.max);

                        if (opts.options.mem_stomp)
                            memset(p, 0xF3, size);

                        freed += size;
                    }
                }
            }
            else if (bin == B_PAGE)
            {
                size_t bit_stride = PAGESIZE / 16;
                size_t bit_i = pn * bit_stride;
                if (!pool.mark.test(bit_i))
                {
                    byte *p = pool.baseAddr + pn * PAGESIZE;
                    if (opts.options.sentinel)
                        sentinel_Invariant(sentinel_add(p));
                    if (pool.finals.testClear(bit_i)) {
                        if (opts.options.sentinel)
                            rt_finalize(sentinel_add(p), false/*gc.no_stack > 0*/);
                        else
                            rt_finalize(p, false/*gc.no_stack > 0*/);
                    }
                    clrAttr(pool, bit_i, uint.max);

                    debug(COLLECT_PRINTF) printf("\tcollecting big %p\n", p);
                    pool.pagetable[pn] = B_FREE;
                    pool.freebits.set_group(bit_i, PAGESIZE / 16);
                    freedpages++;
                    gc.free_mem += PAGESIZE;
                    if (opts.options.mem_stomp)
                        memset(p, 0xF3, PAGESIZE);
                    while (pn + 1 < pool.npages && pool.pagetable[pn + 1] == B_PAGEPLUS)
                    {
                        pn++;
                        pool.pagetable[pn] = B_FREE;
                        bit_i += bit_stride;
                        pool.freebits.set_group(bit_i, PAGESIZE / 16);
                        freedpages++;
                        gc.free_mem += PAGESIZE;

                        if (opts.options.mem_stomp)
                        {
                            p += PAGESIZE;
                            memset(p, 0xF3, PAGESIZE);
                        }
                    }
                }
            }
            else if (bin == B_FREE) {
                gc.free_mem += PAGESIZE;
            }
        }
    }

    // Zero buckets
    gc.free_list[] = null;

    // Free complete pages, rebuild free list
    debug(COLLECT_PRINTF) printf("\tfree complete pages\n");
    size_t recoveredpages = 0;
    for (size_t n = 0; n < gc.pools.length; n++)
    {
        Pool* pool = gc.pools[n];
        for (size_t pn = 0; pn < pool.npages; pn++)
        {
            Bins   bin = cast(Bins)pool.pagetable[pn];
            size_t bit_i;
            size_t u;

            if (bin < B_PAGE)
            {
                size_t size = binsize[bin];
                size_t bit_stride = size / 16;
                size_t bit_base = pn * (PAGESIZE / 16);
                size_t bit_top = bit_base + (PAGESIZE / 16);
                byte*  p;

                bit_i = bit_base;
                for (; bit_i < bit_top; bit_i += bit_stride)
                {
                    if (!pool.freebits.test(bit_i))
                        goto Lnotfree;
                }
                pool.pagetable[pn] = B_FREE;
                pool.freebits.set_group(bit_base, PAGESIZE / 16);
                recoveredpages++;
                gc.free_mem += PAGESIZE;
                continue;

             Lnotfree:
                p = pool.baseAddr + pn * PAGESIZE;
                for (u = 0; u < PAGESIZE; u += size)
                {
                    bit_i = bit_base + u / 16;
                    if (pool.freebits.test(bit_i))
                    {
                        assert ((p+u) >= pool.baseAddr);
                        assert ((p+u) < pool.topAddr);
                        List* list = cast(List*) (p + u);
                        // avoid unnecesary writes (it really saves time)
                        if (list.next != gc.free_list[bin])
                            list.next = gc.free_list[bin];
                        if (list.pool != pool)
                            list.pool = pool;
                        gc.free_list[bin] = list;
                        gc.free_mem += binsize[bin];
                    }
                }
            }
        }
    }

    debug(COLLECT_PRINTF) printf("recovered pages = %d\n", recoveredpages);
    debug(COLLECT_PRINTF) printf("\tfree'd %u bytes, %u pages from %u pools\n",
            freed, freedpages, gc.pools.length);

    // Notify the GC monitor, if any
    if (gc.collect_end_cb.funcptr) {
        debug(COLLECT_PRINTF) printf("\t\tcalling monitor (end)\n");
        gc.collect_end_cb(freed + freedpages * PAGESIZE,
                (freedpages + recoveredpages) * PAGESIZE);
    }

    return freedpages + recoveredpages;
}


/**
 *
 */
uint getAttr(Pool* pool, size_t bit_i)
in
{
    assert( pool );
}
body
{
    uint attrs;

    debug (CDGC_TRACE_PRINTF)
    {
        printf("> getAttr(%p, %u, %u)\n", pool, bit_i);
        scope(exit) printf("< getAttr() : %u\n", attrs);
    }

    if (pool.finals.test(bit_i))
        attrs |= BlkAttr.FINALIZE;
    if (pool.noscan.test(bit_i))
        attrs |= BlkAttr.NO_SCAN;
    if (pool.appendable.test(bit_i))
        attrs |= BlkAttr.APPENDABLE;
    return attrs;
}


/**
 *
 */
void setAttr(Pool* pool, size_t bit_i, uint mask)
in
{
    assert( pool );
}
body
{
    debug (CDGC_TRACE_PRINTF)
    {
        printf("> setAttr(%p, %u, %u)\n", pool, bit_i, mask);
        scope(exit)
            printf("< setAttr()\n");
    }

    if (mask & BlkAttr.FINALIZE)
    {
        pool.finals.set(bit_i);
    }
    if (mask & BlkAttr.NO_SCAN)
    {
        pool.noscan.set(bit_i);
    }
    if (mask & BlkAttr.APPENDABLE)
    {
        pool.appendable.set(bit_i);
    }
}


/**
 *
 */
void clrAttr(Pool* pool, size_t bit_i, uint mask)
in
{
    assert( pool );
}
body
{
    debug (CDGC_TRACE_PRINTF)
    {
        printf("> clrAttr(%p, %u, %u)\n", pool, bit_i, mask);
        scope(exit)
            printf("< clrAttr()\n");
    }

    if (mask & BlkAttr.FINALIZE)
        pool.finals.clear(bit_i);
    if (mask & BlkAttr.NO_SCAN)
        pool.noscan.clear(bit_i);
    if (mask & BlkAttr.APPENDABLE)
        pool.appendable.clear(bit_i);
}


void disable_fork()
{
    // we have to disable all options that assume fork is enabled
    opts.options.fork = false;
    opts.options.eager_alloc = false;
    opts.options.early_collect = false;
}


void initialize()
{
    int dummy;
    gc.stack_bottom = cast(char*)&dummy;
    opts.parse(cstdlib.getenv("D_GC_OPTS"));
    // If we are going to fork, make sure we have the needed OS support
    if (opts.options.fork)
        opts.options.fork = os.HAVE_SHARED && os.HAVE_FORK;
    // Disable fork()-related options if we don't have it
    if (!opts.options.fork)
        disable_fork();
    gc.lock = GCLock.classinfo;
    gc.inited = 1;
    gc.no_stack = 0;

    // NOTE: The GC must initialize the thread library
    //       before its first collection.
    thread_init();

    setStackBottom(thread_stackBottom());

    gc.stats = Stats(gc);
    if (opts.options.prealloc_npools) {
        size_t pages = round_up(opts.options.prealloc_psize, PAGESIZE);
        for (size_t i = 0; i < opts.options.prealloc_npools; ++i)
            newPool(pages);
    }
}


// Launch a parallel collection if we don't have enough free memory available
// (we have less than min_free% of the total heap free).
void early_collect()
{
    static double last_percent_free = 100;

    if ( !opts.options.early_collect || gc.disabled )
        return;

    double percent_free = gc.free_mem * 100.0 / gc.total_mem;

    if (percent_free < opts.options.min_free &&
        // free memory shrank at least 0.1% since the last early collection
        // FIXME: this probably needs to be bigger and/or configurable
        last_percent_free - percent_free > 0.1 )
    {
        last_percent_free = percent_free;
        fullcollectshell(true);
    }
}


private void *malloc(size_t size, uint attrs, size_t* pm_bitmask = null)
{
    size_t capacity_not_used;
    return malloc(size, attrs, capacity_not_used, pm_bitmask);
}

//
//
//
private void *malloc(size_t size, uint attrs, out size_t capacity, size_t* pm_bitmask = null)
{
//    printf("gc malloc called\n");
    assert(size != 0);

    void *p = null;
    Bins bin;

    gc.stats.malloc_started(size, attrs, pm_bitmask,
                            gc.total_mem - gc.free_mem,
                            gc.free_mem);

    scope (exit)
        gc.stats.malloc_finished(p);

    if (opts.options.sentinel)
        size += SENTINEL_EXTRA;

    bool has_pm = has_pointermap(attrs);
    if (has_pm)
        size += size_t.sizeof;

    // Compute size bin
    // Cache previous binsize lookup - Dave Fladebo.
    static size_t lastsize = -1;
    static Bins lastbin;
    if (size == lastsize)
        bin = lastbin;
    else
    {
        bin = findBin(size);
        lastsize = size;
        lastbin = bin;
    }

    Pool* pool = void;
    size_t bit_i = void;
    bool collected = false;
    if (bin < B_PAGE)
    {
        p = gc.free_list[bin];
        if (p is null)
        {
            if (!allocPage(bin) && !gc.disabled)   // try to find a new page
            {
                if (!fullcollectshell())       // collect to find a new page
                {
                    //newPool(1);
                }
                collected = true;
            }
            if (!gc.free_list[bin] && !allocPage(bin))
            {
                newPool(1);         // allocate new pool to find a new page
                // TODO: hint allocPage() to use the pool we just created
                int result = allocPage(bin);
                if (!result)
                    onOutOfMemoryError();
            }
            p = gc.free_list[bin];
        }
        capacity = binsize[bin];

        // Return next item from free list
        List* list = cast(List*) p;
        assert ((cast(byte*)list) >= list.pool.baseAddr);
        assert ((cast(byte*)list) < list.pool.topAddr);
        gc.free_list[bin] = list.next;
        pool = list.pool;
        bit_i = (p - pool.baseAddr) / 16;
        assert (pool.freebits.test(bit_i));
        pool.freebits.clear(bit_i);
        if (!(attrs & BlkAttr.NO_SCAN))
            memset(p + size, 0, capacity - size);
        if (opts.options.mem_stomp)
            memset(p, 0xF0, size);
    }
    else
    {
        size_t pn;
        size_t npages = round_up(size, PAGESIZE);
        p = bigAlloc(npages, pool, &pn, &collected);
        if (!p)
            onOutOfMemoryError();
        assert (pool !is null);

        capacity = npages * PAGESIZE;
        bit_i = pn * (PAGESIZE / 16);
        pool.freebits.clear(bit_i);
        pool.pagetable[pn] = B_PAGE;
        if (npages > 1)
            memset(&pool.pagetable[pn + 1], B_PAGEPLUS, npages - 1);
        p = pool.baseAddr + pn * PAGESIZE;
        memset(cast(char *)p + size, 0, npages * PAGESIZE - size);
        if (opts.options.mem_stomp)
            memset(p, 0xF1, size);

    }

    // Store the bit mask AFTER SENTINEL_POST
    // TODO: store it BEFORE, so the bitmask is protected too
    if (has_pm) {
        auto end_of_blk = cast(size_t**)(p + capacity - size_t.sizeof);
        *end_of_blk = pm_bitmask;
        size -= size_t.sizeof;
    }

    if (opts.options.sentinel) {
        size -= SENTINEL_EXTRA;
        p = sentinel_add(p);
        sentinel_init(p, size);
    }

    if (attrs) {
        setAttr(pool, bit_i, attrs);
        assert (bin >= B_PAGE || !pool.freebits.test(bit_i));
    }

    gc.free_mem -= capacity;
    if (collected) {
        // If there is not enough free memory (after a collection), allocate
        // a new pool big enough to have at least the min_free% of the total
        // heap free. If the collection left too much free memory, try to free
        // some empty pools.
        double percent_free = gc.free_mem * 100.0 / gc.total_mem;
        if (percent_free < opts.options.min_free) {
            auto pool_size = gc.total_mem * 1.0 / opts.options.min_free
                    - gc.free_mem;
            newPool(round_up(cast(size_t)pool_size, PAGESIZE));
        }
        else
            minimize(false);
    }
    else
        early_collect();

    return p;
}


//
//
//
private void *calloc(size_t size, uint attrs, size_t* pm_bitmask = null)
{
    assert(size != 0);

    void *p = malloc(size, attrs, pm_bitmask);
    memset(p, 0, size);
    return p;
}


//
//
//
private void *realloc(void *p, size_t size, uint attrs, size_t* pm_bitmask = null)
{
    if (!size) {
        if (p)
            free(p);
        return null;
    }

    if (p is null)
        return malloc(size, attrs, pm_bitmask);

    Pool* pool = findPool(p);
    if (pool is null)
        return null;

    // Set or retrieve attributes as appropriate
    auto bit_i = cast(size_t)(p - pool.baseAddr) / 16;
    if (attrs) {
        clrAttr(pool, bit_i, uint.max);
        setAttr(pool, bit_i, attrs);
    }
    else
        attrs = getAttr(pool, bit_i);

    void* blk_base_addr = pool.findBase(p);
    size_t blk_size = pool.findSize(p);
    bool has_pm = has_pointermap(attrs);
    size_t pm_bitmask_size = 0;
    if (has_pm) {
        pm_bitmask_size = size_t.sizeof;
        // Retrieve pointer map bit mask if appropriate
        if (pm_bitmask is null) {
            auto end_of_blk = cast(size_t**)(
                    blk_base_addr + blk_size - size_t.sizeof);
            pm_bitmask = *end_of_blk;
        }
    }

    if (opts.options.sentinel) {
        sentinel_Invariant(p);
        size_t sentinel_stored_size = *sentinel_size(p);
        if (sentinel_stored_size != size) {
            void* p2 = malloc(size, attrs, pm_bitmask);
            if (sentinel_stored_size < size)
                size = sentinel_stored_size;
            cstring.memcpy(p2, p, size);
            p = p2;
        }
        return p;
    }

    size += pm_bitmask_size;
    if (blk_size >= PAGESIZE && size >= PAGESIZE) {
        auto psz = blk_size / PAGESIZE;
        auto newsz = round_up(size, PAGESIZE);
        if (newsz == psz)
            return p;

        auto pagenum = (p - pool.baseAddr) / PAGESIZE;

        if (newsz < psz) {
            // Shrink in place
            if (opts.options.mem_stomp)
                memset(p + size - pm_bitmask_size, 0xF2,
                        blk_size - size - pm_bitmask_size);
            pool.freePages(pagenum + newsz, psz - newsz);
            auto new_blk_size = (PAGESIZE * newsz);
            gc.free_mem += blk_size - new_blk_size;
            // update the size cache, assuming that is very likely the
            // size of this block will be queried in the near future
            pool.update_cache(p, new_blk_size);
            if (has_pm) {
                auto end_of_blk = cast(size_t**)(blk_base_addr +
                        new_blk_size - pm_bitmask_size);
                *end_of_blk = pm_bitmask;
            }
            return p;
        }

        if (pagenum + newsz <= pool.npages) {
            // Attempt to expand in place
            for (size_t i = pagenum + psz; 1;) {
                if (i == pagenum + newsz) {
                    if (opts.options.mem_stomp)
                        memset(p + blk_size - pm_bitmask_size, 0xF0,
                                size - blk_size - pm_bitmask_size);
                    memset(pool.pagetable + pagenum + psz, B_PAGEPLUS,
                            newsz - psz);
                    auto new_blk_size = (PAGESIZE * newsz);
                    gc.free_mem -= new_blk_size - blk_size;
                    // update the size cache, assuming that is very
                    // likely the size of this block will be queried in
                    // the near future
                    pool.update_cache(p, new_blk_size);
                    if (has_pm) {
                        auto end_of_blk = cast(size_t**)(
                                blk_base_addr + new_blk_size - pm_bitmask_size);
                        *end_of_blk = pm_bitmask;
                    }
                    early_collect();
                    return p;
                }
                if (i == pool.npages)
                    break;
                if (pool.pagetable[i] != B_FREE)
                    break;
                i++;
            }
        }
    }

    // if new size is bigger or less than half
    if (blk_size < size || blk_size > size * 2) {
        size -= pm_bitmask_size;
        blk_size -= pm_bitmask_size;
        void* p2 = malloc(size, attrs, pm_bitmask);
        if (blk_size < size)
            size = blk_size;
        cstring.memcpy(p2, p, size);
        p = p2;
    }

    return p;
}


/**
 * Attempt to in-place enlarge the memory block pointed to by p by at least
 * min_size beyond its current capacity, up to a maximum of max_size.  This
 * does not attempt to move the memory block (like realloc() does).
 *
 * Returns:
 *  0 if could not extend p,
 *  total size of entire memory block if successful.
 */
private size_t extend(void* p, size_t minsize, size_t maxsize)
in
{
    assert( minsize <= maxsize );
}
body
{
    if (opts.options.sentinel)
        return 0;

    Pool* pool = findPool(p);
    if (pool is null)
        return 0;

    // Retrieve attributes
    auto bit_i = cast(size_t)(p - pool.baseAddr) / 16;
    uint attrs = getAttr(pool, bit_i);

    void* blk_base_addr = pool.findBase(p);
    size_t blk_size = pool.findSize(p);
    bool has_pm = has_pointermap(attrs);
    size_t* pm_bitmask = null;
    size_t pm_bitmask_size = 0;
    if (has_pm) {
        pm_bitmask_size = size_t.sizeof;
        // Retrieve pointer map bit mask
        auto end_of_blk = cast(size_t**)(blk_base_addr +
                blk_size - size_t.sizeof);
        pm_bitmask = *end_of_blk;

        minsize += size_t.sizeof;
        maxsize += size_t.sizeof;
    }

    if (blk_size < PAGESIZE)
        return 0; // cannot extend buckets

    auto psz = blk_size / PAGESIZE;
    auto minsz = round_up(minsize, PAGESIZE);
    auto maxsz = round_up(maxsize, PAGESIZE);

    auto pagenum = (p - pool.baseAddr) / PAGESIZE;

    size_t sz;
    for (sz = 0; sz < maxsz; sz++)
    {
        auto i = pagenum + psz + sz;
        if (i == pool.npages)
            break;
        if (pool.pagetable[i] != B_FREE)
        {
            if (sz < minsz)
                return 0;
            break;
        }
    }
    if (sz < minsz)
        return 0;

    size_t new_size = (psz + sz) * PAGESIZE;

    if (opts.options.mem_stomp)
        memset(p + blk_size - pm_bitmask_size, 0xF0,
                new_size - blk_size - pm_bitmask_size);
    memset(pool.pagetable + pagenum + psz, B_PAGEPLUS, sz);
    gc.p_cache = null;
    gc.size_cache = 0;
    gc.free_mem -= new_size - blk_size;
    // update the size cache, assuming that is very likely the size of this
    // block will be queried in the near future
    pool.update_cache(p, new_size);

    if (has_pm) {
        new_size -= size_t.sizeof;
        auto end_of_blk = cast(size_t**)(blk_base_addr + new_size);
        *end_of_blk = pm_bitmask;
    }

    early_collect();

    return new_size;
}


//
//
//
private void free(void *p)
{
    assert (p);

    Pool*  pool;
    size_t pagenum;
    Bins   bin;
    size_t bit_i;

    // Find which page it is in
    pool = findPool(p);
    if (!pool)                              // if not one of ours
        return;                             // ignore
    if (opts.options.sentinel) {
        sentinel_Invariant(p);
        p = sentinel_sub(p);
    }
    pagenum = cast(size_t)(p - pool.baseAddr) / PAGESIZE;
    bit_i = cast(size_t)(p - pool.baseAddr) / 16;
    clrAttr(pool, bit_i, uint.max);

    bin = cast(Bins)pool.pagetable[pagenum];
    if (bin == B_PAGE)              // if large alloc
    {
        // Free pages
        size_t npages = 1;
        size_t n = pagenum;
        pool.freebits.set_group(bit_i, PAGESIZE / 16);
        while (++n < pool.npages && pool.pagetable[n] == B_PAGEPLUS)
            npages++;
        size_t size = npages * PAGESIZE;
        if (opts.options.mem_stomp)
            memset(p, 0xF2, size);
        pool.freePages(pagenum, npages);
        gc.free_mem += size;
        // just in case we were caching this pointer
        pool.clear_cache(p);
    }
    else
    {
        // Add to free list
        List* list = cast(List*) p;

        if (opts.options.mem_stomp)
            memset(p, 0xF2, binsize[bin]);

        list.next = gc.free_list[bin];
        list.pool = pool;
        gc.free_list[bin] = list;
        pool.freebits.set(bit_i);
        gc.free_mem += binsize[bin];
    }
    double percent_free = gc.free_mem * 100.0 / gc.total_mem;
    if (percent_free > opts.options.min_free)
        minimize(false);
}


/**
 * Determine the allocated size of pointer p.  If p is an interior pointer
 * or not a gc allocated pointer, return 0.
 */
private size_t sizeOf(void *p)
{
    assert (p);

    if (opts.options.sentinel)
        p = sentinel_sub(p);

    Pool* pool = findPool(p);
    if (pool is null)
        return 0;

    auto biti = cast(size_t)(p - pool.baseAddr) / 16;
    uint attrs = getAttr(pool, biti);

    size_t size = pool.findSize(p);
    size_t pm_bitmask_size = 0;
    if (has_pointermap(attrs))
        pm_bitmask_size = size_t.sizeof;

    if (opts.options.sentinel) {
        // Check for interior pointer
        // This depends on:
        // 1) size is a power of 2 for less than PAGESIZE values
        // 2) base of memory pool is aligned on PAGESIZE boundary
        if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
            return 0;
        return size - SENTINEL_EXTRA - pm_bitmask_size;
    }
    else {
        if (p == gc.p_cache)
            return gc.size_cache;

        // Check for interior pointer
        // This depends on:
        // 1) size is a power of 2 for less than PAGESIZE values
        // 2) base of memory pool is aligned on PAGESIZE boundary
        if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
            return 0;

        gc.p_cache = p;
        gc.size_cache = size - pm_bitmask_size;

        return gc.size_cache;
    }
}


/**
 * Verify that pointer p:
 *  1) belongs to this memory pool
 *  2) points to the start of an allocated piece of memory
 *  3) is not on a free list
 */
private void checkNoSync(void *p)
{
    assert(p);

    if (opts.options.sentinel)
        sentinel_Invariant(p);
    debug (PTRCHECK)
    {
        Pool*  pool;
        size_t pagenum;
        Bins   bin;
        size_t size;

        if (opts.options.sentinel)
            p = sentinel_sub(p);
        pool = findPool(p);
        assert(pool);
        pagenum = cast(size_t)(p - pool.baseAddr) / PAGESIZE;
        bin = cast(Bins)pool.pagetable[pagenum];
        assert(bin <= B_PAGE);
        size = binsize[bin];
        assert((cast(size_t)p & (size - 1)) == 0);

        debug (PTRCHECK2)
        {
            if (bin < B_PAGE)
            {
                // Check that p is not on a free list
                for (List* list = gc.free_list[bin]; list; list = list.next)
                {
                    assert(cast(void*)list != p);
                }
            }
        }
    }
}


//
//
//
private void setStackBottom(void *p)
{
    version (STACKGROWSDOWN)
    {
        //p = (void *)((uint *)p + 4);
        if (p > gc.stack_bottom)
        {
            gc.stack_bottom = p;
        }
    }
    else
    {
        //p = (void *)((uint *)p - 4);
        if (p < gc.stack_bottom)
        {
            gc.stack_bottom = cast(char*)p;
        }
    }
}


/**
 * Retrieve statistics about garbage collection.
 * Useful for debugging and tuning.
 */
private GCStats getStats()
{
    GCStats stats;
    size_t psize = 0;
    size_t usize = 0;
    size_t flsize = 0;

    size_t n;
    size_t bsize = 0;

    for (n = 0; n < gc.pools.length; n++)
    {
        Pool* pool = gc.pools[n];
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
        for (List* list = gc.free_list[n]; list; list = list.next)
            flsize += binsize[n];
    }

    usize = bsize - flsize;

    stats.poolsize = psize;
    stats.usedsize = bsize - flsize;
    stats.freelistsize = flsize;
    return stats;
}

/******************* weak-reference support *********************/

private struct WeakPointer
{
    Object reference;

    void ondestroy(Object r)
    {
        assert(r is reference);
        // lock for memory consistency (parallel readers)
        // also ensures that weakpointerDestroy can be called while another
        // thread is freeing the reference with "delete"
        return locked!(void, () {
            reference = null;
        })();
    }
}

/**
 * Create a weak pointer to the given object.
 * Returns a pointer to an opaque struct allocated in C memory.
 */
void* weakpointerCreate( Object r )
{
    if (r)
    {
        // must be allocated in C memory
        // 1. to hide the reference from the GC
        // 2. the GC doesn't scan delegates added by rt_attachDisposeEvent
        //    for references
        auto wp = cast(WeakPointer*)(cstdlib.malloc(WeakPointer.sizeof));
        if (!wp)
            onOutOfMemoryError();
        wp.reference = r;
        rt_attachDisposeEvent(r, &wp.ondestroy);
        return wp;
    }
    return null;
}

/**
 * Destroy a weak pointer returned by weakpointerCreate().
 * If null is passed, nothing happens.
 */
void weakpointerDestroy( void* p )
{
    if (p)
    {
        auto wp = cast(WeakPointer*)p;
        // must be extra careful about the GC or parallel threads
        // finalizing the reference at the same time
        return locked!(void, () {
            if (wp.reference)
                rt_detachDisposeEvent(wp.reference, &wp.ondestroy);
        })();
    }
}

/**
 * Query a weak pointer and return either the object passed to
 * weakpointerCreate, or null if it was free'd in the meantime.
 * If null is passed, null is returned.
 */
Object weakpointerGet( void* p )
{
    if (p)
    {
        // NOTE: could avoid the lock by using Fawzi style GC counters but
        // that'd require core.sync.Atomic and lots of care about memory
        // consistency it's an optional optimization see
        // http://dsource.org/projects/tango/browser/trunk/user/tango/core/Lifetime.d?rev=5100#L158
        return locked!(Object, () {
            return (cast(WeakPointer*)p).reference;
        })();
    }

    return null;
}


/* ============================ Pool  =============================== */


struct Pool
{
    byte* baseAddr;
    byte* topAddr;
    GCBits mark;     // entries already scanned, or should not be scanned
    GCBits scan;     // entries that need to be scanned
    GCBits freebits; // entries that are on the free list
    GCBits finals;   // entries that need finalizer run on them
    GCBits noscan;   // entries that should not be scanned
    GCBits appendable;  // entries that can be appended to without re-allocation

    size_t npages;
    ubyte* pagetable;

    /// Cache for findSize()
    size_t cached_size;
    void* cached_ptr;

    void clear_cache(void* ptr = null)
    {
        if (ptr is null || ptr is this.cached_ptr) {
            this.cached_ptr = null;
            this.cached_size = 0;
        }
    }

    void update_cache(void* ptr, size_t size)
    {
        this.cached_ptr = ptr;
        this.cached_size = size;
    }

    void initialize(size_t npages)
    {
        size_t poolsize = npages * PAGESIZE;
        assert(poolsize >= POOLSIZE);
        baseAddr = cast(byte *) os.alloc(poolsize);

        // Some of the code depends on page alignment of memory pools
        assert((cast(size_t)baseAddr & (PAGESIZE - 1)) == 0);

        if (!baseAddr)
        {
            npages = 0;
            poolsize = 0;
        }
        topAddr = baseAddr + poolsize;

        size_t nbits = cast(size_t)poolsize / 16;

        // if the GC will run in parallel in a fork()ed process, we need to
        // share the mark bits
        os.Vis vis = os.Vis.PRIV;
        if (opts.options.fork)
            vis = os.Vis.SHARED;
        mark.alloc(nbits, vis); // shared between mark and sweep
        freebits.alloc(nbits); // not used by the mark phase
        scan.alloc(nbits); // only used in the mark phase
        finals.alloc(nbits); // not used by the mark phase
        noscan.alloc(nbits); // mark phase *MUST* have a snapshot
        appendable.alloc(nbits); // used only by runtime, ignored in mark phase

        // all is free when we start
        freebits.set_all();

        // avoid accidental sweeping of new pools while using eager allocation
        if (collect_in_progress())
            mark.set_all();

        pagetable = cast(ubyte*) cstdlib.malloc(npages);
        if (!pagetable)
            onOutOfMemoryError();
        memset(pagetable, B_FREE, npages);

        this.npages = npages;
    }


    void Dtor()
    {
        if (baseAddr)
        {
            int result;

            if (npages)
            {
                result = os.dealloc(baseAddr, npages * PAGESIZE);
                assert(result);
                npages = 0;
            }

            baseAddr = null;
            topAddr = null;
        }
        // See Gcx.Dtor() for the rationale of the null check.
        if (pagetable)
            cstdlib.free(pagetable);

        os.Vis vis = os.Vis.PRIV;
        if (opts.options.fork)
            vis = os.Vis.SHARED;
        mark.Dtor(vis);
        freebits.Dtor();
        scan.Dtor();
        finals.Dtor();
        noscan.Dtor();
        appendable.Dtor();
    }


    bool Invariant() const
    {
        return true;
    }


    invariant
    {
        //mark.Invariant();
        //scan.Invariant();
        //freebits.Invariant();
        //finals.Invariant();
        //noscan.Invariant();

        if (baseAddr)
        {
            //if (baseAddr + npages * PAGESIZE != topAddr)
                //printf("baseAddr = %p, npages = %d, topAddr = %p\n", baseAddr, npages, topAddr);
            assert(baseAddr + npages * PAGESIZE == topAddr);
        }

        for (size_t i = 0; i < npages; i++)
        {
            Bins bin = cast(Bins)pagetable[i];
            assert(bin < B_MAX);
        }
    }


    /**
     * Allocate n pages from Pool.
     * Returns OPFAIL on failure.
     */
    size_t allocPages(size_t n)
    {
        size_t i;
        size_t n2;

        n2 = n;
        for (i = 0; i < npages; i++)
        {
            if (pagetable[i] == B_FREE)
            {
                if (--n2 == 0)
                    return i - n + 1;
            }
            else
                n2 = n;
        }
        return OPFAIL;
    }


    /**
     * Free npages pages starting with pagenum.
     */
    void freePages(size_t pagenum, size_t npages)
    {
        memset(&pagetable[pagenum], B_FREE, npages);
    }


    /**
     * Find base address of block containing pointer p.
     * Returns null if the pointer doesn't belong to this pool
     */
    void* findBase(void *p)
    {
        size_t offset = cast(size_t)(p - this.baseAddr);
        size_t pagenum = offset / PAGESIZE;
        Bins bin = cast(Bins)this.pagetable[pagenum];
        // Adjust bit to be at start of allocated memory block
        if (bin <= B_PAGE)
            return this.baseAddr + (offset & notbinsize[bin]);
        if (bin == B_PAGEPLUS) {
            do {
                --pagenum, offset -= PAGESIZE;
            } while (cast(Bins)this.pagetable[pagenum] == B_PAGEPLUS);
            return this.baseAddr + (offset & (offset.max ^ (PAGESIZE-1)));
        }
        // we are in a B_FREE page
        return null;
    }


    /**
     * Find size of pointer p.
     * Returns 0 if p doesn't belong to this pool if if it's block size is less
     * than a PAGE.
     */
    size_t findSize(void *p)
    {
        size_t pagenum = cast(size_t)(p - this.baseAddr) / PAGESIZE;
        Bins bin = cast(Bins)this.pagetable[pagenum];
        if (bin != B_PAGE)
            return binsize[bin];
        if (this.cached_ptr == p)
            return this.cached_size;
        size_t i = pagenum + 1;
        for (; i < this.npages; i++)
            if (this.pagetable[i] != B_PAGEPLUS)
                break;
        this.cached_ptr = p;
        this.cached_size = (i - pagenum) * PAGESIZE;
        return this.cached_size;
    }


    /**
     * Used for sorting pools
     */
    int opCmp(in Pool other)
    {
        if (baseAddr < other.baseAddr)
            return -1;
        else
        return cast(int)(baseAddr > other.baseAddr);
    }
}


/* ============================ SENTINEL =============================== */


enum size_t SENTINEL_PRE = cast(size_t) 0xF4F4F4F4F4F4F4F4UL; // 32 or 64 bits
enum ubyte SENTINEL_POST = 0xF5;           // 8 bits
enum uint SENTINEL_EXTRA = 2 * size_t.sizeof + 1;


size_t* sentinel_size(void *p)  { return &(cast(size_t *)p)[-2]; }
size_t* sentinel_pre(void *p)   { return &(cast(size_t *)p)[-1]; }
ubyte* sentinel_post(void *p) { return &(cast(ubyte *)p)[*sentinel_size(p)]; }


void sentinel_init(void *p, size_t size)
{
    *sentinel_size(p) = size;
    *sentinel_pre(p) = SENTINEL_PRE;
    *sentinel_post(p) = SENTINEL_POST;
}


void sentinel_Invariant(void *p)
{
    if (*sentinel_pre(p) != SENTINEL_PRE ||
            *sentinel_post(p) != SENTINEL_POST)
        cstdlib.abort();
}


void *sentinel_add(void *p)
{
    return p + 2 * size_t.sizeof;
}


void *sentinel_sub(void *p)
{
    return p - 2 * size_t.sizeof;
}



/* ============================ C Public Interface ======================== */


private int _termCleanupLevel=1;

extern (C):

/// sets the cleanup level done by gc
/// 0: none
/// 1: fullCollect
/// 2: fullCollect ignoring stack roots (might crash daemonThreads)
/// result !=0 if the value was invalid
int gc_setTermCleanupLevel(int cLevel)
{
    if (cLevel<0 || cLevel>2) return cLevel;
    _termCleanupLevel=cLevel;
    return 0;
}

/// returns the cleanup level done by gc
int gc_getTermCleanupLevel()
{
    return _termCleanupLevel;
}

void gc_init()
{
    scope (exit) assert (Invariant());
    gc = cast(GC*) cstdlib.calloc(1, GC.sizeof);
    *gc = GC.init;

    initialize();

    version (DigitalMars) version(OSX) {
        _d_osx_image_init();
    }
}

void gc_term()
{
    assert (Invariant());
    if (_termCleanupLevel<1) {
        // no cleanup
    } else if (_termCleanupLevel==2){
        // a more complete cleanup
        // NOTE: There may be daemons threads still running when this routine is
        //       called.  If so, cleaning memory out from under then is a good
        //       way to make them crash horribly.
        //       Often this probably doesn't matter much since the app is
        //       supposed to be shutting down anyway, but for example tests might
        //       crash (and be considerd failed even if the test was ok).
        //       thus this is not the default and should be enabled by
        //       I'm disabling cleanup for now until I can think about it some
        //       more.
        //
        // not really a 'collect all' -- still scans static data area, roots,
        // and ranges.
        return locked!(void, () {
            gc.no_stack++;
            fullcollectshell(false, true); // force block
            gc.no_stack--;
        })();
    } else {
        // default (safe) clenup
        return locked!(void, () {
            fullcollectshell(false, true); // force block
        })();
    }
}

void gc_enable()
{
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        assert (gc.disabled > 0);
        gc.disabled--;
    })();
}

void gc_disable()
{
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        gc.disabled++;
    })();
}

void gc_collect()
{
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        fullcollectshell();
    })();
}


void gc_minimize()
{
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        minimize();
    })();
}

uint gc_getAttr(void* p)
{
    if (p is null)
        return 0;
    return locked!(uint, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        Pool* pool = findPool(p);
        if (pool is null)
            return 0u;
        auto bit_i = cast(size_t)(p - pool.baseAddr) / 16;
        return getAttr(pool, bit_i);
    })();
}

uint gc_setAttr(void* p, uint attrs)
{
    if (p is null)
        return 0;
    return locked!(uint, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        Pool* pool = findPool(p);
        if (pool is null)
            return 0u;
        auto bit_i = cast(size_t)(p - pool.baseAddr) / 16;
        uint old_attrs = getAttr(pool, bit_i);
        setAttr(pool, bit_i, attrs);
        return old_attrs;
    })();
}

uint gc_clrAttr(void* p, uint attrs)
{
    if (p is null)
        return 0;
    return locked!(uint, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        Pool* pool = findPool(p);
        if (pool is null)
            return 0u;
        auto bit_i = cast(size_t)(p - pool.baseAddr) / 16;
        uint old_attrs = getAttr(pool, bit_i);
        clrAttr(pool, bit_i, attrs);
        return old_attrs;
    })();
}

void* gc_malloc(size_t size, uint attrs = 0)
{
    if (size == 0)
        return null;
    return locked!(void*, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return malloc(size, attrs);
    })();
}

void* gc_calloc(size_t size, uint attrs = 0)
{
    if (size == 0)
        return null;
    return locked!(void*, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return calloc(size, attrs);
    })();
}

void* gc_realloc(void* p, size_t size, uint attrs = 0)
{
    return locked!(void*, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return realloc(p, size, attrs);
    })();
}

size_t gc_extend(void* p, size_t min_size, size_t max_size)
{
    return locked!(size_t, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return extend(p, min_size, max_size);
    })();
}

size_t gc_reserve(size_t size)
{
    if (size == 0)
        return 0;
    return locked!(size_t, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return reserve(size);
    })();
}

void gc_free(void* p)
{
    if (p is null)
        return;
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        free(p);
    })();
}

void* gc_addrOf(void* p)
{
    if (p is null)
        return null;
    return locked!(void*, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        Pool* pool = findPool(p);
        if (pool is null)
            return null;
        return pool.findBase(p);
    })();
}

size_t gc_sizeOf(void* p)
{
    if (p is null)
        return 0;
    return locked!(size_t, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return sizeOf(p);
    })();
}

BlkInfo gc_query(void* p)
{
    if (p is null)
        return BlkInfo.init;
    return locked!(BlkInfo, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return getInfo(p);
    })();
}

// NOTE: This routine is experimental.  The stats or function name may change
//       before it is made officially available.
GCStats gc_stats()
{
    return locked!(GCStats, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        return getStats();
    })();
}

void gc_addRoot(void* p)
{
    if (p is null)
        return;
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        if (gc.roots.append(p) is null)
            onOutOfMemoryError();
    })();
}

void gc_addRange(void* p, size_t size)
{
    if (p is null || size == 0)
        return;
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        if (gc.ranges.append(Range(p, p + size)) is null)
            onOutOfMemoryError();
    })();
}

void gc_removeRoot(void* p)
{
    if (p is null)
        return;
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        bool r = gc.roots.remove(p);
        assert (r);
    })();
}

void gc_removeRange(void* p)
{
    if (p is null)
        return;
    return locked!(void, () {
        assert (Invariant()); scope (exit) assert (Invariant());
        bool r = gc.ranges.remove(Range(p, null));
        assert (r);
    })();
}

void* gc_weakpointerCreate(Object r)
{
    // weakpointers do their own locking
    return weakpointerCreate(r);
}

void gc_weakpointerDestroy(void* wp)
{
    // weakpointers do their own locking
    weakpointerDestroy(wp);
}

Object gc_weakpointerGet(void* wp)
{
    // weakpointers do their own locking
    return weakpointerGet(wp);
}

private alias extern(D) void delegate() begin_del;
private alias extern(D) void delegate(int, int) end_del;
void gc_monitor(begin_del begin, end_del end)
{
    locked!(void, () {
        //casts are a workaround for a dmdfe bug present in 1.064, but fixed in 1.066
        gc.collect_begin_cb = cast(typeof(gc.collect_begin_cb)) begin;
        gc.collect_end_cb = cast(typeof(gc.collect_end_cb)) end;
    })();
}

void gc_usage(size_t* used, size_t* free)
{
    *free = gc.free_mem;
    *used = gc.total_mem - gc.free_mem;
}

BlkInfo gc_qalloc( size_t sz, uint ba = 0 )
{
    BlkInfo retval;
    retval.base = malloc( sz, ba, retval.size );
    retval.attr = ba;
    return retval;
}

void gc_runFinalizers( in void[] segment ) nothrow
{
    // TODO
}

// vim: set et sw=4 sts=4 :
