/**
 * ARM support code for fibers and multithreading.
 *
 * Copyright: Copyright Mikola Lysenko 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Johannes Pfau
 * Source:    $(DRUNTIMESRC core/_thread.d)
 */

#include "common.S"

#if defined(__ARM_EABI__)

/**
 * Performs a context switch.
 *
 * Parameters:
 * r0 - void** - ptr to old stack pointer
 * r1 - void*  - new stack pointer
 *
 * ARM EABI registers:
 * r0-r3   : argument/scratch registers
 * r4-r10  : callee-save registers
 * r11     : frame pointer (or a callee save register if fp isn't needed)
 * r12 =ip : inter procedure register. We can treat it like any other scratch register
 * r13 =sp : stack pointer
 * r14 =lr : link register, it contains the return address (belonging to the function which called us)
 * r15 =pc : program counter
 *
 * For floating point registers:
 * According to AAPCS (version 2.09, section 5.1.2) only the d8-d15 registers need to be preserved
 * across method calls. This applies to all ARM FPU variants, whether they have 16 or 32 double registers
 * NEON support or not, half-float support or not and so on does not matter.
 *
 * Note: If this file was compiled with -mfloat-abi=soft but the code runs on a softfp system with fpu the d8-d15
 * registers won't be saved (we do not know that the system has got a fpu in that case) but the registers might actually
 * be used by other code if it was compiled with -mfloat-abi=softfp.
 *
 * Interworking is only supported on ARMv5+, not on ARM v4T as ARM v4t requires special stubs when changing
 * from thumb to arm mode or the other way round.
 */

.text
.align  2
.global CSYM(fiber_switchContext)
#if defined(__ARM_PCS_VFP) || (defined(__ARM_PCS) && !defined(__SOFTFP__)) // ARM_HardFloat  || ARM_SoftFP
  .fpu vfp
#endif
.type   CSYM(fiber_switchContext), %function
CSYM(fiber_switchContext):
    .fnstart
    push {r4-r11}
    // update the oldp pointer. Link register and floating point registers stored later to prevent the GC from
    // scanning them.
    str sp, [r0]
    // push r0 (or any other register) as well to keep stack 8byte aligned
    push {r0, lr}

    #if defined(__ARM_PCS_VFP) || (defined(__ARM_PCS) && !defined(__SOFTFP__)) // ARM_HardFloat  || ARM_SoftFP
      vpush {d8-d15}
      // now switch over to the new stack. Need to subtract (8*8[d8-d15]+2*4[r0, lr]) to position stack pointer
      // below the last saved register. Remember we saved the SP before pushing [r0, lr, d8-d15]
      sub sp, r1, #72
      vpop {d8-d15}
    #else
      sub sp, r1, #8
    #endif

    // we don't really care about r0, we only used that for padding.
    // r1 is now what used to be in the link register when saving.
    pop {r0, r1, r4-r11}
    /**
     * The link register for the initial jump to fiber_entryPoint must be zero: The jump actually
     * looks like a normal method call as we jump to the start of the fiber_entryPoint function.
     * Although fiber_entryPoint never returns and therefore never accesses lr, it saves lr to the stack.
     * ARM unwinding will then look at the stack, find lr and think that fiber_entryPoint was called by
     * the function in lr! So if we have some address in lr the unwinder will try to continue stack unwinding,
     * although it's already at the stack base and crash.
     * In all other cases the content of lr doesn't matter.
     * Note: If we simply loaded into lr above and then moved lr into pc, the initial method call
     * to fiber_entryPoint would look as if it was called from fiber_entryPoint itself, as the fiber_entryPoint
     * address is in lr on the initial context switch.
     */
    mov lr, #0
    // return by writing lr into pc
    mov pc, r1
    .fnend

#endif
