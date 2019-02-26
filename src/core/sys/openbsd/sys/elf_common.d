/**
 * D header file for OpenBSD
 *
 * https://cvsweb.openbsd.org/src/sys/sys/exec_elf.h
 */
module core.sys.openbsd.sys.elf_common;

version (OpenBSD):
extern (C):
pure:
nothrow:

import core.stdc.stdint;

struct Elf32_Note
{
    uint32_t    namesz;
    uint32_t    descsz;
    uint32_t    type;
}

struct Elf32_Nhdr
{
    uint32_t    n_namesz;
    uint32_t    n_descsz;
    uint32_t    n_type;
}

// OpenBSD has Elf64 definitions of the structs above but
// the field sizes are identical. So just aliasing them here
// Row 563 and 578 in the exec_elf.h file
alias Elf64_Note = Elf32_Note;
alias Elf64_Nhdr = Elf32_Nhdr;

// Also alias without 32/64 identifiers
alias Elf_Note = Elf32_Note;
alias Elf_Nhdr = Elf32_Nhdr;

/*
 * e_ident[] identification indexes
 * See http://www.sco.com/developers/gabi/latest/ch4.eheader.html
 */
enum EI_MAG0 =         0;       // file ID
enum EI_MAG1 =         1;       // file ID
enum EI_MAG2 =         2;       // file ID
enum EI_MAG3 =         3;       // file ID
enum EI_CLASS =        4;       // file class
enum EI_DATA =         5;       // data encoding
enum EI_VERSION =      6;       // ELF header version
enum EI_OSABI =        7;       // OS/ABI ID
enum EI_ABIVERSION =   8;       // ABI version
enum EI_PAD =          9;       // start of pad bytes
enum EI_NIDENT =       16;      // Size od e_ident[]

// e_ident[] magic number
enum ELFMAG0 =         0x7f;        // e_ident[EI_MAG0]
enum ELFMAG1 =         'E';         // e_ident[EI_MAG1]
enum ELFMAG2 =         'L';         // e_ident[EI_MAG2]
enum ELFMAG3 =         'F';         // e_ident[EI_MAG3]
enum ELFMAG =          "\177ELF";   // magic
enum SELFMAG =         4;           // size of magic

enum EV_NONE =         0;  // Invalid
enum EV_CURRENT =      1;  // Current
enum EV_NUM =          2;  // number of versions

enum ELFCLASSNONE =    0;  // invalid
enum ELFCLASS32 =      1;  // 32-bit objs
enum ELFCLASS64 =      2;  // 64-bit objs
enum ELFCLASSNUM =     3;  // number of classes

enum ELFDATANONE =     0;  // invalid
enum ELFDATA2LSB =     1;  // Little-Endian
enum ELFDATA2MSB =     2;  // Big-Endian
enum ELFDATANUM =      3;  // number of data encode defines

enum ELFOSABI_NONE =       0;
enum ELFOSABI_SYSV =       0;   // UNIX System V ABI
enum ELFOSABI_HPUX =       1;   // HP-UX operating system
enum ELFOSABI_NETBSD =     2;   // NetBSD
enum ELFOSABI_LINUX =      3;   // GNU/Linux
enum ELFOSABI_HURD =       4;   // GNU/Hurd
enum ELFOSABI_86OPEN =     5;   // 86Open common IA32 ABI
enum ELFOSABI_SOLARIS =    6;   // Solaris
enum ELFOSABI_MONTEREY =   7;   // Monterey
enum ELFOSABI_IRIX =       8;   // IRIX
enum ELFOSABI_FREEBSD =    9;   // FreeBSD
enum ELFOSABI_TRU64 =      10;  // TRU64 UNIX
enum ELFOSABI_MODESTO =    11;  // Novell Modesto
enum ELFOSABI_OPENBSD =    12;  // OpenBSD
enum ELFOSABI_ARM =        97;  // ARM
enum ELFOSABI_STANDALONE = 255; // Standalone (embedded) application

// Copied from netbsd/sys/elf_common.d since OpenBSD has same definition
// in their sys/sys/exec_elf.h file.
extern (D)
{
    auto IS_ELF(T)(T ehdr) { return ehdr.e_ident[EI_MAG0] == ELFMAG0 &&
                                    ehdr.e_ident[EI_MAG1] == ELFMAG1 &&
                                    ehdr.e_ident[EI_MAG2] == ELFMAG2 &&
                                    ehdr.e_ident[EI_MAG3] == ELFMAG3; }
}

