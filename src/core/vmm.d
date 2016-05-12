module core.vmm;

/**
    $(P The module aims to provide the most commonly useful features of
    target OS virtual memory manager subsystem. )

    $(P The primary goal is not to provide full potential of every OS as
        that is next impossible due to inherent differences.
        Instead the goal is to cover $(STRONG the most common) scenarios
        in an $(STRONG optimal) way. In particular issuing the absolute minimum
        of system calls for each scenario.
    )

    Major use cases covered:
    $(LI Getting platform's page size as cheap as reading a global. See $(LREF pageSize).
    It takes a single system call at application start up.)
    $(LI Allocating a memory block that has executable permission. A must have for JITs.
    See $(LREF allocate) to allocate a block and set permissions in one call.)
    $(LI Reserving a large virtual memory range and gradually committing memory from it.
    Important for data-heavy applications. The permissions are set to read/write.
    See $$(LREF reserve) and $(LREF commit).)
    $(LI Locking a range of memory pages to persist in physical memory
        (avoid being paging out by OS). See $(LREF lock) and $(LREF unlock).)

    $(P API provides a way to perform less common operations but may have some overhead
    compared to writing platform-specific code.)

*/

import core.thread;

/// Flags that specify desired kind of access to the memory.
enum MemoryAccess : uint
{
    none =      0b0000_0000,
    read =      0b0000_0001,
    write =     0b0000_0010,
    execute =   0b0000_0100,
    readWrite = read | write,
    readWriteExecute = read | write | execute,
};

/**
    Flags that specify additional memory options.
    BUGS: None of these are implemented yet.
*/
enum MemoryOptions : uint
{
    none =      0b0000_0000,
    hugePages = 0b0001_0000
};

/// The page size as reported by the OS at the application start.
public alias pageSize = PAGESIZE;

//TODO: provide the same for huge page size

/**
    Allocate a block of $(D size) bytes of virtual memory rounded up to
    nearest multiple of page size. The memory is allocated
    with specified permissions and options.

    $(D base) specifies the desired base address of the block, $(D null)
    means any base address.

    To release a block of memory allocated by this function use $(LREF free).

    Note: This operation commits virtual memory.
    To have fine grained control over reserve and commit phases
    use $(LREF reserve) and $(LREF commit).
*/
void[] allocate(void* base, size_t size,
    MemoryAccess access = MemoryAccess.readWrite,
    MemoryOptions options = MemoryOptions.none)
{
    size = roundUpToPage(size);
    void* ptr = osMap(base, size, access, options);
    return ptr ? ptr[0..size] : null;
}

/**
    Reserve a block of $(D size) bytes of virtual memory rounded up
    to nearest multiple of page size. The memory is not commited
    and/or OS is not explicitly asked to assign memory pages to it.

    $(D base) specifies the desired base address of the block, $(D null)
    means any base address.

    To release a virtual memory range reserved by this function use $(LREF free).

    Note: This function and $(LREF commit)
    set read/write permissions but not execute.
    The reason is that some OS would set permissions on reserve
    while others on commit. Also Posix makes the commit stage almost transparent.
    Use $(LREF protect) to override permissions as required.
*/
void[] reserve(void* base, size_t size)
{
    size = roundUpToPage(size);
    void* ptr = osReserve(base, size);
    return ptr ? ptr[0..size] : null;
}

/**
    Commit a set of pages that form the specified $(D range) of virtual memory.
    Only after applying this call is any memory obtained via $(LREF reserve)
    guaranteed to be accessible.

    Note: This function and $(LREF reserve)
    set read/write permissions but not execute.
    The reason is that some OS' would set permissions on reserve
    while others on commit. Also Posix makes the commit stage almost transparent.
    Use $(LREF protect) to override permissions as required.
*/
bool commit(void[] range)
{
    return osCommit(range.ptr, range.length);
}

/**
    Resets a set of pages that form the specified $(D range) of virtual memory.
    This instructs an OS that data in the pages is no loger of interest to the application,
    so it's free to reuse any of page involved while keeping mapping intact.
    Subsequent access will result in either reading a prior data or a fresh page.

*/
bool reset(void[] range)
{
    return osReset(range.ptr, range.length);
}


/**
    Decommit a set of pages that form the specified $(D range) of virtual memory.
    While system retains the address space range, accessing memory inside of it
    is illegal. The exact consequences of such illegal access are platform
    dependent.

*/
bool decommit(void[] range)
{
    return osDecommit(range.ptr, range.length);
}

