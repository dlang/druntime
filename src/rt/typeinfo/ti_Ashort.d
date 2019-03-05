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
module rt.typeinfo.ti_Ashort;

private import core.stdc.string;
private import rt.util.typeinfo;

// short[]

class TypeInfo_As : TypeInfo_Array
{
    mixin TypeInfo_A_T!short;
}

// ushort[]

class TypeInfo_At : TypeInfo_As
{
    mixin TypeInfo_A_T!ushort;
}

// wchar[]

class TypeInfo_Au : TypeInfo_At
{
    mixin TypeInfo_A_T!wchar;
}
