/**
 * This module contains UDA's (User Defined Attributes) either used in
 * the runtime or special UDA's recognized by compiler.
 *
 * Copyright: Copyright Jacob Carlborg 2015.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Jacob Carlborg
 * Source:    $(DRUNTIMESRC core/_attribute.d)
 */

/*          Copyright Jacob Carlborg 2015.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.attribute;

version (Posix)
    version = UdaGNUAbiTag;

version (D_ObjectiveC)
    version = UdaSelector;

version (CoreDdoc)
{
    version = UdaGNUAbiTag;
    version = UdaSelector;
}

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
 *  $(LI It cannot be attached to a method or constructor that is a template),
 *
 *  $(LI
 *      The number of colons in the string need to match the number of
 *      arguments the method accept.
 *  ),
 *
 *  $(LI It can only be used once in a method declaration)
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
version (UdaSelector) struct selector
{
    string selector;
}

/**
 * Use this attribute to declare an ABI tag on a C++ symbol.
 *
 * ABI tag is an attribute introduced by the GNU C++ compiler.
 * It modifies the mangled name of the symbol to incorporate the tag name,
 * in order to distinguish from an earlier version with a different ABI.
 * See: $(LINK2 https://gcc.gnu.org/onlinedocs/gcc/C_002b_002b-Attributes.html, GCC attributes documentation).
 *
 * This is a special compiler recognized attribute, it has a few
 * requirements, which all will be enforced by the compiler:
 *
 * $(UL
 *  $(LI
 *      The attribute can only be attached to an $(D_CODE extern(C++)).
 *  ),
 *
 *  $(LI
 *      The string arguments must only contain valid characters
 *      for C++ name mangling which currently include alphanumerics
 *      and the underscore character.
 *  ),
 * )
 *
 * Note: Unlike other attributes, when applied to a namespace,
 * this attribute applies to the namespace itself not the symbols under it.
 *
 * Examples:
 * ---
 * @gnuAbiTag("bar")
 * extern (C++, "Foo")
 * class A
 * {
 *     @gnuAbiTag("C")
 *     void method() {}
 * }
 * pragma(msg, __traits(getAttributes, A)); // tuple()
 *
 * extern(C++)
 * @gnuAbiTag("B")
 * __gshared A var;
 *
 * extern(C++)
 * @gnuAbiTag("E", "N", "M")
 * enum ABC { a, b, c }
 * ---
 */
version (UdaGNUAbiTag) struct gnuAbiTag
{
    string tag;
    string[] tags;

    @disable this();

    this(string tag, string[] tags...)
    {
        this.tag = tag;
        this.tags = tags;
    }
}
