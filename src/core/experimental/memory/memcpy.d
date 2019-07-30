/**
 * Pure D replacement of the C Standard Library memcpy().
 * There is an idiomatic-D interface, memcpy(), which is split into 3 overloads.
 * One taking static types, one dynamic arrays and one static arrays.
 * Also, there is available a C-like interface, the Dmemcpy() (which is named Dmemcpy
 * for disambiguation with the C memcpy() which has the exact same interface) that
 * is the classic (void*, void*, size_t) interface.
 * Source: $(DRUNTIMESRC core/experimental/memory/memcpy.d)
 */
module core.experimental.memory.memcpy;

import core.internal.traits : isArray;

/* Static Types
   N.B.: No need for more sophisticated code for static types. The compiler
   knows better how to handle them in every target case.
 */
pragma(inline, true)
void memcpy(T)(ref T dst, ref const T src)
if (!isArray!T)
{
    dst = src;
}

/* Dynamic Arrays
 */
void memcpy(T)(ref T[] dst, ref const T[] src)
{
    assert(dst.length == src.length);
    void* d = cast(void*) dst.ptr;
    const(void)* s = cast(const(void)*) src.ptr;
    size_t n = dst.length * typeof(dst[0]).sizeof;
    // Assume that there is no overlap.
    pragma(inline, true);
    Dmemcpy(d, s, n);
}

/* Static Arrays
 */
void memcpy(T, size_t len)(ref T[len] dst, ref const T[len] src)
{
    T[] d = dst[0 .. $];
    const T[] s = src[0 .. $];
    memcpy(d, s);
}

/** Tests
  */

/* Basic features tests
 */
unittest
{
    real a = 1.2;
    real b;
    memcpy(b, a);
    assert(b == 1.2);
}
///
unittest
{
    const float[3] a = [1.2, 3.4, 5.8];
    float[3] b;
    memcpy(b, a);
    assert(b[0] == 1.2f);
    assert(b[1] == 3.4f);
    assert(b[2] == 5.8f);
}

/* More sophisticated test suite
 */
version (unittest)
{
    /* Handy struct
     */
    struct S(size_t Size)
    {
        ubyte[Size] x;
    }
    void tests()
    {
        testStaticType!(byte);
        testStaticType!(ubyte);
        testStaticType!(short);
        testStaticType!(ushort);
        testStaticType!(int);
        testStaticType!(uint);
        testStaticType!(long);
        testStaticType!(ulong);
        testStaticType!(float);
        testStaticType!(double);
        testStaticType!(real);
        static foreach (i; 1..100)
        {
            testStaticType!(S!i);
            testDynamicArray!(i)();
        }
        testStaticType!(S!3452);
        testDynamicArray!(3452)();
        testStaticType!(S!6598);
        testDynamicArray!(6598);
        testStaticType!(S!14928);
        testDynamicArray!(14928);
        testStaticType!(S!27891);
        testDynamicArray!(27891);
        testStaticType!(S!44032);
        testStaticType!(S!55897);
        testStaticType!(S!79394);
        testStaticType!(S!256);
        testStaticType!(S!512);
        testStaticType!(S!1024);
        testStaticType!(S!2048);
        testStaticType!(S!4096);
        testStaticType!(S!8192);
        testStaticType!(S!16384);
        testStaticType!(S!32768);
        testStaticType!(S!65536);
    }
    pragma(inline, false)
    void initStatic(T)(T *v)
    {
        auto m = (cast(ubyte*) v)[0 .. T.sizeof];
        for (int i = 0; i < m.length; i++)
        {
            m[i] = cast(ubyte) i;
        }
    }
    pragma(inline, false)
    void verifyStaticType(T)(const T *a, const T *b)
    {
        const ubyte* aa = (cast(const ubyte*) a);
        const ubyte* bb = (cast(const ubyte*) b);
        // NOTE(stefanos): `real` is an exceptional case,
        // in that it behaves differently across compilers
        // because it's not a power of 2 (its size is 10 for x86)
        // and thus padding is added (to reach 16). But, the padding bytes
        // are not considered (by the compiler) in a move (for instance).
        // So, Dmemcpy, for static types, is *dst = *src. And the compiler
        // might output `fld` followed by `fstp` instruction. Those intructions
        // operate on extended floating point values (whose size is 10). And so,
        // the padding bytes are not copied to dest.
        static if (is(T == real))
        {
            enum n = 10;
        }
        else
        {
            enum n = T.sizeof;
        }
        for (size_t i = 0; i < n; i++)
        {
            assert(aa[i] == bb[i]);
        }
    }
    pragma(inline, false)
    void testStaticType(T)()
    {
        T d, s;
        initStatic!(T)(&d);
        initStatic!(T)(&s);
        memcpy(d, s);
        verifyStaticType(&d, &s);
    }
    pragma(inline, false)
    void init(T)(ref T[] v)
    {
        for (int i = 0; i < v.length; i++)
        {
            v[i] = cast(ubyte) i;
        }
    }
    pragma(inline, false)
    void verifyArray(size_t j, const ref ubyte[] a, const ref ubyte[80000] b)
    {
        //assert(a.length == b.length);
        for (int i = 0; i < a.length; i++)
        {
            assert(a[i] == b[i]);
        }
    }
    pragma(inline, false)
    void testDynamicArray(size_t n)()
    {
        ubyte[80000] buf1;
        ubyte[80000] buf2;
        enum alignments = 32;
        foreach (i; 0..alignments)
        {
            ubyte[] p = buf1[i..i+n];
            ubyte[] q;
            // Relatively aligned
            q = buf2[0..n];
            // Use a copy for the cases of overlap.
            ubyte[80000] copy;
            pragma(inline, false);
            init(q);
            pragma(inline, false);
            init(p);
            for (size_t k = 0; k != p.length; ++k)
            {
                copy[k] = p[k];
            }
            pragma(inline, false);
            memcpy(q, p);
            pragma(inline, false);
            verifyArray(i, q, copy);
        }
    }
}

