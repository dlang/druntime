/**
 * Pure D replacement of the C Standard Library basic memory building blocks of string.h
 * Source: $(DRUNTIMESRC core/experimental/memutils.d)
 */
module core.experimental.memutils;

/*
  If T is an array, set all `dst`'s bytes
  (whose count is the length of the array times
  the size of the array element) to `val`.
  Otherwise, set T.sizeof bytes to `val` starting from the address of `dst`.
*/
void memset(T)(ref T dst, const ubyte val)
{
    import core.internal.traits : isArray;
    const uint v = cast(uint) val;
    static if (isArray!T)
    {
        size_t n = dst.length * typeof(dst[0]).sizeof;
        Dmemset(dst.ptr, v, n);
    }
    else
    {
        Dmemset(&dst, v, T.sizeof);
    }
}

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

    static if (isX86 && __traits(compiles, int4))
    {
        enum useSIMD = true;
    }
    else
    {
        enum useSIMD = false;
    }
}

version (useSIMD)
{
    /* SIMD implementation
     */
    private void Dmemset(void *d, const uint val, size_t n)
    {
        import core.simd : int4;
        version (LDC)
        {
            import ldc.simd : loadUnaligned, storeUnaligned;
            void store16i_sse(void *dest, int4 reg)
            {
                storeUnaligned!int4(reg, cast(int*) dest);
            }
        }
        else version (DigitalMars)
        {
            import core.simd : void16, loadUnaligned, storeUnaligned;
            void store16i_sse(void *dest, int4 reg)
            {
                storeUnaligned(cast(void16*) dest, reg);
            }
        }
        else
        {
            import gcc.builtins;
            import core.simd : ubyte16;
            void store16i_sse(void *dest, int4 reg)
            {
                __builtin_ia32_storedqu(cast(char*) dest, cast(ubyte16) reg);
            }
        }
        void store32i_sse(void *dest, int4 reg)
        {
            store16i_sse(dest, reg);
            store16i_sse(dest+0x10, reg);
        }

        // NOTE(stefanos): I use the naive version, which in my benchmarks was slower
        // than the previous classic switch. BUT. Using the switch had a significant
        // drop in the rest of the sizes. It's not the branch that is responsible for the drop,
        // but the fact that it's more difficult to optimize it as part of the rest of the code.
        if (n < 32)
        {
            memsetNaive(d, val, n);
            return;
        }
        void *temp = d + n - 0x10;                  // Used for the last 32 bytes
        const uint v = val * 0x01010101;            // Broadcast c to all 4 bytes
        // Broadcast v to all bytes.
        auto xmm0 = int4(v);
        ubyte rem = cast(ubyte) d & 15;              // Remainder from the previous 16-byte boundary.
        // Store 16 bytes, from which some will possibly overlap on a future store.
        // For example, if the `rem` is 7, we want to store 16 - 7 = 9 bytes unaligned,
        // add 16 - 7 = 9 to `d` and start storing aligned. Since 16 - `rem` can be at most
        // 16, we store 16 bytes anyway.
        store16i_sse(d, xmm0);
        d += 16 - rem;
        n -= 16 - rem;
        // Move in blocks of 32.
        if (n >= 32)
        {
            // Align to (previous) multiple of 32. That does something invisible to the code,
            // but a good optimizer will avoid a `cmp` instruction inside the loop. With a
            // multiple of 32, the end of the loop can be (if we assume that `n` is in RDX):
            // sub RDX, 32;
            // jge START_OF_THE_LOOP.
            // Without that, it has to be:
            // sub RDX, 32;
            // cmp RDX, 32;
            // jge START_OF_THE_LOOP
            // NOTE, that we align on a _previous_ multiple (for 37, we will go to 32). That means
            // we have somehow to compensate for that, which is done at the end of this function.
            n &= -32;
            do
            {
                store32i_sse(d, xmm0);
                // NOTE(stefanos): I tried avoiding this operation on `d` by combining
                // `d` and `n` in the above loop and going backwards. It was slower in my benchs.
                d += 32;
                n -= 32;
            } while (n >= 32);
        }
        // Compensate for the last (at most) 32 bytes.
        store32i_sse(temp-0x10, xmm0);
    }
}
else
{
    /* Forward to simple implementation.
     */
    private void Dmemset(void *d, const uint val, size_t n)
    {
        memsetNaive(d, val, n);
    }
}

/*
  Naive version for when there isn't any vector support (SIMD etc.).
*/
private void memsetNaive(void *dst, const uint val, size_t n)
{
    // NOTE(stefanos): DMD could not inline it.
    void handleLT16Sizes(void *d, const ulong v, size_t n)
    {
        switch (n)
        {
            case 6:
                *(cast(uint*) (d+2)) = cast(uint) v;
                goto case 2;  // fall-through
            case 2:
                *(cast(ushort*) d) = cast(ushort) v;
                return;

            case 7:
                *(cast(uint*) (d+3)) = cast(uint) v;
                goto case 3;  // fall-through
            case 3:
                *(cast(ushort*) (d+1)) = cast(ushort) v;
                goto case 1;  // fall-through
            case 1:
                *(cast(ubyte*) d) = cast(ubyte) v;
                return;

            case 4:
                *(cast(uint*) d) = cast(uint) v;
                return;
            case 0:
                return;

            case 5:
                *(cast(uint*) (d+1)) = cast(uint) v;
                *(cast(ubyte*) d) = cast(ubyte) v;
                return;
            default:
        }
    }


    const ulong v = cast(ulong) val * 0x0101010101010101;  // Broadcast c to all 8 bytes
    if (n < 8)
    {
        handleLT16Sizes(dst, v, n);
        return;
    }
    // NOTE(stefanos): Normally, we would have different alignment
    // for 32-bit and 64-bit versions. For the sake of simplicity,
    // we'll let the compiler do the work.
    ubyte rem = cast(ubyte) dst & 7;
    if (rem)
    {  // Unaligned
        // Move 8 bytes (which we will possibly overlap later).
        *(cast(ulong*) dst) = v;
        dst += 8 - rem;
        n -= 8 - rem;
    }
    ulong *d = cast(ulong*) dst;
    ulong temp = n / 8;
    // Go in steps of 8 - the register size in x86_64.
    for (size_t i = 0; i != temp; ++i)
    {
        *d = v;
        ++d;
        n -= 8;
    }
    dst = cast(void *) d;

    handleLT16Sizes(dst, v, n);
}


/** Core features tests.
  */
unittest
{
    ubyte[3] a;
    memset(a, 7);
    assert(a[0] == 7);
    assert(a[1] == 7);
    assert(a[2] == 7);

    real b;
    memset(b, 9);
    ubyte *p = cast(ubyte*) &b;
    foreach (i; 0 .. b.sizeof)
    {
        assert(p[i] == 9);
    }
}
