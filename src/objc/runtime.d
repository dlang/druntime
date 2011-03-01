/**
 * Objective-C runtime types and functions.
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
module objc.runtime;

version (D_ObjC) {}
else static assert(0, "Compiler does not support the Objective-C object model");

import core.stdc.stdlib; // malloc, free
import core.stdc.stdint; // uintptr_t

version (OSX)
{
    pragma(lib, "objc");

    // Version identifiers for OS X
    //
    // Before Mac OS X 10.5:  LegacyRuntime
    // Mac OS X 10.5 32-bit:  LegacyRuntime + ModernAPI
    // Mac OS X 10.5 64-bit:  ModernRuntime + ModernAPI
    // iOS:                   ModernRuntime + ModernAPI
    
    version (PPC)
    {
        version = LegacyRuntime;
        version = ModernAPI;
    }
    else version (X86)
    {
        version = LegacyRuntime;
        version = ModernAPI;
    }
    else version (X86_64)
    {
        version = ModernRuntime;
        version = ModernAPI;
    }
    else
        static assert(0, "Unsupported architecture");
}
else
    static assert(0, "Unsupported platform");

extern (C)
{
    
    // MARK: Classes
    
    version (ModernAPI)
    {
        
        const(char)* class_getName(Class cls);
        Class class_getSuperclass(Class cls);
        Class class_setSuperclass(Class cls, Class newSuper);
        BOOL class_isMetaClass(Class cls);
        size_t class_getInstanceSize(Class cls);
        
    }
    
    // Instance Variables
    
    /** Get instance variable description for name in given class. */
    Ivar class_getInstanceVariable(Class c, char* name);
    
    version (ModernAPI)
    {

        Ivar class_getClassVariable(Class cls, const(char)* name);
        BOOL class_addIvar(Class cls, const(char)* name, size_t size, ubyte alignment, const(char)* types);
        Ivar* class_copyIvarList(Class cls, uint* outCount);
        const(char)* class_getIvarLayout(Class cls);
        void class_setIvarLayout(Class cls, const(char)* layout);
        const(char)* class_getWeakIvarLayout(Class cls);
        void class_setWeakIvarLayout(Class cls, const(char)* layout);
    }
    
    // Properties
    
    version (ModernAPI)
    {
    
        objc_property_t class_getProperty(Class cls, const(char)* name);
        objc_property_t* class_copyPropertyList(Class cls, uint* outCount);
    
    }
    
    // Methods
    
    Method class_getInstanceMethod(Class aClass, SEL aSelector);
    Method class_getClassMethod(Class aClass, SEL aSelector);
    
    version (ModernAPI)
    {
        
        BOOL class_addMethod(Class cls, SEL name, IMP imp, const(char)* types);
        Method* class_copyMethodList(Class cls, uint* outCount);
        IMP class_replaceMethod(Class cls, SEL name, IMP imp, const(char)* types);
        IMP class_getMethodImplementation(Class cls, SEL name);
        IMP class_getMethodImplementation_stret(Class cls, SEL name);
        BOOL class_respondsToSelector(Class cls, SEL sel);
    }
    
    version (LegacyRuntime)
    {
        
        objc_method_list* class_nextMethodList(Class c, void** iterator);
        
        /** Add a new method list to given class. */
        void class_addMethods(Class c, objc_method_list* methodList);
        
        /** Remove a method list from given class. */
        void class_removeMethods(Class c, objc_method_list* methodList);
        
    }
    
    // Implemented Protocols
    
    version (ModernAPI)
    {
        
        BOOL class_addProtocol(Class cls, Protocol* protocol);
        BOOL class_conformsToProtocol(Class cls, Protocol* protocol);
        Protocol** class_copyProtocolList(Class cls, uint* outCount);
    }
    
    // Version
    
    /** Set the version number for a class. */
    void class_setVersion(Class c, int v);

    /** Get the version number for a class. */
    int class_getVersion(Class c);
    
    // MARK: Adding Classes
    
    version (ModernAPI)
    {
    
        Class objc_allocateClassPair(Class superclass, const(char)* name, size_t extraBytes);
        void objc_registerClassPair(Class cls);
        
        deprecated
        void objc_addClass(Class myClass);
        
    }
    
    version (LegacyRuntime)
    {
        
        /** Register a class with the runtime. */
        void objc_addClass(Class myClass);
        
    }
    
        
    // Posing
    
    version (LegacyRuntime)
    {
        
        /** Make a class pose as another class, overriding it. */
        Class class_poseAs(Class imposter, Class original);
        
    }
    
    // MARK: Instantiating Classes
    
    /** Create a new instance of a class in the default zone. */
    id class_createInstance(Class c, uint additionalByteCount);
    
    version (LegacyRuntime)
    {
        /** Create a new instance of a class in the specified zone. */
        id class_createInstanceFromZone(Class c, uint additionalByteCount, void* zone);
    }
    
    // MARK: Working with Instances
    
    version (ModernAPI)
    {
    
        id object_copy(id obj, size_t size);
        id object_dispose(id obj);
        
    }
    
    /** Assign new value to instance variable name of object. */
    Ivar object_setInstanceVariable(id obj, const(char)* name, void* value);
    
    /** Get value of instance variable name of object. */
    Ivar object_getInstanceVariable(id obj, const(char)* name, void** value);
    
    version (ModernAPI)
    {
        
        void* object_getIndexedIvars(id obj);
        id object_getIvar(id object, Ivar ivar);
        void object_setIvar(id object, Ivar ivar, id value);
        const(char)* object_getClassName(id obj);
        Class object_getClass(id object);
        Class object_setClass(id object, Class cls);
        
    }
    
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
    
    version (ModernAPI)
    {
    
        Class objc_getRequiredClass(const(char)* name);
        
    }
    
    version (LegacyRuntime)
    {
        /**
         * Set a callback function to handle missing class names in
         * objc_getClass and objc_getMetaClass.
         */
        void objc_setClassHandler(int function(const(char)*) callback);
    }
    
    // MARK: Working With Instance Variables
    
    const(char)* ivar_getName(Ivar ivar);
    const(char)* ivar_getTypeEncoding(Ivar ivar);
    ptrdiff_t ivar_getOffset(Ivar ivar);
    
    // MARK: Associative References
    
    version (ModernAPI)
    {
    
        void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy);
        id objc_getAssociatedObject(id object, void *key);
        void objc_removeAssociatedObjects(id object);
    
    }
    
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

