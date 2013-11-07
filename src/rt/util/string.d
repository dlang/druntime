/**
 * String manipulation and comparison utilities.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.util.string;

private import core.stdc.string;

@trusted:
nothrow:

alias UintStringBuff = char[10];
alias UlongStringBuff = char[20];

version(D_LP64)
    alias SizeStringBuff = UlongStringBuff;
else
    alias SizeStringBuff = UintStringBuff;

char[] uintToTempString(size_t n)(in uint val, ref char[n] buff) pure
{ return val._unsignedToTempString(buff); }

char[] ulongToTempString(size_t n)(in ulong val, ref char[n] buff) pure
{ return val._unsignedToTempString(buff); }

version(D_LP64)
    alias sizeToTempString = ulongToTempString;
else
    alias sizeToTempString = uintToTempString;

private char[] _unsignedToTempString(T, size_t n)(in T val, ref char[n] buff) pure
if(is(T == uint) || is(T == ulong))
{
    static assert(n >= (is(T == uint) ? 10 : 20), "Buffer is to small for `" ~ T.stringof ~ "`.");

    char* p = buff.ptr + buff.length;
    T k = val;
    do
        *--p = cast(char) (k % 10 + '0');
    while(k /= 10);

    return buff[p - buff.ptr .. $];
}

pure unittest
{
    UlongStringBuff buff;
    assert(1.uintToTempString(buff) == "1");
    assert(12.ulongToTempString(buff) == "12");
    assert(long.sizeof.sizeToTempString(buff) == "8");
    assert(uint.max.uintToTempString(buff) == "4294967295");
    assert(ulong.max.ulongToTempString(buff) == "18446744073709551615");
}


string format(string fmt, A...)(A args) pure
{
    static assert(_fmtPlaceholdersCount(fmt) == A.length, "Arguments count mismatch.");
    return format(fmt, args);
}

string format(A...)(in char[] fmt, A args) pure
{
    alias F = string function(in char[], A) pure nothrow;
    return (cast(F) &_formatImpure!A)(fmt, args); // pure hack
}

private string _formatImpure(A...)(in char[] fmt, A args)
{
    char[] res = new char[maxFormattedLength(fmt, args)];
    char* p = res.ptr;
    formatTo((chars) nothrow {
        memcpy(p, chars.ptr, chars.length);
        p += chars.length;
    }, fmt, args);
    return cast(string) res[0 .. p - res.ptr];
}

void formatTo(string fmt, A...)(scope void delegate(in char[]) nothrow put, A args)
{
    static assert(_fmtPlaceholdersCount(fmt) == A.length, "Arguments count mismatch.");
    formatTo(put, fmt, args);
}

void formatTo(A...)(scope void delegate(in char[]) nothrow put, in char[] fmt, A args)
in { assert(_fmtPlaceholdersCount(fmt) == A.length, "Arguments count mismatch."); }
body
{
    const(char)[] s = fmt;

    void putToNextPlaceholder() nothrow
    {
        if(const p = cast(const(char)*) memchr(s.ptr, '^', s.length))
        {
            if(p != s.ptr)
                put(s[0 .. p - s.ptr]);
            s = p[1 .. s.length - (p - s.ptr)];
        }
        else if(s.length)
        {
            put(s);
            s = null;
        }
    }
    putToNextPlaceholder();

    UlongStringBuff buff = void;
    foreach(arg; args)
    {
        alias T = _Unqual!(typeof(arg));
        static if(is(T : const(char)[]))
            put(arg);
        else static if(is(T == char))
            put(*cast(char[1]*) &arg);
        else static if(is(T == ubyte) || is(T == ushort) || is(T == uint))
            put(arg.uintToTempString(buff));
        else static if(is(T == ulong))
            put(arg.ulongToTempString(buff));
        else
            static assert(0, "Unexpected type: `" ~ T.stringof ~ "`.");
        putToNextPlaceholder();
    }
    assert(!s.length);
}

pure unittest
{
    assert(format!"a"() == "a");
    assert(format!"a^"(1U) == "a1");
    assert(format!"^ab^c"(1U, 2UL) == "1ab2c");
    assert(format("^^^", '<', ulong.max, ">") == "<18446744073709551615>");
    static assert(!__traits(compiles, format!"a"(1)));
    static assert(!__traits(compiles, format!"a^"()));
    static assert(!__traits(compiles, format!"^"(byte.max)));
}


size_t maxFormattedLength(A...)(in char[] fmt, A args) pure
in { assert(_fmtPlaceholdersCount(fmt) == A.length, "Arguments count mismatch."); }
body
{
    size_t res = 0;
    foreach(arg; args)
    {
        alias T = _Unqual!(typeof(arg));
        static if(is(T : const(char)[]))
            res += arg.length;
        else static if(is(T == char))
            ++res;
        else static if(is(T == ubyte) || is(T == ushort) || is(T == uint))
            res += UintStringBuff.length;
        else static if(is(T == ulong))
            res += UlongStringBuff.length;
        else
            static assert(0, "Unexpected type: `" ~ T.stringof ~ "`.");
    }
    return fmt.length - args.length + res;
}

pure unittest
{
    assert(maxFormattedLength("a") == 1);
    assert(maxFormattedLength("a^b^c^^", '!', 1U, 2UL, "xy") == 3 + 1 + 10 + 20 + 2);
}

private size_t _fmtPlaceholdersCount(in char[] fmt) pure
{
    size_t res = 0;
    if(__ctfe)
    {
        foreach(ch; fmt) if(ch == '^')
            ++res;
    }
    else
    {
        const(void*) end = fmt.ptr + fmt.length;
        const(void)* p = fmt.ptr;
        while(cast(size_t) (p = memchr(p, '^', end - p) + 1) != 1)
            ++res;
    }
    return res;
}


int dstrcmp( in char[] s1, in char[] s2 ) pure
{
    int  ret = 0;
    auto len = s1.length;
    if( s2.length < len )
        len = s2.length;
    if( 0 != (ret = memcmp( s1.ptr, s2.ptr, len )) )
        return ret;
    return s1.length >  s2.length ? 1 :
           s1.length == s2.length ? 0 : -1;
}


// From `std.traits.Unqual` with @@@BUG1308@@@ workaround.
private template _Unqual(T)
{
         static if (is(T U == shared(inout U))) alias _Unqual = U;
    else static if (is(T U == shared(const U))) alias _Unqual = U;
    else static if (is(T U ==        inout U )) alias _Unqual = U;
    else static if (is(T U ==        const U )) alias _Unqual = U;
    else static if (is(T U ==    immutable U )) alias _Unqual = U;
    else static if (is(T U ==       shared U )) alias _Unqual = U;
    else                                        alias _Unqual = T;
}
