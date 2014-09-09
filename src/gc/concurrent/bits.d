/**
 * This module contains a specialized bitset implementation.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, David Friedman, Sean Kelly
 */

module gc.concurrent.bits;

import os = gc.concurrent.os;

import cstring = core.stdc.string;

private extern (C) void onOutOfMemoryError();


version (DigitalMars)
{
    version = bitops;
    import core.bitop;
}
else version (GNU)
{
    // use the unoptimized version
}
else version(LDC)
{
    // ditto
}
else version (D_InlineAsm_X86)
{
    version = Asm86;
}

struct GCBits
{
    enum int BITS_PER_WORD = 32;
    enum int BITS_SHIFT = 5;
    enum int BITS_MASK = 31;

    uint*  data = null;
    size_t nwords = 0;    // allocated words in data[] excluding sentinals
    size_t nbits = 0;     // number of bits in data[] excluding sentinals

    /// Get the number of bytes needed to store nbits bits
    size_t data_size()
    {
        return (nwords + 2) * uint.sizeof; // +2 for sentinels
    }

    void Dtor(os.Vis vis = os.Vis.PRIV)
    {
        // Even when os.dealloc() can be called with a null pointer, the extra
        // call might be significant. On hard GC benchmarks making the test for
        // null here (i.e. not making the call) can reduce the GC time by
        // almost ~5%.
        if (data)
        {
            os.dealloc(data, data_size, vis);
            data = null;
        }
    }

    invariant
    {
        if (data)
            assert (nwords ==
                    ((nbits + (BITS_PER_WORD - 1)) >> BITS_SHIFT));
    }

    void alloc(size_t nbits, os.Vis vis = os.Vis.PRIV)
    {
        this.nbits = nbits;
        this.nwords = (nbits + (BITS_PER_WORD - 1)) >> BITS_SHIFT;
        this.data = cast(uint*) os.alloc(data_size, vis);
        if (!data)
            onOutOfMemoryError();
    }

    uint test(size_t i)
    in
    {
        assert(i < nbits);
    }
    body
    {
        //return (cast(bit *)(data + 1))[i];
        return data[1 + (i >> BITS_SHIFT)] & (1 << (i & BITS_MASK));
    }

    void set(size_t i)
    in
    {
        assert(i < nbits);
    }
    body
    {
        //(cast(bit *)(data + 1))[i] = 1;
        data[1 + (i >> BITS_SHIFT)] |= (1 << (i & BITS_MASK));
    }

    void clear(size_t i)
    in
    {
        assert(i < nbits);
    }
    body
    {
        //(cast(bit *)(data + 1))[i] = 0;
        data[1 + (i >> BITS_SHIFT)] &= ~(1 << (i & BITS_MASK));
    }

    uint testClear(size_t i)
    {
        version (bitops)
        {
            return btr(cast(size_t*) (data + 1), i);
        }
        else version (Asm86)
        {
            asm
            {
                naked                   ;
                mov     EAX,data[EAX]   ;
                mov     ECX,i-4[ESP]    ;
                btr     4[EAX],ECX      ;
                sbb     EAX,EAX         ;
                ret     4               ;
            }
        }
        else
        {
            //result = (cast(bit *)(data + 1))[i];
            //(cast(bit *)(data + 1))[i] = 0;

            uint* p = &data[1 + (i >> BITS_SHIFT)];
            uint  mask = (1 << (i & BITS_MASK));
            uint result = *p & mask;
            *p &= ~mask;
            return result;
        }
    }

    void zero()
    {
        cstring.memset(data + 1, 0, nwords * uint.sizeof);
    }

    void set_all()
    {
        cstring.memset(data + 1, 0xff, nwords * uint.sizeof);
    }

    void set_group(size_t base, size_t nbits)
    in
    {
    }
    body
    {
        assert ((base % 8) == 0);
        assert ((nbits % 8) == 0);
        size_t nbytes = nbits / 8;
        cstring.memset(data + 1 + (base >> BITS_SHIFT), 0xff, nbytes);
    }

    void copy(GCBits *f)
    in
    {
        assert(nwords == f.nwords);
    }
    body
    {
        cstring.memcpy(data + 1, f.data + 1, nwords * uint.sizeof);
    }

    uint* base()
    in
    {
        assert(data);
    }
    body
    {
        return data + 1;
    }
}

unittest
{
    GCBits b;

    b.alloc(786);
    assert(b.test(123) == 0);
    assert(b.testClear(123) == 0);
    b.set(123);
    assert(b.test(123) != 0);
    assert(b.testClear(123) != 0);
    assert(b.test(123) == 0);

    b.set(785);
    b.set(0);
    assert(b.test(785) != 0);
    assert(b.test(0) != 0);
    b.zero();
    assert(b.test(785) == 0);
    assert(b.test(0) == 0);

    GCBits b2;
    b2.alloc(786);
    b2.set(38);
    b.copy(&b2);
    assert(b.test(38) != 0);
    b2.Dtor();

    b.Dtor();
}


// vim: set et sw=4 sts=4 :
