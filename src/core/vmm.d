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
    $(LI Getting OS page size as cheap as reading a global. See $(LREF pageSize).
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

/**
    Struct that encapsulates OS facilities to manage virtual memory.
*/
struct VMM
{

    /// The page size as reported by the OS at the application start.
    static immutable size_t pageSize;

    //TODO: provide the same for huge page size

    /**
        Allocate a block of $(D size) bytes of virtual memory rounded up to 
        nearest multiple of page size. The memory is allocated 
        with specified permissions and options.

        Note: This operation commits virtual memory. 
        To have fine grained control over reserve and commit phases 
        use $(LREF reserve) and $(LREF commit).
    */
    static void[] allocate(void* base, size_t size, 
        MemoryAccess access = MemoryAccess.readWrite,
        MemoryOptions options = MemoryOptions.none)
    {
        size = (size + pageSize-1) & ~(pageSize-1);
        void* ptr = osMap(base, size, access, options);
        return ptr ? ptr[0..size] : null;
    }

    /**
        Reserve a $(D size) bytes of virtual memory rounded up 
        to nearest multiple of page size. The memory is not commited 
        and/or OS is not explicitly asked to assign memory pages to it.

        To release a virtual memory range reserved by this function use $(LREF free).

        Note: This function and $(LREF commit)
        set read/write permissions but not execute.
        The reason is that some OS would set permissions on reserve 
        while others on commit. Also Posix makes the commit stage almost transparent.
        Use $(LREF protect) to override permissions as required.
    */
    static void[] reserve(void* base, size_t size)
    {
        size = (size + pageSize-1) & ~(pageSize-1);
        void* ptr = osReserve(base, size);        
        return ptr ? ptr[0..size] : null;
    }

    /**
        Commits a set of pages that form the specified $(D range) of virtual memory.
        Only after applying this call is any memory obtained via $(LREF reserve)
        guaranteed to be accessible.

        Note: This function and $(LREF reserve)
        set read/write permissions but not execute.
        The reason is that some OS would set permissions on reserve 
        while others on commit. Also Posix makes the commit stage almost transparent.
        Use $(LREF protect) to override permissions as required.
    */
    static bool commit(void[] range)
    {
        return osCommit(range.ptr, range.length);
    }

    /**
        Decommits a set of pages that form the specified $(D range) of virtual memory.
        While system retains the address space range, accessing memory inside of it 
        is illegal. The exact consequences of such illegal access are platform 
        dependent.

    */
    static bool decommit(void[] range)
    {
        return osDecommit(range.ptr, range.length);
    }

    /**
        Decommits and releases pages that were previously allocated and/or reserved.        
        $(D range) must contain exactly the same address range as the one 
        returned by $(LREF allocate) or $(LREF reserve). 

        It doesn't matter what the state of each page was (reserved vs commited), 
        the OS decommits pages as needed.
    */
    static bool free(void[] range)
    {
        return osUnmap(range.ptr, range.length);
    }

    /**
        Sets permissions on the set of pages that form $(D range).        
    */
    static bool protect(void[] range, MemoryAccess access)
    {
        return osProtect(range.ptr, range.length, access);
    }

    /**
        Lock pages that form $(D range) to prevent their paging out.
    */
    static bool lock(void[] range)
    {
        return osLockPages(range.ptr, range.length);
    }

    /**
        Undoes the effect of locking (with $(LREF lock)) pages that form $(D range).        
    */
    static bool unlock(void[] range)
    {
        return osUnlockPages(range.ptr, range.length);
    }

    //code to initialize pageSize constant  
    version (Windows)
    {
        import core.sys.windows.windows;

        alias int pthread_t;

        pthread_t pthread_self()
        {
            return cast(pthread_t) GetCurrentThreadId();
        }


        shared static this()
        {
            SYSTEM_INFO sysinfo;
            GetSystemInfo(&sysinfo);
            pageSize = sysinfo.dwPageSize;
        }
    }
    else version (Posix)
    {
        import core.stdc.stdlib;

        shared static this()
        {
            pageSize = sysconf(_SC_PAGESIZE);
        }
    }
    else
        static assert(false);

}

//this is not even nearly covering all cases
//some things are hard to check (how to check that segmentation fault is generated?)
unittest
{
    auto pageSize = VMM.pageSize;    
    //power of 2
    assert((pageSize & (pageSize-1)) == 0);
    //alter when porting to some OS with smaller page size
    assert(pageSize >= 4096);
    auto slice = cast(ubyte[])VMM.allocate(null, pageSize/2);
    assert(slice.length == pageSize);
    foreach(i, ref v; slice)
    {
        v = cast(ubyte)i;
    }
    assert(slice[0] == 0);
    assert(slice[$-1] == ((slice.length-1) & 0xFF));
    assert(VMM.free(slice));

    slice = cast(ubyte[])VMM.reserve(null, pageSize*10+1);
    assert(slice.length == pageSize*11);
    assert(VMM.commit(slice[0..$/2]));
    auto relSize = (slice.length/2 + pageSize-1) & ~(pageSize-1);
    foreach(i, ref c; slice[0..relSize])
    {
        c = cast(ubyte)i ^ 0xFF;
    }
    assert(slice[0] == 0xFF);
    assert(slice[pageSize] == (0xFF ^ cast(ubyte)pageSize));
    assert(slice[relSize-1] == (0xFF ^ cast(ubyte)(relSize-1)));
    assert(VMM.commit(slice[$/2..$]));
    slice[$-1] = 0xEA;
    assert(slice[$-1] == 0xEA);
    assert(VMM.decommit(slice[$/2..$]));
    assert(VMM.commit(slice[$/2..$]));
    //decommit - commit leaves memory zeroed-out
    assert(slice[$-1] == 0);

    assert(VMM.lock(slice));
    assert(VMM.unlock(slice));
    assert(VMM.protect(slice, MemoryAccess.read));
    VMM.free(slice);
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
else static if (is(typeof(mmap)))  // else version (GC_Use_Alloc_MMap)
{
    import core.sys.posix.sys.mman;

    uint protectionFlags(uint access)
    {
        if(access == MemoryAccess.None)
            return PROT_NONE;        
        uint protFlags;
        if(access & MemoryAccess.Read)
            protFlags |= PROT_READ;
        if(access & MemoryAccess.Write)
            protFlags |= PROT_WRITE;
        if(access & MemoryAccess.Execute)
            protFlags |= PROT_EXEC;
        return protFlags;
    }

    uint memoryFlags(uint options)
    {
        //TODO: no huge pages yet, the whole procedure isn't trivial
        return MAP_PRIVATE | MAP_ANONYMOUS;
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
        return osMap(base, size);
    }

    bool osCommit(void* ptr, size_t size)
    {
        return madvise(ptr, size, MADV_WILLNEED) == 0;
    }

    bool osDecommit(void* ptr, size_t size)
    {
        return madvise(ptr, size, MADV_DONTNEED) == 0;
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