/**
 * D header file for OpenBSD
 *
 * https://cvsweb.openbsd.org/src/sys/sys/exec_elf.h
 */
module core.sys.openbsd.sys.elf64;

version (OpenBSD):
extern (C):
pure:
nothrow:

import core.stdc.stdint;
public import core.sys.openbsd.sys.elf_common;

alias uint64_t Elf64_Addr;
alias uint64_t Elf64_Off;
alias uint32_t Elf64_Half;
alias int32_t  Elf64_Shalf;
alias uint16_t Elf64_Quarter;
alias int64_t  Elf64_Sxword;
alias uint64_t Elf64_Xword;
alias uint64_t Elf64_Lword;     // Added to OpenBSD: 2019/1/22

version (Alpha)
{
    alias uint64_t Elf64_Word;
    alias int64_t  Elf64_Sword;
}
else
{
    alias uint32_t Elf64_Word;
    alias int32_t  Elf64_Sword;
}

struct Elf64_Ehdr
{
    char[EI_NIDENT] e_ident = 0;    // Id bytes
    Elf64_Quarter e_type;           // file type
    Elf64_Quarter e_machine;        // machine type
    Elf64_Half    e_version;        // version number
    Elf64_Addr    e_entry;          // entry point
    Elf64_Off     e_phoff;          // Program hdr offset
    Elf64_Off     e_shoff;          // Section hdr offset
    Elf64_Half    e_flags;          // Processor flags
    Elf64_Quarter e_ehsize;         // sizeof ehdr
    Elf64_Quarter e_phentsize;      // Program header entry size
    Elf64_Quarter e_phnum;          // Number of program headers
    Elf64_Quarter e_shentsize;      // Section header entry size
    Elf64_Quarter e_shnum;          // Number of section headers
    Elf64_Quarter e_shstrndx;       // String table index
}

struct Elf64_Shdr
{
    Elf64_Half    sh_name;          // section name
    Elf64_Half    sh_type;          // section type
    Elf64_Xword   sh_flags;         // section flags
    Elf64_Addr    sh_addr;          // virtual address
    Elf64_Off     sh_offset;        // file offset
    Elf64_Xword   sh_size;          // section size
    Elf64_Half    sh_link;          // link to another
    Elf64_Half    sh_info;          // misc info
    Elf64_Xword   sh_addralign;     // memory alignment
    Elf64_Xword   sh_entsize;       // table entry size
}

struct Elf64_Phdr
{
    Elf64_Half    p_type;       // entry type
    Elf64_Half    p_flags;      // flags
    Elf64_Off     p_offset;     // offset
    Elf64_Addr    p_vaddr;      // virtual address
    Elf64_Addr    p_paddr;      // physical address
    Elf64_Xword   p_filesz;     // file size
    Elf64_Xword   p_memsz;      // memory size
    Elf64_Xword   p_align;      // memory and file alignment
}

struct Elf64_Dyn
{
  Elf64_Xword  d_tag;
  union _d_un
  {
      Elf64_Addr d_ptr;
      Elf64_Xword d_val;
  } _d_un d_un;
}

struct Elf64_Rel
{
    Elf64_Xword   r_offset;     // where to do it
    Elf64_Xword   r_info;       // index & type of relocation
}

struct Elf64_Rela
{
    Elf64_Xword   r_offset;     // where to do it
    Elf64_Xword   r_info;       // index & type of relocation
    Elf64_Sxword  r_addend;     // adjustment value
}

extern (D)
{
    // From src/sys/sys/exec_elf.h: 403
    // The 64-bit MIPS ELF ABI uses a slightly different relocation format
    // than the regular ELF ABI: the r_info field is split into several
    // pieces (see gnu/usr.bin/bunutils-2/17/include/elf/mips.h for details)
    version(MIPS64)
    {
        // Method retrieved from src/sys/sys/_endian.h: 51
        // May be a better way to handle this but for now,
        // this should get OpenBSD off the ground
        private auto swap32(X)(X x)
        {
            return cast(uint32_t)((cast(uint32_t)x & 0xff) << 24 |
                    (cast(uint32_t)x & 0xff00) << 8 |
                    (cast(uint32_t)x & 0xff0000) >> 8 |
                    (cast(uint32_t)x & 0xff000000) >> 24);
        }
        auto ELF64_R_TYPE(I)(I i) { cast(uint64_t)swap32((i >> 32)); }
        auto ELF64_R_SYM(I)(I i) { return i & 0xffffffff; }
        auto ELF64_R_INFO(S, T)(S sym, T type) { return (cast(uint64_t)sym << 32) + (cast(uint32_t)type); }
    }
    else
    {
        auto ELF64_R_SYM(I)(I i) { return i >> 32; }
        auto ELF64_R_TYPE(I)(I i) { return i & 0xffffffff; }
        auto ELF64_R_INFO(S, T)(S sym, T type) { return (sym << 32) + (type & 0xffffffff); }
    }
}

// Symbol Table Entry
struct Elf64_Sym
{
    Elf64_Half    st_name;  // Symbol name index in str table
    ubyte st_info;          // type / binding attrs
    ubyte st_other;         // unused
    Elf64_Quarter st_shndx; // section index of symbol
    Elf64_Xword   st_value; // value of symbol
    Elf64_Xword   st_size;  // size of symbol
}

extern (D)
{
    auto ELF64_ST_BIND(T)(T val) { return cast(ubyte)val >> 4; }
    auto ELF64_ST_TYPE(T)(T val) { return val & 0xf; }
    auto ELF64_ST_INFO(B, T)(B bind, T type) { return (bind << 4) + (type & 0xf); }
    auto ELF64_ST_VISIBILITY(O)(O o) { return o & 0x03; }
}

