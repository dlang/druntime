/**
 * D header file for C99.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/stdc/_tgmath.d)
 * Standards: ISO/IEC 9899:1999 (E)
 */

module core.stdc.tgmath;

private import core.stdc.config;
private static import core.stdc.math;
private static import core.stdc.complex;

extern (C):
@trusted: // Everything here operates on floating point and integer values.
nothrow:
@nogc:

version( FreeBSD )
{
    alias acos = core.stdc.math.acos;
    alias acos = core.stdc.math.acosf;
    alias acos = core.stdc.math.acosl;

    alias acos = core.stdc.complex.cacos;
    alias acos = core.stdc.complex.cacosf;
    alias acos = core.stdc.complex.cacosl;

    alias asin = core.stdc.math.asin;
    alias asin = core.stdc.math.asinf;
    alias asin = core.stdc.math.asinl;

    alias asin = core.stdc.complex.casin;
    alias asin = core.stdc.complex.casinf;
    alias asin = core.stdc.complex.casinl;

    alias atan = core.stdc.math.atan;
    alias atan = core.stdc.math.atanf;
    alias atan = core.stdc.math.atanl;

    alias atan = core.stdc.complex.catan;
    alias atan = core.stdc.complex.catanf;
    alias atan = core.stdc.complex.catanl;

    alias atan2 = core.stdc.math.atan2;
    alias atan2 = core.stdc.math.atan2f;
    alias atan2 = core.stdc.math.atan2l;

    alias cos = core.stdc.math.cos;
    alias cos = core.stdc.math.cosf;
    alias cos = core.stdc.math.cosl;

    alias cos = core.stdc.complex.ccos;
    alias cos = core.stdc.complex.ccosf;
    alias cos = core.stdc.complex.ccosl;

    alias sin = core.stdc.math.sin;
    alias sin = core.stdc.math.sinf;
    alias sin = core.stdc.math.sinl;

    alias csin = core.stdc.complex.csin;
    alias csin = core.stdc.complex.csinf;
    alias csin = core.stdc.complex.csinl;

    alias tan = core.stdc.math.tan;
    alias tan = core.stdc.math.tanf;
    alias tan = core.stdc.math.tanl;

    alias tan = core.stdc.complex.ctan;
    alias tan = core.stdc.complex.ctanf;
    alias tan = core.stdc.complex.ctanl;

    alias acosh = core.stdc.math.acosh;
    alias acosh = core.stdc.math.acoshf;
    alias acosh = core.stdc.math.acoshl;

    alias acosh = core.stdc.complex.cacosh;
    alias acosh = core.stdc.complex.cacoshf;
    alias acosh = core.stdc.complex.cacoshl;

    alias asinh = core.stdc.math.asinh;
    alias asinh = core.stdc.math.asinhf;
    alias asinh = core.stdc.math.asinhl;

    alias asinh = core.stdc.complex.casinh;
    alias asinh = core.stdc.complex.casinhf;
    alias asinh = core.stdc.complex.casinhl;

    alias atanh = core.stdc.math.atanh;
    alias atanh = core.stdc.math.atanhf;
    alias atanh = core.stdc.math.atanhl;

    alias atanh = core.stdc.complex.catanh;
    alias atanh = core.stdc.complex.catanhf;
    alias atanh = core.stdc.complex.catanhl;

    alias cosh = core.stdc.math.cosh;
    alias cosh = core.stdc.math.coshf;
    alias cosh = core.stdc.math.coshl;

    alias cosh = core.stdc.complex.ccosh;
    alias cosh = core.stdc.complex.ccoshf;
    alias cosh = core.stdc.complex.ccoshl;

    alias sinh = core.stdc.math.sinh;
    alias sinh = core.stdc.math.sinhf;
    alias sinh = core.stdc.math.sinhl;

    alias sinh = core.stdc.complex.csinh;
    alias sinh = core.stdc.complex.csinhf;
    alias sinh = core.stdc.complex.csinhl;

    alias tanh = core.stdc.math.tanh;
    alias tanh = core.stdc.math.tanhf;
    alias tanh = core.stdc.math.tanhl;

    alias tanh = core.stdc.complex.ctanh;
    alias tanh = core.stdc.complex.ctanhf;
    alias tanh = core.stdc.complex.ctanhl;

    alias exp = core.stdc.math.exp;
    alias exp = core.stdc.math.expf;
    alias exp = core.stdc.math.expl;

    alias exp = core.stdc.complex.cexp;
    alias exp = core.stdc.complex.cexpf;
    alias exp = core.stdc.complex.cexpl;

    alias exp2 = core.stdc.math.exp2;
    alias exp2 = core.stdc.math.exp2f;
    alias exp2 = core.stdc.math.exp2l;

    alias expm1 = core.stdc.math.expm1;
    alias expm1 = core.stdc.math.expm1f;
    alias expm1 = core.stdc.math.expm1l;

    alias frexp = core.stdc.math.frexp;
    alias frexp = core.stdc.math.frexpf;
    alias frexp = core.stdc.math.frexpl;

    alias ilogb = core.stdc.math.ilogb;
    alias ilogb = core.stdc.math.ilogbf;
    alias ilogb = core.stdc.math.ilogbl;

    alias ldexp = core.stdc.math.ldexp;
    alias ldexp = core.stdc.math.ldexpf;
    alias ldexp = core.stdc.math.ldexpl;

    alias log = core.stdc.math.log;
    alias log = core.stdc.math.logf;
    alias log = core.stdc.math.logl;

    alias log = core.stdc.complex.clog;
    alias log = core.stdc.complex.clogf;
    alias log = core.stdc.complex.clogl;

    alias log10 = core.stdc.math.log10;
    alias log10 = core.stdc.math.log10f;
    alias log10 = core.stdc.math.log10l;

    alias log1p = core.stdc.math.log1p;
    alias log1p = core.stdc.math.log1pf;
    alias log1p = core.stdc.math.log1pl;

    alias log2 = core.stdc.math.log2;
    alias log2 = core.stdc.math.log2f;
    alias log2 = core.stdc.math.log2l;

    alias logb = core.stdc.math.logb;
    alias logb = core.stdc.math.logbf;
    alias logb = core.stdc.math.logbl;

    alias modf = core.stdc.math.modf;
    alias modf = core.stdc.math.modff;
//  alias core.stdc.math.modfl         modf;

    alias scalbn = core.stdc.math.scalbn;
    alias scalbn = core.stdc.math.scalbnf;
    alias scalbn = core.stdc.math.scalbnl;

    alias scalbln = core.stdc.math.scalbln;
    alias scalbln = core.stdc.math.scalblnf;
    alias scalbln = core.stdc.math.scalblnl;

    alias cbrt = core.stdc.math.cbrt;
    alias cbrt = core.stdc.math.cbrtf;
    alias cbrt = core.stdc.math.cbrtl;

    alias fabs = core.stdc.math.fabs;
    alias fabs = core.stdc.math.fabsf;
    alias fabs = core.stdc.math.fabsl;

    alias fabs = core.stdc.complex.cabs;
    alias fabs = core.stdc.complex.cabsf;
    alias fabs = core.stdc.complex.cabsl;

    alias hypot = core.stdc.math.hypot;
    alias hypot = core.stdc.math.hypotf;
    alias hypot = core.stdc.math.hypotl;

    alias pow = core.stdc.math.pow;
    alias pow = core.stdc.math.powf;
    alias pow = core.stdc.math.powl;

    alias pow = core.stdc.complex.cpow;
    alias pow = core.stdc.complex.cpowf;
    alias pow = core.stdc.complex.cpowl;

    alias sqrt = core.stdc.math.sqrt;
    alias sqrt = core.stdc.math.sqrtf;
    alias sqrt = core.stdc.math.sqrtl;

    alias sqrt = core.stdc.complex.csqrt;
    alias sqrt = core.stdc.complex.csqrtf;
    alias sqrt = core.stdc.complex.csqrtl;

    alias erf = core.stdc.math.erf;
    alias erf = core.stdc.math.erff;
    alias erf = core.stdc.math.erfl;

    alias erfc = core.stdc.math.erfc;
    alias erfc = core.stdc.math.erfcf;
    alias erfc = core.stdc.math.erfcl;

    alias lgamma = core.stdc.math.lgamma;
    alias lgamma = core.stdc.math.lgammaf;
    alias lgamma = core.stdc.math.lgammal;

    alias tgamma = core.stdc.math.tgamma;
    alias tgamma = core.stdc.math.tgammaf;
    alias tgamma = core.stdc.math.tgammal;

    alias ceil = core.stdc.math.ceil;
    alias ceil = core.stdc.math.ceilf;
    alias ceil = core.stdc.math.ceill;

    alias floor = core.stdc.math.floor;
    alias floor = core.stdc.math.floorf;
    alias floor = core.stdc.math.floorl;

    alias nearbyint = core.stdc.math.nearbyint;
    alias nearbyint = core.stdc.math.nearbyintf;
    alias nearbyint = core.stdc.math.nearbyintl;

    alias rint = core.stdc.math.rint;
    alias rint = core.stdc.math.rintf;
    alias rint = core.stdc.math.rintl;

    alias lrint = core.stdc.math.lrint;
    alias lrint = core.stdc.math.lrintf;
    alias lrint = core.stdc.math.lrintl;

    alias llrint = core.stdc.math.llrint;
    alias llrint = core.stdc.math.llrintf;
    alias llrint = core.stdc.math.llrintl;

    alias round = core.stdc.math.round;
    alias round = core.stdc.math.roundf;
    alias round = core.stdc.math.roundl;

    alias lround = core.stdc.math.lround;
    alias lround = core.stdc.math.lroundf;
    alias lround = core.stdc.math.lroundl;

    alias llround = core.stdc.math.llround;
    alias llround = core.stdc.math.llroundf;
    alias llround = core.stdc.math.llroundl;

    alias trunc = core.stdc.math.trunc;
    alias trunc = core.stdc.math.truncf;
    alias trunc = core.stdc.math.truncl;

    alias fmod = core.stdc.math.fmod;
    alias fmod = core.stdc.math.fmodf;
    alias fmod = core.stdc.math.fmodl;

    alias remainder = core.stdc.math.remainder;
    alias remainder = core.stdc.math.remainderf;
    alias remainder = core.stdc.math.remainderl;

    alias remquo = core.stdc.math.remquo;
    alias remquo = core.stdc.math.remquof;
    alias remquo = core.stdc.math.remquol;

    alias copysign = core.stdc.math.copysign;
    alias copysign = core.stdc.math.copysignf;
    alias copysign = core.stdc.math.copysignl;

//  alias core.stdc.math.nan           nan;
//  alias core.stdc.math.nanf          nan;
//  alias core.stdc.math.nanl          nan;

    alias nextafter = core.stdc.math.nextafter;
    alias nextafter = core.stdc.math.nextafterf;
    alias nextafter = core.stdc.math.nextafterl;

    alias nexttoward = core.stdc.math.nexttoward;
    alias nexttoward = core.stdc.math.nexttowardf;
    alias nexttoward = core.stdc.math.nexttowardl;

    alias fdim = core.stdc.math.fdim;
    alias fdim = core.stdc.math.fdimf;
    alias fdim = core.stdc.math.fdiml;

    alias fmax = core.stdc.math.fmax;
    alias fmax = core.stdc.math.fmaxf;
    alias fmax = core.stdc.math.fmaxl;

    alias fmin = core.stdc.math.fmin;
    alias fmin = core.stdc.math.fmin;
    alias fmin = core.stdc.math.fminl;

    alias fma = core.stdc.math.fma;
    alias fma = core.stdc.math.fmaf;
    alias fma = core.stdc.math.fmal;

    alias carg = core.stdc.complex.carg;
    alias carg = core.stdc.complex.cargf;
    alias carg = core.stdc.complex.cargl;

    alias cimag = core.stdc.complex.cimag;
    alias cimag = core.stdc.complex.cimagf;
    alias cimag = core.stdc.complex.cimagl;

    alias conj = core.stdc.complex.conj;
    alias conj = core.stdc.complex.conjf;
    alias conj = core.stdc.complex.conjl;

    alias cproj = core.stdc.complex.cproj;
    alias cproj = core.stdc.complex.cprojf;
    alias cproj = core.stdc.complex.cprojl;

//  alias core.stdc.complex.creal      creal;
//  alias core.stdc.complex.crealf     creal;
//  alias core.stdc.complex.creall     creal;
}
else
{
    alias acos = core.stdc.math.acos;
    alias acos = core.stdc.math.acosf;
    alias acos = core.stdc.math.acosl;

    alias acos = core.stdc.complex.cacos;
    alias acos = core.stdc.complex.cacosf;
    alias acos = core.stdc.complex.cacosl;

    alias asin = core.stdc.math.asin;
    alias asin = core.stdc.math.asinf;
    alias asin = core.stdc.math.asinl;

    alias asin = core.stdc.complex.casin;
    alias asin = core.stdc.complex.casinf;
    alias asin = core.stdc.complex.casinl;

    alias atan = core.stdc.math.atan;
    alias atan = core.stdc.math.atanf;
    alias atan = core.stdc.math.atanl;

    alias atan = core.stdc.complex.catan;
    alias atan = core.stdc.complex.catanf;
    alias atan = core.stdc.complex.catanl;

    alias atan2 = core.stdc.math.atan2;
    alias atan2 = core.stdc.math.atan2f;
    alias atan2 = core.stdc.math.atan2l;

    alias cos = core.stdc.math.cos;
    alias cos = core.stdc.math.cosf;
    alias cos = core.stdc.math.cosl;

    alias cos = core.stdc.complex.ccos;
    alias cos = core.stdc.complex.ccosf;
    alias cos = core.stdc.complex.ccosl;

    alias sin = core.stdc.math.sin;
    alias sin = core.stdc.math.sinf;
    alias sin = core.stdc.math.sinl;

    alias csin = core.stdc.complex.csin;
    alias csin = core.stdc.complex.csinf;
    alias csin = core.stdc.complex.csinl;

    alias tan = core.stdc.math.tan;
    alias tan = core.stdc.math.tanf;
    alias tan = core.stdc.math.tanl;

    alias tan = core.stdc.complex.ctan;
    alias tan = core.stdc.complex.ctanf;
    alias tan = core.stdc.complex.ctanl;

    alias acosh = core.stdc.math.acosh;
    alias acosh = core.stdc.math.acoshf;
    alias acosh = core.stdc.math.acoshl;

    alias acosh = core.stdc.complex.cacosh;
    alias acosh = core.stdc.complex.cacoshf;
    alias acosh = core.stdc.complex.cacoshl;

    alias asinh = core.stdc.math.asinh;
    alias asinh = core.stdc.math.asinhf;
    alias asinh = core.stdc.math.asinhl;

    alias asinh = core.stdc.complex.casinh;
    alias asinh = core.stdc.complex.casinhf;
    alias asinh = core.stdc.complex.casinhl;

    alias atanh = core.stdc.math.atanh;
    alias atanh = core.stdc.math.atanhf;
    alias atanh = core.stdc.math.atanhl;

    alias atanh = core.stdc.complex.catanh;
    alias atanh = core.stdc.complex.catanhf;
    alias atanh = core.stdc.complex.catanhl;

    alias cosh = core.stdc.math.cosh;
    alias cosh = core.stdc.math.coshf;
    alias cosh = core.stdc.math.coshl;

    alias cosh = core.stdc.complex.ccosh;
    alias cosh = core.stdc.complex.ccoshf;
    alias cosh = core.stdc.complex.ccoshl;

    alias sinh = core.stdc.math.sinh;
    alias sinh = core.stdc.math.sinhf;
    alias sinh = core.stdc.math.sinhl;

    alias sinh = core.stdc.complex.csinh;
    alias sinh = core.stdc.complex.csinhf;
    alias sinh = core.stdc.complex.csinhl;

    alias tanh = core.stdc.math.tanh;
    alias tanh = core.stdc.math.tanhf;
    alias tanh = core.stdc.math.tanhl;

    alias tanh = core.stdc.complex.ctanh;
    alias tanh = core.stdc.complex.ctanhf;
    alias tanh = core.stdc.complex.ctanhl;

    alias exp = core.stdc.math.exp;
    alias exp = core.stdc.math.expf;
    alias exp = core.stdc.math.expl;

    alias exp = core.stdc.complex.cexp;
    alias exp = core.stdc.complex.cexpf;
    alias exp = core.stdc.complex.cexpl;

    alias exp2 = core.stdc.math.exp2;
    alias exp2 = core.stdc.math.exp2f;
    alias exp2 = core.stdc.math.exp2l;

    alias expm1 = core.stdc.math.expm1;
    alias expm1 = core.stdc.math.expm1f;
    alias expm1 = core.stdc.math.expm1l;

    alias frexp = core.stdc.math.frexp;
    alias frexp = core.stdc.math.frexpf;
    alias frexp = core.stdc.math.frexpl;

    alias ilogb = core.stdc.math.ilogb;
    alias ilogb = core.stdc.math.ilogbf;
    alias ilogb = core.stdc.math.ilogbl;

    alias ldexp = core.stdc.math.ldexp;
    alias ldexp = core.stdc.math.ldexpf;
    alias ldexp = core.stdc.math.ldexpl;

    alias log = core.stdc.math.log;
    alias log = core.stdc.math.logf;
    alias log = core.stdc.math.logl;

    alias log = core.stdc.complex.clog;
    alias log = core.stdc.complex.clogf;
    alias log = core.stdc.complex.clogl;

    alias log10 = core.stdc.math.log10;
    alias log10 = core.stdc.math.log10f;
    alias log10 = core.stdc.math.log10l;

    alias log1p = core.stdc.math.log1p;
    alias log1p = core.stdc.math.log1pf;
    alias log1p = core.stdc.math.log1pl;

    alias log2 = core.stdc.math.log2;
    alias log2 = core.stdc.math.log2f;
    alias log2 = core.stdc.math.log2l;

    alias logb = core.stdc.math.logb;
    alias logb = core.stdc.math.logbf;
    alias logb = core.stdc.math.logbl;

    alias modf = core.stdc.math.modf;
    alias modf = core.stdc.math.modff;
    alias modf = core.stdc.math.modfl;

    alias scalbn = core.stdc.math.scalbn;
    alias scalbn = core.stdc.math.scalbnf;
    alias scalbn = core.stdc.math.scalbnl;

    alias scalbln = core.stdc.math.scalbln;
    alias scalbln = core.stdc.math.scalblnf;
    alias scalbln = core.stdc.math.scalblnl;

    alias cbrt = core.stdc.math.cbrt;
    alias cbrt = core.stdc.math.cbrtf;
    alias cbrt = core.stdc.math.cbrtl;

    alias fabs = core.stdc.math.fabs;
    alias fabs = core.stdc.math.fabsf;
    alias fabs = core.stdc.math.fabsl;

    alias fabs = core.stdc.complex.cabs;
    alias fabs = core.stdc.complex.cabsf;
    alias fabs = core.stdc.complex.cabsl;

    alias hypot = core.stdc.math.hypot;
    alias hypot = core.stdc.math.hypotf;
    alias hypot = core.stdc.math.hypotl;

    alias pow = core.stdc.math.pow;
    alias pow = core.stdc.math.powf;
    alias pow = core.stdc.math.powl;

    alias pow = core.stdc.complex.cpow;
    alias pow = core.stdc.complex.cpowf;
    alias pow = core.stdc.complex.cpowl;

    alias sqrt = core.stdc.math.sqrt;
    alias sqrt = core.stdc.math.sqrtf;
    alias sqrt = core.stdc.math.sqrtl;

    alias sqrt = core.stdc.complex.csqrt;
    alias sqrt = core.stdc.complex.csqrtf;
    alias sqrt = core.stdc.complex.csqrtl;

    alias erf = core.stdc.math.erf;
    alias erf = core.stdc.math.erff;
    alias erf = core.stdc.math.erfl;

    alias erfc = core.stdc.math.erfc;
    alias erfc = core.stdc.math.erfcf;
    alias erfc = core.stdc.math.erfcl;

    alias lgamma = core.stdc.math.lgamma;
    alias lgamma = core.stdc.math.lgammaf;
    alias lgamma = core.stdc.math.lgammal;

    alias tgamma = core.stdc.math.tgamma;
    alias tgamma = core.stdc.math.tgammaf;
    alias tgamma = core.stdc.math.tgammal;

    alias ceil = core.stdc.math.ceil;
    alias ceil = core.stdc.math.ceilf;
    alias ceil = core.stdc.math.ceill;

    alias floor = core.stdc.math.floor;
    alias floor = core.stdc.math.floorf;
    alias floor = core.stdc.math.floorl;

    alias nearbyint = core.stdc.math.nearbyint;
    alias nearbyint = core.stdc.math.nearbyintf;
    alias nearbyint = core.stdc.math.nearbyintl;

    alias rint = core.stdc.math.rint;
    alias rint = core.stdc.math.rintf;
    alias rint = core.stdc.math.rintl;

    alias lrint = core.stdc.math.lrint;
    alias lrint = core.stdc.math.lrintf;
    alias lrint = core.stdc.math.lrintl;

    alias llrint = core.stdc.math.llrint;
    alias llrint = core.stdc.math.llrintf;
    alias llrint = core.stdc.math.llrintl;

    alias round = core.stdc.math.round;
    alias round = core.stdc.math.roundf;
    alias round = core.stdc.math.roundl;

    alias lround = core.stdc.math.lround;
    alias lround = core.stdc.math.lroundf;
    alias lround = core.stdc.math.lroundl;

    alias llround = core.stdc.math.llround;
    alias llround = core.stdc.math.llroundf;
    alias llround = core.stdc.math.llroundl;

    alias trunc = core.stdc.math.trunc;
    alias trunc = core.stdc.math.truncf;
    alias trunc = core.stdc.math.truncl;

    alias fmod = core.stdc.math.fmod;
    alias fmod = core.stdc.math.fmodf;
    alias fmod = core.stdc.math.fmodl;

    alias remainder = core.stdc.math.remainder;
    alias remainder = core.stdc.math.remainderf;
    alias remainder = core.stdc.math.remainderl;

    alias remquo = core.stdc.math.remquo;
    alias remquo = core.stdc.math.remquof;
    alias remquo = core.stdc.math.remquol;

    alias copysign = core.stdc.math.copysign;
    alias copysign = core.stdc.math.copysignf;
    alias copysign = core.stdc.math.copysignl;

    alias nan = core.stdc.math.nan;
    alias nan = core.stdc.math.nanf;
    alias nan = core.stdc.math.nanl;

    alias nextafter = core.stdc.math.nextafter;
    alias nextafter = core.stdc.math.nextafterf;
    alias nextafter = core.stdc.math.nextafterl;

    alias nexttoward = core.stdc.math.nexttoward;
    alias nexttoward = core.stdc.math.nexttowardf;
    alias nexttoward = core.stdc.math.nexttowardl;

    alias fdim = core.stdc.math.fdim;
    alias fdim = core.stdc.math.fdimf;
    alias fdim = core.stdc.math.fdiml;

    alias fmax = core.stdc.math.fmax;
    alias fmax = core.stdc.math.fmaxf;
    alias fmax = core.stdc.math.fmaxl;

    alias fmin = core.stdc.math.fmin;
    alias fmin = core.stdc.math.fmin;
    alias fmin = core.stdc.math.fminl;

    alias fma = core.stdc.math.fma;
    alias fma = core.stdc.math.fmaf;
    alias fma = core.stdc.math.fmal;

    alias carg = core.stdc.complex.carg;
    alias carg = core.stdc.complex.cargf;
    alias carg = core.stdc.complex.cargl;

    alias cimag = core.stdc.complex.cimag;
    alias cimag = core.stdc.complex.cimagf;
    alias cimag = core.stdc.complex.cimagl;

    alias conj = core.stdc.complex.conj;
    alias conj = core.stdc.complex.conjf;
    alias conj = core.stdc.complex.conjl;

    alias cproj = core.stdc.complex.cproj;
    alias cproj = core.stdc.complex.cprojf;
    alias cproj = core.stdc.complex.cprojl;

//  alias core.stdc.complex.creal      creal;
//  alias core.stdc.complex.crealf     creal;
//  alias core.stdc.complex.creall     creal;
}
