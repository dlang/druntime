import libinit;
import core.thread;

shared static this()
{
    assert(libinit.shared_init == 1);
    assert(libinit.thread_init == 0);
    assert(libinit.tlocal_init == 0);
}

shared static ~this()
{
    assert(libinit.shared_init == 1);
    assert(libinit.thread_init == 0);
    assert(libinit.tlocal_init == 0);
}

static this()
{
    assert(libinit.shared_init == 1);
    assert(libinit.thread_init >= 1);
    assert(libinit.tlocal_init == 1);
}

static ~this()
{
    assert(libinit.shared_init == 1);
    assert(libinit.thread_init >= 1);
    assert(libinit.tlocal_init == 1);
}

unittest
{
    assert(libinit.shared_init == 1);
    assert(libinit.thread_init == 1);
    assert(libinit.tlocal_init == 1);

    void foo()
    {
        assert(libinit.shared_init == 1);
        assert(libinit.thread_init == 2);
        assert(libinit.tlocal_init == 1);
    }

    auto thread = new Thread(&foo);
    thread.start();
    thread.join();

    assert(libinit.shared_init == 1);
    assert(libinit.thread_init == 1);
    assert(libinit.tlocal_init == 1);
}

void main()
{
}
