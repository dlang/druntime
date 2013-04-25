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
module rt.typeinfo.ti_cfloat;

private import rt.typeinfo.ti_common;

// cfloat

class TypeInfo_q : TypeInfoComplex!(cfloat)
{
    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(double);
        return 0;
    }
}