version (LegacyRuntime)
{
    
    // MARK: Forwarding Messages
    // These used to be macros, now they are functions but should work the same.
    
    /** Number of bytes to stuff before arguments. */
    version (PPC)       enum size_t marg_prearg_size = 128;
    else version (X86)  enum size_t marg_prearg_size = 0;
    else static assert (0, "Unsupported architecture");
    
    /** Allocate a new argument list. */
    void marg_malloc(out marg_list margs, Method method)
    {
        margs = cast(marg_list)malloc(marg_prearg_size + 
                                      ((7 + method_getSizeOfArguments(method)) & ~7));
    }
    
    /** Release an argument list. */
    void marg_free(marg_list margs)
    {
        free(margs);
    }
    
    /** Get pointer to argument at offest in the list. */
    T* marg_getRef(T)(marg_list argList, size_t offset)
    {
        return cast(T*)(cast(byte*)margs + marg_prearg_size + offset);
    }
    
    /** Return value of argument at offset in the list. */
    T marg_getValue(T)(marg_list argList, size_t offset)
    {
        return *marg_getRef(margs, offset);
    }
    
    /** Set value of argument at offset in the list. */
    void marg_setValue(T)(marg_list argList, size_t offset, T value)
    {
        *marg_getRef(margs, offset) = value;
    }

}

