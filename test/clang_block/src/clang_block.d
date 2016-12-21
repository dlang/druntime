import core.stdc.clang_block;

extern(C) void voidVoidArgs(Block!()*);
extern(C) int intVoidArgs(Block!(int)*);
extern(C) void voidIntArgs(Block!(void, int)*, int);
extern(C) int intIntArgs(Block!(int, int)*, int);

// block returning void taking no arguments
unittest
{
    enum value = 3;

    int result;
    auto b = block({ result = value; });
    voidVoidArgs(&b);
    assert(result == value);
}

// block returning int taking no arguments
unittest
{
    enum value = 3;

    auto b = block({ return value; });
    auto result = intVoidArgs(&b);
    assert(result == value);
}

// block returning void taking int argument
unittest
{
    enum value = 3;

    int result;
    auto b = block((int v) {
       result = v;
    });
    voidIntArgs(&b, value);
    assert(result == value);
}

// block returning int taking int argument
unittest
{
    enum value = 3;

    auto b = block((int v) {
        return v;
    });
    auto result = intIntArgs(&b, value);
    assert(result == value);
}
