/**
 * Support functions for Objective-C integration into D.
 *
 * Note: This module is available only on Mac OS X when the compiler has 
 * support for the Objective-C object model.
 *
 * Copyright: Copyright Michel Fortin 2011.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Michel Fortin
 *
 *          Copyright Michel Fortin 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module objc.druntime;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

import objc.runtime;

// Replacement allocators for D/Objective-C objects to allow static initializers to work

extern (C):

id _dobjc_alloc(Class cls, SEL _cmd)
{
    id object = class_createInstance(cls, 0);
    id __selector() _dobjc_preinit = cast(id __selector())"_dobjc_preinit";
    return _dobjc_preinit(object);
}

id _dobjc_allocWithZone(Class cls, SEL _cmd, void* zone)
{
    static if (__traits(compiles, class_createInstanceFromZone(cls, 0, zone)))
    {   
        id object = class_createInstanceFromZone(cls, 0, zone);
        id __selector() _dobjc_preinit = cast(id __selector())"_dobjc_preinit";
        return _dobjc_preinit(object);
    }
    else
        return _dobjc_alloc(cls, _cmd);
}

// Dynamic casts stubs

id _dobjc_dynamic_cast(id obj, Class cls)
{
    id __selector(Class) isKindOfClass = cast(id __selector(Class))"isKindOfClass:";
    if (isKindOfClass(obj, cls))
        return obj;
    return null;
}

id _dobjc_interface_cast(id obj, Protocol p)
{
    id __selector(Protocol) conformsToProtocol = cast(id __selector(Protocol))"conformsToProtocol:";
    if (conformsToProtocol(obj, p))
        return obj;
    return null;
}

// Assertion check with invariant

extern (C) void _dobjc_invariant(id obj)
{
    // BUG: needs to be filename/line of caller, not library routine
    assert(obj !is null); // just do null check, not invariant check
    
    auto respondsToSelector = cast(bool __selector(SEL))"respondsToSelector:";
    auto d_invariant = cast(void __selector())"_dobjc_invariant";

    // only call invariant if object responds to selector
    if (respondsToSelector(obj, cast(SEL)d_invariant))
        d_invariant(obj);
}