// e_type
enum ET_NONE =   0;        // No file type
enum ET_REL =    1;        // relocatable file
enum ET_EXEC =   2;        // executable file
enum ET_DYN =    3;        // shared object file
enum ET_CORE =   4;        // core file
enum ET_NUM =    5;        // number of types
enum ET_LOPROC = 0xff00;   // reserved range for processor
enum ET_HIPROC = 0xffff;   // specific e_type

// e_machine
enum EM_NONE =          0;        // No Machine
enum EM_M32 =           1;        // AT&T WE 32100
enum EM_SPARC =         2;        // SPARC
enum EM_386 =           3;        // Intel 80386
enum EM_68K =           4;        // Motorola 68000
enum EM_88K =           5;        // Motorola 88000
enum EM_486 =           6;        // Intel 80486 - unused?
enum EM_860 =           7;        // Intel 80860
enum EM_MIPS =          8;        // MIPS R3000 Big-Endian only
enum EM_MIPS_RS4_BE =   10;       // MIPS R4000 Big-Endian
enum EM_SPARC64 =       11;       // SPARC v9 64-bit unofficial
enum EM_PARISC =        15;       // HPPA
enum EM_SPARC32PLUS =   18;       // Enhanced instruction set SPARC
enum EM_PPC =           20;       // PowerPC
enum EM_PPC64 =         21;       // PowerPC 64
enum EM_ARM =           40;       // Advanced RISC Machines ARM
enum EM_ALPHA =         41;       // DEC ALPHA
enum EM_SH =            42;       // Hitachi/Renesas Super-H
enum EM_SPARCV9 =       43;       // SPARC version 9
enum EM_IA_64 =         50;       // Intel IA-64 Processor
enum EM_AMD64 =         62;       // AMD64 architecture
enum EM_X86_64 =        EM_AMD64;
enum EM_VAX =           75;       // DEC VAX
enum EM_AARCH64 =       183;      // ARM 64-bit architecture (AArch64)
enum EM_ALPHA_EXP =     0x9026;   // DEC ALPHA
enum EM_NUM =           22;       // number of machine types

enum EM__LAST__ =       (EM_ALPHA_EXP + 1); // Added to OpenBSD: 2019/1/22

enum SHT_NULL =          0;             // inactive
enum SHT_PROGBITS =      1;             // program defined information
enum SHT_SYMTAB =        2;             // symbol table section
enum SHT_STRTAB =        3;             // string table section
enum SHT_RELA =          4;             // relocation section with addends
enum SHT_HASH =          5;             // symbol hash table section
enum SHT_DYNAMIC =       6;             // dynamic section
enum SHT_NOTE =          7;             // note section
enum SHT_NOBITS =        8;             // no space section
enum SHT_REL =           9;             // relation section without addends
enum SHT_SHLIB =         10;            // reserved - purpose unknown
enum SHT_DYNSYM =        11;            // dynamic symbol table section
enum SHT_NUM =           12;            // number of section types
enum SHT_INIT_ARRAY =    14;            // pointers to init functions           - Added to OpenBSD: 2019/1/22
enum SHT_FINI_ARRAY =    15;            // pointers termination functions       - Added to OpenBSD: 2019/1/22
enum SHT_PREINIT_ARRAY = 16;            // ptrs to funcs called before init     - Added to OpenBSD: 2019/1/22
enum SHT_GROUP =         17;            // defines a section group              - Added to OpenBSD: 2019/1/22
enum SHT_SYMTAB_SHNDX =  18;            // Section indexes (see SHN_XINDEX)
enum SHT_LOOS =          0x60000000;    // reserved range for OS specific
enum SHT_SUNW_dof =      0x6ffffff4;    // used by dtrace                       - Added to OpenBSD: 2019/1/22
enum SHT_GNU_LIBLIST =   0x6ffffff7;    // libraries to be prelinked            - Added to OpenBSD: 2019/1/22
enum SHT_SUNW_move =     0x6ffffffa;    // inf for partially init'ed symbols    - Added to OpenBSD: 2019/1/22
enum SHT_SUNW_syminfo =  0x6ffffffc;    // ad symbol information                - Added to OpenBSD: 2019/1/22
enum SHT_SUNW_verdef =   0x6ffffffd;    // symbol versioning inf                - Added to OpenBSD: 2019/1/22
enum SHT_SUNW_verneed =  0x6ffffffe;    // symbol versioning req                - Added to OpenBSD: 2019/1/22
enum SHT_SUNW_versym =   0x6fffffff;    // symbol version table                 - Added to OpenBSD: 2019/1/22
enum SHT_HIOS =          0x6fffffff;    // section header types
enum SHT_LOPROC =        0x70000000;    // reserved range for processor
enum SHT_HIPROC =        0x7fffffff;    // specific section header types
enum SHT_LOUSER =        0x80000000;    // reserved range for application
enum SHT_HIUSER =        0xffffffff;    // specific indexes

