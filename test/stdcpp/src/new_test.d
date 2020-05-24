import core.stdcpp.new_;
import core.stdcpp.xutility : __cpp_aligned_new;

extern(C++) struct MyStruct
{
    int* a;
    double* b;
    MyStruct* c;
}

extern(C++) MyStruct cpp_new() @system;
extern(C++) void cpp_delete(ref MyStruct s) @system;
extern(C++) size_t defaultAlignment() @system;
extern(C++) bool hasAlignedNew() @system;

unittest
{
    // test the magic numbers are consistent between C++ and D
    assert(hasAlignedNew() == !!__cpp_aligned_new, "__cpp_aligned_new does not match C++ compiler");
    static if (__cpp_aligned_new)
        assert(defaultAlignment() == __STDCPP_DEFAULT_NEW_ALIGNMENT__, "__STDCPP_DEFAULT_NEW_ALIGNMENT__ does not match C++ compiler");

    // alloc in C++, delete in D
    MyStruct s = cpp_new();
    __cpp_delete(cast(void*)s.a);
    __cpp_delete(cast(void*)s.b);
    __cpp_delete(cast(void*)s.c);

    // alloc in D, delete in C++
    s.a = cast(int*)__cpp_new(int.sizeof);
    s.b = cast(double*)__cpp_new(double.sizeof);
    s.c = cast(MyStruct*)__cpp_new(MyStruct.sizeof);
    cpp_delete(s);
}