/**
    Decommit and releases pages that were previously allocated and/or reserved.
    $(D range) must contain exactly the same address range as the one
    returned by $(LREF allocate) or $(LREF reserve).

    It doesn't matter what the state of each page was (reserved vs commited),
    the OS decommits pages as needed.
*/
bool free(void[] range)
{
    return osUnmap(range.ptr, range.length);
}

/**
    Set permissions on the set of pages that form $(D range).
*/
bool protect(void[] range, MemoryAccess access)
{
    return osProtect(range.ptr, range.length, access);
}

/**
    Lock pages that form $(D range) to prevent their paging out.
*/
bool lock(void[] range)
{
    return osLockPages(range.ptr, range.length);
}

/**
    Undo the effect of locking (with $(LREF lock)) pages that form $(D range).
*/
bool unlock(void[] range)
{
    return osUnlockPages(range.ptr, range.length);
}

/**
    Round up a pointer or integral $(D arg)
    to the nearest multiple of platform's page size.
*/
T roundUpToPage(T)(T arg)
    if (is(T : void*) || is(T : size_t))
{
    return cast(T)((cast(size_t)arg + pageSize-1) & ~(pageSize-1));
}

/**
    Round down a pointer or integral $(D arg)
    to the nearest multiple of platform's page size.
*/
T roundDownToPage(T)(T arg)
    if (is(T : void*) || is(T : size_t))
{
    return cast(T)(cast(size_t)arg & ~(pageSize-1));
}

//this is not even nearly covering all cases
//some things are hard to check (how to check that segmentation fault is generated?)
unittest
{
    auto pageSize = pageSize;
    import core.stdc.stdio;
    //power of 2
    assert((pageSize & (pageSize-1)) == 0);
    //alter when porting to some platform with smaller page size
    assert(pageSize >= 4096);
    auto slice = cast(ubyte[])allocate(null, pageSize/2);
    printf("<<<%d\n", slice.length);
    assert(slice.length == pageSize);
    foreach(i, ref v; slice)
    {
        v = cast(ubyte)i;
    }
    assert(slice[0] == 0);
    assert(slice[$-1] == ((slice.length-1) & 0xFF));
    assert(free(slice));

    slice = cast(ubyte[])reserve(null, pageSize*10+1);
    assert(slice.length == pageSize*11);
    import core.stdc.stdio;
    assert(commit(slice[0..$/2])); //5.5 pages --> 6 commited
    auto relSize = roundUpToPage(slice.length/2);
    assert(relSize == 6 * pageSize);
    foreach(i, ref c; slice[0..relSize])
    {
        c = cast(ubyte)i ^ 0xFF;
    }
    assert(slice[0] == 0xFF);
    assert(slice[pageSize] == (0xFF ^ cast(ubyte)pageSize));
    assert(slice[relSize-1] == (0xFF ^ cast(ubyte)(relSize-1)));
    assert(commit(slice[$/2..$]));
    slice[$-1] = 0xEA;
    assert(slice[$-1] == 0xEA);
//    assert(decommit(slice[$/2..$]));
//    assert(commit(slice[$/2..$]));
    //decommit - commit leaves memory zeroed-out on Linux/Windows
    version(Windows)
        assert(slice[$-1] == 0);
    version(Linux)
        assert(slice[$-1] == 0);

    version(FreeBSD){} // Conflicts with default ZFS memory settings
    else
    {
        assert(lock(slice), "failed to lock memory");
        assert(unlock(slice), "failed to unlock memory");
    }
    assert(protect(slice, MemoryAccess.read));
    free(slice);
}

//------------------------
//OS specific section
//------------------------
private:

