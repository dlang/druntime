/**
 * TypeInfo support code.
 *
 * Copyright: Copyright Digital Mars 2004 - 2009.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright
 */

/*          Copyright Digital Mars 2004 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.typeinfo.ti_wchar;

// wchar

class TypeInfo_u : TypeInfo
{
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() { return "wchar"; }

    override size_t getHash(scope const void* p)
    {
        return *cast(const wchar *)p;
    }

    override bool equals(const scope void* p1, const scope void* p2)
    {
        return *cast(wchar *)p1 == *cast(wchar *)p2;
    }

    override int compare(const scope void* p1, const scope void* p2)
    {
        return *cast(wchar *)p1 - *cast(wchar *)p2;
    }

    override @property size_t tsize()
    {
        return wchar.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        wchar t;

        t = *cast(wchar *)p1;
        *cast(wchar *)p1 = *cast(wchar *)p2;
        *cast(wchar *)p2 = t;
    }

    override const(void)[] initializer() const @trusted
    {
        static immutable wchar c;

        return (&c)[0 .. 1];
    }

    override @property immutable(void)* rtInfo() nothrow pure const @safe { return rtinfoNoPointers; }
}
