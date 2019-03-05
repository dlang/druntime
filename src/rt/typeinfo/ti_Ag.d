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
module rt.typeinfo.ti_Ag;

private import core.stdc.string;
private import core.internal.string;
private import rt.util.typeinfo;

// byte[]

class TypeInfo_Ag : TypeInfo_Array
{
    mixin TypeInfo_A_T!byte;
}

// ubyte[]

class TypeInfo_Ah : TypeInfo_Ag
{
    mixin TypeInfo_A_T!ubyte;
}

// void[]

class TypeInfo_Av : TypeInfo_Ah
{
    mixin TypeInfo_A_T!void;
}

// bool[]

class TypeInfo_Ab : TypeInfo_Ah
{
    mixin TypeInfo_A_T!bool;
}

// char[]

class TypeInfo_Aa : TypeInfo_Ah
{
    mixin TypeInfo_A_T!char;
}

// string

class TypeInfo_Aya : TypeInfo_Aa
{
    mixin TypeInfo_A_T!(immutable(char));
}

// const(char)[]

class TypeInfo_Axa : TypeInfo_Aa
{
    mixin TypeInfo_A_T!(const(char));
}
