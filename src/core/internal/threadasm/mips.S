/**
 * MIPS support code for fibers and multithreading.
 *
 * Copyright: Copyright Mikola Lysenko 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Martin Nowak
 * Source:    $(DRUNTIMESRC core/internal/threadasm/_mips.S)
 */

#include "common.S"

#if _MIPS_SIM == _ABIO32

/**
 * Performs a context switch.
 *
 * $a0 - void** - ptr to old stack pointer
 * $a1 - void*  - new stack pointer
 *
 */
.text
.globl CSYM(fiber_switchContext)
CSYM(fiber_switchContext):
    addiu $sp, $sp, -(10 * 4)

    // fp regs and return address are stored below the stack
    // because we don't want the GC to scan them.

#ifdef __mips_hard_float
#define ALIGN8(val) (val + (-val & 7))
#define BELOW (ALIGN8(6 * 8 + 4))
    sdc1 $f20, (0 * 8 - BELOW)($sp)
    sdc1 $f22, (1 * 8 - BELOW)($sp)
    sdc1 $f24, (2 * 8 - BELOW)($sp)
    sdc1 $f26, (3 * 8 - BELOW)($sp)
    sdc1 $f28, (4 * 8 - BELOW)($sp)
    sdc1 $f30, (5 * 8 - BELOW)($sp)
#endif
    sw $ra, -4($sp)

    sw $s0, (0 * 4)($sp)
    sw $s1, (1 * 4)($sp)
    sw $s2, (2 * 4)($sp)
    sw $s3, (3 * 4)($sp)
    sw $s4, (4 * 4)($sp)
    sw $s5, (5 * 4)($sp)
    sw $s6, (6 * 4)($sp)
    sw $s7, (7 * 4)($sp)
    sw $s8, (8 * 4)($sp)
    sw $gp, (9 * 4)($sp)

    // swap stack pointer
    sw $sp, 0($a0)
    move $sp, $a1

#ifdef __mips_hard_float
    ldc1 $f20, (0 * 8 - BELOW)($sp)
    ldc1 $f22, (1 * 8 - BELOW)($sp)
    ldc1 $f24, (2 * 8 - BELOW)($sp)
    ldc1 $f26, (3 * 8 - BELOW)($sp)
    ldc1 $f28, (4 * 8 - BELOW)($sp)
    ldc1 $f30, (5 * 8 - BELOW)($sp)
#endif
    lw $ra, -4($sp)

    lw $s0, (0 * 4)($sp)
    lw $s1, (1 * 4)($sp)
    lw $s2, (2 * 4)($sp)
    lw $s3, (3 * 4)($sp)
    lw $s4, (4 * 4)($sp)
    lw $s5, (5 * 4)($sp)
    lw $s6, (6 * 4)($sp)
    lw $s7, (7 * 4)($sp)
    lw $s8, (8 * 4)($sp)
    lw $gp, (9 * 4)($sp)

    addiu $sp, $sp, (10 * 4)

    jr $ra // return
#endif
