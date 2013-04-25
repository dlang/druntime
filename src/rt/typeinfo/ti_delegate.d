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
module rt.typeinfo.ti_delegate;

private import rt.typeinfo.ti_common;

// delegate

alias void delegate(int) dg;

class TypeInfo_D : TypeInfoCommonScalar!(dg)
{
    override @property uint flags() const nothrow pure @trusted
    {
        return 1;
    }
}
