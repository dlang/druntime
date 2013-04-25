/**
 * TypeInfo support code.
 *
 * Copyright: Copyright Digital Mars 2004 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright
 */

/*          Copyright Digital Mars 2004 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.typeinfo.ti_void;

private import rt.typeinfo.ti_common;
// void

class TypeInfo_v: TypeInfoInteger!(byte)
{
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { return "void"; }

    override size_t getHash(in void* p)
    {
        assert(0);
    }

    override @property size_t tsize() nothrow pure
    {
        return void.sizeof;
    }

    override @property uint flags() nothrow pure
    {
        return 1;
    }
}