version(Windows)
{
    import core.sys.windows.windows;

    uint protectionFlags(MemoryAccess access)
    {
        //these are not combinable bit flags on win32
        uint protFlags;
        switch(access)
        {
        case MemoryAccess.none:
            protFlags = PAGE_NOACCESS;
            break;
        case MemoryAccess.read:
            protFlags = PAGE_READONLY;
            break;
        case MemoryAccess.readWrite:
        case MemoryAccess.write:
            protFlags = PAGE_READWRITE; // no write-only
            break;
        case MemoryAccess.execute:
            protFlags = PAGE_EXECUTE;
            break;
        case MemoryAccess.read | MemoryAccess.execute:
            protFlags = PAGE_EXECUTE_READ;
            break;
        case MemoryAccess.read | MemoryAccess.write | MemoryAccess.execute:
        case MemoryAccess.write | MemoryAccess.execute:
            protFlags = PAGE_EXECUTE_READWRITE; // no write-only + execute
            break;
        default:
            assert(false, "bad memory access flags");
        }
        return protFlags;
    }

    uint memoryOptions(uint options)
    {
        //TODO: no huge pages yet, the whole procedure isn't trivial
        return 0;
    }

    void *osMap(void* base, size_t nbytes, MemoryAccess access, uint options)
    {
        return VirtualAlloc(base, nbytes,
                MEM_RESERVE | MEM_COMMIT | memoryOptions(options),
                protectionFlags(access));
    }

    bool osUnmap(void *base, size_t nbytes)
    {
        return VirtualFree(base, 0, MEM_RELEASE) != 0;
    }

    void* osReserve(void* base, size_t size)
    {
        return VirtualAlloc(base, size, MEM_RESERVE,
            PAGE_READWRITE);
    }

    bool osCommit(void* ptr, size_t size)
    {
        ptr = VirtualAlloc(ptr, size, MEM_COMMIT, PAGE_READWRITE);
        return ptr != null;
    }

    bool osReset(void* ptr, size_t size)
    {
        return VirtualFree(ptr, size, MEM_RESET) != 0;
    }

    bool osDecommit(void* ptr, size_t size)
    {
        return VirtualFree(ptr, size, MEM_DECOMMIT) != 0;
    }

    bool osProtect(void* ptr, size_t size, MemoryAccess access)
    {
        uint oldProt;
        return VirtualProtect(ptr, size, protectionFlags(access), &oldProt) != 0;
    }

    bool osLockPages(void* ptr, size_t size)
    {
        return VirtualLock(ptr, size) != 0;
    }

    bool osUnlockPages(void* ptr, size_t size)
    {
        return VirtualUnlock(ptr, size) != 0;
    }
}
else version(Posix)
{
    version(linux)
        import core.sys.linux.sys.mman;
    else version(FreeBSD)
        import core.sys.freebsd.sys.mman;
    else version(OSX)
        import core.sys.darwin.sys.mman;
    else
        import core.sys.posix.sys.mman;

    uint protectionFlags(MemoryAccess access)
    {
        if(access == MemoryAccess.none)
            return PROT_NONE;
        uint protFlags;
        if(access & MemoryAccess.read)
            protFlags |= PROT_READ;
        if(access & MemoryAccess.write)
            protFlags |= PROT_WRITE;
        if(access & MemoryAccess.execute)
            protFlags |= PROT_EXEC;
        return protFlags;
    }

    uint memoryFlags(uint options)
    {
        //TODO: no huge pages yet, the whole procedure isn't trivial
        version(linux)
            return MAP_PRIVATE | MAP_ANONYMOUS;
        else
            return MAP_PRIVATE | MAP_ANON;
    }

    void* osMap(void* base, size_t nbytes, MemoryAccess access, uint options)
    {
        uint memFlag = memoryFlags(options) | (base == null ? 0 : MAP_FIXED);
        void* p = mmap(base, nbytes, protectionFlags(access), memFlag, -1, 0);
        return p == MAP_FAILED ? null : p;
    }

    bool osUnmap(void *base, size_t nbytes)
    {
        return munmap(base, nbytes) == 0;
    }

    void* osReserve(void* base, size_t size)
    {
        return osMap(base, size, MemoryAccess.readWrite, MemoryOptions.none);
    }

    bool osCommit(void* ptr, size_t size)
    {
        ptr = roundDownToPage(ptr);
        size = roundUpToPage(size);
        version(linux)
            return madvise(ptr, size, MADV_WILLNEED) == 0;
        else
            return posix_madvise(ptr, size, POSIX_MADV_WILLNEED) == 0;
    }

    bool osDecommit(void* ptr, size_t size)
    {
        ptr = roundDownToPage(ptr);
        size = roundUpToPage(size);
        version(linux)
            return madvise(ptr, size, MADV_DONTNEED) == 0;
        else
            return posix_madvise(ptr, size, POSIX_MADV_DONTNEED) == 0;
    }

    bool osReset(void* ptr, size_t size)
    {
        ptr = roundDownToPage(ptr);
        size = roundUpToPage(size);
        version(FreeBSD)
            return madvise(ptr, size, MADV_FREE) == 0;
        else version(OSX)
            return madvise(ptr, size, MADV_FREE) == 0;
        else
            return false; // not supported on Linux
    }

    bool osProtect(void* ptr, size_t size, MemoryAccess access)
    {
        return mprotect(ptr, size, protectionFlags(access)) == 0;
    }

    bool osLockPages(void* ptr, size_t size)
    {
        return mlock(ptr, size) == 0;
    }

    bool osUnlockPages(void* ptr, size_t size)
    {
        return munlock(ptr, size) == 0;
    }
}
else
    static assert(false);
