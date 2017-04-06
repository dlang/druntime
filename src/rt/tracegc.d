/**
 * Contains implementations of functions called when the
 *   -profile=gc
 * switch is thrown.
 *
 * Copyright: Copyright Digital Mars 2015 - 2015.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright
 * Source: $(DRUNTIMESRC src/rt/_tracegc.d)
 */

module rt.tracegc;

// version = tracegc;

import rt.profilegc;

version (tracegc) import core.stdc.stdio;

version (none)
{
    // this exercises each function

    struct S { ~this() { } }
    class C { }
    interface I { }

    void main()
    {
      {
        auto a = new C();
        auto b = new int;
        auto c = new int[3];
        auto d = new int[][](3,4);
        auto e = new float;
        auto f = new float[3];
        auto g = new float[][](3,4);
      }
        printf("\n");
      {
        int[] a; delete a;
        S[] as; delete as;
        C c; delete c;
        I i; delete i;
        C* pc = &c; delete *pc;
        I* pi = &i; delete *pi;
        int* pint; delete pint;
        S* ps; delete ps;
      }
        printf("\n");
      {
        int[] a = [1, 2, 3];
        string[int] aa = [1:"one", 2:"two", 3:"three"];
      }
        printf("\n");
      {
        int[] a, b, c;
        c = a ~ b;
        c = a ~ b ~ c;
      }
        printf("\n");
      {
        dchar dc = 'a';
        char[] ac; ac ~= dc;
        wchar[] aw; aw ~= dc;
        char[] ac2; ac2 ~= ac;
        int[] ai; ai ~= 3;
      }
        printf("\n");
      {
        int[] ai; ai.length = 10;
        float[] af; af.length = 10;
      }
        printf("\n");
        int v;
      {
        int foo() { return v; }
        static int delegate() dg;
        dg = &foo;      // dynamic closure
      }
    }
}

extern (C) Object _d_newclass(const ClassInfo ci);
extern (C) void[] _d_newarrayT(const TypeInfo ti, size_t length);
extern (C) void[] _d_newarrayiT(const TypeInfo ti, size_t length);
extern (C) void[] _d_newarraymTX(const TypeInfo ti, size_t[] dims);
extern (C) void[] _d_newarraymiTX(const TypeInfo ti, size_t[] dims);
extern (C) void* _d_newitemT(in TypeInfo _ti);
extern (C) void* _d_newitemiT(in TypeInfo _ti);

private string generatePrintf ( )
{
    version (tracegc)
    {
        return q{
            printf("%s file = '%.*s' line = %d function = '%.*s'\n",
                __FUNCTION__.ptr,
                file.length, file.ptr,
                line,
                funcname.length, funcname.ptr
                );
        };
    }
    else
        return "";
}

extern (C) Object _d_newclassTrace(string file, int line, string funcname, const ClassInfo ci)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ci.name, ci.initializer.length);
    return _d_newclass(ci);
}

extern (C) void[] _d_newarrayTTrace(string file, int line, string funcname, const TypeInfo ti, size_t length)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.tsize * length);
    return _d_newarrayT(ti, length);
}

extern (C) void[] _d_newarrayiTTrace(string file, int line, string funcname, const TypeInfo ti, size_t length)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.tsize * length);
    return _d_newarrayiT(ti, length);
}

extern (C) void[] _d_newarraymTXTrace(string file, int line, string funcname, const TypeInfo ti, size_t[] dims)
{
    mixin(generatePrintf());
    size_t n = 1;
    foreach (dim; dims)
        n *= dim;
    accumulate(file, line, funcname, ti.toString(), ti.tsize * n);
    return _d_newarraymTX(ti, dims);
}

extern (C) void[] _d_newarraymiTXTrace(string file, int line, string funcname, const TypeInfo ti, size_t[] dims)
{
    mixin(generatePrintf());
    size_t n = 1;
    foreach (dim; dims)
        n *= dim;
    accumulate(file, line, funcname, ti.toString(), ti.tsize * n);
    return _d_newarraymiTX(ti, dims);
}

extern (C) void* _d_newitemTTrace(string file, int line, string funcname, in TypeInfo ti)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.tsize);
    return _d_newitemT(ti);
}

extern (C) void* _d_newitemiTTrace(string file, int line, string funcname, in TypeInfo ti)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.tsize);
    return _d_newitemiT(ti);
}


extern (C) void _d_callfinalizer(void* p);
extern (C) void _d_callinterfacefinalizer(void *p);
extern (C) void _d_delclass(Object* p);
extern (C) void _d_delinterface(void** p);
extern (C) void _d_delstruct(void** p, TypeInfo_Struct inf);
extern (C) void _d_delarray_t(void[]* p, const TypeInfo_Struct ti);
extern (C) void _d_delmemory(void* *p);

extern (C) void _d_callfinalizerTrace(string file, int line, string funcname, void* p)
{
    mixin(generatePrintf());
    _d_callfinalizer(p);
}

extern (C) void _d_callinterfacefinalizerTrace(string file, int line, string funcname, void *p)
{
    mixin(generatePrintf());
    _d_callinterfacefinalizer(p);
}

