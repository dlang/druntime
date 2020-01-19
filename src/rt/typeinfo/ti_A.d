/**
 * TypeInfo support code.
 *
 * Copyright: Copyright Digital Mars 2004 - 2009.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright
 */

/*          Copyright Digital Mars 2004 - 2019.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.typeinfo.ti_A;

private import rt.util.typeinfo;

// cdouble[]
class TypeInfo_Ar : Impl_TypeInfo_A!cdouble {}

// cfloat[]
class TypeInfo_Aq : Impl_TypeInfo_A!cfloat {}

// creal[]
class TypeInfo_Ac : Impl_TypeInfo_A!creal {}

// double[]
class TypeInfo_Ad : Impl_TypeInfo_A!double {}

// idouble[]
class TypeInfo_Ap : Impl_TypeInfo_A!idouble {}

// float[]
class TypeInfo_Af : Impl_TypeInfo_A!float {}

// ifloat[]
class TypeInfo_Ao : Impl_TypeInfo_A!ifloat {}

// byte[]
class TypeInfo_Ag : Impl_TypeInfo_A!byte {}

// ubyte[]
class TypeInfo_Ah : Impl_TypeInfo_A!ubyte {};

// void[]
class TypeInfo_Av : Impl_TypeInfo_A!void {}

// bool[]
class TypeInfo_Ab : Impl_TypeInfo_A!bool {}

// char[]
class TypeInfo_Aa : Impl_TypeInfo_A!char {}

// string
class TypeInfo_Aya : Impl_TypeInfo_A!(immutable(char)) {}

// const(char)[]
class TypeInfo_Axa : Impl_TypeInfo_A!(const(char)) {}


extern (C) void[] _adSort(void[] a, TypeInfo ti);

// int[]
class TypeInfo_Ai : Impl_TypeInfo_A!int {}

unittest
{
    int[][] a = [[5,3,8,7], [2,5,3,8,7]];
    _adSort(*cast(void[]*)&a, typeid(a[0]));
    assert(a == [[2,5,3,8,7], [5,3,8,7]]);

    a = [[5,3,8,7], [5,3,8]];
    _adSort(*cast(void[]*)&a, typeid(a[0]));
    assert(a == [[5,3,8], [5,3,8,7]]);
}

unittest
{
    // Issue 13073: original code uses int subtraction which is susceptible to
    // integer overflow, causing the following case to fail.
    int[] a = [int.max, int.max];
    int[] b = [int.min, int.min];
    assert(a > b);
    assert(b < a);
}

// uint[]
class TypeInfo_Ak : Impl_TypeInfo_A!uint {}

unittest
{
    // Original test case from issue 13073
    uint x = 0x22_DF_FF_FF;
    uint y = 0xA2_DF_FF_FF;
    assert(!(x < y && y < x));
    uint[] a = [x];
    uint[] b = [y];
    assert(!(a < b && b < a)); // Original failing case
    uint[1] a1 = [x];
    uint[1] b1 = [y];
    assert(!(a1 < b1 && b1 < a1)); // Original failing case
}

// dchar[]
class TypeInfo_Aw : Impl_TypeInfo_A!dchar {}


// long[]
class TypeInfo_Al : Impl_TypeInfo_A!long {}

// ulong[]
class TypeInfo_Am : Impl_TypeInfo_A!ulong {}

// real[]
class TypeInfo_Ae : Impl_TypeInfo_A!real {}

// ireal[]
class TypeInfo_Aj : Impl_TypeInfo_A!ireal {}

// short[]
class TypeInfo_As : Impl_TypeInfo_A!short {}

// ushort[]
class TypeInfo_At : Impl_TypeInfo_A!ushort {}

// wchar[]
class TypeInfo_Au : Impl_TypeInfo_A!wchar {}
