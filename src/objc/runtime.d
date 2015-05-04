/**
 * Objective-C runtime types and functions.
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
module objc.runtime;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

import core.stdc.stdint; // uintptr_t
import objc.types;

version (OSX)
{
    pragma(lib, "objc");

    version (X86) {}
    else version (X86_64) {}

    else
        static assert(0, "Unsupported architecture");
}
else
    static assert(0, "Unsupported platform");

extern (C)
{

    // Classes

    const(char)* class_getName(Class cls);
    Class class_getSuperclass(Class cls);
    Class class_setSuperclass(Class cls, Class newSuper);
    BOOL class_isMetaClass(Class cls);
    size_t class_getInstanceSize(Class cls);

    // Instance Variables

    /** Get instance variable description for name in given class. */
    Ivar class_getInstanceVariable(Class c, char* name);
    Ivar class_getClassVariable(Class cls, const(char)* name);
    BOOL class_addIvar(Class cls, const(char)* name, size_t size, ubyte alignment, const(char)* types);
    Ivar* class_copyIvarList(Class cls, uint* outCount);
    const(char)* class_getIvarLayout(Class cls);
    void class_setIvarLayout(Class cls, const(char)* layout);
    const(char)* class_getWeakIvarLayout(Class cls);
    void class_setWeakIvarLayout(Class cls, const(char)* layout);

    // Properties

    objc_property_t class_getProperty(Class cls, const(char)* name);
    objc_property_t* class_copyPropertyList(Class cls, uint* outCount);

    // Methods

    Method class_getInstanceMethod(Class aClass, SEL aSelector);
    Method class_getClassMethod(Class aClass, SEL aSelector);
    BOOL class_addMethod(Class cls, SEL name, IMP imp, const(char)* types);
    Method* class_copyMethodList(Class cls, uint* outCount);
    IMP class_replaceMethod(Class cls, SEL name, IMP imp, const(char)* types);
    IMP class_getMethodImplementation(Class cls, SEL name);
    IMP class_getMethodImplementation_stret(Class cls, SEL name);
    BOOL class_respondsToSelector(Class cls, SEL sel);

    // Implemented Protocols

    BOOL class_addProtocol(Class cls, Protocol protocol);
    BOOL class_conformsToProtocol(Class cls, Protocol protocol);
    Protocol* class_copyProtocolList(Class cls, uint* outCount);

    // Version

    /** Set the version number for a class. */
    void class_setVersion(Class c, int v);

    /** Get the version number for a class. */
    int class_getVersion(Class c);

    // MARK: Adding Classes

    Class objc_allocateClassPair(Class superclass, const(char)* name, size_t extraBytes);
    void objc_registerClassPair(Class cls);

    // MARK: Instantiating Classes

    /** Create a new instance of a class in the default zone. */
    id class_createInstance(Class c, uint additionalByteCount);

    // MARK: Working with Instances

    id object_copy(id obj, size_t size);
    id object_dispose(id obj);

    /** Assign new value to instance variable name of object. */
    Ivar object_setInstanceVariable(id obj, const(char)* name, void* value);

    /** Get value of instance variable name of object. */
    Ivar object_getInstanceVariable(id obj, const(char)* name, void** value);

    void* object_getIndexedIvars(id obj);
    id object_getIvar(id object, Ivar ivar);
    void object_setIvar(id object, Ivar ivar, id value);
    const(char)* object_getClassName(id obj);
    Class object_getClass(id object);
    Class object_setClass(id object, Class cls);

    // MARK: Obtaining Class Definitions

    /**
     * Get the list of all the classes registered with the runtime in buffer,
     * up to length.
     */
    int objc_getClassList(Class* buf, int len);

    /**
     * Get registered class for name, or null if no class with that name
     * has been registered. This will not trigger the missing class handler.
     */
    Class objc_lookUpClass(const(char) *name);

    /**
     * Get registered class for name, or null if no class with that name
     * has been registered.
     */
    Class objc_getClass(const(char)* name);

    /**
     * Get registered metaclass for name, or null if no class with that
     * name has been registered.
     */
    Class objc_getMetaClass(const(char)* name);

    Class objc_getRequiredClass(const(char)* name);

    // MARK: Working With Instance Variables

    const(char)* ivar_getName(Ivar ivar);
    const(char)* ivar_getTypeEncoding(Ivar ivar);
    ptrdiff_t ivar_getOffset(Ivar ivar);

    // MARK: Associative References

    void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy);
    id objc_getAssociatedObject(id object, void *key);
    void objc_removeAssociatedObjects(id object);

    // MARK: Sending Messages

    /**
     * Call method for given selector on receiver expecting a simple return
     * value.
     */
    id objc_msgSend(id receiver, SEL selector, ...);

    /**
     * Call method for given selector on receiver expecting a struct return
     * value.
     */
    void objc_msgSend_stret(void* structReturnPtr, id receiver, SEL selector, ...);

    version (X86)
    {
        /**
         * Call method for given selector on receiver expecting a floating
         * point return value. [X86 only]
         *
         * Note that if you know receiver to be non-null, you can use
         * objc_msgSend instead. This special version of the function is
         * necessary to avoid a FP stack overflow when receiver is null.
         */
        double objc_msgSend_fpret(id receiver, SEL selector, ...);
    }

    // To superclass...

    /**
     * Call method for given selector on context.receiver using class
     * context.super_class method implementation, expecting a simple
     * return value.
     *
     * On X86, this function is used for floating point values too as
     * the receiver can be assumed non-null on a call to super.
     */
    id objc_msgSendSuper(objc_super* context, SEL selector, ...);

    /**
     * Call method for given selector on context.receiver using class
     * context.super_class method implementation, expecting a struct
     * return value. Contrary to basic objc_msgSend
     */
    void objc_msgSendSuper_stret(void* structReturnPtr, objc_super* context, SEL selector, ...);


    // With pointer to argument frame...

    /**
     * Call method for given selector on receiver expecting a simple return
     * value using given argument frame.
     */
    id objc_msgSendv(id receiver, SEL selector, uint argSize, marg_list argFrame);

    /**
     * Call method for given selector on receiver expecting a struct return
     * value using given argument frame.
     */
    void objc_msgSendv_stret(void* stretAddr, id receiver, SEL selector, uint argSize, marg_list argFrame);

    version (X86)
    {
        /**
         * Call method for given selector on context.receiver using class
         * context.super_class method implementation, expecting a floating
         * point return value using given argument frame.
         */
        double objc_msgSendv_fpret(id receiver, SEL selector, uint argSize, marg_list argFrame);
    }

}

