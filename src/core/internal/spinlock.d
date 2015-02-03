/**
 * SpinLock for runtime internal usage.
 *
 * Copyright: Copyright Digital Mars 2015 -.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Martin Nowak
 * Source: $(DRUNTIMESRC core/internal/_spinlock.d)
 */
module core.internal.spinlock;

import core.atomic, core.thread;

shared struct SpinLock
{
    /// for how long is the lock contended
    enum Contention : ubyte
    {
        brief,
        medium,
        lengthy,
    }

@trusted nothrow:
    this(Contention cont)
    {
        this.cont = cont;
    }

    void lock()
    {
        // TTAS lock
        while (true)
        {
            for (size_t n; atomicLoad!(MemoryOrder.raw)(val); ++n)
                yield(n);
            if (cas(&val, false, true))
                return;
        }
    }

    void unlock()
    {
        atomicStore!(MemoryOrder.rel)(val, false);
    }

    /// yield with backoff
    void yield(size_t k)
    {
        if (k < pauseThresh >> cont) return pause();
        else if (k < 32 >> cont) return Thread.yield();
        Thread.sleep(1.msecs);
    }

private:
    version (D_InlineAsm_X86)
        enum X86 = true;
    else version (D_InlineAsm_X86_64)
        enum X86 = true;
    else
        enum X86 = false;

    static if (X86)
    {
        enum pauseThresh = 16;
        void pause() { asm @trusted nothrow { rep; nop; } }
    }
    else
    {
        enum pauseThresh = 4;
        void pause() {}
    }

    bool val;
    Contention cont;
}

// aligned to cacheline to avoid false sharing
shared align(64) struct AlignedSpinLock
{
    this(SpinLock.Contention cont)
    {
        impl = shared(SpinLock)(cont);
    }
    SpinLock impl;
    alias impl this;
}
