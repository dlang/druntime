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
module core.stdc.complex;

extern (C):
@trusted: // All of these operate on floating point values only.
nothrow:

alias creal complex;
alias ireal imaginary;

pure cdouble cacos(cdouble z);
pure cfloat  cacosf(cfloat z);
pure creal   cacosl(creal z);

pure cdouble casin(cdouble z);
pure cfloat  casinf(cfloat z);
pure creal   casinl(creal z);

pure cdouble catan(cdouble z);
pure cfloat  catanf(cfloat z);
pure creal   catanl(creal z);

pure cdouble ccos(cdouble z);
pure cfloat  ccosf(cfloat z);
pure creal   ccosl(creal z);

pure cdouble csin(cdouble z);
pure cfloat  csinf(cfloat z);
pure creal   csinl(creal z);

pure cdouble ctan(cdouble z);
pure cfloat  ctanf(cfloat z);
pure creal   ctanl(creal z);

pure cdouble cacosh(cdouble z);
pure cfloat  cacoshf(cfloat z);
pure creal   cacoshl(creal z);

pure cdouble casinh(cdouble z);
pure cfloat  casinhf(cfloat z);
pure creal   casinhl(creal z);

pure cdouble catanh(cdouble z);
pure cfloat  catanhf(cfloat z);
pure creal   catanhl(creal z);

pure cdouble ccosh(cdouble z);
pure cfloat  ccoshf(cfloat z);
pure creal   ccoshl(creal z);

pure cdouble csinh(cdouble z);
pure cfloat  csinhf(cfloat z);
pure creal   csinhl(creal z);

pure cdouble ctanh(cdouble z);
pure cfloat  ctanhf(cfloat z);
pure creal   ctanhl(creal z);

pure cdouble cexp(cdouble z);
pure cfloat  cexpf(cfloat z);
pure creal   cexpl(creal z);

pure cdouble clog(cdouble z);
pure cfloat  clogf(cfloat z);
pure creal   clogl(creal z);

pure double cabs(cdouble z);
pure float  cabsf(cfloat z);
pure real   cabsl(creal z);

pure cdouble cpow(cdouble x, cdouble y);
pure cfloat  cpowf(cfloat x, cfloat y);
pure creal   cpowl(creal x, creal y);

pure cdouble csqrt(cdouble z);
pure cfloat  csqrtf(cfloat z);
pure creal   csqrtl(creal z);

pure double carg(cdouble z);
pure float  cargf(cfloat z);
pure real   cargl(creal z);

pure double cimag(cdouble z);
pure float  cimagf(cfloat z);
pure real   cimagl(creal z);

pure cdouble conj(cdouble z);
pure cfloat  conjf(cfloat z);
pure creal   conjl(creal z);

pure cdouble cproj(cdouble z);
pure cfloat  cprojf(cfloat z);
pure creal   cprojl(creal z);

//pure double creal(cdouble z);
pure float  crealf(cfloat z);
pure real   creall(creal z);
