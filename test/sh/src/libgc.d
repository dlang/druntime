import core.memory;

__gshared ubyte[] static_root;

void alloc()
{
    static_root = (cast(ubyte*)GC.malloc(10))[0 .. 10];
    static_root[] = 0;
}

void access()
{
    assert(static_root.length == 10);
    foreach(b; static_root)
        assert(b == 0);
}

void free()
{
    GC.free(static_root.ptr);
    static_root = null;
}

ubyte[] tls_root;

void tls_alloc()
{
    tls_root = (cast(ubyte*)GC.malloc(10))[0 .. 10];
    tls_root[] = 0;
}

void tls_access()
{
    assert(tls_root.length == 10);
    foreach(b; tls_root)
        assert(b == 0);
}

void tls_free()
{
    GC.free(tls_root.ptr);
    tls_root = null;
}
