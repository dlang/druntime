/**
 * This module contains a minimal garbage collector implementation according to
 * published requirements.  This library is mostly intended to serve as an
 * example, but it is usable in applications which do not rely on a garbage
 * collector to clean up memory (ie. when dynamic array resizing is not used,
 * and all memory allocated with 'new' is freed deterministically with
 * 'delete').
 *
 * Please note that block attribute data must be tracked, or at a minimum, the
 * FINALIZE bit must be tracked for any allocated memory block because calling
 * rt_finalize on a non-object block can result in an access violation.  In the
 * allocator below, this tracking is done via a leading uint bitmask.  A real
 * allocator may do better to store this data separately, similar to the basic
 * GC.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2016.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sean Kelly
 */

/*          Copyright Sean Kelly 2005 - 2016.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.impl.handlers.gc;

import gc.config;
import gc.gcinterface;

import rt.util.container.array;

import cstdlib = core.stdc.stdlib : calloc, free, malloc, realloc;
static import core.memory;

extern (C) void onOutOfMemoryError(void* pretend_sideffect = null) @trusted pure nothrow @nogc; /* dmd @@@BUG11461@@@ */


__gshared HandlerGC hgc;

class HandlerGC : GC
{
    __gshared Array!Root roots;
    __gshared Array!Range ranges;

    enum getFuncProtoStr(string m) = "public alias proto" ~ m ~ " = typeof(&func);";


    //static foreach(member; __traits(allMembers, HandlerGC))
    //    static foreach(func; __traits(getOverloads,  HandlerGC, member))
    //{
    //    import std.array : replaceFirst;
    //    mixin(getFuncProtoStr!member.replaceFirst("function", "delegate"));
    //    mixin("public __gshared proto" ~ member ~ " " ~ member ~ "Handler;");
    //}

    //static string handlerImplementation(string func = __FUNCTION__)()
    //{
    //    import std.algorithm, std.array, std.traits, std.format, std.meta;
    //    enum handlerIdentifier = func.splitter(".").array[$-1] ~ "Handler";
    //    alias Pit = ParameterIdentifierTuple!(mixin(func));
    //    string parametersString ;
    //    foreach (i, p; Pit)
    //    {
    //        parametersString ~= (i != Pit.length - 1)
    //            ? p ~ " ,"
    //            : p;
    //    }
    //
    //    string specifier = q{ if (%s){ return %s(%s); } };
    //    return specifier.format(handlerIdentifier, handlerIdentifier, parametersString);
    //}

    static void initialize(ref GC gc)
    {
        import core.stdc.string;

        if (config.gc != "handlers")
            return;

        auto p = cstdlib.malloc(__traits(classInstanceSize, HandlerGC));
        if (!p)
            onOutOfMemoryError();

        auto init = typeid(HandlerGC).initializer();
        assert(init.length == __traits(classInstanceSize, HandlerGC));
        auto instance = cast(HandlerGC) memcpy(p, init.ptr, init.length);
        instance.__ctor();

        gc = instance;
        hgc = instance;
    }

    static void finalize(ref GC gc)
    {
        if (config.gc != "manual")
            return;

        auto instance = cast(HandlerGC) gc;
        instance.Dtor();
        cstdlib.free(cast(void*) instance);
    }

    this()
    {
    }

    void delegate() DtorHandler;
    void Dtor()
    {
        if (DtorHandler)
        {
            DtorHandler();
            return;
        }
    }

    void delegate() enableHandler;
    void enable()
    {
        if (enableHandler)
        {
            enableHandler();
            return;
        }
    }

    void delegate() disableHandler;
    void disable()
    {
        if (disableHandler)
        {
            disableHandler();
            return;
        }
    }

    void delegate() nothrow collectHandler;
    void collect() nothrow
    {
        if (collectHandler)
        {
            collectHandler();
            return;
        }
    }

    void delegate() nothrow collectNoStackHandler;
    void collectNoStack() nothrow
    {
        if (collectNoStackHandler)
        {
            collectNoStackHandler();
            return;
        }
    }

    void delegate() nothrow minimizeHandler;
    void minimize() nothrow
    {
        if (minimizeHandler)
        {
            minimizeHandler();
        }
    }

    uint delegate(void*) nothrow getAttrHandler;
    uint getAttr(void* p) nothrow
    {
        if (getAttrHandler)
        {
            return getAttrHandler(p);
        }
        return 0;
    }

    uint delegate(void*,uint) nothrow setAttrHandler;
    uint setAttr(void* p, uint mask) nothrow
    {
        if (setAttrHandler)
        {
            return setAttrHandler(p, mask);
        }
        return 0;
    }

    uint delegate(void*,uint) nothrow clrAttrHandler;
    uint clrAttr(void* p, uint mask) nothrow
    {
        if (minimizeHandler)
        {
            return clrAttrHandler(p, mask);
        }
        return 0;
    }

    void* delegate(size_t,uint,const TypeInfo) nothrow mallocHandler;
    void* malloc(size_t size, uint bits, const TypeInfo ti) nothrow
    {
        if (mallocHandler)
        {
            return mallocHandler(size, bits, ti);
        }

        void* p = cstdlib.malloc(size);

        if (size && p is null)
            onOutOfMemoryError();
        return p;
    }

