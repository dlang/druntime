/*
A simple performance test to measure the difference that sentinel arrays can make
when you don't have to copy strings to temporary buffers just to add sentinel values for
functions like C standard library string functions.

Run With:
../dmd/generated/linux/release/64/dmd -I../import -run sentinelPerfTest.d

Here's the numbers I got:
---
empty string:
  tempCString: 344 ms
  alloca copy: 332 ms
  sentinel (no copy): 68 ms
10 char str:
  tempCString: 1449 ms
  alloca copy: 349 ms
  sentinel (no copy): 68 ms
100 char string:
  tempCString: 11494 ms
  alloca copy: 458 ms
  sentinel (no copy): 153 ms
---

A huge increase in performance from both tempCString and the alloca copy
*/

import std.stdio;

import core.stdc.stdlib : alloca;
import core.sentinel;
import std.datetime.stopwatch;

extern(C) size_t strlen(cstring);

pragma(inline) size_t strlenWrapper(T)(T str)
{
    static if (is(T : SentinelArray!(const(char))))
    {
        pragma(msg, "detected sentinel array");
        // no need to copy the string, it is already
        // null-terminated
        return strlen(str.ptr);
    }
    else
    {
        pragma(msg, "detected normal array");
        //
        // An optimal version of tempCString
        //
        auto buffer = cast(char*)alloca(str.length + 1);
        buffer[0 .. str.length] = str[];
        buffer[str.length] = '\0';
        return strlen(buffer.asSentinelPtrUnchecked);
    }
}

void main()
{
    for(int i = 0; i < 4; i++)
    {
        run(i);
    }
}

void run(size_t runIndex)
{
    writefln("---- run %s --------------------------", runIndex);
    writefln("empty string:");
    test!""();
    writefln("10 char str:");
    test!"1234567890"();
    writefln("100 char string:");
    test!"1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"();
}

void test(string s)()
{
    enum iterations = 10000000;
    StopWatch sw;

    sw.reset();
    sw.start();
    foreach (i; 0 .. iterations)
    {
        import std.internal.cstring : tempCString;
        strlen(s.tempCString.asSentinelPtrUnchecked);
    }
    sw.stop();
    writefln("  tempCString: %s ms", sw.peek.total!"msecs");

    sw.reset();
    sw.start();
    foreach (i; 0 .. iterations)
    {
        strlenWrapper(s);
    }
    sw.stop();
    writefln("  alloca copy: %s ms", sw.peek.total!"msecs");

    sw.reset();
    sw.start();
    foreach (i; 0 .. iterations)
    {
        strlenWrapper(StringLiteral!s);
    }
    sw.stop();
    writefln("  sentinel (no copy): %s ms", sw.peek.total!"msecs");
}
