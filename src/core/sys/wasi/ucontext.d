module core.sys.wasi.ucontext;

private import core.sys.wasi.config;
public import core.sys.wasi.signal; // for sigset_t, stack_t
private import core.stdc.stdint : uintptr_t;

version (WebAssembly):
extern (C):
nothrow:
@nogc:

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

struct mcontext_t
{
    ulong[32] __space;
}
struct ucontext_t
{
    ulong uc_flags;
    ucontext_t *uc_link;
    stack_t uc_stack;
    mcontext_t uc_mcontext;
    sigset_t uc_sigmask;
    ulong[64] __fpregs_mem;
}
