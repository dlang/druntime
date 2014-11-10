/**
 * This module contains UDA's (User Defined Attributes) either used in
 * the runtime or special UDA's recognized by compiler.
 *
 * Copyright: Copyright Jacob Carlborg 2014.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Jacob Carlborg
 * Source:    $(DRUNTIMESRC core/_attribute.d)
 */

/*          Copyright Jacob Carlborg 2014.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.attribute;

/**
 * This s represent a meta attribute. Any declaration that has this attribute
 * attached to itself is to be considered an attribute. That declaration
 * should only be used as an attribute and never on its own.
 */
enum attribute;

/**
 * Use this attribute to attach an Objective-C selector to a method.
 *
 * This is a special compiler recognized attribute, it has several
 * requirements, which all will be enforced by the compiler:
 *
 * $(UL
 *  $(LI
 *      The attribute can only be attached to methods or constructors which
 *      have Objective-C linkage. That is, a method or a constructor in a
 *      class or interface declared as $(D_CODE extern(Objective-C)).
 *  ),
 *
 *  $(LI It cannot be attached to a method or constructor that is a template)
 *
 *  $(LI
 *      The number of colons in the string need to match the number of
 *      arguments the method accept.
 *  )
 * )
 *
 * Examples:
 * ---
 * extern (Objective-C)
 * class NSObject
 * {
 *  this() @selector("init");
 *  static NSObject alloc() @selector("alloc");
 *  NSObject initWithUTF8String(in char* str) @selector("initWithUTF8String:");
 *  ObjcObject copyScriptingValue(ObjcObject value, NSString key, NSDictionary properties)
 *      @selector("copyScriptingValue:forKey:withProperties:");
 * }
 * ---
 */
version (D_ObjC) @attribute struct selector
{
    string selector;
}