enum SHF_WRITE =            0x1;           // Writeable
enum SHF_ALLOC =            0x2;           // occupies memory
enum SHF_EXECINSTR =        0x4;           // executable
enum SHF_MERGE =            0x10;          // may be merged
enum SHF_STRINGS =          0x20;          // contains strings
enum SHF_INFO_LINK =        0x40;          // sh_info holds section index
enum SHF_LINK_ORDER =       0x80;          // ordering requirements
enum SHF_OS_NONCONFORMING = 0x100;         // OS-specific processing required
enum SHF_GROUP =            0x200;         // member of sectoin group
enum SHF_TLS =              0x400;         // thread local storage
enum SHF_COMPRESSED =       0x800;         // contains compressed data
enum SHF_MASKOS =           0x0ff00000;    // OS-specific semantices
enum SHF_MASKPROC =         0xf0000000;    // reserved bits for processor

enum PT_NULL =         0;           // unused
enum PT_LOAD =         1;           // loadable segment
enum PT_DYNAMIC =      2;           // dynamic linking section
enum PT_INTERP =       3;           // the RTLD
enum PT_NOTE =         4;           // auxiliary information
enum PT_SHLIB =        5;           // reserved - pirpose undefined
enum PT_PHDR =         6;           // program header
enum PT_TLS =          7;           // thread local storage
enum PT_LOOS =         0x60000000;  // reserved range for OS
enum PT_HIOS =         0x6fffffff;  // specific segment types
enum PT_LOPROC =       0x70000000;  // reserved range for processor
enum PT_HIPROC =       0x7fffffff;  // specific segment types

enum PT_GNU_EH_FRAME = 0x6474e550;  // Exception handling info
enum PT_GNU_RELRO =    0x6474e552;  // Read-only after relocation

enum PT_OPENBSD_RANDOMIZE = 0x65a3dbe6; // fill with random data
enum PT_OPENBSD_WXNEEDED =  0x65a3dbe7; // program performs W^X violations
enum PT_OPENBSD_BOOTDATA =  0x65a41be6; // section for boot arguments

enum PF_X =         0x1;        // Executable
enum PF_W =         0x2;        // Writable
enum PF_R =         0x4;        // Readable
enum PF_MASKPROC =  0xf0000000; // reserved bits for processor


enum DT_NULL =         0;           // marks end of _DYNAMIC array
enum DT_NEEDED =       1;           // string table offset of needed lib
enum DT_PLTRELSZ =     2;           // size of relocation entries in PLT
enum DT_PLTGOT =       3;           // address PLT/GOT
enum DT_HASH =         4;           // address of symbol hash table
enum DT_STRTAB =       5;           // address of string table
enum DT_SYMTAB =       6;           // address of symbol table
enum DT_RELA =         7;           // address of relocation table
enum DT_RELASZ =       8;           // size of relocation table
enum DT_RELAENT =      9;           // size of relocation entry
enum DT_STRSZ =        10;          // size of string table
enum DT_SYMENT =       11;          // size of symbol table entry
enum DT_INIT =         12;          // address of initialization func.
enum DT_FINI =         13;          // address of termination function
enum DT_SONAME =       14;          // string table offset of shared obj
enum DT_RPATH =        15;          // string table offset of library search path
enum DT_SYMBOLIC =     16;          // start sym serach in shared obj.
enum DT_REL =          17;          // address of rel. tbl. w addends
enum DT_RELSZ =        18;          // size of DT_REL relocation table
enum DT_RELENT =       19;          // size of DT_REL relocation entry
enum DT_PLTREL =       20;          // PLT referenced relocatoin entry
enum DT_DEBUG =        21;          // bugger
enum DT_TEXTREL =      22;          // Allow rel. mod. to unwritable seg
enum DT_JMPREL =       23;          // add. of PLT's relocatoin entries
enum DT_BIND_NOW =     24;          // Bind now regardless of env setting
enum DT_INIT_ARRAY =   25;          // address of array of init func
enum DT_FINI_ARRAY =   26;          // address of array of term func
enum DT_INIT_ARRAYSZ = 27;          // size of array of init func
enum DT_FINI_ARRAYSZ = 28;          // size of array of term func
enum DT_RUNPATH =      29;          // strtab offset of lib search path
enum DT_FLAGS =        30;          // Set of DF_* flags
enum DT_ENCODING =     32;          // further DT_* follow encoding rules
enum DT_PREINIT_ARRAY = 32;         // address of array of preinit func
enum DT_PREINIT_ARRAYSZ = 33;       // size of array of preinit func
enum DT_LOOS =         0x6000000d;  // reserved range for OS
enum DT_HIOS =         0x6ffff000;  // specific dynamic array tags
enum DT_LOPROC =       0x70000000;  // reserved range for processor
enum DT_HIPROC =       0x7fffffff;  // specific dynamic array tags
enum DT_RELACOUNT =    0x6ffffff9;  // if present, number of RELATIVE
enum DT_RELCOUNT =     0x6ffffffa;  // relocs, which must come first
enum DT_FLAGS_1 =      0x6ffffffb;

