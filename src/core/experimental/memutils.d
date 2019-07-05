/**
 * Pure D replacement of the C Standard Library basic memory building blocks of string.h
 * Source: $(DRUNTIMESRC core/experimental/memutils.d)
 */
module core.experimental.memutils;

unittest
{
    Dmemset_testStaticType!(byte)(5);
    Dmemset_testStaticType!(ubyte)(5);
    Dmemset_testStaticType!(short)(5);
    Dmemset_testStaticType!(ushort)(5);
    Dmemset_testStaticType!(int)(5);
    Dmemset_testStaticType!(uint)(5);
    Dmemset_testStaticType!(long)(5);
    Dmemset_testStaticType!(ulong)(5);
    Dmemset_testStaticType!(float)(5);
    Dmemset_testStaticType!(double)(5);
    Dmemset_testStaticType!(real)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 3);
    static foreach (i; 1..10) {
        Dmemset_testDynamicArray!(ubyte)(5, 2^^i);
        Dmemset_testStaticArray!(ubyte, 2^^i)(5);
    }
    Dmemset_testDynamicArray!(ubyte)(5, 100);
    Dmemset_testStaticArray!(ubyte, 100)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 500);
    Dmemset_testStaticArray!(ubyte, 500)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 700);
    Dmemset_testStaticArray!(ubyte, 700)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 3434);
    Dmemset_testStaticArray!(ubyte, 3434)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 7128);
    Dmemset_testStaticArray!(ubyte, 7128)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 13908);
    Dmemset_testStaticArray!(ubyte, 13908)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 16343);
    Dmemset_testStaticArray!(ubyte, 16343)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 27897);
    Dmemset_testStaticArray!(ubyte, 27897)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 32344);
    Dmemset_testStaticArray!(ubyte, 32344)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 46830);
    Dmemset_testStaticArray!(ubyte, 46830)(5);
    Dmemset_testDynamicArray!(ubyte)(5, 64349);
    Dmemset_testStaticArray!(ubyte, 64349)(5);
}

// From a very good Chandler Carruth video on benchmarking: https://www.youtube.com/watch?v=nXaxk27zwlk
void escape(void* p)
{
    version (LDC)
    {
        import ldc.llvmasm;
        __asm("", "r,~{memory}", p);
    }
    version (GNU)
    {
        asm { "" : : "g" p : "memory"; }
    }
}

void Dmemset_verifyArray(T)(int j, const ref T[] a, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) a.ptr;
    for (size_t i = 0; i < a.length * T.sizeof; i++)
    {
        assert(p[i] == v);
    }
}

void Dmemset_verifyStaticType(T)(const ref T t, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) &t;
    for (size_t i = 0; i < T.sizeof; i++)
    {
        assert(p[i] == v);
    }
}

void Dmemset_testDynamicArray(T)(const ubyte v, size_t n)
{
    T[] buf;
    buf.length = n + 32;

    enum alignments = 32;
    size_t len = n;

    foreach (i; 0..alignments)
    {
        auto d = buf[i..i+n];

        escape(d.ptr);
        Dmemset(d, v);
        Dmemset_verifyArray(i, d, v);
    }
}

void Dmemset_testStaticArray(T, size_t n)(const ubyte v)
{
    T[n + 32] buf;

    enum alignments = 32;
    size_t len = n;

    foreach (i; 0..alignments)
    {
        auto d = buf[i..i+n];

        escape(d.ptr);
        Dmemset(d, v);
        Dmemset_verifyArray(i, d, v);
    }
}

void Dmemset_testStaticType(T)(const ubyte v)
{
    T t;
    escape(&t);
    Dmemset(t, v);
    Dmemset_verifyStaticType(t, v);
}

