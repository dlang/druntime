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
module rt.typeinfo.ti_Adouble;

private import rt.util.typeinfo;

// double[]

class TypeInfo_Ad : TypeInfo_Array
{
    mixin TypeInfo_A_T!double;
}

// idouble[]

class TypeInfo_Ap : TypeInfo_Ad
{
    mixin TypeInfo_A_T!idouble;
}
