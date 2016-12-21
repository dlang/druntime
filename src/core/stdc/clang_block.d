/**
 * This module contains functionality for interfacing with
 * $(LINK2 http://clang.llvm.org/docs/BlockLanguageSpec.html, Clang Blocks).
 *
 * The examples below first shows a C function, using Clang Blocks, to call and
 * then the D code for calling the C function.
 *
 * Examples:
 *
 * Basic example of calling a function taking a block with no arguments that
 * returns void.
 *
 * $(CCODE void foo(void (^block)(void));)
 *
 * Will look like:
 *
 * ---
 * import core.stdc.clang_block;
 *
 * // The `Block` type is used to represent the Clang block in D
 * extern(C) void foo(Block!()* block);
 *
 * void main()
 * {
 *      // The `block` function is used to initialize an instance of `Block`.
 *      // A delegate will be passed to the `block` function which will be the
 *      // body of the block.
 *      auto b = block({ writeln("foo"); });
 *      foo(&b);
 * }
 * ---
 *
 * Example of calling a function taking a block with arguments that returns
 * void.
 *
 * $(CCODE void foo(void (^block)(int));)
 *
 * Will look like:
 *
 * ---
 * import core.stdc.clang_block;
 *
 * // The type parameters to the instantiation of `Block` is first the return
 * // type, `void`, and then the parameter types, `int`.
 * extern(C) void foo(Block!(void, int)* block);
 *
 * void main()
 * {
 *      // The delegate to the `block` function cannot use inferred type
 *      // parameters.
 *      auto b = block((int a){ writeln(a); });
 *      foo(&b);
 * }
 * ---
 *
 * Example of calling a function taking a block with no arguments that returns
 * an int.
 *
 * $(CCODE void foo(int (^block)(void));)
 *
 * Will look like:
 *
 * ---
 * import core.stdc.clang_block;
 *
 * extern(C) void foo(Block!(int)* block);
 *
 * void main()
 * {
 *      // The return type can be inferred
 *      auto b = block({ return 3; });
 *      foo(&b);
 * }
 * ---
 *
 * To build on non Apple platforms the C code needs to be compiled using Clang
 * and it's required to link with the
 * $(LINK2 http://compiler-rt.llvm.org, Blocks runtime). On Debian based
 * platforms install the following packages:
 * "llvm", "clang" and "libblocksruntime-dev". Example of compiling on Linux:
 *
 * $(CCODE
 *      $ clang foo.c -o foo.o
 *      $ dmd main.d foo.o -L-lBlocksRuntime
 * )
 *
 * Copyright: Copyright Jacob Carlborg 2016.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Jacob Carlborg
 * Source:    $(DRUNTIMESRC core/_clang_block.d)
 */
module core.stdc.clang_block;

import core.stdc.config;

/**
 * This struct is the D representation of a Clang Block.
 *
 * Params:
 *  R = the return type of the block
 *  Params = the parameter types of the block
 */
struct Block(R = void, Params...)
{
private:

    alias extern(C) R function(Block*, Params) Invoke;

    void* isa;
    int flags;
    int reserved = 0;
    Invoke invoke;
    Descriptor* descriptor;

    // Imported variables go here
    R delegate(Params) dg;

    this(void* isa, int flags, Invoke invoke, R delegate(Params) dg)
    {
        this.isa = isa;
        this.flags = flags;
        this.invoke = invoke;
        this.dg = dg;
        this.descriptor = &.descriptor;
    }
}

/**
 * Creates a new block that can be passed to a C function expecting a
 * Clang Block.
 *
 * Params:
 *  R = the return type of the block
 *  Params = the parameter types of the block
 *  dg = the body of the block
 *
 * Returns: the newly created block
 */
Block!(R, Params) block(R, Params...)(R delegate(Params) dg)
{
    static if (Params.length == 0)
        enum flags = 0x50000000;
    else
        enum flags = 0x40000000;

    return Block!(R, Params)(
        &_NSConcreteStackBlock, flags, &invoke!(R, Params), dg
    );
}

private:

/*
 * The the block implementation specification is available here:
 * http://clang.llvm.org/docs/Block-ABI-Apple.html
 */

// Block descriptor
struct Descriptor
{
    // null/0
    c_ulong reserved;

    // Block!(R, Params).sizeof
    c_ulong size;

    // Optional helper functions
    // extern(C) void function(void* dst, void* src) copy_helper;
    // extern(C) void function(void* src) dispose_helper;

    /*
     * Signature of the block, using Objective-C type encoding.
     * Seems not to be used.
     */
    const(char)* signature;
}

// Block of uninitialized memory used for stack block literals
extern(C) extern __gshared void*[32] _NSConcreteStackBlock;

/*
 * Shared block descriptor. Since the descriptor will always look the same we
 * can reuse a single descriptor.
 */
__gshared auto descriptor = Descriptor(0, Block!().sizeof);

/*
 * The body of a block that the C runtime will call.
 *
 * The implementation forwards to the delegate stored in the block struct
 * containing the real D body.
 *
 * Since a delegate is used to store the actual D body of the block a single
 * body can be shared for all blocks.
 *
 * Params:
 *  R = the return type of the block
 *  Args = the parameter types of the block
 *  args = the argument that was passed to the block
 *
 * Returns: whatever the delegate stored in the block returns
 */
extern(C) R invoke(R, Args...)(Block!(R, Args)* block, Args args)
{
    return block.dg(args);
}
