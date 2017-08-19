/**
 * Written in the D programming language.
 * This module provides OS X x86 specific support for sections.
 *
 * Copyright: Copyright Digital Mars 2008 - 2016.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors: Walter Bright, Sean Kelly, Martin Nowak, Jacob Carlborg
 * Source: $(DRUNTIMESRC src/rt/_sections_osx_x86.d)
 */
module rt.sections_osx_x86;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version(Darwin):
version(X86):

// debug = PRINTF;
import core.stdc.stdio;
import core.stdc.string, core.stdc.stdlib;
import core.sys.posix.pthread;
import core.sys.darwin.mach.dyld;
import core.sys.darwin.mach.getsect;
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
    immutable(void)[][2] _tlsImage;
}

/****
 * Boolean flag set to true while the runtime is initialized.
 */
__gshared bool _isRuntimeInitialized;

/****
 * Gets called on program startup just before GC is initialized.
 */
void initSections() nothrow @nogc
{
    pthread_key_create(&_tlsKey, null);
    _dyld_register_func_for_add_image(&sections_osx_onAddImage);
    _isRuntimeInitialized = true;
}

/***
 * Gets called on program shutdown just after GC is terminated.
 */
void finiSections() nothrow @nogc
{
    _sections._gcRanges.reset();
    pthread_key_delete(_tlsKey);
    _isRuntimeInitialized = false;
}

void[]* initTLSRanges() nothrow @nogc
{
    return &getTLSBlock();
}

void finiTLSRanges(void[]* rng) nothrow @nogc
{
    .free(rng.ptr);
    .free(rng);
}

void scanTLSRanges(void[]* rng, scope void delegate(void* pbeg, void* pend) nothrow dg) nothrow
{
    dg(rng.ptr, rng.ptr + rng.length);
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
            fprintf(stderr, "Loading shared libraries isn't yet supported on Darwin.\n");
            return;
        }
        else if (_sections.modules.ptr !is null)
        {
            fprintf(stderr, "Shared libraries are not yet supported on Darwin.\n");
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

    auto tlssect = getSection(h, slide, "__DATA", "__tls_data");
    if (tlssect != null)
    {
        debug(PRINTF) printf("  tls_data %p %p\n", tlssect.ptr, tlssect.ptr + tlssect.length);
        _sections._tlsImage[0] = (cast(immutable(void)*)tlssect.ptr)[0 .. tlssect.length];
    }

    auto tlssect2 = getSection(h, slide, "__DATA", "__tlscoal_nt");
    if (tlssect2 != null)
    {
        debug(PRINTF) printf("  tlscoal_nt %p %p\n", tlssect2.ptr, tlssect2.ptr + tlssect2.length);
        _sections._tlsImage[1] = (cast(immutable(void)*)tlssect2.ptr)[0 .. tlssect2.length];
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
    assert(header.magic == MH_MAGIC);
    auto sect = getsectbynamefromheader(header, segmentName, sectionName);

    if (sect !is null && sect.size > 0)
        return (cast(ubyte*)sect.addr + slide)[0 .. cast(size_t)sect.size];
    return null;
}
