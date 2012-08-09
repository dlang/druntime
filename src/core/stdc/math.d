/**
 * D header file for C99.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 * Standards: ISO/IEC 9899:1999 (E)
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.stdc.math;

private import core.stdc.config;

extern (C):
@trusted: // All functions here operate on floating point and integer values only.
nothrow:

alias float  float_t;
alias double double_t;

enum double HUGE_VAL      = double.infinity;
enum double HUGE_VALF     = float.infinity;
enum double HUGE_VALL     = real.infinity;

enum float INFINITY       = float.infinity;
enum float NAN            = float.nan;

enum int FP_ILOGB0        = int.min;
enum int FP_ILOGBNAN      = int.min;

enum int MATH_ERRNO       = 1;
enum int MATH_ERREXCEPT   = 2;
enum int math_errhandling = MATH_ERRNO | MATH_ERREXCEPT;

version( none )
{
    //
    // these functions are all macros in C
    //

    //int fpclassify(real-floating x);
    int fpclassify(float x);
    int fpclassify(double x);
    int fpclassify(real x);

    //int isfinite(real-floating x);
    int isfinite(float x);
    int isfinite(double x);
    int isfinite(real x);

    //int isinf(real-floating x);
    int isinf(float x);
    int isinf(double x);
    int isinf(real x);

    //int isnan(real-floating x);
    int isnan(float x);
    int isnan(double x);
    int isnan(real x);

    //int isnormal(real-floating x);
    int isnormal(float x);
    int isnormal(double x);
    int isnormal(real x);

    //int signbit(real-floating x);
    int signbit(float x);
    int signbit(double x);
    int signbit(real x);

    //int isgreater(real-floating x, real-floating y);
    int isgreater(float x, float y);
    int isgreater(double x, double y);
    int isgreater(real x, real y);

    //int isgreaterequal(real-floating x, real-floating y);
    int isgreaterequal(float x, float y);
    int isgreaterequal(double x, double y);
    int isgreaterequal(real x, real y);

    //int isless(real-floating x, real-floating y);
    int isless(float x, float y);
    int isless(double x, double y);
    int isless(real x, real y);

    //int islessequal(real-floating x, real-floating y);
    int islessequal(float x, float y);
    int islessequal(double x, double y);
    int islessequal(real x, real y);

    //int islessgreater(real-floating x, real-floating y);
    int islessgreater(float x, float y);
    int islessgreater(double x, double y);
    int islessgreater(real x, real y);

    //int isunordered(real-floating x, real-floating y);
    int isunordered(float x, float y);
    int isunordered(double x, double y);
    int isunordered(real x, real y);
}

version( DigitalMars ) version( Windows )
    version = DigitalMarsWin32;

version( DigitalMarsWin32 )
{
    enum
    {
        FP_NANS        = 0,
        FP_NANQ        = 1,
        FP_INFINITE    = 2,
        FP_NORMAL      = 3,
        FP_SUBNORMAL   = 4,
        FP_ZERO        = 5,
        FP_NAN         = FP_NANQ,
        FP_EMPTY       = 6,
        FP_UNSUPPORTED = 7,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    uint __fpclassify_f(float x);
    uint __fpclassify_d(double x);
    uint __fpclassify_ld(real x);

  extern (D)
  {
    //int fpclassify(real-floating x);
    int fpclassify(float x)     { return __fpclassify_f(x); }
    int fpclassify(double x)    { return __fpclassify_d(x); }
    int fpclassify(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __fpclassify_d(x)
            : __fpclassify_ld(x);
    }

    //int isfinite(real-floating x);
    int isfinite(float x)       { return fpclassify(x) >= FP_NORMAL; }
    int isfinite(double x)      { return fpclassify(x) >= FP_NORMAL; }
    int isfinite(real x)        { return fpclassify(x) >= FP_NORMAL; }

    //int isinf(real-floating x);
    int isinf(float x)          { return fpclassify(x) == FP_INFINITE; }
    int isinf(double x)         { return fpclassify(x) == FP_INFINITE; }
    int isinf(real x)           { return fpclassify(x) == FP_INFINITE; }

    //int isnan(real-floating x);
    int isnan(float x)          { return fpclassify(x) <= FP_NANQ;   }
    int isnan(double x)         { return fpclassify(x) <= FP_NANQ;   }
    int isnan(real x)           { return fpclassify(x) <= FP_NANQ;   }

    //int isnormal(real-floating x);
    int isnormal(float x)       { return fpclassify(x) == FP_NORMAL; }
    int isnormal(double x)      { return fpclassify(x) == FP_NORMAL; }
    int isnormal(real x)        { return fpclassify(x) == FP_NORMAL; }

    //int signbit(real-floating x);
    int signbit(float x)     { return (cast(short*)&(x))[1] & 0x8000; }
    int signbit(double x)    { return (cast(short*)&(x))[3] & 0x8000; }
    int signbit(real x)
    {
        return (real.sizeof == double.sizeof)
            ? (cast(short*)&(x))[3] & 0x8000
            : (cast(short*)&(x))[4] & 0x8000;
    }
  }
}
else version( linux )
{
    enum
    {
        FP_NAN,
        FP_INFINITE,
        FP_ZERO,
        FP_SUBNORMAL,
        FP_NORMAL,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    int __fpclassifyf(float x);
    int __fpclassify(double x);
    int __fpclassifyl(real x);

    int __finitef(float x);
    int __finite(double x);
    int __finitel(real x);

    int __isinff(float x);
    int __isinf(double x);
    int __isinfl(real x);

    int __isnanf(float x);
    int __isnan(double x);
    int __isnanl(real x);

    int __signbitf(float x);
    int __signbit(double x);
    int __signbitl(real x);

  extern (D)
  {
    //int fpclassify(real-floating x);
    int fpclassify(float x)     { return __fpclassifyf(x); }
    int fpclassify(double x)    { return __fpclassify(x);  }
    int fpclassify(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __fpclassify(x)
            : __fpclassifyl(x);
    }

    //int isfinite(real-floating x);
    int isfinite(float x)       { return __finitef(x); }
    int isfinite(double x)      { return __finite(x);  }
    int isfinite(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __finite(x)
            : __finitel(x);
    }

    //int isinf(real-floating x);
    int isinf(float x)          { return __isinff(x);  }
    int isinf(double x)         { return __isinf(x);   }
    int isinf(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __isinf(x)
            : __isinfl(x);
    }

    //int isnan(real-floating x);
    int isnan(float x)          { return __isnanf(x);  }
    int isnan(double x)         { return __isnan(x);   }
    int isnan(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __isnan(x)
            : __isnanl(x);
    }

    //int isnormal(real-floating x);
    int isnormal(float x)       { return fpclassify(x) == FP_NORMAL; }
    int isnormal(double x)      { return fpclassify(x) == FP_NORMAL; }
    int isnormal(real x)        { return fpclassify(x) == FP_NORMAL; }

    //int signbit(real-floating x);
    int signbit(float x)     { return __signbitf(x); }
    int signbit(double x)    { return __signbit(x);  }
    int signbit(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __signbit(x)
            : __signbitl(x);
    }
  }
}
else version( OSX )
{
    enum
    {
        FP_NAN         = 1,
        FP_INFINITE    = 2,
        FP_ZERO        = 3,
        FP_NORMAL      = 4,
        FP_SUBNORMAL   = 5,
        FP_SUPERNORMAL = 6,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    int __fpclassifyf(float x);
    int __fpclassifyd(double x);
    int __fpclassify(real x);

    int __isfinitef(float x);
    int __isfinited(double x);
    int __isfinite(real x);

    int __isinff(float x);
    int __isinfd(double x);
    int __isinf(real x);

    int __isnanf(float x);
    int __isnand(double x);
    int __isnan(real x);

    int __signbitf(float x);
    int __signbitd(double x);
    int __signbitl(real x);

  extern (D)
  {
    //int fpclassify(real-floating x);
    int fpclassify(float x)     { return __fpclassifyf(x); }
    int fpclassify(double x)    { return __fpclassifyd(x); }
    int fpclassify(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __fpclassifyd(x)
            : __fpclassify(x);
    }

    //int isfinite(real-floating x);
    int isfinite(float x)       { return __isfinitef(x); }
    int isfinite(double x)      { return __isfinited(x); }
    int isfinite(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __isfinited(x)
            : __isfinite(x);
    }

    //int isinf(real-floating x);
    int isinf(float x)          { return __isinff(x); }
    int isinf(double x)         { return __isinfd(x); }
    int isinf(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __isinfd(x)
            : __isinf(x);
    }

    //int isnan(real-floating x);
    int isnan(float x)          { return __isnanf(x); }
    int isnan(double x)         { return __isnand(x); }
    int isnan(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __isnand(x)
            : __isnan(x);
    }

    //int isnormal(real-floating x);
    int isnormal(float x)       { return fpclassify(x) == FP_NORMAL; }
    int isnormal(double x)      { return fpclassify(x) == FP_NORMAL; }
    int isnormal(real x)        { return fpclassify(x) == FP_NORMAL; }

    //int signbit(real-floating x);
    int signbit(float x)     { return __signbitf(x); }
    int signbit(double x)    { return __signbitd(x); }
    int signbit(real x)
    {
        return (real.sizeof == double.sizeof)
            ? __signbitd(x)
            : __signbitl(x);
    }
  }
}
else version( FreeBSD )
{
    enum
    {
        FP_INFINITE  = 0x01,
        FP_NAN       = 0x02,
        FP_NORMAL    = 0x04,
        FP_SUBNORMAL = 0x08,
        FP_ZERO      = 0x10,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    int __fpclassifyd(double);
    int __fpclassifyf(float);
    int __fpclassifyl(real);
    int __isfinitef(float);
    int __isfinite(double);
    int __isfinitel(real);
    int __isinff(float);
    int __isinfl(real);
    int __isnanl(real);
    int __isnormalf(float);
    int __isnormal(double);
    int __isnormall(real);
    int __signbit(double);
    int __signbitf(float);
    int __signbitl(real);

  extern (D)
  {
    //int fpclassify(real-floating x);
    int fpclassify(float x)     { return __fpclassifyf(x); }
    int fpclassify(double x)    { return __fpclassifyd(x); }
    int fpclassify(real x)      { return __fpclassifyl(x); }

    //int isfinite(real-floating x);
    int isfinite(float x)       { return __isfinitef(x); }
    int isfinite(double x)      { return __isfinite(x); }
    int isfinite(real x)        { return __isfinitel(x); }

    //int isinf(real-floating x);
    int isinf(float x)          { return __isinff(x); }
    int isinf(double x)         { return __isinfl(x); }
    int isinf(real x)           { return __isinfl(x); }

    //int isnan(real-floating x);
    int isnan(float x)          { return __isnanl(x); }
    int isnan(double x)         { return __isnanl(x); }
    int isnan(real x)           { return __isnanl(x); }

    //int isnormal(real-floating x);
    int isnormal(float x)       { return __isnormalf(x); }
    int isnormal(double x)      { return __isnormal(x); }
    int isnormal(real x)        { return __isnormall(x); }

    //int signbit(real-floating x);
    int signbit(float x)        { return __signbitf(x); }
    int signbit(double x)       { return __signbit(x); }
    int signbit(real x)         { return __signbit(x); }
  }
}

extern (D)
{
    //int isgreater(real-floating x, real-floating y);
    int isgreater(float x, float y)        { return !(x !>  y); }
    int isgreater(double x, double y)      { return !(x !>  y); }
    int isgreater(real x, real y)          { return !(x !>  y); }

    //int isgreaterequal(real-floating x, real-floating y);
    int isgreaterequal(float x, float y)   { return !(x !>= y); }
    int isgreaterequal(double x, double y) { return !(x !>= y); }
    int isgreaterequal(real x, real y)     { return !(x !>= y); }

    //int isless(real-floating x, real-floating y);
    int isless(float x, float y)           { return !(x !<  y); }
    int isless(double x, double y)         { return !(x !<  y); }
    int isless(real x, real y)             { return !(x !<  y); }

    //int islessequal(real-floating x, real-floating y);
    int islessequal(float x, float y)      { return !(x !<= y); }
    int islessequal(double x, double y)    { return !(x !<= y); }
    int islessequal(real x, real y)        { return !(x !<= y); }

    //int islessgreater(real-floating x, real-floating y);
    int islessgreater(float x, float y)    { return !(x !<> y); }
    int islessgreater(double x, double y)  { return !(x !<> y); }
    int islessgreater(real x, real y)      { return !(x !<> y); }

    //int isunordered(real-floating x, real-floating y);
    int isunordered(float x, float y)      { return (x !<>= y); }
    int isunordered(double x, double y)    { return (x !<>= y); }
    int isunordered(real x, real y)        { return (x !<>= y); }
}

/* NOTE: freebsd < 8-CURRENT doesn't appear to support *l, but we can
 *       approximate.
 * A lot of them were added in 8.0-RELEASE, and so a lot of these workarounds
 * should then be removed.
 */
