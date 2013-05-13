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
module rt.typeinfo.ti_Aint;

private import rt.typeinfo.ti_common;

// int[]

class TypeInfo_Ai : TypeInfoShortArray!(int)
{
}

unittest
{
    int[][] a = [[5,3,8,7], [2,5,3,8,7]];
    a.sort;
    assert(a == [[2,5,3,8,7], [5,3,8,7]]);

    a = [[5,3,8,7], [5,3,8]];
    a.sort;
    assert(a == [[5,3,8], [5,3,8,7]]);
}

// uint[]

class TypeInfo_Ak : TypeInfoIntegerArray!(uint) //unable to simple compare (v1 - v2)
{
}

// dchar[]

class TypeInfo_Aw : TypeInfoIntegerArray!(dchar)
{
}
