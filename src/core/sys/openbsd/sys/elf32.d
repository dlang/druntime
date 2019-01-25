/**
 * D header file for OpenBSD
 *
 * https://cvsweb.openbsd.org/src/sys/sys/exec_elf.h
 */
module core.sys.openbsd.sys.elf32;

version (OpenBSD):
    extern (C):
    pure:
    nothrow:
    
    import core.stdc.stdint;
    public import core.sys.openbsd.sys.elf_common;

    alias uint16_t Elf32_Half;      // Unsigned medium integer
    alias uint32_t Elf32_Word;      // Unsigned large integer
    alias int32_t  Elf32_Sword;     // Signed large integer
    alias uint64_t Elf32_Lword;     // Added to OpenBSD: 2019/1/22
    alias uint32_t Elf32_Addr;      // Unsigned program address
    alias uint32_t Elf32_off;       // Unsigned file offset

    struct Elf32_Ehdr
    {
        char[EI_NIDENT] e_ident = 0;    // ELF Identification
        Elf32_Half    e_type;           // object file type
        Elf32_Half    e_machine;        // machine
        Elf32_Word    e_version;        // object file version
        Elf32_Addr    e_entry;          // virtual entry point
        Elf32_Off     e_phoff;          // program header table offset
        Elf32_Off     e_shoff;          // section header table offset
        Elf32_Word    e_flags;          // processor-specific flags
        Elf32_Half    e_ehsize;         // ELF header size
        Elf32_Half    e_phentsize;      // program header entry size
        Elf32_Half    e_phnum;          // number of program header entries
        Elf32_Half    e_shentsize;      // section header entry size
        Elf32_Half    e_shnum;          // number of section header entries
        Elf32_Half    e_shstrndx;       // section header table's "section
                                        // header string table" entry offset
    }

    // Section header
    struct Elf32_Shdr
    {
        Elf32_Word    sh_name;          // name - index into section header string table section
        Elf32_Word    sh_type;          // type
        Elf32_Word    sh_flags;         // flags
        Elf32_Addr    sh_addr;          // address
        Elf32_Off     sh_offset;        // file offset
        Elf32_Word    sh_size;          // section size
        Elf32_Word    sh_link;          // section header table index link
        Elf32_Word    sh_info;          // extra information
        Elf32_Word    sh_addralign;     // address alignment
        Elf32_Word    sh_entsize;       // section entry size
    }

    // Program header
    struct Elf32_Phdr
    {
        Elf32_Word    p_type;       // segment type
        Elf32_Off     p_offset;     // segment offset
        Elf32_Addr    p_vaddr;      // virtual address of segment
        Elf32_Addr    p_paddr;      // physical address - ignored?
        Elf32_Word    p_filesz;     // number of bytes in file for seg.
        Elf32_Word    p_memsz;      // number of bytes in mem. for seg.
        Elf32_Word    p_flags;      // flags
        Elf32_Word    p_align;      // memory alignment
    }

    // Dynamic structure
    struct Elf32_Dyn
    {
      Elf32_Sword   d_tag;      // controls meaning of d_val
      union _d_un
      {
          Elf32_Word d_val;     // Multiple meanings - see d_tag
          Elf32_Addr d_ptr;     // program virtual address
      } _d_un d_un;
    }

    // Relocation entry with implicit addend
    struct Elf32_Rel
    {
        Elf32_Addr    r_offset; // offset of relocation
        Elf32_Word    r_info;   // symbol table index and type
    }

    // Relocation entry with explicit addend
    struct Elf32_Rela
    {
        Elf32_Addr    r_offset; // offset of relocation
        Elf32_Word    r_info;   // symbol table index and type
        Elf32_Sword   r_addend;
    }

    extern (D)
    {
        auto ELF32_R_SYM(V)(V val) { return val >> 8; }
        auto ELF32_R_TYPE(V)(V val) { return val & 0xff; }
        auto ELF32_R_INFO(S, T)(S sym, T type) { return (sym << 8) + (type & 0xff); }
    }

    // Symbol table entry
    struct Elf32_Sym
    {
        Elf32_Word    st_name;  // name - index into string table
        Elf32_Addr    st_value; // symbol value
        Elf32_Word    st_size;  // symbol size
        ubyte st_info;          // type and binding
        ubyte st_other;         // 0 - no defined meaning
        Elf32_Half st_shndx;    // section header index
    }

    extern (D)
    {
        auto ELF32_ST_BIND(T)(T val) { return cast(ubyte)val >> 4; }
        auto ELF32_ST_TYPE(T)(T val) { return val & 0xf; }
        auto ELF32_ST_INFO(B, T)(B bind, T type) { return (bind << 4) + (type & 0xf); }
        auto ELF32_ST_VISIBILITY(O)(O o) { return o & 0x03; }
    }
    
