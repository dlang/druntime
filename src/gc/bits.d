/**
 * Contains a bitfield used by the GC.
 *
 * Copyright: Copyright Digital Mars 2005 - 2013.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, David Friedman, Sean Kelly
 */

/*          Copyright Digital Mars 2005 - 2013.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.bits;


import core.bitop;
import core.stdc.string;
import core.stdc.stdlib;
import core.exception : onOutOfMemoryError;


// use version bitwise to disable optimizations that use word operands
// on bulk operation copyRange, setRange, clrRange, etc.
// version = bitwise;

struct GCBits
{
    alias size_t wordtype;

    enum BITS_PER_WORD = (wordtype.sizeof * 8);
    enum BITS_SHIFT = (wordtype.sizeof == 8 ? 6 : 5);
    enum BITS_MASK = (BITS_PER_WORD - 1);
    enum BITS_0 = cast(wordtype)0;
    enum BITS_1 = cast(wordtype)1;
    enum BITS_2 = cast(wordtype)2;

    wordtype* data;
    size_t nbits;

    void Dtor() nothrow
    {
        if (data)
        {
            free(data);
            data = null;
        }
    }

    void alloc(size_t nbits) nothrow
    {
        this.nbits = nbits;
        data = cast(typeof(data[0])*)calloc(nwords, data[0].sizeof);
        if (!data)
            onOutOfMemoryError();
    }

    pragma(inline,true)
    wordtype test(size_t i) const nothrow
    in
    {
        assert(i < nbits);
    }
    body
    {
        return core.bitop.bt(data, i);
    }

    pragma(inline,true)
    int set(size_t i) nothrow
    in
    {
        assert(i < nbits);
    }
    body
    {
        return core.bitop.bts(data, i);
    }

    pragma(inline,true)
    int clear(size_t i) nothrow
    in
    {
        assert(i <= nbits);
    }
    body
    {
        return core.bitop.btr(data, i);
    }

    mixin template RangeVars()
    {
        size_t firstWord = (target >> BITS_SHIFT);
        size_t firstOff  = target &  BITS_MASK;
        size_t last      = target + len - 1;
        size_t lastWord  = (last >> BITS_SHIFT);
        size_t lastOff   = last &  BITS_MASK;
    }

    // extract loops to allow inlining the rest
    void clearWords(size_t firstWord, size_t lastWord) nothrow
    {
        for(size_t w = firstWord; w < lastWord; w++)
            data[w] = 0;
    }

    void setWords(size_t firstWord, size_t lastWord) nothrow
    {
        for(size_t w = firstWord; w < lastWord; w++)
            data[w] = ~0;
    }

    void copyWords(size_t firstWord, size_t lastWord, const(wordtype)* source) nothrow
    {
        for(size_t w = firstWord; w < lastWord; w++)
            data[w] = source[w - firstWord];
    }

    void copyWordsShifted(size_t firstWord, size_t cntWords, size_t firstOff, const(wordtype)* source) nothrow
    {
        wordtype mask = ~BITS_0 << firstOff;
        data[firstWord] = (data[firstWord] & ~mask) | (source[0] << firstOff);
        for(size_t w = 1; w < cntWords; w++)
            data[firstWord + w] = (source[w - 1] >> (BITS_PER_WORD - firstOff)) | (source[w] << firstOff);
    }

    // target = the biti to start the copy to
    // destlen = the number of bits to copy from source
    pragma(inline,true)
    void copyRange(size_t target, size_t len, const(wordtype)* source) nothrow
    {
        version(bitwise)
        {
            for (size_t i = 0; i < len; i++)
                if(source[(i >> BITS_SHIFT)] & (BITS_1 << (i & BITS_MASK)))
                    set(target+i);
                else
                    clear(target+i);
        }
        else
        {
            if(len > 0)
                copyRangeZ(target, len, source);
        }
    }

    pragma(inline,true)
    void copyRangeZ(size_t target, size_t len, const(wordtype)* source) nothrow
    {
        mixin RangeVars!();

        if(firstWord == lastWord)
        {
            wordtype mask = ((BITS_2 << (lastOff - firstOff)) - 1) << firstOff;
            data[firstWord] = (data[firstWord] & ~mask) | ((source[0] << firstOff) & mask);
        }
        else if(firstOff == 0)
        {
            copyWords(firstWord, lastWord, source);

            wordtype mask = (BITS_2 << lastOff) - 1;
            data[lastWord] = (data[lastWord] & ~mask) | (source[lastWord - firstWord] & mask);
        }
        else
        {
            size_t cntWords = lastWord - firstWord;
            copyWordsShifted(firstWord, cntWords, firstOff, source);

            wordtype src = (source[cntWords - 1] >> (BITS_PER_WORD - firstOff)) | (source[cntWords] << firstOff);
            wordtype mask = (BITS_2 << lastOff) - 1;
            data[lastWord] = (data[lastWord] & ~mask) | (src & mask);
        }
    }

    void copyRangeRepeating(size_t target, size_t destlen, const(wordtype)* source, size_t sourcelen) nothrow
    {
        version(bitwise)
        {
            for (size_t i=0; i < destlen; i++)
            {
                bool b;
                size_t j = i % sourcelen;
                b = (source[j >> BITS_SHIFT] & (BITS_1 << (j & BITS_MASK))) != 0;
                if (b) set(target+i);
                else clear(target+i);
            }
        }
        else
        {
            if (destlen > 4 * sourcelen && destlen > 4 * BITS_PER_WORD)
            {
                // precalculate the number of words where a bit pattern of the
                //  source length repeats on word alignment
                static ubyte lcm(ubyte i)
                {
                    // calc lcm(i,BITS_PER_WORD)/BITS_PER_WORD
                    // by just stripping all factors 2 from i
                    if ((i & (i - 1)) == 0)
                        return 1;
                    while((i & 1) == 0)
                        i >>= 1;
                    return i;
                }
                static calcRepLength()
                {
                    ubyte[BITS_PER_WORD] rep;
                    for (ubyte i = 0; i < BITS_PER_WORD; i++)
                        rep[i] = lcm(i);
                    return rep;
                }
                static immutable repLength = calcRepLength();

                // make some initial copies until we have a pattern that
                //  repeats on word boundary
                size_t rep = repLength[sourcelen & BITS_MASK];
                size_t repwords = ((sourcelen >> BITS_SHIFT) + 1) * rep;
                size_t alignbits = (target & BITS_MASK ? BITS_PER_WORD - (target & BITS_MASK) : 0);
                size_t initbits = BITS_PER_WORD * repwords + alignbits;

                if (initbits < destlen)
                {
                    while (initbits > sourcelen)
                    {
                        copyRange(target, sourcelen, source);
                        target += sourcelen;
                        destlen -= sourcelen;
                        initbits -= sourcelen;
                    }
                    copyRange(target, initbits, source);
                    target += initbits;
                    destlen -= initbits;
                    assert((target & BITS_MASK) == 0);

                    size_t tpos = target >> BITS_SHIFT;
                    while (destlen >= BITS_PER_WORD)
                    {
                        data[tpos] = data[tpos - repwords];
                        destlen -= BITS_PER_WORD;
                        tpos++;
                    }

                    if (destlen > 0)
                    {
                        wordtype mask = (BITS_1 << destlen) - 1;
                        data[tpos] = (data[tpos] & ~mask) | (data[tpos - repwords] & mask);
                    }
                    return;
                }
            }

            while (destlen > sourcelen)
            {
                copyRange(target, sourcelen, source);
                target += sourcelen;
                destlen -= sourcelen;
            }
            copyRange(target, destlen, source);
        }
    }

    pragma(inline,true)
    void setRange(size_t target, size_t len) nothrow
    {
        version(bitwise)
        {
            for (size_t i = 0; i < len; i++)
                set(target+i);
        }
        else
        {
            if(len > 0)
                setRangeZ(target, len);
        }
    }

    pragma(inline,true)
    void setRangeZ(size_t target, size_t len) nothrow
    {
        mixin RangeVars!();

        if(firstWord == lastWord)
        {
            wordtype mask = ((BITS_2 << (lastOff - firstOff)) - 1) << firstOff;
            data[firstWord] |= mask;
        }
        else
        {
            data[firstWord] |= ~BITS_0 << firstOff;
            setWords(firstWord + 1, lastWord);
            wordtype mask = (BITS_2 << lastOff) - 1;
            data[lastWord] |= mask;
        }
    }

    pragma(inline,true)
    void clrRange(size_t target, size_t len) nothrow
    {
        version(bitwise)
        {
            for (size_t i = 0; i < len; i++)
                clear(target+i);
        }
        else
        {
            if(len > 0)
                clrRangeZ(target, len);
        }
    }

    pragma(inline,true)
    void clrRangeZ(size_t target, size_t len) nothrow
    {
        mixin RangeVars!();
        if(firstWord == lastWord)
        {
            wordtype mask = ((BITS_2 << (lastOff - firstOff)) - 1) << firstOff;
            data[firstWord] &= ~mask;
        }
        else
        {
            data[firstWord] &= ~(~BITS_0 << firstOff);
            clearWords(firstWord + 1, lastWord);
            wordtype mask = (BITS_2 << lastOff) - 1;
            data[lastWord] &= ~mask;
        }
    }

    unittest
    {
        GCBits bits;
        bits.alloc(1000);
        auto data = bits.data;

        bits.setRange(0,1);
        assert(data[0] == 1);

        bits.clrRange(0,1);
        assert(data[0] == 0);

        bits.setRange(BITS_PER_WORD-1,1);
        assert(data[0] == BITS_1 << (BITS_PER_WORD-1));

        bits.clrRange(BITS_PER_WORD-1,1);
        assert(data[0] == 0);

        bits.setRange(12,7);
        assert(data[0] == 0b0111_1111_0000_0000_0000);

        bits.clrRange(14,4);
        assert(data[0] == 0b0100_0011_0000_0000_0000);

        bits.clrRange(0,BITS_PER_WORD);
        assert(data[0] == 0);

        bits.setRange(0,BITS_PER_WORD);
        assert(data[0] == ~0);
        assert(data[1] == 0);

        bits.setRange(BITS_PER_WORD,BITS_PER_WORD);
        assert(data[0] == ~0);
        assert(data[1] == ~0);
        assert(data[2] == 0);
        bits.clrRange(BITS_PER_WORD/2,BITS_PER_WORD);
        assert(data[0] == (BITS_1 << (BITS_PER_WORD/2)) - 1);
        assert(data[1] == ~data[0]);
        assert(data[2] == 0);

        bits.setRange(8*BITS_PER_WORD+1,4*BITS_PER_WORD-2);
        assert(data[8] == ~0 << 1);
        assert(data[9] == ~0);
        assert(data[10] == ~0);
        assert(data[11] == cast(wordtype)~0 >> 1);

        bits.clrRange(9*BITS_PER_WORD+1,2*BITS_PER_WORD);
        assert(data[8] == ~0 << 1);
        assert(data[9] == 1);
        assert(data[10] == 0);
        assert(data[11] == ((cast(wordtype)~0 >> 1) & ~1));

        wordtype[4] src = [ 0xa, 0x5, 0xaa, 0x55 ];

        void testCopyRange(size_t start, size_t len, int repeat = 1)
        {
            bits.setRange(0, bits.nbits);
            if (repeat > 1)
                bits.copyRangeRepeating(start, repeat * len, src.ptr, len);
            else
                bits.copyRange(start, len, src.ptr);
            foreach (i; 0 .. start)
                assert(bits.test(i));
            foreach (r; 0 .. repeat)
                foreach (i; 0 .. len)
                    assert(!bits.test(start + r*len + i) == !core.bitop.bt(src.ptr, i));
            foreach (i; start + repeat*len .. 10*BITS_PER_WORD)
                assert(bits.test(i));
        }

        testCopyRange(20, 10); // short copy range within same word
        testCopyRange(50, 20); // short copy range spanning two words
        testCopyRange(64, 3 * BITS_PER_WORD + 3); // aligned copy range
        testCopyRange(77, 2 * BITS_PER_WORD + 15); // unaligned copy range
        testCopyRange(64, 127); // copy range within critical end alignment

        testCopyRange(10, 4, 5); // repeating small range within same word
        testCopyRange(20, 5, 10); // repeating small range spanning two words
        testCopyRange(40, 21, 7); // repeating medium range
        testCopyRange(73, 2 * BITS_PER_WORD + 15, 5); // repeating multi-word range

        testCopyRange(2, 3, 166); // failed with assert
    }

    void zero() nothrow
    {
        memset(data, 0, nwords * wordtype.sizeof);
    }

    void copy(GCBits *f) nothrow
    in
    {
        assert(nwords == f.nwords);
    }
    body
    {
        memcpy(data, f.data, nwords * wordtype.sizeof);
    }

    @property size_t nwords() const pure nothrow
    {
        return (nbits + (BITS_PER_WORD - 1)) >> BITS_SHIFT;
    }
}

unittest
{
    GCBits b;

    b.alloc(786);
    assert(!b.test(123));
    assert(!b.clear(123));
    assert(!b.set(123));
    assert(b.test(123));
    assert(b.clear(123));
    assert(!b.test(123));

    b.set(785);
    b.set(0);
    assert(b.test(785));
    assert(b.test(0));
    b.zero();
    assert(!b.test(785));
    assert(!b.test(0));

    GCBits b2;
    b2.alloc(786);
    b2.set(38);
    b.copy(&b2);
    assert(b.test(38));
    b2.Dtor();
    b.Dtor();
}
