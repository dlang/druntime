/** 
  * D header file for OpenBSD
  *
  * Path to online source file reference goes here
  */
module core.sys.openbsd.sys.link_elf;

version (OpenBSD):
    extern (C):
    nothrow:

    import core.stdc.stdint : uint64_t;
    import core.sys.posix.sys.types : caddr_t;
    import core.sys.openbsd.sys.elf;

    version (D_LP64)
        enum __ELF_NATIVE_CLASS = 64;
    else
        enum __ELF_NATIVE_CLASS = 32;

    template ElfW(string type)
    {
        mixin("alias Elf"~__ELF_NATIVE_CLASS.stringof~"_"~type~" ElfW;");
    }

    struct link_map
    {
        caddr_t     l_addr;     // Base address of library
        char*       l_name;     // Absolute path to library
        void*       l_ld;       // pointer to _DYNAMIC
        link_map*   l_next;
        link_map*   l_prev;
    }
    alias link_map Link_map;

    enum
    {
        RT_CONSISTEN,
        RT_ADD,
        RT_DELETE,
    }

    struct dl_phdr_info
    {
        ElfW!"Addr"     dlpi_addr;
        char*           dlpi_name;
        ElfW!"Phdr"*    dlpi_phdr;
        ElfW!"Half"     dlpi_phnum;
    };

    private alias extern(C) int function(dl_phdr_info*, size_t, void *) dl_iterate_phdr_cb;
    private alias extern(C) int function(dl_phdr_info*, size_t, void *) @nogc dl_iterate_phdr_cb_ngc;
    extern int dl_iterate_phdr(dl_iterate_phdr_cb __callback, void*__data);
    extern int dl_iterate_phdr(dl_iterate_phdr_cb_ngc __callback, void*__data) @nogc;
