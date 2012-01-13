/**
 * Runtime support for dynamic libraries.
 *
 * Copyright: Copyright Martin Nowak 2012-2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Martin Nowak
 * Source: $(DRUNTIMESRC src/rt/_dso.d)
 */
module rt.dso;

version (Windows)
{
    // missing integration with the existing DLL mechanism
    enum USE_DSO = false;
}
else version (linux)
{
    enum USE_DSO = true;
    import core.sys.linux.elf;
    import core.sys.linux.link;
}
else version (OSX)
{
    // missing integration with rt.memory_osx.onAddImage
    enum USE_DSO = false;
}
else version (FreeBSD)
{
    // missing elf and link headers
    enum USE_DSO = false;
}
else
{
    static assert(0, "Unsupported platform");
}

static if (USE_DSO)
{

import rt.minfo;
import rt.deh2;
import rt.util.container;
import core.stdc.stdlib;
import core.stdc.string;

struct DSO
{
    static int opApply(scope int delegate(ref DSO) dg)
    {
        foreach(dso; _static_dsos[])
        {
            if (auto res = dg(*dso))
                return res;
        }
        return 0;
    }

    @property inout(ModuleInfo*)[] modules() inout
    {
        return _moduleGroup.modules;
    }

    @property ref inout(ModuleGroup) moduleGroup() inout
    {
        return _moduleGroup;
    }

    @property inout(FuncTable)[] ehtables() inout
    {
        return _ehtables[];
    }

    @property const(char)[] name()
    {
        return _name[0 .. strlen(_name)];
    }

    @property int delegate(scope int delegate(ref void[])) gcRanges()
    {
        return &gcRangeDg;
    }

    private int gcRangeDg(scope int delegate(ref void[]) dg)
    {
        if (_flags & Flags.SingleGCRange)
            return dg(_gcRange[]);

        foreach(rng; _gcRanges)
        {
            if (auto res = dg(rng[]))
                return res;
        }
        return 0;
    }

    @property void[] tlsRange()
    {
        return getTLSRange(_tlsMod, _tlsSize);
    }

private:

    invariant()
    {
        assert(_moduleGroup.modules.length);
        assert(_tlsMod || !_tlsSize);
    }

    enum Flags
    {
        None          = 0x0,
        SingleGCRange = 0x1,
    }

    const(char)*        _name;
    FuncTable[]     _ehtables;
    union
    {
           void[][] _gcRanges; // this one is allocated
           void[]    _gcRange; // this is not <= Flags.SingleGCRange
    }
    size_t            _tlsMod;
    size_t           _tlsSize;
    ModuleGroup  _moduleGroup;
    Flags              _flags;
}

struct TLS
{
    void updateRanges()
    {
        if (_ranges.length)
            return;

        _ranges.length = _static_dsos.length;
        size_t idx;
        foreach(dso; _static_dsos[])
        {
            if (auto r = dso.tlsRange)
                _ranges[idx++] = r;
        }
        _ranges.length = idx;
    }

    void free()
    {
        _ranges.clear();
    }

    int opApply(scope int delegate(ref void[]) dg)
    {
        foreach(r; _ranges[])
        {
            if (auto res = dg(r))
                return res;
        }
        return 0;
    }

private:
    Array!(void[]) _ranges;
}

/*
 * Static DSOs loaded by the runtime linker. These can't be unloaded.
 */
private __gshared Array!(DSO*) _static_dsos;

///////////////////////////////////////////////////////////////////////////////
// Compiler to runtime interface.
///////////////////////////////////////////////////////////////////////////////


/*
 *
 */
struct CompilerDSOData
{
    // can be used to attach runtime data
    static struct Rec
    {
        DSO* _ptr;
    }

    static struct Range(T)
    {
        T[] opSlice()
        {
            return start[0 .. end - start];
        }

        T* start, end;
    }

    size_t _version;
    Rec*       _rec;
    Range!(object.ModuleInfo*)  _modules;
    Range!(rt.deh2.FuncTable)  _ehtables;
}

extern(C) void _d_dso_registry(CompilerDSOData* data)
{
    // only one supported currently
    assert(data._version == 1);

    // no payload => register
    if (data._rec._ptr is null)
    {
        // 1) allocate
        DSO* pdso         = cast(DSO*).malloc(DSO.sizeof);
        // 2) store backlink in library record
        data._rec._ptr    = pdso;
        // 3) initialize
        *pdso             = DSO.init;
        // 4) copy out data ranges
        pdso._moduleGroup = ModuleGroup(data._modules[]);
        pdso._ehtables    = data._ehtables[];
        // 5) fetch further data from Phdr
        dl_iterate_phdr(&digestPhdr, pdso);
        // 6) append to array
        _static_dsos.insertBack(pdso);
    }
    // has payload => unregister
    else
    {
        // get backlink from library record
        DSO*  pdso = data._rec._ptr;
        // 6) remove from array
        assert(pdso == _static_dsos.back);
        _static_dsos.popBack();
        // 5) free resources
        .free(cast(char*)pdso._name);
        if (!(pdso._flags & DSO.Flags.SingleGCRange))
            .free(cast(void*)pdso._gcRanges.ptr);
        // 4) clean data ranges
        pdso._ehtables = null;
        // 3) uninitialize
        .clear(*pdso);
        // 2) clear backlink in library
        data._rec._ptr = null;
        // 1) deallocate
        .free(pdso);
    }
}


///////////////////////////////////////////////////////////////////////////////
// Elf program header iteration
///////////////////////////////////////////////////////////////////////////////

/*
 * Search through the program header tables of all loaded images for
 * an image containing the given address.
 */
extern(C) int digestPhdr(dl_phdr_info *info, size_t size, void* data)
{
    auto pdso = cast(DSO*)data;
    // Use the module infos as image internal address to identify the
    // object.
    auto addr = cast(void*)pdso.modules.ptr;

    // quick reject
    if (addr < cast(void*)info.dlpi_addr)
        return 0;

    size_t i;
    for (i = 0; i < info.dlpi_phnum; ++i)
    {
        auto seg_beg = cast(void*)(info.dlpi_addr + info.dlpi_phdr[i].p_vaddr);
        auto seg_end = seg_beg + info.dlpi_phdr[i].p_memsz;
        if (addr >= seg_beg && addr <= seg_end)
            break;
    }
    // wrong dl
    if (i == info.dlpi_phnum)
        return 0;

    // name
    pdso._name = cast(char*).strdup(info.dlpi_name);

    // get loaded, writeable segments

    static void[] addrRange(dl_phdr_info *info, size_t idx)
    {
        assert(idx < info.dlpi_phnum);
        void* seg_beg = cast(void*)(info.dlpi_addr + info.dlpi_phdr[idx].p_vaddr);
        immutable sz  = info.dlpi_phdr[idx].p_memsz;
        return seg_beg[0 .. sz];
    }

    size_t nranges;
    for (i = 0; i < info.dlpi_phnum; ++i)
    {
        immutable p_type  = info.dlpi_phdr[i].p_type;
        immutable p_flags = info.dlpi_phdr[i].p_flags;

        if (p_type == PT_LOAD && (p_flags & PF_W))
        {
            if (nranges++) continue;
            pdso._gcRange = addrRange(info, i);
        }
        else if (p_type == PT_TLS)
        {
            pdso._tlsMod   = info.dlpi_tls_modid;
            pdso._tlsSize  = info.dlpi_phdr[i].p_memsz;
        }
    }

    if (nranges <= 1)
    {
        // only one range => already copied it
        pdso._flags |= DSO.Flags.SingleGCRange;
    }
    else
    {
        // multiple ranges => need to allocate storage
        immutable nbytes = nranges * (void[]).sizeof;
        auto ranges = cast(void[]*)malloc(nbytes);

        for (nranges = 0, i = 0; i < info.dlpi_phnum; ++i)
        {
            immutable p_type  = info.dlpi_phdr[i].p_type;
            immutable p_flags = info.dlpi_phdr[i].p_flags;

            if (p_type == PT_LOAD && p_flags & PF_W)
            {
                ranges[nranges++] = addrRange(info, i);
            }
        }
        pdso._gcRanges = ranges[0 .. nranges];
    }

    // terminate iteration
    return 1;
}


///////////////////////////////////////////////////////////////////////////////
// TLS module helper
///////////////////////////////////////////////////////////////////////////////

/*
 * Returns the TLS memory range for a given module and the calling
 * thread. Be aware that this will cause the TLS memory to be eagerly
 * allocated. Returns null if that module has no TLS.
 */
struct tls_index
{
    size_t ti_module;
    size_t ti_offset;
}

extern(C) void* __tls_get_addr(tls_index* ti);

private void[] getTLSRange(size_t mod, size_t sz)
{

    if (mod == 0)
        return null;

    // base offset
    auto ti = tls_index(mod, 0);
    return __tls_get_addr(&ti)[0 .. sz];
}

} // USE_DSO
