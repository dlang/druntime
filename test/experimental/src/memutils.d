import core.experimental.memutils : memset;

void main()
{
    DmemsetTestStaticType!(byte)(5);
    DmemsetTestStaticType!(ubyte)(5);
    DmemsetTestStaticType!(short)(5);
    DmemsetTestStaticType!(ushort)(5);
    DmemsetTestStaticType!(int)(5);
    DmemsetTestStaticType!(uint)(5);
    DmemsetTestStaticType!(long)(5);
    DmemsetTestStaticType!(ulong)(5);
    DmemsetTestStaticType!(float)(5);
    DmemsetTestStaticType!(double)(5);
    DmemsetTestStaticType!(real)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 3);
    static foreach (i; 1..10) {
        DmemsetTestDynamicArray!(ubyte)(5, 2^^i);
        DmemsetTestStaticArray!(ubyte, 2^^i)(5);
    }
    DmemsetTestDynamicArray!(ubyte)(5, 100);
    DmemsetTestStaticArray!(ubyte, 100)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 500);
    DmemsetTestStaticArray!(ubyte, 500)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 700);
    DmemsetTestStaticArray!(ubyte, 700)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 3434);
    DmemsetTestStaticArray!(ubyte, 3434)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 7128);
    DmemsetTestStaticArray!(ubyte, 7128)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 13908);
    DmemsetTestStaticArray!(ubyte, 13908)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 16343);
    DmemsetTestStaticArray!(ubyte, 16343)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 27897);
    DmemsetTestStaticArray!(ubyte, 27897)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 32344);
    DmemsetTestStaticArray!(ubyte, 32344)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 46830);
    DmemsetTestStaticArray!(ubyte, 46830)(5);
    DmemsetTestDynamicArray!(ubyte)(5, 64349);
    DmemsetTestStaticArray!(ubyte, 64349)(5);
}

// From a very good Chandler Carruth video on benchmarking: https://www.youtube.com/watch?v=nXaxk27zwlk
void escape(void* p)
{
    version (LDC)
    {
        import ldc.llvmasm;
        __asm("", "r,~{memory}", p);
    }
    version (GNU)
    {
        asm { "" : : "g" p : "memory"; }
    }
}

void DmemsetVerifyArray(T)(int j, const ref T[] a, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) a.ptr;
    foreach (i; 0 .. (a.length * T.sizeof))
    {
        assert(p[i] == v);
    }
}

void DmemsetVerifyStaticType(T)(const ref T t, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) &t;
    foreach (i; 0 .. T.sizeof)
    {
        assert(p[i] == v);
    }
}

void DmemsetTestDynamicArray(T)(const ubyte v, size_t n)
{
    T[] buf;
    buf.length = n + 32;

    enum alignments = 32;
    size_t len = n;

    foreach (i; 0 .. alignments)
    {
        auto d = buf[i..i+n];

        escape(d.ptr);
        memset(d, v);
        DmemsetVerifyArray(i, d, v);
    }
}

void DmemsetTestStaticArray(T, size_t n)(const ubyte v)
{
    T[n + 32] buf;

    enum alignments = 32;
    size_t len = n;

    foreach (i; 0..alignments)
    {
        auto d = buf[i..i+n];

        escape(d.ptr);
        memset(d, v);
        DmemsetVerifyArray(i, d, v);
    }
}

void DmemsetTestStaticType(T)(const ubyte v)
{
    T t;
    escape(&t);
    memset(t, v);
    DmemsetVerifyStaticType(t, v);
}