extern (C)
{

    // MARK: Working with Methods

    /** Get the number of argument of a method. */
    uint method_getNumberOfArguments(Method method);

    SEL method_getName(Method method);
    IMP method_getImplementation(Method method);
    const(char)* method_getTypeEncoding(Method method);
    char* method_copyReturnType(Method method);
    char* method_copyArgumentType(Method method, uint index);
    void method_getReturnType(Method method, char* dst, size_t dst_len);

    void method_getArgumentType(Method method, uint index, char* dst, size_t dst_len);
    IMP method_setImplementation(Method method, IMP imp);
    void method_exchangeImplementations(Method m1, Method m2);

    // MARK: Working with Selectors

    /** Get the name of a selector. */
    const(char)* sel_getName(SEL aSelector);

    /**
     * Register selector with a given name with the runtime.
     * Return it's value.
     */
    SEL sel_registerName(const char* str);

    /** ditto */
    SEL sel_getUid(const char* str);

    BOOL sel_isEqual(SEL lhs, SEL rhs);

    // MARK: Working with Protocols

    Protocol objc_getProtocol(const(char)* name);
    Protocol* objc_copyProtocolList(uint* outCount);
    const(char)* protocol_getName(Protocol p);
    BOOL protocol_isEqual(Protocol proto, Protocol other);
    objc_method_description*protocol_copyMethodDescriptionList(Protocol p, BOOL isRequiredMethod, BOOL isInstanceMethod, uint *outCount);
    objc_method_description protocol_getMethodDescription(Protocol p, SEL aSel, BOOL isRequiredMethod, BOOL isInstanceMethod);
    objc_property_t * protocol_copyPropertyList(Protocol protocol, uint *outCount);
    objc_property_t protocol_getProperty(Protocol proto, const(char)* name, BOOL isRequiredProperty, BOOL isInstanceProperty);
    Protocol* protocol_copyProtocolList(Protocol proto, uint *outCount);
    BOOL protocol_conformsToProtocol(Protocol proto, Protocol other);

    // MARK: Working with Properties

    const(char)* property_getName(objc_property_t property);
    const(char)* property_getAttributes(objc_property_t property);
}

// MARK: Data Types

// Class-Definition

/** Pointer to an Objective-C class definition. */
alias objc_class* Class;

/** Pointer to a definition of an Objective-C method. */
alias objc_method *Method;

/** Pointer to instance variable definition. */
alias objc_ivar* Ivar;

// category
alias objc_category* Category;

// property
alias objc_property* objc_property_t;

/** Pointer to a method implementation. */
alias id function(id, SEL, ...) IMP;

/** Pointer to a list of argument. */
alias void* marg_list;

/**
 * Method selector type. Selectors are indexed pointers to a C string
 * representing the name of the method to be called.
 */
alias SEL = objc_selector*;

struct objc_method_description
{
    SEL name;
    char *types;
}

// Instance

/** Pointer to an Objective-C object instance. */
alias objc_object* id;

/** Superclass call context for objc_msgSendSuper. */
struct objc_super
{

    /** Pointer to the receiver instance this message applies to. */
    id receiver;

    /** Pointer to the class which will get the message. */
    Class super_class;
}

// Boolean

/** Objective-C boolean type, defined as one (signed) byte. */
enum BOOL : byte
{
    NO = 0,
    YES = 1
}

alias YES = BOOL.YES;
alias NO = BOOL.NO;

// Associative References
alias objc_AssociationPolicy = uintptr_t;

// Type Implementation

pragma (objc_selectortarget)
struct objc_class;

struct objc_method;
struct objc_ivar;
struct objc_category;
struct objc_property;

pragma (objc_selectortarget)
struct objc_object
{
    Class isa;
}

pragma (objc_isselector)
struct objc_selector {}
