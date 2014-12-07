/**
 * Objective-C protocol type.
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
module objc.types;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

extern (Objective-C):

/**
 * An object representing an Objective-C protocol. You can get the protocol
 * object of an extern(Objective-C) interface using the "protocolof" property.
 */
abstract class Protocol : NSObject
{
    @disable this();
}

pragma(mangle, "NSObject")
interface ObjcObject { }

class NSObject : ObjcObject
{
	Class isa;
}
