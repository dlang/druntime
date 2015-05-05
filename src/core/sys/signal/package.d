/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Iain Buclaw 2015.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Iain Buclaw
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 * Source:    $(DRUNTIMESRC core/sys/signal/_package.d)
 */

version      (AArch64) public import core.sys.signal.aarch;
else version (ARM)     public import core.sys.signal.arm;
else version (MIPS)    public import core.sys.signal.mips;
else version (PPC)     public import core.sys.signal.ppc;
else version (PPC64)   public import core.sys.signal.ppc;
else version (X86_64)  public import core.sys.signal.intel;
else version (X86)     public import core.sys.signal.intel;
else                   public import core.sys.signal.generic;