version (GNU)
{
    void Dmemset(void *d, const uint val, size_t n)
    {
        Dmemset_naive(d, cast(const(ubyte))val, n);
    }
}
else
{
    version (D_SIMD)
    {
        // NOTE(stefanos): I could not GDC respective intrinsics.
        void Dmemset(void *d, const uint val, size_t n)
        {
            import core.simd: int4;
            version (LDC)
            {
                import ldc.simd: loadUnaligned, storeUnaligned;
            }
            else
            version (DigitalMars)
            {
                import core.simd: void16, loadUnaligned, storeUnaligned;
            }
            else
            {
                static assert(0, "Only DMD / LDC are supported");
            }
            // TODO(stefanos): Is there a way to make them @safe?
            // (The problem is that for LDC, they could take int* or float* pointers
            // but the cast to void16 for DMD is necessary anyway).
            void store32i_sse(void *dest, int4 reg)
            {
                version (LDC)
                {
                    storeUnaligned!int4(reg, cast(int*)dest);
                    storeUnaligned!int4(reg, cast(int*)(dest+0x10));
                }
                else
                {
                    storeUnaligned(cast(void16*)dest, reg);
                    storeUnaligned(cast(void16*)(dest+0x10), reg);
                }
            }
            void store16i_sse(void *dest, int4 reg)
            {
                version (LDC)
                {
                    storeUnaligned!int4(reg, cast(int*)dest);
                }
                else
                {
                    storeUnaligned(cast(void16*)dest, reg);
                }
            }
            const uint v = val * 0x01010101;            // Broadcast c to all 4 bytes
            // NOTE(stefanos): I use the naive version, which in my benchmarks was slower
            // than the previous classic switch. BUT. Using the switch had a significant
            // drop in the rest of the sizes. It's not the branch that is responsible for the drop,
            // but the fact that it's more difficult to optimize it as part of the rest of the code.
            if (n <= 16)
            {
                Dmemset_naive(cast(ubyte*)d, cast(ubyte)val, n);
                return;
            }
            void *temp = d + n - 0x10;                  // Used for the last 32 bytes
            // Broadcast v to all bytes.
            auto xmm0 = int4(v);
            ubyte rem = cast(ubyte)d & 15;              // Remainder from the previous 16-byte boundary.
            // Store 16 bytes, from which some will possibly overlap on a future store.
            // For example, if the `rem` is 7, we want to store 16 - 7 = 9 bytes unaligned,
            // add 16 - 7 = 9 to `d` and start storing aligned. Since 16 - `rem` can be at most
            // 16, we store 16 bytes anyway.
            store16i_sse(d, xmm0);
            d += 16 - rem;
            n -= 16 - rem;
            // Move in blocks of 32.
            // TODO(stefanos): Experiment with differnt sizes.
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
}

void Dmemset_naive(void *dst, const ubyte val, size_t n)
{
    ubyte *d = cast(ubyte*)dst;
    for (size_t i = 0; i != n; ++i)
    {
        d[i] = val;
    }
}

// NOTE(stefanos):
// Range-checking is not needed since the user never
// pass an `n` (byte count) directly.

// Copied from std.traits
import core.internal.traits: Unqual;

package template ModifyTypePreservingTQ(alias Modifier, T)
{
    static if (is(T U ==          immutable U)) alias ModifyTypePreservingTQ =          immutable Modifier!U;
    else static if (is(T U == shared inout const U)) alias ModifyTypePreservingTQ = shared inout const Modifier!U;
    else static if (is(T U == shared inout       U)) alias ModifyTypePreservingTQ = shared inout       Modifier!U;
    else static if (is(T U == shared       const U)) alias ModifyTypePreservingTQ = shared       const Modifier!U;
    else static if (is(T U == shared             U)) alias ModifyTypePreservingTQ = shared             Modifier!U;
    else static if (is(T U ==        inout const U)) alias ModifyTypePreservingTQ =        inout const Modifier!U;
    else static if (is(T U ==        inout       U)) alias ModifyTypePreservingTQ =              inout Modifier!U;
    else static if (is(T U ==              const U)) alias ModifyTypePreservingTQ =              const Modifier!U;
    else                                             alias ModifyTypePreservingTQ =                    Modifier!T;
}

template OriginalType(T)
{
    template Impl(T)
    {
        static if (is(T U == enum)) alias Impl = OriginalType!U;
        else                        alias Impl =              T;
    }

    alias OriginalType = ModifyTypePreservingTQ!(Impl, T);
}

enum bool isAggregateType(T) = is(T == struct) || is(T == union) ||
                               is(T == class) || is(T == interface);

private template AliasThisTypeOf(T)
if (isAggregateType!T)
{
    alias members = __traits(getAliasThis, T);

    static if (members.length == 1)
    {
        alias AliasThisTypeOf = typeof(__traits(getMember, T.init, members[0]));
    }
    else
        static assert(0, T.stringof~" does not have alias this type");
}

template DynamicArrayTypeOf(T)
{
    static if (is(AliasThisTypeOf!T AT) && !is(AT[] == AT))
        alias X = DynamicArrayTypeOf!AT;
    else
        alias X = OriginalType!T;

    static if (is(Unqual!X : E[], E) && !is(typeof({ enum n = X.length; })))
    {
        alias DynamicArrayTypeOf = X;
    }
    else
        static assert(0, T.stringof~" is not a dynamic array");
}

enum bool isDynamicArray(T) = is(DynamicArrayTypeOf!T) && !isAggregateType!T;
enum bool isStaticArray(T) = __traits(isStaticArray, T);
enum bool isArray(T) = isStaticArray!T || isDynamicArray!T;

void Dmemset(T)(ref T dst, const ubyte val)
{
    const uint v = cast(uint)val;
    version (D_SIMD)
    {
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
    else
    {
        static if (isArray!T)
        {
            Dmemset_naive(dst.ptr, val, dst.length * typeof(dst[0]).sizeof);
        }
        else
        {
            Dmemset_naive(&dst, val, T.sizeof);
        }
    }
}
