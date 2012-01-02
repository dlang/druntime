__gshared size_t shared_init;
__gshared size_t thread_init;
size_t tlocal_init;

shared static this()
{
    assert(shared_init == 0);
    assert(thread_init == 0);
    assert(tlocal_init == 0);
    ++shared_init;
}

shared static ~this()
{
    --shared_init;
    assert(tlocal_init == 0);
    assert(thread_init == 0);
    assert(shared_init == 0);
}

static this()
{
    ++thread_init;
    ++tlocal_init;
}

static ~this()
{
    --tlocal_init;
    --thread_init;
}
