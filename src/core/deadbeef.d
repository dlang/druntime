/**
 * This module contains deadbeef().
 *
 * Copyright: D Language Foundation 2019
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Walter Bright
 * Source:    $(DRUNTIMESRC core/_deadbeef.d)
 */

module core.deadbeef;

/****************************************
 * Step on all the register contents that
 * are not saved by the calling convention
 * of the function.
 *
 * Useful for:
 *
 * 1. testing the code generator
 * 2. testing code that uses inline assembler to help ensure that
 * it follows the function ABI
 * 2. avoiding leaking register information that should be hidden
 * from the caller (clobbering the released part of the stack is
 * a separate concern)
 * 3. avoiding leaking register information to a callee (although
 * clobbering information on the stack is a separate concern)
 *
 * Inserting a call to this function at any point in the code
 * should not produce any failures.
 */

nothrow
@safe
@nogc
pure
void clobberRegisters()
{
    /* Rely on the inline assembler to know which registers
     * are to be preserved by the ABI.
     */
    version (D_InlineAsm_X86)
    {
        asm pure nothrow @safe @nogc
        {
            mov EAX,0xDEADBEEF  ;
            mov EBX,EAX         ;
            mov ECX,EAX         ;
            mov EDX,EAX         ;
            //mov EBP,EAX       ;
            mov ESI,EAX         ;
            mov EDI,EAX         ;

            push EAX            ;
            movd XMM0,[ESP]     ;
            pshufd XMM0,XMM0,0  ;
            movdqa XMM1,XMM0    ;
            movdqa XMM2,XMM0    ;
            movdqa XMM3,XMM0    ;
            movdqa XMM4,XMM0    ;
            movdqa XMM5,XMM0    ;
            movdqa XMM6,XMM0    ;
            movdqa XMM7,XMM0    ;
            pop EAX             ;

            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
        }
    }
    else
    version (D_InlineAsm_X86_64)
    {
        asm pure nothrow @safe @nogc
        {
            mov RAX,0xDEADBEEFDEADBEEF  ;
            mov RBX,RAX         ;
            mov RCX,RAX         ;
            mov RDX,RAX         ;
            mov RBP,RAX         ;
            mov RSI,RAX         ;
            mov RDI,RAX         ;
            mov R8,RAX          ;
            mov R9,RAX          ;
            mov R10,RAX         ;
            mov R11,RAX         ;
            mov R12,RAX         ;
            mov R13,RAX         ;
            mov R14,RAX         ;
            mov R15,RAX         ;

            push RAX            ;
            movd XMM0,[RSP]     ;
            pshufd XMM0,XMM0,0  ;
            movdqa XMM1,XMM0    ;
            movdqa XMM2,XMM0    ;
            movdqa XMM3,XMM0    ;
            movdqa XMM4,XMM0    ;
            movdqa XMM5,XMM0    ;
            movdqa XMM6,XMM0    ;
            movdqa XMM7,XMM0    ;
            movdqa XMM8,XMM0    ;
            movdqa XMM9,XMM0    ;
            movdqa XMM10,XMM0   ;
            movdqa XMM11,XMM0   ;
            movdqa XMM12,XMM0   ;
            movdqa XMM13,XMM0   ;
            movdqa XMM14,XMM0   ;
            movdqa XMM15,XMM0   ;
            pop RAX             ;

            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fldlg2              ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
            fstp ST(0)          ;
        }
    }
}

unittest
{
    clobberRegisters();
}
