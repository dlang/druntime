import libgc;
import core.memory;

unittest
{
    libgc.alloc();
    libgc.access();
    GC.collect();
    libgc.access();
    libgc.free();

    libgc.tls_alloc();
    libgc.tls_access();
    GC.collect();
    libgc.tls_access();
    libgc.tls_free();
}

void main()
{
}