extern (C)
{

    // MARK: Working with Methods
    
    /** Get the number of argument of a method. */
    uint method_getNumberOfArguments(Method method);
    
    version (ModernAPI)
    {
    
        SEL method_getName(Method method);
        IMP method_getImplementation(Method method);
        const(char)* method_getTypeEncoding(Method method);
        char* method_copyReturnType(Method method);
        char* method_copyArgumentType(Method method, uint index);
        void method_getReturnType(Method method, char* dst, size_t dst_len);

        void method_getArgumentType(Method method, uint index, char* dst, size_t dst_len);
        IMP method_setImplementation(Method method, IMP imp);
        void method_exchangeImplementations(Method m1, Method m2);
        
    }
    
    version (LegacyRuntime)
    {
        
        /** Get the size of the stack frame required for method's arguments. */
        uint method_getSizeOfArguments(Method method);
        
        /** Get information about argument index of given method. */
        uint method_getArgumentInfo(Method method, int index, char** type, int* offset);
        
    }
    
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
    
    version (LegacyRuntime)
    {
        
        /** Tell if a selector has been registered. */
        BOOL sel_isMapped(SEL aSelector);
        
    }
    
    // MARK: Working with Protocols
    
    /** Objective-C object representing a protocol. */
    typedef objc_object Protocol;
    
    version (ModernAPI)
    {
    
        Protocol* objc_getProtocol(const(char)* name);
        Protocol** objc_copyProtocolList(uint* outCount);
        const(char)* protocol_getName(Protocol *p);
        BOOL protocol_isEqual(Protocol *proto, Protocol *other);
        objc_method_description*protocol_copyMethodDescriptionList(Protocol *p, BOOL isRequiredMethod, BOOL isInstanceMethod, uint *outCount);
        objc_method_description protocol_getMethodDescription(Protocol *p, SEL aSel, BOOL isRequiredMethod, BOOL isInstanceMethod);
        objc_property_t * protocol_copyPropertyList(Protocol *protocol, uint *outCount);
        objc_property_t protocol_getProperty(Protocol *proto, const(char)* name, BOOL isRequiredProperty, BOOL isInstanceProperty);
        Protocol **protocol_copyProtocolList(Protocol *proto, uint *outCount);
        BOOL protocol_conformsToProtocol(Protocol *proto, Protocol *other);
        
    }
    

    // MARK: Working with Properties
    
    version (ModernAPI)
    {
        
        const(char)* property_getName(objc_property_t property);
        const(char)* property_getAttributes(objc_property_t property);
        
    }
    
}

// MARK: Data Types

// Class-Definition

/** Pointer to an Objective-C class definition. */
alias objc_class* Class;

/** Pointer to a definition of an Objective-C method. */
alias objc_method *Method;

/** Pointer to instance variable definition. */
alias objc_ivar* Ivar;

version (ModernAPI)
{

    // category
    alias objc_category* Category;
    
    // property
    alias objc_property* objc_property_t;
    
}

/** Pointer to a method implementation. */
alias id function(id, SEL, ...) IMP;

/** Pointer to a list of argument. */
alias void* marg_list;

/**
 * Method selector type. Selectors are indexed pointers to a C string 
 * representing the name of the method to be called.
 */
typedef objc_selector* SEL;
// Using struct even in legacy runtime to enable automatic conversions

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
enum BOOL : byte { NO = 0, YES = 1 }
alias BOOL.YES YES;
alias BOOL.NO  NO;

// Associative References

version (ModernAPI)
{
    
    alias uintptr_t objc_AssociationPolicy;
    
}

// Type Implementation

