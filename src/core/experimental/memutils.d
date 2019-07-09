/**
 * Pure D replacement of the C Standard Library basic memory building blocks of string.h
 * Source: $(DRUNTIMESRC core/experimental/memutils.d)
 */
module core.experimental.memutils;

void memmove(T)(T *dst, const T *src)
{
    void *d = cast(void*) dst;
    const(void) *s = cast(void*) src;
    if ((cast(ulong)d - cast(ulong)s) < T.sizeof)
    {  // There is overlap with dest being ahead. Use backwards move.
        Dmemmove_back(d, s, T.sizeof);
    }
    else if ((cast(ulong)s - cast(ulong)d) < T.sizeof)
    {  // There is overlap with src being ahead. Use backwards move.
        Dmemmove_forw(d, s, T.sizeof);
    }
    else
    {  // There is no overlap, use memcpy.
        Dmemcpy(dst, src);
    }
}

unittest
{
    real a = 1.2;
    real b;
    memmove(&b, &a);
    assert(b == 1.2);
    // Overwrite the type system and create overlap with dst forward.
    ubyte[8] buf;
    int *p = cast(int*) buf.ptr;
    int *q = cast(int*) (buf.ptr + 2);
    *p = 203847;
    memmove(q, p);
    assert(*q == 203847);
    // Create overlap with src forward.
    *q = 92239;
    memmove(p, q);
    assert(*p == 92239);
}

/* Dynamic Arrays
 */
void memmove(T)(T[] dst, const T[] src)
{
    mixin(arrayCode);
}

/* Static Arrays
 */
void memmove(T, size_t len)(ref T[len] dst, ref const T[len] src)
{
    mixin(arrayCode);
}

enum arrayCode = "
    assert(dst.length == src.length);
    void *d = cast(void*) dst.ptr;
    const void *s = cast(const(void)*) src.ptr;
    size_t n = dst.length * typeof(dst[0]).sizeof;
    if ((cast(ulong)d - cast(ulong)s) < n)
    {  // There is overlap with dest being ahead. Use backwards move.
        Dmemmove_back(d, s, n);
    }
    else if ((cast(ulong)s - cast(ulong)d) < n)
    {  // There is overlap with src being ahead. Use backwards move.
        Dmemmove_forw(d, s, n);
    }
    else
    {  // There is no overlap, use memcpy.
        pragma(inline, true);
        Dmemcpy(d, s, n);
    }";



unittest
{
    const float[3] a = [1.2, 3.4, 5.8];
    float[3] b;
    memmove(b, a);
    assert(b[0] == 1.2f);
    assert(b[1] == 3.4f);
    assert(b[2] == 5.8f);
}

/* Can we use SIMD?
 */
version (D_SIMD)
{
    import core.simd: float4;
    enum useSIMD = true;
}
else version (LDC)
{
    // LDC always supports SIMD (but doesn't ever set D_SIMD) and
    // the back-end uses the most appropriate size for every target.
    import core.simd: float4;
    enum useSIMD = true;
}
else version (GNU)
{
    import core.simd: float4;
    // GNU does not support SIMD by default.
    version (X86_64)
    {
        enum isX86 = true;
    }
    else version (X86)
    {
        enum isX86 = true;
    }

    static if (isX86 && __traits(compiles, float4))
    {
        enum useSIMD = true;
    }
    else
    {
        enum useSIMD = false;
    }
}
else
{
    enum useSIMD = false;
}

/* Little SIMD library
 */
