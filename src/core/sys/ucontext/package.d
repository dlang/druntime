
module core.sys.ucontext;

version      (AArch64) public import core.sys.ucontext.aarch;
else version (ARM)     public import core.sys.ucontext.arm;
else version (MIPS)    public import core.sys.ucontext.mips;
else version (PPC)     public import core.sys.ucontext.ppc;
else version (PPC64)   public import core.sys.ucontext.ppc;
else version (X86_64)  public import core.sys.ucontext.intel;
else version (X86)     public import core.sys.ucontext.intel;
else                   public import core.sys.ucontext.generic;
