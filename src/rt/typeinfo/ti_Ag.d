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
module rt.typeinfo.ti_Ag;

private import rt.typeinfo.ti_common;

// byte[]

class TypeInfo_Ag : TypeInfoShortArray!(byte)
{
}

// ubyte[]

class TypeInfo_Ah : TypeInfoUbyteArray!(ubyte)
{
}

// void[]

class TypeInfo_Av : TypeInfoUbyteArray!(void)
{
}

// bool[]

class TypeInfo_Ab : TypeInfoUbyteArray!(bool)
{
}

// char[]

class TypeInfo_Aa : TypeInfoUbyteArray!(char)
{
}

// string

class TypeInfo_Aya : TypeInfoUbyteArray!(immutable(char))
{
}

