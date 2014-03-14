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
    version (AArch64)
    {
        alias int greg_t;

        struct sigcontext {
            ulong           fault_address;
            /* AArch64 registers */
            ulong           regs[31];
            ulong           sp;
            ulong           pc;
            ulong           pstate;
            /* 4K reserved for FP/SIMD state and future expansion */
            align(16) ubyte __reserved[4096];
        }

        alias sigcontext mcontext_t;

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

