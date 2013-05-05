/**
 * Objective-C protocol type.
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
module objc.types;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

import objc.runtime;

/**
 * An object representing an Objective-C protocol. You can get the protocol
 * object of an extern(Objective-C) interface using the "protocolof" property.
 */
extern (Objective-C)
abstract class Protocol : __Object
{
    @disable this();

    // could add some other members, but they are probably irrelevant
}

/**
 * The Objective-C class "Object", a mostly obsolete root class which has been
 * replaced by NSObject everywhere but as the root class for Protocol.
 */
extern (Objective-C)
pragma(objc_nameoverride, "Object")
abstract class __Object
{
    void* isa;

    @disable this();
    bool opEquals(__Object) [isEqual:];
}
