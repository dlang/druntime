/**
 * An currently small experimental SIMD library for D. It is cross-compiler (DMD, LDC, GDC)
 * and cross-platform (For GDC, it is only i386 and x86_64 specific).
 * Source: $(DRUNTIMESRC core/experimental/memory/simd.d)
 */
module core.experimental.memory.simd;

/* Provide enum to the user to know
 * if they can use SIMD
 */
version (D_SIMD)
{
    import core.simd : float4;
    enum useSIMD = true;
}
else version (LDC)
{
    // LDC always supports SIMD (but doesn't ever set D_SIMD) and
    // the back-end uses the most appropriate size for every target.
    import core.simd : float4;
    enum useSIMD = true;
}
else version (GNU)
{
    import core.simd : float4;
    // GNU does not support SIMD by default.
    version (X86_64)
    {
        private enum isX86 = true;
    }
    else version (X86)
    {
        private enum isX86 = true;
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

static if (useSIMD)
{
    version (LDC)
    {
        import ldc.simd : loadUnaligned, storeUnaligned;
    }
    else version (DigitalMars)
    {
        import core.simd : void16, loadUnaligned, storeUnaligned;
    }
    else version (GNU)
    {
        import gcc.builtins : __builtin_ia32_storeups, __builtin_ia32_loadups;
    }

    void store16fSSE(void* dest, float4 reg) nothrow @nogc
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
    float4 load16fSSE(const(void)* src) nothrow @nogc
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

    private void prefetchForward(void* s) nothrow @nogc
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
    void lstore128fpSSE(void* d, const(void)* s) nothrow @nogc
    {
        prefetchForward(cast(void*) s);
        lstore128fSSE(d, s);
    }
    void lstore128fSSE(void* d, const(void)* s) nothrow @nogc
    {
        float4 xmm0 = load16fSSE(cast(const float*)s);
        float4 xmm1 = load16fSSE(cast(const float*)(s+16));
        float4 xmm2 = load16fSSE(cast(const float*)(s+32));
        float4 xmm3 = load16fSSE(cast(const float*)(s+48));
        float4 xmm4 = load16fSSE(cast(const float*)(s+64));
        float4 xmm5 = load16fSSE(cast(const float*)(s+80));
        float4 xmm6 = load16fSSE(cast(const float*)(s+96));
        float4 xmm7 = load16fSSE(cast(const float*)(s+112));
        //
        store16fSSE(cast(float*)d, xmm0);
        store16fSSE(cast(float*)(d+16), xmm1);
        store16fSSE(cast(float*)(d+32), xmm2);
        store16fSSE(cast(float*)(d+48), xmm3);
        store16fSSE(cast(float*)(d+64), xmm4);
        store16fSSE(cast(float*)(d+80), xmm5);
        store16fSSE(cast(float*)(d+96), xmm6);
        store16fSSE(cast(float*)(d+112), xmm7);
    }
    void lstore64fSSE(void* d, const(void)* s) nothrow @nogc
    {
        float4 xmm0 = load16fSSE(cast(const float*)s);
        float4 xmm1 = load16fSSE(cast(const float*)(s+16));
        float4 xmm2 = load16fSSE(cast(const float*)(s+32));
        float4 xmm3 = load16fSSE(cast(const float*)(s+48));
        //
        store16fSSE(cast(float*)d, xmm0);
        store16fSSE(cast(float*)(d+16), xmm1);
        store16fSSE(cast(float*)(d+32), xmm2);
        store16fSSE(cast(float*)(d+48), xmm3);
    }
    void lstore32fSSE(void* d, const(void)* s) nothrow @nogc
    {
        float4 xmm0 = load16fSSE(cast(const float*)s);
        float4 xmm1 = load16fSSE(cast(const float*)(s+16));
        //
        store16fSSE(cast(float*)d, xmm0);
        store16fSSE(cast(float*)(d+16), xmm1);
    }
}
