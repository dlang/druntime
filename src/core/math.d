// Written in the D programming language.

/**
 * Builtin mathematical intrinsics
 *
 * Source: $(DRUNTIMESRC core/_math.d)
 * Macros:
 *      TABLE_SV = <table border="1" cellpadding="4" cellspacing="0">
 *              <caption>Special Values</caption>
 *              $0</table>
 *
 *      NAN = $(RED NAN)
 *      SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *      POWER = $1<sup>$2</sup>
 *      PLUSMN = &plusmn;
 *      INFIN = &infin;
 *      PLUSMNINF = &plusmn;&infin;
 *      LT = &lt;
 *      GT = &gt;
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(WEB digitalmars.com, Walter Bright),
 *                        Don Clugston
 */
module core.math;

import core.stdc.stdint;

public:
@nogc:

/***********************************
 * Returns cosine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cos(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN)) $(TD yes)     )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN)) $(TD yes)     )
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

real cos(real x) @safe pure nothrow;       /* intrinsic */

/***********************************
 * Returns sine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)               $(TH sin(x))      $(TH invalid?))
 *      $(TR $(TD $(NAN))          $(TD $(NAN))      $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))    $(TD $(NAN))      $(TD yes))
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

real sin(real x) @safe pure nothrow;       /* intrinsic */

/*****************************************
 * Returns x rounded to a long value using the current rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */
long rndtol(real x) @safe pure nothrow;    /* intrinsic */


/*****************************************
 * Returns x rounded to a long value using the FE_TONEAREST rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */
extern (C) real rndtonl(real x);

/***************************************
 * Compute square root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH sqrt(x))   $(TH invalid?))
 *      $(TR $(TD -0.0)      $(TD -0.0)      $(TD no))
 *      $(TR $(TD $(LT)0.0)  $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */

@safe pure nothrow
{
    float sqrt(float x);    /* intrinsic */
    double sqrt(double x);  /* intrinsic */ /// ditto
    real sqrt(real x);      /* intrinsic */ /// ditto
}

/*******************************************
 * Compute n * 2$(SUPERSCRIPT exp)
 * References: frexp
 */

real ldexp(real n, int exp) @safe pure nothrow;    /* intrinsic */

unittest {
    static if (real.mant_dig == 113)
    {
        assert(ldexp(1, -16384) == 0x1p-16384L);
        assert(ldexp(1, -16382) == 0x1p-16382L);
    }
    else static if (real.mant_dig == 106)
    {
        assert(ldexp(1,  1023) == 0x1p1023L);
        assert(ldexp(1, -1022) == 0x1p-1022L);
        assert(ldexp(1, -1021) == 0x1p-1021L);
    }
    else static if (real.mant_dig == 64)
    {
        assert(ldexp(1, -16384) == 0x1p-16384L);
        assert(ldexp(1, -16382) == 0x1p-16382L);
    }
    else static if (real.mant_dig == 53)
    {
        assert(ldexp(1,  1023) == 0x1p1023L);
        assert(ldexp(1, -1022) == 0x1p-1022L);
        assert(ldexp(1, -1021) == 0x1p-1021L);
    }
    else
        assert(false, "Only 128bit, 80bit and 64bit reals expected here");
}

/*******************************
 * Returns |x|
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH fabs(x)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) )
 *      )
 */
real fabs(real x) @safe pure nothrow;      /* intrinsic */

/**********************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 * If the return value is not equal to x, the FE_INEXACT
 * exception is raised.
 * $(B nearbyint) performs
 * the same operation, but does not set the FE_INEXACT exception.
 */
real rint(real x) @safe pure nothrow;      /* intrinsic */

/***********************************
 * Building block functions, they
 * translate to a single x87 instruction.
 */

real yl2x(real x, real y)   @safe pure nothrow;       // y * log2(x)
real yl2xp1(real x, real y) @safe pure nothrow;       // y * log2(x + 1)

unittest
{
    version (INLINE_YL2X)
    {
        assert(yl2x(1024, 1) == 10);
        assert(yl2xp1(1023, 1) == 10);
    }
}

/**
Computes the product of two unsigned 64 bit numbers.
The result is stored into two 64 bit values which represent the lower and upper part.

Params:
    a, b = the number to be multiplied
    lo   = the lower 64 bits of the result
    hi   = the upper 64 bits of the result
*/
void mul128(in uint64_t a, in uint64_t b, out uint64_t lo, out uint64_t hi) @safe @nogc pure nothrow
{
    immutable uint64_t lowMask = 0xFFFFFFFF;
    uint64_t aLo = a & lowMask;
    uint64_t bLo = b & lowMask;
    uint64_t bHi = b >> 32;
    uint64_t aHi = a >> 32;

    uint64_t abLo = aLo * bLo;
    uint64_t abHi = aHi * bHi;
    uint64_t abMid1 = aLo * bHi;
    uint64_t abMid2 = aHi * bLo;

    uint64_t tmp = (abMid1 & lowMask) + (abMid2 & lowMask) + (abLo >> 32);
    lo = (tmp << 32) + (abLo & lowMask);
    uint64_t carry = tmp >> 32;

    hi = abHi + (abMid1 >> 32) + (abMid2 >> 32) + carry;
}

///
@safe @nogc pure nothrow unittest
{
    uint64_t lo, hi;
    mul128(0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, lo, hi);
    assert(hi == 0xFFFFFFFFFFFFFFFE);
    assert(lo == 1);

    mul128(0x1234567890123456, 0x9876543210987654, lo, hi);
    assert(hi == 0x0AD77D742CE3C72E);
    assert(lo == 0x45FD10D81D28D038);

    mul128(0, 0x9876543210987654, lo, hi);
    assert(lo == 0);
    assert(hi == 0);
}
