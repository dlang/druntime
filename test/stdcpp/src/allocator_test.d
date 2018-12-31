import core.stdcpp.allocator;

extern(C++) struct Mystruct { int a; }

alias AliasSeq(T...) = T;
unittest
{
    static foreach(T; AliasSeq!(int,float, Mystruct))
    {{
        allocator!T alloc;
        auto ptr = alloc.allocate(42);
        alloc.deallocate(ptr,42);
    }}
}