    BlkInfo delegate(size_t,uint,const TypeInfo) nothrow qallocHandler;
    BlkInfo qalloc(size_t size, uint bits, const TypeInfo ti) nothrow
    {
        if (qallocHandler)
        {
            return qallocHandler(size, bits, ti);
        }

        BlkInfo retval;
        retval.base = malloc(size, bits, ti);
        retval.size = size;
        retval.attr = bits;
        return retval;
    }

    void* delegate(size_t,uint,const TypeInfo) nothrow callocHandler;
    void* calloc(size_t size, uint bits, const TypeInfo ti) nothrow
    {
        if (callocHandler)
        {
            return callocHandler(size, bits, ti);
        }

        void* p = cstdlib.calloc(1, size);

        if (size && p is null)
            onOutOfMemoryError();
        return p;
    }

    void* delegate(void*,size_t,uint,const TypeInfo) nothrow reallocHandler;
    void* realloc(void* p, size_t size, uint bits, const TypeInfo ti) nothrow
    {
        if (reallocHandler)
        {
            return reallocHandler(p, size, bits, ti);
        }

        p = cstdlib.realloc(p, size);

        if (size && p is null)
            onOutOfMemoryError();
        return p;
    }

    size_t delegate(void*,size_t,size_t,const TypeInfo) nothrow extendHandler;
    size_t extend(void* p, size_t minsize, size_t maxsize, const TypeInfo ti) nothrow
    {
        if (extendHandler)
        {
            return extendHandler(p, minsize, maxsize, ti);
        }

        return 0;
    }

    size_t delegate(size_t) nothrow reserveHandler;
    size_t reserve(size_t size) nothrow
    {
        if (reserveHandler)
        {
            return reserveHandler(size);
        }

        return 0;
    }

    void delegate(void*) nothrow @nogc freeHandler;
    void free(void* p) nothrow @nogc
    {
        if (freeHandler)
        {
            return freeHandler(p);
        }

        cstdlib.free(p);
    }

    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    void* delegate(void*) nothrow @nogc addrOfHandler;
    void* addrOf(void* p) nothrow @nogc
    {
        if (addrOfHandler)
        {
            return addrOfHandler(p);
        }

        return null;
    }

    /**
     * Determine the allocated size of pointer p.  If p is an interior pointer
     * or not a gc allocated pointer, return 0.
     */
    size_t delegate(void*) nothrow @nogc sizeOfHandler;
    size_t sizeOf(void* p) nothrow @nogc
    {
        if (sizeOfHandler)
        {
            return sizeOfHandler(p);
        }

        return 0;
    }

    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    BlkInfo delegate(void*) nothrow queryHandler;
    BlkInfo query(void* p) nothrow
    {
        if (queryHandler)
        {
            return queryHandler(p);
        }

        return BlkInfo.init;
    }

    core.memory.GC.Stats delegate() nothrow statsHandler;
    core.memory.GC.Stats stats() nothrow
    {
        if (statsHandler)
        {
            return statsHandler();
        }

        return typeof(return).init;
    }

    void delegate(void*) nothrow @nogc addRootHandler;
    void addRoot(void* p) nothrow @nogc
    {
        if (addRootHandler)
        {
            return addRootHandler(p);
        }

        roots.insertBack(Root(p));
    }

    void delegate(void* p) nothrow @nogc removeRootHandler;
    void removeRoot(void* p) nothrow @nogc
    {
        if (removeRootHandler)
        {
            return removeRootHandler(p);
        }

        foreach (ref r; roots)
        {
            if (r is p)
            {
                r = roots.back;
                roots.popBack();
                return;
            }
        }
        assert(false);
    }

    RootIterator delegate() return @nogc rootIterHandler;
    @property RootIterator rootIter() return @nogc
    {
        if (rootIterHandler)
        {
            return rootIterHandler();
        }

        return &rootsApply;
    }

    private int rootsApply(scope int delegate(ref Root) nothrow dg)
    {
        foreach (ref r; roots)
        {
            if (auto result = dg(r))
                return result;
        }
        return 0;
    }

    void delegate(void* p, size_t sz, const TypeInfo = null) nothrow @nogc addRangeHandler;
    void addRange(void* p, size_t sz, const TypeInfo ti = null) nothrow @nogc
    {
        if (addRangeHandler)
        {
            return addRangeHandler(p, sz, ti);
        }

        ranges.insertBack(Range(p, p + sz, cast() ti));
    }

    void delegate(void* p) nothrow @nogc removeRangeHandler;
    void removeRange(void* p) nothrow @nogc
    {
        if (removeRangeHandler)
        {
            return removeRangeHandler(p);
        }

        foreach (ref r; ranges)
        {
            if (r.pbot is p)
            {
                r = ranges.back;
                ranges.popBack();
                return;
            }
        }
        assert(false);
    }

    @property RangeIterator rangeIter() return @nogc
    {
        return &rangesApply;
    }

    private int rangesApply(scope int delegate(ref Range) nothrow dg)
    {
        foreach (ref r; ranges)
        {
            if (auto result = dg(r))
                return result;
        }
        return 0;
    }

    void delegate(in void[] segment) nothrow runFinalizersHandler;
    void runFinalizers(in void[] segment) nothrow
    {
        if (runFinalizersHandler)
        {
            return runFinalizersHandler(segment);
        }
    }

    bool delegate() nothrow inFinalizerHandler;
    bool inFinalizer() nothrow
    {
        if (inFinalizerHandler)
        {
            return inFinalizerHandler();
        }

        return false;
    }
}