version (LegacyRuntime)
{
    
    /** Objective-C class definition. */
    pragma (objc_selectortarget)
    struct objc_class
    {
        
        /**
         * Pointer to the metaclass. The metaclass essentially manages class 
         * methods while a regular (non-meta) class manages isntance methods
         * and variables.
         *
         * If this class is a metaclass, isa points to the root class, which is 
         * usually NSObject's metaclass. The metaclass for a root class points to 
         * itself.
         */
        objc_class* isa;
        
        /**
         * Pointer to the superclass from which this class is derived.
         *
         * If this class is a metaclass, super_class points to the metaclass of
         * this superclass. If this class is a root class, it points to null.
         */
        objc_class* super_class;
        
        /**
         * Name of this class, as a C string.
         */
        const(char)* name;
        
        /**
         * The version number for this class, used when unserializing to indicate
         * that the layout of instance variable may have changed.
         */
        int version_ = 0;
        
        /**
         * Set of flags indicating some properties and states for the runtime.
         */
        int info;
        
        /**
         * The size occupied by the instance variables of in objects of this class.
         */
        int instance_size;
        
        /**
         * Pointer to an objc_ivar_list structure which is in itself a list of the 
         * instance variable's names, types, and offsets. A null value means there
         * is no instance variable.
         */
        objc_ivar_list* ivars;
        
        // If flag CLS_METHOD_ARRAY is set, use methodLists, otherwise
        // use singleMethodList.
        union
        {
            /**
             * Pointer to a null-terminated list of objc_method_list structures, 
             * which are each a group of methods for instances of this class. Use
             * only when the CLS_METHOD_ARRAY flag is set.
             */
            objc_method_list** methodLists;
            
            /**
             * Pointer to a single objc_method_list structure containing methods
             * for instances of this class. Use only when the CLS_METHOD_ARRAY 
             * flag is not set.
             */
            objc_method_list* singleMethodList;
        }
        
        /**
         * Pointer to a cache structure for use by the runtime.
         */
        objc_cache* cache;
        
        /**
         * Pointer to a objc_protocol_list structure describing the protocols
         * this class adhere to.
         */
        objc_protocol_list* protocols;
        
    }
    
    enum : int
    {
        /** Indicate a regular class. */
        CLS_CLASS = 0x1,
        
        /** Indicate a metaclass. */
        CLS_META = 0x2,
        
        /** Indicate a class which has been initialized. (For use by the runtime). */
        CLS_INITIALIZED = 0x4,
        
        /** Indicate a class posing for another class. */
        CLS_POSING = 0x8,
        
        // Runtime internal use:
        CLS_MAPPED = 0x10,
        CLS_GROW_CACHE = 0x20,
        CLS_FLUSH_CACHE = 0x40,
        CLS_NEED_BIND = 0x80,
        
        /**
         * Indicate a class using multiple method arrays instead of a single one
         * (use methodLists instead of singleMethodList in the objc_class).
         */
        CLS_METHOD_ARRAY = 0x100,
        
    }
    
    /** Definition of an Objective-C method. */
    struct objc_method
    {
        
        /** Selector for the method. */
        SEL method_name;
        
        /** Pointer to encoded method argument types as a C string. */
        const(char)* method_types;
        
        /** Pointer to the method implementation. This is null for protocols. */
        IMP method_imp;
        
    }
    
    /** Instance variable definition. */
    struct objc_ivar
    {
        
        /** Pointer to a C string with the variable name. */
        const(char)* ivar_name;
        
        /** Pointer to a C string with the encoded type for the variable. */
        const(char)* ivar_type;
        
        /** 
         * Offset of this variable from the start of the memory allocated for an 
         * instance.
         */
        int ivar_offset;
            
    }
    
    struct objc_category;
    
    struct objc_property;
    
    /** Definition of the base Objective-C object instance. */
    pragma (objc_selectortarget)
    struct objc_object
    {
        
        /** Pointer to the class definition of this instance. */
        Class isa;
        
        // Additional data for subclass-specific instance variables goes here...
        
    }

    /** List of instance variable definitions. */
    struct objc_ivar_list
    {
        
        /** Number of instance variables in this list. */
        int ivar_count;
        
        /** Array of instance variable definition. [variable length] */
        objc_ivar[0] ivar_list;
        
    }
    
    /** List of method definitions. */
    struct objc_method_list
    {
        
        /** Reserved. */
        void* obsolete;
        
        /** Number of methods in this list. */
        int method_count;
        
        /** Array with all the methods in this list. [variable length] */
        objc_method[0] method_list;
        
    }
    
    /** Cache to speedup method lookup. */
    struct objc_cache
    {
        
        /**
         * Number of cached methods minus one. Used with an AND mask it serves as 
         * a simple hashing algorithm for starting the search at the right bucket.
         */
        uint mask;
        
        /** The number of methods present in the cache. */
        uint occupied;
        
        /** Array of pointers to cached method definitions. */
        Method buckets[0];
    }
    
    /** List of protocols for use in a class definition. */
    struct objc_protocol_list
    {
        
        /** Pointer to the next protocol list. */
        objc_protocol_list *next;
        
        /** Number of protocols in this list. */
        int count;
        
        /** Inline array of pointers to protocol object instances. [variable length] */
        Protocol*[0] list;
        
    }
    
}
else
{
    
    // Modern runtime uses opaque types
    
    pragma (objc_selectortarget)
    struct objc_class;
    
    struct objc_method;
    struct objc_ivar;
    struct objc_category;
    struct objc_property;
    
    pragma (objc_selectortarget)
    struct objc_object;
    
}

pragma (objc_isselector)
struct objc_selector {}

// MARK: Implementation of some part of the modern API on the Legacy Runtime

version (LegacyRuntime)
{
    version (ModernAPI)
    {}
    else
    {
        
        // This is not exhaustive, functions are added as needed.
        
        Class object_getClass(id object) { return object.isa; }
        Class class_getSuperclass(Class cls) { return cls.super_class; }
        
    }
}
