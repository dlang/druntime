module pool_lookup;

import core.memory, std.random, std.stdio;

enum N = 25_000_000;
enum P = 4096;

void main()
{
    version (RANDOMIZE)
        auto rnd = Xorshift(unpredictableSeed);
    else
        auto rnd = Xorshift(1202387523);

    auto ptrs = new void[][](P);
    size_t accum;
    foreach(i; 0..P)
    {
        ptrs[i] = new void[32*2^10];
    }
    foreach(_; 0..N)
    {
        size_t i = uniform(0, P, rnd);
        auto blk = GC.query(ptrs[i].ptr);
        accum += blk.attr;
    }
    writeln("Result: ", accum);
}
