module core.internal.adapted.string;

immutable(char)* toStringz(const(char)[] s) @trusted pure nothrow
out (result)
{
    import core.stdc.string : strlen, memcmp;

    if (result)
    {
        auto slen = s.length;
        while (slen > 0 && s[slen - 1] == 0)
            --slen;
        assert(strlen(result) == slen);
        assert(result[0 .. slen] == s[0 .. slen]);
    }
}
do
{
    //import std.exception : assumeUnique;
    /+ Unfortunately, this isn't reliable.
     We could make this work if string literals are put
     in read-only memory and we test if s[] is pointing into
     that.

     /* Peek past end of s[], if it's 0, no conversion necessary.
     * Note that the compiler will put a 0 past the end of static
     * strings, and the storage allocator will put a 0 past the end
     * of newly allocated char[]'s.
     */
     char* p = &s[0] + s.length;
     if (*p == 0)
     return s;
     +/

    // Need to make a copy
    auto copy = new char[s.length + 1];
    copy[0 .. s.length] = s[];
    copy[s.length] = 0;

    // CHECKME
    //return &assumeUnique(copy)[0];
    return &copy[0];
}

/++ Ditto +/
immutable(char)* toStringz(in string s) @trusted pure nothrow
{
    if (s.empty)
        return "".ptr;
    /* Peek past end of s[], if it's 0, no conversion necessary.
     * Note that the compiler will put a 0 past the end of static
     * strings, and the storage allocator will put a 0 past the end
     * of newly allocated char[]'s.
     */
    immutable p = s.ptr + s.length;
    // Is p dereferenceable? A simple test: if the p points to an
    // address multiple of 4, then conservatively assume the pointer
    // might be pointing to a new block of memory, which might be
    // unreadable. Otherwise, it's definitely pointing to valid
    // memory.
    if ((cast(size_t) p & 3) && *p == 0)
        return &s[0];
    return toStringz(cast(const char[]) s);
}

private:
bool empty(string a) pure nothrow
{
    return a.length == 0;
}