static if (useSIMD)
{
    version (LDC)
    {
        import ldc.simd: loadUnaligned, storeUnaligned;
    }
    else version (DigitalMars)
    {
        import core.simd: void16, loadUnaligned, storeUnaligned;
    }
    else version (GNU)
    {
        import gcc.builtins : __builtin_ia32_storeups, __builtin_ia32_loadups;
    }

    void store16f_sse(void *dest, float4 reg)
    {
        version (LDC)
        {
            storeUnaligned!float4(reg, cast(float*)dest);
        }
        else version (DigitalMars)
        {
            storeUnaligned(cast(void16*)dest, reg);
        }
        else version (GNU)
        {
            __builtin_ia32_storeups(cast(float*) dest, reg);
        }
    }
    float4 load16f_sse(const(void) *src)
    {
        version (LDC)
        {
            return loadUnaligned!(float4)(cast(const(float)*) src);
        }
        else version (DigitalMars)
        {
            return loadUnaligned(cast(void16*) src);
        } else version (GNU)
        {
            return __builtin_ia32_loadups(cast(float*) src);
        }
    }

    void prefetchForward(void *s)
    {
        enum writeFetch = 0;
        enum locality = 3;  // -> t0
        version (DigitalMars)
        {
            import core.simd : prefetch;
            prefetch!(writeFetch, locality)(s+0x1a0);
            prefetch!(writeFetch, locality)(s+0x280);
        }
        else version (LDC)
        {
            import ldc.intrinsics : llvm_prefetch;
            enum dataCache = 1;
            llvm_prefetch(s+0x1a0, writeFetch, locality, dataCache);
            llvm_prefetch(s+0x280, writeFetch, locality, dataCache);
        }
        else version (GNU)
        {
            import gcc.builtins : __builtin_prefetch;
            __builtin_prefetch(s+0x1a0, writeFetch, locality);
            __builtin_prefetch(s+0x280, writeFetch, locality);
        }

    }
    void lstore128fp_sse(void *d, const(void) *s)
    {
        prefetchForward(cast(void*) s);
        lstore128f_sse(d, s);
    }
    void lstore128f_sse(void *d, const(void) *s)
    {
        float4 xmm0 = load16f_sse(cast(const float*)s);
        float4 xmm1 = load16f_sse(cast(const float*)(s+16));
        float4 xmm2 = load16f_sse(cast(const float*)(s+32));
        float4 xmm3 = load16f_sse(cast(const float*)(s+48));
        float4 xmm4 = load16f_sse(cast(const float*)(s+64));
        float4 xmm5 = load16f_sse(cast(const float*)(s+80));
        float4 xmm6 = load16f_sse(cast(const float*)(s+96));
        float4 xmm7 = load16f_sse(cast(const float*)(s+112));
        //
        store16f_sse(cast(float*)d, xmm0);
        store16f_sse(cast(float*)(d+16), xmm1);
        store16f_sse(cast(float*)(d+32), xmm2);
        store16f_sse(cast(float*)(d+48), xmm3);
        store16f_sse(cast(float*)(d+64), xmm4);
        store16f_sse(cast(float*)(d+80), xmm5);
        store16f_sse(cast(float*)(d+96), xmm6);
        store16f_sse(cast(float*)(d+112), xmm7);
    }
    void lstore64f_sse(void *d, const(void) *s)
    {
        float4 xmm0 = load16f_sse(cast(const float*)s);
        float4 xmm1 = load16f_sse(cast(const float*)(s+16));
        float4 xmm2 = load16f_sse(cast(const float*)(s+32));
        float4 xmm3 = load16f_sse(cast(const float*)(s+48));
        //
        store16f_sse(cast(float*)d, xmm0);
        store16f_sse(cast(float*)(d+16), xmm1);
        store16f_sse(cast(float*)(d+32), xmm2);
        store16f_sse(cast(float*)(d+48), xmm3);
    }
    void lstore32f_sse(void *d, const(void) *s)
    {
        float4 xmm0 = load16f_sse(cast(const float*)s);
        float4 xmm1 = load16f_sse(cast(const float*)(s+16));
        //
        store16f_sse(cast(float*)d, xmm0);
        store16f_sse(cast(float*)(d+16), xmm1);
    }
}

/*
 *
 *
 * memcpy() implementation
 *
 *
 */

/*
 * Static implementation
 *
 */

/* Handle static types.
 */
// NOTE(stefanos): Previously, there was more sophisticated code
// for static types. But the rationale of removing it is that
// the compiler knows better how to optimize static types.
pragma(inline, true)
void Dmemcpy(T)(T *dst, const T *src)
{
    *dst = *src;
}

/*
 * Dynamic implementation
 * NOTE: Dmemcpy requires _no_ overlap
 *
 */
