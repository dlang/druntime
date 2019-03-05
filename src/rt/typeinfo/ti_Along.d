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
module rt.typeinfo.ti_Along;

private import core.stdc.string;
private import rt.util.typeinfo;

// long[]

class TypeInfo_Al : TypeInfo_Array
{
    mixin TypeInfo_A_T!long;
}

// ulong[]

class TypeInfo_Am : TypeInfo_Al
{
    mixin TypeInfo_A_T!ulong;
}
