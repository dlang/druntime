/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.config.mips.ucontext;

private import core.sys.posix.config;
public import core.sys.posix.signal; // for sigset_t, stack_t

version (Posix):
extern (C):

//
// XOpen (XSI)
//
/*
mcontext_t

struct ucontext_t
{
    ucontext_t* uc_link;
    sigset_t    uc_sigmask;
    stack_t     uc_stack;
    mcontext_t  uc_mcontext;
}
*/

version (linux)
{
    version (MIPS)
    {
        private
        {
            enum NGREG  = 32;
            enum NFPREG = 32;

            alias ulong         greg_t;
            alias greg_t[NGREG] gregset_t;

            struct fpregset_t
            {
                union fp_r_t
                {
                    double[NFPREG]  fp_dregs;
                    static struct fp_fregs_t
                    {
                        float   _fp_fregs;
                        uint    _fp_pad;
                    } fp_fregs_t[NFPREG] fp_fregs;
                } fp_r_t fp_r;
            }
        }

        version (MIPS_O32)
        {
            struct mcontext_t
            {
                uint regmask;
                uint status;
                greg_t pc;
                gregset_t gregs;
                fpregset_t fpregs;
                uint fp_owned;
                uint fpc_csr;
                uint fpc_eir;
                uint used_math;
                uint dsp;
                greg_t mdhi;
                greg_t mdlo;
                c_ulong hi1;
                c_ulong lo1;
                c_ulong hi2;
                c_ulong lo2;
                c_ulong hi3;
                c_ulong lo3;
            }
        }
        else
        {
            struct mcontext_t
            {
                gregset_t gregs;
                fpregset_t fpregs;
                greg_t mdhi;
                greg_t hi1;
                greg_t hi2;
                greg_t hi3;
                greg_t mdlo;
                greg_t lo1;
                greg_t lo2;
                greg_t lo3;
                greg_t pc;
                uint fpc_csr;
                uint used_math;
                uint dsp;
                uint reserved;
            }
        }

        struct ucontext_t
        {
            c_ulong     uc_flags;
            ucontext_t* uc_link;
            stack_t     uc_stack;
            mcontext_t  uc_mcontext;
            sigset_t    uc_sigmask;
        }
    }
    else
        static assert(0, "unimplemented");
}
else
    static assert(0, "unimplemented");