// NOTE: FreeBSD 8.0-RELEASE doesn't support log2* nor these *l functions:
//         acoshl, asinhl, atanhl, coshl, sinhl, tanhl, cbrtl, powl, expl,
//         expm1l, logl, log1pl, log10l, erfcl, erfl, lgammal, tgammal;
//       but we can approximate.
version( FreeBSD )
{
  version (none) // < 8-CURRENT
  {
    pure real   acosl(real x) { return acos(x); }
    pure real   asinl(real x) { return asin(x); }
    pure real   atanl(real x) { return atan(x); }
    pure real   atan2l(real y, real x) { return atan2(y, x); }
    pure real   cosl(real x) { return cos(x); }
    pure real   sinl(real x) { return sin(x); }
    pure real   tanl(real x) { return tan(x); }
    pure real   exp2l(real x) { return exp2(x); }
    real        frexpl(real value, int* exp) { return frexp(value, exp); }
    pure int    ilogbl(real x) { return ilogb(x); }
    pure real   ldexpl(real x, int exp) { return ldexp(x, exp); }
    pure real   logbl(real x) { return logb(x); }
    //pure real   modfl(real value, real *iptr); // nontrivial conversion
    pure real   scalbnl(real x, int n) { return scalbn(x, n); }
    pure real   scalblnl(real x, c_long n) { return scalbln(x, n); }
    pure real   fabsl(real x) { return fabs(x); }
    pure real   hypotl(real x, real y) { return hypot(x, y); }
    pure real   sqrtl(real x) { return sqrt(x); }
    pure real   ceill(real x) { return ceil(x); }
    pure real   floorl(real x) { return floor(x); }
    pure real   nearbyintl(real x) { return nearbyint(x); }
    pure real   rintl(real x) { return rint(x); }
    pure c_long lrintl(real x) { return lrint(x); }
    pure real   roundl(real x) { return round(x); }
    pure c_long lroundl(real x) { return lround(x); }
    pure long   llroundl(real x) { return llround(x); }
    pure real   truncl(real x) { return trunc(x); }
    pure real   fmodl(real x, real y) { return fmod(x, y); }
    pure real   remainderl(real x, real y) { return remainder(x, y); }
    real        remquol(real x, real y, int* quo) { return remquo(x, y, quo); }
    pure real   copysignl(real x, real y) { return copysign(x, y); }
//  pure double nan(char* tagp);
//  pure float  nanf(char* tagp);
//  pure real   nanl(char* tagp);
    pure real   nextafterl(real x, real y) { return nextafter(x, y); }
    pure real   nexttowardl(real x, real y) { return nexttoward(x, y); }
    pure real   fdiml(real x, real y) { return fdim(x, y); }
    pure real   fmaxl(real x, real y) { return fmax(x, y); }
    pure real   fminl(real x, real y) { return fmin(x, y); }
    pure real   fmal(real x, real y, real z) { return fma(x, y, z); }
  }
  else
  {
    pure real   acosl(real x);
    pure real   asinl(real x);
    pure real   atanl(real x);
    pure real   atan2l(real y, real x);
    pure real   cosl(real x);
    pure real   sinl(real x);
    pure real   tanl(real x);
    pure real   exp2l(real x);
    real        frexpl(real value, int* exp);
    pure int    ilogbl(real x);
    pure real   ldexpl(real x, int exp);
    pure real   logbl(real x);
    pure real   modfl(real value, real *iptr);
    pure real   scalbnl(real x, int n);
    pure real   scalblnl(real x, c_long n);
    pure real   fabsl(real x);
    pure real   hypotl(real x, real y);
    pure real   sqrtl(real x);
    pure real   ceill(real x);
    pure real   floorl(real x);
    pure real   nearbyintl(real x);
    pure real   rintl(real x);
    pure c_long lrintl(real x);
    pure real   roundl(real x);
    pure c_long lroundl(real x);
    pure long   llroundl(real x);
    pure real   truncl(real x);
    pure real   fmodl(real x, real y);
    pure real   remainderl(real x, real y);
    real        remquol(real x, real y, int* quo);
    pure real   copysignl(real x, real y);
    pure double nan(char* tagp);
    pure float  nanf(char* tagp);
    pure real   nanl(char* tagp);
    pure real   nextafterl(real x, real y);
    pure real   nexttowardl(real x, real y);
    pure real   fdiml(real x, real y);
    pure real   fmaxl(real x, real y);
    pure real   fminl(real x, real y);
    pure real   fmal(real x, real y, real z);
  }
    pure double acos(double x);
    pure float  acosf(float x);

    pure double asin(double x);
    pure float  asinf(float x);

    pure double atan(double x);
    pure float  atanf(float x);

    pure double atan2(double y, double x);
    pure float  atan2f(float y, float x);

    pure double cos(double x);
    pure float  cosf(float x);

    pure double sin(double x);
    pure float  sinf(float x);

    pure double tan(double x);
    pure float  tanf(float x);

    pure double acosh(double x);
    pure float  acoshf(float x);
    pure real   acoshl(real x) { return acosh(x); }

    pure double asinh(double x);
    pure float  asinhf(float x);
    pure real   asinhl(real x) { return asinh(x); }

    pure double atanh(double x);
    pure float  atanhf(float x);
    pure real   atanhl(real x) { return atanh(x); }

    pure double cosh(double x);
    pure float  coshf(float x);
    pure real   coshl(real x) { return cosh(x); }

    pure double sinh(double x);
    pure float  sinhf(float x);
    pure real   sinhl(real x) { return sinh(x); }

    pure double tanh(double x);
    pure float  tanhf(float x);
    pure real   tanhl(real x) { return tanh(x); }

    pure double exp(double x);
    pure float  expf(float x);
    pure real   expl(real x) { return exp(x); }

    pure double exp2(double x);
    pure float  exp2f(float x);

    pure double expm1(double x);
    pure float  expm1f(float x);
    pure real   expm1l(real x) { return expm1(x); }

    double      frexp(double value, int* exp);
    float       frexpf(float value, int* exp);

    pure int    ilogb(double x);
    pure int    ilogbf(float x);

    pure double ldexp(double x, int exp);
    pure float  ldexpf(float x, int exp);

    pure double log(double x);
    pure float  logf(float x);
    pure real   logl(real x) { return log(x); }

    pure double log10(double x);
    pure float  log10f(float x);
    pure real   log10l(real x) { return log10(x); }

    pure double log1p(double x);
    pure float  log1pf(float x);
    pure real   log1pl(real x) { return log1p(x); }

    private enum real ONE_LN2 = 1 / 0x1.62e42fefa39ef358p-1L;
    pure double log2(double x) { return log(x) * ONE_LN2; }
    pure float  log2f(float x) { return logf(x) * ONE_LN2; }
    pure real   log2l(real x)  { return logl(x) * ONE_LN2; }

    pure double logb(double x);
    pure float  logbf(float x);

    pure double modf(double value, double* iptr);
    pure float  modff(float value, float* iptr);

    pure double scalbn(double x, int n);
    pure float  scalbnf(float x, int n);

    double scalbln(double x, c_long n);
    float  scalblnf(float x, c_long n);

    pure double cbrt(double x);
    pure float  cbrtf(float x);
    pure real   cbrtl(real x) { return cbrt(x); }

    pure double fabs(double x);
    pure float  fabsf(float x);

    pure double hypot(double x, double y);
    pure float  hypotf(float x, float y);

    pure double pow(double x, double y);
    pure float  powf(float x, float y);
    pure real   powl(real x, real y) { return pow(x, y); }

    pure double sqrt(double x);
    pure float  sqrtf(float x);

    pure double erf(double x);
    pure float  erff(float x);
    pure real   erfl(real x) { return erf(x); }

    pure double erfc(double x);
    pure float  erfcf(float x);
    pure real   erfcl(real x) { return erfc(x); }

    double      lgamma(double x);
    float       lgammaf(float x);
    real        lgammal(real x) { return lgamma(x); }

    pure double tgamma(double x);
    pure float  tgammaf(float x);
    pure real   tgammal(real x) { return tgamma(x); }

    pure double ceil(double x);
    pure float  ceilf(float x);

    pure double floor(double x);
    pure float  floorf(float x);

    pure double nearbyint(double x);
    pure float  nearbyintf(float x);

    pure double rint(double x);
    pure float  rintf(float x);

    pure c_long lrint(double x);
    pure c_long lrintf(float x);

    pure long   llrint(double x);
    pure long   llrintf(float x);
    pure long   llrintl(real x) { return llrint(x); }

    pure double round(double x);
    pure float  roundf(float x);

    pure c_long lround(double x);
    pure c_long lroundf(float x);

    pure long   llround(double x);
    pure long   llroundf(float x);

    pure double trunc(double x);
    pure float  truncf(float x);

    pure double fmod(double x, double y);
    pure float  fmodf(float x, float y);

    pure double remainder(double x, double y);
    pure float  remainderf(float x, float y);

    double      remquo(double x, double y, int* quo);
    float       remquof(float x, float y, int* quo);

    pure double copysign(double x, double y);
    pure float  copysignf(float x, float y);

    pure double nextafter(double x, double y);
    pure float  nextafterf(float x, float y);

    pure double nexttoward(double x, real y);
    pure float  nexttowardf(float x, real y);

    pure double fdim(double x, double y);
    pure float  fdimf(float x, float y);

    pure double fmax(double x, double y);
    pure float  fmaxf(float x, float y);

    pure double fmin(double x, double y);
    pure float  fminf(float x, float y);

    pure double fma(double x, double y, double z);
    pure float  fmaf(float x, float y, float z);
}
else
{
    pure double acos(double x);
    pure float  acosf(float x);
    pure real   acosl(real x);

    pure double asin(double x);
    pure float  asinf(float x);
    pure real   asinl(real x);

    pure double atan(double x);
    pure float  atanf(float x);
    pure real   atanl(real x);

    pure double atan2(double y, double x);
    pure float  atan2f(float y, float x);
    pure real   atan2l(real y, real x);

    pure double cos(double x);
    pure float  cosf(float x);
    pure real   cosl(real x);

    pure double sin(double x);
    pure float  sinf(float x);
    pure real   sinl(real x);

    pure double tan(double x);
    pure float  tanf(float x);
    pure real   tanl(real x);

    pure double acosh(double x);
    pure float  acoshf(float x);
    pure real   acoshl(real x);

    pure double asinh(double x);
    pure float  asinhf(float x);
    pure real   asinhl(real x);

    pure double atanh(double x);
    pure float  atanhf(float x);
    pure real   atanhl(real x);

    pure double cosh(double x);
    pure float  coshf(float x);
    pure real   coshl(real x);

    pure double sinh(double x);
    pure float  sinhf(float x);
    pure real   sinhl(real x);

    pure double tanh(double x);
    pure float  tanhf(float x);
    pure real   tanhl(real x);

    pure double exp(double x);
    pure float  expf(float x);
    pure real   expl(real x);

    pure double exp2(double x);
    pure float  exp2f(float x);
    pure real   exp2l(real x);

    pure double expm1(double x);
    pure float  expm1f(float x);
    pure real   expm1l(real x);

    double      frexp(double value, int* exp);
    float       frexpf(float value, int* exp);
    real        frexpl(real value, int* exp);

    pure int    ilogb(double x);
    pure int    ilogbf(float x);
    pure int    ilogbl(real x);

    pure double ldexp(double x, int exp);
    pure float  ldexpf(float x, int exp);
    pure real   ldexpl(real x, int exp);

    pure double log(double x);
    pure float  logf(float x);
    pure real   logl(real x);

    pure double log10(double x);
    pure float  log10f(float x);
    pure real   log10l(real x);

    pure double log1p(double x);
    pure float  log1pf(float x);
    pure real   log1pl(real x);

    pure double log2(double x);
    pure float  log2f(float x);
    pure real   log2l(real x);

    pure double logb(double x);
    pure float  logbf(float x);
    pure real   logbl(real x);

    pure double modf(double value, double* iptr);
    pure float  modff(float value, float* iptr);
    pure real   modfl(real value, real *iptr);

    pure double scalbn(double x, int n);
    pure float  scalbnf(float x, int n);
    pure real   scalbnl(real x, int n);

    pure double scalbln(double x, c_long n);
    pure float  scalblnf(float x, c_long n);
    pure real   scalblnl(real x, c_long n);

    pure double cbrt(double x);
    pure float  cbrtf(float x);
    pure real   cbrtl(real x);

    pure double fabs(double x);
    pure float  fabsf(float x);
    pure real   fabsl(real x);

    pure double hypot(double x, double y);
    pure float  hypotf(float x, float y);
    pure real   hypotl(real x, real y);

    pure double pow(double x, double y);
    pure float  powf(float x, float y);
    pure real   powl(real x, real y);

    pure double sqrt(double x);
    pure float  sqrtf(float x);
    pure real   sqrtl(real x);

    pure double erf(double x);
    pure float  erff(float x);
    pure real   erfl(real x);

    pure double erfc(double x);
    pure float  erfcf(float x);
    pure real   erfcl(real x);

    double      lgamma(double x);
    float       lgammaf(float x);
    real        lgammal(real x);

    pure double tgamma(double x);
    pure float  tgammaf(float x);
    pure real   tgammal(real x);

    pure double ceil(double x);
    pure float  ceilf(float x);
    pure real   ceill(real x);

    pure double floor(double x);
    pure float  floorf(float x);
    pure real   floorl(real x);

    pure double nearbyint(double x);
    pure float  nearbyintf(float x);
    pure real   nearbyintl(real x);

    pure double rint(double x);
    pure float  rintf(float x);
    pure real   rintl(real x);

    pure c_long lrint(double x);
    pure c_long lrintf(float x);
    pure c_long lrintl(real x);

    pure long   llrint(double x);
    pure long   llrintf(float x);
    pure long   llrintl(real x);

    pure double round(double x);
    pure float  roundf(float x);
    pure real   roundl(real x);

    pure c_long lround(double x);
    pure c_long lroundf(float x);
    pure c_long lroundl(real x);

    pure long   llround(double x);
    pure long   llroundf(float x);
    pure long   llroundl(real x);

    pure double trunc(double x);
    pure float  truncf(float x);
    pure real   truncl(real x);

    pure double fmod(double x, double y);
    pure float  fmodf(float x, float y);
    pure real   fmodl(real x, real y);

    pure double remainder(double x, double y);
    pure float  remainderf(float x, float y);
    pure real   remainderl(real x, real y);

    double      remquo(double x, double y, int* quo);
    float       remquof(float x, float y, int* quo);
    real        remquol(real x, real y, int* quo);

    pure double copysign(double x, double y);
    pure float  copysignf(float x, float y);
    pure real   copysignl(real x, real y);

    pure double nan(char* tagp);
    pure float  nanf(char* tagp);
    pure real   nanl(char* tagp);

    pure double nextafter(double x, double y);
    pure float  nextafterf(float x, float y);
    pure real   nextafterl(real x, real y);

    pure double nexttoward(double x, real y);
    pure float  nexttowardf(float x, real y);
    pure real   nexttowardl(real x, real y);

    pure double fdim(double x, double y);
    pure float  fdimf(float x, float y);
    pure real   fdiml(real x, real y);

    pure double fmax(double x, double y);
    pure float  fmaxf(float x, float y);
    pure real   fmaxl(real x, real y);

    pure double fmin(double x, double y);
    pure float  fminf(float x, float y);
    pure real   fminl(real x, real y);

    pure double fma(double x, double y, double z);
    pure float  fmaf(float x, float y, float z);
    pure real   fmal(real x, real y, real z);
}