static if (useSIMD)
{


/* Handle dynamic sizes. `d` and `s` must not overlap.
 */
void Dmemcpy(void *d, const(void) *s, size_t n)
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
void Dmemcpy_small(void *d, const(void) *s, size_t n)
{
    if (n < 16) {
        if (n & 0x01)
        {
            *cast(ubyte*)d = *cast(const ubyte*)s;
            ++d;
            ++s;
        }
        if (n & 0x02)
        {
            *cast(ushort*)d = *cast(const ushort*)s;
            d += 2;
            s += 2;
        }
        if (n & 0x04)
        {
            *cast(uint*)d = *cast(const uint*)s;
            d += 4;
            s += 4;
        }
        if (n & 0x08)
        {
            *cast(ulong*)d = *cast(const ulong*)s; }
        return;
    }
    if (n <= 32)
    {
        float4 xmm0 = load16f_sse(s);
        float4 xmm1 = load16f_sse(s-16+n);
        store16f_sse(d, xmm0);
        store16f_sse(d-16+n, xmm1);
        return;
    }
    // NOTE(stefanos): I'm writing using load/storeUnaligned() but you possibly can
    // achieve greater performance using naked ASM. Be careful that you should either use
    // only D or only naked ASM.
    if (n <= 64)
    {
        float4 xmm0 = load16f_sse(s);
        float4 xmm1 = load16f_sse(s+16);
        float4 xmm2 = load16f_sse(s-32+n);
        float4 xmm3 = load16f_sse(s-32+n+16);
        store16f_sse(d, xmm0);
        store16f_sse(d+16, xmm1);
        store16f_sse(d-32+n, xmm2);
        store16f_sse(d-32+n+16, xmm3);
        return;
    }
    import core.simd: void16;
    lstore64f_sse(d, s);
    // NOTE(stefanos): Requires _no_ overlap.
    n -= 64;
    s = s + n;
    d = d + n;
    lstore64f_sse(d, s);
}


/* Handle dynamic sizes > 128. `d` and `s` must not overlap.
 */
// TODO(stefanos): I tried prefetching. I suppose
// because this is a forward implementation, it should
// actuall reduce performance, but a better check would be good.
// TODO(stefanos): Consider aligning from the end, negate `n` and adding
// every time the `n` (and thus going backwards). That reduces the operations
// inside the loop.
// TODO(stefanos): Consider aligning `n` to 32. This will reduce one operation
// inside the loop but only if the compiler can pick it up (in my tests, it didn't).
// TODO(stefanos): Do a better research on how to inform the compiler about alignment,
// something like assume_aligned.
// NOTE(stefanos): This function requires _no_ overlap.
void Dmemcpy_large(void *d, const(void) *s, size_t n)
{
    // NOTE(stefanos): Alternative - Reach 64-byte
    // (cache-line) alignment and use rep movsb
    // Good for bigger sizes and only for Intel.

    // Align destination (write) to 32-byte boundary
    // NOTE(stefanos): We're using SSE, which needs 16-byte alignment.
    // But actually, 32-byte alignment was quite faster (probably because
    // the loads / stores are faster and there's the bottleneck).
    uint rem = cast(ulong)d & 15;
    if (rem)
    {
        store16f_sse(d, load16f_sse(s));
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
        mixin(loop!("lstore128fp_sse")());
    }
    else
    {
        mixin(loop!("lstore128f_sse")());
    }

    // NOTE(stefanos): We already have checked that the initial size is >= 128
    // to be here. So, we won't overwrite previous data.
    if (n != 0)
    {
        lstore128f_sse(d - 128 + n, s - 128 + n);
    }
}

}
else
{
    /* Non-SIMD version
     */
    // TODO(stefanos): GNU algorithm.
    void Dmemcpy(void *d, const(void) *s, size_t n)
    {
        ubyte *dst = cast(ubyte*) d;
        const(ubyte) *src = cast(const(ubyte)*) s;
        for (size_t i = 0; i != n; ++i)
        {
            *dst = *src;
            dst++;
            src++;
        }
    }
}



/*
 *
 *
 * memmove() implementation
 *
 *
 */

