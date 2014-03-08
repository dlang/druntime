/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Kai Nacke 2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Kai Nacke
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Kai Nacke 2013.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.ucontext;

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
    version (PPC)
    {
        private
        {
            enum NGREG  = 48;

            alias c_ulong        greg_t;
            alias greg_t[NGREG]  gregset_t;

            struct fpregset_t
            {
                double[32] fpregs;
                double fpscr;
                uint[2] _pad;
            }

            struct vrregset_t
            {
                uint[32][4] vrregs;
                uint        vrsave;
                uint[2]     __pad;
                uint vscr;
            }

            struct pt_regs
            {
                c_ulong[32] gpr;
                c_ulong     nip;
                c_ulong     msr;
                c_ulong     orig_gpr3;
                c_ulong     ctr;
                c_ulong     link;
                c_ulong     xer;
                c_ulong     ccr;
                c_ulong     mq;
                c_ulong     trap;
                c_ulong     dar;
                c_ulong     dsisr;
                c_ulong     result;
            }
        }

        struct mcontext_t
        {
            gregset_t gregs;
            fpregset_t fpregs;
            align(16) vrregset_t vrregs;
        }

        struct ucontext_t
        {
            c_ulong     uc_flags;
            ucontext_t* uc_link;
            stack_t     uc_stack;
            int[7]      uc_pad;
            union uc_mcontext
            {
                pt_regs*     regs;
                mcontext_t*  uc_regs;
            }
            sigset_t    uc_sigmask;
            char[mcontext_t.sizeof + 12] uc_reg_space;
        }
    }
    else version (PPC64)
    {
        private
        {
            enum NGREG  = 48;
            enum NFPREG = 33;
            enum NVRREG = 34;

            alias c_ulong        greg_t;
            alias greg_t[NGREG]  gregset_t;
            alias double[NFPREG] fpregset_t;

            struct vscr_t
            {
                uint[3] __pad;
                uint    vscr_word;
            }

            struct vrregset_t
            {
                uint[32][4] vrregs;
                vscr_t      vscr;
                uint        vrsave;
                uint[3]     __pad;
            }

            struct pt_regs
            {
                c_ulong[32] gpr;
                c_ulong     nip;
                c_ulong     msr;
                c_ulong     orig_gpr3;
                c_ulong     ctr;
                c_ulong     link;
                c_ulong     xer;
                c_ulong     ccr;
                c_ulong     softe;
                c_ulong     trap;
                c_ulong     dar;
                c_ulong     dsisr;
                c_ulong     result;
            }
        }

        struct mcontext_t
        {
            c_ulong[4] __unused;
            int signal;
            int __pad0;
            c_ulong handler;
            c_ulong oldmask;
            pt_regs* regs;
            gregset_t gp_regs;
            fpregset_t fp_regs;
            vrregset_t *v_regs;
            c_long[NVRREG+NVRREG+1] vmx_reserve;
        }

        struct ucontext_t
        {
            c_ulong     uc_flags;
            ucontext_t* uc_link;
            stack_t     uc_stack;
            sigset_t    uc_sigmask;
            mcontext_t  uc_mcontext;
        }
    }
    else
        static assert(0, "unimplemented");
}
else
    static assert(0, "unimplemented");

//
// Obsolescent (OB)
//
/*
int  getcontext(ucontext_t*);
void makecontext(ucontext_t*, void function(), int, ...);
int  setcontext(in ucontext_t*);
int  swapcontext(ucontext_t*, in ucontext_t*);
*/

int  getcontext(ucontext_t*);
void makecontext(ucontext_t*, void function(), int, ...);
int  setcontext(in ucontext_t*);
int  swapcontext(ucontext_t*, in ucontext_t*);

