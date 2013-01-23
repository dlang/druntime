/**
 * D header file for C99.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/stdc/_math.d)
 */

module core.stdc.math;

private import core.stdc.config;

version( Windows )
{
    version( LDC )
        version = MSVCRT;
    else version( DigitalMars )
    {
        version( Win32 )
            version = DigitalMarsWin32;
        else version( Win64 )
            version = MSVCRT;
    }
}

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
    int signbit(float x)        { return (cast(short*)&(x))[1] & 0x8000; }
    int signbit(double x)       { return (cast(short*)&(x))[3] & 0x8000; }
    int signbit(real x)
    {
        return (real.sizeof == double.sizeof)
            ? (cast(short*)&(x))[3] & 0x8000
            : (cast(short*)&(x))[4] & 0x8000;
    }
  }
}
else version( MSVCRT )
{
    enum
    {
        _FPCLASS_SNAN = 1,
        _FPCLASS_QNAN = 2,
        _FPCLASS_NINF = 4,
        _FPCLASS_NN   = 8,
        _FPCLASS_ND   = 0x10,
        _FPCLASS_NZ   = 0x20,
        _FPCLASS_PZ   = 0x40,
        _FPCLASS_PD   = 0x80,
        _FPCLASS_PN   = 0x100,
        _FPCLASS_PINF = 0x200,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    int _fpclassf(float x);
    int _fpclass(double x);

    int _finitef(float x);
    int _finite(double x);

    int _isnanf(float x);
    int _isnan(double x);

  extern (D)
  {
    //int fpclassify(real-floating x);
    int fpclassify(float x)     { return _fpclassf(x); }
    int fpclassify(double x)    { return _fpclass(x);  }
    int fpclassify(real x)      { return _fpclass(x);  }

    //int isfinite(real-floating x);
    int isfinite(float x)       { return _finitef(x); }
    int isfinite(double x)      { return _finite(x);  }
    int isfinite(real x)        { return _finite(x);  }

    //int isinf(real-floating x);
    private enum IS_INF_MASK = _FPCLASS_NINF | _FPCLASS_PINF;
    int isinf(float x)          { return fpclassify(x) & IS_INF_MASK; }
    int isinf(double x)         { return fpclassify(x) & IS_INF_MASK; }
    int isinf(real x)           { return fpclassify(x) & IS_INF_MASK; }

    //int isnan(real-floating x);
    int isnan(float x)          { return _isnanf(x); }
    int isnan(double x)         { return _isnan(x);  }
    int isnan(real x)           { return _isnan(x);  }

    //int isnormal(real-floating x);
    private enum IS_NORMAL_MASK = _FPCLASS_NN | _FPCLASS_PN;
    int isnormal(float x)       { return fpclassify(x) & IS_NORMAL_MASK; }
    int isnormal(double x)      { return fpclassify(x) & IS_NORMAL_MASK; }
    int isnormal(real x)        { return fpclassify(x) & IS_NORMAL_MASK; }

    // NOTE: only little-endian currently supported
    //int signbit(real-floating x);
    int signbit(float x)        { return (cast(short*)&(x))[1] & 0x8000; }
    int signbit(double x)       { return (cast(short*)&(x))[3] & 0x8000; }
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
        FP_NAN       = 0,
        FP_INFINITE  = 1,
        FP_ZERO      = 2,
        FP_SUBNORMAL = 3,
        FP_NORMAL    = 4,
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
    int signbit(float x)        { return __signbitf(x); }
    int signbit(double x)       { return __signbit(x);  }
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
    int signbit(float x)        { return __signbitf(x); }
    int signbit(double x)       { return __signbitd(x); }
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
        FP_INFINITE  = 1,
        FP_NAN       = 2,
        FP_NORMAL    = 4,
        FP_SUBNORMAL = 8,
        FP_ZERO      = 0x10,
    }

    enum
    {
        FP_FAST_FMA  = 0,
        FP_FAST_FMAF = 0,
        FP_FAST_FMAL = 0,
    }

    int __fpclassifyf(float);
    int __fpclassifyd(double);
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

    int __signbitf(float);
    int __signbit(double);
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


// standard C functions
double  acos(double x);
double  asin(double x);
double  atan(double x);
double  atan2(double y, double x);
double  cos(double x);
double  sin(double x);
double  tan(double x);
double  cosh(double x);
double  sinh(double x);
double  tanh(double x);
double  exp(double x);
double  frexp(double value, int* exp);
double  ldexp(double x, int exp);
double  log(double x);
double  log10(double x);
double  modf(double value, double* iptr);
double  pow(double x, double y);
double  sqrt(double x);
double  fabs(double x);
double  ceil(double x);
double  floor(double x);
double  fmod(double x, double y);

// NOTE: Microsoft's C Run-Time Library doesn't support C99
//       it only adds float versions (x64 only) and a few C99 functions:
//         logb, scalbn, scalbln, hypot, copysign, nextafter
version( MSVCRT )
{
    // corresponding C99 float versions
    float   acosf(float x);
    float   asinf(float x);
    float   atanf(float x);
    float   atan2f(float y, float x);
    float   cosf(float x);
    float   sinf(float x);
    float   tanf(float x);
    float   coshf(float x);
    float   sinhf(float x);
    float   tanhf(float x);
    float   expf(float x);
//  float   frexpf(float value, int* exp); // macro
//  float   ldexpf(float x, int exp);      // macro
    float   logf(float x);
    float   log10f(float x);
    float   modff(float value, float* iptr);
    float   powf(float x, float y);
    float   sqrtf(float x);
    float   fabsf(float x);
    float   ceilf(float x);
    float   floorf(float x);
    float   fmodf(float x, float y);

    // missing float versions
  deprecated("wrapper for double precision")
  {
    float   frexpf(float value, int* exp) { return frexp(value, exp); }
    float   ldexpf(float x, int exp)      { return ldexp(x, exp);     }
  }

    // a few additional C99 functions:

    private double _logb(double x);
    private float  _logbf(float x);
    double  logb(double x)                { return _logb(x);  }
    float   logbf(float x)                { return _logbf(x); }

    private double _scalb(double x, c_long n);
    private float  _scalbf(float x, c_long n);
    double  scalbln(double x, c_long n)   { return _scalb(x, n);  }
    float   scalblnf(float x, c_long n)   { return _scalbf(x, n); }

    double  scalbn(double x, int n)       { return scalbln(x, n);  }
    float   scalbnf(float x, int n)       { return scalblnf(x, n); }

    private double _hypot(double x, double y);
    private float  _hypotf(float x, float y);
    double  hypot(double x, double y)     { return _hypot(x, y);  }
    float   hypotf(float x, float y)      { return _hypotf(x, y); }

    private double _copysign(double x, double y);
    private float  _copysignf(float x, float y);
    double  copysign(double x, double y)  { return _copysign(x, y);  }
    float   copysignf(float x, float y)   { return _copysignf(x, y); }

    private double _nextafter(double x, double y);
    private float  _nextafterf(float x, float y);
    double  nextafter(double x, double y) { return _nextafter(x, y);  }
    float   nextafterf(float x, float y)  { return _nextafterf(x, y); }

    // long double versions:

  deprecated("wrapper for double precision")
  {
    real    acosl(real x)                 { return acos(x);           }
    real    asinl(real x)                 { return asin(x);           }
    real    atanl(real x)                 { return atan(x);           }
    real    atan2l(real y, real x)        { return atan2(y, x);       }
    real    cosl(real x)                  { return cos(x);            }
    real    sinl(real x)                  { return sin(x);            }
    real    tanl(real x)                  { return tan(x);            }
    real    coshl(real x)                 { return cosh(x);           }
    real    sinhl(real x)                 { return sinh(x);           }
    real    tanhl(real x)                 { return tanh(x);           }
    real    expl(real x)                  { return exp(x);            }
    real    frexpl(real value, int* exp)  { return frexp(value, exp); }
    real    ldexpl(real x, int exp)       { return ldexp(x, exp);     }
    real    logl(real x)                  { return log(x);            }
    real    log10l(real x)                { return log10(x);          }
    real    modfl(real value, real* iptr)
    {
        double id;
        double fd = modf(value, &id);
        *iptr = id;
        return fd;
    }
    real    powl(real x, real y)          { return pow(x, y);         }
    real    sqrtl(real x)                 { return sqrt(x);           }
    real    fabsl(real x)                 { return fabs(x);           }
    real    ceill(real x)                 { return ceil(x);           }
    real    floorl(real x)                { return floor(x);          }
    real    fmodl(real x, real y)         { return fmod(x, y);        }

    // C99
    real    logbl(real x)                 { return logb(x);   }
    real    scalblnl(real x, c_long n)    { return scalbln(x, n); }
    real    scalbnl(real x, int n)        { return scalblnl(x, n); }
    real    hypotl(real x, real y)        { return hypot(x, y);   }
    real    copysignl(real x, real y)     { return copysign(x, y);   }
    real    nextafterl(real x, real y)    { return nextafter(x, y);   }
  }
}
else // !MSVCRT
{
    // corresponding C99 float versions
    float   acosf(float x);
    float   asinf(float x);
    float   atanf(float x);
    float   atan2f(float y, float x);
    float   cosf(float x);
    float   sinf(float x);
    float   tanf(float x);
    float   coshf(float x);
    float   sinhf(float x);
    float   tanhf(float x);
    float   expf(float x);
    float   frexpf(float value, int* exp);
    float   ldexpf(float x, int exp);
    float   logf(float x);
    float   log10f(float x);
    float   modff(float value, float* iptr);
    float   powf(float x, float y);
    float   sqrtf(float x);
    float   fabsf(float x);
    float   ceilf(float x);
    float   floorf(float x);
    float   fmodf(float x, float y);

    // additional C99 functions (double and float versions only):

    double  acosh(double x);
    float   acoshf(float x);

    double  asinh(double x);
    float   asinhf(float x);

    double  atanh(double x);
    float   atanhf(float x);

    double  exp2(double x);
    float   exp2f(float x);

    double  expm1(double x);
    float   expm1f(float x);

    int     ilogb(double x);
    int     ilogbf(float x);

    double  log1p(double x);
    float   log1pf(float x);

  version( FreeBSD )
  {
    // missing log2 function (available since FreeBSD 8.3-RELEASE)
    private enum real ONE_LN2 = 1 / 0x1.62e42fefa39ef35793c7673007e5fp-1L;
    deprecated("unoptimized")
    {
        double  log2(double x) { return log(x)  * cast(double) ONE_LN2; }
        float   log2f(float x) { return logf(x) * cast(float)  ONE_LN2; }
        real    log2l(real x)  { return logl(x) *              ONE_LN2; }
    }
  }
  else
  {
    double  log2(double x);
    float   log2f(float x);
  }

    double  logb(double x);
    float   logbf(float x);

    double  scalbn(double x, int n);
    float   scalbnf(float x, int n);

    double  scalbln(double x, c_long n);
    float   scalblnf(float x, c_long n);

    double  cbrt(double x);
    float   cbrtf(float x);

    double  hypot(double x, double y);
    float   hypotf(float x, float y);

    double  erf(double x);
    float   erff(float x);

    double  erfc(double x);
    float   erfcf(float x);

    double  lgamma(double x);
    float   lgammaf(float x);

    double  tgamma(double x);
    float   tgammaf(float x);

    double  nearbyint(double x);
    float   nearbyintf(float x);

    double  rint(double x);
    float   rintf(float x);

    c_long  lrint(double x);
    c_long  lrintf(float x);

    long    llrint(double x);
    long    llrintf(float x);

    double  round(double x);
    float   roundf(float x);

    c_long  lround(double x);
    c_long  lroundf(float x);

    long    llround(double x);
    long    llroundf(float x);

    double  trunc(double x);
    float   truncf(float x);

    double  remainder(double x, double y);
    float   remainderf(float x, float y);

    double  remquo(double x, double y, int* quo);
    float   remquof(float x, float y, int* quo);

    double  copysign(double x, double y);
    float   copysignf(float x, float y);

    double  nan(char* tagp);
    float   nanf(char* tagp);

    double  nextafter(double x, double y);
    float   nextafterf(float x, float y);

    double  nexttoward(double x, real y);
    float   nexttowardf(float x, real y);

    double  fdim(double x, double y);
    float   fdimf(float x, float y);

    double  fmax(double x, double y);
    float   fmaxf(float x, float y);

    double  fmin(double x, double y);
    float   fminf(float x, float y);

    double  fma(double x, double y, double z);
    float   fmaf(float x, float y, float z);

    // long double versions:

  // NOTE: FreeBSD 8.0-RELEASE doesn't support log2* nor these *l functions:
  //         acoshl, asinhl, atanhl, coshl, sinhl, tanhl, cbrtl, powl, expl,
  //         expm1l, logl, log1pl, log10l, erfcl, erfl, lgammal, tgammal;
  //       but we can approximate.
  version( FreeBSD )
  {
    real    acosl(real x);
    real    asinl(real x);
    real    atanl(real x);
    real    atan2l(real y, real x);
    real    cosl(real x);
    real    sinl(real x);
    real    tanl(real x);
    real    coshl(real x)        { return cosh(x);   }
    real    sinhl(real x)        { return sinh(x);   }
    real    tanhl(real x)        { return tanh(x);   }
    real    expl(real x)         { return exp(x);    }
    real    frexpl(real value, int* exp);
    real    ldexpl(real x, int exp);
    real    logl(real x)         { return log(x);    }
    real    log10l(real x)       { return log10(x);  }
    real    modfl(real value, real* iptr);
    real    powl(real x, real y) { return pow(x, y); }
    real    sqrtl(real x);
    real    fabsl(real x);
    real    ceill(real x);
    real    floorl(real x);
    real    fmodl(real x, real y);

    // C99
    real    acoshl(real x)       { return acosh(x);  }
    real    asinhl(real x)       { return asinh(x);  }
    real    atanhl(real x)       { return atanh(x);  }
    real    exp2l(real x);
    real    expm1l(real x)       { return expm1(x);  }
    int     ilogbl(real x);
    real    log1pl(real x)       { return log1p(x);  }
//  real    log2l(real x); // already implemented above
    real    logbl(real x);
    real    scalbnl(real x, int n);
    real    scalblnl(real x, c_long n);
    real    cbrtl(real x)        { return cbrt(x);   }
    real    hypotl(real x, real y);
    real    erfl(real x)         { return erf(x);    }
    real    erfcl(real x)        { return erfc(x);   }
    real    lgammal(real x)      { return lgamma(x); }
    real    tgammal(real x)      { return tgamma(x); }
    real    nearbyintl(real x);
    real    rintl(real x);
    c_long  lrintl(real x);
    long    llrintl(real x);
    real    roundl(real x);
    c_long  lroundl(real x);
    long    llroundl(real x);
    real    truncl(real x);
    real    remainderl(real x, real y);
    real    remquol(real x, real y, int* quo);
    real    copysignl(real x, real y);
    real    nanl(char* tagp);
    real    nextafterl(real x, real y);
    real    nexttowardl(real x, real y);
    real    fdiml(real x, real y);
    real    fmaxl(real x, real y);
    real    fminl(real x, real y);
    real    fmal(real x, real y, real z);
  }
  else // !FreeBSD
  {
    real    acosl(real x);
    real    asinl(real x);
    real    atanl(real x);
    real    atan2l(real y, real x);
    real    cosl(real x);
    real    sinl(real x);
    real    tanl(real x);
    real    coshl(real x);
    real    sinhl(real x);
    real    tanhl(real x);
    real    expl(real x);
    real    frexpl(real value, int* exp);
    real    ldexpl(real x, int exp);
    real    logl(real x);
    real    log10l(real x);
    real    modfl(real value, real* iptr);
    real    powl(real x, real y);
    real    sqrtl(real x);
    real    fabsl(real x);
    real    ceill(real x);
    real    floorl(real x);
    real    fmodl(real x, real y);

    // C99
    real    acoshl(real x);
    real    asinhl(real x);
    real    atanhl(real x);
    real    exp2l(real x);
    real    expm1l(real x);
    int     ilogbl(real x);
    real    log1pl(real x);
    real    log2l(real x);
    real    logbl(real x);
    real    scalbnl(real x, int n);
    real    scalblnl(real x, c_long n);
    real    cbrtl(real x);
    real    hypotl(real x, real y);
    real    erfl(real x);
    real    erfcl(real x);
    real    lgammal(real x);
    real    tgammal(real x);
    real    nearbyintl(real x);
    real    rintl(real x);
    c_long  lrintl(real x);
    long    llrintl(real x);
    real    roundl(real x);
    c_long  lroundl(real x);
    long    llroundl(real x);
    real    truncl(real x);
    real    remainderl(real x, real y);
    real    remquol(real x, real y, int* quo);
    real    copysignl(real x, real y);
    real    nanl(char* tagp);
    real    nextafterl(real x, real y);
    real    nexttowardl(real x, real y);
    real    fdiml(real x, real y);
    real    fmaxl(real x, real y);
    real    fminl(real x, real y);
    real    fmal(real x, real y, real z);
  }
}
