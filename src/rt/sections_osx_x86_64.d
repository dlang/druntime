/**
 * Written in the D programming language.
 * This module provides OS X x86-64 specific support for sections.
 *
 * Copyright: Copyright Digital Mars 2016.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors: Walter Bright, Sean Kelly, Martin Nowak, Jacob Carlborg
 * Source: $(DRUNTIMESRC src/rt/_sections_osx_x86_64.d)
 */
module rt.sections_osx_x86_64;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version(Darwin):
version(X86_64):

// debug = PRINTF;
import core.stdc.clang_block;
import core.stdc.stdio;
import core.stdc.string, core.stdc.stdlib;
import core.sys.posix.pthread;
import core.sys.osx.mach.dyld;
import core.sys.osx.mach.getsect;
import rt.deh, rt.minfo;
import rt.util.container.array;

struct SectionGroup
{
    static int opApply(scope int delegate(ref SectionGroup) dg)
    {
        return dg(_sections);
    }

    static int opApplyReverse(scope int delegate(ref SectionGroup) dg)
    {
        return dg(_sections);
    }

    @property immutable(ModuleInfo*)[] modules() const
    {
        return _moduleGroup.modules;
    }

    @property ref inout(ModuleGroup) moduleGroup() inout
    {
        return _moduleGroup;
    }

    @property inout(void[])[] gcRanges() inout
    {
        return _gcRanges[];
    }

    @property immutable(FuncTable)[] ehTables() const
    {
        return _ehTables[];
    }

private:
    immutable(FuncTable)[] _ehTables;
    ModuleGroup _moduleGroup;
    Array!(void[]) _gcRanges;
}

/****
 * Boolean flag set to true while the runtime is initialized.
 */
__gshared bool _isRuntimeInitialized;

/****
 * Gets called on program startup just before GC is initialized.
 */
void initSections()
{
    _dyld_register_func_for_add_image(&sections_osx_onAddImage);
    _isRuntimeInitialized = true;
}

/***
 * Gets called on program shutdown just after GC is terminated.
 */
void finiSections()
{
    _sections._gcRanges.reset();
    _isRuntimeInitialized = false;
}

void[] initTLSRanges()
{
    auto range = getTLSRange();
    assert(range.isValid, "Could not determine TLS range.");
    return range.toArray();
}

void finiTLSRanges(void[] rng)
{

}

void scanTLSRanges(void[] rng, scope void delegate(void* pbeg, void* pend) nothrow dg) nothrow
{
    dg(rng.ptr, rng.ptr + rng.length);
}

private:

// Declarations from dyld_priv.h in dyld, available on 10.7+.
enum dyld_tlv_states
{
    allocated = 10,
    deallocated = 20
}

struct dyld_tlv_info
{
    size_t info_size;
    void * tlv_addr;
    size_t tlv_size;
}

alias dyld_tlv_state_change_handler = Block!(void, dyld_tlv_states, dyld_tlv_info*)*;
extern(C) void dyld_enumerate_tlv_storage(dyld_tlv_state_change_handler handler);

ubyte dummyTlsSymbol;

struct TLSRange
{
    void* start;
    size_t size;

    bool isValid()
    {
        return start !is null && size > 0;
    }

    void[] toArray()
    {
        return start[0 .. size];
    }
}

TLSRange getTLSRange()
{
    void* tlsSymbol = &dummyTlsSymbol;
    TLSRange range;

    scope dg = (dyld_tlv_states state, dyld_tlv_info* info) {
        assert(state == dyld_tlv_states.allocated);

        if (info.tlv_addr <= tlsSymbol && tlsSymbol <
            (info.tlv_addr + info.tlv_size)
        )
        {
            range = TLSRange(info.tlv_addr, info.tlv_size);
        }
    };

    auto handler = block(dg);
    dyld_enumerate_tlv_storage(&handler);

    return range;
}

__gshared SectionGroup _sections;

extern (C) void sections_osx_onAddImage(in mach_header* h, intptr_t slide)
{
    foreach (e; dataSegs)
    {
        auto sect = getSection(h, slide, e.seg.ptr, e.sect.ptr);
        if (sect != null)
            _sections._gcRanges.insertBack((cast(void*)sect.ptr)[0 .. sect.length]);
    }

    auto minfosect = getSection(h, slide, "__DATA", "__minfodata");
    if (minfosect != null)
    {
        // no support for multiple images yet
        // take the sections from the last static image which is the executable
        if (_isRuntimeInitialized)
        {
            fprintf(stderr, "Loading shared libraries isn't yet supported on OSX.\n");
            return;
        }
        else if (_sections.modules.ptr !is null)
        {
            fprintf(stderr, "Shared libraries are not yet supported on OSX.\n");
        }

        debug(PRINTF) printf("  minfodata\n");
        auto p = cast(immutable(ModuleInfo*)*)minfosect.ptr;
        immutable len = minfosect.length / (*p).sizeof;

        _sections._moduleGroup = ModuleGroup(p[0 .. len]);
    }

    auto ehsect = getSection(h, slide, "__DATA", "__deh_eh");
    if (ehsect != null)
    {
        debug(PRINTF) printf("  deh_eh\n");
        auto p = cast(immutable(FuncTable)*)ehsect.ptr;
        immutable len = ehsect.length / (*p).sizeof;

        _sections._ehTables = p[0 .. len];
    }
}

struct SegRef
{
    string seg;
    string sect;
}

static immutable SegRef[] dataSegs = [{SEG_DATA, SECT_DATA},
                                      {SEG_DATA, SECT_BSS},
                                      {SEG_DATA, SECT_COMMON}];

ubyte[] getSection(in mach_header* header, intptr_t slide,
                   in char* segmentName, in char* sectionName)
{
    assert(header.magic == MH_MAGIC_64);
    auto sect = getsectbynamefromheader_64(cast(mach_header_64*)header,
                                        segmentName,
                                        sectionName);

    if (sect !is null && sect.size > 0)
        return (cast(ubyte*)sect.addr + slide)[0 .. cast(size_t)sect.size];
    return null;
}