static if (useSIMD)
{


/* Handle dynamic sizes < 64 with backwards move. Overlap is possible.
 */
void Dmemmove_back_lt64(void *d, const(void) *s, size_t n)
{
    if (n & 32)
    {
        n -= 32;
        // IMPORTANT(stefanos): Don't call _store* functions as they copy forward.
        // First load both values, _then_ store.
        float4 xmm0 = load16f_sse(s+n+16);
        float4 xmm1 = load16f_sse(s+n);
        store16f_sse(d+n+16, xmm0);
        store16f_sse(d+n, xmm1);
    }
    if (n & 16)
    {
        n -= 16;
        float4 xmm0 = load16f_sse(s+n);
        store16f_sse(d+n, xmm0);
    }
    if (n & 8)
    {
        n -= 8;
        *(cast(ulong*)(d+n)) = *(cast(const ulong*)(s+n));
    }
    if (n & 4)
    {
        n -= 4;
        *(cast(uint*)(d+n)) = *(cast(const uint*)(s+n));
    }
    if (n & 2)
    {
        n -= 2;
        *(cast(ushort*)(d+n)) = *(cast(const ushort*)(s+n));
    }
    if (n & 1)
    {
        *(cast(ubyte*)d) = *(cast(const ubyte*)s);
    }
}


/* Handle dynamic sizes with backwards move. Overlap is possible.
 */
void Dmemmove_back(void *d, const(void) *s, size_t n)
{
START:
    if (n < 64)
    {
        Dmemmove_back_lt64(d, s, n);
        return;
    }
    s += n;
    d += n;
    if (n < 128)
    {
        float4 xmm0 = load16f_sse(s-0x10);
        float4 xmm1 = load16f_sse(s-0x20);
        float4 xmm2 = load16f_sse(s-0x30);
        float4 xmm3 = load16f_sse(s-0x40);
        store16f_sse(d-0x10, xmm0);
        store16f_sse(d-0x20, xmm1);
        store16f_sse(d-0x30, xmm2);
        store16f_sse(d-0x40, xmm3);
        // NOTE(stefanos): We can't do the standard trick where we just go back enough bytes
        // so that we can move the last bytes with a 64-byte move even if they're less than 64.
        // To do that, we have to _not_ have overlap.
        s = s - n;
        d = d - n;
        n -= 64;
        Dmemmove_back_lt64(d, s, n);
        return;
    }
    uint rem = cast(ulong)d & 31;
    if (rem)
    {
        // NOTE(stefanos): Again, can't use the standard trick because of overlap.
        Dmemmove_back_lt64(d-rem, s-rem, rem);
        s -= rem;
        d -= rem;
        n -= rem;
    }
    while (n >= 128)
    {
        // NOTE(stefanos): No problem with the overlap here since
        // we never use overlapped bytes. But, we should still copy backwards.
        // NOTE(stefanos): Prefetching had ambiguous and not clear win.
        store16f_sse(d-0x10, load16f_sse(s-0x10));
        store16f_sse(d-0x20, load16f_sse(s-0x20));
        store16f_sse(d-0x30, load16f_sse(s-0x30));
        store16f_sse(d-0x40, load16f_sse(s-0x40));
        store16f_sse(d-0x50, load16f_sse(s-0x50));
        store16f_sse(d-0x60, load16f_sse(s-0x60));
        store16f_sse(d-0x70, load16f_sse(s-0x70));
        store16f_sse(d-0x80, load16f_sse(s-0x80));
        s -= 128;
        d -= 128;
        n -= 128;
    }

    if (n)
    {
        // NOTE(stefanos): Again, can't use the standard trick because of overlap.
        // Move pointers to their start.
        s -= n;
        d -= n;
        goto START;
    }
}

/* Handle dynamic sizes < 64 with forwards move. Overlap is possible.
 */
void Dmemmove_forw_lt64(void *d, const(void) *s, size_t n)
{
    if (n & 32)
    {
        lstore32f_sse(d, s);
        n -= 32;
        s += 32;
        d += 32;
    }
    if (n & 16)
    {
        store16f_sse(d, load16f_sse(s));
        n -= 16;
        s += 16;
        d += 16;
    }
    if (n & 8)
    {
        *(cast(ulong*)(d)) = *(cast(const ulong*)(s));
        n -= 8;
        s += 8;
        d += 8;
    }
    if (n & 4)
    {
        n -= 4;
        *(cast(uint*)(d)) = *(cast(const uint*)(s));
        n -= 4;
        s += 4;
        d += 4;
    }
    if (n & 2)
    {
        n -= 2;
        *(cast(ushort*)(d)) = *(cast(const ushort*)(s));
        n -= 2;
        s += 2;
        d += 2;
    }
    if (n & 1)
    {
        *(cast(ubyte*)d) = *(cast(const ubyte*)s);
    }
}

/* Handle dynamic sizes with forwards move. Overlap is possible.
 */
void Dmemmove_forw(void *d, const(void) *s, size_t n)
{
START:
    if (n < 64)
    {
        Dmemmove_forw_lt64(d, s, n);
        return;
    }
    if (n < 128)
    {
        // We know it's >= 64, so move the first 64 bytes freely.
        lstore64f_sse(d, s);
        // NOTE(stefanos): We can't do the standard trick where we just go forward enough bytes
        // so that we can move the last bytes with a 64-byte move even if they're less than 64.
        // To do that, we have to _not_ have overlap.
        s += 64;
        d += 64;
        n -= 64;
        Dmemmove_forw_lt64(d, s, n);
        return;
    }
    uint rem = cast(ulong)d & 31;
    if (rem)
    {
        // NOTE(stefanos): Again, can't use the standard trick because of overlap.
        Dmemmove_forw_lt64(d, s, 32-rem);
        s += 32 - rem;
        d += 32 - rem;
        n -= 32 - rem;
    }

    while (n >= 128)
    {
        // NOTE(stefanos): No problem with the overlap here since
        // we never use overlapped bytes.
        // NOTE(stefanos): Prefetching had a relatively insignificant
        // win for about > 30000.
        lstore128f_sse(d, s);
        s += 128;
        d += 128;
        n -= 128;
    }

    if (n)
    {
        // NOTE(stefanos): Again, can't use the standard trick because of overlap.
        goto START;
    }
}

}
else
{
    void Dmemmove_forw(void *d, const(void) *s, size_t n)
    {
        ubyte *dst = cast(ubyte*) d;
        const(ubyte) *src = cast(const(ubyte)*) s;
        foreach (i; 0 .. n)
        {
            *(dst+i) = *(src+i);
        }
    }

    void Dmemmove_back(void *d, const(void) *s, size_t n)
    {
        ubyte *dst = cast(ubyte*) d;
        const(ubyte) *src = cast(const(ubyte)*) s;
        foreach_reverse (i; 0 .. n)
        {
            *(dst+i) = *(src+i);
        }
    }
}
