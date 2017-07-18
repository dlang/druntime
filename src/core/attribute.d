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
version (D_ObjectiveC) struct selector
{
    string selector;
}

/** 
 * The following attribute groups are the special language function and have 
 * the following requirements enforced by the compiler:
 *  $(UL
 *   $(LI 
 *        A module declaration may be tagged with zero or more attribute 
 *        groups, to apply to all symbols (bar templates which remain 
 *        inferred with explicit tagging, see item 3) declared within the 
 *        module acting as the default value for that attribute group.
 *   ),
 *
 *   $(LI
 *        If any attribute groups are absent on a module declaration, then 
 *        the value for that  attribute group default to the corresponding 
 *        value in `core.attribute.defaultAttributeSet`.
 *   ),
 *
 *   $(LI
 *        Attributes may be applied to any function, method or class or struct,
 *        overrding the modules default value for that attribute. Attributes 
 *        applied to a struct or class apply to all methods of that struct or class. 
 *   ),
 * 
 *   $(LI
 *        No attribute from a given attribute group may appear more than once
 *        on any given symbol. i.e each attribute within each attribute group is
 *        mutually exclusive with every other attribute in that group.
 *   ),
 *
 *   $(LI
 *       An attribute from the `ClassVirtuality` group may only appear on classes 
 *       or class methods.
 *   )
 *  )
 * Examples:
 * ---
 * // all functions nogc by default
 * @nogc module foo; 
 * //uses the GC.
 * @core.attribute.FunctionGarbageCollectedness.gc void bar() {auto a = new int;} 
 * // Has FunctionGarbageCollectedness inferred
 * @core.attribute.FunctionGarbageCollectedness.inferred void baz() { someOtherFunction(); }
 * // Is implicity @nogc because foo is.
 * void quux();
 * ---
 */

enum FunctionGarbageCollectedness
{
    inferred = 0,
    gc,
    nogc,
}

// Aliases for brevity & backwards compatibility
// can add aliases for the other members if desired.
alias nogc = FunctionGarbageCollectedness.nogc;

enum FunctionSafety
{
    inferred = 0,
    system,
    safe,
    trusted,
}

alias system  = FunctionSafety.system;
alias safe    = FunctionSafety.safe;
alias trusted = FunctionSafety.trusted;

enum FunctionThrowness
{
    inferred = 0,
    throws,
    nothrow,
}

alias nothrow = FunctionThrowness.nothrow;

enum FunctionPurity
{
    inferred = 0,
    impure,
    pure,
    // strongly pure?
}

enum ClassVirtuality
{
    virtual,
    final,
}

alias final = ClassVirtuality.final;

private template AliasSeq(TList...)
{
    alias AliasSeq = TList;
}

// Version identifiers for illustration.
version (D_SafeD)
    alias __defaultSafetyAttribute = FunctionSafety.safe;
else
    alias __defaultSafetyAttribute = FunctionSafety.inferred;

// ditto
// defaultAttributeSet is compiler recognised
version (D_BetterC)
{
    alias defaultAttributeSet = 
        AliasSeq!(nogc,
                  __defaultSafetyAttribute,
                  nothrow,
                  FunctionPurity.inferred);
}
else
{
    alias defaultAttributeSet = 
        AliasSeq!(FunctionGarbageCollectedness.inferred,
                  __defaultSafetyAttribute,
                  FunctionThrowness.inferred,
                  FunctionPurity.inferred);
}                                     