// Dynamic Flags - DT_FLAGS .dynamic entry
enum DF_ORIGIN =       0x00000001;
enum DF_SYMBOLIC =     0x00000002;
enum DF_TEXTREL =      0x00000004;
enum DF_BIND_NOW =     0x00000008;
enum DF_STATIC_TLS =   0x00000010;

// Dynamic Flags - DT_FLAGS_1 .dynamic entry
enum DF_1_NOW =        0x00000001;
enum DF_1_GLOBAL =     0x00000002;
enum DF_1_GROUP =      0x00000004;
enum DF_1_NODELETE =   0x00000008;
enum DF_1_LOADFLTR =   0x00000010;
enum DF_1_INITFIRST =  0x00000020;
enum DF_1_NOOPEN =     0x00000040;
enum DF_1_ORIGIN =     0x00000080;
enum DF_1_DIRECT =     0x00000100;
enum DF_1_TRANS =      0x00000200;
enum DF_1_INTERPOSE =  0x00000400;
enum DF_1_NODEFLIB =   0x00000800;
enum DF_1_NODUMP =     0x00001000;
enum DF_1_CONLFAT =    0x00002000;

// Values for n_type
enum NT_PRSTATUS =     1;       // Process status
enum NT_FPREGSET =     2;       // Floating point registers
enum NT_PRPSINFO =     3;       // Process state info

/*
 * OpenBSD-specific core file information.
 *
 * OpenBSD ELF core files use notes to provide information about
 * the process's state.  The note name is "OpenBSD" for information
 * that is global to the process, and "OpenBSD@nn", where "nn" is the
 * thread ID of the thread that the information belongs to (such as
 * register state).
 *
 * We use the following note identifiers:
 *
 *	NT_OPENBSD_PROCINFO
 *		Note is a "elfcore_procinfo" structure.
 *	NT_OPENBSD_AUXV
 *		Note is a a bunch of Auxilliary Vectors, terminated by
 *		an AT_NULL entry.
 *	NT_OPENBSD_REGS
 *		Note is a "reg" structure.
 *	NT_OPENBSD_FPREGS
 *		Note is a "fpreg" structure.
 *
 * Please try to keep the members of the "elfcore_procinfo" structure
 * nicely aligned, and if you add elements, add them to the end and
 * bump the version.
 */
enum NT_OPENBSD_PROCINFO = 10;
enum NT_OPENBSD_AUXV     = 11;

enum NT_OPENBSD_REGS     = 20;
enum NT_OPENBSD_FPREGS   = 21;
enum NT_OPENBSD_XFPREGS  = 22;
enum NT_OPENBSD_WCOOKIE  = 23;

// Symbol Binding - ELF32_ST_BIND - st_info
enum STB_LOCAL =       0;   // Local symbol
enum STB_GLOBAL =      1;   // Global symbol
enum STB_WEAK =        2;   // like global - lower precedence
enum STB_NUM =         3;   // number of symbol bindings
enum STB_LOPROC =      13;  // reserved range for processor
enum STB_HIPROC =      15;  // specific symbol bindings

// Symbol type - ELF32_ST_TYPE - st_info
enum STT_NOTYPE =      0;   // not specified
enum STT_OBJECT =      1;   // data object
enum STT_FUNC =        2;   // function
enum STT_SECTION =     3;   // section
enum STT_FILE =        4;   // file
enum STT_TLS =         6;   // thread local storage
enum STT_LOPROC =      13;  // reserved range for processor
enum STT_HIPROC =      15;  // specific symbol types

enum STV_DEFAULT =     0;   // Visibility set by binding type
enum STV_INTERNAL =    1;   // OS specific version of STV_HIDDEN
enum STV_HIDDEN =      2;   // can only be seen inside own .so
enum STV_PROTECTED =   3;   // HIDDEN inside, DEFAULT outside

enum STN_UNDEF =       0;   // undefined

