/**
 * Support code for mutithreading.
 *
 * Copyright: Copyright Mikola Lysenko 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Mikola Lysenko
 * Source:    $(DRUNTIMESRC core/internal/threadasm/_aarch64.S)
 */

#if (__linux__ || __FreeBSD__ || __NetBSD__ || __DragonFly__) && __ELF__
/*
 * Mark the resulting object file as not requiring execution permissions on
 * stack memory. The absence of this section would mark the whole resulting
 * library as requiring an executable stack, making it impossible to
 * dynamically load druntime on several Linux platforms where this is
 * forbidden due to security policies.
 */
.section .note.GNU-stack,"",%progbits
#endif

/* Let preprocessor tell us if C symbols have a prefix: __USER_LABEL_PREFIX__ */
#ifdef __USER_LABEL_PREFIX__
#define GLUE2(a, b) a ## b
#define GLUE(a, b) GLUE2(a, b)
#define CSYM(name) GLUE(__USER_LABEL_PREFIX__, name)
#else
#define CSYM(name) name
#endif

/************************************************************************************
 * AArch64 (arm64) ASM BITS
 ************************************************************************************/

/**
 * preserve/restore AAPCS64 registers
 *   x19-x28 5.1.1 64-bit callee saved
 *   x29 fp, or possibly callee saved reg - depends on platform choice 5.2.3)
 *   x30 lr
 *   d8-d15  5.1.2 says callee only must save bottom 64-bits (the "d" regs)
 *
 * saved regs on stack will look like:
 *   19: x19
 *   18: x20
 *   ...
 *   10: x28
 *    9: x29 (fp)  <-- oldp / *newp save stack top
 *    8: x30 (lr)
 *    7: d8
 *   ...
 *    0: d15       <-- sp
 */
        .text
        .global CSYM(fiber_switchContext)
        .p2align  2
        .type   fiber_switchContext, %function
CSYM(fiber_switchContext):
        stp     d15, d14, [sp, #-20*8]!
        stp     d13, d12, [sp, #2*8]
        stp     d11, d10, [sp, #4*8]
        stp     d9, d8,   [sp, #6*8]
        stp     x30, x29, [sp, #8*8] // lr, fp
        stp     x28, x27, [sp, #10*8]
        stp     x26, x25, [sp, #12*8]
        stp     x24, x23, [sp, #14*8]
        stp     x22, x21, [sp, #16*8]
        stp     x20, x19, [sp, #18*8]

        // oldp is set above saved lr (x30) to hide it and float regs
        // from GC
        add     x19, sp, #9*8
        str     x19, [x0]       // *oldp tstack
        sub     sp, x1, #9*8    // switch to newp sp

        ldp     x20, x19, [sp, #18*8]
        ldp     x22, x21, [sp, #16*8]
        ldp     x24, x23, [sp, #14*8]
        ldp     x26, x25, [sp, #12*8]
        ldp     x28, x27, [sp, #10*8]
        ldp     x30, x29, [sp, #8*8] // lr, fp
        ldp     d9, d8,   [sp, #6*8]
        ldp     d11, d10, [sp, #4*8]
        ldp     d13, d12, [sp, #2*8]
        ldp     d15, d14, [sp], #20*8
        ret

/**
 * When generating any kind of backtrace (gdb, exception handling) for
 * a function called in a Fiber, we need to tell the unwinder to stop
 * at our Fiber main entry point, i.e. we need to mark the bottom of
 * the call stack. This can be done by clearing the link register lr
 * prior to calling fiber_entryPoint (i.e. in fiber_switchContext) or
 * using a .cfi_undefined directive for the link register in the
 * Fiber entry point. cfi_undefined seems to yield better results in gdb.
 * Unfortunately we can't place it into fiber_entryPoint using inline
 * asm, so we use this trampoline instead.
 */
        .text
        .global CSYM(fiber_trampoline)
        .p2align  2
        .type   fiber_trampoline, %function
CSYM(fiber_trampoline):
        .cfi_startproc
        .cfi_undefined x30
        // fiber_entryPoint never returns
        bl fiber_entryPoint
        .cfi_endproc