extern (C) void _d_delclassTrace(string file, int line, string funcname, Object* p)
{
    mixin(generatePrintf());
    _d_delclass(p);
}

extern (C) void _d_delinterfaceTrace(string file, int line, string funcname, void** p)
{
    mixin(generatePrintf());
    _d_delinterface(p);
}

extern (C) void _d_delstructTrace(string file, int line, string funcname, void** p, TypeInfo_Struct inf)
{
    mixin(generatePrintf());
    _d_delstruct(p, inf);
}

extern (C) void _d_delarray_tTrace(string file, int line, string funcname, void[]* p, const TypeInfo_Struct ti)
{
    mixin(generatePrintf());
    _d_delarray_t(p, ti);
}

extern (C) void _d_delmemoryTrace(string file, int line, string funcname, void* *p)
{
    mixin(generatePrintf());
    _d_delmemory(p);
}


extern (C) void* _d_arrayliteralTX(const TypeInfo ti, size_t length);
extern (C) void* _d_assocarrayliteralTX(const TypeInfo_AssociativeArray ti, void[] keys, void[] vals);

extern (C) void* _d_arrayliteralTXTrace(string file, int line, string funcname, const TypeInfo ti, size_t length)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.next.tsize * length);
    return _d_arrayliteralTX(ti, length);
}

extern (C) void* _d_assocarrayliteralTXTrace(string file, int line, string funcname,
        const TypeInfo_AssociativeArray ti, void[] keys, void[] vals)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), (ti.key.tsize + ti.value.tsize) * keys.length);
    return _d_assocarrayliteralTX(ti, keys, vals);
}



extern (C) byte[] _d_arraycatT(const TypeInfo ti, byte[] x, byte[] y);
extern (C) void[] _d_arraycatnTX(const TypeInfo ti, byte[][] arrs);

extern (C) byte[] _d_arraycatTTrace(string file, int line, string funcname, const TypeInfo ti, byte[] x, byte[] y)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), (x.length + y.length) * ti.next.tsize);
    return _d_arraycatT(ti, x, y);
}

extern (C) void[] _d_arraycatnTXTrace(string file, int line, string funcname, const TypeInfo ti, byte[][] arrs)
{
    mixin(generatePrintf());
    size_t length;
    foreach (b; arrs)
        length += b.length;
    accumulate(file, line, funcname, ti.toString(), length * ti.next.tsize);
    return _d_arraycatnTX(ti, arrs);
}

extern (C) void[] _d_arrayappendT(const TypeInfo ti, ref byte[] x, byte[] y);
extern (C) byte[] _d_arrayappendcTX(const TypeInfo ti, ref byte[] px, size_t n);
extern (C) void[] _d_arrayappendcd(ref byte[] x, dchar c);
extern (C) void[] _d_arrayappendwd(ref byte[] x, dchar c);

extern (C) void[] _d_arrayappendTTrace(string file, int line, string funcname, const TypeInfo ti, ref byte[] x, byte[] y)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.next.tsize * y.length);
    return _d_arrayappendT(ti, x, y);
}

extern (C) byte[] _d_arrayappendcTXTrace(string file, int line, string funcname, const TypeInfo ti, ref byte[] px, size_t n)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.next.tsize * n);
    return _d_arrayappendcTX(ti, px, n);
}

extern (C) void[] _d_arrayappendcdTrace(string file, int line, string funcname, ref byte[] x, dchar c)
{
    mixin(generatePrintf());
    size_t n;
    if (c <= 0x7F)
        n = 1;
    else if (c <= 0x7FF)
        n = 2;
    else if (c <= 0xFFFF)
        n = 3;
    else if (c <= 0x10FFFF)
        n = 4;
    else
        assert(0);
    accumulate(file, line, funcname, "char[]", n * char.sizeof);
    return _d_arrayappendcd(x, c);
}

extern (C) void[] _d_arrayappendwdTrace(string file, int line, string funcname, ref byte[] x, dchar c)
{
    mixin(generatePrintf());
    size_t n = 1 + (c > 0xFFFF);
    accumulate(file, line, funcname, "wchar[]", n * wchar.sizeof);
    return _d_arrayappendwd(x, c);
}

extern (C) void[] _d_arraysetlengthT(const TypeInfo ti, size_t newlength, void[]* p);
extern (C) void[] _d_arraysetlengthiT(const TypeInfo ti, size_t newlength, void[]* p);

extern (C) void[] _d_arraysetlengthTTrace(string file, int line, string funcname, const TypeInfo ti, size_t newlength, void[]* p)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.next.tsize * newlength);
    return _d_arraysetlengthT(ti, newlength, p);
}

extern (C) void[] _d_arraysetlengthiTTrace(string file, int line, string funcname, const TypeInfo ti, size_t newlength, void[]* p)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, ti.toString(), ti.next.tsize * newlength);
    return _d_arraysetlengthiT(ti, newlength, p);
}


extern (C) void* _d_allocmemory(size_t sz);

extern (C) void* _d_allocmemoryTrace(string file, int line, string funcname, size_t sz)
{
    mixin(generatePrintf());
    accumulate(file, line, funcname, "closure", sz);
    return _d_allocmemory(sz);
}