unittest
{
    tests();
}

/* Implementation
 */

import core.experimental.memory.simd;

/*
 * Dynamic implementation
 * N.B.: All Dmemcpy functions require _no_ overlap.
 *
 */
static if (useSIMD)
{

import core.simd : float4;

/* Handle dynamic sizes. `d` and `s` must not overlap.
 */
void Dmemcpy(void* d, const(void)* s, size_t n)
{
    if (n <= 128)
    {
        Dmemcpy_small(d, s, n);
    }
    else
    {
        Dmemcpy_large(d, s, n);
    }
}

/* Handle dynamic sizes <= 128. `d` and `s` must not overlap.
 */
private void Dmemcpy_small(void* d, const(void)* s, size_t n)
{
    if (n < 16) {
        if (n & 0x01)
        {
            *(cast(ubyte*) d) = *(cast(const ubyte*) s);
            ++d;
            ++s;
        }
        if (n & 0x02)
        {
            *(cast(ushort*) d) = *(cast(const ushort*) s);
            d += 2;
            s += 2;
        }
        if (n & 0x04)
        {
            *(cast(uint*) d) = *(cast(const uint*) s);
            d += 4;
            s += 4;
        }
        if (n & 0x08)
        {
            *(cast(ulong*) d) = *(cast(const ulong*) s);
        }
        return;
    }
    if (n <= 32)
    {
        float4 xmm0 = load16fSSE(s);
        float4 xmm1 = load16fSSE(s-16+n);
        store16fSSE(d, xmm0);
        store16fSSE(d-16+n, xmm1);
        return;
    }
    // NOTE(stefanos): I'm writing using load/storeUnaligned() but you possibly can
    // achieve greater performance using naked ASM. Be careful that you should either use
    // only D or only naked ASM.
    if (n <= 64)
    {
        float4 xmm0 = load16fSSE(s);
        float4 xmm1 = load16fSSE(s+16);
        float4 xmm2 = load16fSSE(s-32+n);
        float4 xmm3 = load16fSSE(s-32+n+16);
        store16fSSE(d, xmm0);
        store16fSSE(d+16, xmm1);
        store16fSSE(d-32+n, xmm2);
        store16fSSE(d-32+n+16, xmm3);
        return;
    }
    import core.simd : void16;
    lstore64fSSE(d, s);
    // Requires _no_ overlap.
    n -= 64;
    s = s + n;
    d = d + n;
    lstore64fSSE(d, s);
}

/* Handle dynamic sizes > 128. `d` and `s` must not overlap.
 */
private void Dmemcpy_large(void* d, const(void)* s, size_t n)
{
    // NOTE(stefanos): Alternative - Reach 64-byte
    // (cache-line) alignment and use rep movsb
    // Good for bigger sizes and only for Intel.

    // Align destination (write) to 32-byte boundary
    // NOTE(stefanos): We're using SSE, which needs 16-byte alignment.
    // But actually, 32-byte alignment was quite faster (probably because
    // the loads / stores are faster and there's the bottleneck).
    uint rem = cast(ulong) d & 15;
    if (rem)
    {
        store16fSSE(d, load16fSSE(s));
        s += 16 - rem;
        d += 16 - rem;
        n -= 16 - rem;
    }

    static string loop(string prefetchChoice)()
    {
        return
        "
        while (n >= 128)
        {
            // Aligned stores / writes
            " ~ prefetchChoice ~ "(d, s);
            d += 128;
            s += 128;
            n -= 128;
        }
        ";
    }

    if (n >= 20000)
    {
        mixin(loop!("lstore128fpSSE")());
    }
    else
    {
        mixin(loop!("lstore128fSSE")());
    }

    // We already have checked that the initial size is >= 128
    // to be here. So, we won't overwrite previous data.
    if (n != 0)
    {
        lstore128fSSE(d - 128 + n, s - 128 + n);
    }
}

}
else
{

/* Non-SIMD version
 */
void Dmemcpy(void* d, const(void)* s, size_t n)
{
    ubyte* dst = cast(ubyte*) d;
    const(ubyte)* src = cast(const(ubyte)*) s;
    for (size_t i = 0; i != n; ++i)
    {
        *dst = *src;
        dst++;
        src++;
    }
}
}
