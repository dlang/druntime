extern(C) __gshared string[] rt_options = [ "gcopt=minPoolSize:16K maxPoolSize:10M incPoolSize:4K" ];

void main(string[] args)
{
    immutable string[2][] table =
    [
        ["printf", "printf"],
        ["_foo", "_foo"],
        ["_D88", "_D88"],
        ["_D3fooQeFIAyaZv", "void foo.foo(in immutable(char)[])" ],
        ["_D3barQeFIKAyaZv", "void bar.bar(in ref immutable(char)[])" ],
        ["_D4test3fooAa", "char[] test.foo"],
        ["_D8demangle8demangleFAaZAa", "char[] demangle.demangle(char[])"],
        ["_D6object6Object8opEqualsFC6ObjectZi", "int object.Object.opEquals(Object)"],
    ];

    import core.demangle;

    foreach ( i, name; table )
    {
        auto r = demangle!(100 * 1024)( name[0] );
        assert( r == name[1],
                "demangled `" ~ name[0] ~ "` as `" ~ r ~ "` but expected `" ~ name[1] ~ "`");
    }
}
