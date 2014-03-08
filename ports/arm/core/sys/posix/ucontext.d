/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Johannes Pfau 2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Johannes Pfau
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Johannes Pfau 2013.
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
    version(ARM)
    {
        enum
        {
            R0 = 0,
            R1 = 1,
            R2 = 2,
            R3 = 3,
            R4 = 4,
            R5 = 5,
            R6 = 6,
            R7 = 7,
            R8 = 8,
            R9 = 9,
            R10 = 10,
            R11 = 11,
            R12 = 12,
            R13 = 13,
            R14 = 14,
            R15 = 15
        }

        struct sigcontext
        {
            c_ulong trap_no;
            c_ulong error_code;
            c_ulong oldmask;
            c_ulong arm_r0;
            c_ulong arm_r1;
            c_ulong arm_r2;
            c_ulong arm_r3;
            c_ulong arm_r4;
            c_ulong arm_r5;
            c_ulong arm_r6;
            c_ulong arm_r7;
            c_ulong arm_r8;
            c_ulong arm_r9;
            c_ulong arm_r10;
            c_ulong arm_fp;
            c_ulong arm_ip;
            c_ulong arm_sp;
            c_ulong arm_lr;
            c_ulong arm_pc;
            c_ulong arm_cpsr;
            c_ulong fault_address;
        }

        //alias elf_fpregset_t fpregset_t;
        alias sigcontext mcontext_t;

        struct ucontext_t
        {
            c_ulong uc_flags;
            ucontext_t* uc_link;
            stack_t uc_stack;
            mcontext_t uc_mcontext;
            sigset_t uc_sigmask;
            align(8) c_ulong[128] uc_regspace;
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

