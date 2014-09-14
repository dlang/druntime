/**
 * Support functions for Objective-C integration into D.
 *
 * Note: This module is available only on Mac OS X when the compiler has
 * support for the Objective-C object model.
 *
 * Copyright: Copyright Michel Fortin 2011.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Michel Fortin
 */

/*          Copyright Michel Fortin 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module objc.dobjc;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

import objc.runtime;

/**
 * Replacement allocators for D/Objective-C objects to allow static
 * initializers to work as expected.
 *
 * For classes with static initializers, including non-zero default values,
 * the compiler automatically generate the $(D _dobjc_preinit) instance method
 * to performs this initialization. To allow $(D _dobjc_preinit) to be
 * called before the constuctor is called, the compiler also make $(D alloc)
 * and $(D allocWithZone:) class methods use these two implementations.
 */
extern (C) id _dobjc_alloc(Class cls, SEL _cmd)
{
    id object = class_createInstance(cls, 0);
    id __selector() _dobjc_preinit = cast(id __selector())"_dobjc_preinit";
    return _dobjc_preinit(object);
}
/// ditto
extern (C) id _dobjc_allocWithZone(Class cls, SEL _cmd, void* zone)
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

/**
 * The compiler makes call to these functions when it must perform a dynamic
 * cast for Objective-C objects.
 */
extern (C) id _dobjc_dynamic_cast(id obj, Class cls)
{
    id __selector(Class) isKindOfClass = cast(id __selector(Class))"isKindOfClass:";
    if (isKindOfClass(obj, cls))
        return obj;
    return null;
}
/// ditto
extern (C) id _dobjc_interface_cast(id obj, Protocol p)
{
    id __selector(Protocol) conformsToProtocol = cast(id __selector(Protocol))"conformsToProtocol:";
    if (conformsToProtocol(obj, p))
        return obj;
    return null;
}

// Assertion check with invariant

/**
 * Check Objective-C class invariant by calling the $(D _dobjc_invariant)
 * instance method generated by the compiler for classes having invariant.
 */
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

// Exception wrapping

private
{
    // D throwable wrapped in an Objective-C exception
    final class D_ThrowableWrapper : NSException
    {
        Throwable throwable;

        this(Throwable t)
        {
            throwable = t;

            auto dname = throwable.classinfo.name;
            auto name = new NSString(dname.ptr, dname.length, NSString.Encoding.UTF8);

            auto ddesc = throwable.toString();
            auto reason = new NSString(ddesc.ptr, ddesc.length, NSString.Encoding.UTF8);

            super(name, reason, null);
        }

        override NSString description() @property [description]
        {
            return new NSString("hello", 5, NSString.Encoding.UTF8);
        }
    }

    extern (Objective-C) void objc_exception_throw(NSObject obj);
}

/**
 * Throw D exception in the Objective-C exception mechanism
 */
extern (Objective-C) void _dobjc_throwAs_objc(Throwable throwable)
{
    // check if this is a wrapped Objective-C exception
    auto wrapper = cast(ObjcExceptionWrapper)throwable;
    if (wrapper)
        objc_exception_throw(wrapper.except); // unwrap!

    objc_exception_throw(new D_ThrowableWrapper(throwable));
}

private
{
    // Objective-C exception wrapped in an D throwable
    final class ObjcExceptionWrapper : ObjcThrowable
    {
        NSException except;

        this(NSException except, Throwable next = null)
        {
            this.except = except;
            super("Objective-C wrapped exception", next);
        }

        override string toString()
        {
            auto desc = except.description;
            return desc.utf8String[0 .. desc.length].idup;
        }
    }
}

/**
 * Throw Objective-C exception in the D exception mechanism
 */
extern (C) void _dobjc_throwAs_d(NSException except)
{
    // check if this is a wrapped D exception
    auto wrapper = cast(D_ThrowableWrapper)except;
    if (wrapper)
        throw wrapper.throwable; // unwrap!

    throw new ObjcExceptionWrapper(except);
}

/**
 * Extract Objective-C exception from wrapper.
 */
extern (C) NSException _dobjc_exception_extract(ObjcExceptionWrapper wrapper)
{
    return wrapper.except;
}

// Legacy Objective-C runtime. Note: can throw Objective-C exceptions, which is
// why it is marked as extern(Objective-C) instead of extern(C).
version (X86)
private extern(Objective-C) int objc_exception_match(Class, id);

/**
 * Determine which catch handler class matches a specific Objective-C object,
 * return -1 if no match.
 */
extern (C) size_t _dobjc_exception_select(id ex, Class[] clist)
{
    foreach (i, c; clist)
        if (objc_exception_match(c, ex))
            return i;
    return -1;
}

private:

// Minimal declarations of some Foundation classes necessary for the
// implementation of this module.

extern (Objective-C)
class NSObject
{
    static NSObject alloc() [alloc];
    this() [init];
    NSString description() @property [description];
}

extern (Objective-C)
pragma (objc_takestringliteral)
class NSString : NSObject
{
    private Class _isa;

    enum Encoding { UTF8 = 4 }
    this(const(char)*, size_t, Encoding) [initWithBytes:length:encoding:];
    size_t length() @property [length];
    const(char)* utf8String() @property [UTF8String];
}

extern (Objective-C)
class NSDictionary
{
    static NSObject alloc() [alloc];
    this() [init];
}

extern (Objective-C)
class NSException : NSObject
{
    private
    {
        NSString _name;
        NSString _reason;
        NSDictionary _userInfo;
        id _reserved;
    }

    this(NSString name, NSString reason, NSDictionary userInfo) [initWithName:reason:userInfo:];
}
